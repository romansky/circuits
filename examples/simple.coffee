http = require 'http'
Server = require('../../').Server
Operation = require('../../').Messages.Operation
CRUD = require('../../').CRUD
sioc = require 'socket.io-client'

testPort = 8001
# create a server
httpServer = http.Server()
# instantiate a Circuits server with a controller router
server = new Server httpServer, (controller)->
	switch controller
		# match against the requested router to a specific one
		# every router needs to implement the CRUD operation 
		# it needs to support
		when 'echo' then {
				"read" : (message, id, cb)-> cb(null,message)
			}


httpServer.listen testPort

client = sioc.connect("http://localhost:#{testPort}")

client.on 'connect', ->
	client.emit Operation, 'echo', CRUD.read, 'any bats in here?',(err, data)->
		if (data == 'any bats in here?')
			console.log 'No bats here I guess..'
			process.exit()