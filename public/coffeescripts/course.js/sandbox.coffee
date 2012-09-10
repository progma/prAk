turtle = turtle2d

$ ->
  output = document.getElementById "turtleSpace"
  errorDiv = $ "<div>", class: "errorOutput"
  canvas = $("<div>", class: "canvasJacket")
  canvas.append $ "<canvas>", id: "turtle3dCanvas"

  myCodeMirror = CodeMirror.fromTextArea $('#editorArea').get(0),
            lineNumbers: true

  turtle2d.settings.defaultTotalTime = 2000
  turtle3d.parameters.BACKGROUND_COLOR = 0xFFFFFF
  turtle.init output
  errorDiv.prependTo output

  $('#evalButton').click ->
    currentCode = myCodeMirror.getValue()
    errorDiv.html ""
    result = turtle.run currentCode, false

    unless result == true
      console.log "error occured"
      console.log result.errObj
      errorDiv.html result.reason

    # console.log "turtle.lastDegreeSequence: #{turtle2d.lastDegreeSequence}"

  $("select[name='mode']").change (obj) ->
    $("#turtleSpace").html ""

    switch obj.target.value
      when "turtle2d"
        console.log "turtle2d init"
        turtle = turtle2d
        turtle.init output
      when "turtle3d"
        console.log "turtle3d init"
        turtle = turtle3d
        $("#turtleSpace").append canvas
        turtle.init $('#turtle3dCanvas').get(0)

    errorDiv.prependTo output

