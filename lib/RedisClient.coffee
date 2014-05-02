redis = require 'redis'
logr = require('node-logr').getLogger(__filename,"circuits")

exports.RedisClient = class RedisClient

	@_instance : null

	@_auxClients : []

	### @param Int db - the redis db identifier ###
	### @param String host - the ip address of the redis host ### 
	### @param Int port - the port number on which the redis instance is listening on ### 
	### @param bool isAux - create auxiliary client (for pub/sub for example) ###
	@get : (db, host, port, isAux = false)->
		if not RedisClient._instance || isAux

			instance = createNewClient(db, host, port)
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



createNewClient = (db, host = "127.0.0.1", port = 6379)->
	logr.info "creating redis client with args: #{db} #{host}:#{port}"
	instance = redis.createClient port, host
	instance.on 'error', (err)-> logr.error("redis client:#{err}")
	instance.select db, ()-> #nothingness
	return instance
