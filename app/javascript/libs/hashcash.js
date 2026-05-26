// http://www.hashcash.org/docs/hashcash.html
// based on and compatible with https://github.com/BaseSecrete/active_hashcash. See license below.
/*
The MIT License (MIT)

Copyright (c) 2022 Alexis Bernard

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

// Declare Hashcash as a global variable to avoid "not defined" errors
globalThis.Hashcash = function (input) {
    this.input = input;
    this.options = JSON.parse(input.dataset.hashcash);

    // Start computing immediately when instantiated
    this.computeHashcash();

    // Add listener to handle form submission with hashcash validation
    this.boundOnFormSubmit = this.onFormSubmit.bind(this);
    input.form.addEventListener("submit", this.boundOnFormSubmit);
};

globalThis.Hashcash.prototype.computeHashcash = function () {
    const input = this.input;
    const options = this.options;

    // Clear existing value and mark as fresh
    input.value = "";
    input.dataset.hashcashUsed = "false";

    globalThis.Hashcash.disableParentForm(input, options);
    input.dispatchEvent(new CustomEvent("hashcash:mint", { bubbles: true }));

    globalThis.Hashcash.mint(options.resource, options, function (stamp) {
        input.value = stamp.toString();
        input.dataset.hashcashGeneratedAt = Date.now().toString();
        input.dataset.hashcashUsed = "false";

        globalThis.Hashcash.enableParentForm(input, options);
        input.dispatchEvent(
            new CustomEvent("hashcash:minted", {
                bubbles: true,
                detail: { stamp: stamp },
            }),
        );

        console.log("[Hashcash] New stamp generated:", stamp.toString());
    });
};

globalThis.Hashcash.prototype.onFormSubmit = function (event) {
    // Always prevent the first submission to ensure fresh hashcash
    event.preventDefault();

    // If hashcash is empty or potentially stale, generate a new one
    if (!this.input.value || this.input.value === "" || this.isStampStale()) {
        console.log("[Hashcash] Generating new stamp for submission");
        this.computeHashcash();
        return false;
    }

    // If we have a fresh stamp, allow the form to submit naturally
    console.log("[Hashcash] Using fresh stamp:", this.input.value);
    this.markStampAsUsed();

    // Remove the event listener to prevent interference and resubmit
    this.input.form.removeEventListener("submit", this.boundOnFormSubmit);

    // Trigger the form submission programmatically
    setTimeout(() => {
        this.input.form.submit();
    }, 10);

    return false;
};

globalThis.Hashcash.prototype.isStampStale = function () {
    // Consider a stamp stale if it was marked as used or is more than 30 seconds old
    if (this.input.dataset.hashcashUsed === "true") {
        return true;
    }

    if (this.input.dataset.hashcashGeneratedAt) {
        const generatedAt = Number.parseInt(
            this.input.dataset.hashcashGeneratedAt,
        );
        const now = Date.now();
        return now - generatedAt > 30_000; // 30 seconds
    }

    return false;
};

globalThis.Hashcash.prototype.markStampAsUsed = function () {
    this.input.dataset.hashcashUsed = "true";
};

globalThis.Hashcash.setup = function () {
    if (document.readyState == "loading") {
        document.addEventListener(
            "DOMContentLoaded",
            globalThis.Hashcash.setup,
        );
    } else {
        var input = document.querySelector("input[name='hashcash']");
        if (input) {
            new globalThis.Hashcash(input);
        }
    }

    // Also set up for any new hashcash inputs that might be added via Turbo navigation
    document.addEventListener("turbo:load", function () {
        var input = document.querySelector("input[name='hashcash']");
        if (input && !input.dataset.hashcashInitialized) {
            input.dataset.hashcashInitialized = "true";
            new globalThis.Hashcash(input);
        }
    });
};

globalThis.Hashcash.setSubmitText = function (submit, text) {
    if (!text) {
        return;
    }
    if (submit.tagName == "BUTTON") {
        !submit.originalValue && (submit.originalValue = submit.textContent);
        submit.textContent = text;
    } else {
        !submit.originalValue && (submit.originalValue = submit.value);
        submit.value = text;
    }
};

globalThis.Hashcash.disableParentForm = function (input, options) {
    for (const submit of input.form.querySelectorAll("[type=submit]")) {
        globalThis.Hashcash.setSubmitText(submit, options["waiting_message"]);
        submit.disabled = true;
    }
};

globalThis.Hashcash.enableParentForm = function (input) {
    for (const submit of input.form.querySelectorAll("[type=submit]")) {
        globalThis.Hashcash.setSubmitText(submit, submit.originalValue);
        submit.disabled = undefined;
    }
};

globalThis.Hashcash.prototype.preventFromAutoSubmitFromPasswordManagers =
    function (event) {
        this.input.value == "" && event.preventDefault();
    };

globalThis.Hashcash.default = {
    version: 1,
    bits: 20,
    extension: undefined,
};

globalThis.Hashcash.mint = function (resource, options, callback) {
    // Format date to YYMMDD
    var date = new Date();
    var year = date.getFullYear().toString();
    year = year.slice(-2);
    var month = (date.getMonth() + 1).toString().padStart(2, "0");
    var day = date.getDate().toString().padStart(2, "0");

    // Generate a more unique random string using timestamp + random
    var uniqueRand =
        options.rand ||
        (Date.now().toString(36) + Math.random().toString(36)).slice(2, 12);

    var stamp = new globalThis.Hashcash.Stamp(
        options.version || globalThis.Hashcash.default.version,
        options.bits || globalThis.Hashcash.default.bits,
        options.date || year + month + day,
        resource,
        options.extension || globalThis.Hashcash.default.extension,
        uniqueRand,
    );
    return stamp.work(callback);
};

globalThis.Hashcash.Stamp = function (
    version,
    bits,
    date,
    resource,
    extension,
    rand,
    counter = 0,
) {
    this.version = version;
    this.bits = bits;
    this.date = date;
    this.resource = resource;
    this.extension = extension;
    this.rand = rand;
    this.counter = counter;
};

globalThis.Hashcash.Stamp.parse = function (string) {
    var arguments_ = string.split(":");
    return new globalThis.Hashcash.Stamp(
        arguments_[0],
        arguments_[1],
        arguments_[2],
        arguments_[3],
        arguments_[4],
        arguments_[5],
        arguments_[6],
    );
};

globalThis.Hashcash.Stamp.prototype.toString = function () {
    return [
        this.version,
        this.bits,
        this.date,
        this.resource,
        this.extension,
        this.rand,
        this.counter,
    ].join(":");
};

// Trigger the given callback when the problem is solved.
// In order to not freeze the page, setTimeout is called every 100ms to let some CPU to other tasks.
globalThis.Hashcash.Stamp.prototype.work = function (callback) {
    this.startClock();
    var timer = performance.now();
    while (!this.check())
        if (this.counter++ && performance.now() - timer > 100)
            return setTimeout(this.work.bind(this), 0, callback);
    this.stopClock();
    callback(this);
};

globalThis.Hashcash.Stamp.prototype.check = function () {
    var array = globalThis.Hashcash.sha1(this.toString());
    return array[0] >> (160 - this.bits) == 0;
};

globalThis.Hashcash.Stamp.prototype.startClock = function () {
    this.startedAt || (this.startedAt = performance.now());
};

globalThis.Hashcash.Stamp.prototype.stopClock = function () {
    this.endedAt || (this.endedAt = performance.now());
    var duration = this.endedAt - this.startedAt;
    var speed = Math.round((this.counter * 1000) / duration);
    console.debug(
        "Hashcash " +
            this.toString() +
            " minted in " +
            duration +
            "ms (" +
            speed +
            " per seconds)",
    );
};

/**
 * Secure Hash Algorithm (SHA1)
 * http://www.webtoolkit.info/
 **/
globalThis.Hashcash.sha1 = function (message) {
    var rotate_left = globalThis.Hashcash.sha1.rotate_left;
    var Utf8Encode = globalThis.Hashcash.sha1.Utf8Encode;

    var blockstart;
    var index, index_;
    var W = Array.from({ length: 80 });
    var H0 = 0x67_45_23_01;
    var H1 = 0xef_cd_ab_89;
    var H2 = 0x98_ba_dc_fe;
    var H3 = 0x10_32_54_76;
    var H4 = 0xc3_d2_e1_f0;
    var A, B, C, D, E;
    var temporary;
    message = Utf8Encode(message);
    var message_length = message.length;
    var word_array = new Array();
    for (index = 0; index < message_length - 3; index += 4) {
        index_ =
            (message.codePointAt(index) << 24) |
            (message.codePointAt(index + 1) << 16) |
            (message.codePointAt(index + 2) << 8) |
            message.codePointAt(index + 3);
        word_array.push(index_);
    }
    switch (message_length % 4) {
        case 0: {
            index = 0x0_80_00_00_00;
            break;
        }
        case 1: {
            index =
                (message.codePointAt(message_length - 1) << 24) | 0x0_80_00_00;
            break;
        }
        case 2: {
            index =
                (message.codePointAt(message_length - 2) << 24) |
                (message.codePointAt(message_length - 1) << 16) |
                0x0_80_00;
            break;
        }
        case 3: {
            index =
                (message.codePointAt(message_length - 3) << 24) |
                (message.codePointAt(message_length - 2) << 16) |
                (message.codePointAt(message_length - 1) << 8) |
                0x80;
            break;
        }
    }
    word_array.push(index);
    while (word_array.length % 16 != 14) word_array.push(0);
    word_array.push(
        message_length >>> 29,
        (message_length << 3) & 0x0_ff_ff_ff_ff,
    );
    for (blockstart = 0; blockstart < word_array.length; blockstart += 16) {
        for (index = 0; index < 16; index++)
            W[index] = word_array[blockstart + index];
        for (index = 16; index <= 79; index++)
            W[index] = rotate_left(
                W[index - 3] ^ W[index - 8] ^ W[index - 14] ^ W[index - 16],
                1,
            );
        A = H0;
        B = H1;
        C = H2;
        D = H3;
        E = H4;
        for (index = 0; index <= 19; index++) {
            temporary =
                (rotate_left(A, 5) +
                    ((B & C) | (~B & D)) +
                    E +
                    W[index] +
                    0x5a_82_79_99) &
                0x0_ff_ff_ff_ff;
            E = D;
            D = C;
            C = rotate_left(B, 30);
            B = A;
            A = temporary;
        }
        for (index = 20; index <= 39; index++) {
            temporary =
                (rotate_left(A, 5) +
                    (B ^ C ^ D) +
                    E +
                    W[index] +
                    0x6e_d9_eb_a1) &
                0x0_ff_ff_ff_ff;
            E = D;
            D = C;
            C = rotate_left(B, 30);
            B = A;
            A = temporary;
        }
        for (index = 40; index <= 59; index++) {
            temporary =
                (rotate_left(A, 5) +
                    ((B & C) | (B & D) | (C & D)) +
                    E +
                    W[index] +
                    0x8f_1b_bc_dc) &
                0x0_ff_ff_ff_ff;
            E = D;
            D = C;
            C = rotate_left(B, 30);
            B = A;
            A = temporary;
        }
        for (index = 60; index <= 79; index++) {
            temporary =
                (rotate_left(A, 5) +
                    (B ^ C ^ D) +
                    E +
                    W[index] +
                    0xca_62_c1_d6) &
                0x0_ff_ff_ff_ff;
            E = D;
            D = C;
            C = rotate_left(B, 30);
            B = A;
            A = temporary;
        }
        H0 = (H0 + A) & 0x0_ff_ff_ff_ff;
        H1 = (H1 + B) & 0x0_ff_ff_ff_ff;
        H2 = (H2 + C) & 0x0_ff_ff_ff_ff;
        H3 = (H3 + D) & 0x0_ff_ff_ff_ff;
        H4 = (H4 + E) & 0x0_ff_ff_ff_ff;
    }
    return [H0, H1, H2, H3, H4];
};

globalThis.Hashcash.hexSha1 = function (message) {
    var array = globalThis.Hashcash.sha1(message);
    var cvt_hex = globalThis.Hashcash.sha1.cvt_hex;
    return (
        cvt_hex(array[0]) +
        cvt_hex(array[1]) +
        cvt_hex(array[2]) +
        cvt_hex(array[3]) +
        cvt_hex(array[4])
    );
};

globalThis.Hashcash.sha1.rotate_left = function (n, s) {
    var t4 = (n << s) | (n >>> (32 - s));
    return t4;
};

globalThis.Hashcash.sha1.lsb_hex = function (value) {
    var string_ = "";
    var index;
    var vh;
    var vl;
    for (index = 0; index <= 6; index += 2) {
        vh = (value >>> (index * 4 + 4)) & 0x0f;
        vl = (value >>> (index * 4)) & 0x0f;
        string_ += vh.toString(16) + vl.toString(16);
    }
    return string_;
};

globalThis.Hashcash.sha1.cvt_hex = function (value) {
    var string_ = "";
    var index;
    var v;
    for (index = 7; index >= 0; index--) {
        v = (value >>> (index * 4)) & 0x0f;
        string_ += v.toString(16);
    }
    return string_;
};

globalThis.Hashcash.sha1.Utf8Encode = function (string) {
    string = string.replaceAll("\r\n", "\n");
    var utftext = "";
    for (var n = 0; n < string.length; n++) {
        var c = string.codePointAt(n);
        if (c < 128) {
            utftext += String.fromCodePoint(c);
        } else if (c > 127 && c < 2048) {
            utftext += String.fromCodePoint((c >> 6) | 192);
            utftext += String.fromCodePoint((c & 63) | 128);
        } else {
            utftext += String.fromCodePoint((c >> 12) | 224);
            utftext += String.fromCodePoint(((c >> 6) & 63) | 128);
            utftext += String.fromCodePoint((c & 63) | 128);
        }
    }
    return utftext;
};

globalThis.Hashcash.setup();
