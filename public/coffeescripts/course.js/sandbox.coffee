turtle = turtle2d

$ ->
  output = document.getElementById "turtleSpace"
  errorDiv = $ "<div>", class: "errorOutput"
  errorDiv.appendTo document.body

  myCodeMirror = CodeMirror.fromTextArea $('#editorArea').get(0),
            lineNumbers: true


  $('#evalButton').click ->
    currentCode = myCodeMirror.getValue()
    errorDiv.html ""
    result = turtle.run currentCode, output, false

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
        turtle2d.settings.defaultTotalTime = 2000
        turtle = turtle2d
      when "turtle3d"
        console.log "turtle3d init"
        turtle = turtle3d
        turtle.parameters.BACKGROUND_COLOR = 0xFFFFFF
        $("#turtleSpace").append $("<canvas>", id: "turtle3dCanvas")
        turtle.init $('#turtle3dCanvas').get(0)

