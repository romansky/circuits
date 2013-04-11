{CRUD} = require 'node-acl'

exports.Messages = {
	"Register"
	"Operation"
}


exports.Services = {

	### @param Server server - an instance of the server ###
	### @param String entityName - model name ###
	### @param [ node-acl.CRUD ] crudOps - crud operations ###
	### @param Int entityId - the entity ID ###
	### @param Function(Error, data) callback - a callback function to be called with the result or error ###
	Register : (server, entityName, crudOps, entityId, callback)->
		C = server.getController(entityName)
		# currently we support only one crud operation per register request
		crudOp = crudOps[0]
		switch crudOp
			when CRUD.read then C.read(entityId, callback)
			else callback(new Error("bad crud operation requested:" + crudOps))

	### @param Server server - an instance of the server ###
	### @param String entityName - model name ###
	### @param [ node-acl.CRUD ] crudOps - crud operations ###
	### @param Int entityId - the entity ID ###
	### @param Function(Error, data) callback - a callback function to be called with the result or error ###
	Operation : (server, entityName, crudOps, entityId, callback)->
		C = server.getController(entityName)
		# currently we support only one crud operation per register request
		crudOp = crudOps[0]
		switch crudOp
			when CRUD.read then C.read(entityId, callback)
			else callback(new Error("bad crud operation requested:" + crudOps))
			
}