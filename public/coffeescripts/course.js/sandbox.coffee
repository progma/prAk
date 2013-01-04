$ ->
  if warn  # send by server
    $("#myWarning").modal "show"

  turtle2d.settings.defaultTotalTime = 2000
  turtle3d.parameters.BACKGROUND_COLOR = 0xFFFFFF

  editorDiv = document.getElementById "turtleEditor"
  output    = document.getElementById "turtleSpace"
  selectObj = $ "select[name='mode']"

  # Get mode from selected option
  mode = selectObj.find(":selected").val()

  evaluationContext =
    editorTextareaID: "editorArea"
    courseName: "sandbox"
    codeObjectID: codeID  # send by server

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

  selectObj.change (obj) ->
    output.innerHTML = ""
    mode = obj.target.value
    initTD()

  $("#btnShare").click ->
    window.open pageDesign.facebookShareUrl(evaluationContext.codeObjectID)
