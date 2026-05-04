const generateWebpackConfigs = require("./generateWebpackConfigs.cjs");

const productionEnvironmentOnly = (clientConfig, serverConfig) => {
    clientConfig.devtool = false;
    serverConfig.devtool = false;
};

module.exports = generateWebpackConfigs(productionEnvironmentOnly);
