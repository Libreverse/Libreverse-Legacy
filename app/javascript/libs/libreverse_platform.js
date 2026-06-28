// Libreverse platform utilities for experience iframes (silent, opt-in services).
(function () {
    "use strict";

    var SAME_ORIGIN = globalThis.location.origin;

    function isSameOriginMessage(event) {
        return Boolean(event && event.origin && event.origin === SAME_ORIGIN);
    }

    function readMessageData(event) {
        if (!isSameOriginMessage(event)) return;
        var data = event.data;
        return data !== null && typeof data === "object" ? data : undefined;
    }

    function MultiplayerService() {
        this.connected = false;
        this.isHost = false;
        this.peerId = undefined;
        this.sessionId = undefined;
        this.participants = {};
        this.messageHandlers = new Map();
        this.status = "idle";
        this.initialConfig = {};
        this._collabLoaded = false;
        this._collabLoading = null;

        var self = this;
        globalThis.addEventListener("message", function (event) {
            var data = readMessageData(event);
            if (!data) return;
            self.handleParentMessage(data);
        });
    }

    MultiplayerService.prototype.sendToParent = function (type, data) {
        globalThis.parent.postMessage(
            { type: type, data: data || {} },
            SAME_ORIGIN,
        );
    };

    MultiplayerService.prototype.handleParentMessage = function (message) {
        if (!message || !message.type) return;

        switch (message.type) {
            case "p2p-init": {
                this.peerId = message.peerId;
                this.sessionId = message.sessionId;
                this.isHost = message.isHost;
                this.connected = message.connected;
                this.status = message.connected ? "connected" : "disconnected";
                this.initialConfig = message.config || {};
                this.onInit(message);
                if (this.initialConfig.autoCollab) {
                    var self = this;
                    this.enableCollab()
                        .then(function () {
                            if (
                                typeof self._attachDefaultCollabIfReady ===
                                "function"
                            ) {
                                self._attachDefaultCollabIfReady();
                            }
                        })
                        .catch(function (error) {
                            console.warn(
                                "Multiplayer collab unavailable:",
                                error,
                            );
                        });
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
                for (
                    var index = 0;
                    index < (message.participants || []).length;
                    index++
                ) {
                    var participant = message.participants[index];
                    if (!participant || typeof participant.peerId !== "string")
                        continue;
                    var sanitized = participant.peerId.replaceAll(
                        /[^a-zA-Z0-9-]/g,
                        "",
                    );
                    if (!sanitized) continue;
                    this.participants[sanitized] = { peerId: sanitized };
                }
                this.onParticipantsChange(this.participants);
                break;
            }
        }
    };

    MultiplayerService.prototype.isAvailable = function () {
        return this.status !== "idle";
    };

    MultiplayerService.prototype.enableCollab = function () {
        if (this._collabLoaded) return Promise.resolve(this);
        if (this._collabLoading) return this._collabLoading;

        var scriptUrl = globalThis.__LIBREVERSE_COLLAB_SCRIPT_URL__;
        if (!scriptUrl) {
            return Promise.reject(
                new Error("Multiplayer collab script URL is not configured"),
            );
        }

        var self = this;
        this._collabLoading = new Promise(function (resolve, reject) {
            var script = document.createElement("script");
            script.type = "module";
            script.src = scriptUrl;
            script.addEventListener("load", function () {
                self._collabLoaded = true;
                resolve(self);
            });
            script.onerror = function () {
                reject(new Error("Failed to load multiplayer collab module"));
            };
            document.head.append(script);
        });

        return this._collabLoading;
    };

    MultiplayerService.prototype.send = function (data) {
        if (!this.connected) return false;
        this.sendToParent("p2p-send", data);
        return true;
    };

    MultiplayerService.prototype.sendTo = function (peerId, data) {
        if (!this.connected) return false;
        this.sendToParent("p2p-send-to", { peerId: peerId, data: data });
        return true;
    };

    MultiplayerService.prototype.getPeers = function () {
        return Object.keys(this.participants);
    };

    MultiplayerService.prototype.getParticipant = function (peerId) {
        return this.participants[peerId];
    };

    MultiplayerService.prototype.isConnected = function () {
        return this.connected;
    };

    MultiplayerService.prototype.getStatus = function () {
        return this.status;
    };

    MultiplayerService.prototype.onInit = function () {};
    MultiplayerService.prototype.onStatusChange = function () {};
    MultiplayerService.prototype.onParticipantsChange = function () {};

    MultiplayerService.prototype.onMessage = function (senderId, data) {
        for (const handler of this.messageHandlers) {
            try {
                handler(senderId, data);
            } catch (error) {
                console.error("Multiplayer message handler error:", error);
            }
        }
    };

    MultiplayerService.prototype.addMessageHandler = function (handler) {
        if (typeof handler !== "function") {
            throw new TypeError("Message handler must be a function");
        }
        var id = Symbol();
        this.messageHandlers.set(id, handler);
        return function () {
            this.messageHandlers.delete(id);
        }.bind(this);
    };

    MultiplayerService.prototype.clearMessageHandlers = function () {
        this.messageHandlers.clear();
    };

    Object.defineProperty(MultiplayerService.prototype, "onMessageCallback", {
        set: function (callback) {
            this.clearMessageHandlers();
            if (typeof callback === "function")
                this.addMessageHandler(callback);
        },
    });

    // Collab methods are installed by experience_multiplayer_collab.js when loaded.
    MultiplayerService.prototype.attachCollab = function () {
        throw new Error(
            "Call Libreverse.services.multiplayer.enableCollab() before using collaborative documents",
        );
    };
    MultiplayerService.prototype.getDoc = function () {
        return;
    };
    MultiplayerService.prototype.onCollabReady = function () {
        return function () {};
    };

    var multiplayer = new MultiplayerService();
    var libreverse = globalThis.Libreverse || {};
    libreverse.services = libreverse.services || {};
    libreverse.services.multiplayer = multiplayer;
    globalThis.Libreverse = libreverse;

    // Back-compat aliases (lazy no-ops until parent initializes a session).
    globalThis.LibreverseP2P = multiplayer;
    globalThis.P2P = multiplayer;

    function notifyReady() {
        multiplayer.sendToParent("iframe-ready", {});
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", notifyReady, {
            once: true,
        });
    } else {
        notifyReady();
    }
})();
