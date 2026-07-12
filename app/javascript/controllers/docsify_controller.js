import { Controller } from "@hotwired/stimulus";

/**
 * Boots Docsify inside the app layout (no iframe).
 * Docsify auto-inits on import via documentReady; config must be set first.
 */
export default class extends Controller {
    static values = {
        basePath: { type: String, default: "/docs/content/" },
        editBase: {
            type: String,
            default:
                "https://github.com/Libreverse/Libreverse/edit/main/documentation/",
        },
    };

    static #themeLinkId = "docsify-vista-theme";
    static #loadPromise = null;

    connect() {
        this.configureDocsify();
        this.ensureTheme();
        this.loadDocsify();
    }

    disconnect() {
        // Docsify attaches global listeners; full page loads avoid re-init issues
        // (this page uses data-turbo="false" on the host).
    }

    configureDocsify() {
        const basePath = this.basePathValue.endsWith("/")
            ? this.basePathValue
            : `${this.basePathValue}/`;
        const editBase = this.editBaseValue;
        const plugins = [];

        plugins.push(this.editOnGithubPlugin(editBase));
        plugins.push(this.inaccuracyWarningPlugin());

        window.$docsify = {
            el: "#docsify-app",
            name: "Libreverse Documentation",
            loadSidebar: true,
            basePath,
            alias: {
                "/.*/_sidebar.md": "/_sidebar.md",
            },
            subMaxLevel: 2,
            auto2top: true,
            relativePath: false,
            plugins,
        };
    }

    ensureTheme() {
        if (document.getElementById(this.constructor.#themeLinkId)) return;
        const link = document.createElement("link");
        link.id = this.constructor.#themeLinkId;
        link.rel = "stylesheet";
        link.href =
            "https://cdn.jsdelivr.net/gh/LIGMATV/docsify-theme-vista@latest/vista.css";
        document.head.appendChild(link);
    }

    loadDocsify() {
        if (document.querySelector('script[data-docsify-bundle="true"]')) {
            // Script already present (e.g. soft re-entry). Full page load preferred.
            if (!document.getElementById("docsify-app")?.querySelector(".content")) {
                globalThis.location.reload();
            }
            return;
        }

        if (this.constructor.#loadPromise) {
            this.constructor.#loadPromise.then((url) => this.injectScript(url));
            return;
        }

        this.constructor.#loadPromise = import(
            "docsify/lib/docsify.min.js?url"
        )
            .then((mod) => {
                const url = mod.default || mod;
                this.injectScript(url);
                return url;
            })
            .catch((err) => {
                console.error("[docsify] failed to load", err);
                this.constructor.#loadPromise = null;
                this.element.innerHTML =
                    '<p class="docsify-host__error">Documentation failed to load. Please refresh the page.</p>';
            });
    }

    injectScript(url) {
        if (document.querySelector('script[data-docsify-bundle="true"]')) return;
        const script = document.createElement("script");
        script.src = url;
        script.async = true;
        script.dataset.docsifyBundle = "true";
        script.onerror = () => {
            this.element.innerHTML =
                '<p class="docsify-host__error">Documentation failed to load. Please refresh the page.</p>';
        };
        document.body.appendChild(script);
    }

    editOnGithubPlugin(editBase) {
        const title =
            "Found something inaccurate? Edit this page on GitHub to fix it.";
        return (hook, vm) => {
            hook.afterEach((html, next) => {
                const file = vm.route.file || "README.md";
                const editUrl = editBase + file;
                const footer = `
          <p class="edit-on-github" style="margin-top:1rem">
            <a href="${editUrl}" target="_blank" rel="noopener">${title}</a>
          </p>`;
                next(html + footer);
            });
        };
    }

    inaccuracyWarningPlugin() {
        const formatDateNatural = (date) => {
            const day = date.getDate();
            const months = [
                "January",
                "February",
                "March",
                "April",
                "May",
                "June",
                "July",
                "August",
                "September",
                "October",
                "November",
                "December",
            ];
            const monthName = months[date.getMonth()];
            const year = date.getFullYear();
            const j = day % 10;
            const k = day % 100;
            let suffix = "th";
            if (j === 1 && k !== 11) suffix = "st";
            else if (j === 2 && k !== 12) suffix = "nd";
            else if (j === 3 && k !== 13) suffix = "rd";
            return `${day}${suffix} of ${monthName} ${year}`;
        };

        const daysAgo = (fromDate) => {
            const now = new Date();
            const diffMs = Math.max(0, now - fromDate);
            return Math.floor(diffMs / (1000 * 60 * 60 * 24));
        };

        const inaccuracyLevel = (days) => {
            if (days <= 7) return "unlikely to be inaccurate";
            if (days <= 30) return "potentially inaccurate";
            if (days <= 90) return "reasonably likely to be inaccurate";
            return "highly likely to be inaccurate";
        };

        const buildMarkdown = (formatted, days, levelPhrase) => {
            const plural = days === 1 ? "" : "s";
            return `!> ⚠️ Libreverse is an early-stage project iterating quickly. This page was last updated on the ${formatted}. That was ${days} day${plural} ago. This page is ${levelPhrase}. ⚠️\n\n`;
        };

        return (hook, vm) => {
            hook.beforeEach((content, next) => {
                const file =
                    vm && vm.route && vm.route.file
                        ? vm.route.file
                        : "README.md";
                const base =
                    (window.$docsify && window.$docsify.basePath) ||
                    "/docs/content/";
                const url = base.replace(/\/?$/, "/") + file.replace(/^\//, "");
                fetch(url, { method: "HEAD", cache: "no-cache" })
                    .then((res) => res.headers.get("Last-Modified"))
                    .then((lm) => {
                        const d = lm ? new Date(lm) : new Date();
                        const days = daysAgo(d);
                        next(
                            buildMarkdown(
                                formatDateNatural(d),
                                days,
                                inaccuracyLevel(days),
                            ) + content,
                        );
                    })
                    .catch(() => {
                        const d = new Date();
                        const days = daysAgo(d);
                        next(
                            buildMarkdown(
                                formatDateNatural(d),
                                days,
                                inaccuracyLevel(days),
                            ) + content,
                        );
                    });
            });
        };
    }
}
