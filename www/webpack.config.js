const CopyWebpackPlugin = require("copy-webpack-plugin");
const path = require('path');

module.exports = {
    performance: {
    hints: false, // Disable performance hints
  },
  experiments: {
    asyncWebAssembly: true
  },
  entry: "./bootstrap.js",
  output: {
    path: path.resolve(__dirname, "dist"),
    filename: "bootstrap.js",
  },
  //mode: "development",
  mode: "production",
  plugins: [
    new CopyWebpackPlugin({ patterns: ['index.html'] })
  ],
};
