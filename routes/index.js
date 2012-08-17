var crypto = require('crypto');
var mongo = require('../progma/mongo').db;

/*
 * GET home page.
 */

exports.index = function(req, res) {
  res.render('index', {
    title: 'Express',
    page: 'index',
    user: req.user,
    errors: req.flash('error'),
  });
};

exports.lecture = function(req, res) {
  res.render('lecture', {
    title: 'Lecture',
    page: 'lecture',
    user: req.user,
    errors: req.flash('error'),
  });
};

exports.lukas = function(req, res) {
  res.render('lukas', {
    title: 'Lukasuv mockup',
    page: 'lukas',
    user: req.user,
    errors: req.flash('error'),
  });
};

exports.login = function(req, res) {
  res.render('login', {
    title: 'Login',
    page: 'login',
    user: req.user,
    errors: req.flash('error'),
  });
};

exports.get_register = function(req, res) {
  res.render('register', {
    title: 'Registration',
    page: 'registration',
    user: req.user,
    errors: req.flash('error'),
  });
}

exports.post_register = function(req, res, next, passport) {
  mongo.collection('user').findOne({
      id: req.body.username.toLowerCase(),
    },
    function(err, user) {
      if (err) {
        return res.redirect(500);
      }

      if (user) {
        req.flash('error', 'User already exist.');
        return res.redirect('/login');
      }

      var shasum = crypto.createHash('sha1');
      shasum.update(req.body.password);

      var new_user = {
        id: req.body.username.toLowerCase(),
        displayName: req.body.username,
        password: shasum.digest(),
      }

      mongo.collection('users').insert(new_user, function(err, result) {
        if (err) {
          return res.redirect(500);
        }

        passport.authenticate('local', {
          successRedirect: '/',
          failureRedirect: '/register',
          failureFlash: true,
        })(req, res, next);
      });
    });
  };
