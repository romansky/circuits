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
	@param crudOps node-acl.CRUD - crud operations 
	@param params Map[String,String]
	@param opParams List[Object] - operation specific parameters 
	@param callback Function[Error, data] - a callback function to be called with the result or error 
	###
	Operation : (clientId, server, entityName, crudOp, params, opPrams... , callback) ->
		controller = server.getController(entityName)
		logr.debug "op:#{crudOp} controller:#{entityName}"

		switch crudOp
			when CRUD.create
				[data] = opPrams
				controller.create(params, data, callback)
			when CRUD.read 
				[entityId] = opPrams
				controller.read(params, entityId, callback)
			when CRUD.update
				[entityId, data] = opPrams
				controller.update(params, entityId, data, callback)
				# TODO: exclude this server from recipients of events, also the specific client from later distribution
				server.publishEvent(entityName, crudOp, params, entityId, data)
			when CRUD.delete
				[entityId] = opPrams
				controller.delete(params, entityId, callback)
			else callback(new Error("bad crud operation requested:" + crudOps))


	UnRegister : ()->
		throw "TBD"

	Publish : ()->
		throw "TBD"

}