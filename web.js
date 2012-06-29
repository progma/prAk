var static = require('node-static'),
  http = require('http'),
  util = require('util');
var webroot = './',
  port = process.env.PORT || 5000;
var file = new(static.Server)(webroot, {
  cache: 600,
  headers: { 'X-Powered-By': 'node-static' }
});
http.createServer(function(req, res) {
  req.addListener('end', function() {
    if (req["url"] === "/")
    {
        req["url"] = "/mockup.html";
    }
    file.serve(req, res, function(err, result) {
      if (err) {
        console.error('Error serving %s - %s', req.url, err.message);
        res.writeHead(err.status, err.headers);
        res.end();
      } else {
        console.log('%s - %s', req.url, res.message);
      }
    });
  });
}).listen(port);
console.log('node-static running at http://localhost:%d', port);
