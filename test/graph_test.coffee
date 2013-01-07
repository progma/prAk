PATH = '../public/coffeescripts/course.js/'
qc = require PATH + 'quickcheck'
ex = require PATH + 'examine'

{ PRECISION
  QuadTree
  Position
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
dump = (obj, caller = console.log) ->
  basicIndent = "  "
  indent = (depth) ->
    (basicIndent for i in [1..depth] by 1).join ""

  fn = (o, d=0, index = "DUMP") ->
    idt = indent d

    type = if o? && (typeof o != "object")
        ": #{typeof o}"
      else
        ""

    s = if o instanceof Function
            "<<FUNCTION>>"
          else
            "#{o}"

    "#{idt}#{index}: #{s} #{type}\n" +
      if not o?
        ""
      else if o instanceof Object
        res = ""
        res += fn(o[i],d+1,i) for i of o

        if o instanceof Array
          if o.length > 0
            "#{idt}[\n#{res}#{idt}]\n"
          else
            "#{idt + basicIndent}[]\n"
        else
          res
      else
        ""

  caller fn obj

repeat = (n, seq) ->
  if n > 0
    seq.concat repeat n-1, seq
  else
    []

check = (testObject) ->
  process.stdout.write "#{++testCount}. test: "
  res = ex.test testObject
  if res == true
    console.log "OK"
  else
    console.dir res
    console.log "Test failed."
    process.exit 1

graphSequences = ->
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
  g.sequences()

graphDegSeq = ->
  (graphSequences arguments...).degreeSequence

graphDistSeq = ->
  (graphSequences arguments...).distanceSequence

# Tests
console.log "\t === Graph tests ==="
basicPoints = ({ x: i, y: i, z:i } for i in [-5..5])

check
  name: "QuadTree"
  property: (points, toFind) ->
    (new QuadTree points).findPoints(toFind).length
  testCases: [
    T [ basicPoints.concat([
            x: 0 - PRECISION/4
            y: 0
            z: 0
          ,
            x: 0
            y: 0 + PRECISION/4
            z: 0
        ])
      , ( x: 0, y: 0, z: 0 )], 3, "basic test"

    T [ basicPoints.concat(basicPoints)
      , ( x: 6, y: 0, z: 0 )], 0, "basic test 2"
  ]

check
  name: "graph degree sequence"
  property: graphDegSeq
  testCases: [
    T [go, 3, right, 36, go, 3, go, 3], [1,1,2], "basic test"
    T [go, 40, go, 40, right, 180, go, 80, go, 10], [1,1], "basic test 2"
    T [go, 60, penUp, right, 90, go, 30, right, 90, go, 30, right, 90,
      penDown, go, 60], [1,1,1,1,4], "cross"
    T (repeat 7, [go, 50, right, 60]), [2,2,2,2,2,2], "hexagon"
    T (repeat 30, [go, 3, right, 360/30]), (repeat 30, [2]), "circle"
    T (repeat 20, [go, 30, right, 180, penUp, go, 30, right, 180+360/4, penDown]),
      [1,1,1,1,4], "cross 2"
  ]

check
  name: "graph distance sequence"
  property: graphDistSeq
  testCases: [
    T [go, 10, go, 10], [20, 20], "basic test"
    T [go, 10, go, 10, go, 10, go, 10, go, 10], [50, 50], "basic test 2"
    T [go, 10, go, 10, right, 180, go, 30], [30, 30], "elimination by outside segment"
    T [go, 10, go, 10, right, 180, go, 15], [20, 20], "elimination of inside segment"
  ]


# TODO definitely needs more testing:
#   intersectingPointWith
#   degreeSequence
#   angleSequence
#   addLineSegment - case by case testing!
