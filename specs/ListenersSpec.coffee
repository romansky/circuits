{Listeners} = require '../lib/Listeners'
{CRUD} = require 'node-acl'

describe "Listeners Spec",->

	beforeEach ->
		console.log "==========running new test( #{@suite.description} - #{@description} )=========="

	it "can add a listener ID",->
		l = new Listeners()
		res = l.add("12345", "blah", [CRUD.update], 10)
		expect(res).toBeTruthy()

	it "disallows registration to read crud operation because it does not make sense",->
		l = new Listeners()
		res = l.add("12345", "blah", [CRUD.read], 10)
		expect(res).toBeFalsy()


	it "finds relevant registered listeners",->
		l = new Listeners()
		l.add("10", "blah", [CRUD.update], 10)
		l.add("11", "blah", [CRUD.update], 10)
		l.add("12", "blah", [CRUD.update], 10)
		res = l.getList("blah", CRUD.update, 10)
		expect(res).toEqual(["10","11","12"])


	it "removes a listener",->
		l = new Listeners()
		l.add("10", "blah", [CRUD.update], 10)
		l.add("11", "blah", [CRUD.update], 10)
		l.add("12", "blah", [CRUD.update], 10)
		res = l.getList("blah", CRUD.update, 10)
		expect(res).toEqual(["10","11","12"])
		l.remove("11")
		res2 = l.getList("blah", CRUD.update, 10)
		expect(res2).toEqual(["10","12"])




