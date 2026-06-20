import { jest } from "@jest/globals";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";

await jest.unstable_mockModule("@y-rb/actioncable", () => ({
    WebsocketProvider: class MockProvider {
        constructor() {
            this.synced = false;
        }
        on() {}
        destroy() {}
    },
}));

globalThis.ActionCable = {
    createConsumer: () => ({
        subscriptions: {
            create: () => ({}),
        },
    }),
};

const platformPath = path.resolve(
    path.dirname(fileURLToPath(import.meta.url)),
    "../../app/javascript/libs/libreverse_platform.js",
);

let postMessageSpy;

beforeAll(() => {
    globalThis.parent = globalThis;
    postMessageSpy = jest
        .spyOn(globalThis.parent, "postMessage")
        .mockImplementation(() => {});
    eval(readFileSync(platformPath, "utf8"));

    const multiplayer = globalThis.Libreverse.services.multiplayer;
    multiplayer.enableCollab = function enableCollab() {
        if (this._collabLoading) return this._collabLoading;
        this._collabLoading = import("../../app/javascript/libs/multiplayer_collab.js").then(
            () => this,
        );
        return this._collabLoading;
    };
});

describe("Experience platform multiplayer API", () => {
    beforeEach(() => {
        postMessageSpy.mockClear();
    });

    it("exposes optional multiplayer service without forcing collab", () => {
        expect(globalThis.Libreverse.services.multiplayer).toBeDefined();
        expect(typeof globalThis.P2P.send).toBe("function");
        expect(globalThis.P2P.getStatus()).toBe("idle");
    });

    it("can notify parent when ready", () => {
        postMessageSpy.mockClear();
        globalThis.Libreverse.services.multiplayer.sendToParent("iframe-ready", {});
        expect(postMessageSpy).toHaveBeenCalledWith(
            { type: "iframe-ready", data: {} },
            globalThis.location.origin,
        );
    });

    it("attaches default collab doc after init when autoCollab is enabled", async () => {
        const handler = jest.fn();
        const unsub = globalThis.P2P.onCollabReady(handler);

        globalThis.P2P.handleParentMessage({
            type: "p2p-init",
            peerId: "peer-1",
            sessionId: "sess-123",
            isHost: true,
            connected: true,
            config: { autoCollab: true },
        });

        await globalThis.P2P._collabLoading;
        expect(globalThis.P2P.defaultDocId).toBe("session:sess-123");
        unsub();
    });
});
