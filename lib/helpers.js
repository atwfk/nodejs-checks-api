var crypto = require("crypto");
var queryString = require("querystring");
var https = require("https");
var path = require("path");
var fs = require("fs");
var config = require("./config");

var helpers = {};

helpers.getANumber = function () {
  return 1;
};

helpers.hash = function (str) {
  if (typeof str === "string" && str.length > 0) {
    var hash = crypto
      .createHmac("sha256", config.hashingSecret)
      .update(str)
      .digest("hex");
    return hash;
  } else {
    return false;
  }
};

helpers.parseJsonToObject = function (str) {
  try {
    var obj = JSON.parse(str);
    return obj;
  } catch (e) {
    return {};
  }
};

helpers.createRandomString = function (strLength) {
  strLength =
    typeof strLength === "number" && strLength > 0 ? strLength : false;
  if (strLength) {
    var possibleCharacters = "abcdefghijklmnopqrstuvwxyz0123456789";
    var str = "";

    for (i = 1; i <= strLength; i++) {
      var randomCharacter = possibleCharacters.charAt(
        Math.floor(Math.random() * possibleCharacters.length)
      );
      str += randomCharacter;
    }

    return str;
  } else {
    return false;
  }
};

helpers.sendTwilioSms = function (phone, msg, callback) {
  phone =
    typeof phone === "string" && phone.trim().length > 10
      ? phone.trim()
      : false;
  msg =
    typeof msg == "string" && msg.trim().length > 0 && msg.trim().length <= 1600
      ? msg.trim()
      : false;

  if (phone && msg) {
    var accountSid = config.twilio.accountSid;
    var authToken = config.twilio.authToken;
    var fromPhoneNumber = config.twilio.fromPhone;
    var toPhoneNumber = phone;
    var messageBody = msg;

    var auth = Buffer.from(`${accountSid}:${authToken}`).toString("base64");
    var postData = queryString.stringify({
      From: fromPhoneNumber,
      To: `+${toPhoneNumber}`,
      Body: messageBody,
    });

    var requestDetails = {
      hostname: "api.twilio.com",
      port: 443,
      path: `/2010-04-01/Accounts/${accountSid}/Messages.json`,
      method: "POST",
      headers: {
        Authorization: `Basic ${auth}`,
        "Content-Type": "application/x-www-form-urlencoded",
        "Content-Length": Buffer.byteLength(postData),
      },
    };

    var req = https.request(requestDetails, function (res) {
      var resData = "";
      res.on("data", function (chunk) {
        resData += chunk;
      });
      res.on("end", function () {
        // console.log("Response:", resData);
        var status = res.statusCode;
        if (status === 200 || status === 201) {
          callback(false);
        } else {
          callback("Status code returned was " + status);
        }
      });
    });

    req.on("error", function (e) {
      callback(e);
    });

    req.write(postData);

    req.end();
  } else {
    callback("Given parameters were missing or invalid");
  }
};

// Get the string content of a template, and use provided data for string interpolation
helpers.getTemplate = function (templateName, data, callback) {
  templateName =
    typeof templateName == "string" && templateName.length > 0
      ? templateName
      : false;
  data = typeof data == "object" && data !== null ? data : {};
  if (templateName) {
    var templatesDir = path.join(__dirname, "/../templates/");
    fs.readFile(
      templatesDir + templateName + ".html",
      "utf8",
      function (err, str) {
        if (!err && str && str.length > 0) {
          // Do interpolation on the string
          var finalString = helpers.interpolate(str, data);
          callback(false, finalString);
        } else {
          callback("No template could be found");
        }
      }
    );
  } else {
    callback("A valid template name was not specified");
  }
};

// Add the universal header and footer to a string, and pass provided data object to header and footer for interpolation
helpers.addUniversalTemplates = function (str, data, callback) {
  str = typeof str == "string" && str.length > 0 ? str : "";
  data = typeof data == "object" && data !== null ? data : {};
  // Get the header
  helpers.getTemplate("_header", data, function (err, headerString) {
    if (!err && headerString) {
      // Get the footer
      helpers.getTemplate("_footer", data, function (err, footerString) {
        if (!err && headerString) {
          // Add them all together
          var fullString = headerString + str + footerString;
          callback(false, fullString);
        } else {
          callback("Could not find the footer template");
        }
      });
    } else {
      callback("Could not find the header template");
    }
  });
};

// Take a given string and data object, and find/replace all the keys within it
helpers.interpolate = function (str, data) {
  str = typeof str == "string" && str.length > 0 ? str : "";
  data = typeof data == "object" && data !== null ? data : {};

  // Add the templateGlobals to the data object, prepending their key name with "global."
  for (var keyName in config.templateGlobals) {
    if (config.templateGlobals.hasOwnProperty(keyName)) {
      data["global." + keyName] = config.templateGlobals[keyName];
    }
  }
  // For each key in the data object, insert its value into the string at the corresponding placeholder
  for (var key in data) {
    if (data.hasOwnProperty(key) && typeof (data[key] == "string")) {
      var replace = data[key];
      var find = "{" + key + "}";
      str = str.replace(find, replace);
    }
  }
  return str;
};

helpers.getStaticAsset = function (fileName, callback) {
  fileName =
    typeof fileName == "string" && fileName.length > 0 ? fileName : false;

  if (fileName) {
    var publicDir = path.join(__dirname, "/../public/");
    fs.readFile(publicDir + fileName, function (err, data) {
      if (!err && data) {
        callback(false, data);
      } else {
        callback("No file could be found");
      }
    });
  } else {
    callback("A valid file name was not specified");
  }
};

module.exports = helpers;
