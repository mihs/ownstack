var express = require('express')
var app = express()
var morgan = require('morgan')

app.use(morgan('combined'))

app.get('/', function (req, res) {
  res.send('/ OK')
})

app.get('/error', function(req, res) {
  console.error(new Error().stack)
  res.sendStatus(500)
})

app.listen(parseInt(process.env.port) || 8080, function () {
  console.log('Started')
})
