express = require("express")
path = require("path")
logger = require("./common/logger")
redisHandler = require("./handlers/redisHandler")
conf = require("./conf.json")
crc32 = require("easy-crc32")

process.on "uncaughtException", (err) ->
  logger.error("#{err.stack}")

app = express()
application_root = __dirname
run_id_crc32 = null
port = conf.port || 8433

app.configure ->
  app.use express.urlencoded({limit: '10mb'})
  app.use express.json({limit: '10mb'})
  app.use express.methodOverride()
  app.use app.router
  app.use express.errorHandler
    dumpExceptions: true,
    showStack: true

app.get "/databases/:DBID/:Command/:Key?/:EntryKey?", (req, res) ->
  #logger.log req.params.Key
  commandText = req.params.Command.toLowerCase()
  execRequest(commandText, req, res)

app.get "/faq", (req, res) ->
  redisHandler.ping (isAlive)->
    if(isAlive is false)
      res.json 500, {error: "redis connection is unhealthy."}
    else
      res.json 200, {redis:"ok"}
    res.end()

app.put "/databases", (req, res) ->
  #logger.log req.body
  if(not req.body.Command?)
    message = "bad request: not found command."
    logger.errorWithoutMail(message)
    res.json 400, {error: message}
    return

  commandText = req.body.Command.toLowerCase()
  execRequest(commandText, req, res)

execRequest = (commandText, req, res) ->
  commandFunc = redisHandler[commandText]

  if(typeof(commandFunc) isnt "function")
    message = "unknown command: #{commandText}"
    logger.errorWithoutMail message
    res.json 400, {error: message}
    return

  if(redisHandler.isHealthy() is false)
    message = "could not handle command: #{commandText}, redis connection is unhealthy."
    logger.errorWithoutMail message
    res.json 500, {error: message}
    return

  ###
  if(not run_id_crc32?)
    run_id_crc32 = crc32.calculate(redisHandler.info().run_id)
  
  if(req.body.Ridc is run_id_crc32)
    logger.log "[ignore myself]DBID:#{req.body.DBID}, Command: #{req.body.Command}, Key: #{req.body.Key}"
    res.statusCode = 204
    res.end()
    return
  ###

  commandFunc req, res, ->
    res.end()

server = app.listen port, ->
  logger.log("Redis dog listening on port #{port}")

server.on 'connection', (socket) ->
  #30 second timeout. the default value is 120.
  socket.setTimeout(30 * 1000) 
  