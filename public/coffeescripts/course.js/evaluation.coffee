parser = @esprima ? require "../sweet"
gen = @escodegen ? require "../escodegen"

turtle3dDiv = undefined
turtle3dCanvas = undefined

cleanCodeMirror = (cm) ->
  return   unless cm.__DIRTY__

  cm.__DIRTY__ = false
  for i in [0...cm.lineCount()]
    cm.setLineClass i, null

highlightCodeMirror = (cm, line) ->
  cm.setLineClass line, "syntaxError"
  cm.__DIRTY__ = true

jsHintOptions =
  boss: true
  evil: true
  # undef: true

syntaxCheck = (code) ->
  result = JSHINT(code, jsHintOptions)
  result || JSHINT.errors[0]


traverse = (object, visitor) ->
  # DISCLAIMER: I stole this private function from esmorph and repurposed it.
  # (https://github.com/ariya/esmorph)
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
      name: "checkRunningTimeAndHaltIfNeeded"

    arguments: []

initialiseTurtleDen = (mode, div, context) ->
  switch mode
    when "turtle3d"
      unless turtle3dDiv?
        turtle3dDiv = $ "<div>", class: "canvasJacket"
        turtle3dCanvas = $ "<canvas>", id: "turtle3dCanvas"
        turtle3dDiv.append turtle3dCanvas # TODO uz pri tvoreni divu to tam narvat?

      turtle = turtle3d
      turtle3dDiv.appendTo div
      turtle.init $('#turtle3dCanvas').get(0) # turtle3dCanvas
    # when "game" ...
    else
      turtle = turtle2d
      turtle.init div

  context.turtle = turtle

initialiseEditor = (div, isTalk, context, showHelp, runCode) ->
  cm = new CodeMirror div.get(0),
      lineNumbers: true
      readOnly: isTalk
      indentWithTabs: false
      onChange: cleanCodeMirror
      # autofocus: true

  buttonsContainer = $ "<div>", class: "runButtonContainer"
  buttonsContainer.appendTo div

  $("<button>",
    text: "Nápověda"
    class: if isTalk then "hidden" else "btn runButton"
    click: showHelp
  ).appendTo buttonsContainer

  $("<button>",
    text: "Spustit kód"
    class: if isTalk then "hidden" else "btn runButton"
    click: -> runCode cm.getValue()
  ).appendTo buttonsContainer

  context.cm = cm

evaluate = (code, isUserCode, lecture, context, handler) ->
  cleanCodeMirror context.cm

  if isUserCode
    syntax = syntaxCheck code

    unless syntax == true
      highlightCodeMirror context.cm, syntax.line-1

      handler
        errorOccurred: true
        reason: "Syntaktická chyba (#{syntax.reason})"
      return

  if isUserCode && lecture.test?
    setTimeout =>
        res = tests[lecture.test](code, context.expectedCode)
        res.errorOccurred = true
        handler res # TODO inspect if errorOccurred = true is necessary
                    # TODO inspect if setTimeout is necessary
      , 0
  else
    lastResult = context.turtle.run code, !isUserCode

    if isUserCode
      given = context.turtle.sequences

      if lecture.testAgainstOneOf?
        for candidate in lecture.testAgainstOneOf
          if graph.sequencesEqual candidate, given
            handler true
            break

      else
        if graph.sequencesEqual context.expectedResult, given, lecture.testProperties
          handler true

    if lastResult == true
      handler null  # code is OK, but test not passed
    else
      handler lastResult # code failed

@evaluation = {
  initialiseTurtleDen
  initialiseEditor
  evaluate
}
