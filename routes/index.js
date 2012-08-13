
/*
 * GET home page.
 */

exports.index = function(req, res) {
  res.render('index', {
    title: 'Express',
    page: 'index',
    user: req.user,
  });
};

exports.lecture = function(req, res) {
  res.render('lecture', {
    title: 'Lecture',
    page: 'lecture',
    user: req.user,
  });
};

exports.lukas = function(req, res) {
  res.render('lukas', {
    title: 'Lukasuv mockup',
    page: 'lukas',
    user: req.user,
  });
};
