{RedisClient} = require '../lib/RedisClient'
{Server} = require '../lib/Server'
{Config} = require '../lib/Config'
{CRUD} = require 'node-acl'
{Messages} = require '../lib/Messages'

sioc = require 'socket.io-client'

__config = Config.get Config.preset.TEST
__server = null
getServerInstance = ()->
	# if _server then _server.
	__server = new Server __config

__client = null
getClientInstance = ()->
	__client = sioc.connect( "http://127.0.0.1", { 'port': __config.server.port , 'reconnect': false, 'force new connection': true})

describe "Server Specs",->

	beforeEach ->
		console.log "==========running new test=========="
		RedisClient.get(__config).flushdb()

	afterEach ->
		RedisClient.destroy(true)
		__server?.shutdown()
		__client?.disconnect()

	it "registers and listens to pub sub on backend",->
		asyncSpecWait()
		server = getServerInstance()
		spy = spyOn(server, "recieveEvent").andCallFake ()-> 
			expect(true).toEqual(true)
			asyncSpecDone()
		server.onPulishReady ()->
			server.publishEvent "some event"

	it "allows clients to send registeration request",->
		asyncSpecWait()
		acl = [ role : "public", model: "tester", crudOps : [CRUD.read] ]
		server = getServerInstance()
		client = getClientInstance()
		client.on 'connect', ->
			client.emit Messages.Register, "tester", [CRUD.read], 1, (err)->
				expect(err).toBeNull()
				asyncSpecDone()

	xit "allows creating express server"
	xit "cleans up after disconnection of a client"

		
