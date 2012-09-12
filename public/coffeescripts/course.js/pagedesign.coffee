lectureAdd = (newLecture, container, slideList) ->
    $("<div>",
      id: newLecture.fullName + "backArrow"
      class: "arrow-w"
      click: -> newLecture.back()
    ).appendTo container

    $.each newLecture.data["slides"], (i, slide) ->
      slideIcon = $("<div>",
        id: "iconOf" + newLecture.fullName + slide.name
        class: if slide.type == "code" then "slideIconFirst" else "slideIcon"
        style: "background-image: url('/images/icons/" + slide.type + ".png')"
        mouseover: -> newLecture.showPreview(slide)
        mouseout: -> newLecture.hidePreview(slide)
      ).appendTo(slideList)

      slideDiv = $ "<div>",
        id: newLecture.fullName + slide.name
        class: "slide"
        style: "display: none"

      slide["div"] = slideDiv
      slide["iconDiv"] = slideIcon
      slideDiv.appendTo container

    $("<div>",
      id: newLecture.fullName + "forwardArrow"
      class: "arrow-e"
      click: -> newLecture.forward()
    ).appendTo container

    slideList.appendTo newLecture.div
    container.appendTo newLecture.div

# Following three functions moves slides' DIVs to proper places.
showSlide = (slide, order, isThereSecond, toRight) ->
  slide.iconDiv.addClass "slideIconActive"
  slide.div.css "margin-left"
              , if isThereSecond then (
                    if order == 0 then "-440px" else "1px"
                ) else "-210px"
  slide.div.css "display", "block"

  if toRight
    slide.div.css "left", "150%"
    slide.div.animate { left: "-=100%" }, 1000
  else
    slide.div.css "left", "-50%"
    slide.div.animate { left: "+=100%" }, 1000

hideSlide = (slide, toLeft) ->
  slide.div.animate { left: if toLeft then "-=100%" else "+=100%" }
                   , 1000
                   , ->
                     slide.div.css "display", "none"
                     slide.div.html "" unless slide.isActive
  slide.iconDiv.removeClass "slideIconActive"

moveSlide = (slide, toLeft) ->
  slide.div.animate { "margin-left": if toLeft then "-=440px" else "+=440px" }
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
