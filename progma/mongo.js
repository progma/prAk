var mongo = require('mongoskin');
var settings = require('./settings');

exports.db = mongo.db(settings.MONGO_URI);
