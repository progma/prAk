db = require('./mongo').db
errors = require('./errors')
crypto = require('crypto')

# Check if user exists.
exports.userExists = (userId, callback) ->
  db.collection('users').findOne { id: userId },
    (err, user) ->
      # Server error.
      if err?
        return callback(err, null)

      # Second argument will be true if the user exists.
      return callback(null, user?)


# Get user if exists.
exports.getUser = (userId, callback) ->
  # Find user in database.
  db.collection('users').findOne { id: userId },
    (err, user) ->
      # Server error.
      if err?
        return callback(err, null)

      # User doesn't exist.
      unless user?
        return callback(new errors.UserNotFoundError(), null)

      # Return user.
      return callback(null, user)


# Create new user if doesn't exist.
exports.createUser = (userId, displayName, password, email, callback) ->
  exports.userExists userId,
    (err, exists) ->
      # Server error.
      if err?
        return callback(err, null)

      # User already exists.
      if exists
        return callback(new errors.UserAlreadyExistsError(), null)

      # Create salt and password
      salt = new Date().getTime()
      passwordHash = exports.hashPassword(salt, password)

      # Create new user.
      user =
        id: userId
        displayName: displayName
        salt: salt
        password: passwordHash
        email: email
        courses: []
        achievements: []

      # Save new user in database.
      db.collection('users').insert user,
        (err, result) ->
          # Check that the number of results is 1.
          if result.length != 1
            return callback(new errors.UserError("Wrong number of results."),
              null)

          callback(err, result[0])


# Update user.
exports.updateUser = (user, callback) ->
  db.collection('users').update({ id: user.id }, user, callback)


# Delete user.
exports.deleteUser = (user, callback) ->
  db.collection('users').remove({ id: user.id }, callback)


# Check password.
exports.checkPassword = (userId, password, callback) ->
  exports.getUser userId,
    (err, user) ->
      # Server error.
      if err?
        return callback(err, null)

      # User doesn't exist.
      unless user?
        return callback(new errors.UserNotFoundError(), null)

      # Create hash from saved salt and given password.
      passwordHash = exports.hashPassword(user.salt, password)
      return callback(null, passwordHash == user.password)


# Enroll user in course.
exports.enrollUserInCourse = (user, courseId, callback) ->
    # User is already enrolled in the course.
    if courseId in user.courses
      return callback(new errors.UserAlreadyEnrolledError(), user)

    # Append the course id to the list of courses.
    user.courses.push(courseId)

    # Save the changes.
    exports.updateUser(user)

    callback(null, user)


# Drop course.
exports.dropCourse = (user, courseId, callback) ->
  # User is not enrolled in the course.
  unless courseId in user.courses
    return callback(new errors.UserNotEnrolledError(), user)

  # Remove the course from user's courses.
  courseIndex = user.courses.indexOf(courseId)
  user.courses[courseIndex..courseIndex] = []

  # Save the changes.
  exports.updateUser(user)

  callback(null, user)


# List courses in which the user is enrolled.
exports.listCourses = (user, callback) ->
  callback(null, user.courses)


# Hash password with salt.
exports.hashPassword = (salt, password, callback) ->
  shasum = crypto.createHash('sha1')
  shasum.update('' + salt)
  shasum.update(password)
  return shasum.digest('hex')


