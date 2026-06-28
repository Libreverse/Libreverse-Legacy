import * as Y from "yjs";
import { WebsocketProvider as YActionCableProvider } from "@y-rb/actioncable";
import {
    addSameOriginMessageListener,
    readSameOriginMessageData,
} from "./trusted_post_message.js";

const DEFAULT_ICE_SERVERS = [
    { urls: "stun:stun.l.google.com:19302" },
    { urls: "stun:stun1.l.google.com:19302" },
];

function resolveMultiplayerService() {
    const service = globalThis.Libreverse?.services?.multiplayer;
    if (!service) {
        throw new Error("Libreverse multiplayer service is not available");
    }
    return service;
}

function installCollabExtensions(service) {
    if (service.__collabInstalled) return service;

    service.docs = service.docs || new Map();
    service.serverProviders = service.serverProviders || new Map();
    service.serverProviderFactories =
        service.serverProviderFactories || new Map();
    service.webrtcProviders = service.webrtcProviders || new Map();
    service.docConfigs = service.docConfigs || new Map();
    service.collabReadyHandlers = service.collabReadyHandlers || new Set();
    service._disconnectTimeouts = service._disconnectTimeouts || new Map();
    service.yProviders = service.serverProviders;

    service.attachCollab = function attachCollab(documentId) {
        if (!documentId) throw new Error("documentId required");
        if (this.serverProviders.has(documentId)) {
            const existing = this.serverProviders.get(documentId);
            const cfg = this.docConfigs.get(documentId);
            if (cfg) {
                if (cfg.mode === "strict")
                    this._connectServerProvider(documentId);
                else this._disconnectServerProvider(documentId, false);
                if (cfg.webrtc)
                    this._ensureWebRTCProvider(
                        documentId,
                        this.docs.get(documentId),
                    );
                else this._destroyWebRTCProvider(documentId);
            }
            return existing;
        }

        const consumer =
            globalThis.App?.cable ||
            (globalThis.ActionCable?.createConsumer &&
                globalThis.ActionCable.createConsumer());
        if (!consumer) {
            throw new Error(
                "No ActionCable consumer available for Yjs provider",
            );
        }

        if (!this.docs.has(documentId)) this.docs.set(documentId, new Y.Doc());
        const ydoc = this.docs.get(documentId);

        if (!this.docConfigs.has(documentId)) {
            this.docConfigs.set(documentId, {
                mode: "strict",
                webrtc: true,
                signaling: undefined,
                iceServers: DEFAULT_ICE_SERVERS,
            });
        }
        const cfg = this.docConfigs.get(documentId);

        const factory = () => {
            const provider = new YActionCableProvider(
                ydoc,
                consumer,
                "SyncChannel",
                {
                    id: documentId,
                },
            );
            provider.on("status", (eventStatus) => {
                if (eventStatus.status === "connected")
                    this._notifyCollabReady(documentId);
            });
            return provider;
        };

        this.serverProviderFactories.set(documentId, factory);
        const provider = factory();
        this.serverProviders.set(documentId, provider);

        if (cfg.mode === "strict") this._connectServerProvider(documentId);
        else this._disconnectServerProvider(documentId, false);

        if (cfg.webrtc) this._ensureWebRTCProvider(documentId, ydoc);
        return provider;
    };

    service.detachCollab = function detachCollab(documentId) {
        const provider = this.serverProviders.get(documentId);
        if (provider) {
            provider.destroy();
            this.serverProviders.delete(documentId);
        }
    };

    service.getDoc = function getDocument(documentId = this.defaultDocId) {
        if (!documentId) return;
        return this.docs.get(documentId);
    };

    service.onCollabReady = function onCollabReady(handler) {
        if (typeof handler !== "function")
            throw new TypeError("Handler must be a function");
        this.collabReadyHandlers.add(handler);
        if (this.defaultDocId && this._providerConnected(this.defaultDocId)) {
            handler(this.defaultDocId, this.getDoc(this.defaultDocId));
        }
        return () => this.collabReadyHandlers.delete(handler);
    };

    service.configureDocSync = function configureDocumentSync(
        documentId,
        options = {},
    ) {
        if (!documentId) throw new Error("documentId required");
        const previous = this.docConfigs.get(documentId) || {
            mode: "strict",
            webrtc: false,
            signaling: undefined,
            iceServers: DEFAULT_ICE_SERVERS,
        };
        const next = { ...previous };
        if (typeof options.mode === "string") {
            next.mode = options.mode === "relaxed" ? "relaxed" : "strict";
        }
        if (typeof options.webrtc === "boolean") next.webrtc = options.webrtc;
        if (Array.isArray(options.signaling)) {
            next.signaling = options.signaling.filter(
                (u) => typeof u === "string",
            );
        }
        const userIce = Array.isArray(options.iceServers)
            ? options.iceServers
            : (Array.isArray(options.ice_servers)
              ? options.ice_servers
              : undefined);
        if (Array.isArray(userIce))
            next.iceServers = service._normalizeIceServers(userIce);
        this.docConfigs.set(documentId, next);

        if (previous.mode !== next.mode) {
            if (next.mode === "strict") this._connectServerProvider(documentId);
            else this._disconnectServerProvider(documentId);
        }
        if (next.webrtc)
            this._ensureWebRTCProvider(documentId, this.docs.get(documentId));
        else this._destroyWebRTCProvider(documentId);
        return next;
    };

    service.configureSync = function configureSync(options = {}) {
        if (this.defaultDocId)
            return this.configureDocSync(this.defaultDocId, options);
    };
    service.setSyncMode = function setSyncMode(mode) {
        if (this.defaultDocId)
            return this.configureDocSync(this.defaultDocId, { mode });
    };
    service.enableWebRTC = function enableWebRTC(enabled = true) {
        if (this.defaultDocId) {
            return this.configureDocSync(this.defaultDocId, {
                webrtc: !!enabled,
            });
        }
    };
    service.flushDocToServer = function flushDocumentToServer(documentId) {
        if (
            !this.serverProviders.get(documentId) &&
            this.serverProviderFactories.get(documentId)
        ) {
            const factory = this.serverProviderFactories.get(documentId);
            const provider = factory();
            this.serverProviders.set(documentId, provider);
        }
        this._connectServerProvider(documentId);
        const cfg = this.docConfigs.get(documentId);
        if (cfg?.mode === "relaxed") {
            const existing = this._disconnectTimeouts.get(documentId);
            if (existing) clearTimeout(existing);
            const id = setTimeout(
                () => this._disconnectServerProvider(documentId),
                1500,
            );
            this._disconnectTimeouts.set(documentId, id);
        }
    };
    service.flushToServer = function flushToServer() {
        if (this.defaultDocId) this.flushDocToServer(this.defaultDocId);
    };

    service._providerConnected = function _providerConnected(documentId) {
        const provider = this.serverProviders.get(documentId);
        return provider && provider.synced;
    };

    service._notifyCollabReady = function _notifyCollabReady(documentId) {
        if (!this._providerConnected(documentId)) return;
        for (const handler of this.collabReadyHandlers) {
            try {
                handler(documentId, this.getDoc(documentId));
            } catch (error) {
                console.error("collabReady handler error", error);
            }
        }
    };

    service._ensureWebRTCProvider = async function _ensureWebRTCProvider(
        documentId,
        ydoc,
    ) {
        if (this.webrtcProviders.has(documentId))
            return this.webrtcProviders.get(documentId);
        try {
            const module_ = await import(/* @vite-ignore */ "y-webrtc");
            const WebrtcProvider =
                module_.WebrtcProvider || globalThis.WebrtcProvider;
            if (!WebrtcProvider) throw new Error("y-webrtc not available");
            const cfg = this.docConfigs.get(documentId) || {};
            const options = {};
            if (Array.isArray(cfg.signaling) && cfg.signaling.length > 0) {
                options.signaling = cfg.signaling;
            }
            const iceServers =
                Array.isArray(cfg.iceServers) && cfg.iceServers.length > 0
                    ? cfg.iceServers
                    : DEFAULT_ICE_SERVERS;
            options.peerOpts = { config: { iceServers } };
            const provider = new WebrtcProvider(documentId, ydoc, options);
            this.webrtcProviders.set(documentId, provider);
            return provider;
        } catch (error) {
            console.warn("y-webrtc provider unavailable", error);
            const cfg = this.docConfigs.get(documentId) || {
                mode: "strict",
                webrtc: false,
            };
            this.docConfigs.set(documentId, { ...cfg, webrtc: false });
        }
    };

    service._destroyWebRTCProvider = function _destroyWebRTCProvider(
        documentId,
    ) {
        const provider = this.webrtcProviders.get(documentId);
        if (!provider) return;
        try {
            provider.destroy?.();
        } catch (error) {
            console.warn("webrtc destroy error", error);
        }
        this.webrtcProviders.delete(documentId);
    };

    service._normalizeIceServers = function _normalizeIceServers(servers) {
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
    };

    service._connectServerProvider = function _connectServerProvider(
        documentId,
    ) {
        const provider = this.serverProviders.get(documentId);
        if (!provider) return;
        try {
            provider.connect?.();
        } catch (error) {
            console.warn("server provider connect error", error);
        }
        const timeout = this._disconnectTimeouts.get(documentId);
        if (timeout) clearTimeout(timeout);
        this._disconnectTimeouts.delete(documentId);
    };

    service._disconnectServerProvider = function _disconnectServerProvider(
        documentId,
        destroyIfNeeded = false,
    ) {
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
    };

    service._attachDefaultCollabIfReady =
        function _attachDefaultCollabIfReady() {
            if (!this.sessionId || this.defaultDocId) return;
            this.defaultDocId = `session:${this.sessionId}`;
            this.attachCollab(this.defaultDocId);
            const defaults = this.initialConfig?.yjs || {};
            const mode = defaults.mode || "strict";
            const webrtc =
                defaults.webrtc === undefined ? true : !!defaults.webrtc;
            const cfgIce = Array.isArray(defaults.iceServers)
                ? defaults.iceServers
                : (Array.isArray(defaults.ice_servers)
                  ? defaults.ice_servers
                  : undefined);
            const documentOptions = { mode, webrtc };
            if (Array.isArray(cfgIce))
                documentOptions.iceServers = this._normalizeIceServers(cfgIce);
            this.configureDocSync(this.defaultDocId, documentOptions);
        };

    service.__collabInstalled = true;
    if (service.sessionId) service._attachDefaultCollabIfReady();
    return service;
}

const service = resolveMultiplayerService();
installCollabExtensions(service);

// Back-compat class export for tests and advanced usage.
export class LibreverseWebSocketP2P {
    constructor() {
        return service;
    }
}

export default LibreverseWebSocketP2P;
