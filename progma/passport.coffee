crypto = require 'crypto'
FacebookStrategy = require('passport-facebook').Strategy
GoogleStrategy = require('passport-google').Strategy
LocalStrategy = require('passport-local').Strategy
mongo = require('./mongo').db
settings = require './settings'


# Use Google for authentification.
exports.googleAuth = ->
  googleOptions =
    # Where should user return after confirming authentification.
    returnURL: settings.URL + '/auth/google/return'
    # Which domain will be able access the user account.
    realm: settings.URL

  return new GoogleStrategy googleOptions, (identifier, profile, done) ->
    # Check if the user is already in our database.
    mongo.collection('users').findOne { id: identifier }, (err, user) ->
      # Server error.
      if err?
        return done err

      # User exists, return profile from database.
      if user?
        return done null, user

      # Create a new user.
      profile.id = identifier
      return done null, profile


# Use Facebook for authentification
exports.facebookAuth = ->
  facebookOptions =
    # Our application ID.
    clientID: "274343352671549"
    # Our application secret.
    clientSecret: settings.FACEBOOK_SECRET
    # Where should user return after confirming authentification.
    callbackURL: settings.URL + '/auth/facebook/return'

  return new FacebookStrategy facebookOptions,
    (accessToken, refreshToken, profile, done) ->
      # Check if the user is already in our database.
      mongo.collection('users').findOne { id: profile.id }, (err, user) ->
        # Server error.
        if err?
          return done err

        # User exists, return profile from database.
        if user?
          return done null, user

        # Create a new user.
        return done null, profile


# Use email and password for authentification.
exports.localAuth = ->
  return new LocalStrategy (username, password, done) ->
    mongo.collection('users').findOne { id: username.toLowerCase() },
      (err, user) ->
        # Server error.
        if err?
          return done err

        # User doesn't exist.
        unless user?
          return done null, false, { message: 'Unknown user' }

        # Check password.
        shasum = crypto.createHash 'sha1'
        shasum.update password
        if shasum.digest('hex') != user.password
          return done null, false, { message: 'Invalid password' }

        # Return user profile.
        return done null, user


# Serialize user from session to database.
exports.serializeUser = (user, done) ->
  mongo.collection('users').save user, (err, result) ->
    return done err, user.id

# Deserialize user from database to session.
exports.deserializeUser = (id, done) ->
  mongo.collection('users').findOne { id: id }, (err, user) ->
    # Server error.
    if err?
      return done err

    # User doesn't exist.
    unless user?
      return done null, false

    # Return user profile.
    return done null, user
