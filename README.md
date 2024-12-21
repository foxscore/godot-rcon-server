# RCON server for Godot

Functional, but not perfect

## Usage

1. Create a `RconServer` node
2. Set the desired bind-address *(default: `*`, for local-only set to `127.0.0.1`)*, port *(default: `27015`)*, and password *(optional)*
    - Only the password can be changed after the server started
    - Simply destroy the node to stop the server
3. Subscribe to its `on_command_recieved` signal to receive messages
   - The content sent by the clients is the `message.body` field
