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