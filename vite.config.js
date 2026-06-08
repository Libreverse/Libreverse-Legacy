import { defineConfig } from "vite";
import path from "node:path";
import rubyPlugin from "vite-plugin-ruby";
import postcssInlineRtl from "postcss-inline-rtl";
import cssnano from "cssnano";
import coffeescript from "./plugins/coffeescript.js";
import postcssUrl from "postcss-url";
import typehints from "./plugins/typehints.js";
import preserveAllComments from "./plugins/preserveallcomments.js";
import Erb from "vite-plugin-erb";
import fullReload from "vite-plugin-full-reload";
import stimulusHMR from "vite-plugin-stimulus-hmr";

function withInstrumentation(p) {
    let modified = 0;
    return {
        ...p,
        async transform(code, id) {
            const out = await p.transform.call(this, code, id);
            if (out && out.code && out.code !== code) modified += 1;
            return out;
        },
        buildEnd() {
            this.info(`[typehints] Files modified: ${modified}`);
            if (p.buildEnd) return p.buildEnd.call(this);
        },
    };
}

export default defineConfig(({ mode }) => {
    const isDevelopment = mode === "development";
    const typehintPlugin = withInstrumentation(
        typehints({
            variableDocumentation: true,
            objectShapeDocumentation: true,
            maxObjectProperties: 6,
            enableCoercions: true,
            parameterHoistCoercions: false,
        }),
    );

    return {
        esbuild: {
            target: "es2020", // Modern target
            keepNames: false,
            treeShaking: isDevelopment ? false : true, // Disable tree shaking in development for faster builds
            legalComments: isDevelopment ? "none" : "inline", // Skip legal comments in development
        },
        resolve: {
            extensions: [".js", ".json", ".coffee", ".scss"],
            // Workaround for js-cookie packaging (dist folder not present in installed copy under bun)
            // Map to ESM source file so Vite can bundle successfully
            alias: {
                // Use explicit path into node_modules since package exports field hides src/*
                "js-cookie": path.resolve(
                    process.cwd(),
                    "node_modules/js-cookie/index.js",
                ),
            },
        },
        build: {
            cache: isDevelopment, // Enable cache in development for faster rebuilds
            rollupOptions: {
                input: {
                    application: "app/javascript/application.js",
                    emails: "app/stylesheets/emails.scss",
                },
                output: {
                    minifyInternalExports: true,
                    inlineDynamicImports: false,
                    compact: true,
                    generatedCode: {
                        preset: "es2015", // Modern output
                        arrowFunctions: true,
                        constBindings: true,
                        objectShorthand: true,
                    },
                },
                external: [],
                treeshake: {
                    moduleSideEffects: true,
                    propertyReadSideEffects: false,
                    tryCatchDeoptimization: false,
                    unknownGlobalSideEffects: false,
                },
            },
            target: ["es2020", "edge88", "firefox78", "chrome87", "safari14"], // Modern browsers
            modulePreload: { polyfill: true },
            cssCodeSplit: true,
            assetsInlineLimit: 2147483647,
            cssTarget: ["esnext"],
            sourcemap: false,
            chunkSizeWarningLimit: 2147483647,
            reportCompressedSize: false,
            minify: isDevelopment ? false : "terser",
            terserOptions: isDevelopment
                ? undefined
                : {
                      parse: {
                          bare_returns: false,
                          html5_comments: false,
                          shebang: false,
                          ecma: 2020, // Modern parsing
                      },
                      compress: {
                          defaults: true,
                          arrows: true, // Keep arrow functions
                          arguments: true,
                          booleans: true,
                          booleans_as_integers: false,
                          collapse_vars: true,
                          comparisons: true,
                          computed_props: true,
                          conditionals: true,
                          dead_code: true,
                          directives: true,
                          drop_console: true, // Re-enabled to drop console statements
                          drop_debugger: true, // Re-enabled to drop debugger statements
                          ecma: 2020, // Modern compression
                          evaluate: true,
                          expression: false,
                          global_defs: {},
                          hoist_funs: true,
                          hoist_props: true,
                          hoist_vars: true,
                          if_return: true,
                          inline: true,
                          join_vars: true,
                          keep_classnames: false,
                          keep_fargs: true,
                          keep_fnames: false,
                          keep_infinity: false,
                          loops: true,
                          negate_iife: true,
                          passes: 10,
                          properties: true,
                          pure_getters: "strict",
                          pure_funcs: [
                              "console.log",
                              "console.info",
                              "console.debug",
                              "console.warn",
                              "console.error",
                              "console.trace",
                              "console.dir",
                              "console.dirxml",
                              "console.group",
                              "console.groupCollapsed",
                              "console.groupEnd",
                              "console.time",
                              "console.timeEnd",
                              "console.timeLog",
                              "console.assert",
                              "console.count",
                              "console.countReset",
                              "console.profile",
                              "console.profileEnd",
                              "console.table",
                              "console.clear",
                          ], // Re-added console methods as pure functions
                          reduce_vars: true,
                          reduce_funcs: true,
                          sequences: true,
                          side_effects: true,
                          switches: true,
                          toplevel: true,
                          top_retain: null,
                          typeofs: true,
                          unsafe: true,
                          unsafe_arrows: true, // Allow arrow function optimizations
                          unsafe_comps: true,
                          unsafe_Function: true,
                          unsafe_math: true,
                          unsafe_symbols: true,
                          unsafe_methods: true,
                          unsafe_proto: true,
                          unsafe_regexp: true,
                          unsafe_undefined: true,
                          unused: true,
                      },
                      mangle: {
                          eval: false,
                          keep_classnames: false,
                          keep_fnames: false,
                          reserved: [],
                          toplevel: true,
                          safari10: false, // No need for Safari 10 workarounds
                      },
                      format: {
                          ascii_only: false,
                          beautify: false,
                          braces: false,
                          comments: "some",
                          ecma: 2020, // Modern output format
                          indent_level: 0,
                          inline_script: true,
                          keep_numbers: false,
                          keep_quoted_props: false,
                          max_line_len: 0,
                          quote_keys: false,
                          preserve_annotations: false,
                          safari10: false, // No Safari 10 workarounds
                          semicolons: true,
                          shebang: false,
                          webkit: false, // No need for webkit workarounds
                          wrap_iife: false,
                          wrap_func_args: false,
                      },
                  },
        },
        server: {
            host: "127.0.0.1",
            port: 3001,
            strictPort: true,
            https: false,
            hmr: { overlay: true }, // Allow Vite to infer host/protocol
            headers: isDevelopment
                ? {
                      "Cache-Control":
                          "no-store, no-cache, must-revalidate, max-age=0",
                  }
                : {},
            fs: { strict: false },
        },
        css: {
            preprocessorOptions: {
                scss: {
                    api: "modern-compiler",
                    includePaths: ["node_modules", "./node_modules"],
                },
            },
            postcss: {
                plugins: [
                    postcssUrl({ url: "inline", maxSize: 2147483647 }),
                    postcssInlineRtl(),
                    cssnano({
                        preset: [
                            "advanced",
                            {
                                autoprefixer: true,
                                discardComments: {
                                    removeAllButCopyright: true,
                                },
                                normalizeString: true,
                                normalizeUrl: true,
                                normalizeCharset: true,
                            },
                        ],
                    }),
                ],
            },
        },
        define: {
            global: "globalThis",
        },
        optimizeDeps: {
            // Force inclusion of dependencies that might not be detected
            include: [
                "debounced",
                "@hotwired/turbo",
                "@hotwired/stimulus",
                "foundation-sites",
                "what-input",
                "@fingerprintjs/botd",
                "@rails/ujs",
                "js-cookie",
                "@sentry/browser",
                "turbo_power",
                "@rails/activestorage",
                "stimulus_reflex",
                "cable_ready",
                "@rails/actioncable",
                "locomotive-scroll",
                "@rails/request.js",
                "stimulus-store",
                "@hotwired/turbo-rails",
                "leaflet",
                "leaflet.offline",
                "leaflet-ajax",
                "leaflet-spin",
                "leaflet-sleep",
                "leaflet.a11y",
                "leaflet.translate",
                "stimulus-use/hotkeys",
            ],
            exclude: [],
            // Force reoptimization in development
            force: isDevelopment && process.env.VITE_FORCE_DEPS === "true",
        },
        plugins: [
            // no point doing gc in such a short lived process
            Erb({env: {RUBYOPT: "--yjit --yjit-exec-mem-size=2 --yjit-call-threshold=1 --yjit-cold-threshold=1000000 --yjit-code-gc", DISABLE_SPRING: '0'}}),
            coffeescript(),
            rubyPlugin(),
            stimulusHMR(),
            fullReload(["config/routes.rb", "app/views/**/*"]),
            typehintPlugin,
            preserveAllComments(),
        ],
    };
});
