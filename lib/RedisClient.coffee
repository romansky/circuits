redis = require 'redis'
logr = require('node-logr').getLogger(__filename)
{Config} = require './Config'

exports.RedisClient = class RedisClient

	@_instance : null

	@_auxClients : []

	### @param { db: null, host: null, port: null } config ###
	### @param bool isAux - create auxiliary client (for pub/sub for example) ###
	@get : (config, isAux = false)->
		if not RedisClient._instance || isAux
			instance = createNewClient(config)
			if isAux
				RedisClient._auxClients.push instance
				return instance
			else 
				RedisClient._instance = instance
		return RedisClient._instance

	### @param bool isAllClients - kill aux clients ###
	@destroy : (isAllClients = false)->
		if RedisClient._instance
			RedisClient._instance.quit()
			RedisClient._instance = null
		if isAllClients
			while (c = RedisClient._auxClients.shift())
				c.quit()


### @param { db: null, host: null, port: null } config ###
createNewClient = (config)->
	logr.info "creating redis client with config #{JSON.stringify(config)}"
	instance = redis.createClient config.port, config.host
	instance.on 'error', (err)-> logr.error("redis client:#{err}")
	instance.select config.db, ()-> #nothingness
	return instance