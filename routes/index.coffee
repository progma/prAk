crypto = require('crypto')
settings = require('../progma/settings')
users = require('../progma/users')
db = require('../progma/mongo').db
fs = require('fs')

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
renderSandbox = (req, res, code, mode, warn, codeID) ->
  res.render 'sandbox',
    title: 'prAk – programátorská akademie'
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
    title: 'prAk » název kurzu'
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
    title: 'Login'
    page: 'login'
    user: req.user
    errors: req.flash 'error'

exports.user = (req, res) ->
  lectures = {}
  for courseName of req.user.lecturesDone
    file = fs.readFileSync('public/courses/' + courseName + '/course.json')
    course = JSON.parse(file)

    lectures[courseName] = {readableName: course['readableName'], list: []}

    for lectureName of course['lectures']
      lecture = course['lectures'][lectureName]
      lectures[courseName]['list'].push({
        name: lecture['name']
        readableName: lecture['readableName']
        done: lecture['name'] in req.user.lecturesDone[courseName]
      })

  console.log(lectures)

  res.render 'user',
    title: 'User'
    page: 'user'
    user: req.user
    lectures: lectures
    errors: req.flash 'error'

exports.user_password = (req, res) ->
  if req.user?
    old_password = req.body.old_password
    new_password = req.body.new_password
    confirm = req.body.confirm_new_password

    users.checkPassword req.user.id, old_password, (err, correct) ->
      if correct
        users.getUser req.user.id, (err, user) ->
          # Create salt and password
          user.salt = new Date().getTime()
          user.password = users.hashPassword(user.salt, new_password)
          users.updateUser user, ->
            res.redirect '/user'
      else
        res.redirect 'back'
  else
    res.redirect 'back'

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

    salt = new Date().getTime()
    # Compute password hash.
    shasum = crypto.createHash 'sha1'
    shasum.update "" + salt
    shasum.update req.body.password
    hash = shasum.digest('hex')

    # Create new user profile.
    new_user =
      id: username
      salt: salt
      displayName: req.body.username
      password: hash

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
