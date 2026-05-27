// Keyboard lock handler for iframes
(function () {
    const TRUSTED_MESSAGE_ORIGIN = globalThis.location.origin;

    function isTrustedMessage(event) {
        return (
            Boolean(event?.origin) && event.origin === TRUSTED_MESSAGE_ORIGIN
        );
    }

    function addTrustedMessageListener(handler) {
        const wrappedListener = (event) => {
            if (!isTrustedMessage(event)) return;
            handler(event);
        };

        globalThis.addEventListener("message", wrappedListener);
        return () => globalThis.removeEventListener("message", wrappedListener);
    }

    // Store original keyboard lock methods
    const originalLock = navigator.keyboard && navigator.keyboard.lock;
    const originalUnlock = navigator.keyboard && navigator.keyboard.unlock;

    // Override keyboard lock to communicate with parent
    if (navigator.keyboard) {
        navigator.keyboard.lock = function (keyCodes) {
            // Try to call from iframe first (might work in some cases)
            if (originalLock) {
                try {
                    return originalLock.call(this, keyCodes);
                } catch (error) {
                    console.warn("Direct keyboard lock failed:", error.message);
                }
            }

            // Fallback: request parent to lock keyboard
            return globalThis.parent && globalThis.parent !== globalThis
                ? new Promise((resolve, reject) => {
                      const messageId = Date.now() + Math.random();

                      const removeListener = addTrustedMessageListener(
                          (event) => {
                              if (
                                  event.data.type ===
                                      "keyboard-lock-response" &&
                                  event.data.messageId === messageId
                              ) {
                                  removeListener();
                                  if (event.data.success) {
                                      resolve();
                                  } else {
                                      reject(
                                          new Error(
                                              event.data.error ||
                                                  "Keyboard lock failed",
                                          ),
                                      );
                                  }
                              }
                          },
                      );

                      globalThis.parent.postMessage(
                          {
                              type: "keyboard-lock-request",
                              messageId: messageId,
                              keyCodes: keyCodes,
                          },
                          globalThis.location.origin,
                      );

                      setTimeout(() => {
                          removeListener();
                          reject(new Error("Keyboard lock request timeout"));
                      }, 5000);
                  })
                : Promise.reject(
                      new Error("No parent window available for keyboard lock"),
                  );
        };

        navigator.keyboard.unlock = function () {
            if (originalUnlock) {
                try {
                    return originalUnlock.call(this);
                } catch (error) {
                    console.warn(
                        "Direct keyboard unlock failed:",
                        error.message,
                    );
                }
            }

            if (globalThis.parent && globalThis.parent !== globalThis) {
                globalThis.parent.postMessage(
                    {
                        type: "keyboard-unlock-request",
                    },
                    globalThis.location.origin,
                );
            }
        };
    }

    addTrustedMessageListener((event) => {
        if (event.data.type === "keyboard-lock-response") {
            // Response handled by the promise resolver above
        }
    });
})();
