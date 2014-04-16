{CRUD} = require 'node-acl'
logr = require('node-logr').getLogger(__filename)

exports.Messages = {
	"Register"
	"UnRegister"
	"Operation"
	"Publish"
}


exports.Services = {

	### 
	@param server Server - an instance of the server
	@param entityName String - model name
	@param params Map[String,String]
	@param entityId Int - the entity ID
	@param callback Function[Error, data] - a callback function to be called with the result or error 
	###
	Register : (clientId, server, entityName, params, entityId, callback) ->
		controller = server.getController(entityName)
		controller.read(params, entityId, callback)
		server.listeners.add(clientId,entityName, [ 'update' ], entityId)
		
	### 
	@param clientId String 
	@param server Server - an instance of the server 
	@param entityName String - model name 
	@param crudOps [ node-acl.CRUD ] - crud operations 
	@param params Map[String,String]
	@param entityId Int - the entity ID 
	@param data Object - JSON data object 
	@param callback Function[Error, data] - a callback function to be called with the result or error 
	###
	Operation : (clientId, server, entityName, crudOps, params, entityId, data, callback) ->
		controller = server.getController(entityName)
		crudOp = crudOps[0]
		logr.debug "op:#{crudOp} controller:#{entityName}"
		switch crudOp
			when CRUD.read 
				controller.read(params, entityId, callback)
			when CRUD.update
				controller.update(params, entityId, data, callback)
				# TODO: exclude this server from recipients of events, also the specific client from later distribution
				server.publishEvent(entityName, crudOps, params, entityId, data)
			else callback(new Error("bad crud operation requested:" + crudOps))


	UnRegister : ()->
		throw "TBD"

	Publish : ()->
		throw "TBD"

}