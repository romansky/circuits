{RedisClient} = require '../lib/RedisClient'
{Server} = require '../lib/Server'
{Config} = require '../lib/Config'
{CRUD} = require 'node-acl'
{Services,Messages} = require '../lib/Services'
{Tester} = require './controller/Tester'

sioc = require 'socket.io-client'

flatCopy = (target,sources)-> target[k] = v for k,v of sources ; target

__config = Config.get Config.preset.TEST
__server = null
getServerInstance = (configToMerge)->
	# if _server then _server.
	tmpConf = flatCopy({}, configToMerge)
	__server = new Server __config

__client = null
getClientInstance = ()->
	__client = sioc.connect( "http://127.0.0.1", { 'port': __config.server_port , 'reconnect': false, 'force new connection': true})

describe "Server Specs",->

	beforeEach ->
		console.log "==========running new test=========="
		RedisClient.get(__config.redis_db, __config.redis_host, __config.redis_port).flushdb()

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

	it "registers request recieved and intercepted by services",->
		asyncSpecWait()
		acl = [ role : "public", model: "tester", crudOps : [CRUD.read] ]
		testObj = { a: "a", b: "b" }
		spy = spyOn(Services, Messages.Register).andCallFake (a,b,c,d,cb)-> 
			cb(null, testObj)
		server = getServerInstance()
		client = getClientInstance()
		client.on 'connect', ->
			client.emit Messages.Register, "tester", [CRUD.read], 1, (err, data)->
				expect(data).toEqual(testObj)
				asyncSpecDone()

	it "recieves configuration of controllers folder and dispatches message to specified model",->
		asyncSpecWait()
		acl = [ role : "public", model: "Tester", crudOps : [CRUD.read] ]
		testObj = { a: "a", b: "b" }
		spy = spyOn(Tester, "read").andCallFake (id, cb)-> 
			expect(id).toEqual(42)
			cb(null, testObj)
		server = getServerInstance()
		client = getClientInstance()
		client.on 'connect', ->
			client.emit Messages.Register, "Tester", [CRUD.read], 42, (err, data)->
				expect(data).toEqual(testObj)
				asyncSpecDone()


	xit "allows creating express server"
	xit "cleans up after disconnection of a client"

		
