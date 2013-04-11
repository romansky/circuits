{RedisClient} = require '../lib/RedisClient'
{Server} = require '../lib/Server'
{Config} = require '../lib/Config'
{CRUD} = require 'node-acl'
{Services,Messages} = require '../lib/Services'
{Tester} = require './controller/Tester'

sioc = require 'socket.io-client'

tcf = require('path').resolve(__dirname,"./controller")

flatCopy = (target,sources...)-> sources.reduce(((a,b)-> a[k] = v for k,v of b ; a ),target)


__config = Config.get Config.preset.TEST
__server = null
getServerInstance = (configToMerge)->
	# if _server then _server.
	mergedConf = flatCopy({}, __config,configToMerge)
	__server = new Server mergedConf

__client = null
__auxClients = []
getClientInstance = (isAux = false)->
	if not isAux
		__client ?= sioc.connect( "http://127.0.0.1", { 'port': __config.server_port , 'reconnect': false, 'force new connection': true})
	else
		__auxClients.push sioc.connect( "http://127.0.0.1", { 'port': __config.server_port , 'reconnect': false, 'force new connection': true})
		__auxClients[__auxClients.length-1]

envCleaup = ->
	RedisClient.destroy(true)
	__server?.shutdown()
	__client?.disconnect()
	__auxClients.forEach (c)-> c.disconnect()
	__server = null
	__client = null
	__auxClients = []

describe "Server Specs",->

	beforeEach ->
		console.log "==========running new test=========="
		RedisClient.get(__config.redis_db, __config.redis_host, __config.redis_port).flushdb()

	afterEach ->
		envCleaup()

	it "publishes event with object",->
		asyncSpecWait()
		testEN = "ZZZ"
		testCO = CRUD.update
		testEID = 5
		testData = {that: "and this"}
		server = getServerInstance()
		spy = spyOn(server, "_recieveEvent").andCallFake (entityName, crudOp, entityId, data)->
			
			expect(entityName).toEqual(testEN)
			expect(crudOp).toEqual(testCO)
			expect(entityId).toEqual(testEID)
			expect(data).toEqual(testData)
			asyncSpecDone()
		server.onPulishReady ()->
			server.publishEvent testEN, testCO, testEID, testData

	it "registers request recieved and intercepted by services",->
		asyncSpecWait()
		acl = [ role : "public", model: "tester", crudOps : [CRUD.read] ]
		testObj = { a: "a", b: "b" }
		spy = spyOn(Services, Messages.Register).andCallFake (a,b,c,d,e,cb)-> 
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

		server = getServerInstance({user_controllers : tcf})

		client = getClientInstance()
		client.on 'connect', ->
			client.emit Messages.Register, "Tester", [CRUD.read], 42, (err, data)->
				expect(data).toEqual(testObj)
				asyncSpecDone()


	it "dispatches a read message to model",->
		asyncSpecWait()
		acl = [ role : "public", model: "Tester", crudOps : [CRUD.read] ]
		testObj = { a: "a", b: "b" }
		spy = spyOn(Tester, "read").andCallFake (id, cb)-> 
			expect(id).toEqual(42)
			cb(null, testObj)

		server = getServerInstance({user_controllers : tcf})

		client = getClientInstance()
		client.on 'connect', ->
			client.emit Messages.Operation, "Tester", [CRUD.read], 42, null, (err, data)->
				expect(data).toEqual(testObj)
				asyncSpecDone()

	xit "notifies a registered client on model change",->
		asyncSpecWait()
		acl = [ role : "public", model: "Tester", crudOps : [CRUD.read] ]
		testObj1 = { a: "a", b: "b" }
		testObj2 = { a: "a2", b: "b2" }
		spyOn(Tester, "read").andCallFake (id, cb)-> 
			expect(id).toEqual(42)
			cb(null, testObj1)

		spyOn(Tester, "update").andCallFake (id, data, cb)-> 
			expect(id).toEqual(42)
			expect(data).toEqual(testObj2)
			cb(null)

		server = getServerInstance({user_controllers : tcf})

		clientA = getClientInstance()
		clientB = getClientInstance(true)
		clientB.on 'connect', ->
			clientA.emit Messages.Register, "Tester", [CRUD.read], 42, (err, data)->
				expect(err).toBeNull()
				expect(data).toEqual(testObj1)
			clientA.on Messages.Publish, (entityName, crudOp, entityId, data)->
				expect(data).toEqual(testObj2)
				asyncSpecDone()
			clientB.emit Messages.Operation,"Tester",[CRUD.update],42, testObj2, (err)->
				expect(err).toBeNull()

	xit "checks if the controller folder exists as configured during startup"
	xit "checks if the passed controller file exists"
	xit "allows creating express server"
	xit "cleans up after disconnection of a client"

		
