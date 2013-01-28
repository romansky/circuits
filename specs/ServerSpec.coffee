{RedisClient} = require '../lib/RedisClient'
{Server} = require '../lib/Server'
{Config} = require '../lib/Config'


__config = Config.get Config.preset.TEST
__server = null
getServerInstance = ()->
	# if _server then _server.
	__server = new Server __config
	return __server

describe "Server Specs",->

	beforeEach ->
		RedisClient.get(__config).flushdb()

	afterEach ->
		RedisClient.destroy(true)

	it "registers and listens to pub sub on backend",->
		asyncSpecWait()
		server = getServerInstance()
		spy = spyOn(server, "recieveEvent").andCallFake ()-> 
			expect(true).toEqual(true)
			asyncSpecDone()
		server.onPulishReady ()->
			server.publishEvent "some event"

		
