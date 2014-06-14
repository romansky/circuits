{CRUD} = require './CRUD'
logr = require('node-logr').getLogger(__filename,"circuits")
{Messages} = require './Messages'


### 
@param server Server - an instance of the server
@param userId String
@param entityName String - model name
@param params Map[String,String]
@param entityId Int - the entity ID
@param callback Function[Error, data] - a callback function to be called with the result or error 
###
exports.Register = (clientId, userId, server, entityName, params, entityId, callback) ->
	logr.info "#{entityName}#register@#{entityId} #{clientId}/#{userId}"
	server.acl.verify userId, entityName, entityId, CRUD.read, (err, isAllowed)->
		if isAllowed
			server.getController(entityName).read(params, entityId, callback)
			server.listeners.add(clientId,entityName, [ 'update' ], entityId)
		else callback("not allowed")
		
### 
@param clientId String 
@param userId String
@param server Server - an instance of the server 
@param entityName String - model name 
@param crudOps CRUD - crud operations 
@param params Map[String,String]
@param opParams List[Object] - operation specific parameters 
@param callback Function[Error, data] - a callback function to be called with the result or error 
###
exports.Operation = (clientId, userId, server, entityName, crudOp, params, opPrams... , callback) ->
	logr.info "#{entityName}##{crudOp} #{JSON.stringify(params)} #{clientId}/#{userId}"
	controller = server.getController(entityName)

	switch crudOp

		when CRUD.create
			[data] = opPrams
			server.acl.verify userId, entityName, null, crudOp, (err,isAllowed)->
				if isAllowed then controller.create(params, data, callback)
				else 
					m = "ACL: #{entityName}##{crudOp}@#{userId} " + err
					logr.notice(m)
					callback(m)

		when CRUD.read
			[entityId] = opPrams
			server.acl.verify userId, entityName, entityId, crudOp, (err,isAllowed)->
				if isAllowed then controller.read(params, entityId, callback)
				else
					m = "ACL: #{entityName}##{crudOp}@#{userId} " + err
					logr.notice(m)
					callback(m)

		when CRUD.update
			[entityId, data] = opPrams
			server.acl.verify userId, entityName, entityId, crudOp, (err,isAllowed)->
				if isAllowed
					controller.update(params, entityId, data, callback)
					# TODO: exclude this server from recipients of events,
					# also the specific client from later distribution
					server.publishEvent(entityName, crudOp, params, entityId, data)
				else 
					m = "ACL: #{entityName}##{crudOp}@#{userId} " + err
					logr.notice(m)
					callback(m)
			
		when CRUD.delete
			[entityId] = opPrams
			server.acl.verify userId, entityName, entityId, crudOp, (err,isAllowed)->
				if isAllowed then controller.delete(params, entityId, callback)
				else 
					m = "ACL: #{entityName}##{crudOp}@#{userId} " + err
					logr.notice(m)
					callback(m)
			
		else
			logr.notice("bad crud operation requested:" + crudOp) 
			callback("bad crud operation requested:" + crudOp)


exports.UnRegister = ()->
		throw "TBD"

exports.Publish = ()->
		throw "TBD"


