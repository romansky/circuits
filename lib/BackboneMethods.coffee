{Messages} = require './Services'

logr = require('node-logr').getLogger(__filename)

exports.registerSync = (callback = (->), model, sioc)->
	modelName = model.constructor.name
	sioc.emit Messages.Register, modelName, model.id, (err,curValue)->
		if err
			msg = "failed to register model name:#{modelName} id:#{model.id} err:#{err}"
			logr.error msg
			callback(msg)
		else
			model.set curValue
			callback(null)
	sioc.on Messages.Publish, (_modelName, _crudOps, _modelId, _newData)->
		if modelName is _modelName and model.id is _modelId
			# TODO: need to manage collisions better, maybe with changes counter..?
			model.set _newData


exports.sync = (method, model, options, sioc)->
	modelName = model.constructor.name
	sioc.emit Messages.Operation, modelName, [method], model.id, model.toJSON(), (err,res)->
		if err
			logr.error "error while syncing model; name:#{modelName} id:#{model.id} err: #{err}"
			options.error(model, err)
		else
			options.success(res)