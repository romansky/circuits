{RedisClient} = require './RedisClient'
{Services,Messages} = require './Services'
{Listeners} = require './Listeners'

sio = require 'socket.io'
logr = require('node-logr').getLogger(__filename)
path = require 'path'

exports.Server = class Server

	### @type Listeners ###
	listeners : null
	### @type RedisClient ###
	redis : null
	### @type RedisClient ###
	redisSub : null
	### @type [Function,..] ###
	publishReadyCBs : null
	### @type socket.io ###
	sio : null
	### @type List<Socket> ###
	connectedSockets : null

	### PUBLIC ###

	###
	@param httpServer Int
	@param redisDB Int
	@param controllerResolver Function[String,Map[String,Any]]
	@param redisHost String
	@param redisPort Int
	@param circuitChannel String
	###
	constructor : (@httpServer, @redisDB, @controllerResolver = (()-> null) , @redisHost = "127.0.0.1", @redisPort = 6379, @circuitChannel = "circuit-channel") ->

		@listeners = new Listeners()

		### Setup redis stuff ###
		@redis = RedisClient.get(@redisDB, @redisHost, @redisPort)

		@redisSub = RedisClient.get(@redisDB, @redisHost, @redisPort, true)
		@_registerPubsub()
		### Setup socket io stuff ###
		@_setupSocketIO()

	publishEvent : (entityName, crudOp, entityId, data)=>
		m = JSON.stringify({entityName, crudOp, entityId, data})
		@redis.publish @circuitChannel, m, (err)-> if err then logr.error("error while publishing event: #{err}")

	onPulishReady : (cb)=>
		( @publishReadyCBs = [] ).push cb

	shutdown : (cb)=>
		# disconnect all clients
		@connectedSockets.map (s)->
			s.disconnect()
			logr.info "disconnecting socket #{s.id}"
		# shutdown socket io + server
		@httpServer.close()

	###
	get controller from resolver

	@param String cn - controller name
	###
	getController  : (cn)=>
		@controllerResolver(cn)
		
	

	### PRIVATE ###

	_recieveEvent : (entityName, crudOp, entityId, data)=>
		clients = @listeners.getList(entityName, crudOp, entityId)
		clients.forEach((c)=> @sio.sockets.in(c).emit(Messages.Publish, entityName, crudOp, entityId, data ) )
		

	_registerPubsub : =>
		@redisSub.on "message", (channel, message)=>
			if channel == @circuitChannel
				m = JSON.parse(message)
				@_recieveEvent m.entityName, m.crudOp, m.entityId, m.data
		@redisSub.subscribe @circuitChannel
		@redisSub.on "subscribe", =>
			while (cb = ( @publishReadyCBs || [] ).shift() )
				cb()

	_setupSocketIO : ()=>
		@sio = sio(@httpServer)
		@connectedSockets = []
		@sio.on 'connection', (socket)=>
			@connectedSockets.push socket
			# creates personal room for this socket
			socket.join(socket.id)
			# print out some debug info
			# TODO: fix this, to include IP and port of client
			# socket.clientAddress = socket.handshake.address.address + ":" + socket.handshake.address.port
			socket.clientAddress = socket.request.connection.remoteAddress
			logr.info "client connecting:#{socket.id} ip:#{socket.clientAddress}"
			server = @
			bindMessage = (message)->
				socket.on message, (args...)->
					Services[message](socket.id,server,args...)
			bindMessage(message) for message of Messages

			socket.on "disconnect",=>
				logr.info "client disconnecting:#{socket.id} ip:#{socket.clientAddress}"

