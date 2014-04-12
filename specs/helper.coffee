{Server} = require '../lib/Server'
{RedisClient} = require '../lib/RedisClient'
http = require 'http'
sioc = require 'socket.io-client'


redisPort = 15
__server = null
__httpServer = null

__testPort = 7474

__client = null
__auxClients = []

exports.getServerInstance = (contollerHandler)->	
	__httpServer = http.Server()
	__server = new Server(__httpServer, redisPort, contollerHandler)	
	__httpServer.listen __testPort
	__server


exports.getClientInstance = (isAux = false)->
	if not isAux
		__client ?= sioc.connect( "http://localhost:#{__testPort}")
	else
		__auxClients.push sioc.connect( "http://localhost:#{__testPort}", { 'reconnect': false, 'forceNew': true})
		__auxClients[__auxClients.length-1]

exports.envCleaup = ->
	RedisClient.destroy(true)
	__server?.shutdown()
	__client?.disconnect()
	__auxClients.forEach (c)-> c.disconnect()
	__server = null
	__client = null
	__auxClients = []
	RedisClient.get(redisPort).flushdb()
	__testPort++