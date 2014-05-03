{RedisClient} = require './RedisClient'
{Services,Messages} = require './Services'
{Listeners} = require './Listeners'
{CRUD} = require 'node-acl'

sio = require 'socket.io'
logr = require('node-logr').getLogger(__filename,"circuits")
path = require 'path'
UUID = require 'node-uuid'

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

	publishEvent : (entityName, crudOp, params, eventParams...)=>
		logr.info "publishing event entity:#{entityName} op:#{crudOp} params:#{JSON.stringify(params)}"
		m = JSON.stringify({entityName, crudOp, params, eventParams })
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
		
	makeTokenForUserID : (userID)=>
		uuid = UUID.v4()
		@redis.set @_tmpTokenStoreKey(uuid), userID, "EX", 60 * 60 * 24, ( ()-> )
		uuid

	genUserIDFromToken : (token,cb)=>
		@redis.get @_tmpTokenStoreKey(token), (err, value)=>
			if err 
				logr.error("could not get userID for token:#{token}",err)
				cb("could not get userID for token:#{token}", null)
			else
				cb(null, value)

		@redis.del @_tmpTokenStoreKey(token)

	### PRIVATE ###


	_tmpTokenStoreKey : (token)-> "circuits:tokenstore:#{token}"

	_recieveEvent : (entityName, crudOp, params, eventParams)=>
		# id = 0 is fallback for collections 
		entityId = switch crudOp
			when CRUD.read then eventParams[0] or 0
			when CRUD.update then eventParams[0]
			else throw "unknow op:#{crudOp}"
		clients = @listeners.getList(entityName, crudOp, entityId)
		logr.debug "publishing to clients entity:#{entityName} op:#{crudOp} id:#{entityId} eventParams:#{JSON.stringify(eventParams)} #{clients.join(",")}"
		clients.forEach((c)=> @sio.sockets.in(c).emit(Messages.Publish, entityName, crudOp, params, eventParams ) )
		

	_registerPubsub : =>
		@redisSub.on "message", (channel, message)=>
			logr.debug "pubsub recieved ch:#{channel} msg:#{message}"
			if channel == @circuitChannel
				m = JSON.parse(message)
				@_recieveEvent m.entityName, m.crudOp, m.params, m.eventParams
		@redisSub.subscribe @circuitChannel
		@redisSub.on "subscribe", =>
			while (cb = ( @publishReadyCBs || [] ).shift() )
				cb()

	_setupSocketIO : ()=>
		@sio = sio(@httpServer)
		@connectedSockets = []

		@sio.set 'authorization', (handshakeData, cb)=>
			cb(null, true)
			@genUserIDFromToken handshakeData._query.token, (err, sessionId)->
				console.log handshakeData.headers.cookie				

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
					# pop last arg because its null
					cb = args.pop()
					logr.debug "received message:#{message} args:#{JSON.stringify(args)}"
					Services[message](socket.id,server,args...,cb)
			bindMessage(message) for message of Messages

			socket.on "disconnect",=>
				logr.info "client disconnecting:#{socket.id} ip:#{socket.clientAddress}"

