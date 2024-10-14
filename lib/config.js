/*
 * Create and export configuration variables
 *
 */

// Container for all the environments
var environments = {};
const DEFAULT_ENV = "staging";

// Staging (default) environment
environments.staging = {
  httpPort: 3001,
  httpsPort: 3002,
  envName: "staging",
  hashingSecret: "thisIsASecret",
  maxChecks: 5,
  twilio: {
    accountSid: "",
    authToken: "",
    fromPhone: "",
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
    accountSid: "",
    authToken: "",
    fromPhone: "",
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
