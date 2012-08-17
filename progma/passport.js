'use strict';

var crypto = require('crypto');
var FacebookStrategy = require('passport-facebook').Strategy;
var GoogleStrategy = require('passport-google').Strategy;
var LocalStrategy = require('passport-local').Strategy;
var mongo = require('./mongo').db;
var settings = require('./settings');

exports.googleAuth = function () {
  var googleOptions = {
    returnURL: settings.URL + '/auth/google/return',
    realm: settings.URL,
  };

  return new GoogleStrategy(googleOptions, function (identifier, profile, done) {
    mongo.collection('users').findOne({
      id: identifier,
    }, function (err, user) {
      if (err) {
        return done(err);
      }

      if (user) {
        return done(null, user);
      }

      profile.id = identifier;
      return done(null, profile);
    });
  });
};

exports.facebookAuth = function () {
  var facebookOptions = {
    clientID: "274343352671549",
    clientSecret: "6241e9f761c99945de8c0b24fd1558ba",
    callbackURL: settings.URL + '/auth/facebook/return',
  };

  return new FacebookStrategy(facebookOptions,
    function (accessToken, refreshToken, profile, done) {
      mongo.collection('users').findOne({
        id: profile.id,
      }, function (err, user) {
        if (err) {
          return done(err);
        }

        if (user) {
          return done(null, user);
        }

        return done(null, profile);
      });
    });
};

exports.localAuth = function () {
  return new LocalStrategy(function (username, password, done) {
    mongo.collection('users').findOne({
      id: username.toLowerCase(),
    }, function (err, user) {
      if (err) {
        return done(err);
      }

      if (!user) {
        return done(null, false, { message: 'Unknown user' });
      }

      var shasum = crypto.createHash('sha1');
      shasum.update(password);
      if (shasum.digest('hex') !== user.password) {
        return done(null, false, { message: 'Invalid password' });
      }

      return done(null, user);
    });
  });
};

exports.serializeUser = function (user, done) {
  mongo.collection('users').save(user, function (err, result) {
    return done(err, user.id);
  });
};

exports.deserializeUser = function (id, done) {
  mongo.collection('users').findOne({
    id: id,
  }, function (err, user) {
    if (err) { return done(err); }
    if (!user) {
      return done(null, false);
    }
    return done(null, user);
  });
};
