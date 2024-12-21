
class_name RconServer
extends Node

signal on_client_connected(rcon_client: RconClient)
signal on_client_disconnected(rcon_client: RconClient, reason: RconClient.DisconnectReason)
signal on_command_recieved(rcon_client: RconClient, message: RconMessage)

@export var bind_address: String = "*"
@export var port: int = 27015 
@export var password: String = ""

var _server: TCPServer = TCPServer.new()
var clients: Array[RconClient] = []

func _ready() -> void:
	if _server.listen(port, bind_address) == OK:
		print("RCON Server started listening on port: ", port)
	else:
		print("Failed to start RCON server")
		queue_free()

func _process(_delta):
	if _server.is_connection_available():
		var stream: StreamPeerTCP = _server.take_connection()
		if stream:
			stream.set_no_delay(true)
			var client = RconClient.new(self, stream)
			clients.append(client)
			print("New RCON client connected: ", client.id)
			on_client_connected.emit(client)

	for client in clients:
		match client.stream.get_status():
			StreamPeerTCP.STATUS_CONNECTED:
				var data: RconMessageResult = RconMessage.get_from_client(client)
				if not data.error == "":
					print("Recieved an invalid rcon packet, terminating connection... client_id(", client.id, ")")
					disconnect_client(client, RconClient.DisconnectReason.INVALID_PACKET)
				elif not data.is_empty:
					if (data.message.type == RconMessage.TYPE_AUTH):
						if (client.is_authenticated):
							data.message.acknowledge(RconMessage.TYPE_AUTH_RESPONSE)
						elif data.message.body == password:
							client.is_authenticated = true
							data.message.acknowledge(RconMessage.TYPE_AUTH_RESPONSE)
						else:
							data.message.respond("", RconMessage.TYPE_AUTH_RESPONSE, -1)
							disconnect_client(client, RconClient.DisconnectReason.AUTHENTICATION_FAILED)

					elif (data.message.type == RconMessage.TYPE_EXECCOMMAND):
						if (!client.is_authenticated):
							data.message.respond("", RconMessage.TYPE_AUTH_RESPONSE, -1)
							disconnect_client(client, RconClient.DisconnectReason.AUTHENTICATION_FAILED)
						else:
							on_command_recieved.emit(client, data.message)

			_:
				disconnect_client(client, RconClient.DisconnectReason.UNKNOWN)

func _notification(what: int):
	if what == NOTIFICATION_PREDELETE:
		for client in clients:
			disconnect_client(client, RconClient.DisconnectReason.SERVER_SHUTDOWN)
		_server.stop()
		print("RCON Server stopped")

func disconnect_client(client: RconClient, reason: RconClient.DisconnectReason):
	clients.erase(client)
	client.stream.disconnect_from_host()
	print("RCON Client disconnected ", client.id, " because ", str(reason))
	on_client_disconnected.emit(client, reason)
