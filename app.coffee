express = require 'express'


ASSET_BUILD_PATH = 'server/client_build/development'
PORT = process.env.PORT ? 3000
WHITELISTED_URLS = ['/favicon.ico']

# controllers
publicController = require './server/controllers/public_controller'
job = require './server/jobs/feed_job'

app = express()
app.configure ->
  # jade templates from templates dir
  app.use express.compress()
  app.set 'views', "#{__dirname}/server/templates"
  app.set 'view engine', 'jade'
  
  # serve static assets
  app.use('/assets', express.static("#{__dirname}/#{ASSET_BUILD_PATH}"))
  
  # needed for body parsing and session usage
  app.use express.cookieParser()
  app.use express.bodyParser()
  
  # logging
  app.use express.logger()
  
# public routes
app.get '/', publicController.index
app.get '/rss', publicController.rss

job.schedule()
module.exports = app
