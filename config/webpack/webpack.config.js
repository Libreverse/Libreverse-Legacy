import { existsSync } from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const nodeEnv = process.env.NODE_ENV || "development";

const environmentSpecificConfig = async () => {
    const extension = ".cjs";
    const configPath = path.resolve(__dirname, `${nodeEnv}${extension}`);
    if (!existsSync(configPath)) {
        throw new Error(
            `Could not find file to load ${configPath}, based on NODE_ENV`,
        );
    }
    console.log(
        `Loading ENV specific webpack configuration file ${configPath}`,
    );
    const module_ = await import(pathToFileURL(configPath));
    return module_.default || module_;
};

export default await environmentSpecificConfig();
