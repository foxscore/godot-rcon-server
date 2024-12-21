
class_name RconClient

enum DisconnectReason {
	UNKNOWN = 0,
	AUTHENTICATION_FAILED = 1,
	INVALID_PACKET = 2,
	SERVER_SHUTDOWN = 3,
}

static var _idCounter: int = 0

var server: RconServer
var stream: StreamPeerTCP
var id: int

var is_authenticated: bool:
	get:
		if server.password == "":
			return true
		else:
			return is_authenticated
	set(value):
		is_authenticated = value

func _init(p_server: RconServer, p_stream: StreamPeerTCP):
	server = p_server
	stream = p_stream
	_idCounter += 1
	id = _idCounter

func disconnect_client(reason: DisconnectReason):
	server.disconnect_client(self, reason)
