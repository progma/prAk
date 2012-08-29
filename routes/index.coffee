crypto = require('crypto')
mongo = require('../progma/mongo').db

exports.index = (req, res) ->
  res.render 'index',
    title: 'prAk – programátorská akademie'
    page: 'index'
    user: req.user
    errors: req.flash 'error'

exports.course = (req, res) ->
  res.render 'course',
    title: 'prAk » název kurzu'
    page: 'course'
    user: req.user
    courseName: req.courseName
    errors: req.flash 'error'

exports.login = (req, res) ->
  res.render 'login',
    title: 'Login'
    page: 'login'
    user: req.user
    errors: req.flash 'error'

exports.get_register = (req, res) ->
  res.render 'register',
    title: 'Registration'
    page: 'registration'
    user: req.user
    errors: req.flash 'error'

# Handle registration request.
exports.post_register = (req, res, next, passport) ->
  # Convert username to lowercase.
  username = req.body.username.toLowerCase()

  # Check if the username already exists.
  mongo.collection('users').findOne { id: username }, (err, user) ->
    # Server error.
    if err?
      return res.redirect 500

    # User already exists.
    if user?
      req.flash 'error', 'User already exists.'
      return res.redirect '/login'

    # Compute password hash.
    shasum = crypto.createHash 'sha1'
    shasum.update req.body.password

    # Create new user profile.
    new_user =
      id: username
      displayName: req.body.username
      password: shasum.digest 'hex'

    # Insert new user to database.
    mongo.collection('users').save new_user, (err, result) ->
      # Server error.
      if err?
        return res.redirect 500

      # Authenticate new user immediately.
      passport.authenticate('local',
        successRedirect: '/'
        failureRedirect: '/register'
        failureFlash: true
      )(req, res, next)
