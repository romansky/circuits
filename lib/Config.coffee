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


testConfig = {
	redis : {
		db : 15
		host : "127.0.0.1"
		port : "6379"
	}
}