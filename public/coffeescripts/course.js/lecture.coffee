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
  constructor: (@name, @data, @div) ->
    @courseName = _.last _.filter @name.split("/"), (el) -> el != ""
    @fullName = (@div.attr "id") + @name.replace "/", ""
    @errorDiv = $ "<div>", class: "errorOutput"

    @evaluationContext = {}
    @helpSlide = null

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
        , => slide.div.html pageDesign.loadProblem

        @lectureDone()

    # Display drawing areay with expected result
    else if slide.type == "turtleDen"
      output = document.getElementById @fullName + slide.name

      evaluation.initialiseTurtleDen slide.lecture.mode, output, @evaluationContext
      @errorDiv.prependTo output

      if  slide.lecture.type == "turtleTask" and
          slide.lecture.mode != "turtle3d"   and
          not @evaluationContext.expectedCode?
        loadText @name + "/" + slide.lecture.name + "/expected.turtle", (data) =>
          @evaluationContext.expectedCode = data

          if slide.lecture.test?
            f = tests[@courseName]?[slide.lecture.test+"Expected"]
            f(data) if f?
          else
            @runCode data, false
            @evaluationContext.expectedResult = @evaluationContext.turtle.sequences

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
          , (=> @showHelp())
          , (code) => @runCode code
      cm = slide.cm = @evaluationContext.cm

      if slide.talk?
        cm.setSize 380, 440
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
          sound.playTalk slide, @data.mediaRoot, @fullName, =>
            @lectureDone()
            # TODO stg like
            # if @currentSlide.lecture.forward == "auto"
            #   @forward()

    else if slide.type == "test"
      if slide.testDone
        slide.div.html pageDesign.testDoneResultPage
      else
        slide.div.html pageDesign.testNotDoneResultPage

  runCode: (code, isUserCode = true) ->
    @hideHelp()
    slide = @currentSlide

    if isUserCode
      connection.sendUserCode
        code: code
        course: @courseName
        lecture: slide.lecture.name
        mode: slide.lecture.mode ? "turtle2d"

    @errorDiv.html pageDesign.codeIsRunning

    callback = (res) =>
      @errorDiv.html ""

      if res == true
        @passedTheTest slide
      else if res?
        @handleFailure res

    evaluation.evaluate code
      , isUserCode
      , slide.lecture
      , @evaluationContext
      , callback

  # Handles error object given by failing computation.
  handleFailure: (failingResult) ->
    console.dir failingResult

    if failingResult.errorOccurred
      @errorDiv.html failingResult.reason
    else
      @errorDiv.html pageDesign.wrongAnswer + failingResult.args.toString()

  passedTheTest: (slide) ->
    @lectureDone()
    slide.next.testDone = true
    @forward()

  lectureDone: ->
    lecture = @currentSlide.lecture
    pageDesign.lectureDone lecture

    unless lecture.done
      connection.lectureDone @courseName, lecture.name
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

        slide = @data.slides[0]
        @currentSlides = [slide]

        # Fill @historyStack and @currentSlides
        while slide.name != @currentSlide.name
          @historyStack.push @currentSlides
          @currentSlides = nextSlides slide
          slide = _.last @currentSlides

    if !lectureName
      @currentSlide  = @data.slides[0]
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

  hideHelp: ->
    pageDesign.hideSlide @helpSlide if @helpSlide
    @helpSlide = null

  showHelp: ->
    helpDiv = pageDesign.showHelp (@currentSlide.lecture.help ? ""),
      => @hideHelp()
    @helpSlide =
      div: helpDiv
    pageDesign.showSlide @helpSlide, 1, true, "fadeIn"

  resetElements: ->
    @errorDiv.html ""
    @hideHelp()

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

    while i < @data.slides.length
      if (!byLectureName and @data.slides[i].name == name) or
          (byLectureName and @data.slides[i].lecture.name == name)
        return @data.slides[i]
      i++

    false

@lecture = {
  Lecture
}
