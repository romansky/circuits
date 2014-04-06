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
	@param sioPort Int
	@param redisDB Int
	@param controllerResolver Function[String,Map[String,Any]]
	@param redisHost String
	@param redisPort Int
	@param circuitChannel String
	###
	constructor : (@sioPort, @redisDB, @controllerResolver = (()-> null) , @redisHost = "127.0.0.1", @redisPort = 6379, @circuitChannel = "circuit-channel") ->

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
		# shutdown socket io
		@sio.server.close()



	###
	get controller from resolver

	@param String cn - controller name
	###
	getController : (cn)=>
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
		@sio = sio.listen(@sioPort)
		@connectedSockets = []
		@sio.configure ()=>
			@sio.set 'transports', ['websocket']
			@sio.set 'flash policy server', false
			@sio.disable 'flash policy server'
		@sio.on 'connection', (socket)=>
			@connectedSockets.push socket
			# creates personal room for this socket
			socket.join(socket.id)
			# print out some debug info
			socket.clientAddress = socket.handshake.address.address + ":" + socket.handshake.address.port
			logr.info "client connecting:#{socket.id} ip:#{socket.clientAddress}"
			bindMessage = (message)=>
				socket.on message, (args...)=>
					Services[message](socket.id,@,args...)
			bindMessage(message) for message of Messages

			socket.on "disconnect",=>
				logr.info "client disconnecting:#{socket.id} ip:#{socket.clientAddress}"

