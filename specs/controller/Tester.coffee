
doThrow = -> throw new Error("should not be here....")

exports.Tester = class Tester 
	
	@create : ()->			doThrow()
	@read :   (id, cb)->	doThrow()
	@update : (id, data, cb)-> doThrow()
	@delete : ()->			doThrow()