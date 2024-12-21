
class_name RconMessageResult

var is_empty: bool:
	get:
		return (not message) and error == ""

var message: RconMessage
var error: String

func _init(p_message: RconMessage, p_error: String):
	message = p_message
	error = p_error
	
static func new_empty() -> RconMessageResult:
	return RconMessageResult.new(null, "")

static func new_error(reason: String) -> RconMessageResult:
	push_warning("New RCON message result from error: " + reason)
	return RconMessageResult.new(null, reason)
	
static func new_success(p_message: RconMessage):
	return RconMessageResult.new(p_message, "")
