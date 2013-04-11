exports.Config = class Config

	@preset : {
		"TEST"
		"ENV"
	}

	@get : (preset, overrides = {})->
		# TODO: implement overrides
		switch preset
			when Config.preset.TEST then testConfig
			when Config.preset.ENV then
				# write code here to resolve env and merge overrides


testConfig = 
	preset : Config.preset.TEST
	redis_db : 15
	redis_host : "127.0.0.1"
	redis_port : "6379"
	server_port : 7474
	user_controllers : "./controller"
