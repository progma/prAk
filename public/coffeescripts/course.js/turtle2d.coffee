##
## Imports
##
ex = @examine ? require './examine'
{Position, PlanarGraph} = @graph ? require './graph'

##
## Settings
##
settings =
  defaultTotalTime  : 2000  # ms
  rotationTime      : 0.2   # one degree rotation time = rotationTime * one step time
  maxComputationTime: 4000
  maxActions        : 10000

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
    @graph = new PlanarGraph(0, 0, @angle)

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

  transFromAction: (action, pos, aniTime) ->
    switch action.type
      when "go"
        len = action.steps
        [oldX, oldY] = [pos.x, pos.y]
        [newX, newY] = pos.go len

        trans = "...t0,#{-len}"
        drawLine oldX, oldY, newX, newY, aniTime, this  if pos.penDown && !@STOP

      when "rotate"
        a = action.angle
        pos.rotate a
        trans = "...r#{a}"

      when "penUp", "penDown"
        pos.penDown = action.type == "penDown"

      when "color"
        @color = action.color

    trans

  runActions: (callback, config) ->
    pos = new Position 0, 0, @angle

    # Limit number of actions
    @actions = @actions.slice 0, config.maxActions

    if config.animate
      @runActionsAnim pos, callback
    else
      @runActionsPlain pos, callback

  runActionsAnim: (pos, callback) ->
    if @actions.length == 0
      callback?()
      return

    currentAction = @actions.shift()
    aniTime = @msForStep *
      (currentAction.steps ? (settings.rotationTime * Math.abs(currentAction.angle)))

    trans = @transFromAction currentAction, pos, aniTime

    # Don't animate when there is no transformation
    if !trans?
      aniTime = 0
      trans = "..." # emtpy transformation

    unless @STOP
      @im.animate transform: trans
                , aniTime
                , "linear"
                , => @runActionsAnim(pos, callback)

  runActionsPlain: (pos, callback) ->
    while @actions.length != 0
      currentAction = @actions.shift()
      @transFromAction currentAction, pos, 0

    @im.transform "t#{pos.x},#{pos.y},r#{pos.angle}"
    callback?()

environment = (turtle, config) ->
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
    if typeof col == 'number'
      str = col.toString 16
      col = '#'
      col += '0' for i in [0...6-str.length]
      col += str
    turtle.addAction (CO col)

  # Time
  __bigBangTime: new Date()

  __checkRunningTimeAndHaltIfNeeded: ->
    if (new Date() - @__bigBangTime) > config.maxTime
      throw new Error "Time exceeded." # TODO change error class

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

  nullPath = "M#{fromX + atSX} #{fromY + atSY}L#{fromX + atSX} #{fromY + atSY}"
  path = "M#{fromX + atSX} #{fromY + atSY}L#{toX + atSX} #{toY + atSY}"

  if aniTime != 0
    turtle.paper.path(nullPath)
      .attr(stroke: turtle.color)
      .animate { path: path }, aniTime
  else
    turtle.paper.path(path)
      .attr(stroke: turtle.color)

clearPaper = ->
  activeTurtle.STOP = true  if activeTurtle?

  if turtle2d.paper?
    turtle2d.paper.clear()
    turtle2d.paper
      .rect(0, 0, settings.paperWidth, settings.paperHeight)
      .attr fill: settings.paperBackgroundColor

init = (canvas, config) ->
  @aftercleaningCallback = config.aftercleaningCallback ? (callback) => callback()

  turtle2d.paper.remove()  if turtle2d.paper?
  turtle2d.paper = Raphael(canvas, settings.paperWidth, settings.paperHeight)
  clearPaper()

  # Show turtle at the beginning
  (new Turtle()).runActions (->), { maxTime: 1, maxActions: 1 }

run = (code, config = {}) ->
  config.shadow  ?= false
  config.draw    ?= true
  config.animate ?= true
  config.maxTime    ?= settings.maxComputationTime
  config.maxActions ?= settings.maxActions

  clearPaper()

  activeTurtle = new Turtle()
  activeTurtle.color =
    if config.shadow then settings.shadowTraceColor else settings.normalTraceColor

  @aftercleaningCallback =>
    result = ex.test
      code: code
      environment: environment activeTurtle, config
      constants: constants

    try
      turtle2d.sequences = activeTurtle.graph.sequences()
      if config.draw
        activeTurtle.countTime()
        activeTurtle.runActions (->), config
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
  if stashedSettings.length > 0
    {turtle: activeTurtle, paper: turtle2d.paper} = stashedSettings.pop()

##
## Exports
##
@turtle2d = {
  name: "turtle2d"
  sequences: null
  paper: null
  settings
  init
  run
  stash
  unstash
}
module?.exports = @turtle2d
