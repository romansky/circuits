{Listeners} = require '../lib/Listeners'
{CRUD} = require 'node-acl'

describe "Listeners Spec",->
	it "can add a listener ID",->
		l = new Listeners()
		res = l.add("12345", "blah", [CRUD.update], 10)
		expect(res).toBeTruthy()

	it "disallows registration to read crud operation because it does not make sense",->
		l = new Listeners()
		res = l.add("12345", "blah", [CRUD.read], 10)
		expect(res).toBeFalsy()