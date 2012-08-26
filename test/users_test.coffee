users = require('../progma/users')
errors = require('../progma/errors')
db = require('../progma/mongo').db
should = require('should')


describe 'Users', ->

  beforeEach (done) ->
    db.dropDatabase (err) ->
      if err?
        done(err)

      users.createUser 'john@example.com',
        'John Doe',
        'hunter2',
        'john@example.com',
        (err, user) ->
          users.enrollUserInCourse user, 'course1', (err) ->
            users.enrollUserInCourse user, 'course2', (err) ->
              done(err)


  describe '.getUser()', ->

    it 'should not find the user', (done) ->
      users.getUser 'test@example.com',
        (err, user) ->
          should.exist(err)
          err.should.be.an.instanceOf(errors.UserNotFoundError)
          should.not.exist(user)
          done()

    it 'should find the user', (done) ->
      users.getUser 'john@example.com',
        (err, user) ->
          should.exist(user)
          done(err)


  describe '.createUser()', ->

    it 'should create new user', (done) ->
      users.createUser 'doe@example.com',
        'John Doe',
        'hunter2',
        'john@example.com',
        (err, user) ->
          should.exist(user)
          user.should.have.property('id', 'doe@example.com')
          user.should.have.property('displayName', 'John Doe')
          user.should.have.property('email', 'john@example.com')
          user.should.have.property('courses').with.lengthOf(0)
          user.should.have.property('achievements').with.lengthOf(0)
          user.should.have.property('salt')
          user.should.have.property('password')
          users.hashPassword(user.salt, 'hunter2').should.eql(user.password)
          done(err)

    it 'should return an error when the user already exists', (done) ->
      users.createUser 'john@example.com',
        'John Doe',
        'hunter2',
        'john@example.com',
        (err, user) ->
          err.should.be.an.instanceOf(errors.UserAlreadyExistsError)
          should.not.exist(user)
          done()


  describe '.updateUser()', ->

    it 'should update the user', (done) ->
      users.getUser 'john@example.com', (err, user) ->
        should.not.exist(err)
        should.exist(user)
        user.email = 'doe@example.com'
        users.updateUser user, (err) ->
          users.getUser 'john@example.com', (err, user) ->
            should.exist(user)
            user.should.have.property('email', 'doe@example.com')
            done(err)


  describe '.userExists', ->

    it 'should return false when the user does not exist', (done) ->
      users.userExists 'test@example.com', (err, exists) ->
        exists.should.be.false
        done(err)

    it 'should return true when the user exists', (done) ->
      users.userExists 'john@example.com', (err, exists) ->
        exists.should.be.true
        done(err)


  describe '.deleteUser', ->

    it 'should delete the user from db', (done) ->
      users.getUser 'john@example.com', (err, user) ->
        users.deleteUser user, (err) ->
          should.not.exist(err)
          users.getUser 'john@example.com', (err, user) ->
            err.should.be.an.instanceOf(errors.UserNotFoundError)
            done()


  describe '.checkPassword', ->

    it 'should return false when the password is incorrect', (done) ->
      users.checkPassword 'john@example.com', 'wrong password',
        (err, correct) ->
          correct.should.be.false
          done(err)

    it 'should return true when the password is correct', (done) ->
      users.checkPassword 'john@example.com', 'hunter2', (err, correct) ->
        correct.should.be.true
        done(err)


  describe '.enrollUserInCourse', ->

    it 'should add the new course to list of courses', (done) ->
      users.getUser 'john@example.com', (err, user) ->
        users.enrollUserInCourse user, 'course3', (err) ->
          should.not.exist(err)
          users.getUser 'john@example.com', (err, user) ->
            user.should.have.property('courses').with.lengthOf(3)
            user.courses.should.include('course1')
            user.courses.should.include('course2')
            user.courses.should.include('course3')
            done(err)

    it 'should return an error when the user is already enrolled in course',
      (done) ->
        users.getUser 'john@example.com', (err, user) ->
          users.enrollUserInCourse user, 'course1', (err, user) ->
            user.should.have.property('courses').with.lengthOf(2)
            err.should.be.an.instanceOf(errors.UserAlreadyEnrolledError)
            done()


  describe '.dropCourse', ->

    it 'should remove the course from list of courses', (done) ->
      users.getUser 'john@example.com', (err, user) ->
        users.dropCourse user, 'course1', (err, user) ->
          user.should.have.property('courses').with.lengthOf(1)
          user.courses.should.include('course2')
          done(err)

    it 'should return an error when the user is not enrolled in course',
      (done) ->
        users.getUser 'john@example.com', (err, user) ->
          users.dropCourse user, 'course00', (err, user) ->
            user.should.have.property('courses').with.lengthOf(2)
            err.should.be.an.instanceOf(errors.UserNotEnrolledError)
            done()


  describe '.listCourses', ->

    it 'should return a list of courses', (done) ->
      users.getUser 'john@example.com', (err, user) ->
        users.listCourses user, (err, courses) ->
          courses.should.have.length(2)
          courses.should.include('course1')
          courses.should.include('course2')
          done(err)


