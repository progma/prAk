userCode = window.userCode ? {}
lecturesDone = window.lecturesDone ? []

$(document).ready(->
  soundManager.setup url: "/javascripts/soundManagerSwf"
  $.ajaxSetup
    cache: false
  $("div[slidedata]").each (i, div) ->
    courses.createCourse $(div)
  window.courses = courses    # nice to have in debugging process
)


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
      run: "turtle.run"
      drawTo: lecture.name + "TurtleDen"
    ,
      name: lecture.name + "TurtleDen"
      lecture: lecture
      type: "html"
      go: lecture.go ? "nextLecture"
    ]

  turtleTask: (lecture) ->
    [
      name: lecture.name + "TextPad"
      lecture: lecture
      type: "code"
      text: lecture.text
      code: lecture.code
      userCode: userCode[lecture.name]
      drawTo: lecture.name + "TurtleDen"
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

    name = @baseDir + theDiv.attr("slidedata")

    $.getJSON(name + "/course.json", (data) =>
      data.slides = _.reduce data.lectures, (memo, lecture)->
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
        return memo
      , []
      
      # create convinient pointers to next and previous slide/lecture
      for array in [data.lectures, data.slides]
        for li in [0...array.length]
          array[li-1].next = array[li]   unless li == 0
          array[li+1].prev = array[li]   unless li == array.length-1

      newCourse = new lecture.Lecture name, data, theDiv

      pageDesign.lectureAdd newCourse, innerSlides, slideList
      @list.push newCourse
      newCourse.showSlide `undefined`, 0, false, true
    ).error ->
      slideList.html pageDesign.courseNAProblem name
      slideList.appendTo theDiv
