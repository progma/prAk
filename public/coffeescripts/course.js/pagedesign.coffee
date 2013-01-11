lectureAdd = (newLecture, container, slideList, infoPanel) ->
    newLecture.backArrow = $ "<div>",
      id: newLecture.fullName + "backArrow"
      class: "arrow-w"
      click: -> newLecture.back()
    newLecture.backArrow.appendTo container

    $('<i>',
      class: "icon-chevron-left",
    ).appendTo(newLecture.backArrow)

    for lecture in newLecture.course.lectures
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

    $.each newLecture.course["slides"], (i, slide) ->
      slideDiv = $ "<div>",
        id: newLecture.fullName + slide.name
        class: "slide"
        style: "display: none"

      slide["div"] = slideDiv
      slideDiv.appendTo container

    newLecture.forwardArrow = $ "<div>",
      id: newLecture.fullName + "forwardArrow"
      class: "arrow-e"
      click: -> newLecture.forward()
    newLecture.forwardArrow.appendTo container

    $('<i>',
      class: "icon-chevron-right",
    ).appendTo(newLecture.forwardArrow)

    slideList.appendTo newLecture.div
    container.appendTo newLecture.div

# TODO .alert-block?
flash = (message, type) ->
  [klass, opening] =
    switch type
      when "error"   then ["alert-error", "CHYBA: "]
      when "success" then ["alert-success", "ÚSPĚCH: "]
      when "info"    then ["alert-info", "INFORMACE: "]
      else ["",""]

  $("body > div.container").first().prepend """
    <div class='alert #{klass}'>
      <button class="close" data-dismiss="alert">×</button>
      <strong>#{opening}</strong>#{message}
    </div>"""

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
  else if (lecture.type == "turtleTask") || (lecture.type == "turtleTalk")
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
        f = tests[lecture.course.name]?[lecture.test+"Expected"]
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
    class: "control"
    click: clickHandler
  ).appendTo(player)
  pauseIcon = $("<i>",
    class: "control-icon icon-pause"
  ).appendTo(pause)
  seek   = $("<div>",
    class: "seek"
    click: seekHandler
  ).appendTo(player)
  inseek = $("<div>",
    class: "inseek"
    click: seekHandler
  ).appendTo(seek)

displayArrow = (arrow, display) ->
  if display?
    arrow.removeClass "hidden"
  else
    arrow.addClass "hidden"

appearEffect = (elem, callback = (->), time = 150) ->
  elem.css "opacity", 0
  elem.animate { "opacity": "+=1" }, time, ->
    callback()

apiHelp = [
    name: "go"
    title: "Želví příkazy"
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
    title: "Funkce"
    code: "function jmeno(argument1, argument2, ...) {\n  &lt;zde je libovolná posloupnost příkazů&gt;\n}"
    desc: """Naučí želvu nové slovo <code>jmeno</code> (při definici vlastního
    slova můžeš zvolit jakýkoliv název místo <code>jmeno</code>). A poté
    kdykoliv želvě řekneme <code>jmeno(x1, x2, x3, ...)</code>, želva vykoná
    příkazy uvedené v těle funkce, čili zapsané mezi složenými
    závorkami.</p>
    <p>Počet a pojmenování argumentů je při definici nového slova
    volitelný, ale když toto slovo později voláme, vyžaduje stejný počet
    argumentů.
    """
  ,
    name: "if"
    title: "Podmínky"
    code: "if (podminka) {\n  &lt;zde je libovolná posloupnost příkazů&gt;\n}"
    desc: """Vykoná příkazy uvedené v těle podmínky, čili zapsané mezi
    složenými závorkami. Pro porovnávání čísel se jako v matematice používá <code>= &lt; &le; &gt; &ge;</code>, ale nahrazené za <code>== &lt; &lt;= &gt; &gt;=</code>. Například <code>if (x >= 3) { go(30); }</code> způsobí, že želva ujde o <code>30</code> kroků, pokud <code>x &ge; 3</code>.
    """
  ,
    name: "var"
    title: "Proměnné"
    code: "var promenna = &lt;zde je libovolný výraz&gt;;"
    desc: """Do proměnné <code>promenna</code> uloží výsledek výrazu uvedeného
    napravo od <code>=</code>. Například <code>var x = 3*7;</code> uloží do
    <code>x</code> hodnotu <code>21</code>. Později je možné hodnotu uloženou v
    <code>x</code> změnit dalším přiřazením. Například <code>x = 15;</code>
    změní hodnotu <code>x</code> na <code>15</code>.
    """
  ,
    name: "while"
    title: "Cykly"
    code: "while (podminka) {\n  &lt;zde je libovolná posloupnost příkazů&gt;\n}"
    desc: """Stejně jako <code>if</code>, ale příkazy uvedené v těle podmínky se provádějí <em>dokud</em> podmínka platí. Je proto potřeba zajistit, že podmínka někdy platit přestane. Příklad cyklu, který nikdy neskončí:
      <pre><code>while (1 < 2) {\n  ...\n}</code></pre>
    Příklad správného cyklu:
      <pre><code>var i = 1;\nwhile (i <= 10) {\n  right(36);\n  i = i + 1;\n}</code></pre>
    """
    # TODO penUp, penDown, color
]

extendedApiHelp =
  "turtle3d": [
      name: "3dmotion"
      title: "Příkazy 3D želvy"
      code: "up(s);\ndown(s);\nrollLeft(s);\nrollRight(s);"
      desc: """Želva se otočí o <code>s</code> stupňů nahoru/dolů, respektive
      udělá piruetu doleva/doprava vzhledem k ose procházející jí od ocasu k
      hlavě."""
    ,
      name: "width"
      code: "width(n);"
      desc: "Změní šířku štětce na <code>n</code>."
    ,
      name: "color"
      code: "color(barva);"
      desc: """Změní barvu štětce. Barvu je možné zadat číslem, nebo jménem
      jedné z předdefinovaných barev: <code>white, yellow, fuchsia, aqua, red,
        lime, blue, black, green, maroon, olive, purple, gray, navy, teal,
        silver, brown, orange</code>."""
  ]

renderHelp = (conf, help) ->
  container = $ "<div>"

  for h in help
    if h.title
      $("<h3>#{h.title}</h3>").appendTo container

    $("<pre><code>#{h.code}</code></pre>",
      style: "float: left;"
    ).appendTo container

    $("<p>#{h.desc}</p>").appendTo container

    return [h.name, container] if h.name == conf

  [h, container]

showHelp = (conf, hideCallback) ->
  container = $ "<div>", class: "helpSlide"

  # Close button
  $("<button>",
    style: "float: right;"
    class: "btn"
    text: "Skrýt"
    click: hideCallback
  ).appendTo container

  [h, basicAPI] = renderHelp conf, apiHelp
  basicAPI.appendTo container

  if h != conf and conf of extendedApiHelp
    [h, res] = renderHelp conf, extendedApiHelp[conf]
    res.appendTo container

  container

startDISQUS = ->
  resetDisqus = ->
    DISQUS?.reset
      reload: true
      config: disqus_config

  $.getScript "http://#{disqus_shortname}.disqus.com/embed.js"
  $(window).on "hashchange", resetDisqus

facebookShareUrl = (id) ->
    "https://www.facebook.com/dialog/feed?app_id=274343352671549&link=http://prak.mff.cuni.cz/sandbox/#{id}&picture=http://upload.wikimedia.org/wikipedia/commons/thumb/9/98/Kturtle_side_view.svg/474px-Kturtle_side_view.svg.png&name=PrAk&caption=Programovací akademie&description=Programování vystavuje světu nesčetně tváří a některé z nich jsou opravdu přístupné. Třeba želví grafika. Dostanete želvu se štětcem na břichu a budete jí psát příkazy, složitějí a složitější, až budete umět kreslit vcelku složité a zvláštní útvary a, jen tak mimochodem, docela dobře programovat.&redirect_uri=http://prak.mff.cuni.cz"


testDoneResultPage = (id) -> """
  <center>
  <h2 style='margin-top: 30px;'>Správné řešení</h2>
    <img src='/images/checked.png' style='width: 200px; height: 143px; margin: 50px;' />
    <p>Nejen že jsi správně vyřešil/a danou úlohu &#8212 mimoděk jsi stvořil/a veliké
    umělecké dílo, jež bude svou nádherou a noblesou okouzlovat spatřující
    stovky nadcházejících let.</p>
    <p>Nechceš ho sdílet na Facebooku? <a href="#{facebookShareUrl id}" class="btn" target="_blank"><i class="icon-facebook"></i></a></p>
    <p style='margin-top: 30px; font-size: 1.2em;'>Pokračuj dál šipkou vpravo.</p>
  </center>
  """

testNotDoneResultPage = (id) -> """
  <center>
    <h2 style='margin-top: 20px;'>Ještě jsi neodeslal/a správné řešení.</h2>
    <img src='/images/questionmark.png' style='width: 138px; height: 200px; margin: 50px;'>
    <p>Chceš i přes to pokračovat dále v kurzu?</p>
    <p style='padding: 10px 30px 0;'>Sdílet řešení na Facebooku: <a href="#{facebookShareUrl id}" class="btn" target="_blank"><i class="icon-facebook"></i></a></p>
  </center>
"""

loadProblem = """
  Nastala chyba při stahování obsahu ze serveru.
  """

soundManagerFailed = """
  Nastala chyba při spouštění zvuku. Je nainstalován Flash?
  """

courseNAProblem = (name) -> """
  Kurz '""" + name + """' není dostupný.
  """

wrongAnswer = """
  Program vrátil nesprávnou hodnotu při následujících argumentech:
  """

connectionError = "Chyba v připojení"

codeIsRunning = "Běží výpočet."

@pageDesign = {
  lectureAdd
  flash

  # Following three functions moves slides' DIVs to proper places.
  showSlide
  hideSlide
  moveSlide

  lectureDone
  addPlayer
  displayArrow
  appearEffect

  showHelp
  startDISQUS

  facebookShareUrl
  testDoneResultPage
  testNotDoneResultPage
  loadProblem
  soundManagerFailed
  courseNAProblem
  wrongAnswer
  connectionError
  codeIsRunning
}
