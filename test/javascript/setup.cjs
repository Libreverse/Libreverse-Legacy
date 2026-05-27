/* eslint-disable no-undef */
// CommonJS setup for Jest to avoid ESM import parsing issues
// Import Jest DOM matchers
require("@testing-library/jest-dom");

// Mock Turbo's visit function which is used in many controllers
globalThis.Turbo = {
    visit: jest.fn(),
    navigator: {
        history: {
            push: jest.fn(),
        },
    },
};

// Setup localStorage mock
class LocalStorageMock {
    constructor() {
        this.store = {};
    }
    clear() {
        this.store = {};
    }
    getItem(key) {
        return this.store[key] ?? undefined;
    }
    setItem(key, value) {
        this.store[key] = String(value);
    }
    removeItem(key) {
        delete this.store[key];
    }
}

Object.defineProperty(globalThis, "localStorage", {
    value: new LocalStorageMock(),
});

// Mock XMLHttpRequest
class XMLHttpRequestMock {
    constructor() {
        this.readyState = 0;
        this.status = 0;
        this.responseType = "";
        this.responseText = "";
        this.responseXML = undefined;
        this.responseJSON = undefined;
        this.headers = {};
        this._events = {};
    }
    open() {
        this.readyState = 1;
        this._trigger("readystatechange");
    }
    setRequestHeader(header, value) {
        this.headers[header] = value;
    }
    send() {
        setTimeout(() => {
            this.readyState = 4;
            this.status = 200;
            this._trigger("readystatechange");
            this._trigger("load");
        }, 0);
    }
    addEventListener(event, callback) {
        if (!this._events[event]) this._events[event] = [];
        this._events[event].push(callback);
    }
    removeEventListener(event, callback) {
        if (!this._events[event]) return;
        this._events[event] = this._events[event].filter(
            (callback_) => callback_ !== callback,
        );
    }
    _trigger(event) {
        if (!this._events[event]) return;
        const callbacks = this._events[event];
        for (const callback of callbacks) callback.call(this);
    }
}

globalThis.XMLHttpRequest = XMLHttpRequestMock;
globalThis.Node = { ELEMENT_NODE: 1 };

// Mock console.error and console.warn to keep test output clean
console.error = jest.fn();
console.warn = jest.fn();

// Set up fake timers
jest.useFakeTimers();

// Add global custom matchers if needed
expect.extend({
    toBeWithinRange(received, floor, ceiling) {
        const pass = received >= floor && received <= ceiling;
        return pass
            ? {
                  message: () =>
                      `expected ${received} not to be within range ${floor} - ${ceiling}`,
                  pass: true,
              }
            : {
                  message: () =>
                      `expected ${received} to be within range ${floor} - ${ceiling}`,
                  pass: false,
              };
    },
});

// Clean up between tests
afterEach(() => {
    jest.clearAllMocks();
    document.body.innerHTML = "";
    globalThis.localStorage.clear();
});
