turtle = turtle2d
mode = "turtle2d"

$ ->
  editorDiv = document.getElementById "turtleEditor"
  output    = document.getElementById "turtleSpace"
  evaluationContext =
    editorTextareaID: "editorArea"

  runCode = (code) ->
    evaluation.evaluate code, false, {}, evaluationContext, (->)

  initTD = ->
    evaluation.initialiseTurtleDen mode, output, evaluationContext

  turtle2d.settings.defaultTotalTime = 2000
  turtle3d.parameters.BACKGROUND_COLOR = 0xFFFFFF

  evaluation.initialiseEditor editorDiv, false, evaluationContext, (->), runCode
  initTD()

  $('#evalButton').click ->
    currentCode = myCodeMirror.getValue()

    connection.sendUserCode
      code: currentCode
      mode: mode

    errorDiv.html ""
    result = turtle.run currentCode, shadow: false

    unless result == true
      console.log "error occured"
      console.log result.errObj
      errorDiv.html result.reason

  $("select[name='mode']").change (obj) ->
    $("#turtleSpace").html ""

    mode = obj.target.value
    initTD()
