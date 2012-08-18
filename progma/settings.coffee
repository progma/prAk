exports.PORT = process.env.PORT || 3000
exports.URL = process.env.URL || "http://localhost:" + exports.PORT
exports.MONGO_DB = process.env.MONGOLAB_DB || "test"
exports.MONGO_URI = process.env.MONGOLAB_URI ||
  "mongodb://localhost:27017/" + exports.MONGO_DB
exports.SECRET = process.env.SECRET || "public secret"
