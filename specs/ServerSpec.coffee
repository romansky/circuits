{CRUD} = require 'node-acl'
{Services,Messages} = require '../lib/Services'
helper = require './helper'

describe "Server Specs",->

	beforeEach ->
		console.log "==========running new test=========="

	afterEach ->
		helper.envCleaup()

	it "publishes event with object",(done)->
		testEN = "ZZZ"
		testCO = CRUD.update
		testEID = 5
		testData = {that: "and this"}
		server = helper.getServerInstance()

		spy = spyOn(server, "_recieveEvent").andCallFake (entityName, crudOp, params, eventParams)->
			expect(entityName).toEqual(testEN)
			expect(crudOp).toEqual(testCO)
			expect(params).toEqual(params)
			expect(eventParams[0]).toEqual(testEID)
			expect(eventParams[1]).toEqual(testData)
			done()
		server.onPulishReady ()->
			server.publishEvent(testEN, testCO, {}, testEID, testData)

	it "registers request recieved and intercepted by services",(done)->
		acl = [ role : "public", model: "tester", crudOps : [CRUD.read] ]
		testObj = { a: "a", b: "b" }
		spy = spyOn(Services, Messages.Register).andCallFake (a,b,c,d,e,cb)->
			cb(null, testObj)
		server = helper.getServerInstance()
		client = helper.getClientInstance()
		client.on 'connect', ->
			client.emit Messages.Register, "tester",{}, 1, (err, data)->
				expect(data).toEqual(testObj)
				done()

	it "registers for updates and receives the current value",(done)->
		acl = [ role : "public", model: "Tester", crudOps : [CRUD.update] ]
		testObj = { a: "a", b: "b" }
		
		good = false
		server = helper.getServerInstance (controllerName)->
			{
				'read' : (params, id, cb)-> 
					expect(id).toEqual(42)
					cb(null, testObj)
			}
		

		client = helper.getClientInstance()
		client.on 'connect', ->
			client.emit Messages.Register, "Tester", {}, 42, (err, data)->
				expect(data).toEqual(testObj)
				done()


	it "dispatches a read message to model via an Operation",(done)->
		acl = [ role : "public", model: "Tester", crudOps : [CRUD.read] ]
		testObj = { a: "a", b: "b" }

		server = helper.getServerInstance (controllerName)->
			{
				'read' : (params, id, cb)-> 
					expect(id).toEqual(42)
					cb(null, testObj)
			}

		client = helper.getClientInstance()
		client.on 'connect', ->
			client.emit Messages.Operation, "Tester", CRUD.read, {}, 42, null, (err, data)->
				expect(data).toEqual(testObj)
				done()

	it "notifies a registered client on model change", (done)->
		acl = [ role : "public", model: "Tester", crudOps : [CRUD.read] ]
		testObj1 = { a: "a", b: "b" }
		testObj2 = { a: "a2", b: "b2" }
		testsDone = 0

		server = helper.getServerInstance (controllerName)->
			{
				'read' : (params, id, cb)-> 
					testsDone += 1
					expect(id).toEqual(42)
					cb(null, testObj1)
				'update' : (params, id, data, cb)->
					expect(id).toEqual(42)
					testsDone += 1
					expect(data).toEqual(testObj2)
					cb(null)

			}

		clientA = helper.getClientInstance()
		clientB = helper.getClientInstance(true)

		clientB.on 'connect', ->
			clientA.emit Messages.Register, "Tester", {}, 42, (err, data)->
				expect(err).toBeNull()
				testsDone += 1
				expect(data).toEqual(testObj1)

			clientA.on Messages.Publish, (entityName, crudOp, {}, eventParams)->
				[entityId, data] = eventParams
				expect(data).toEqual(testObj2)
				expect(testsDone).toEqual(3)
				done()

			clientB.emit Messages.Operation,"Tester", CRUD.update, {}, 42, testObj2, (err)->
				expect(err).toBeNull()

	xit "checks if the passd controller file exists"
	xit "cleans up after disconnection of a client"
		
	it "stores a userID in the tmp store via provided token and retrieves it",(done)->
		userID = "fake-user-id"
		server = helper.getServerInstance()
		token = server.makeTokenForUserID(userID)
		server.genUserIDFromToken token, (err, res)->
			expect(err).toBeNull()
			expect(res).toEqual(userID)
			done()
