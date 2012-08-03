
/*
 * GET home page.
 */

exports.index = function(req, res) {
  res.render('index', { title: 'Express', page: 'index' });
};

exports.lecture = function(req, res) {
  res.render('lecture', { title: 'Lecture', page: 'lecture' });
};

exports.lukas = function(req, res) {
  res.render('lukas', { title: 'Lukasuv mockup', page: 'lukas' });
};
