var express = require('express');
var fetch = require('node-fetch');
var path = require('path');
var queryString = require('querystring');

var app = express();

app.use(express.static(path.resolve(__dirname + '/../../')));

app.use('/api', function(req, res) {
    fetch('https://api.twitter.com/1.1' + req.path + '?' + queryString.stringify(req.query), {
        method: req.method,
        headers: {
            "Authorization": "Bearer AAAAAAAAAAAAAAAAAAAAAJR5ugAAAAAAYs%2BlOKeM3f4ftYKUfZqn3ohbuVQ%3DOAxp4zKeDh4g2DHXLXM92BFc48FOnQGWxMswOz6i7qvhSNtdfY",
            "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8"
        }
    })
    .then(function(res) { return res.json();})
    .then(function(json) {
        res.json(json)
    });
})

app.listen(3000, function() {
    console.log('Twitter Search app listening on port 3000');
})