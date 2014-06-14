Still Work In Progress! - circuits [![Build Status](https://travis-ci.org/uniformlyrandom/circuits.png)](https://travis-ci.org/uniformlyrandom/circuits)
====
[![NPM](https://nodei.co/npm/circuits.png?downloads=true)](https://nodei.co/npm/circuits/)

A simple socket-io framework for client and server communcation around CRUD operations

## Usage

install using npm

	npm install circuits

Basic client server example [source](https://github.com/uniformlyrandom/circuits/blob/master/examples/simple.coffee)

	# port to listen to
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
					"read" : (message, id, cb)-> 
						# the first argument for the callback is 
						cb(null,message)
				}


	httpServer.listen testPort

	client = sioc.connect("http://localhost:#{testPort}")

	client.on 'connect', ->
		client.emit Operation, 'echo', CRUD.read, 'any bats in here?',(err, data)->
			if (data == 'any bats in here?')
				console.log 'No bats here I guess..'
				process.exit()


ToDo:
Example using Circuits with a Backbone model
Example using Circuits with a Backbone collection
Example using Circuits with Express framework


## Whats in the box?

#### create Circuits server instance

`new circuits.Server( httpServer, controllerResolver, [acl, redisHost, redisDB, redis, redisPort, circuitChannel] )`

`httpServer` an instance of `require('http').Server`
`controllerResolver` a function that returns an object with mapping to CRUD operation for provided controller name
`acl` the ACL object, if none provided it allowes everything
`redisHost` IP address of your redis (default is "127.0.0.1")
`redisDB` redis db to use (default is 10 )
`redisPort` redis port (deault is 6379)
`circuitChannel` name space for communication between Circuits instances

#### messages

`circuits.Messages`
is a map of String => String of supported Circuits messages

the `Operation` message is a request for a message to be dispatched to respective controller on the server 

arguments

name | type | description
-----|------|------------
`controller name` | `String` | the controller to dispatch this message to
`crudOp` | `circuits.CRUD.{create,read..}` | the crud operation
`params` | `Object` | parameters to be passed
`operation params` | `Object*` | depending on the CRUD operation, a set of required fields

required `operation params` for the different CRUD operations

`CRUD.create`

name | type | description
-----|------|------------
`data` | `Object` | the object to be created

`CRUD.read`

name | type | description
-----|------|------------
`id` | `String` | resource id

`CRUD.update`

name | type | description
-----|------|------------
`id` | `String` | resource id
`data` | `Object` | the object to update with

`CRUD.delete`

name | type | description
-----|------|------------
`id` | `String` | resource id

#### CRUD operations

`circuits.CRUD`

is simply a map of String => String of  
`create`, `read, `update, `delete` and `patch`

#### ACL

`circuits.ACL` constructor arguments

name | type | description
-----|------|------------
`rules` | `Object` | mapping of controllers to allowed crud operations and respective user groups
`controller+crud groups` | `function(userID, callback = function(err, groups))` | function that returns groups for a given user ID
`optional check` | `function(userID, model, modelId, crudOp, callback = function(message,boolean)` | an optional check for special cases were you want to enforce a finer grained ACL, for example for when only a creater of a resource is only allowed to do a write operation on that model..

example of a controller+crud group rules

	{
		"MyModel" : {
			"create" : ["public"],
			"read" : ["public"],
			"update" : ["users"],
			"delete" : []
		},
		"SecretModel" : {
			"create" : ["users"],
			"read" : ["users"],
			"update" : ["users"],
			"delete" : ["users"]
		}
	}

is simply an object mapping controllers to respective allowed crud operations



## High Level Design

<img src="https://docs.google.com/drawings/d/1ELXFEhsntD2jyYehrcceV-sUHDaTgFCz3Hw180TCKOs/pub?w=982&amp;h=867">
