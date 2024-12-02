/*
 * Primary file for the API
 *
 */

var server = require("./lib/server");
var workers = require("./lib/workers");
var cli = require("./lib/cli");

var app = {};

app.init = function (callback) {
  server.init();

  workers.init();

  setTimeout(function () {
    cli.init();
    callback();
  }, 50);
};

if (require.main === module) {
  app.init(function () {});
}

module.exports = app;
