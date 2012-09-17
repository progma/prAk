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
  paperHeight: 476

  turtleImage: "/images/zelva.png"
  turtleImageCorrection:
    x: 10
    y: 16

  # Starting possition
  startX: 190
  startY: 238
  startAngle: 0

activeTurtle = null
stashedSettings = []

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

    @paper = turtle2d.paper

    # Stack of actions to perform
    @actions = []

    # Graph for actual relative coordinates
    @graph = new EmbeddedGraph(0, 0, @angle)

    @im = @paper.image settings.turtleImage
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

  runActions: (callback, pos = undefined, animate = true) ->
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
        drawLine oldX, oldY, newX, newY, aniTime, this  if pos.penDown && !@STOP

      when "rotate"
        a = currentAction.angle
        pos.rotate a
        trans = "...r#{a}"

      when "penUp", "penDown"
        pos.penDown = currentAction.type == "penDown"

      when "color"
        @color = currentAction.color

    # Don't animate when there is no transformation or it's prohibited
    if !trans? or !animate
      aniTime = 0
      trans = "..." # emtpy transformation

    unless @STOP
      @im.animate transform: trans
                , aniTime
                , "linear"
                , => @runActions(callback, pos, animate)

environment = (turtle) ->
  go: (steps) ->
    turtle.addAction (MV steps)
    turtle.graph.go steps

  right: (angle) ->
    turtle.addAction (RT angle)
    turtle.graph.rotate angle

  left: (angle) ->
    @right -angle

  repeat: (n, f, args...) ->
    i = 0
    f args... while i++ < n

  penUp: ->
    turtle.addAction PU
    turtle.graph.penUp()

  penDown: ->
    turtle.addAction PD
    turtle.graph.penDown()

  color: (col) ->
    turtle.addAction (CO col)

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

drawLine = (fromX, fromY, toX, toY, aniTime, turtle) ->
  atSX = turtle.startX
  atSY = turtle.startY

  turtle.paper.path("M#{fromX + atSX} #{fromY + atSY}L#{fromX + atSX} #{fromY + atSY}")
    .attr(stroke: turtle.color)
    .animate { path: "M#{fromX + atSX} #{fromY + atSY}L#{toX + atSX} #{toY + atSY}" }, aniTime

clearPaper = ->
  turtle2d.paper.clear()
  turtle2d.paper
    .rect(0, 0, settings.paperWidth, settings.paperHeight)
    .attr fill: settings.paperBackgroundColor

init = (canvas) ->
  turtle2d.paper.remove()    if turtle2d.paper?
  activeTurtle.STOP = true   if activeTurtle?
  turtle2d.paper = Raphael(canvas, settings.paperWidth, settings.paperHeight)
  clearPaper()

  # Show turtle at the beginning
  (new Turtle()).runActions (->)

run = (code, shadow, draw = true, animate = true) ->
  clearPaper()

  activeTurtle = new Turtle()
  activeTurtle.color =
    if shadow then settings.shadowTraceColor else settings.normalTraceColor

  result = ex.test
    code: code
    environment: environment activeTurtle
    constants: constants

  try
    turtle2d.sequences = activeTurtle.graph.sequences()
    if draw
      activeTurtle.countTime()
      activeTurtle.runActions (->), undefined, animate
  catch e
    turtle2d.sequences = null
    console.log "Problem while turtle drawing."
    console.log e.toString()
  finally
    return result


stash = ->
  stashedSettings.push
    turtle: activeTurtle
    paper: turtle2d.paper
  activeTurtle = null
  turtle2d.paper = null

unstash = ->
  {turtle: activeTurtle, paper: turtle2d.paper} = stashedSettings.pop()

##
## Exports
##
@turtle2d = {
  sequences: null
  paper: null
  settings
  init
  run
  stash
  unstash
}
module?.exports = @turtle2d
