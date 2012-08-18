mongo = require 'mongoskin'
settings = require './settings'

exports.db = mongo.db settings.MONGO_URI
