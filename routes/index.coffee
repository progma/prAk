crypto = require('crypto')
settings = require('../progma/settings')
db = require('../progma/mongo').db
userCodeCollection = db.collection('userCode')


exports.index = (req, res) ->
  res.render 'index',
    title: 'prAk » programátorská akademie'
    page: 'index'
    user: req.user
    errors: req.flash 'error'

exports.aboutUs  = (req, res) ->
  res.render 'about-us',
    title: 'prAk » O nás'
    page: 'about-us'
    user: req.user
    errors: req.flash 'error'

#
# Sandbox
#
renderSandbox = (req, res, code, mode, warn, codeID) ->
  res.render 'sandbox',
    title: 'prAk » Pískoviště'
    page: 'sandbox'
    code: code
    mode: mode
    warn: warn
    codeID: codeID
    user: req.user
    errors: req.flash 'error'

exports.sandbox = (req, res) ->
  codeID = req.param "codeID"

  if codeID? && codeID != ""
    try
      maybeID = db.ObjectID.createFromHexString(codeID)
    catch e
      return res.send 404

    userCodeCollection.findOne { _id: maybeID }, (err, codeObj) ->
      return res.send 500   if err?
      return res.send 404   if codeObj == null

      # Show warning for code from other users.
      warn = not req.user? ||
             codeObj.user_id != req.user.id ||
             codeObj.user_id == ""

      renderSandbox req, res, codeObj.code, codeObj.mode, warn, codeID
  else
    renderSandbox req, res, "", "", false, ""
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
    title: 'prAk » název kurzu' # TODO
    page: 'course'
    user: req.user
    codes: codes
    lecturesDone: JSON.stringify(lecturesDone)
    courseName: courseName
    errors: req.flash 'error'

exports.course = (req, res) ->
  if req.user?
    userCodeCollection.group ["lecture"]
      , { course: req.param('courseName'), user_id: req.user.id }
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
    title: 'prAk » Přihlášení'
    page: 'login'
    user: req.user
    errors: req.flash 'error'

exports.get_register = (req, res) ->
  res.render 'register',
    title: 'prAk » Registrace'
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
