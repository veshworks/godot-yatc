extends Node
class_name YatcAuthServer

func _init() -> void:
	self.name = 'YatcAuthServer'

const URL_AUTHORIZE = 'https://id.twitch.tv/oauth2/authorize'
const CALLBACK_PORT = 7777
const CALLBACK_URL = 'http://localhost:%d/' % CALLBACK_PORT

const SERVER_STARTUP_TIMEOUT = 5

static func open_auth_url(client_id: String, scope: Array[String]) -> void:
	var query = '&'.join([
		'response_type=token',
		'client_id=' + client_id,
		'redirect_uri=' + CALLBACK_URL,
		'scope=' + '+'.join(scope)
	])
	var href = URL_AUTHORIZE + '?' + query
	Logger.scope('Yatc.AuthServer').info('Opening %s on default browser to log-in' % href)
	OS.shell_open(href)


signal token_received(token: String)

var _server: TCPServer
var _clients: Array[StreamPeerTCP] = []

var logger:= Logger.scope('Yatc.AuthServer')

var time_processing: float

func _ready() -> void:
	logger.info('starting tcp server on %s' % CALLBACK_URL)

	_server = TCPServer.new()

	var err = _server.listen(CALLBACK_PORT)
	logger.info('tcp server: is_listening = %s' % _server.is_listening())
	logger.info('tcp server: is_connection_available = %s' % _server.is_connection_available())

	assert(err == OK, 'Error: cannot start auth server')
	if err:
		logger.error('tcp server failed to start (with error code: %s)' % err)

func _exit_tree() -> void:
	if _server:
		_server.stop()

func _process(_delta: float) -> void:
	if !_server: return

	var conn = _server.take_connection()
	if conn:
		logger.info('received connection')
		_clients.push_back(conn)

	for client: StreamPeerTCP in _clients:
		if client.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			continue
		logger.info('connection status connected')

		var bytes = client.get_available_bytes()
		_clients = _clients.filter(func(item): return item != client)
		var req_as_str = client.get_string(bytes)
		if req_as_str.length() < 1:
			continue
		logger.info('request from connect:\n%s' % req_as_str)

		var req_info = req_as_str.split('\n')[0].split(' ')
		var method = req_info[0]
		var url = req_info[1]

		match method:
			'GET':
				logger.info('rendering "login page"')
				send200(client, get_login_page())
			'POST':
				var token = URL.new(url).query.token
				if token:
					logger.info('token received: %s' % token)
					logger.info('rendering "blank page"')
					send200(client)
					token_received.emit(token)
					logger.info('token emitted')


func send200(client: StreamPeer, data: String = ''):
	var data_buffer = data.to_ascii_buffer()
	client.put_data(('HTTP/1.1 200 OK\r\n').to_ascii_buffer())
	client.put_data(('Server: AUTH_SERVER\r\n').to_ascii_buffer())
	client.put_data(('Content-Length: %d\r\n' % data_buffer.size()).to_ascii_buffer())
	client.put_data(('Connection: close\r\n').to_ascii_buffer())
	client.put_data(('Content-Type: text/html\r\n').to_ascii_buffer())
	client.put_data(('\r\n').to_ascii_buffer())
	client.put_data(data_buffer)


func get_login_page() -> String:
	var path = Yatc.get_module_path().path_join('public/index.html')
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	return content
