{exec} = require 'child_process'
logr = require('node-logr').getLogger(__filename)

handleExecErrors = (err, stdout, stderr)->
        if err then console.log 'Errors: '+err
        if stdout then console.log 'Messages: '+stdout
        if stderr then console.log 'Errors: '+stderr
        if err then process.exit 1

task 'build',->
	exec "coffee -c index", handleExecErrors


option '-n', '--name [NAME]', 'tests name pattern matching'

task 'test', 'runs tests', (options)->
	specDir = "./specs"
	matchstring = ""
	if options.name
		matchstring = "--match \"#{options.name}\""
	command = "NODE_ENV=test #{__dirname}/node_modules/jasmine-node/bin/jasmine-node --verbose #{matchstring} --forceexit --color --coffee \"#{specDir}\""
	logr.info "running: " + command
	require('child_process').exec command, handleExecErrors
