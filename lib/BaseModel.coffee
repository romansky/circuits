backbone = require 'backbone'
BackboneMethods = require './BackboneMethods'

exports.BaseModel = class BaseModel extends backbone.Model

	sioc : null

	constructor : (@sioc, args...)->
		super(args...)

	registerSync : (callback)=>
		BackboneMethods.registerSync callback, @, @sioc

	sync : (method, model, options)=>
		BackboneMethods.sync method, model, options, @sioc
