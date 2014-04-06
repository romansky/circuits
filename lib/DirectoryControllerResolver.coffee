exports.DirectoryControllerResolver = (controllersDir)->
	(controllerName)->
		try
			cf = path.resolve __dirname, @controllersDir
			require("#{cf}/#{controllerName}")[controllerName]
		catch err
			logr.error("could not find resource file #{cf}/#{controllerName} ")
			null