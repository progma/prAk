PATH = '../public/coffeescripts/course.js/'
qc = require PATH + 'quickcheck'
ex = require PATH + 'examine'

{ PRECISION
  QuadTree
  Position
  LineSegment
  PlanarGraph
  Simple3DGraph
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
    console.log "(#{testObject.name}) OK"
  else
    console.dir res
    console.log "Test failed."
    process.exit 1

graphSequences = ->
  g = new PlanarGraph 0, 0, 0

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

simple3dGraphSequences = ->
  g = new Simple3DGraph()

  for e in arguments
    g.addEdge e[0], e[1]

  g.sequences()

simple3dGraphDegSeq = ->
  (simple3dGraphSequences arguments...).degreeSequence

simple3dGraphDistSeq = ->
  (simple3dGraphSequences arguments...).distanceSequence

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
    T (repeat 8, [go, 50, right, 60]), [2,2,2,2,2,2], "hexagon"
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

check
  name: "3D graph degree sequence"
  property: simple3dGraphDegSeq
  testCases: [
    T [[(x:0, y:0, z:0),(x:10, y: 10, z:0)]], [1,1], "basic test"
    T [[(x:0, y:0, z:0),(x:10, y: 10, z:0)], [(x:10, y:10, z:0),(x:5, y: 15, z:0)]],
        [1,1,2], "basic test 2"
    T [ [(x: 0, y: 0, z: 0), (x:10, y:10, z: 0)]
        [(x:10, y:10, z: 0), (x:20, y: 0, z: 0)]
        [(x:20, y: 0, z: 0), (x:10, y: 0, z:10)]
        [(x:10, y: 0, z:10), (x: 0, y: 0, z: 0)]
      ], [2,2,2,2], "four edges"
    T [ [
            x: 0 - PRECISION/4
            y: 0
            z: 0
          ,
            x: 0
            y: 0 + PRECISION/4
            z: 10
        ],
        [
            x: 0
            y: 0 - PRECISION/4
            z: 10
          ,
            x: 0
            y: 0 + PRECISION/4
            z: 0
        ]
      ], [1,1], "edge elimination"

    # A redundant way, how to create cube.
    T [ [( x: 0, y: 0, z: 0), ( x: 0, y: 93.96926168497417, z: 34.202015414019755)]
        [( x: 0, y: 93.96926168497417, z: 34.202015414019755), ( x: 0, y: 93.96926168497417, z: 34.202015414019755)]
        [( x: 0, y: 93.96926168497417, z: 34.202015414019755), ( x: 0, y: 93.96926168497417, z: 34.202015414019755)]
        [( x: 0, y: 93.96926168497417, z: 34.202015414019755), ( x: 93.96926175764031, y: 82.2714823055163, z: 66.34139627790087)]
        [( x: 93.96926175764031, y: 82.2714823055163, z: 66.34139627790087), ( x: 93.96926175764031, y: 82.2714823055163, z: 66.34139627790087)]
        [( x: 93.96926175764031, y: 82.2714823055163, z: 66.34139627790087), ( x: 93.96926175764031, y: 82.2714823055163, z: 66.34139627790087)]
        [( x: 93.96926175764031, y: 82.2714823055163, z: 66.34139627790087), ( x: 93.96925969409227, y: -11.697779114767556, z: 32.13938013665056)]
        [( x: 93.96925969409227, y: -11.697779114767556, z: 32.13938013665056), ( x: 93.96925969409227, y: -11.697779114767556, z: 32.13938013665056)]
        [( x: 93.96925969409227, y: -11.697779114767556, z: 32.13938013665056), ( x: 93.96925969409227, y: -11.697779114767556, z: 32.13938013665056)]
        [( x: 93.96925969409227, y: -11.697779114767556, z: 32.13938013665056), ( x: -0.000001448394570502387, y: 0.0000013164404339960356, z: -0.000002143013141164829)]
        [( x: -0.000001448394570502387, y: 0.0000013164404339960356, z: -0.000002143013141164829), ( x: -0.000001448394570502387, y: 0.0000013164404339960356, z: -0.000002143013141164829)]
        [( x: -0.000001448394570502387, y: 0.0000013164404339960356, z: -0.000002143013141164829), ( x: -0.000001448394570502387, y: 0.0000013164404339960356, z: -0.000002143013141164829)]
        [( x: -0.000001448394570502387, y: 0.0000013164404339960356, z: -0.000002143013141164829), ( x: 34.20201408875321, y: 32.139382191499536, z: -88.30222369017801)]
        [( x: 34.20201408875321, y: 32.139382191499536, z: -88.30222369017801), ( x: 34.20201394903251, y: 126.10864385173846, z: -54.10020820819874)]
        [( x: 34.20201394903251, y: 126.10864385173846, z: -54.10020820819874), ( x: -0.000003143191491972175, y: 93.96926472145205, z: 34.202013371685226)]
        [( x: -0.000003143191491972175, y: 93.96926472145205, z: 34.202013371685226), ( x: 34.20201472947205, y: 126.10864315012653, z: -54.10020816127768)]
        [( x: 34.20201472947205, y: 126.10864315012653, z: -54.10020816127768), ( x: 128.1712753284169, y: 114.41086277600621, z: -21.960824271625484)]
        [( x: 128.1712753284169, y: 114.41086277600621, z: -21.960824271625484), ( x: 93.96926160740733, y: 82.27148830028099, z: 66.34140030814926)]
        [( x: 93.96926160740733, y: 82.27148830028099, z: 66.34140030814926), ( x: 128.17127828205483, y: 114.41086303138418, z: -21.960823034645784)]
        [( x: 128.17127828205483, y: 114.41086303138418, z: -21.960823034645784), ( x: 128.17127749266612, y: 20.441598757972187, z: -56.16283133699052)]
        [( x: 128.17127749266612, y: 20.441598757972187, z: -56.16283133699052), ( x: 93.96926520995487, y: -11.697782536950221, z: 32.13939131789432)]
        [( x: 93.96926520995487, y: -11.697782536950221, z: 32.13939131789432), ( x: 128.17127711600554, y: 20.441601055225107, z: -56.162830646750365)]
        [( x: 128.17127711600554, y: 20.441601055225107, z: -56.162830646750365), ( x: 34.202014145961, y: 32.139376321244114, z: -88.30220946296782)]
        [( x: 34.202014145961, y: 32.139376321244114, z: -88.30220946296782), ( x: -0.0000039869972496831, y: -0.000011501098690303024, z: 0.00000855015933609593)]
        [( x: -0.0000039869972496831, y: -0.000011501098690303024, z: 0.00000855015933609593), ( x: 34.20201561965, y: 32.139376339229905, z: -88.30220888561888)]
      ], [3,3,3,3, 3,3,3,3], "cube"
    ]

check
  name: "3D graph distance sequence"
  property: simple3dGraphDistSeq
  testCases: [
    T [[(x:0, y:0, z:0),(x:0, y: 10, z:0)]], [10,10], "basic test"
    T [[(x:0, y:0, z:0),(x:10, y: 10, z:0)], [(x:10, y:10, z:0),(x:5, y: 15, z:0)]],
        [14.142135623730951, 14.142135623730951,
        7.0710678118654755, 7.0710678118654755], "basic test 2"
    T [ [(x: 0, y: 0, z: 0), (x:10, y: 0, z: 0)]
        [(x:10, y: 0, z: 0), (x:10, y:10, z: 0)]
        [(x:10, y:10, z: 0), (x: 0, y:10, z: 0)]
        [(x: 0, y:10, z: 0), (x: 0, y: 0, z: 0)]

        # The last edge is duplicated.
        [(x: 0, y:10, z: 0), (x: 0, y: 0, z: 0)]
      ], (repeat 8, [10]), "four edges"
  ]

# TODO definitely needs more testing:
#   intersectingPointWith
#   degreeSequence
#   angleSequence
#   addLineSegment - case by case testing!
