var crypto = require("crypto");
var queryString = require("querystring");
var https = require("https");
var config = require("./config");

var helpers = {};

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
      To: toPhoneNumber,
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
        console.log("Response:", resData);
        var status = res.statusCode;
        if (status === 200 || status === 201) {
          callback(false);
        } else {
          callback("Status code returned was " + status + " - " + resData);
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

module.exports = helpers;
