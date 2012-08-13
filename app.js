
/**
 * Module dependencies.
 */

var express = require('express'),
  routes = require('./routes'),
  http = require('http'),
  redis = require('./progma/redis'),
  redisClient = redis.createClient(),
  RedisStore = require('connect-redis')(express),
  passport = require('passport'),
  GoogleStrategy = require('passport-google').Strategy,
  FacebookStrategy = require('passport-facebook').Strategy;

var app = express();

/**
 * Set up passport.
 */

passport.use(new GoogleStrategy({
    returnURL: process.env.URL + '/auth/google/return',
    realm: process.env.URL,
  },
  function(identifier, profile, done) {
    console.log(identifier);
    console.log(profile);
    profile.id = identifier;
    done(null, profile);
  }
));

passport.use(new FacebookStrategy({
    clientID: "274343352671549",
    clientSecret: "6241e9f761c99945de8c0b24fd1558ba",
    callbackURL: process.env.URL + '/auth/facebook/return',
  },
  function(accessToken, refreshToken, profile, done) {
    console.log(profile);
    done(null, profile);
  }
));

passport.serializeUser(function(user, done) {
  redisClient.set(user.id, JSON.stringify(user), function(err, reply) {
    done(err, user.id);
  });
});

passport.deserializeUser(function(id, done) {
  redisClient.get(id, function(err, reply) {
    var user = JSON.parse(reply);
    if (user == null) {
      done(null, false);
    } else {
      done(err, user);
    }
  });
});

/**
 * Configure application.
 */

app.configure(function(){
  app.set('port', process.env.PORT || 3000);
  app.set('views', __dirname + '/views');
  app.set('view engine', 'jade');
  app.use(express.favicon());
  app.use(express.logger('dev'));
  app.use(express.cookieParser());
  app.use(express.bodyParser());
  app.use(express.session({
    secret: "a184395e6926a87cf6d5fbeeb7e18bee",
    store: new RedisStore({
      client: redisClient,
    }),
  }));
  app.use(express.methodOverride());

  app.use(passport.initialize());
  app.use(passport.session());

  app.use(app.router);
  app.use(express.static(__dirname + '/public'));
});

app.configure('development', function(){
  app.use(express.errorHandler());
});

/**
 * Routes
 */

app.get('/', routes.index);
app.get('/lecture', routes.lecture);
app.get('/lukas', routes.lukas);

/**
 * Passport routes.
 */

app.get('/auth/google', passport.authenticate('google'));
app.get('/auth/google/return', passport.authenticate('google',
  {
    successRedirect: '/',
    failureRedirect: '/login',
  }
));

app.get('/auth/facebook', passport.authenticate('facebook'));
app.get('/auth/facebook/return', passport.authenticate('facebook',
  {
    successRedirect: '/',
    failureRedirect: '/login',
  }
));

app.get('/logout', function(req, res) {
  req.logOut();
  res.redirect('/');
});

/**
 * Create server.
 */

http.createServer(app).listen(app.get('port'), function(){
  console.log("Express server listening on port " + app.get('port'));
});
