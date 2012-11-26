turtle = turtle2d
mode = "turtle2d"

$ ->
  turtle2d.settings.defaultTotalTime = 2000
  turtle3d.parameters.BACKGROUND_COLOR = 0xFFFFFF

  editorDiv = document.getElementById "turtleEditor"
  output    = document.getElementById "turtleSpace"

  evaluationContext =
    editorTextareaID: "editorArea"
    courseName: "sandbox"

  lecture =
    name: ""
    help: mode
    testProperties: []

  runCode = (code) ->
    evaluation.evaluate code, true, lecture, evaluationContext, (->)

  initTD = ->
    # Set help content depending on turtle mode
    evaluationContext.lecture.help = mode

    evaluation.initialiseTurtleDen mode, output, evaluationContext

  # Initialise environment
  evaluation.initialiseEditor editorDiv, false, evaluationContext, runCode
  initTD()

  evaluationContext.cm.setSize "100%", 390
  evaluationContext.cm.refresh()

  $("select[name='mode']").change (obj) ->
    output.innerHTML = ""
    mode = obj.target.value
    initTD()
