express = require 'express'
module.exports = app = express()

ROOT = "#{__dirname}/.."

app.configure ->
  app.set "views", "#{ROOT}/views"
  app.set "view engine", "jade"

  app.use express.methodOverride()
  app.use express.static("#{ROOT}/public")
  
  app.use express.bodyParser()
  app.use app.router
  
  app.use require('connect-assets')()
  
app.get '/', (req, res) -> res.render 'index'
