exports.return404 = (req, res) ->
	res.status(404)
	res.render '404',
	  title: 'prAk – Stránka nebyla nalezena'
	  page: '404'
	  user: req.user
	  errors: req.flash 'error'