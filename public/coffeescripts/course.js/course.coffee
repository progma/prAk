$(document).ready(->
  soundManager.setup url: "/javascripts/soundManagerSwf"
  $.ajaxSetup
    cache: false
  $("div[slidedata]").each (i, div) ->
    lectures.createLecture $(div)
  window.lectures = lectures    # nice to have in debugging process
)


# We use abbreviations in the course description file: one object for two or
# more slides. This is where we translate them to basic slides. Every function
# stands for an advanced slide.
TurtleSlidesHelper =
  turtleTalk: (slide) ->
    [
      name: slide.name + "TextPad"
      lectureName: slide.name
      type: "code"
      talk: slide.talk
      run: "turtle.run"
      drawTo: slide.name + "TurtleDen"
    ,
      name: slide.name + "TurtleDen"
      lectureName: slide.name
      type: "html"
      go: slide.go
    ]

  turtleTask: (slide) ->
    [
      name: slide.name + "TextPad"
      lectureName: slide.name
      type: "code"
      text: slide.text
      code: slide.code
      drawTo: slide.name + "TurtleDen"
    ,
      name: slide.name + "TurtleDen"
      lectureName: slide.name
      type: "turtleDen"
      go: "move"
    ,
      name: slide.name + "Test"
      lectureName: slide.name
      type: "test"
      code: slide.name + "TextPad"
      go: slide.go
    ]


# In this object we keep the list of all lectures on a page and, moreover,
# this is where we create them.
lectures =
  ls: new Array() # list of lectures on the page
  baseDir: ""

  createLecture: (theDiv) ->
    slideList = $("<div>", { class: "slideList" })
    innerSlides = $("<div>", { class: "innerSlides" })
    errorDiv = $ "<div>", class: "errorOutput"
    errorDiv.appendTo theDiv

    name = @baseDir + theDiv.attr("slidedata")

    $.getJSON(name + "/desc.json", (data) =>
      data.slides = _.reduce data.slides, (memo, slide)->
        if TurtleSlidesHelper[slide.type]?
          memo = memo.concat TurtleSlidesHelper[slide.type](slide)
        else
          memo.push slide
        return memo
      , []

      newLecture = new lecture.Lecture name, data, theDiv, errorDiv

      pageDesign.lectureAdd newLecture, innerSlides, slideList
      @ls.push newLecture
      newLecture.showSlide `undefined`, 0, false, true
    ).error ->
      slideList.html pageDesign.courseNAProblem name
      slideList.appendTo theDiv