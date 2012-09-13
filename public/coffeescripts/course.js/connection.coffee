url = window.serverURL ? "http://localhost:3000/"

# Example of usage:
#
# sendUsersCode
#   code: "var a = 1 + 1;"
#   course: "turtle1"
#   lecture: "sestiuhelnik"
sendUserCode = (data) ->
  $.ajax
    type: 'POST'
    url: url + "/ajax/userCode"
    data: data
    dataType: "json"

giveBadget = (name) ->
  $.ajax
    type: 'POST'
    url: url + "/ajax/badget"
    data: { name }
    dataType: "json"

lectureDone = (course, lecture) ->
  $.ajax
    type: 'POST'
    url: url + "/ajax/lectureDone"
    data: {
      course
      lecture
    }
    dataType: "json"

whenWhereDictionary = {}

log = (type, content) ->
  whenWhereDictionary.time = new Date()
  $.ajax
    type: 'POST'
    url: url + "/ajax/log"
    data: {
      type
      content
      whenWhere: whenWhereDictionary
    }
    dataType: "json"

@connection = {
  sendUserCode
  giveBadget
  lectureDone
  log
  whenWhereDictionary
}
