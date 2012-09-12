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

      loadText @name + "/" + slide.lectureName + "/expected.turtle", (data) =>
        @expectedCode = data

        if slide.test?
          f = tests[slide.test+"Beforehand"]
          f(data) if f?
        else
          @runCode data, false
          @expectedResult = turtle2d.sequences

    else if slide.type == "code"
      textDiv = $("<div>")
      textDiv.appendTo slide.div

      loadText @name + "/" + slide.lectureName + "/text.html", (data) =>
        textDiv.html data
        textDiv.height "80px"

      cm = new CodeMirror slide.div.get(0),
            lineNumbers: true
            readOnly: slide.talk?
            indentWithTabs: false
            # autofocus: true

      if slide.userCode
        cm.setValue slide.userCode
      else if slide.code
        loadText @name + "/#{slide.lectureName}/#{slide.code}", (data) =>
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
        lecture: @findSlide(@currentSlide).lectureName
        mode: "turtle2d"

    @errorDiv.html pageDesign.codeIsRunning if isUserCode

    if isUserCode && slide.test?
      setTimeout =>
          lastResult = tests[slide.test](code, @expectedCode)
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
    slideI = _.indexOf @data.slides, slide

    unless @data.slides[slideI+1].testDone
      connection.lectureDone @courseName, slide.lectureName

    @data.slides[slideI+1].testDone = true
    @forward()

  # Following three functions moves slides' DIVs to proper places.
  showSlide: (slideName, order, isThereSecond, toRight) ->
    if (!slideName)
      @currentSlide  = slideName = @data.slides[0].name
      @currentSlides = [@currentSlide]

    slide = @findSlide slideName
    pageDesign.showSlide slide, order, isThereSecond, toRight
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

    switch slide.go
      when "nextOne"
        slide.next = [@data.slides[slideI+1].name]
      when "nextTwo"
        slide.next = [@data.slides[slideI+1].name, @data.slides[slideI+2].name]
      when "move"
        slide.next = [@currentSlide, @data.slides[slideI+1].name]
      else
        if !slide.next?
          alert "Toto je konec kurzu."
          return

    @historyStack.push @currentSlides

    $.each @currentSlides, (i, slideName) =>
      if slideName == slide.next[0]
        @moveSlide slideName, true
      else
        @hideSlide slideName, true

    $.each slide.next, (i, slideName) =>
      if slideName != _.last @currentSlides
        @showSlide slideName, i, slide.next.length > 1, true
      @currentSlide = slideName

    @currentSlides = slide.next
    @resetElements()

  back: ->
    if @historyStack.length == 0
      alert "Toto je začátek kurzu."
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
