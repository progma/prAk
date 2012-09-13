PATH = '../public/coffeescripts/course.js/'
qc = require PATH + 'quickcheck'
ex = require PATH + 'examine'

{ Position
  LineSegment
  EmbeddedGraph
} = require PATH + 'graph'

{T, Tn} = ex

# Constants
testCount = 0

go      = "go"
right   = "right"
penUp   = "penUp"
penDown = "penDown"

# Helpers
repeat = (n, seq) ->
  if n > 0
    seq.concat repeat n-1, seq
  else
    []

check = (testObject) ->
  process.stdout.write "#{++testCount}. test: "
  console.dir ex.test testObject

graphDegree = ->
  g = new EmbeddedGraph 0, 0, 0

  for i in [0...arguments.length]
    switch arguments[i]
      when go
        g.go arguments[++i]
      when right
        g.rotate arguments[++i]
      when penUp
        g.penUp()
      when penDown
        g.penDown()
  g.sequences().degreesSequence

# Tests
check
  name: "graphDegree"
  property: graphDegree
  testCases: [
    T [go, 3, right, 36, go, 3, go, 3], [1,1,2], "basic test"
    T [go, 40, go, 40, right, 180, go, 80, go, 10], [1,1]
    T [go, 60, penUp, right, 90, go, 30, right, 90, go, 30, right, 90,
      penDown, go, 60], [1,1,1,1,4], "cross"
    T (repeat 30, [go, 3, right, 360/30]), (repeat 30, [2]), "circle"
    T (repeat 20, [go, 30, right, 180, penUp, go, 30, right, 180+360/4, penDown]),
      [1,1,1,1,4], "cross 2"
  ]

# TODO definitely needs more testing:
#   intersectingPointWith
#   degreesSequence
#   anglesSequence
#   addLineSegment - case by case testing!
