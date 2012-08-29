$ ->
  errorDiv = $ "<div>", class: "errorOutput"
  errorDiv.appendTo $ "body"

  myCodeMirror = CodeMirror.fromTextArea $('#editorArea').get(0),
            lineNumbers: true

  # Eval nemerime pri eventech, ale sbirame pri kliknuti tlacitka 'Eval!'.
  $('#evalButton').click ->
    currentCode = myCodeMirror.getValue()

    errorDiv.html ""
    output = document.getElementById "turtleSpace"
    turtle.settings.defaultTotalTime = 2000
    result = turtle.run currentCode, output, true

    unless result == true
      console.log @lastResult.errObj
      errorDiv.html @lastResult.reason

    console.log "turtle.lastDegreeSequence: #{turtle.lastDegreeSequence}"
