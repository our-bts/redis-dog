os = require("os")
#crypto = require("crypto")

exports.getLocalIP = ->
  interfaces = os.networkInterfaces()
  for k of interfaces
    for k2 of interfaces[k]
      temp = interfaces[k][k2]
      return temp.address  if temp.family is "IPv4" and not temp.internal

#exports.getHash = (data) ->
  #crypto.createHash("md5").update(data).digest "hex"
