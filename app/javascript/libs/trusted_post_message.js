const SAME_ORIGIN = globalThis.location.origin;

export function isSameOriginMessage(event) {
    return Boolean(event?.origin) && event.origin === SAME_ORIGIN;
}

export function addSameOriginMessageListener(listener) {
    const wrappedListener = (event) => {
        if (!isSameOriginMessage(event)) return;
        listener(event);
    };

    globalThis.addEventListener("message", wrappedListener);
    return () => globalThis.removeEventListener("message", wrappedListener);
}

export function readSameOriginMessageData(event) {
    if (!isSameOriginMessage(event)) return null;

    const { data } = event;
    return data !== null && typeof data === "object" ? data : null;
}
