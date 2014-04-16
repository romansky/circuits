Still Work In Progress! - circuits [![Build Status](https://travis-ci.org/romansky/circuits.png)](https://travis-ci.org/romansky/circuits)
====


Minimalistic Real-Time Backend For Node.js

High Level Design

<img src="https://docs.google.com/drawings/d/1ELXFEhsntD2jyYehrcceV-sUHDaTgFCz3Hw180TCKOs/pub?w=982&amp;h=867">

## Usage

	var circuits = require('circuits')

	// setup the server
	var sioPort = 7474 # port for socketIO to listen on
	var redisDB = 3 # the Redis DB id you would like to use
	var controllerResolver = function(controllerName){
		//// user a controllers directory
		// var controllersDir = require('path').resolve(__dirname,"./controllers")
		// return require(controllersDir + "/" + controllerName)
		//// or use some inline code toresolve the controller
		switch(controllerName) {
			case "Zubi": 
				// return an object with CRUD operations mapping
				return {
					"read" : function(params, id, cb){
						// return some value in first parameter of CB if there was an error
						// do some work to fetch the value of this specific id
						cb(null,"some value")
					},
					"update" : function(params, id, data, cb){
						// return some value in first parameter of CB if there was an error
						// do some work to update the value of this specific id
						cb(null)
					}
				}
		}
	}
	var redisHost = "127.0.0.1" # the Redis host address
	
	var server = circuits.Server(sioPort, redisDB, controllerResolver, redisHost)

	// connect with some socket.io client
	var client = sioc.connect( "http://127.0.0.1", { 'port': 7474 , 'reconnect': false, 'force new connection': true})
	// register for updates on a model with some id
	client.emit(circuits.Messages.Register, "Zubi",{}, 111, function(err){
		console.log("recieved update for Zubi:" + data)
	})
	//> recieved update for Zubi:some value
	client.emit(circuits.Messages.Operation, "Zubi", ["update"], {}, 111, "new value",function(err){
		assert(!err)
	})
	//> recieved update for Zubi:new value
	client.emit(circuits.Messages.Operation, "Zubi", ["read"], {}, 111, function(err,data){
		assert(!err)
		assert(data == "new value")
	})



## Installation

	npm install circuits
