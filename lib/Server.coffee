{RedisClient} = require './RedisClient'
{Messages} = require './Messages'
{Config} = require './Config'
sio = require 'socket.io'

logr = require('node-logr').getLogger(__filename)

exports.Server = class Server

	circuitChannel : "circuit-channel"

	### @type { redis:{[redis options]}, } serverConfig ###
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

	constructor : (@config) ->
		### Setup redis stuff ###
		@redis = RedisClient.get(@config.redis)
		@redisSub = RedisClient.get(@config.redis, true)
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
			logr.debug "disconnecting socket #{s.id}"
		# shutdown socket io
		@sio.server.close()

	_registerPubsub : =>
		@redisSub.on "message", (channel, message)=>
			if channel == @circuitChannel
				@recieveEvent message
		@redisSub.subscribe @circuitChannel
		@redisSub.on "subscribe", =>
			while (cb = ( @publishReadyCBs || [] ).shift() )
				cb()

	recieveEvent : (message)=>

	_setupSocketIO : ()=>
		@sio = sio.listen(@config.server.port)
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
			clientAddress = socket.handshake.address.address + ":" + socket.handshake.address.port
			logr.debug "client connecting:#{socket.id} ip:#{clientAddress}"
			socket.on Messages.Register, (entityName, crudOps, entityId, callback)=>
				callback(null)
			socket.on "disconnect",=>
				logr.info "client disconnecting:#{socket.id} ip:{clientAddress}"

