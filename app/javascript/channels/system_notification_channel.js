import consumer from "./consumer";
import CookieUtils from "../libs/cookies.js";

// Subscribe to system notifications
const systemNotificationChannel = consumer.subscriptions.create(
    "SystemNotificationChannel",
    {
        connected() {
            console.log("Connected to SystemNotificationChannel");
        },

        disconnected() {
            console.log("Disconnected from SystemNotificationChannel");
        },

        received(data) {
            console.log("System notification received:", data);

            // Handle different types of system notifications
            if (data.type === "clear_cookies_and_reload") {
                this.handleClearCookiesAndReload(data);
            } else {
                console.log("Unknown system notification type:", data.type);
            }
        },

        handleClearCookiesAndReload(data) {
            console.log(
                "Clearing cookies and reloading due to invalid session:",
                data.reason,
            );

            // Add a flag to prevent multiple simultaneous clears
            if (sessionStorage.getItem("clearing_cookies") === "true") {
                console.log("Cookie clearing already in progress, skipping");
                return;
            }

            sessionStorage.setItem("clearing_cookies", "true");

            for (const name of Object.keys(CookieUtils.getAll())) {
                CookieUtils.remove(name, { path: "/", secure: true });
            }

            console.log("Cookies cleared, reloading page...");

            // Reload the page to get a fresh session
            globalThis.location.reload();
        },
    },
);

export default systemNotificationChannel;
