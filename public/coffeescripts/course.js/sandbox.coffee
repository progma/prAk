$ ->
  errorDiv = $ "<div>", class: "errorOutput"
  errorDiv.appendTo $ "body"

  myCodeMirror = CodeMirror.fromTextArea $('#editorArea').get(0),
            lineNumbers: true

  $('#evalButton').click ->
    currentCode = myCodeMirror.getValue()

    errorDiv.html ""
    output = document.getElementById "turtleSpace"
    turtle.settings.defaultTotalTime = 2000
    result = turtle2d.run currentCode, output, false

    unless result == true
      console.log @lastResult.errObj
      errorDiv.html @lastResult.reason

    console.log "turtle.lastDegreeSequence: #{turtle.lastDegreeSequence}"
