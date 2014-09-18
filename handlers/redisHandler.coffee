redis = require("redis")
logger = require("../common/logger")
conf = require("../conf.json")
async = require("async")

isHealthy = false
redisClient = redis.createClient(conf.redisServer.port, conf.redisServer.host, {retry_max_delay: 30 * 1000})

redisClient.on "ready", ->
  isHealthy = true
  logger.log "Redis is ready to receive commands."

redisClient.on "error", (err) ->
  #isHealthy = false #maybe SyntaxError
  logger.error "Redis Error: " + err

redisClient.on "end", (err) ->
  isHealthy = false
  logger.error "Redis connection is closed"

exports.isHealthy = ->
  return isHealthy

exports.ping = (callback) ->
  redisClient.ping (err, res)->
    isAlive = true
    if(err?)
      isAlive = false
    callback isAlive

exports.info = ->
  return redisClient.server_info

###
{
"DBID":4,
"Command":"hmset",
"Key":"zeetest",
"Value":{
  "Key":"123",
  "Value": "test123"
},
"Timestamp":""
}
###
exports.hset = (req, res, callback) ->
  action = ->
    params = []
    params.push req.body.Key

    entry = req.body.Value
    params.push entry.Key
    if(typeof(entry.Value) is 'object')
      params.push JSON.stringify(entry.Value)
    else
      params.push entry.Value

    #logger.log params
    redisClient.hset params, ->
      logger.log "DBID:#{req.body.DBID}, Command: #{req.body.Command}, Key: #{req.body.Key}"
      res.statusCode = 204
      callback()
  execCommand req.body.DBID, req, res, action, callback

###
{
"DBID":4,
"Command":"hmset",
"Key":"zeetest",
"Value":[{
  "Key":"123",
  "Value": "test123"
},
{
  "Key":"12345",
  "Value": {"id":"1","name":"zh61" }
}],
"Timestamp":""
}
###
exports.hmset = (req, res, callback) ->
  action = ->
    params = []
    params.push req.body.Key
    for entry in req.body.Value
      do (entry) ->
        params.push entry.Key
        if(typeof(entry.Value) is 'object')
          params.push JSON.stringify(entry.Value)
        else
          params.push entry.Value

    #for datakey,datavalue of req.body.value
    #params.push datakey
    #params.push JSON.stringify(datavalue)

    #logger.log params
    redisClient.hmset params, ->
      logger.log "DBID:#{req.body.DBID}, Command: #{req.body.Command}, Key: #{req.body.Key}"
      res.statusCode = 204
      callback()
  execCommand req.body.DBID, req, res, action, callback

###
{
"DBID":4,
"Command":"hdel",
"Key":"urn:Configuration",
"Value":["1277","1282"],
"Timestamp":""
}
###
exports.hdel = (req, res, callback) ->
  action = ->
    params = []
    params.push req.body.Key
    for entryKey in req.body.Value
      params.push entryKey

    #logger.log params
    redisClient.hdel params, ->
      logger.log "DBID:#{req.body.DBID}, Command: #{req.body.Command}, Key: #{req.body.Key}"
      res.statusCode = 204
      callback()
  execCommand req.body.DBID, req, res, action, callback

exports.del = (req, res, callback) ->
  action = ->
    params = []
    for key in req.body.Key
      params.push key

    #logger.log params
    redisClient.del params, ->
      logger.log "DBID:#{req.body.DBID}, Command: #{req.body.Command}, Key: #{req.body.Key}"
      res.statusCode = 204
      callback()
  execCommand req.body.DBID, req, res, action, callback

exports.hget = (req, res, callback) ->
  action = ->
    params = []
    params.push req.params.Key
    params.push req.params.EntryKey

    #logger.log params
    redisClient.hget params, (err, data) ->
      if (err?) 
        throw(err)

      #logger.log "DBID:#{req.params.DBID}, Command: #{req.params.Command}, Key: #{req.params.Key}"
      res.json 200, JSON.parse(data)
      callback()
  execCommand req.params.DBID, req, res, action, callback

#/hvals/{hashId}
exports.hvals = (req, res, callback) ->
  action = ->
    redisClient.hvals req.params.Key, (err, data) ->
      if (err?) 
        throw(err)

      result = []
      for entryValue in data
        result.push JSON.parse(entryValue)

      res.json 200, result
      callback()
  execCommand req.params.DBID, req, res, action, callback

#/keys/*
exports.keys = (req, res, callback) ->
  action = ->
    redisClient.keys req.params.Key, (err, data) ->
      if (err?) 
        throw(err)

      res.json 200, data
      callback()
  execCommand req.params.DBID, req, res, action, callback

###
{
"DBID":4,
"Command":"set",
"Key":"zeetest",
"Value":"",
"Timestamp":""
}
###
exports.set = (req, res, callback) ->
  action = ->
    params = []
    params.push req.body.Key
    params.push req.body.Value

    #logger.log params
    redisClient.set params, ->
      logger.log "DBID:#{req.body.DBID}, Command: #{req.body.Command}, Key: #{req.body.Key}"
      res.statusCode = 204
      callback()
  execCommand req.body.DBID, req, res, action, callback

#/get/{key}
exports.get = (req, res, callback) ->
  action = ->
    redisClient.get req.params.Key, (err, data) ->
      if (err?) 
        throw(err)

      result = 
        Key: req.params.Key
        Value: data
      res.json 200, result
      callback()
  execCommand req.params.DBID, req, res, action, callback

###
{
"DBID":4,
"Command":"mset",
"Mutations":[
{
  "Key":"zeetest",
  "Value":""
},
{
  "Key":"zeetest1",
  "Value":""
}
],
"Timestamp":""
}
###
exports.mset = (req, res, callback) ->
  action = ->
    params = []
    keys = []
    for mutation in req.body.Mutations
      do (mutation) ->
        params.push mutation.Key
        keys.push mutation.Key
        if(typeof(mutation.Value) is 'object')
          params.push JSON.stringify(mutation.Value)
        else
          params.push mutation.Value

    redisClient.mset params, (err)->
      if(err?)
        throw(err)
      logger.log "DBID:#{req.body.DBID}, Command: #{req.body.Command}, Keys: #{keys.join()}"
      res.statusCode = 204
      callback()
  execCommand req.body.DBID, req, res, action, callback

#/mget/key1,key2...keyn
exports.mget = (req, res, callback) ->
  action = ->
    params = []
    for key in req.params.Key.split(',')
      do (key) ->
        params.push key

    redisClient.mget params, (err, data) ->
      if (err?) 
        throw(err)
      
      result = []
      i=0
      while i<data.length
        result.push 
          Key: params[i],
          Value: data[i]
        i++
      res.json 200, result
      callback()
  execCommand req.params.DBID, req, res, action, callback

execCommand = (dbid, req, res, action, callback)->
  async.series [
    (next) ->
      redisClient.select dbid, next
    (next) ->
      try
        action()
      catch e
        next(e)
  ], (err) ->
    logger.errorWithoutMail err.stack
    res.json 500, {error: err.message}
    callback()