var http = require("http");
var https = require("https");
var url = require("url");
var StringDecoder = require("string_decoder").StringDecoder;
var fs = require("fs");
var util = require("util");
var config = require("./config");
var handlers = require("./handlers");
var helpers = require("./helpers");
var path = require("path");
var debug = util.debuglog("server");

var server = {};

server.httpServer = http.createServer(function (req, res) {
  server.unifiedServer(req, res);
});

server.httpsServerOptions = {
  key: fs.readFileSync(path.join(__dirname, "/../https/key.pem")),
  cert: fs.readFileSync(path.join(__dirname, "/../https/cert.pe")),
};

server._httpsServerOptions = {};

server.httpsServer = https.createServer(
  server._httpsServerOptions,
  function (req, res) {
    server.unifiedServer(req, res);
  }
);

server.unifiedServer = function (req, res) {
  // Get the url and parse it
  var parsedUrl = url.parse(req.url, true);

  // Get the path
  var path = parsedUrl.pathname;
  var trimmedPath = path.replace(/^\/+|\/+$/g, "");

  // Get the query string as an object
  var queryStringObject = parsedUrl.query;

  // Get the http method
  var method = req.method.toLowerCase();

  // Get the headers as an object
  var headers = req.headers;

  // Get the payload, if any
  var decoder = new StringDecoder("utf-8");
  var buffer = "";
  req.on("data", function (data) {
    buffer += decoder.write(data);
  });

  req.on("end", function () {
    buffer += decoder.end();

    // Choose the handlers this request should go to
    var chooseHandlers =
      typeof server.router[trimmedPath] !== "undefined"
        ? server.router[trimmedPath]
        : handlers.notFound;

    // Construct the data object to send to the handlers
    var data = {
      trimmedPath: trimmedPath,
      queryStringObject: queryStringObject,
      method: method,
      headers: headers,
      payload: helpers.parseJsonToObject(buffer),
    };

    // Route the request to the handler specified to the handler
    chooseHandlers(data, function (statusCode, payload) {
      // Use the status code callback by the handler or default to 200
      statusCode = typeof statusCode === "number" ? statusCode : 200;

      // Use the payload callback by the handler or default to an empty object
      payload = typeof payload === "object" ? payload : {};

      // Convert the payload to a string
      var payloadString = JSON.stringify(payload);

      // Return the response
      res.setHeader("Content-Type", "application/json");
      res.writeHead(statusCode);
      res.end(payloadString);

      // If the response is 200, print green otherwise print red
      if (statusCode == 200) {
        debug(
          "\x1b[32m%s\x1b[0m",
          `${method.toUpperCase()} /${trimmedPath} ${statusCode}`
        );
      } else {
        debug(
          "\x1b[31m%s\x1b[0m",
          `${method.toUpperCase()} /${trimmedPath} ${statusCode}`
        );
      }
    });
  });
};

// Define a request router
server.router = {
  ping: handlers.ping,
  users: handlers.users,
  tokens: handlers.tokens,
  checks: handlers.checks,
};

server.init = function () {
  server.httpServer.listen(config.httpPort, function () {
    // Send to console, in yellow
    console.log(
      "\x1b[36m%s\x1b[0m",
      `The server is listening on port ${config.httpPort} now`
    );
  });

  server.httpsServer.listen(config.httpsPort, function () {
    console.log(
      "\x1b[35m%s\x1b[0m",
      `The server is listening on port ${config.httpsPort} now`
    );
  });
};

module.exports = server;
