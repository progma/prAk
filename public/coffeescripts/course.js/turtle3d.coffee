ex = @examine ? require './examine'

parameters =
# These parameters are read only in init.
  WIDTH: 380
  HEIGHT: 480

  # This controls the level of detail, the roundness, of the cylinders
  # dropped by the turtle.
  SEGMENTS: 10

  FIELD_OF_VIEW: 75
  FRUSTUM_NEAR: 0.1
  FRUSTUM_FAR: 1000000
# These parameters are also read in run.
  CAMERA_DISTANCE: 400

  TURTLE_START_POS: new THREE.Vector3(0, 0, 0)
  TURTLE_START_DIR: new THREE.Vector3(0, 1, 0)
  TURTLE_START_UP: new THREE.Vector3(0, 0, 1)
  TURTLE_START_COLOR: 0xFF0000
  TURTLE_START_WIDTH: 5

  DIR_LIGHT_COLOR: 0xFFFFFF
  DIR_LIGHT_POS: new THREE.Vector3(1, 1, 1)
  DIR_LIGHT_TARGET: new THREE.Vector3(0, 0, 0)

  AMB_LIGHT_COLOR: 0x555555

  BACKGROUND_COLOR: 0x00FFFF


deg2rad = (degrees) ->
  degrees / 360 * 2 * Math.PI

# Returns an arbitrary vector perpendicular to vec.
getPerpVec = (vec) ->
  if vec.z == 0
    new THREE.Vector3(0, 0, 1)
  else if vec.y == 0
    new THREE.Vector3(0, 1, 0)
  else
    new THREE.Vector3(0, 1, -(vec.y / vec.z))

# My "global" variables.
turtleGeometry = undefined
camera = undefined
controls = undefined
scene = undefined


# Our turtle in space. Maintains its position in space, a unit
# direction vector (where is the turtle pointing now), a unit up
# vector (the direction the turtle's back is pointing), the shading
# material used to paint the current droppings, the width of the
# current droppings, the trail of droppings the turtle has painted
# and whether it is drawing more now. See the constructor for details.
class Turtle3D
  constructor: (@position, @direction, @up, @material, @width) ->
    @direction.normalize()
    @up.normalize()
    @droppings = []
    @drawing = on
    @graph = new graph.Simple3DGraph()

  go: (distance) ->
    newPosition = new THREE.Vector3()
    newPosition.add(@position, @direction.clone().multiplyScalar(distance))
    if @drawing
      @droppings.push({ from: @position
                      , to: newPosition
                      , material: @material
                      , width: @width })

    @graph.markEdge { x: @position.x, y: @position.y, z: @position.z }, { x: newPosition.x, y: newPosition.y, z: newPosition.z }

    @position = newPosition

  yaw: (angle) ->
    # When we want to change the yaw, we rotate around our 'up' vector.
    # This also means the 'up' vector doesn't change.
    rotation = new THREE.Matrix4().makeRotationAxis @up, deg2rad angle
    rotation.multiplyVector3 @direction
    # Funny JavaScript numbers let our unit vectors grow all the way
    # to NaN if we don't normalize them from time to time. Here, I just
    # normalize them every time I change them.
    @direction.normalize()

  pitch: (angle) ->
    # Changing the pitch means rotating around our 'right' axis. We
    # don't store this one but we can easily compute it using the
    # cross product of 'direction' and 'up'.
    right = new THREE.Vector3().cross(@direction, @up).normalize()
    rotation = new THREE.Matrix4().makeRotationAxis right, deg2rad angle
    rotation.multiplyVector3 @direction
    @direction.normalize()
    rotation.multiplyVector3 @up
    @up.normalize()

  roll: (angle) ->
    # Changing the roll means rotating around our 'direction',
    # therefore 'direction' doesn't have to change at all.
    rotation = new THREE.Matrix4().makeRotationAxis @direction, deg2rad angle
    rotation.multiplyVector3 @up
    @up.normalize()

  penUp: ->
    @drawing = off

  penDown: ->
    @drawing = on

  setWidth: (@width) ->

  setMaterial: (@material) ->

  setColor: (hex) ->
    @setMaterial(new THREE.MeshLambertMaterial({ color: hex
                                               , ambient: hex }))

  # Returns meshes for all the droppings left by the turtle.
  retrieveMeshes: ->
    for {from, to, material, width} in @droppings
      distance = from.distanceTo to

      mesh = new THREE.Mesh(turtleGeometry, material)

      # Calculate the desired dimensions of the trail. Support for
      # different values of bottomRadius and topRadius are from a
      # previous design, it doesn't hurt to have it here so we don't
      # have to research the shearing matrix again if we need it later
      # again.
      bottomRadius = width
      topRadius = width
      height = distance
      shearFactor = (topRadius - bottomRadius) / height

      # I construct the matrix to scale, rotate and position the
      # trail. The transformations are multiplied onto the matrix in
      # the opposite order they are applied, so read from the bottom.
      # Also, order matters. Generally, you want to do scaling first,
      # then rotation and finally translation.
      turtleTransform = new THREE.Matrix4()
      # 4. Finally, we position the whole thing in the correct
      # starting position.
      turtleTransform.translate(from)
      # 3. Rotate the cylinder so that it is pointing from one path
      # node to the next. The third argument is a mandatory 'up'
      # direction. Since we do not care about 'up' when rendering, I
      # just compute some arbitrary vector perpendicular to the
      # direction of sight.
      turtleTransform.lookAt(from, to, getPerpVec(to.clone().subSelf(from)))
      # 2. Use a shearing transformation to make the cylinder have a
      # different radius on the top.
      turtleTransform.multiplySelf(new THREE.Matrix4(1, shearFactor, 0, 0,
                                                     0,           1, 0, 0,
                                                     0, shearFactor, 1, 0,
                                                     0,           0, 0, 1))
      # 1. Scale the cylinder so its radius and height are of the
      # desired magnitude.
      turtleTransform.scale(new THREE.Vector3(bottomRadius, bottomRadius, height))

      mesh.applyMatrix(turtleTransform)
      mesh


init = (canvas) ->
  # We take the cylinder geometry, which is constantly dropped behind
  # by the turtle, and rearrange it a little. We move the pivot,
  # the origin of the geometries' vertices, so that it lies
  # in the bottom center of the cylinder and we rotate it so that
  # Y axis points in the Z axis (this means that now if we orient
  # the cylinder using lookAt, the axis of the cylinder will point
  # towards the target). parameters.PS: The transformations have to be multiplied
  # onto the resulting matrix in the opposite order to the one
  # in which we want to perform them.
  turtleGeometry = new THREE.CylinderGeometry(1, 1, 1, parameters.SEGMENTS)
  normalizationMatrix = new THREE.Matrix4()
  normalizationMatrix.rotateX(Math.PI / 2)
  normalizationMatrix.translate(new THREE.Vector3(0, -0.5, 0))
  turtleGeometry.applyMatrix(normalizationMatrix)

  rendererParams =
    canvas: canvas
    clearColor: parameters.BACKGROUND_COLOR
    clearAlpha: 1
  try
    renderer = new THREE.WebGLRenderer(rendererParams)
  catch e
    console.log "loading WebGLRenderer failed, trying CanvasRenderer"
    renderer = new THREE.CanvasRenderer(rendererParams)

  renderer.setSize parameters.WIDTH, parameters.HEIGHT
  #$(parentElement).append renderer.domElement

  camera = new THREE.PerspectiveCamera(parameters.FIELD_OF_VIEW,
                                       parameters.WIDTH / parameters.HEIGHT,
                                       parameters.FRUSTUM_NEAR,
                                       parameters.FRUSTUM_FAR)
  camera.position.set(0, 0, parameters.CAMERA_DISTANCE)
  # This doesn't matter, as after something is rendered, the camera is
  # controlled by the OrbitControls, whose 'center' we set to the
  # centroid of the rendered stuff.
  camera.lookAt(new THREE.Vector3(0, 0, 0))

  controls = new THREE.OrbitControls(camera, renderer.domElement)

  scene = new THREE.Scene()

  animate = ->
    # This causes the browser to call our animate repeatedly in some
    # way which is suitable for graphics rendering.
    requestAnimationFrame animate
    controls.update()
    renderer.render scene, camera

  animate()

  return renderer.domElement

# Since my Turtle3D is a nice object with its own fields and I
# want to use its methods as global function in a global context,
# I export them like this.
environment = (myTurtle) ->
  go: (distance) -> myTurtle.go(distance)
  left: (angle) -> myTurtle.yaw(angle)
  right: (angle) -> myTurtle.yaw(-angle)
  up: (angle) -> myTurtle.pitch(angle)
  down: (angle) -> myTurtle.pitch(-angle)
  rollLeft: (angle) -> myTurtle.roll(-angle)
  rollRight: (angle) -> myTurtle.roll(angle)
  penUp: -> myTurtle.penUp()
  penDown: -> myTurtle.penDown()
  color: (hex) -> myTurtle.setColor(hex)
  width: (width) -> myTurtle.setWidth(width)

  repeat: (n, f, args...) ->
    i = 0
    f args... while i++ < n

constants =
  white: 0xFFFFFF
  yellow: 0xFFFF00
  fuchsia: 0xFF00FF
  aqua: 0x00FFFF
  red: 0xFF0000
  lime: 0x00FF00
  blue: 0x0000FF
  black: 0x000000
  green: 0x008000
  maroon: 0x800000
  olive: 0x808000
  purple: 0x800080
  gray: 0x808080
  navy: 0x000080
  teal: 0x008080
  silver: 0xC0C0C0

  brown: 0x552222
  orange: 0xCC3232


run = (turtleCode, shadow, draw = true) ->
  material = new THREE.MeshLambertMaterial({ color: parameters.TURTLE_START_COLOR
                                           , ambient: parameters.TURTLE_START_COLOR })

  myTurtle = new Turtle3D(parameters.TURTLE_START_POS.clone(),
                          parameters.TURTLE_START_DIR.clone(),
                          parameters.TURTLE_START_UP.clone(),
                          material,
                          parameters.TURTLE_START_WIDTH)

  result = ex.test
    code: turtleCode
    environment: environment(myTurtle)
    constants: constants
  turtle3d.sequences = myTurtle.graph.sequences()
  return   unless draw

  try

    # We dump the old scene and populate a new one.
    scene = new THREE.Scene()

    meshes = myTurtle.retrieveMeshes()
    for mesh in meshes
      scene.add(mesh)

    # simple helper
    helper = new THREE.AxisHelper()
    newZ = myTurtle.direction
    newY = myTurtle.up
    newX = new THREE.Vector3().cross(newZ, newY)
    rotationMatrix = new THREE.Matrix4(newX.x, newY.x, newZ.x, 0,
                                       newX.y, newY.y, newZ.y, 0,
                                       newX.z, newY.z, newZ.z, 0,
                                            0,      0,      0, 1)
    helper.applyMatrix(rotationMatrix)
    helper.position = myTurtle.position
    scene.add(helper)

    centroid = new THREE.Vector3()
    for mesh in meshes
      centroid.addSelf(mesh.position)
    centroid.divideScalar(meshes.length)

    # We center the camera around the centroid of the generated geometry.
    camera.position = new THREE.Vector3(0, 0, parameters.CAMERA_DISTANCE).addSelf(centroid)
    controls.center = centroid

    dirLight = new THREE.DirectionalLight(parameters.DIR_LIGHT_COLOR)
    dirLight.position = parameters.DIR_LIGHT_POS.clone()
    dirLight.target.position = parameters.DIR_LIGHT_TARGET.clone()
    scene.add(dirLight)

    ambLight = new THREE.AmbientLight(parameters.AMB_LIGHT_COLOR)
    scene.add(ambLight)
  catch e
    console.log "Problem while turtle drawing."
  finally
    return result

@turtle3d = {
  sequences: null
  Turtle3D
  init
  run
  parameters
}
module?.exports = @turtle3d
