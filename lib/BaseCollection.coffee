backbone = require 'backbone'
BackboneMethods = require './BackboneMethods'
Socket = require('socket.io-client').Socket

logr = require('node-logr').getLogger(__filename)

exports.BaseCollection = class BaseCollection extends backbone.Collection

	sioc : null

	constructor : (@sioc, args...)->
		if @sioc and not (@sioc.constructor is Socket)
			msg = "first argument needs to be instance of Socket.io-client, model:#{@constructor.name}"
			logr.error msg, Error(msg)
			throw msg
		super(args...)

	registerSync : (params, callback)=>
		BackboneMethods.registerSync params, callback, @, @sioc

	sync : (method, model, options)=>
		BackboneMethods.sync method, model, options, @sioc