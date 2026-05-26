// WebSocket P2P Client Library for Libreverse Experiences
// Provides backwards compatible API with the previous P2P implementation

import * as Y from "yjs";
import { WebsocketProvider as YActionCableProvider } from "@y-rb/actioncable";

// Default ICE servers (Google STUN)
const DEFAULT_ICE_SERVERS = [
    { urls: "stun:stun.l.google.com:19302" },
    { urls: "stun:stun1.l.google.com:19302" },
    { urls: "stun:stun1.l.google.com:3478" },
    { urls: "stun:stun2.l.google.com:19302" },
    { urls: "stun:stun3.l.google.com:19302" },
    { urls: "stun:stun3.l.google.com:3478" },
    { urls: "stun:stun4.l.google.com:19302" },
];

class LibreverseWebSocketP2P {
    constructor() {
        this.connected = false;
        this.isHost = false;
        this.peerId = undefined;
        this.sessionId = undefined;
        this.participants = {};
        this.messageHandlers = new Map();
        this.status = "disconnected";

        // Yjs related (per-document)
        this.docs = new Map(); // docId -> Y.Doc
        this.serverProviders = new Map(); // docId -> ActionCable provider
        this.serverProviderFactories = new Map(); // docId -> factory()
        this.webrtcProviders = new Map(); // docId -> WebRTC provider
        this.docConfigs = new Map(); // docId -> { mode: 'strict'|'relaxed', webrtc: boolean }
        this.defaultDocId = undefined;
        this.collabReadyHandlers = new Set();

        // Back-compat shims
        this.yProviders = this.serverProviders; // keep name used elsewhere
        // One-shot disconnect timers per document for relaxed flushes
        this._disconnectTimeouts = new Map(); // docId -> timeout id

        // Listen for messages from parent window (Libreverse app)
        window.addEventListener("message", (event) => {
            // Origin check for security - only accept messages from same origin
            if (event.origin !== globalThis.location.origin) {
                console.warn(
                    "WebSocket P2P: Ignored message from untrusted origin:",
                    event.origin,
                );
                return;
            }

            this.handleParentMessage(event.data);
        });

        // Signal that iframe is ready
        this.sendToParent("iframe-ready", {});

        // Flush on tab hide / navigation in relaxed mode so last state persists server-side
        const maybeFlush = () => {
            try {
                // Flush any doc configured as relaxed
                for (const [documentId, cfg] of this.docConfigs) {
                    if (cfg?.mode === "relaxed")
                        this.flushDocToServer(documentId);
                }
            } catch (error) {
                console.warn("flushToServer error", error);
            }
        };
        document.addEventListener("visibilitychange", () => {
            if (document.visibilityState === "hidden") maybeFlush();
        });
        // Fallbacks for some browsers
        window.addEventListener("pagehide", maybeFlush);
        window.addEventListener("beforeunload", maybeFlush);
    }

    // Send message to parent window (Libreverse app)
    sendToParent(type, data) {
        window.parent.postMessage({ type, data }, "*");
    }

    // Handle messages from parent window
    handleParentMessage(message) {
        if (!message || !message.type) return;

        switch (message.type) {
            case "p2p-init": {
                this.peerId = message.peerId;
                this.sessionId = message.sessionId;
                this.isHost = message.isHost;
                this.connected = message.connected;
                this.initialConfig = message.config || {};
                this.onInit(message);
                // Auto attach default collaborative doc once session known
                if (!this.defaultDocId && this.sessionId) {
                    this.defaultDocId = `session:${this.sessionId}`;
                    this.attachCollab(this.defaultDocId);
                    // Apply optional defaults from config at boot
                    const defaults = this.initialConfig?.yjs || {};
                    const mode = defaults.mode || "strict";
                    const webrtc =
                        defaults.webrtc === undefined
                            ? true
                            : !!defaults.webrtc;
                    const cfgIce = Array.isArray(defaults.iceServers)
                        ? defaults.iceServers
                        : Array.isArray(defaults.ice_servers)
                          ? defaults.ice_servers
                          : undefined;
                    const documentOptions = { mode, webrtc };
                    if (Array.isArray(cfgIce))
                        documentOptions.iceServers =
                            this._normalizeIceServers(cfgIce);
                    this.configureDocSync(this.defaultDocId, documentOptions);
                }
                break;
            }

            case "p2p-status": {
                this.connected = message.connected;
                this.status = message.connected ? "connected" : "disconnected";
                this.onStatusChange(message);
                break;
            }

            case "p2p-message": {
                this.onMessage(message.senderId, message.data);
                break;
            }

            case "p2p-participants": {
                this.participants = {};
                for (const participant of message.participants) {
                    // Validate participant data and sanitize peerId
                    if (
                        participant &&
                        typeof participant.peerId === "string" &&
                        participant.peerId.length > 0
                    ) {
                        // Only allow alphanumeric characters and hyphens for peer IDs
                        const sanitizedPeerId = participant.peerId.replaceAll(
                            /[^a-zA-Z0-9-]/g,
                            "",
                        );
                        if (sanitizedPeerId.length > 0) {
                            this.participants[sanitizedPeerId] = {
                                peerId: sanitizedPeerId,
                                // Copy other safe properties with validation
                                ...Object.fromEntries(
                                    Object.entries(participant).filter(
                                        ([key, value]) =>
                                            key !== "peerId" &&
                                            typeof value === "string",
                                    ),
                                ),
                            };
                        }
                    }
                }
                this.onParticipantsChange(this.participants);
                break;
            }
        }
    }

    // --- Collaborative Document API (Yjs + yrb-actioncable) ---
    attachCollab(documentId) {
        if (!documentId) throw new Error("documentId required");
        // If we've already created a provider for this document, reapply any updated config before returning it
        if (this.serverProviders.has(documentId)) {
            const existing = this.serverProviders.get(documentId);
            const cfg = this.docConfigs.get(documentId);
            if (cfg) {
                // Reapply configuration to existing provider
                if (cfg.mode === "strict") {
                    this._connectServerProvider(documentId);
                } else {
                    this._disconnectServerProvider(documentId, false);
                }
                if (cfg.webrtc) {
                    this._ensureWebRTCProvider(
                        documentId,
                        this.docs.get(documentId),
                    );
                } else {
                    this._destroyWebRTCProvider(documentId);
                }
            }
            return existing;
        }
        // Prepare ActionCable consumer
        const consumer =
            globalThis.App?.cable ||
            (globalThis.ActionCable &&
                globalThis.ActionCable.createConsumer &&
                globalThis.ActionCable.createConsumer());
        if (!consumer) {
            throw new Error(
                "No ActionCable consumer available for Yjs provider",
            );
        }

        // Ensure a Y.Doc exists for this document
        if (!this.docs.has(documentId)) this.docs.set(documentId, new Y.Doc());
        const ydoc = this.docs.get(documentId);

        // Set default config if missing
        if (!this.docConfigs.has(documentId))
            this.docConfigs.set(documentId, {
                mode: "strict",
                webrtc: true,
                signaling: undefined,
                iceServers: DEFAULT_ICE_SERVERS,
            });
        const cfg = this.docConfigs.get(documentId);

        // Factory to (re)create the server provider for this doc
        const factory = () => {
            const p = new YActionCableProvider(ydoc, consumer, "SyncChannel", {
                id: documentId,
            });
            p.on("status", (eventStatus) => {
                if (eventStatus.status === "connected") {
                    this._notifyCollabReady(documentId);
                }
            });
            return p;
        };

        this.serverProviderFactories.set(documentId, factory);
        // Create provider (may connect or keep disconnected based on mode)
        const provider = factory();
        this.serverProviders.set(documentId, provider);

        if (cfg.mode === "strict") this._connectServerProvider(documentId);
        else
            this._disconnectServerProvider(
                documentId,
                /*destroyIfNeeded=*/ false,
            );

        // Optionally start WebRTC provider for fast P2P diffusion
        if (cfg.webrtc) this._ensureWebRTCProvider(documentId, ydoc);

        return provider;
    }

    detachCollab(documentId) {
        const provider = this.yProviders.get(documentId);
        if (provider) {
            provider.destroy();
            this.yProviders.delete(documentId);
        }
    }

    getDoc(documentId = this.defaultDocId) {
        if (!documentId) return;
        return this.docs.get(documentId);
    }

    onCollabReady(handler) {
        if (typeof handler !== "function") {
            throw new TypeError("Handler must be a function");
        }
        this.collabReadyHandlers.add(handler);
        // Immediate fire if already connected
        if (this.defaultDocId && this._providerConnected(this.defaultDocId))
            handler(this.defaultDocId, this.ydoc);
        return () => this.collabReadyHandlers.delete(handler);
    }
    _providerConnected(documentId) {
        const p = this.serverProviders.get(documentId);
        return p && p.synced; // yrb-actioncable provider sets synced when initial state applied
    }

    _notifyCollabReady(documentId) {
        if (!this._providerConnected(documentId)) return;
        for (const h of this.collabReadyHandlers) {
            try {
                h(documentId, this.ydoc);
            } catch (error) {
                console.error("collabReady handler error", error);
            }
        }
    }

    // --- Sync mode configuration API ---
    configureDocSync(documentId, options = {}) {
        if (!documentId) throw new Error("documentId required");
        const previous = this.docConfigs.get(documentId) || {
            mode: "strict",
            webrtc: false,
            signaling: undefined,
            iceServers: DEFAULT_ICE_SERVERS,
        };
        const next = { ...previous };
        if (typeof options.mode === "string")
            next.mode = options.mode === "relaxed" ? "relaxed" : "strict";
        if (typeof options.webrtc === "boolean") next.webrtc = options.webrtc;
        if (Array.isArray(options.signaling))
            next.signaling = options.signaling.filter(
                (u) => typeof u === "string",
            );
        const userIce = Array.isArray(options.iceServers)
            ? options.iceServers
            : Array.isArray(options.ice_servers)
              ? options.ice_servers
              : undefined;
        if (Array.isArray(userIce))
            next.iceServers = this._normalizeIceServers(userIce);
        this.docConfigs.set(documentId, next);

        // Apply live
        if (previous.mode !== next.mode) {
            if (next.mode === "strict") this._connectServerProvider(documentId);
            else this._disconnectServerProvider(documentId);
        }
        if (next.webrtc)
            this._ensureWebRTCProvider(documentId, this.docs.get(documentId));
        else this._destroyWebRTCProvider(documentId);

        return next;
    }

    // Back-compat: apply to default doc if set
    configureSync(options = {}) {
        if (this.defaultDocId)
            return this.configureDocSync(this.defaultDocId, options);
    }
    setSyncMode(mode) {
        if (this.defaultDocId)
            return this.configureDocSync(this.defaultDocId, { mode });
    }
    enableWebRTC(enabled = true) {
        if (this.defaultDocId)
            return this.configureDocSync(this.defaultDocId, {
                webrtc: !!enabled,
            });
    }

    async _ensureWebRTCProvider(documentId, ydoc) {
        if (this.webrtcProviders.has(documentId))
            return this.webrtcProviders.get(documentId);
        try {
            const module_ = await import(/* @vite-ignore */ "y-webrtc");
            const WebrtcProvider =
                module_.WebrtcProvider || globalThis.WebrtcProvider;
            if (!WebrtcProvider) throw new Error("y-webrtc not available");
            // Use documentId as room; we can tune signaling servers later if needed
            const cfg = this.docConfigs.get(documentId) || {};
            const options = {};
            if (Array.isArray(cfg.signaling) && cfg.signaling.length > 0) {
                options.signaling = cfg.signaling;
            }
            const iceServers =
                Array.isArray(cfg.iceServers) && cfg.iceServers.length > 0
                    ? cfg.iceServers
                    : DEFAULT_ICE_SERVERS;
            const peerOptions = { config: { iceServers } };
            options.peerOpts = peerOptions;
            const provider = new WebrtcProvider(documentId, ydoc, options);
            this.webrtcProviders.set(documentId, provider);
            return provider;
        } catch (error) {
            console.warn(
                "y-webrtc provider unavailable; install 'y-webrtc' to enable P2P CRDT sync",
                error,
            );
            const cfg = this.docConfigs.get(documentId) || {
                mode: "strict",
                webrtc: false,
            };
            this.docConfigs.set(documentId, { ...cfg, webrtc: false });
            return;
        }
    }

    _destroyWebRTCProvider(documentId) {
        const provider = this.webrtcProviders.get(documentId);
        if (!provider) return;
        try {
            if (provider?.destroy) provider.destroy();
        } catch (error) {
            console.warn("webrtc destroy error", error);
        }
        this.webrtcProviders.delete(documentId);
    }

    _normalizeIceServers(servers) {
        const normalized = [];
        for (const entry of servers) {
            if (typeof entry === "string") {
                const value =
                    entry.startsWith("stun:") || entry.startsWith("turn:")
                        ? entry
                        : `stun:${entry}`;
                normalized.push({ urls: value });
            } else if (entry && typeof entry === "object") {
                if (Array.isArray(entry.urls)) {
                    for (const u of entry.urls) normalized.push({ urls: u });
                } else if (typeof entry.urls === "string") {
                    normalized.push({ urls: entry.urls });
                }
            }
        }
        return normalized.length > 0 ? normalized : DEFAULT_ICE_SERVERS;
    }

    _connectServerProvider(documentId) {
        const provider = this.serverProviders.get(documentId);
        if (!provider) return;
        try {
            if (typeof provider.connect === "function") provider.connect();
        } catch (error) {
            console.warn("server provider connect error", error);
        }
        // Cancel any auto-disconnect timer
        const t = this._disconnectTimeouts.get(documentId);
        if (t) clearTimeout(t);
        this._disconnectTimeouts.delete(documentId);
    }

    _disconnectServerProvider(documentId, destroyIfNeeded = false) {
        const provider = this.serverProviders.get(documentId);
        if (!provider) return;
        try {
            if (typeof provider.disconnect === "function")
                provider.disconnect();
            else if (destroyIfNeeded && typeof provider.destroy === "function")
                provider.destroy();
        } catch (error) {
            console.warn("server provider disconnect/destroy error", error);
        }
        if (destroyIfNeeded) this.serverProviders.delete(documentId);
    }

    // Trigger a one-shot sync to the server for a specific doc (used in relaxed mode)
    flushDocToServer(documentId) {
        if (
            !this.serverProviders.get(documentId) &&
            this.serverProviderFactories.get(documentId)
        ) {
            // recreate provider if it was destroyed
            const factory = this.serverProviderFactories.get(documentId);
            const provider = factory();
            this.serverProviders.set(documentId, provider);
        }
        this._connectServerProvider(documentId);
        // Auto-disconnect shortly after to keep connection lean in relaxed mode
        const cfg = this.docConfigs.get(documentId);
        if (cfg?.mode === "relaxed") {
            const existing = this._disconnectTimeouts.get(documentId);
            if (existing) clearTimeout(existing);
            const id = setTimeout(() => {
                this._disconnectServerProvider(documentId);
            }, 1500);
            this._disconnectTimeouts.set(documentId, id);
        }
    }

    // Back-compat convenience for default doc
    flushToServer() {
        if (this.defaultDocId) this.flushDocToServer(this.defaultDocId);
    }

    // Send P2P message to all peers
    send(data) {
        if (!this.connected) {
            console.warn("WebSocket P2P not connected");
            return false;
        }

        this.sendToParent("p2p-send", data);
        return true;
    }

    // Send P2P message to specific peer
    sendTo(peerId, data) {
        if (!this.connected) {
            console.warn("WebSocket P2P not connected");
            return false;
        }

        this.sendToParent("p2p-send-to", { peerId, data });
        return true;
    }

    // Get list of connected peers
    getPeers() {
        return Object.keys(this.participants);
    }

    // Get participant info
    getParticipant(peerId) {
        return this.participants[peerId];
    }

    // Check if connected to session
    isConnected() {
        return this.connected;
    }

    // Get connection status
    getStatus() {
        return this.status;
    }

    // Event handlers (can be overridden by experience)
    onInit(data) {
        console.log("WebSocket P2P initialized:", data);
    }

    onStatusChange(status) {
        console.log("WebSocket P2P status changed:", status);
    }

    onMessage(senderId, data) {
        console.log("WebSocket P2P message from", senderId, ":", data);

        // Call registered message handlers
        for (const handler of this.messageHandlers) {
            try {
                handler(senderId, data);
            } catch (error) {
                console.error("Error in P2P message handler:", error);
            }
        }
    }

    onParticipantsChange(participants) {
        console.log("WebSocket P2P participants changed:", participants);
    }

    // Register message handler
    addMessageHandler(handler) {
        if (typeof handler !== "function") {
            throw new TypeError("Message handler must be a function");
        }

        const id = Symbol();
        this.messageHandlers.set(id, handler);

        // Return unsubscribe function
        return () => this.messageHandlers.delete(id);
    }

    // Remove all message handlers
    clearMessageHandlers() {
        this.messageHandlers.clear();
    }

    // Backwards compatibility: support old callback style
    set onMessageCallback(callback) {
        if (typeof callback === "function") {
            this.clearMessageHandlers();
            this.addMessageHandler(callback);
        }
    }
}

// Create global instance for backward compatibility
if (typeof globalThis !== "undefined") {
    // Make P2P available globally in the experience
    globalThis.LibreverseP2P = new LibreverseWebSocketP2P();

    // Convenient shorthand
    globalThis.P2P = globalThis.LibreverseP2P;

    // Also expose the class for advanced usage
    globalThis.LibreverseWebSocketP2P = LibreverseWebSocketP2P;
}

export default LibreverseWebSocketP2P;
