PRECISION    = 0.0000005
PREC_3D      = 0.0001 # TODO fix
QUAD_TREE_CELL_CAPACITY = 10


approxZero = (num, prec = PRECISION) ->
  Math.abs(num) < prec

# Returns distance between two points *squared*
dist = (p1, p2) ->
  px = p1.x - p2.x
  py = p1.y - p2.y
  px*px + py*py

dist3 = (p1, p2) ->
  px = p1.x - p2.x
  py = p1.y - p2.y
  pz = p1.z - p2.z
  px*px + py*py + pz*pz

computeCoords = (x,y,len,angle) ->
  newX = x + len * Math.sin(angle / 360 * Math.PI * 2)
  newY = y - len * Math.cos(angle / 360 * Math.PI * 2)
  [newX,newY]

normalizeAngle = (a) ->
  a %= 2 * Math.PI
  if a < 0
    a += 2*Math.PI
  a

findBucket = (p) ->
  mod = p % PRECISION
  if mod < PRECISION/2
    return p - mod
  else
    return p + PRECISION - mod

# We assume positive length of neighs
computeAngles = ({x,y}, neighs) ->
  return [0] if neighs.length == 1
  angles = []
  tmp = ((Math.atan2 n.y-y, n.x-x) for n in neighs).sort()

  fst = last = tmp.shift()
  for a in tmp
    angles.push normalizeAngle(a - last)
    last = a

  angles.push normalizeAngle(fst - last)
  angles

class QuadTree
  constructor: (points) ->
    if points.length < QUAD_TREE_CELL_CAPACITY
      @points = points
      return

    # compute center
    pointsSum = { x: 0, y: 0, z: 0 }

    for p in points
      pointsSum.x += p.x ? 0
      pointsSum.y += p.y ? 0
      pointsSum.z += p.z ? 0

    @center =
      x: pointsSum.x / points.length
      y: pointsSum.y / points.length
      z: pointsSum.z / points.length

    # divide to sublists
    segments =
      true:
        true:
          true:  [] # East North Front
          false: [] # East North Back
        false:
          true:  [] # West North Front
          false: [] # West North Back
      false:
        true:
          true:  [] # East South Front
          false: [] # East South Back
        false:
          true:  [] # West South Front
          false: [] # West South Back

    for p in points
      segments[p.x > @center.x][p.y > @center.y][p.z > @center.z].push p

    # generate subtrees
    @branches =
      true:
        true:
          true:  new QuadTree segments[true][true][true]
          false: new QuadTree segments[true][true][false]
        false:
          true:  new QuadTree segments[true][false][true]
          false: new QuadTree segments[true][false][false]
      false:
        true:
          true:  new QuadTree segments[false][true][true]
          false: new QuadTree segments[false][true][false]
        false:
          true:  new QuadTree segments[false][false][true]
          false: new QuadTree segments[false][false][false]

  findPoints: (point) ->
    storage = []
    @_findPoints point, storage
    storage

  _findPoints: (point, storage) ->
    # no branches from this node
    if @points
      (storage.push p) for p in @points when approxZero dist3(p, point)
      return

    # find quadron
    bx1 = point.x > @center.x - PRECISION
    bx2 = point.x > @center.x + PRECISION
    by1 = point.y > @center.y - PRECISION
    by2 = point.y > @center.y + PRECISION
    bz1 = point.z > @center.z - PRECISION
    bz2 = point.z > @center.z + PRECISION
    bools = [bx1, bx2, by1, by2, bz1, bz2]

    findInQuadron = (node, i) ->
      if i == 6 # == bools.length
        # search in quadron
        node._findPoints point, storage
      else
        [b1, b2] = [bools[i], bools[i+1]]
        i1 = i + 2

        # select quadron by the next criterion
        findInQuadron node[b1], i1
        findInQuadron node[b2], i1  if b1 != b2

    findInQuadron @branches, 0

class Position
  constructor: (@x, @y, @angle, @penDown = true) ->

  go: (steps) ->
    [@x, @y] = computeCoords @x, @y, steps, @angle

  rotate: (a) ->
    @angle += a

class LineSegment
  constructor: (@p1, @p2) ->
    # Line equation parameters
    @a = @p1.y - @p2.y
    @b = @p2.x - @p1.x
    @c = @p1.x * @p2.y - @p2.x * @p1.y
    this

  containsPoint: (p) ->
    pointInside =
      (@p1.x - PRECISION <= p.x <= @p2.x + PRECISION ||
       @p2.x - PRECISION <= p.x <= @p1.x + PRECISION) &&
      (@p1.y - PRECISION <= p.y <= @p2.y + PRECISION ||
       @p2.y - PRECISION <= p.y <= @p1.y + PRECISION)
    liesOnLine = approxZero @a*p.x + @b*p.y + @c

    liesOnLine && pointInside

  scalarProductWith: (otherLS) ->
    @a * otherLS.b - otherLS.a * @b

  parallelTo: (otherLS) ->
    approxZero @scalarProductWith otherLS

  intersectingPointWith: (otherLS) ->
    scal = @scalarProductWith otherLS

    # solving linear equations using cramer's rule to find intersecting point
    p =
      x: (@b * otherLS.c - otherLS.b * @c) / scal
      y: (@c * otherLS.a - otherLS.c * @a) / scal

    if  (@containsPoint p) && (otherLS.containsPoint p)
      p
    else
      false

  isLengthZero: ->
    (approxZero @p1.x - @p2.x) && (approxZero @p1.y - @p2.y)

  toString: ->
    "<<LS (#{@p1.x},#{@p1.y}) -- (#{@p2.x},#{@p2.y})>>"


class EmbeddedGraph
  constructor: (startX, startY, startAngle) ->
    @lineSegments = []
    @vertices = []

    # Actual position
    @pos = new Position startX, startY, startAngle

  go: (steps) ->
    [oldX, oldY] = [@pos.x, @pos.y]
    [newX, newY] = @pos.go steps

    if @pos.penDown
      @addLineSegment {x: oldX, y: oldY}, {x: newX, y: newY}

  rotate: (a) ->
    @pos.rotate a

  penUp:   -> @pos.penDown = false
  penDown: -> @pos.penDown =  true

  sequences: ->
    angles  = []
    degrees = []
    dists   = []
    hashObj = {}

    # Collect all vertices
    points = []

    for l in @lineSegments
      # Initialise structures
      p1 = x: l.p1.x, y: l.p1.y, z: 0
      p2 = x: l.p2.x, y: l.p2.y, z: 0

      hashObj[findBucket p1.x] = {}
      hashObj[findBucket p2.x] = {}

      points.push p1
      points.push p2

      p1.neigh = p2
      p2.neigh = p1

    qt = new QuadTree points

    # Discard points inside a line segment
    for p1 in points when p1.discarded != true
      nearPoints = qt.findPoints p1
      continue  unless nearPoints.length == 2

      [neigh1,neigh2] = [nearPoints[0].neigh, nearPoints[1].neigh]

      if (new LineSegment neigh1, neigh2).containsPoint p1
        # p1's neighbours should be neighbours of themselves
        fixNeighs = (n1, n2) ->
          neigh2.neigh = neigh1
          neigh1.neigh = neigh2

        fixNeighs neigh1, neigh2
        fixNeighs neigh2, neigh1

        nearPoints[0].discarded = true
        nearPoints[1].discarded = true

    for p1 in points when p1.discarded != true
      {x,y} =
        x: findBucket p1.x
        y: findBucket p1.y

      continue  if hashObj[x][y]

      pointsNear = qt.findPoints p1
      neighs = hashObj[x][y] = []

      for p2 in pointsNear
        neighs.push p2.neigh

    for x of hashObj
      for y of hashObj[x] when hashObj[x][y] != null
        neighs = hashObj[x][y]

        degrees.push neighs.length
        angles = angles.concat computeAngles({x,y}, neighs)
        dists.push Math.sqrt(dist({x,y}, p)) for p in neighs

    return {
      angleSequence: angles.sort()
      degreeSequence: degrees.sort()
      distanceSequence: dists.sort()
    }

  addLineSegment: (from, to) ->
    # Parts of added new line (just the whole line segment at the beginning)
    M = [new LineSegment(from, to)]

    newLSs = []

    # Each line already on plane can intersects with our new line segment and
    # divide it to smaller ones.
    for l,lIdx in @lineSegments
      newM = []

      # Check if l intersects with any part of the original segment
      for m in M
        if m.parallelTo l
          # l doesn't intersects with m, keep m unchanged
          if  !(m.containsPoint l.p1) &&
              !(m.containsPoint l.p2) &&
              !(l.containsPoint m.p1)
            newM.push m

          # We know that l intersects with m, possible cases:
          # 1.:      X----|       m
          #      |------------|   l
          #
          # 2.:        X-------|  m
          #      |---------|      l
          #
          # 3.:  X-----|          m
          #         |--------|    l
          #
          # 4.:  X-------------|  m
          #         |----|        l
          #
          # X corresponds to the m.p1 point (one end of m line segment)

          # identify 1st and 2nd case
          else if l.containsPoint m.p1
            # Discard m on 1st case, otherwise shorten m
            unless l.containsPoint m.p2
              newM.push new LineSegment m.p2,
                if (dist m.p2, l.p1) < (dist m.p2, l.p2) then l.p1 else l.p2

          # otherwise we have 3rd or 4th case
          else
            # identify 3rd case
            if l.containsPoint m.p2
              newM.push new LineSegment m.p1,
                if (dist m.p1, l.p1) < (dist m.p1, l.p2) then l.p1 else l.p2

            # 4th case, m contains the whole l
            # keep just trailing parts of m
            else
              if (dist m.p1, l.p1) < (dist m.p2, l.p1)
                newM.push new LineSegment m.p1, l.p1
                newM.push new LineSegment m.p2, l.p2
              else
                newM.push new LineSegment m.p1, l.p2
                newM.push new LineSegment m.p2, l.p1

        # Not parallel, divide to smaller parts m and l when m crosses l
        else if (x = m.intersectingPointWith l) != false
          # When we hit an endpoint of a line segment, we should discard the
          # new zero-length line segment
          addNotEmpty = (p1, p2, set) ->
            ls = new LineSegment p1, p2
            set.push ls unless ls.isLengthZero()

          addNotEmpty m.p1, x, newM
          addNotEmpty m.p2, x, newM

          l1 = new LineSegment l.p1, x
          # We know that at least one segment is of length zero, because our
          # previous line had positive length
          if l1.isLengthZero()
            @lineSegments[lIdx] = new LineSegment l.p2, x
          else
            @lineSegments[lIdx] = l1
            addNotEmpty l.p2, x, newLSs

        # m doesn't intersects with l
        else
          newM.push m

      M = newM

    @lineSegments = @lineSegments.concat M, newLSs

class Simple3DGraph
  constructor: ->
    @vertices = []
    @edgeLengths = []

  # TODO cannot handle edge created from smaller edges
  markEdge: (from, to) ->
    fromV = @ensureVertex from
    toV = @ensureVertex to

    # no multiedges
    for v in fromV.edges
      if @closeEnough toV.pos, v.pos
        return

    fromV.edges.push toV
    toV.edges.push fromV

    distX = fromV.pos.x - toV.pos.x
    distY = fromV.pos.y - toV.pos.y
    distZ = fromV.pos.z - toV.pos.z
    @edgeLengths.push Math.sqrt(distX*distX+distY*distY+distZ*distZ)

  ensureVertex: (position) ->
    for vertex in @vertices
      if @closeEnough position, vertex.pos
        return vertex

    newVertex = { pos: position, edges: [] }
    @vertices.push newVertex

    return newVertex

  closeEnough: (vPos, wPos) ->
    (approxZero vPos.x - wPos.x, PREC_3D) and
    (approxZero vPos.y - wPos.y, PREC_3D) and
    (approxZero vPos.z - wPos.z, PREC_3D)

  sequences: ->
    degreeSequence: (_.map @vertices, (vertex) -> vertex.edges.length).sort()
    distanceSequence: @edgeLengths.sort()


almostEqual = (s1, s2) ->
  return false unless s1.length == s2.length

  for i in [0...s1.length]
    return false unless approxZero s1[i] - s2[i], PREC_3D

  true

sequencesEqual = (expected, given,
                  toTest = [ "degreeSequence"
                           , "angleSequence"
                           , "distanceSequence"]) ->

  degs  = !("degreeSequence"   in toTest && "degreeSequence"   of expected)
  angls = !("angleSequence"    in toTest && "angleSequence"    of expected)
  dists = !("distanceSequence" in toTest && "distanceSequence" of expected)

  degs  ||= _.isEqual   expected.degreeSequence,   given.degreeSequence
  angls ||= almostEqual expected.angleSequence,    given.angleSequence
  dists ||= almostEqual expected.distanceSequence, given.distanceSequence

  degs && angls && dists

##
## Exports
##
@graph = {
  PRECISION

  QuadTree
  Position
  LineSegment
  EmbeddedGraph
  Simple3DGraph

  # Compares two sorted sequences of distances or angles
  almostEqual

  sequencesEqual
}
module?.exports = @graph
