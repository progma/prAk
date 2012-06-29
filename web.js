var staticFiles = new (static.Server)("static");

server = http.createServer(function(request, response) {
 request.addListener('end', function() {
  staticFiles.serve(request, response);
 });
});

var port = process.env.PORT || 3000;
server.listen(port);
console.log("Static Content Server Started");
