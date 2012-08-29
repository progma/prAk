##
## Imports
##
ex = (exports ? this).examine

##
## Settings
##
settings =
  defaultTotalTime: 2000  # ms
  rotationTime    : 0.2   # one degree rotation time = rotationTime * one step time

  # Colors defined in users environment
  shadowTraceColor: "yellow"
  normalTraceColor: "red"

  paperBackgroundColor: "#fff"
  paperWidth : 380
  paperHeight: 480

  turtleImage: "examples/zelva/zelva.png"
  turtleImageCorrection:
    x: 10
    y: 16

  # Starting possition
  startX: 190
  startY: 240
  startAngle: 0

activeTurtle = null

##
## Turtle events
##

# Rotate event
RT = (a) ->
  type: "rotate"
  angle: a

# Move event
MV = (steps) ->
  type: "go"
  steps: steps

# Pen up/down event
PU = type: "penUp"
PD = type: "penDown"

# Change color event
CO = (col) ->
  type: "color"
  color: col


class Turtle
  constructor: (@startX = settings.startX,
                @startY = settings.startY,
                @angle  = settings.startAngle,
                @totalTime = settings.defaultTotalTime,
                @color     = settings.normalTraceColor) ->

    # Stack of actions to perform
    @actions = []

    # Graph for actual relative coordinates
    @graph = new EmbeddedGraphWithGo(0, 0, @angle)

    @im = turtle.paper.image settings.turtleImage
                           , @startX - settings.turtleImageCorrection.x
                           , @startY - settings.turtleImageCorrection.y
                           , 20, 30
    @im.rotate @angle

  addAction: (a) ->
    @actions.push a

  countTime: ->
    totalSteps = _.reduce @actions, (memo, action) ->
      memo += action.steps                                     if action.steps?
      memo += (settings.rotationTime * Math.abs(action.angle)) if action.angle?
      memo
    , 0
    @msForStep = @totalTime / totalSteps

  runActions: (callback, pos = undefined) ->
    if @actions.length == 0
      callback()
      return

    unless pos?
      pos = new Position 0, 0, @angle

    currentAction = @actions.shift()
    aniTime = @msForStep *
      (currentAction.steps ? (settings.rotationTime * Math.abs(currentAction.angle)))

    switch currentAction.type
      when "go"
        len = currentAction.steps
        [oldX, oldY] = [pos.x, pos.y]
        [newX, newY] = pos.go len

        trans = "...t0,#{-len}"
        drawLine oldX, oldY, newX, newY, aniTime, @color if pos.penDown

      when "rotate"
        a = currentAction.angle
        pos.rotate a
        trans = "...r#{a}"

      when "penUp", "penDown"
        pos.penDown = currentAction.type == "penDown"

      when "color"
        @color = currentAction.color

    # Dont animate when there is no transformation
    unless trans?
      aniTime = 0
      trans = "..." # emtpy transformation

    @im.animate transform: trans
              , aniTime
              , "linear"
              , => @runActions(callback, pos)

class Position
  constructor: (@x, @y, @angle, @penDown = true) ->

  go: (steps) ->
    [@x, @y] = computeCoords @x, @y, steps, @angle

  rotate: (a) ->
    @angle += a

class EmbeddedGraphWithGo
  constructor: (startX, startY, startAngle) ->
    @vertices = []
    @newVertex startX, startY

    # Actual position
    @pos = new Position startX, startY, startAngle

  # Structure representing vertex on space
  newVertex: (x, y) ->
    newV =
      x: x
      y: y
      edges: []
    @vertices.push newV
    newV

  findVertex: (x, y) ->
    _.find @vertices, (v) -> Math.abs(v.x - x) < 0.0001 and Math.abs(v.y - y) < 0.0001

  go: (steps) ->
    [oldX, oldY] = [@pos.x, @pos.y]
    [newX, newY] = @pos.go steps
    return unless @pos.penDown

    oldV = @findVertex(oldX, oldY)
    newV = @findVertex(newX, newY)

    unless oldV?
      oldV = @newVertex oldX, oldY

    unless newV?
      newV = @newVertex newX, newY

    oldV.edges.push newV
    newV.edges.push oldV

  rotate: (a) ->
    @pos.rotate a

  degreeSequence: ->
    (_.map @vertices, (v) -> v.edges.length).sort()


computeCoords = (x,y,len,angle) ->
  newX = x + len * Math.sin(angle / 360 * Math.PI * 2)
  newY = y - len * Math.cos(angle / 360 * Math.PI * 2)
  [newX,newY]

environment =
  go: (steps) ->
    activeTurtle.addAction (MV steps)
    activeTurtle.graph.go steps

  right: (angle) ->
    activeTurtle.addAction (RT angle)
    activeTurtle.graph.rotate angle

  left: (angle) ->
    right -angle

  repeat: (n, f, args...) ->
    i = 0
    f args... while i++ < n

  penUp: ->
    activeTurtle.addAction PU
    activeTurtle.graph.pos.penDown = false

  penDown: ->
    activeTurtle.addAction PD
    activeTurtle.graph.pos.penDown = true

  color: (col) ->
    activeTurtle.addAction (CO col)

  # TODO
  # print
  # clear
  # delay

constants =
  # Colors
  white:   "#FFFFFF"
  yellow:  "#FFFF00"
  fuchsia: "#FF00FF"
  aqua:    "#00FFFF"
  red:     "#FF0000"
  lime:    "#00FF00"
  blue:    "#0000FF"
  black:   "#000000"
  green:   "#008000"
  maroon:  "#800000"
  olive:   "#808000"
  purple:  "#800080"
  gray:    "#808080"
  navy:	   "#000080"
  teal:	   "#008080"
  silver:  "#C0C0C0"
  brown:   "#552222"
  orange:  "#CC3232"

drawLine = (fromX, fromY, toX, toY, aniTime) ->
  atSX = activeTurtle.startX
  atSY = activeTurtle.startY

  turtle.paper.path("M#{fromX + atSX} #{fromY + atSY}L#{fromX + atSX} #{fromY + atSY}")
    .attr(stroke: activeTurtle.color)
    .animate { path: "M#{fromX + atSX} #{fromY + atSY}L#{toX + atSX} #{toY + atSY}" }, aniTime


run = (code, canvas, shadow) ->
  turtle.paper.remove()  if turtle.paper

  paper = Raphael(canvas, settings.paperWidth, settings.paperHeight)
  turtle.paper = paper
  paper.rect(0, 0, settings.paperWidth, settings.paperHeight)
       .attr fill: settings.paperBackgroundColor

  activeTurtle = new Turtle()
  activeTurtle.color =
    if shadow then settings.shadowTraceColor else settings.normalTraceColor

  result = ex.test
    code: code
    environment: environment
    constants: constants

  try
    activeTurtle.countTime()
    turtle.lastDegreeSequence = activeTurtle.graph.degreeSequence()
    activeTurtle.runActions (->)
  catch e
    turtle.lastDegreeSequence = undefined
    console.log "Problem while turtle drawing."
    console.log e.toString()
  finally
    return result

(exports ? this).turtle = {
  lastDegreeSequence: null
  settings
  run
}
