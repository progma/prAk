lectureAdd = (newLecture, container, slideList, infoPanel) ->
    newLecture.backArrow = $ "<div>",
      id: newLecture.fullName + "backArrow"
      class: "arrow-w"
      click: -> newLecture.back()
    newLecture.backArrow.appendTo container

    for lecture in newLecture.data.lectures
      do (lecture) ->
        lectureIconGroup = $("<div>",
          id: "groupOf" + newLecture.fullName + lecture.name
          class: "lectureIconGroup"
          click: ->
            newLecture.hideCurrentSlides()
            newLecture.showLecture lecture.name
          mouseenter: -> showPreview(lecture)
          mouseleave: -> hidePreview(lecture)
        ).appendTo(slideList)
        lecture.iconDiv = lectureIconGroup

        for slide in lecture.slides
          slideIcon = $("<div>",
            id: "iconOf" + newLecture.fullName + slide.name
            class: "slideIcon" + if lecture.done then " slideDone" else ""
            style: "background-image: url('/images/icons/" + slide.type + ".png')"
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
      class: "slide"
      style: "display: none"
      id: "helpSlide"
    ).appendTo container

    newLecture.forwardArrow = $ "<div>",
      id: newLecture.fullName + "forwardArrow"
      class: "arrow-e"
      click: -> newLecture.forward()
    newLecture.forwardArrow.appendTo container

    slideList.appendTo newLecture.div
    container.appendTo newLecture.div
    infoPanel.appendTo newLecture.div

    showFeedback infoPanel

# Following three functions moves slides' DIVs to proper places.
showSlide = (slide, order, isThereSecond, effect) ->
  slide.iconDiv?.addClass "slideIconActive"
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
  slide.iconDiv?.removeClass "slideIconActive"

moveSlide = (slide, toLeft) ->
  slide.div.animate { "margin-left": if toLeft then "-=410px" else "+=410px" }
                  , 1000

showPreview = (lecture) ->
  iconPos = lecture.iconDiv.offset()
  lecture.previewDiv = $("<div>",
    class: "preview"
    style: "left: " + iconPos.left + "px; top: " + (iconPos.top+40) + "px;"
    html: "<h4>" + lecture.readableName + "</h4>"
  ).appendTo($ "body")

  if lecture.preview?
    lecture.previewDiv.html(lecture.previewDiv.html() + "<br><img src='" + lecture.preview + "'>")
  else if lecture.type == "turtleTask"
    return if lecture.mode? && lecture.mode != "turtle2d"
    t = turtle2d
    t.stash()

    turtlePlace = $("<div>"
      style: "height: 20px; width: 40px; transform: scale(0.3); -moz-transform: scale(0.3); -webkit-transform: scale(0.3)"
    ).appendTo lecture.previewDiv

    $("<div>"
      style: "height: 130px"
    ).appendTo lecture.previewDiv
    t.init turtlePlace.get 0

    $.ajax(
      url: lecture.course.urlStart + "/" + lecture.name + "/expected.turtle"
      dataType: "text"
    ).done((data) ->
      if lecture.test?
        f = tests[lecture.test+"Expected"]
        f(data, false) if f?
      else
        t.run data, animate: false
    ).always ->
      t.unstash()

hidePreview = (lecture) ->
  lecture.previewDiv.remove()

lectureDone = (lecture) ->
  for slide in lecture.slides
    slide.iconDiv.addClass "slideDone"

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
  ).appendTo(div)
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

displayArrow = (arrow, display) ->
  if display?
    arrow.removeClass "hidden"
  else
    arrow.addClass "hidden"

apiHelp = [
    name: "go"
    code: "go(n);"
    desc: "Želva ujde n kroků dopředu."
  ,
    name: "right"
    code: "right(s);"
    desc: "Želva se otočí doprava o <code>s</code> stupňů."
  ,
    name: "left"
    code: "left(s);"
    desc: "Želva se otočí doleva o <code>s</code> stupňů."
  ,
    name: "function"
    code: "function jmeno(argument1, argument2, ....) {\n  (zde je libovolná posloupnost instrukcí)\n}"
    desc: """Naučí želvu nové slovo <code>jmeno</code> (při definici vlastního
    slova můžeš zvolit jakýkoliv název místo <code>jmeno</code>). A poté
    kdykoliv želvě řekneme <code>jmeno(x1, x2, x3, ...)</code>, želva vykoná
    instrukce uvedené v těle funkce, čili zapsané mezi složenými
    závorkami.</p>
    <p>Počet a pojmenování argumentů je při definici nového slova
    volitelný, ale když toto slovo později voláme, vyžaduje stejný počet
    argumentů.
    """
  ,
    name: "repeat"
    code: "repeat(n, slovo, argument1, argument2, ...);"
    desc: """Vykoná <code>slovo</code> <code>n</code>-krát. Pokaždé s argumenty
    argument1, argument2, ... (v závislosti na tom, kolik jich je uvedeno).
    """

    # TODO if (vcetne porovnavani == < <=), penUp, penDown, color
]

extendedApiHelp =
  "turtle3d": [] # TODO up, down, rollLeft, rollRight, width
  "game": []

apiHelpNames =
  "turtle3d": "Příkazy 3D želvy"
  "game": "Příkazy pro prostředí Hra"

renderHelp = (conf, help) ->
  container = $ "<div>"

  for h in help
    $("<pre><code>#{h.code}</code></pre>",
      style: "float: left;"
    ).appendTo container

    $("<p>#{h.desc}</p>").appendTo container

    return [h, container] if h.name == conf

  [h, container]

showHelp = (conf, hideCallback) ->
  container = $ "#helpSlide"
  container.html ""
  $("<button>",
    style: "float: right;"
    class: "btn"
    text: "Skrýt"
    click: hideCallback
  ).appendTo container
  $("<h3>Želví příkazy</h3>").appendTo container

  [h, basicAPI] = renderHelp conf, apiHelp
  basicAPI.appendTo container

  if h != conf and conf of extendedApiHelp
    [h, res] = renderHelp conf, extendedApiHelp[conf]
    $("<h3>#{apiHelpNames[conf]}</h3>").appendTo container
    res.appendTo container

  container


testDoneResultPage = """
  <center>
  <h2 style='margin-top: 30px;'>Správné řešení</h2>
    <img src='/images/checked.png' style='width: 200px; height: 143px; margin: 50px;'>
    <p>Nejen že jsi správně vyřešil/a danou úlohu &#8212 mimoděk jsi stvořil/a veliké
    umělecké dílo, jež bude svou nádherou a noblesou okouzlovat spatřující
    stovky nadcházejících let.
    <p>Nechceš ho sdílet na Facebooku?
    <p style='margin-top: 30px; font-size: 1.2em;'>Pokračuj dál šipkou vpravo.
  </center>
  """

testNotDoneResultPage = """
  <center>
    <h2 style='margin-top: 30px;'>Ještě jsi neodeslal/a správné řešení.</h2>
    <img src='/images/questionmark.png' style='width: 138px; height: 200px; margin: 50px;'>
    <p>Chceš i přes to pokračovat dále v kurzu?</p>
  </center>
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

  lectureDone
  addPlayer
  displayArrow

  showHelp

  testDoneResultPage
  testNotDoneResultPage
  loadProblem
  courseNAProblem
  wrongAnswer
  codeIsRunning
}
