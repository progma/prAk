##
## Imports
##
ex = @examine ? require './examine'
{Position, EmbeddedGraph} = @graph ? require './graph'

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

  turtleImage: "/images/zelva.png"
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
    @graph = new EmbeddedGraph(0, 0, @angle)

    @im = turtle2d.paper.image settings.turtleImage
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
        drawLine oldX, oldY, newX, newY, aniTime, @color if pos.penDown && !@STOP

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

    unless @STOP
      @im.animate transform: trans
                , aniTime
                , "linear"
                , => @runActions(callback, pos)

environment =
  go: (steps) ->
    activeTurtle.addAction (MV steps)
    activeTurtle.graph.go steps

  right: (angle) ->
    activeTurtle.addAction (RT angle)
    activeTurtle.graph.rotate angle

  left: (angle) ->
    @right -angle

  repeat: (n, f, args...) ->
    i = 0
    f args... while i++ < n

  penUp: ->
    activeTurtle.addAction PU
    activeTurtle.graph.penUp()

  penDown: ->
    activeTurtle.addAction PD
    activeTurtle.graph.penDown()

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

  turtle2d.paper.path("M#{fromX + atSX} #{fromY + atSY}L#{fromX + atSX} #{fromY + atSY}")
    .attr(stroke: activeTurtle.color)
    .animate { path: "M#{fromX + atSX} #{fromY + atSY}L#{toX + atSX} #{toY + atSY}" }, aniTime

clearPaper = ->
  turtle2d.paper.clear()
  turtle2d.paper
    .rect(0, 0, settings.paperWidth, settings.paperHeight)
    .attr fill: settings.paperBackgroundColor

init = (canvas) ->
  turtle2d.paper.remove()    if turtle2d.paper
  activeTurtle.STOP = true   if activeTurtle?
  turtle2d.paper = Raphael(canvas, settings.paperWidth, settings.paperHeight)
  clearPaper()

  # Show turtle at the beginning
  (new Turtle()).runActions (->)

run = (code, shadow, animate = true) ->
  clearPaper()

  activeTurtle = new Turtle()
  activeTurtle.color =
    if shadow then settings.shadowTraceColor else settings.normalTraceColor

  result = ex.test
    code: code
    environment: environment
    constants: constants

  try
    turtle2d.sequences = activeTurtle.graph.sequences()
    if animate
      activeTurtle.countTime()
      activeTurtle.runActions (->)
  catch e
    turtle2d.lastDegreeSequence = undefined
    console.log "Problem while turtle drawing."
    console.log e.toString()
  finally
    return result

##
## Exports
##
@turtle2d = {
  sequences: null
  paper: null
  settings
  init
  run
}
module?.exports = @turtle2d
