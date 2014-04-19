{TypedModel} = require('backbone-typed')
BackboneMethods = require './BackboneMethods'
Socket = require('socket.io-client').Socket

logr = require('node-logr').getLogger(__filename)

exports.BaseTypedModel = class BaseTypedModel extends TypedModel

	sioc : null

	constructor : (@sioc, args...)->
		if not (@sioc.constructor is Socket)
			msg = "first argument needs to be instance of Socket.io-client, model:#{@constructor.name}"
			logr.error msg, Error(msg)
			throw msg
		super(args...)

	registerSync : (params, callback)=>
		BackboneMethods.registerSync params, callback, @, @sioc

	sync : (method, model, options)=>
		BackboneMethods.sync method, model, options, @sioc
