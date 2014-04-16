{TypedModel} = require('backbone-typed')
BackboneMethods = require './BackboneMethods'

exports.BaseTypedModel = class BaseTypedModel extends TypedModel

	sioc : null

	constructor : (@sioc, args...)->
		super(args...)

	registerSync : (params, callback)=>
		BackboneMethods.registerSync params, callback, @, @sioc

	sync : (method, model, options)=>
		BackboneMethods.sync method, model, options, @sioc
