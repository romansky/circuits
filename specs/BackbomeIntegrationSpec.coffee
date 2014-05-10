{BaseModel} = require '../lib/BaseModel'
{BaseTypedModel} = require '../lib/BaseTypedModel'
helper = require './helper'


describe "backbone integration",->

	beforeEach ->
		console.log "==========running new test( #{@suite.description} - #{@description} )=========="

	afterEach ->
		helper.envCleaup()

	it "registers on updates", (done)->

		class T extends BaseModel

		good = false
		helper.getServerInstance (c)->
			{
				read : (params, id, cb)-> 
					good = true
					expect(id).toEqual(8)
					cb(null, {something : "other"})
			}

		sioc = helper.getClientInstance()
		t = new T(sioc, {id: 8})
		t.registerSync {}, (err)->
			expect(err).toBeFalsy()
			expect(good).toBeTruthy()

		t.on "change:something",->
			expect(t.get("something")).toEqual("other")
			done()


	it "checks also typed model",->
		class T extends BaseTypedModel

		good = false
		helper.getServerInstance (c)->
			{
				read : (params, id, cb)-> 
					good = true
					expect(id).toEqual(8)
					cb(null, {something : "other"})
			}

		sioc = helper.getClientInstance()
		t = new T(sioc, {id: 8})
		t.registerSync {}, (err)->
			expect(err).toBeFalsy()
			expect(good).toBeTruthy()

		t.on "change:something",->
			expect(t.get("something")).toEqual("other")
			done()


	it "receives an update!", (done)->

		class T2 extends BaseModel

		server = helper.getServerInstance (c)->
			{
				read : (params, id, cb)-> 
					expect(id).toEqual(8)
					cb(null, {something : "other"})
				update : (params, id, value, cb)->
					cb(null)
			}

		sioc = helper.getClientInstance()
		sioc2 = helper.getClientInstance(true)

		t1 = new T2(sioc, {id: 8})
		t2 = new T2(sioc2, {id: 8})

		t1.registerSync {}, ()->
		t2.registerSync {}, ()->
			t1.set {"something": "other other"}
			t1.save()


		t2.on "change:something",->
			if t2.get("something") is "other other"
				expect(t2.get("something")).toEqual("other other")
				done()

	it "throws when first parameter is not a socket.io client",->

		class Bad extends BaseModel

		good = false
		try Bad({imnot: "sioc"})
		catch err
			good = true

		expect(good).toBeTruthy()


	it "keeps sequence, so a request with the same time arriving out of sync is ignored",(done)->
		class Papa extends BaseModel

		serverSeq = [1,2,3,4]

		checkFinished = (num)->
			if num
				expect(num).toEqual(4)
				done()

		sioc = helper.getClientInstance()

		server = helper.getServerInstance (c)->

			{
				read : (params, id, cb)->	
					num = serverSeq.shift()
					setTimeout(
						( -> cb(null, {num:num}) )
						,10
					)
			}

		child = new Papa(sioc,{id:5})

		child.fetch {
			success : (c,m)->
				checkFinished(m.num)
		}
		child.fetch {
			success : (c,m)-> 
				checkFinished(m.num)
		}
		child.fetch {
			success : (c,m)-> 
				checkFinished(m.num)
		}

		child.fetch {
			success : (c,m)-> 
				checkFinished(m.num)
		}

		expect(true).toBeTruthy()





	
		