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
		console.log "->>>>>>>>----"
		process.exit()

	Operation : (server)->

}