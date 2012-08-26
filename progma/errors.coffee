
# Hack to support real inheritance for builtin Error
# Source: http://stackoverflow.com/a/8460753/495305
BaseError = (message) ->
  this.constructor.prototype.__proto__ = Error.prototype
  Error.captureStackTrace(this, this.constructor)
  this.name = this.constructor.name
  this.message = message

#
# User errors.
#
class UserError extends BaseError
  constructor: (message) ->
    @type = "users"
    super(message)

class UserNotFoundError extends UserError
  constructor: ->
    super("User not found.")

class UserAlreadyExistsError extends UserError
  constructor: ->
    super("User already exists.")

class UserAlreadyEnrolledError extends UserError
  constructor: ->
    super("User is already enrolled in this course.")

class UserNotEnrolledError extends UserError
  constructor: ->
    super("User is not enrolled in this course.")

#
# Exported classes.
#
exports.BaseError = BaseError
exports.UserError = UserError
exports.UserNotFoundError = UserNotFoundError
exports.UserAlreadyExistsError = UserAlreadyExistsError
exports.UserAlreadyEnrolledError = UserAlreadyEnrolledError
exports.UserNotEnrolledError = UserNotEnrolledError
