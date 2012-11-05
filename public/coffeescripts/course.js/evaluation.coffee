parser = @esprima ? require "../esprima"
gen = @escodegen ? require "../escodegen"

# Constants
quickRunTime    = 500
quickRunActions = 500

turtle3dDiv    = undefined
turtle3dCanvas = undefined
codeToRun      = undefined

cleanCodeMirror = (cm) ->
  return   unless cm.__DIRTY__?

  cm.setLineClass cm.__DIRTY__, null
  cm.__DIRTY__ = undefined

codeMirrorChanged = (onlineCoding, context) -> (cm) ->
  cleanCodeMirror cm

  if onlineCoding.get(0).checked && context.turtle.name == "turtle2d"
    # Stop previous (if any) attempt to run code
    clearTimeout codeToRun

    # Start new attempt
    codeToRun = setTimeout ->
        evaluate cm.getValue(), false, null, context, (->), true
      , 800

highlightCodeMirror = (cm, line) ->
  cm.setLineClass line, "syntaxError"
  cm.__DIRTY__ = line


# DISCLAIMER: I stole this private function from esmorph and repurposed it.
# (https://github.com/ariya/esmorph)
traverse = (object, visitor) ->
  for own key of object
    child = object[key]
    traverse child, visitor  if typeof child == "object" and child != null
  visitor object

makeSafe = (parseTree, safetyCall) ->
  traverse parseTree, (node) ->
    switch node.type
      when "WhileStatement", "DoWhileStatement", "ForStatement", "ForInStatement"
        node.body =
          type: "BlockStatement"
          body: [safetyCall, node.body]

      when "FunctionDeclaration", "FunctionExpression"
        if node.body.type == "BlockStatement"
          node.body.body.splice 0, 0, safetyCall
        else if node.body.type == "Expression"
          node.body =
            type: "BlockStatement"
            body: [ safetyCall,
              type: "ExpressionStatement"
              expression: node.body
            ]

ourSafetyCall =
  type: "ExpressionStatement"
  expression:
    type: "CallExpression"
    callee:
      type: "Identifier"
      name: "__checkRunningTimeAndHaltIfNeeded"

    arguments: []

initialiseTurtleDen = (mode, div, context) ->
  hideHelp context
  context.turtleDen = div
  context.mode      = mode
  context.errorDiv  = $("<div>", class: "errorOutput").appendTo div
  context.turtleDiv = $("<div>").appendTo div

  div = context.turtleDiv.get(0)

  switch mode
    when "turtle3d"
      unless turtle3dDiv?
        turtle3dDiv = $ "<div>", class: "canvasJacket"
        turtle3dCanvas = $ "<canvas>", id: "turtle3dCanvas"
        turtle3dDiv.append turtle3dCanvas

      turtle = turtle3d
      turtle3dDiv.appendTo div
      turtle.init turtle3dCanvas.get(0)
    # when "game" ...
    else
      turtle = turtle2d
      turtle.init div

  context.turtle = turtle

hideHelp = (context) ->
  return  unless context.helpDiv
  context.turtleDiv.show()
  context.helpDiv.detach()
  context.helpDiv = undefined

showHelp = (context) ->
  if context.helpDiv
    hideHelp context
  else
    # create jQuery object
    td = $ context.turtleDen

    # generate help object
    context.helpDiv =
      pageDesign.showHelp (context.lecture.help ? ""), -> hideHelp context

    context.turtleDiv.hide()
    td.append context.helpDiv

initialiseEditor = (div, isTalk, context, runCode, lecture = {}) ->
  onlineCodingChBox = $ "<input>",
    type: "checkbox"
    class: if isTalk then "hidden" else ""

  settings =
      lineNumbers: true
      readOnly: isTalk
      indentWithTabs: false
      onChange: codeMirrorChanged(onlineCodingChBox, context)
      # autofocus: true

  if context.editorTextareaID?
    cm = CodeMirror.fromTextArea $("##{context.editorTextareaID}").get(0),
          settings
  else
    cm = new CodeMirror div.get(0), settings

  runFunction = -> runCode cm.getValue()

  buttonsContainer = $ "<div>", class: "runButtonContainer"
  buttonsContainer.appendTo div

  onlineCodingChBox.appendTo buttonsContainer

  $("<button>",
    text: "Nápověda"
    class: if isTalk then "hidden" else "btn runButton"
    click: -> showHelp context
  ).appendTo buttonsContainer

  $("<button>",
    text: "Spustit kód"
    class: if isTalk then "hidden" else "btn runButton"
    click: runFunction
  ).appendTo buttonsContainer

  context.lecture = lecture
  context.cm = cm

# Handles error object given by computation.
handleFailure = (result, context) ->
  context.errorDiv.html ""
  return  if result == null || result == true

  if result.errorOccurred
    context.errorDiv.html result.reason
  else
    context.errorDiv.html pageDesign.wrongAnswer + result.args.toString()

  console.dir result

evaluate = (code, isUserCode, lecture, context, callback, quickRun = false) ->
  hideHelp context
  cleanCodeMirror context.cm
  context.errorDiv.html pageDesign.codeIsRunning

  callback_ = (res) ->
    handleFailure res, context
    callback res

  if isUserCode && !quickRun
    connection.sendUserCode
      code: code
      course: context.courseName
      lecture: lecture.name
      mode: context.mode ? "turtle2d"

  try
    parsedTree = parser.parse code
    makeSafe parsedTree, ourSafetyCall
    code = gen.generate parsedTree
  catch error
    highlightCodeMirror context.cm, error.lineNumber - 1

    # "Line XX: ...." is esprima's error message format.
    # We should get rid of the part before ':'.
    reason = error.message.replace /^[^:]*: /, ""

    callback_
      errorOccurred: true
      reason: "Syntaktická chyba (#{reason})"
    return

  # Run code outside of main loop in order to be able to show "Code is
  # running..." tooltip.
  setTimeout =>
    if isUserCode && lecture.test?
      # Run specialized test code from course's test module.
      res = tests[lecture.course.name][lecture.test](code, context.expectedCode)
      callback_ res
    else
      lastResult = context.turtle.run code,
        shadow: !(quickRun || isUserCode)
        animate: !quickRun
        maxTime:    if quickRun then quickRunTime    else undefined
        maxActions: if quickRun then quickRunActions else undefined

      # Perform tests?
      if isUserCode
        given = context.turtle.sequences

        if lecture.testAgainstOneOf?
          for candidate in lecture.testAgainstOneOf
            if graph.sequencesEqual candidate, given
              callback_ true
              break

        else
          # Just test sequences of angles, distances, ...
          if graph.sequencesEqual(context.expectedResult
                                , given
                                , lecture.testProperties)
            callback_ true

      if lastResult == true
        callback_ null  # code is OK, but test didn't pass
      else
        callback_ lastResult # code failed
  , 0

@evaluation = {
  initialiseTurtleDen
  initialiseEditor
  evaluate
}
