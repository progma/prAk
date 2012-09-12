loadText = (name, callback, errorHandler = null) ->
    $.ajax(
      url: name
      dataType: "text"
    ).done(callback)
     .error(errorHandler)


class Lecture
  constructor: (@name, @data, @div) ->
    @courseName = _.last _.filter @name.split("/"), (el) -> el != ""
    @fullName = (@div.attr "id") + @name.replace "/", ""
    @errorDiv = $ "<div>", class: "errorOutput"

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
      turtle2d.init output
      @errorDiv.prependTo output

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
        sound.playTalk slide, @data.mediaRoot, @fullName

    else if slide.type == "test"
      if slide.testDone
        slide.div.html pageDesign.testDoneResultPage
      else
        slide.div.html pageDesign.testNotDoneResultPage

  runCode: (code, isUserCode = true) ->
    slide = @findSlide @currentSlide

    if isUserCode
      connection.sendUserCode
        code: code
        course: @courseName
        lecture: @findSlide(@currentSlide).lecture.name
        mode: "turtle2d"

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
      lastResult = turtle2d.run code, isUserCode == false

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

  # Following three functions moves slides' DIVs to proper places.
  showSlide: (slideName, order, isThereSecond, toRight) ->
    if (!slideName)
      @currentSlide  = slideName = @data.slides[0].name
      @currentSlides = [@currentSlide]

    slide = @findSlide slideName
    pageDesign.showSlide slide, order, isThereSecond, toRight
    @updateHash slide.lecture
    @loadSlide slide

  hideSlide: (slideName, toLeft) ->
    slide = @findSlide slideName

    # Deactivate slide
    sound.stopSound slide if slide.soundObject
    slide.userCode = slide.cm.getValue() if slide.cm?
    slide.isActive = false

    pageDesign.hideSlide slide, toLeft

  moveSlide: (slideName, toLeft) ->
    slide = @findSlide slideName
    pageDesign.moveSlide slide, toLeft

  # Following two functions handle the first response to a user's click.
  forward: ->
    slide = @findSlide @currentSlide
    slideI = _.indexOf @data.slides, slide

    if slide.go == "nextLecture"
      if slide.lecture.next.slides.length > 1
        go = "nextTwo"
      else
        go = "nextOne"
    else
      go = slide.go

    switch go
      when "nextOne"
        next = [slide.next.name]
      when "nextTwo"
        next = [slide.next.name, slide.next.next.name]
      when "move"
        next = [@currentSlide, slide.next.name]
      else
        if !next?
          alert "Toto je konec kurzu."
          return

    @historyStack.push @currentSlides

    $.each @currentSlides, (i, slideName) =>
      if slideName == next[0]
        @moveSlide slideName, true
      else
        @hideSlide slideName, true

    $.each next, (i, slideName) =>
      if slideName != _.last @currentSlides
        @showSlide slideName, i, next.length > 1, true
      @currentSlide = slideName

    @currentSlides = next
    @resetElements()

  back: ->
    if @historyStack.length == 0
      alert "This is the beginning of the course. Try to move forward!"
      return

    nextSlides = @historyStack.pop()
    beforeSlides = @currentSlides

    $.each @currentSlides, (i, slideName) =>
      if  nextSlides.length     > 1     and
          @currentSlides.length > 1     and
          slideName == nextSlides[1]
        @moveSlide slideName, false
      else
        @hideSlide slideName, false

    @currentSlides = nextSlides
    $.each @currentSlides, (i, slideName) =>
      if slideName != beforeSlides[0]
        @showSlide slideName, i, @currentSlides.length > 1, false
      @currentSlide = slideName

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
  findSlide: (slideName) ->
    i = 0

    while i < @data.slides.length
      return @data.slides[i]  if @data.slides[i].name == slideName
      i++

@lecture = {
  Lecture
}
