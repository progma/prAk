users = require '../progma/users'
db = require('../progma/mongo').db
db.bind('userCode')
db.bind('log')

getUserID = (req) ->
  if req.user? then req.user.id else ""

exports.userCode = (req, res) ->
  if req.body?.code
    codeObj =
      user_id: getUserID req
      date: new Date()
      code: req.body.code
      lecture: req.body.lecture ? ""
      course: req.body.course ? "sandbox"
      mode: req.body.mode

    db.userCode.insert codeObj, (err) ->
      if err?
        console.log "problem during saving codeObj"

    # TODO code from unregistered users mark with session id

  res.send 200

exports.badget = (req, res) ->
  if req.user?
    unless req.user.achievements
      req.user.achievements = []

    unless req.body.name in req.user.achievements
      req.user.achievements.push req.body.name

    users.updateUser req.user

  res.send 200

exports.lectureDone = (req, res) ->
  if req.user?
    unless req.user.lecturesDone
      req.user.lecturesDone = {}

    unless req.user.lecturesDone[req.body.course]
      req.user.lecturesDone[req.body.course] = []

    unless req.body.lecture in req.user.lecturesDone[req.body.course]
      req.user.lecturesDone[req.body.course].push req.body.lecture

    users.updateUser(req.user, ->)

  res.send 200

exports.log = (req, res) ->
  db.log.insert
    user_id: getUserID req
    type: req.body.type
    content: req.body.content
    whenWhere: req.body.whenWhere
  , (err) ->
    if err?
      console.log "cannot log"

  res.send 200

# TODO deal with unregistered users via session
