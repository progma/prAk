
/*
 * GET home page.
 */

exports.index = function(req, res) {
  res.render('index', { title: 'Express' });
};

exports.lecture = function(req, res) {
  res.render('lecture', { title: 'Lecture' });
};
