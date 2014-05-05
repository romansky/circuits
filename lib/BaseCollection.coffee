backbone = require 'backbone'
BackboneMethods = require './BackboneMethods'
Socket = require('socket.io-client').Socket

logr = require('node-logr').getLogger(__filename,"circuits")

exports.BaseCollection = class BaseCollection extends backbone.Collection

	sioc : null

	constructor : (@sioc, args...)->
		BackboneMethods.constructor @, sioc
		super(args...)

	registerSync : (params, callback)=>
		BackboneMethods.registerSync params, callback, @, @sioc

	sync : (method, model, options)=>
		BackboneMethods.sync method, model, options, @sioc
