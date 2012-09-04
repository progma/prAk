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
