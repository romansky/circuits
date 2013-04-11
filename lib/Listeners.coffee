{CRUD} = require 'node-acl'

exports.Listeners = class Listeners

	listeners : {}

	constructor : ()->


	add : (id, entityName, crudOps, entityId)=>
		allowed = [CRUD.update, CRUD.delete, CRUD.create, CRUD.patch]
		if crudOps.filter((co)-> allowed.indexOf(co) == -1).length > 0
			return false
		true

	remove: ()=>

	getList : ()=>

