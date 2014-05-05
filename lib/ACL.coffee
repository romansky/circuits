

exports.ACL = class ACL

	@AllowAll : {
		verify : (userID, modelName, modelID, crudOp, cb)-> cb(null,true)
	}

	###
	ACL
	=======
	rules are of the followng heirarchy:
	ModelName / CRUD operation / user groups
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


	userGroupsResolver is a function that accepts a userID and a callback with 
	error and a list of groups, this is called only when target group is not "public"
	in which case it will allow it

	optionalCheck has the final say on access to a resource, it can be used for finer control
	over access to some resource, for example in cases when you only want to allow a model to be
	edited by the owner only
	an example optional function implementation:
	function ownerOnly(userID, model, modelId, crudOp, cb){
		if (model == "MyModel") {
			if (crudOp == "update" || crudOp == "delete"){
				MyModel.getById(modelId, function(err, myModel){
					if (err){
						cb("could not find model", false);
					} else {
						if (myModel.createdBy == userID){
							cb(null, true)
						} else {
							cb("not allowed", false)
						}
					};
				})
			} else cb("operation not supported", false);
		} else cb("model not found", false);
	}
	###

	#param rules
	constructor : (@rules, @userGroupsResolver, @optionalCheck = ( (args...,cb)-> cb(null, true)) )->


	verify : (userID, modelName, modelID, crudOp, cb)=>
		allowedG = @rules?[modelName]?[crudOp]
		if not allowedG or allowedG.length == 0 then cb("not allowed",false)
		else
			if allowedG.indexOf('public') >= 0
				@optionalCheck(userID, modelName, modelID, crudOp, cb)
			else
				@userGroupsResolver userID, (err, groups)->
					if err then cb("user not in correct group", false)
					else
						if ( groups.some (g)-> allowedG.indexOf(g) >= 0 )
							@optionalCheck(userID, modelName, modelID, crudOp, cb)
						else cb("not allowed")