{RedisClient} = require './RedisClient'

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

	constructor : (@config) ->
		@redis = RedisClient.get(@config.redis)
		@redisSub = RedisClient.get(@config.redis, true)
		@_registerPubsub()

	_registerPubsub : =>
		@redisSub.on "message", (channel, message)=>
			if channel == @circuitChannel
				@recieveEvent message
		@redisSub.subscribe @circuitChannel
		@redisSub.on "subscribe", =>
			while (cb = ( @publishReadyCBs || [] ).shift() )
				cb()

	publishEvent : (text)=>
		@redis.publish @circuitChannel, text

	onPulishReady : (cb)=>
		( @publishReadyCBs = [] ).push cb

	recieveEvent : (message)=>
