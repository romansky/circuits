{RedisClient} = require './RedisClient'
{Services,Messages} = require './Services'
{Config} = require './Config'

sio = require 'socket.io'
logr = require('node-logr').getLogger(__filename)
path = require 'path'

exports.Server = class Server

	circuitChannel : "circuit-channel"

	### @type Config serverConfig ###
	config : null

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

	constructor : (@config) ->
		### Setup redis stuff ###
		@redis = RedisClient.get(@config.redis_db, @config.redis_host, @config.redis_port)

		@redisSub = RedisClient.get(@config.redis_db, @config.redis_host, @config.redis_port, true)
		@_registerPubsub()
		### Setup socket io stuff ###
		@_setupSocketIO()

	publishEvent : (text)=>
		@redis.publish @circuitChannel, text

	onPulishReady : (cb)=>
		( @publishReadyCBs = [] ).push cb

	shutdown : (cb)=>
		# disconnect all clients
		@connectedSockets.map (s)->
			s.disconnect()
			logr.info "disconnecting socket #{s.id}"
		# shutdown socket io
		@sio.server.close()


	recieveEvent : (message)=>

	###
	get controller reference from one of the configured controller folders

	@param String cn - controller name
	###
	getController : (cn)=>
		cf = path.resolve __dirname, @config.user_controller || "./controller"
		console.log @config.user_controller,"<<<<"
		require("#{cf}/#{cn}")[cn]


	### PRIVATE ###

	_registerPubsub : =>
		@redisSub.on "message", (channel, message)=>
			if channel == @circuitChannel
				@recieveEvent message
		@redisSub.subscribe @circuitChannel
		@redisSub.on "subscribe", =>
			while (cb = ( @publishReadyCBs || [] ).shift() )
				cb()

	

	_setupSocketIO : ()=>
		@sio = sio.listen(@config.server_port)
		@connectedSockets = []
		switch @config.preset
			when Config.preset.TEST
				@sio.configure ()=>
					@sio.set 'transports', ['websocket']
					@sio.set 'flash policy server', false
					@sio.disable 'flash policy server'
		@sio.on 'connection', (socket)=>
			@connectedSockets.push socket
			#creates personal room for this socket
			socket.join(socket.id)
			# print out some debug info
			socket.clientAddress = socket.handshake.address.address + ":" + socket.handshake.address.port
			logr.info "client connecting:#{socket.id} ip:#{socket.clientAddress}"
			bindMessage = (message)=>
				socket.on message, (args...)=>
					Services[message](@,args...)
			bindMessage(message) for message of Messages

			socket.on "disconnect",=>
				logr.info "client disconnecting:#{socket.id} ip:#{socket.clientAddress}"


