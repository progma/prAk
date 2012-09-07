users = require '../progma/users'
db = require('../progma/mongo').db
db.bind('userCode')

exports.userCode = (req, res) ->
  if req.user? && req.body?.code
    codeObj =
      user_id: req.user.id
      date: new Date()
      code: req.body.code
      lecture: req.body.lecture
      course: req.body.course ? "sandbox"
      # name: ... TODO generate some if course is sandbox

    db.userCode.insert codeObj, (err) ->
      if err?
        console.log "problem during saving codeObj"

    # TODO dont discard code from nonregistered users

exports.badget = (req, res) ->
  if req.user?
    unless req.user.achievements
      req.user.achievements = []

    unless req.body.name in req.user.achievements
      req.user.achievements.push req.body.name

    users.updateUser req.user

exports.lectureDone = (req, res) ->
  if req.user?
    unless req.user.lecturesDone
      req.user.lecturesDone = {}

    unless req.user.lecturesDone[req.body.course]
      req.user.lecturesDone[req.body.course] = []

    unless req.body.lecture in req.user.lecturesDone[req.body.course]
      req.user.lecturesDone[req.body.course].push req.body.lecture

    users.updateUser req.user

# TODO deal with unregistered users via session
