{RedisClient} = require '../lib/RedisClient'
{Server} = require '../lib/Server'
{CRUD} = require 'node-acl'
{Services,Messages} = require '../lib/Services'
http = require 'http'

sioc = require 'socket.io-client'

tcf = require('path').resolve(__dirname,"./controller")

__server = null
__httpServer = null

__testPort = 7474

getServerInstance = (contollerHandler)->	
	__httpServer = http.Server()
	__server = new Server(__httpServer, 15, contollerHandler)	
	__httpServer.listen __testPort
	__server

__client = null
__auxClients = []
getClientInstance = (isAux = false)->
	if not isAux
		__client ?= sioc.connect( "http://localhost:#{__testPort}", { 'reconnect': false, 'force new connection': true})
	else
		__auxClients.push sioc.connect( "http://localhost:#{__testPort}", { 'reconnect': false, 'force new connection': true})
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
		__testPort++
		console.log "==========running new test=========="
		RedisClient.get(15).flushdb()

	afterEach ->
		envCleaup()

	it "publishes event with object",(done)->
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
			done()
		server.onPulishReady ()->
			server.publishEvent testEN, testCO, testEID, testData

	it "registers request recieved and intercepted by services",(done)->

		acl = [ role : "public", model: "tester", crudOps : [CRUD.read] ]
		testObj = { a: "a", b: "b" }
		spy = spyOn(Services, Messages.Register).andCallFake (a,b,c,d,cb)->
			cb(null, testObj)
		server = getServerInstance()
		client = getClientInstance()
		client.on 'connect', ->
			client.emit Messages.Register, "tester", 1, (err, data)->
				expect(data).toEqual(testObj)
				done()

	it "registers for updates and receives the current value",(done)->
		acl = [ role : "public", model: "Tester", crudOps : [CRUD.update] ]
		testObj = { a: "a", b: "b" }
		
		good = false
		server = getServerInstance (controllerName)->
			{
				'read' : (id, cb)-> 
					expect(id).toEqual(42)
					cb(null, testObj)
			}
		

		client = getClientInstance()
		client.on 'connect', ->
			client.emit Messages.Register, "Tester", 42, (err, data)->
				expect(data).toEqual(testObj)
				done()


	it "dispatches a read message to model via an Operation",(done)->
		acl = [ role : "public", model: "Tester", crudOps : [CRUD.read] ]
		testObj = { a: "a", b: "b" }

		server = getServerInstance (controllerName)->
			{
				'read' : (id, cb)-> 
					expect(id).toEqual(42)
					cb(null, testObj)
			}

		client = getClientInstance()
		client.on 'connect', ->
			client.emit Messages.Operation, "Tester", [ CRUD.read ], 42, null, (err, data)->
				expect(data).toEqual(testObj)
				done()

	it "notifies a registered client on model change",(done)->
		acl = [ role : "public", model: "Tester", crudOps : [CRUD.read] ]
		testObj1 = { a: "a", b: "b" }
		testObj2 = { a: "a2", b: "b2" }
		testsDone = 0

		server = getServerInstance (controllerName)->
			{
				'read' : (id, cb)-> 
					testsDone += 1
					expect(id).toEqual(42)
					cb(null, testObj1)
				'update' : (id, data, cb)->
					expect(id).toEqual(42)
					testsDone += 1
					expect(data).toEqual(testObj2)
					cb(null)

			}

		clientA = getClientInstance()
		clientB = getClientInstance(true)

		clientB.on 'connect', ->
			clientA.emit Messages.Register, "Tester", 42, (err, data)->
				expect(err).toBeNull()
				testsDone += 1
				expect(data).toEqual(testObj1)
			clientA.on Messages.Publish, (entityName, crudOp, entityId, data)->
				expect(data).toEqual(testObj2)
				expect(testsDone).toEqual(3)
				done()
			clientB.emit Messages.Operation,"Tester",[CRUD.update],42, testObj2, (err)->
				expect(err).toBeNull()

	xit "checks if the passed controller file exists"
	xit "allows creating express server"
	xit "cleans up after disconnection of a client"

		
