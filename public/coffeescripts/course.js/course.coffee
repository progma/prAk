userCode = window.userCode ? {}
lecturesDone = window.lecturesDone ? []

$(document).ready ->
  soundManager.setup
    url: "/javascripts/soundManagerSwf"
    debugMode: false
    useFlashBlock: true
    # preferFlash: false # TODO uncomment in future, see SM2 documentation
    ontimeout: (status) ->
      pageDesign.flash pageDesign.soundManagerFailed, "error"

  $.ajaxSetup
    cache: false

  $("div[slidedata]").each (i, div) ->
    courses.createCourse $(div)

  window.courses = courses    # nice to have in debugging process
  window.onerror = (message, url, line) ->
    connection.log "jsError", { message, url, line }

  # DISQUS
  window.disqus_config = ->
    hashString = window.location.hash.substring(1)
    @page.url = "http://prak.mff.cuni.cz/courses/#{courseName}/#{hashString}"

  pageDesign.startDISQUS()


# One lecture stands for one or more slides. Lecture is a logical unit of
# course -- it can be a task or talk about some interesting mathematical object.
# Slide, on the other hand, is a technical unit, a box that serves the
# purpose given by lecture.

# For example, turtleTask is a lecture unit that asks user to fuilfill
# a task. It contains three slides: the first one takes care of edit
# environment for our user, the second one executes the code and shows
# the picture of this execution, the third one accomplishes the user
# and gives him sharing options.

# It is often possible to take a lecture out of course context and offer it as
# an independent task or talk or whatever. Contrary to that, there is not much
# sense in taking one particular slide out of lecture context as it may
# technically depend on another slides and, this is more important, it is not
# a logical unit of teaching.

# In the following simple case, lecture blends with the only slide it contains.
StandardSlidesHelper =
  html: (lecture) ->
    [
      name: lecture.name
      lecture: lecture
      type: "html"
      source: lecture.source
      go: lecture.go ? "nextLecture"
    ]

TurtleSlidesHelper =
  turtleTalk: (lecture) ->
    [
      name: lecture.name + "TextPad"
      lecture: lecture
      type: "code"
      talk: lecture.talk
    ,
      name: lecture.name + "TurtleDen"
      lecture: lecture
      type: "turtleDen"
      go: lecture.go ? "nextLecture"
    ]

  turtleTask: (lecture) ->
    [
      name: lecture.name + "TextPad"
      lecture: lecture
      type: "code"
      userCode: userCode[lecture.name]
    ,
      name: lecture.name + "TurtleDen"
      lecture: lecture
      type: "turtleDen"
      go: "move"
    ,
      name: lecture.name + "Test"
      lecture: lecture
      type: "test"
      code: lecture.name + "TextPad"
      go: lecture.go ? "nextLecture"
      testDone: lecture.name in lecturesDone
    ]


# In this object we keep the list of all courses on the page.
courses =
  list: new Array() # list of courses on the page
  baseDir: ""

  # This is is a starting point of course construction from course.json,
  # the course description file.
  createCourse: (theDiv) ->
    slideList = $("<div>", { class: "slideList" })
    innerSlides = $("<div>", { class: "innerSlides" })
    infoPanel = $("<div>", { class: "infoPanel" })

    name = @baseDir + theDiv.attr("slidedata")

    $.getJSON(name + "/course.json", (courseData) =>
      courseData.urlStart = name
      courseData.name = _.last (_.filter name.split('/'), (s) -> s != "")

      courseData.slides = _.reduce courseData.lectures, (memo, lecture)->
        if StandardSlidesHelper[lecture.type]?
          newSlides = StandardSlidesHelper[lecture.type](lecture)
          lecture.slides = newSlides
          memo = memo.concat newSlides
        else if TurtleSlidesHelper[lecture.type]?
          newSlides = TurtleSlidesHelper[lecture.type](lecture)
          lecture.slides = newSlides
          memo = memo.concat newSlides
        else
          lecture.lecture = lecture  # epic!
          lecture.slides = [lecture]
          memo.push lecture

        lecture.course = courseData
        lecture.done = lecture.name in lecturesDone
        return memo
      , []

      # create convinient pointers to next and previous slide/lecture
      for array in [courseData.lectures, courseData.slides]
        for li in [0...array.length]
          array[li-1].next = array[li]   unless li == 0
          array[li+1].prev = array[li]   unless li == array.length-1

      newCourse = new lecture.Lecture name, courseData, theDiv

      pageDesign.lectureAdd newCourse, innerSlides, slideList, infoPanel
      @list.push newCourse
      newCourse.showLecture location.hash.replace('#', '')

      connection.whenWhereDictionary.course = name
    ).error ->
      pageDesign.flash pageDesign.courseNAProblem(name), "error"
