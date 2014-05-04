{RedisClient} = require './RedisClient'
{Services} = require './Services'
{Messages} = require './Messages'
{Listeners} = require './Listeners'
{CRUD} = require './CRUD'
{ACL} = require './ACL'

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
	### @type ACL ###
	acl : null

	### PUBLIC ###

	###
	@param httpServer Int
	@param redisDB Int
	@param controllerResolver Function[String,Map[String,Any]]
	@param acl ACL
	@param redisHost String
	@param redisPort Int
	@param circuitChannel String
	###
	constructor : (@httpServer, @redisDB, @controllerResolver = (()-> null) , @acl = ACL.AllowAll, @redisHost = "127.0.0.1", @redisPort = 6379, @circuitChannel = "circuit-channel") ->

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

	_getCookieValue : (cookies, cookieName)->
		found = cookies?.split(";").map((s)-> s.trim().split("=") ).filter((v)-> v[0] == cookieName)
		found?[0]?[1]

	_setupSocketIO : ()=>
		@sio = sio(@httpServer)
		@connectedSockets = []

		@sio.on 'connection', (socket)=>
			@connectedSockets.push socket
			# creates personal room for this socket
			socket.join(socket.id)
			socket.clientAddress = socket.request.connection.remoteAddress + ":" + socket.request.connection.remotePort
			logr.info "client connecting:#{socket.id} ip:#{socket.clientAddress}"
			server = @
			token = @_getCookieValue(socket.request.headers.cookie, "circuits-token")
			@genUserIDFromToken token, (err, userID)->
				if err then logr.error "failed to get userID for token:#{err}"
				# finish by binding all message types onto the socket
				bindMessage(socket, message, userID, server) for message of Messages

			socket.on "disconnect",=>
				logr.info "client disconnecting:#{socket.id} ip:#{socket.clientAddress}"
				@connectedSockets.splice(@connectedSockets.indexOf(socket),1)



bindMessage = (socket, message,userID, server)->
	socket.on message, (args...)->
		# pop last arg because its null
		cb = args.pop()
		logr.debug "received message:#{message} args:#{JSON.stringify(args)}"
		Services[message](socket.id, userID, server, args..., cb)