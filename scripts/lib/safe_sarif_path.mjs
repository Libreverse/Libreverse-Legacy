import { basename, resolve } from "node:path";

const SARIF_SOCKET_RESULTS = "socket-results.sarif";
const SARIF_SOCKET_FULL = "socket-full.sarif";

/**
 * Map argv to an allowlisted SARIF file name (literals only — breaks path traversal taint).
 */
export function cliSarifFileName(defaultFileName) {
    const fromArgv = process.argv[2] ? basename(process.argv[2]) : defaultFileName;

    if (fromArgv === SARIF_SOCKET_RESULTS) return SARIF_SOCKET_RESULTS;
    if (fromArgv === SARIF_SOCKET_FULL) return SARIF_SOCKET_FULL;

    throw new Error(
        `Unsupported SARIF file: ${fromArgv}. Allowed: ${SARIF_SOCKET_RESULTS}, ${SARIF_SOCKET_FULL}`,
    );
}

export function resolveAllowedSarifPath(fileName) {
    if (fileName === SARIF_SOCKET_RESULTS) {
        return resolve(process.cwd(), SARIF_SOCKET_RESULTS);
    }
    if (fileName === SARIF_SOCKET_FULL) {
        return resolve(process.cwd(), SARIF_SOCKET_FULL);
    }

    throw new Error(`Unsupported SARIF file: ${fileName}`);
}
