{TypedModel} = require('backbone-typed')
BackboneMethods = require './BackboneMethods'
Socket = require('socket.io-client').Socket

logr = require('node-logr').getLogger(__filename,"circuits")

exports.BaseTypedModel = class BaseTypedModel extends TypedModel

	sioc : null

	constructor : (arg,args...)->
		if args?[0]?.collection
			BackboneMethods.constructor @, ( @sioc = args[0].collection.sioc )
			super(arg, args...)
		else
			BackboneMethods.constructor @, ( @sioc = arg )
			super(args...)

	registerSync : (params, callback)=>
		BackboneMethods.registerSync params, callback, @, @sioc

	sync : (method, model, options)=>
		BackboneMethods.sync method, model, options, @sioc
