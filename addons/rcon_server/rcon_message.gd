
class_name RconMessage
extends Object

const TYPE_AUTH: int = 3
const TYPE_EXECCOMMAND: int = 2
const TYPE_AUTH_RESPONSE: int = 2
const TYPE_RESPONSE_VALUE: int = 0

var id: int
var type: int
var body: String

var _client: RconClient

func _init(p_client: RconClient, p_id: int, p_type: int, p_body: String):
	_client = p_client
	id = p_id
	type = p_type
	body = p_body
	
const MAX_BODY_SIZE: int = 4082 # 4096 - the 14 bytes needed for the rest of the packet
	
func send():
	var body_bytes: PackedByteArray = body.to_utf8_buffer()
	
	var count: int = 0
	while count * MAX_BODY_SIZE <= body_bytes.size():
		var index: int = count * MAX_BODY_SIZE
		_send_INTERNAL(body_bytes.slice(index, index + MAX_BODY_SIZE))
		count = count + 1

func _send_INTERNAL(p_body: PackedByteArray):
	# Size			32-bit little-endian Signed Integer
	# ID			32-bit little-endian Signed Integer
	# Type			32-bit little-endian Signed Integer
	# Body			Null-terminated ASCII String
	# Empty String	Null-terminated ASCII String
	var packet: PackedByteArray = PackedByteArray()
	var size: int               = 10 + p_body.size()

	packet.resize(4 + size)
	packet.encode_s32(0, size)
	packet.encode_s32(4, id)
	packet.encode_s32(8, type)
	for i in p_body.size():
		packet[i + 12] = p_body[i]
	packet.encode_s16(12 + p_body.size(), 0) # End of body + Empty String (2 null bytes)

	_client.stream.put_data(packet)

func acknowledge(p_type: int = TYPE_RESPONSE_VALUE):
	respond("", p_type)

func respond(p_body: String, p_type: int = TYPE_RESPONSE_VALUE, p_id: int = id):
	var response = RconMessage.new(_client, p_id, p_type, p_body)
	response.send()

static func get_from_client(p_client: RconClient) -> RconMessageResult:
	var available_bytes: int = p_client.stream.get_available_bytes()
	if available_bytes == 0:
		return RconMessageResult.new_empty()
	
	if available_bytes < 14:
		return RconMessageResult.new_error("Packet is below minimum size (expected 14 bytes, got " + str(available_bytes) + " bytes)")
	
	var _size: int
	var _id: int
	var _type: int
	var _body: String
	
	# Size
	_size = p_client.stream.get_32()
	if _size < 10 or _size - 10 > MAX_BODY_SIZE:
		return RconMessageResult.new_error("Payload size is " + str(_size) + " bytes, but expected > 10 and < 4082")
	if _size < available_bytes - 4:
		return RconMessageResult.new_error("Payload size is more than the available bytes (has " + str(available_bytes - 4) + ", wants " + str(_size) + ")")
		
	# ID
	_id = p_client.stream.get_32()
	
	# Type
	var type_unparsed: int = p_client.stream.get_32()
	match (type_unparsed):
		TYPE_AUTH:
			_type = type_unparsed
		TYPE_EXECCOMMAND:
			_type = type_unparsed
		_:
			return RconMessageResult.new_error("Invalid type: " + str(type_unparsed))
		
	# Body
	_body = p_client.stream.get_utf8_string(_size - 10)
	p_client.stream.get_8()
	
	# Empty String
	p_client.stream.get_8()
	
	var rconMessage = RconMessage.new(p_client, _id, _type, _body)
	return RconMessageResult.new_success(rconMessage)
