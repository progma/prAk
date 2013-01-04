exports.PORT = process.env.PORT || 3000
exports.URL = process.env.URL || "http://brun.cz:" + exports.PORT
exports.MONGO_DB = process.env.MONGOLAB_DB || "test"
exports.MONGO_URI = process.env.MONGOLAB_URI ||
  "mongodb://localhost:27017/" + exports.MONGO_DB
exports.SECRET = process.env.SECRET || "public secret"
exports.FACEBOOK_SECRET = process.env.FACEBOOK_SECRET || "no secret"
