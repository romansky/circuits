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
	@param entityId Int - the entity ID
	@param callback Function(Error, data) - a callback function to be called with the result or error 
	###
	Register : (clientId, server, entityName, entityId, callback) ->
		controller = server.getController(entityName)
		controller.read(entityId, callback)
		server.listeners.add(clientId,entityName, [ 'update' ], entityId)
		
	### 
	@param String clientId
	@param Server server - an instance of the server 
	@param String entityName - model name 
	@param [ node-acl.CRUD ] crudOps - crud operations 
	@param Int entityId - the entity ID 
	@param Object data - JSON data object 
	@param Function(Error, data) callback - a callback function to be called with the result or error 
	###
	Operation : (clientId, server, entityName, crudOps, entityId, data, callback) ->
		controller = server.getController(entityName)
		crudOp = crudOps[0]
		logr.debug "op:#{crudOp} controller:#{entityName}"
		switch crudOp
			when CRUD.read 
				controller.read(entityId, callback)
			when CRUD.update
				controller.update(entityId, data, callback)
				server.publishEvent(entityName, crudOps, entityId, data)
			else callback(new Error("bad crud operation requested:" + crudOps))


	UnRegister : ()->
		throw "TBD"

	Publish : ()->
		throw "TBD"

}