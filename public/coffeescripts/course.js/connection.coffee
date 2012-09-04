url = "http://localhost:3000/" # TODO make universal? (from server side?)

# Example of usage:
#
# sendUsersCode
#   code: "var a = 1 + 1;"
#   course: "turtle1"
#   lecture: "sestiuhelnik"
sendUserCode = (data) ->
  $.ajax
    type: 'POST'
    url: url + "ajax/userCode"
    data: data
    dataType: "json"

giveBadget = (name) ->

lectureDone = (course, lecture) ->


@connection = {
  sendUserCode
  giveBadget
  lectureDone
}
