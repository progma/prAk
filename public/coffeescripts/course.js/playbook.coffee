# How to play back the values of individual properties.
playbook =
  bufferContents: (value, environment) ->
    environment.codeMirror.setValue value

  cursorPosition: (value, environment) ->
    environment.codeMirror.setCursor value

  selectionRange: (value, environment) ->
    environment.codeMirror.setSelection value.from, value.to

  scrollPosition: (value, environment) ->
    destination = environment.codeMirror.getScrollInfo()
    environment.codeMirror.scrollTo value.x / value.width * destination.width,
                                    value.y / value.height * destination.height

  evaluatedCode: (value, environment) ->
    if not environment.evaluationMode?
      environment.evaluationMode = "turtle2d"

    switch environment.evaluationMode
      when "turtle2d"
        turtle2d.run value
      when "turtle3d"
        turtle3d.run value

@playbook =
  playbook: playbook
module?.exports = @playbook
