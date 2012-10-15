parser = @esprima ? require "../esprima"
gen = @escodegen ? require "../escodegen"

turtle3dDiv = undefined
codeToRun   = undefined

cleanCodeMirror = (cm) ->
  return   unless cm.__DIRTY__?

  cm.setLineClass cm.__DIRTY__, null
  cm.__DIRTY__ = undefined

codeMirrorChanged = (onlineCoding, context) -> (cm) ->
  cleanCodeMirror cm

  if onlineCoding.get(0).checked && context.turtle.name == "turtle2d"
    clearTimeout codeToRun
    codeToRun = setTimeout ->
        evaluate cm.getValue(), false, null, context, (->)
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
  switch mode
    when "turtle3d"
      unless turtle3dDiv?
        turtle3dDiv = $ "<div>", class: "canvasJacket"
        turtle3dCanvas = $ "<canvas>", id: "turtle3dCanvas"
        turtle3dDiv.append turtle3dCanvas

      turtle = turtle3d
      turtle3dDiv.appendTo div
      turtle.init $('#turtle3dCanvas').get(0) # turtle3dCanvas
    # when "game" ...
    else
      turtle = turtle2d
      turtle.init div

  context.turtle = turtle

initialiseEditor = (div, isTalk, context, showHelp, runCode) ->
  onlineCodingChBox = $ "<input>", type: "checkbox"

  cm = new CodeMirror div.get(0),
      lineNumbers: true
      readOnly: isTalk
      indentWithTabs: false
      onChange: codeMirrorChanged(onlineCodingChBox, context)
      # autofocus: true
  runFunction = -> runCode cm.getValue()

  buttonsContainer = $ "<div>", class: "runButtonContainer"
  buttonsContainer.appendTo div

  onlineCodingChBox.appendTo buttonsContainer

  $("<button>",
    text: "Nápověda"
    class: if isTalk then "hidden" else "btn runButton"
    click: showHelp
  ).appendTo buttonsContainer

  $("<button>",
    text: "Spustit kód"
    class: if isTalk then "hidden" else "btn runButton"
    click: runFunction
  ).appendTo buttonsContainer

  context.cm = cm

evaluate = (code, isUserCode, lecture, context, callback) ->
  cleanCodeMirror context.cm

  try
    parsedTree = parser.parse code
    makeSafe parsedTree, ourSafetyCall
    code = gen.generate parsedTree
  catch error
    highlightCodeMirror context.cm, error.lineNumber - 1

    # "Line XX: ...." is sweet's message format.
    # We should get rid of the part before ':'.
    reason = error.message.replace /^[^:]*: /, ""

    callback
      errorOccurred: true
      reason: "Syntaktická chyba (#{reason})"
    return

  setTimeout =>
    if isUserCode && lecture.test?
      res = tests[lecture.test](code, context.expectedCode)
      callback res
    else
      lastResult = context.turtle.run code, !isUserCode

      if isUserCode
        given = context.turtle.sequences

        if lecture.testAgainstOneOf?
          for candidate in lecture.testAgainstOneOf
            if graph.sequencesEqual candidate, given
              callback true
              break

        else
          if graph.sequencesEqual(context.expectedResult
                                , given
                                , lecture.testProperties)
            callback true

      if lastResult == true
        callback null  # code is OK, but test not passed
      else
        callback lastResult # code failed
  , 0

@evaluation = {
  initialiseTurtleDen
  initialiseEditor
  evaluate
}
