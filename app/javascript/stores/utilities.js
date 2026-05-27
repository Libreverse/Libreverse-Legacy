// Store utilities and migration helpers
import {
    themeStore,
    glassConfigStore,
    navigationStore,
    instanceSettingsStore,
    toastStore,
    experienceStore,
    searchStore,
} from "../stores";

const UNSAFE_PROPERTY_KEYS = new Set([
    "__proto__",
    "constructor",
    "prototype",
]);

function isPlainObject(value) {
    return value !== null && typeof value === "object" && !Array.isArray(value);
}

function safeShallowMerge(base, patch) {
    const merged = { ...base };
    for (const key of Object.keys(patch)) {
        if (UNSAFE_PROPERTY_KEYS.has(key)) continue;
        merged[key] = patch[key];
    }
    return merged;
}

/**
 * Store Management Utilities
 * Provides helper functions for managing stimulus-store state
 */

export class StoreManager {
    constructor() {
        this.stores = {
            theme: themeStore,
            glassConfig: glassConfigStore,
            navigation: navigationStore,
            instanceSettings: instanceSettingsStore,
            toast: toastStore,
            experience: experienceStore,
            search: searchStore,
        };
    }

    // Get all store values
    getAllStoreValues() {
        const values = {};
        for (const key of Object.keys(this.stores)) {
            values[key] = this.stores[key].value;
        }
        return values;
    }

    // Reset all stores to initial values
    resetAllStores() {
        for (const store of Object.values(this.stores)) {
            store.value = store.initialValue;
        }
    }

    // Export store state to JSON
    exportStoreState() {
        return JSON.stringify(this.getAllStoreValues(), undefined, 2);
    }

    // Import store state from JSON
    importStoreState(jsonString) {
        try {
            const state = JSON.parse(jsonString);
            if (!isPlainObject(state)) {
                return false;
            }

            for (const key of Object.keys(this.stores)) {
                if (!Object.hasOwn(state, key)) continue;

                const patch = state[key];
                if (!isPlainObject(patch)) continue;

                this.stores[key].value = safeShallowMerge(
                    this.stores[key].value,
                    patch,
                );
            }
            return true;
        } catch (error) {
            console.error("Failed to import store state:", error);
            return false;
        }
    }

    // Save store state to localStorage
    saveToLocalStorage(key = "libreverse-store-state") {
        try {
            localStorage.setItem(key, this.exportStoreState());
            return true;
        } catch (error) {
            console.error("Failed to save store state:", error);
            return false;
        }
    }

    // Load store state from localStorage
    loadFromLocalStorage(key = "libreverse-store-state") {
        try {
            const state = localStorage.getItem(key);
            if (state) {
                return this.importStoreState(state);
            }
            return false;
        } catch (error) {
            console.error("Failed to load store state:", error);
            return false;
        }
    }

    // Subscribe to store changes
    subscribeToStore(storeName, callback) {
        const store = this.stores[storeName];
        if (!store) {
            console.warn(`Store "${storeName}" not found`);
            return;
        }

        const handleChange = (event) => {
            callback(event.detail.value, event.detail.previousValue);
        };

        document.addEventListener(`${storeName}Store:changed`, handleChange);

        return () => {
            document.removeEventListener(
                `${storeName}Store:changed`,
                handleChange,
            );
        };
    }

    // Batch update multiple stores
    batchUpdateStores(updates) {
        if (!isPlainObject(updates)) return;

        for (const storeName of Object.keys(this.stores)) {
            if (!Object.hasOwn(updates, storeName)) continue;

            const patch = updates[storeName];
            if (!isPlainObject(patch)) continue;

            this.stores[storeName].value = safeShallowMerge(
                this.stores[storeName].value,
                patch,
            );
        }
    }

    // Get store by name
    getStore(name) {
        return this.stores[name];
    }

    // Check if store exists
    hasStore(name) {
        return name in this.stores;
    }
}

/**
 * Migration helpers for existing controllers
 */

export class ControllerMigrationHelper {
    constructor(controller) {
        this.controller = controller;
        this.storeManager = new StoreManager();
    }

    // Migrate existing controller values to stores
    migrateControllerValues() {
        // Migrate glass controller values
        if (this.controller.hasGlassValues) {
            this.migrateGlassValues();
        }

        // Migrate navigation values
        if (this.controller.hasNavValues) {
            this.migrateNavValues();
        }

        // Migrate instance settings values
        if (this.controller.hasInstanceSettingsValues) {
            this.migrateInstanceSettingsValues();
        }
    }

    migrateGlassValues() {
        const glassStore = this.storeManager.getStore("glassConfig");
        const updates = {};

        // Map controller values to store
        if (this.controller.borderRadiusValue !== undefined) {
            updates.borderRadius = this.controller.borderRadiusValue;
        }
        if (this.controller.tintOpacityValue !== undefined) {
            updates.tintOpacity = this.controller.tintOpacityValue;
        }
        if (this.controller.glassTypeValue !== undefined) {
            updates.glassType = this.controller.glassTypeValue;
        }
        if (this.controller.parallaxSpeedValue !== undefined) {
            updates.parallaxSpeed = this.controller.parallaxSpeedValue;
        }
        if (this.controller.parallaxOffsetValue !== undefined) {
            updates.parallaxOffset = this.controller.parallaxOffsetValue;
        }
        if (this.controller.syncWithParallaxValue !== undefined) {
            updates.syncWithParallax = this.controller.syncWithParallaxValue;
        }
        if (this.controller.backgroundParallaxSpeedValue !== undefined) {
            updates.backgroundParallaxSpeed =
                this.controller.backgroundParallaxSpeedValue;
        }

        if (Object.keys(updates).length > 0) {
            glassStore.value = { ...glassStore.value, ...updates };
        }
    }

    migrateNavValues() {
        const navStore = this.storeManager.getStore("navigation");
        const updates = {};

        if (this.controller.navItemsValue !== undefined) {
            updates.navItems = this.controller.navItemsValue;
        }

        if (Object.keys(updates).length > 0) {
            navStore.value = { ...navStore.value, ...updates };
        }
    }

    migrateInstanceSettingsValues() {
        const settingsStore = this.storeManager.getStore("instanceSettings");
        const updates = {};

        // Map form values to store
        const formData = this.getFormData();
        if (formData) {
            Object.assign(updates, formData);
        }

        if (Object.keys(updates).length > 0) {
            settingsStore.value = { ...settingsStore.value, ...updates };
        }
    }

    getFormData() {
        const form =
            this.controller.element.closest("form") || this.controller.element;
        if (!form) return;

        const formData = new FormData(form);
        const data = {};

        for (const [key, value] of formData.entries()) {
            data[key] = value;
        }

        return data;
    }
}

/**
 * Toast management utilities
 */

export class ToastManager {
    constructor() {
        this.toastStore = toastStore;
    }

    show(message, type = "info", options = {}) {
        const currentToasts = this.toastStore.value;
        const newToast = {
            id: currentToasts.nextId,
            message,
            type,
            timeout: options.timeout || currentToasts.defaultTimeout,
            timestamp: Date.now(),
            ...options,
        };

        // Limit number of toasts
        let updatedToasts = [...currentToasts.toasts, newToast];
        if (updatedToasts.length > currentToasts.maxToasts) {
            updatedToasts = updatedToasts.slice(-currentToasts.maxToasts);
        }

        this.toastStore.value = {
            ...currentToasts,
            toasts: updatedToasts,
            nextId: currentToasts.nextId + 1,
        };

        return newToast.id;
    }

    remove(toastId) {
        const currentToasts = this.toastStore.value;
        this.toastStore.value = {
            ...currentToasts,
            toasts: currentToasts.toasts.filter(
                (toast) => toast.id !== toastId,
            ),
        };
    }

    clear() {
        const currentToasts = this.toastStore.value;
        this.toastStore.value = {
            ...currentToasts,
            toasts: [],
        };
    }

    success(message, options = {}) {
        return this.show(message, "success", options);
    }

    error(message, options = {}) {
        return this.show(message, "error", options);
    }

    warning(message, options = {}) {
        return this.show(message, "warning", options);
    }

    info(message, options = {}) {
        return this.show(message, "info", options);
    }
}

/**
 * Theme management utilities
 */

export class ThemeManager {
    constructor() {
        this.themeStore = themeStore;
    }

    toggleDarkMode() {
        const currentTheme = this.themeStore.value;
        this.themeStore.value = {
            ...currentTheme,
            darkMode: !currentTheme.darkMode,
        };
    }

    toggleGlass() {
        const currentTheme = this.themeStore.value;
        this.themeStore.value = {
            ...currentTheme,
            glassEnabled: !currentTheme.glassEnabled,
        };
    }

    toggleAnimations() {
        const currentTheme = this.themeStore.value;
        this.themeStore.value = {
            ...currentTheme,
            animationsEnabled: !currentTheme.animationsEnabled,
        };
    }

    toggleParallax() {
        const currentTheme = this.themeStore.value;
        this.themeStore.value = {
            ...currentTheme,
            parallaxEnabled: !currentTheme.parallaxEnabled,
        };
    }

    setTheme(themeName) {
        const currentTheme = this.themeStore.value;
        this.themeStore.value = {
            ...currentTheme,
            currentTheme: themeName,
        };
    }

    getCurrentTheme() {
        return this.themeStore.value;
    }

    isDarkMode() {
        return this.themeStore.value.darkMode;
    }

    isGlassEnabled() {
        return this.themeStore.value.glassEnabled;
    }

    areAnimationsEnabled() {
        return this.themeStore.value.animationsEnabled;
    }

    isParallaxEnabled() {
        return this.themeStore.value.parallaxEnabled;
    }
}

// Export singleton instances
export const storeManager = new StoreManager();
export const toastManager = new ToastManager();
export const themeManager = new ThemeManager();

// Export utility functions
export const createMigrationHelper = (controller) =>
    new ControllerMigrationHelper(controller);

// Global store access (for debugging)
if (typeof globalThis !== "undefined") {
    globalThis.LibreverseStores = {
        stores: storeManager.stores,
        manager: storeManager,
        toast: toastManager,
        theme: themeManager,
    };
}
