'use strict';

/**
 * Module dependencies.
 */

var crypto = require('crypto');
var express = require('express');
var flash = require('connect-flash');
var http = require('http');
var mongo = require('./progma/mongo').db;
var MongoStore = require('connect-mongo')(express);
var passport = require('passport');
var passportUtils = require('./progma/passport');
var routes = require('./routes');
var settings = require('./progma/settings');

var app = express();

/**
 * Set up passport.
 */

passport.use(passportUtils.googleAuth());
passport.use(passportUtils.facebookAuth());
passport.use(passportUtils.localAuth());

passport.serializeUser(passportUtils.serializeUser);
passport.deserializeUser(passportUtils.deserializeUser);

/**
 * Configure application.
 */

app.configure(function () {
  app.set('port', settings.PORT);
  app.set('views', __dirname + '/views');
  app.set('view engine', 'jade');
  app.use(express.favicon());
  app.use(express.logger('dev'));
  app.use(express.cookieParser());
  app.use(express.bodyParser());
  app.use(flash());
  app.use(express.session({
    secret: "a184395e6926a87cf6d5fbeeb7e18bee",
    store: new MongoStore({
      url: settings.MONGO_URI,
      db: settings.MONGO_DB,
    }),
  }));
  app.use(express.methodOverride());

  app.use(passport.initialize());
  app.use(passport.session());

  app.use(app.router);
  app.use(express.static(__dirname + '/public'));
});

app.configure('development', function () {
  app.use(express.errorHandler());
});

/**
 * Routes
 */

app.get('/', routes.index);
app.get('/lecture', routes.lecture);
app.get('/lukas', routes.lukas);

app.get('/login', routes.login);
app.post('/login', passport.authenticate('local', {
  successRedirect: '/',
  failureRedirect: '/login',
  failureFlash: true,
}));

app.get('/register', routes.get_register);
app.post('/register', function (req, res, next) {
  routes.post_register(req, res, next, passport);
});

app.get('/logout', function (req, res) {
  req.logOut();
  res.redirect('/');
});

app.get('/auth/google', passport.authenticate('google'));
app.get('/auth/google/return', passport.authenticate('google', {
  successRedirect: '/',
  failureRedirect: '/login',
  failureFlash: true,
}));

app.get('/auth/facebook', passport.authenticate('facebook'));
app.get('/auth/facebook/return', passport.authenticate('facebook', {
  successRedirect: '/',
  failureRedirect: '/login',
  failureFlash: true,
}));

/**
 * Create server.
 */

http.createServer(app).listen(app.get('port'), function () {
  console.log("Express server listening on port " + app.get('port'));
});
