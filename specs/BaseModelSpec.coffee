{BaseModel} = require '../lib/BaseModel'
helper = require './helper'


describe "backbone integration",->

	beforeEach ->
		console.log "==========running new test=========="

	afterEach ->
		helper.envCleaup()

	it "registers on updates", (done)->

		class T extends BaseModel

		good = false
		helper.getServerInstance (c)->
			{
				read : (id, cb)-> 
					good = true
					expect(id).toEqual(8)
					cb(null, {something : "other"})
			}

		sioc = helper.getClientInstance()
		t = new T(sioc, {id: 8})
		t.registerSync (err)->
			expect(err).toBeFalsy()
			expect(good).toBeTruthy()

		t.on "change:something",->
			expect(t.get("something")).toEqual("other")
			done()


	xit "receives an update!", (done)->


	
		