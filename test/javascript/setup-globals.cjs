/* eslint-disable no-undef */
// Runs before jsdom initializes (setupFiles, not setupFilesAfterEnv).
const { TextEncoder, TextDecoder } = require("node:util");
const {
    ReadableStream,
    WritableStream,
    TransformStream,
} = require("node:stream/web");
const { MessageChannel, MessagePort } = require("node:worker_threads");

globalThis.TextEncoder = TextEncoder;
globalThis.TextDecoder = TextDecoder;
globalThis.ReadableStream = ReadableStream;
globalThis.WritableStream = WritableStream;
globalThis.TransformStream = TransformStream;
globalThis.MessageChannel = MessageChannel;
globalThis.MessagePort = MessagePort;
