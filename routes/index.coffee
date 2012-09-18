crypto = require('crypto')
settings = require('../progma/settings')
db = require('../progma/mongo').db
userCodeCollection = db.collection('userCode')


exports.index = (req, res) ->
  res.render 'index',
    title: 'prAk – programátorská akademie'
    page: 'index'
    user: req.user
    errors: req.flash 'error'

#
# Sandbox
#
renderSandbox = (req, res, code, mode) ->
  res.render 'sandbox',
    title: 'prAk – programátorská akademie'
    page: 'sandbox'
    code: code
    mode: mode
    user: req.user
    errors: req.flash 'error'

exports.sandbox = (req, res) ->
  codeID = req.param "codeID"
  console.dir codeID

  if codeID? && codeID != ""
    userCodeCollection.findOne { _id: db.ObjectID.createFromHexString(codeID) }
    , (err, codeObj) ->
      if err?
        return res.redirect 404

      renderSandbox req, res, codeObj.code, codeObj.mode
  else
    renderSandbox req, res, "", ""
#
# Course page
#
reduceUC = (obj, prev) ->
  if obj.date > prev.date
    prev.date = obj.date
    prev.code = obj.code

renderCourse = (req, res, codes) ->
  courseName = req.param('courseName')
  if req.user? && req.user.lecturesDone?
    lecturesDone = req.user.lecturesDone[courseName]

  unless lecturesDone?
    lecturesDone = []

  res.render 'course',
    title: 'prAk » název kurzu'
    page: 'course'
    user: req.user
    codes: codes
    lecturesDone: JSON.stringify(lecturesDone)
    serverURL: settings.URL
    courseName: courseName
    errors: req.flash 'error'

exports.course = (req, res) ->
  console.log "requesting course"
  if req.user?
    userCodeCollection.group ["lecture"]
      , { course: req.param('courseName') }
      , { code: "", date: 0 }
      , reduceUC.toString()
      , true
      , (err, codes) ->
        codesN = {}
        codesN[o.lecture] = o.code for o in codes
        renderCourse req, res, JSON.stringify(codesN)
  else
    renderCourse req, res, "[]"

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
  db.collection('users').findOne { id: username }, (err, user) ->
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
    db.collection('users').save new_user, (err, result) ->
      # Server error.
      if err?
        return res.redirect 500

      # Authenticate new user immediately.
      passport.authenticate('local',
        successRedirect: '/'
        failureRedirect: '/register'
        failureFlash: true
      )(req, res, next)
