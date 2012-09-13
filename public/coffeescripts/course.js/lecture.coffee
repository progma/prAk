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

    @turtle = null
    @turtle3dDiv = $ "<div>", class: "canvasJacket"
    @turtle3dCanvas = $ "<canvas>", id: "turtle3dCanvas"
    @turtle3dDiv.append @turtle3dCanvas

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

    # Display drawing areay with expected result
    else if slide.type == "turtleDen"
      output = document.getElementById @fullName + slide.name

      switch slide.lecture.mode
        when "turtle3d"
          @turtle = turtle3d
          @turtle3dDiv.appendTo output
          @turtle.init $('#turtle3dCanvas').get(0) # @turtle3dCanvas
        # when "game" ...
        else
          @turtle = turtle2d
          @turtle.init output

      @errorDiv.prependTo output

      unless slide.lecture.talk?
        loadText @name + "/" + slide.lecture.name + "/expected.turtle", (data) =>
          @expectedCode = data

          if slide.lecture.test?
            f = tests[slide.lecture.test+"Beforehand"]
            f(data) if f?
          else
            @runCode data, false
            @expectedResult = turtle2d.sequences

    else if slide.type == "code"
      textDiv = $("<div>")
      textDiv.appendTo slide.div

      unless slide.lecture.talk?
        loadText @name + "/" + slide.lecture.name + "/text.html", (data) =>
          textDiv.html data
          textDiv.height "80px"

      cm = new CodeMirror slide.div.get(0),
            lineNumbers: true
            readOnly: slide.talk?
            indentWithTabs: false
            # autofocus: true

      if slide.userCode
        cm.setValue slide.userCode
      else if slide.lecture.code
        loadText @name + "/#{slide.lecture.name}/#{slide.lecture.code}"
        , (data) =>
          cm.setValue data
          slide.userCode = data

      cm.setSize 380, 360
      slide.cm = cm

      $("<button>",
        text: "Spustit kód"
        class: if slide.talk? then "hidden" else "btn"
        click: =>
          @runCode cm.getValue()
      ).appendTo slide.div

      if slide.talk?
        soundManager.onready =>
          sound.playTalk slide, @data.mediaRoot, @fullName

    else if slide.type == "test"
      if slide.testDone
        slide.div.html pageDesign.testDoneResultPage
      else
        slide.div.html pageDesign.testNotDoneResultPage

  runCode: (code, isUserCode = true) ->
    slide = @currentSlide

    if isUserCode
      connection.sendUserCode
        code: code
        course: @courseName
        lecture: slide.lecture.name
        mode: slide.lecture.mode ? "turtle2d"

    @errorDiv.html pageDesign.codeIsRunning if isUserCode

    if isUserCode && slide.lecture.test?
      setTimeout =>
          lastResult = tests[slide.lecture.test](code, @expectedCode)
          if lastResult == true
            @lectureDone slide
            @errorDiv.html ""
          else
            @handleFailure lastResult
        , 0
    else
      lastResult = @turtle.run code, isUserCode == false

      if isUserCode
        expected = @expectedResult
        given = turtle2d.sequences
        eq = graph.almostEqual

        if  _.isEqual(expected.degreesSequence, given.degreesSequence) and
            eq(expected.anglesSequence,    given.anglesSequence)       and
            eq(expected.distancesSequence, given.distancesSequence)
          @lectureDone slide

      @errorDiv.html ""

      unless lastResult == true
        @handleFailure lastResult

  # Handles error object given by failing computation.
  handleFailure: (failingResult) ->
    console.dir failingResult

    if failingResult.errorOccurred
      @errorDiv.html failingResult.reason
    else
      @errorDiv.html pageDesign.wrongAnswer + failingResult.args.toString()

  lectureDone: (slide) ->
    unless slide.next.testDone
      connection.lectureDone @courseName, slide.lecture.name

    slide.next.testDone = true
    @forward()

  # Following four functions moves slides' DIVs to proper places.
  startCourse: (slideName) ->
    if slideName
      @currentSlide = @findSlide slideName, true

      if @currentSlide == false
        slideName = "" # search failed, start with first slide
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

    if !slideName
      @currentSlide  = @data.slides[0]
      slideName = @currentSlide.name
      @currentSlides = [@currentSlide]

    $.each @currentSlides, (i, slideIt) =>
      @showSlide @currentSlides[i], i, @currentSlides.length > 1, true

  showSlide: (slide, order, isThereSecond, toRight) ->
    pageDesign.showSlide slide, order, isThereSecond, toRight
    @updateHash slide.lecture
    @loadSlide slide

  hideSlide: (slide, toLeft) ->
    # Deactivate slide
    sound.stopSound slide if slide.soundObject
    slide.userCode = slide.cm.getValue() if slide.cm?
    slide.isActive = false

    pageDesign.hideSlide slide, toLeft

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
        @hideSlide slideIt, true

    $.each next, (i, slideIt) =>
      if slideIt.name != (_.last @currentSlides).name
        @showSlide slideIt, i, next.length > 1, true
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
        @hideSlide slideIt, false

    @currentSlides = next
    $.each @currentSlides, (i, slideIt) =>
      if slideIt.name != beforeSlides[0].name
        @showSlide slideIt, i, @currentSlides.length > 1, false
      @currentSlide = slideIt

    @resetElements()

  # Empty error area
  resetElements: ->
    @errorDiv.html ""

  # Hash is the part of URL after #
  # TODO: This is going to need more systematic handling with respect to
  #       - other possible course instances
  #       - other scripts on the page
  #       Right now (for prAk) it works fine, though.
  updateHash: (lecture) ->
    location.hash = "#" + lecture.name

  # Previews!
  showPreview: (slide) ->
    slide.iconDiv.offset().left

  hidePreview: (slide) ->


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
