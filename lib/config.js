/*
 * Create and export configuration variables
 *
 */

// Container for all the environments
var fs = require("fs");
var path = require("path");

var environments = {};
var DEFAULT_ENV = "staging";

// Path to your .env file
var envFilePath = path.resolve(__dirname, "../.env");

// Check if the file exists
if (fs.existsSync(envFilePath)) {
  var envFileContent = fs.readFileSync(envFilePath, { encoding: "utf8" });

  // Split content into lines and parse key-value pairs
  envFileContent.split("\n").forEach((line) => {
    var [key, value] = line.split("=");
    if (key && value) {
      process.env[key.trim()] = value.trim();
    }
  });
} else {
  console.error(".env file not found!");
}

// Staging (default) environment
environments.staging = {
  httpPort: 3001,
  httpsPort: 3002,
  envName: "staging",
  hashingSecret: "thisIsASecret",
  maxChecks: 5,
  twilio: {
    accountSid: process.env.ACCOUNT_SID,
    authToken: process.env.AUTH_TOKEN,
    fromPhone: "+14125207022",
  },
};

// Production environment
environments.production = {
  httpPort: 5000,
  httpsPort: 5001,
  envName: "production",
  hashingSecret: "thisIsAlsoASecret",
  maxChecks: 5,
  twilio: {
    accountSid: process.env.ACCOUNT_SID,
    authToken: process.env.AUTH_TOKEN,
    fromPhone: "+14125207022",
  },
};

// Determine which environment was passed as a command-line argument
var currentEnvironment =
  typeof process.env.NODE_ENV === "string"
    ? process.env.NODE_ENV.toLowerCase()
    : "";

// Check that the environment is one of the environments above, if not, default to staging
var environmentToExport =
  typeof environments[currentEnvironment] === "object"
    ? environments[currentEnvironment]
    : environments[DEFAULT_ENV];

// Export the module
module.exports = environmentToExport;
