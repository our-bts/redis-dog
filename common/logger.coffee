path = require("path")
conf = require("../conf.json")
mkdirp = require("mkdirp")
util = require("util")
dUtil = require("date-utils")
log4js = require("log4js")
log4js.configure path.join(__dirname, "../log4js.json"),
  reloadSecs: 60
  cwd: __dirname

logger = log4js.getLogger()
errorLogger = log4js.getLogger("errors")
mkdirp path.join(__dirname, "../logs")

exports.log = ->
  args = util.format.apply(this, arguments)
  logger.info args

#this.consoleLog(args);
exports.error = ->
  args = util.format.apply(this, arguments)
  errorLogger.error args
  #@consoleError args

exports.errorWithoutMail = ->
  args = util.format.apply(this, arguments)
  errorLogger.error args
  #@consoleError args

exports.consoleLog = (args) ->
  blue = undefined
  reset = undefined
  blue = "\u001b[36m"
  reset = "\u001b[0m"
  if conf.isDebug is true
    console.log blue + "Log: "
    console.log "Date: " + (new Date()).toFormat("YYYY-MM-DD HH24:MI:SS:LL")
    console.log "Content: " + args
    console.log reset

exports.consoleError = (args) ->
  red = undefined
  reset = undefined
  red = "\u001b[31m"
  reset = "\u001b[0m"
  if conf.isDebug is true
    console.log red + "Error: "
    console.log "Date: " + (new Date()).toFormat("YYYY-MM-DD HH24:MI:SS:LL")
    console.log "Content: " + args
    console.log reset