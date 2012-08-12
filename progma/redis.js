'use strict';

var redis = require('redis');

exports.createClient = function () {
  if (process.env.REDISTOGO_URL) {
    var rtg = require('url').parse(process.env.REDISTOGO_URL);
    var client = redis.createClient(rtg.port, rtg.hostname);

    client.auth(rtg.auth.split(":"[1]));
    return client;
  } else {
    return redis.createClient();
  }
};
