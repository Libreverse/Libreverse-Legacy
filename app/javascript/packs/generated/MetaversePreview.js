import ReactOnRails from "react-on-rails/client";
import MetaversePreview from "../../src/Metaverse3D/ror_components/MetaversePreview.jsx";

ReactOnRails.setOptions({
    turbo: true,
});

ReactOnRails.register({ MetaversePreview });

if (!globalThis.ReactOnRails) {
    globalThis.ReactOnRails = ReactOnRails;
}

const recordHydrationEvent = (event, payload = {}) => {
    const entry = { event, timestamp: Date.now(), ...payload };
    (globalThis.__MetaverseHydrationLog ||= []).push(entry);
    if (process.env.NODE_ENV !== "production") {
        console.debug(`[MetaverseHydration] ${event}`, payload);
    }
};

let hasHydrated = false;

const triggerHydration = (source) => {
    if (hasHydrated) {
        recordHydrationEvent("skip", { source });
        return;
    }

    try {
        recordHydrationEvent("start", { source });
        ReactOnRails.reactOnRailsPageLoaded();
        hasHydrated = true;
        recordHydrationEvent("success", { source });
    } catch (error) {
        recordHydrationEvent("error", { source, error: error?.message });
        console.error("ReactOnRails hydration failed", error);
    }
};

const resetHydration = (source) => {
    hasHydrated = false;
    recordHydrationEvent("reset", { source });
};

if (
    document.readyState === "complete" ||
    document.readyState === "interactive"
) {
    triggerHydration("document-ready");
} else {
    document.addEventListener(
        "DOMContentLoaded",
        () => triggerHydration("domcontentloaded"),
        { once: true },
    );
}

document.addEventListener("turbo:before-render", () =>
    resetHydration("turbo:before-render"),
);
document.addEventListener("turbo:render", () =>
    triggerHydration("turbo:render"),
);
document.addEventListener("turbo:load", () => triggerHydration("turbo:load"));
