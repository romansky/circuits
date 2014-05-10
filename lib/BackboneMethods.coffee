{Messages} = require './Messages'
Backbone = require 'backbone'

logr = require('node-logr').getLogger(__filename,"circuits")

exports.constructor = (clazz, sioc)->
	# console.log clazz
	if sioc and not (sioc.constructor.name is 'Socket')
		msg = "first argument needs to be instance of Socket.io-client, model:#{clazz.constructor.name}"
		logr.error msg, Error(msg)
		throw msg

exports.registerSync = (params, callback = (->), model, sioc)->
	modelName = model.constructor.name
	logr.debug "sending registration request for model:#{modelName} id:#{model.id}"
	sioc.emit Messages.Register, modelName, params, model.id or 0, (err,curValue)->
		if err
			msg = "failed to register model name:#{modelName} id:#{model.id} err:#{err}"
			logr.error msg
			callback(msg)
		else
			model.set curValue
			callback(null)
	sioc.on Messages.Publish, (_modelName, _crudOps, _params, _eventParams)->
		[ _modelId , _newData ] = _eventParams
		logr.debug "received publish event model:#{_modelName} crudOp:#{_crudOps} id:#{_modelId} data:#{_newData}"
		if modelName is _modelName and model.id is _modelId
			# TODO: need to manage collisions better, maybe with changes counter..?
			model.set _newData

isCollection = (backboneObject)->
        backboneObject?.__super__?.constructor == Backbone.Collection

exports.sync = (method, model, options, sioc)->
	modelName = model.constructor.name

	sending = switch method
		when "create" then [ model.toJSON() ]
		when "read"
			if isCollection(model) then []
			else [ model.id ]
		when "update" then [ model.id, model.toJSON() ]
		when "delete" then  [ model.id ]

	model.__circuits_seq ?= {}
	key = [modelName, method, model.id || 0].join("|")
	seq = model.__circuits_seq[key] ?= 0
	model.__circuits_seq[key] += 1

	logr.debug "sending message model:#{modelName} method:#{method} sending:#{JSON.stringify(sending)}"
	sioc.emit Messages.Operation, modelName, method, options.params || {}, sending... , (err,res)->
		if err
			logr.error "error while syncing model; name:#{modelName} id:#{model.id} err: #{err}"
			options.error(model, err)
		else
			if model.__circuits_seq[key] == seq + 1
				options.success(res)
			else
				logr.notice("response ignored due to out of sequence for key:#{key} seq:#{seq}")
				options.success({})
