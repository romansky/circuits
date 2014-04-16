backbone = require 'backbone'
BackboneMethods = require './BackboneMethods'

exports.BaseCollection = class BaseCollection extends backbone.Collection

	sioc : null

	constructor : (@sioc, args...)->
		super(args...)

	registerSync : (params, callback)=>
		BackboneMethods.registerSync params, callback, @, @sioc

	sync : (method, model, options)=>
		BackboneMethods.sync method, model, options, @sioc