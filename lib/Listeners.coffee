{CRUD} = require './CRUD'

logr = require('node-logr').getLogger(__filename,"circuits")

exports.Listeners = class Listeners

	listeners : null
	idToListeners : null

	constructor : ()->
		@listeners = {}
		@idToListeners = {}

	###
	@param String id
	@param String entityName
	@param [CRUD] crudOps
	@param Integer entityId
	@returns Bool - was the operation succesful
	###
	add : (id, entityName, crudOps, entityId)=>
		allowed = [CRUD.update, CRUD.delete, CRUD.create, CRUD.patch]

		if crudOps.filter((co)-> allowed.indexOf(co) == -1).length > 0
			logr.notice "client #{id} trying to register crudOps:#{crudOps} entity:#{entityName} eId:#{entityId}"
			return false

		@listeners[ entityName ] ?= {}
		for co in crudOps
			@idToListeners[ id ] ?= []
			if not @idToListeners[id].some((x)-> simpleCompareArrs(x, [entityName,co,entityId]) )
				@listeners[entityName][co] ?= {}
				@listeners[entityName][co][entityId] ?= []
				@listeners[entityName][co][entityId].push( id )

				@idToListeners[id] ?= []
				@idToListeners[id].push([entityName,co,entityId])


	###
	@param String entityName
	@param CRUD crudOp
	@param Integer entityId
	@returns [<id1>,<id2>,...]
	###
	getList : (entityName, crudOp, entityId)=>
		( @listeners[entityName]?[crudOp]?[entityId] ) || []

		

	remove: (id)=>
		(@idToListeners[id] || []).forEach( (x)=> 
			@listeners[x[0]][x[1]][x[2]].splice( @listeners[x[0]][x[1]][x[2]].indexOf(id), 1 )
			if @listeners[x[0]][x[1]][x[2]].length == 0
				delete @listeners[x[0]][x[1]][x[2]]
		)
		@idToListeners[id]



simpleCompareArrs = (arr1, arr2)-> 
	!arr1.some((x)-> arr2.indexOf(x) == -1)
	


