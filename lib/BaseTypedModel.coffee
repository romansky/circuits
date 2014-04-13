{TypedModel} = require('backbone-typed')
BackboneMethods = require './BackboneMethods'

exports.BaseTypedModel = class BaseTypedModel extends TypedModel

	sioc : null

	constructor : (@sioc, args...)->
		super(args...)

	registerSync : (callback)=>
		BackboneMethods.registerSync callback, @, @sioc

	sync : (method, model, options)=>
		BackboneMethods.sync method, model, options, @sioc
