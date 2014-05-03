{ACL} = require '../lib/ACL'

describe "ACL spec",->

	it "allows access by model and crud op for public group" ,(done)->
		checkedOptional = false
		rules = {
			"TestModel" : { "read" : ["public"] }
		}
		userGroupsResolver = (userID)->
			throw "should not check for public"
		optionalCheck = (userID, modelName, modelID, crudOp, cb)->
			checkedOptional = true
			cb(null, true)

		acl = new ACL(rules, userGroupsResolver, optionalCheck)
		acl.verify "test-user", "TestModel", 1, "read", (err,result)->
			expect(err).toBeNull()
			expect(result).toBeTruthy()
			expect(checkedOptional).toBeTruthy()
			done()