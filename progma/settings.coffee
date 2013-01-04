exports.PORT = process.env.PORT || 3000
exports.URL = process.env.URL || "http://brun.cz:" + exports.PORT
exports.MONGO_DB = process.env.MONGOLAB_DB || "test"
exports.MONGO_URI = "mongodb://testovaci_prak:testovaci_prak@ds037047.mongolab.com:37047/heroku_app6660443"
exports.SECRET = process.env.SECRET || "public secret"
exports.FACEBOOK_SECRET = process.env.FACEBOOK_SECRET || "no secret"
