loadText = (name, callback, errorHandler = null) ->
    $.ajax(
      url: name
      dataType: "text"
    ).done(callback)
     .error(errorHandler)

nextSlides = (slide) ->
  if slide.go == "nextLecture"
    if slide.lecture.next.slides.length > 1
      go = "nextTwo"
    else
      go = "nextOne"
  else
    go = slide.go

  switch go
    when "nextOne"
      [slide.next]
    when "nextTwo"
      [slide.next, slide.next.next]
    when "move"
      [slide, slide.next]
    else
      false


class Lecture
  constructor: (@name, @course, @div) ->
    @fullName = (@div.attr "id") + @name.replace "/", ""
    @evaluationContext = { courseName: @course.name }

    # This is where we keep notion about what to do if a user hit the back
    # arrow.
    @historyStack = new Array()

  # Loads content to one slide.
  loadSlide: (slide) ->
    slide.div.html ""
    slide.isActive = true

    if slide.type == "html" and slide.source?
        loadText @name + "/" + slide.source
        , (data) =>
          slide.div.html data
        , -> pageDesign.flash pageDesign.loadProblem, "error"

        @lectureDone()

    # Display drawing areay with expected result
    else if slide.type == "turtleDen"
      output = document.getElementById @fullName + slide.name

      evaluation.initialiseTurtleDen slide.lecture.mode, output, @evaluationContext

      if  slide.lecture.type == "turtleTask"
        loadText @name + "/" + slide.lecture.name + "/expected.turtle", (data) =>
          @evaluationContext.expectedCode = data

          if slide.lecture.test?
            f = tests[@course.name]?[slide.lecture.test+"Expected"]
            f(data) if f?
          else
            @runCode data, false, true

    else if slide.type == "code"
      textDiv = $("<div>")
      textDiv.appendTo slide.div

      unless slide.talk?
        loadText @name + "/" + slide.lecture.name + "/text.html", (data) =>
          if slide.lecture.readableName?
            data = "<h4>#{slide.lecture.readableName}</h4>\n#{data}"
          textDiv.html data
          textDiv.height "80px"

      evaluation.initialiseEditor slide.div
          , slide.talk?
          , @evaluationContext
          , ((code) => @runCode code)
          , slide.lecture
      cm = slide.cm = @evaluationContext.cm

      if slide.talk?
        cm.setSize 380, 413
      else
        cm.setSize 380, 365
      cm.setValue ""    # force CodeMirror to redraw using the new size

      if slide.userCode
        cm.setValue slide.userCode
      else if slide.lecture.code
        loadText @name + "/#{slide.lecture.name}/#{slide.lecture.code}"
        , (data) =>
          cm.setValue data
          slide.userCode = data

      if slide.talk?
        soundManager.onready =>
          sound.playTalk slide, @course.mediaRoot, @evaluationContext, =>
            @lectureDone()
            # TODO stg like
            # if @currentSlide.lecture.forward == "auto"
            #   @forward()

    else if slide.type == "test"
      oId = @evaluationContext.codeObjectID
      if slide.testDone
        slide.div.html pageDesign.testDoneResultPage(oId)
      else
        slide.div.html pageDesign.testNotDoneResultPage(oId)

  runCode: (code, isUserCode = true, saveContext = false) ->
    slide = @currentSlide

    callback = (res) =>
      if res == true
        @passedTheTest slide

      if saveContext
        @evaluationContext.expectedResult = @evaluationContext.turtle.sequences

    evaluation.evaluate code
      , isUserCode
      , slide.lecture
      , @evaluationContext
      , callback

  passedTheTest: (slide) ->
    @lectureDone()
    slide.next.testDone = true
    @forward()

  lectureDone: ->
    lecture = @currentSlide.lecture
    pageDesign.lectureDone lecture

    unless lecture.done
      connection.lectureDone @course.name, lecture.name
      lecture.done = true

  # Following four functions moves slides' DIVs to proper places.
  showLecture: (lectureName) ->
    if lectureName
      @currentSlide = @findSlide lectureName, true

      if @currentSlide == false
        lectureName = "" # search failed, start with first slide
      else
        # @currentSlide is the slide displayed on the right, so it's the second
        # one in lectures with more than one slide
        if @currentSlide.lecture.slides.length > 1
          @currentSlide = @currentSlide.next

        slide = @course.slides[0]
        @currentSlides = [slide]

        # Fill @historyStack and @currentSlides
        while slide.name != @currentSlide.name
          @historyStack.push @currentSlides
          @currentSlides = nextSlides slide
          slide = _.last @currentSlides

    if !lectureName
      @currentSlide  = @course.slides[0]
      @currentSlides = [@currentSlide]

    $.each @currentSlides, (i, slideIt) =>
      @showSlide @currentSlides[i], i, @currentSlides.length > 1, "fadeIn"

    @resetElements()

  hideCurrentSlides: ->
    for slide in @currentSlides
      @hideSlide slide, "fadeOut"

  showSlide: (slide, order, isThereSecond, effect) ->
    pageDesign.showSlide slide, order, isThereSecond, effect
    @updateHash slide.lecture
    connection.whenWhereDictionary.lecture = slide.lecture.name
    @loadSlide slide

  hideSlide: (slide, effect) ->
    # Deactivate slide
    sound.stopSound slide if slide.soundObject
    slide.userCode = slide.cm.getValue() if slide.cm?
    slide.isActive = false

    pageDesign.hideSlide slide, effect

  moveSlide: (slide, toLeft) ->
    pageDesign.moveSlide slide, toLeft

  # Following two functions handle the first response to a user's click.
  forward: ->
    slide = @currentSlide
    next = nextSlides slide

    if next == false
      alert "Toto je konec kurzu."
      return

    @historyStack.push @currentSlides

    $.each @currentSlides, (i, slideIt) =>
      if slideIt == next[0]
        @moveSlide slideIt, true
      else
        @hideSlide slideIt, "toLeft"

    $.each next, (i, slideIt) =>
      if slideIt.name != (_.last @currentSlides).name
        @showSlide slideIt, i, next.length > 1, "toRight"
      @currentSlide = slideIt

    @currentSlides = next
    @resetElements()

  back: ->
    if @historyStack.length == 0
      alert "This is the beginning of the course. Try to move forward!"
      return

    next = @historyStack.pop()
    beforeSlides = @currentSlides

    $.each @currentSlides, (i, slideIt) =>
      if  next.length     > 1     and
          @currentSlides.length > 1     and
          slideIt.name == next[1].name
        @moveSlide slideIt, false
      else
        @hideSlide slideIt, "toRight"

    @currentSlides = next
    $.each @currentSlides, (i, slideIt) =>
      if slideIt.name != beforeSlides[0].name
        @showSlide slideIt, i, @currentSlides.length > 1, "toLeft"
      @currentSlide = slideIt

    @resetElements()

  resetElements: ->
    pageDesign.displayArrow @backArrow, @currentSlides[0].prev
    pageDesign.displayArrow @forwardArrow, (_.last @currentSlides).next

  # Hash is the part of URL after #
  # TODO: This is going to need more systematic handling with respect to
  #       - other possible course instances
  #       - other scripts on the page
  #       Right now (for prAk) it works fine, though.
  updateHash: (lecture) ->
    location.hash = "#" + lecture.name

  # Finds the slide with a given name.
  #
  # If byLectureName is true, we search by lecture name and the first slide of
  # the lecture is returned.
  findSlide: (name, byLectureName = false) ->
    i = 0

    while i < @course.slides.length
      if (!byLectureName and @course.slides[i].name == name) or
          (byLectureName and @course.slides[i].lecture.name == name)
        return @course.slides[i]
      i++

    false

@lecture = {
  Lecture
}
