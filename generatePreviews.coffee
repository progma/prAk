# This takes the course descriptions in public/courses and the JSON
# keyboard data in public/media and generates expected.turtle for
# turtleTalk previews.

fs = require("fs")

for course in fs.readdirSync("public/courses")
  courseDesc = JSON.parse(fs.readFileSync(
      "public/courses/" + course + "/course.json", "utf8"))

  for lecture in courseDesc.lectures
    if lecture.type == "turtleTalk"
  
      talkName = lecture.name
      lastTalkFile = lecture.talk[lecture.talk.length - 1].file

      talkScript = JSON.parse(fs.readFileSync(
        "public/media/" + course + "/" + lastTalkFile + ".json", "utf8"))

      lastEvaledCode = talkScript
        .evaluatedCode[talkScript.evaluatedCode.length - 1]
        .value


      talkDir = "public/courses/" + course + "/" + talkName

      if not fs.existsSync(talkDir)
        fs.mkdirSync(talkDir)
  
      fs.writeFileSync(talkDir + "/expected.turtle", lastEvaledCode)