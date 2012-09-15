lectureAdd = (newLecture, container, slideList, infoPanel) ->
    $("<div>",
      id: newLecture.fullName + "backArrow"
      class: "arrow-w"
      click: -> newLecture.back()
    ).appendTo container

    for lecture in newLecture.data.lectures
      do (lecture) ->
        lectureIconGroup = $("<div>",
          id: "groupOf" + newLecture.fullName + lecture.name
          class: "lectureIconGroup"
          click: ->
            newLecture.hideCurrentSlides()
            newLecture.showLecture lecture.name
        ).appendTo(slideList)

        for slide in lecture.slides
          slideIcon = $("<div>",
            id: "iconOf" + newLecture.fullName + slide.name
            class: "slideIcon"
            style: "background-image: url('/images/icons/" + slide.type + ".png')"
            mouseover: -> newLecture.showPreview(slide)
            mouseout: -> newLecture.hidePreview(slide)
          ).appendTo(lectureIconGroup)
          slide.iconDiv = slideIcon

    $.each newLecture.data["slides"], (i, slide) ->
      slideDiv = $ "<div>",
        id: newLecture.fullName + slide.name
        class: "slide"
        style: "display: none"

      slide["div"] = slideDiv
      slideDiv.appendTo container

    $("<div>",
      id: newLecture.fullName + "forwardArrow"
      class: "arrow-e"
      click: -> newLecture.forward()
    ).appendTo container

    slideList.appendTo newLecture.div
    container.appendTo newLecture.div
    infoPanel.appendTo newLecture.div

    showFeedback infoPanel

# Following three functions moves slides' DIVs to proper places.
showSlide = (slide, order, isThereSecond, effect) ->
  slide.iconDiv.addClass "slideIconActive"
  slide.div.css "margin-left"
              , if isThereSecond then (
                    if order == 0 then "-405px" else "5px"
                ) else "-200px"
  slide.div.css "display", "block"

  if effect == "toRight"
    slide.div.css "left", "150%"
    slide.div.animate { left: "-=100%" }, 1000
  else if effect == "toLeft"
    slide.div.css "left", "-50%"
    slide.div.animate { left: "+=100%" }, 1000
  else if effect == "fadeIn"
    slide.div.css "left", "50%"
    slide.div.fadeIn 300
  else
    slide.div.css "left", "50%"

hideSlide = (slide, effect) ->
  afterEffect = ->
    slide.div.css "display", "none"
    slide.div.html "" unless slide.isActive
  if effect == "toLeft" or effect == "toRight"
    slide.div.animate { left: if effect=="toLeft" then "-=100%" else "+=100%" }
                     , 1000
                     , afterEffect
  else if effect == "fadeOut"
    slide.div.fadeOut 300, afterEffect
  else
    afterEffect()
  slide.iconDiv.removeClass "slideIconActive"

moveSlide = (slide, toLeft) ->
  slide.div.animate { "margin-left": if toLeft then "-=410px" else "+=410px" }
                  , 1000

addPlayer = (div, clickHandler, seekHandler) ->
  div.addClass "playSlide"
  player = $("<div>",
    class: "player"
  ).appendTo(div)
  pause  = $("<div>",
    class: "pause"
    click: clickHandler
  ).appendTo(player)
  seek   = $("<div>",
    class: "seek"
    click: seekHandler
  ).appendTo(player)
  inseek = $("<div>",
    class: "inseek"
    click: seekHandler
  ).appendTo(seek)

showFeedback = (div) ->
  pp = $("<p>",
    text: "Rychlá zpětná vazba: "
    style: "display: inline-block"
  ).appendTo(div);
  thumbUp = $("<button>",
    class: "thumbUp btn"
    click: ->
      connection.log "feedback",
        thumb: true
  ).appendTo(div)
  thumbDown = $("<button>",
    class: "thumbDown btn"
    click: ->
      connection.log "feedback",
        thumb: false
  ).appendTo(div)
  commentary = $("<input>",
    type: "text"
    class: "commentary"
    placeholder: "Pište!"
    keydown: (ev) ->
      if ev.keyCode == 13
        connection.log "feedback",
          commentary: $(this).val()
        $(this).val("")
        $(this).attr("placeholder", "Díky! Ještě něco?")
  ).appendTo(div)


testDoneResultPage = """
  <p>Výborně!
  <h2>Správné řešení</h2>
    <p>Nejen že jsi správně vyřešil/a danou úlohu -- mimoděk jsi stvořil/a veliké
    umělecké dílo, jež bude svou nádherou a noblesou okouzlovat spatřující
    stovky nadcházejících let.
    <p>Nechceš ho sdílet na Facebooku?
  """

testNotDoneResultPage = """
  <p>Počkat!
  <h2>Ještě jsi neodeslal/a správné řešení.</h2>
    <p>Chceš i přes to pokračovat dále v kurzu?
"""

loadProblem = """
  <center>There was an unusual accident during the load.</center>
  """
courseNAProblem = (name) -> """
  <p style='position: relative; top: 0.5em'>
    Course at '""" + name + """' is not available.
  """

wrongAnswer = """
  Program vrátil nesprávnou hodnotu při následujících arugemntech: 
  """

codeIsRunning = "Běží výpočet."

@pageDesign = {
  lectureAdd

  # Following three functions moves slides' DIVs to proper places.
  showSlide
  hideSlide
  moveSlide

  addPlayer

  testDoneResultPage
  testNotDoneResultPage
  loadProblem
  courseNAProblem
  wrongAnswer
  codeIsRunning
}
