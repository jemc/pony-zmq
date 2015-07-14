
use "net"
use "collections"

primitive _ProtocolAuthNullStateReadGreeting
primitive _ProtocolAuthNullStateReadHandshakeReady
primitive _ProtocolAuthNullStateReadMessage

type _ProtocolAuthNullState is
  ( _ProtocolAuthNullStateReadGreeting
  | _ProtocolAuthNullStateReadHandshakeReady
  | _ProtocolAuthNullStateReadMessage)

class ProtocolAuthNull is Protocol
  let _parent: _ClientConnection ref
  let _socket_type: String val
  
  var _state: _ProtocolAuthNullState = _ProtocolAuthNullStateReadGreeting
  let _message_parser: _MessageParser = _MessageParser
  
  new create(parent: _ClientConnection ref, socket_type: String val) =>
    _parent = parent
    _socket_type = socket_type
  
  fun ref _next_state(state: _ProtocolAuthNullState) =>
    _state = state
  
  fun ref handle_input(peer: _ClientPeer ref, buffer: Buffer ref) =>
    try while true do
      match _state
      | _ProtocolAuthNullStateReadGreeting       => _read_greeting(peer, buffer)
      | _ProtocolAuthNullStateReadHandshakeReady => _read_ready_command(peer, buffer)
      | _ProtocolAuthNullStateReadMessage        => _read_message(peer, buffer)
      end
    end end
  
  fun ref handle_start(peer: _ClientPeer ref) =>
    _next_state(_ProtocolAuthNullStateReadGreeting)
    _write_greeting(peer)
    
  fun ref _write_greeting(peer: _ClientPeer ref) =>
    _parent.write(peer, _Greeting.write())
  
  fun ref _read_greeting(peer: _ClientPeer ref, buffer: Buffer ref) ? =>
    (let success, let string) = _Greeting.read(buffer)
    if not success then _parent.protocol_error(peer, string) end
    
    _next_state(_ProtocolAuthNullStateReadHandshakeReady)
    _write_ready_command(peer)
  
  fun ref _write_ready_command(peer: _ClientPeer ref) =>
    let command = _CommandAuthNullReady
    command.metadata.update("Socket-Type", _socket_type)
    _parent.write(peer, _CommandParser.write(command))
  
  fun ref _read_ready_command(peer: _ClientPeer ref, buffer: Buffer ref) ? =>
    let command = _CommandAuthNullReady
    (let success, let string) = _CommandParser.read(command, buffer)
    if not success then _parent.protocol_error(peer, string) end
    
    // TODO: verify valid socket type in metadata
    let other_socket_type = try command.metadata("Socket-Type") else "" end
    
    _parent.handshake_complete(peer)
    _next_state(_ProtocolAuthNullStateReadMessage)
  
  fun ref _read_message(peer: _ClientPeer ref, buffer: Buffer ref) ? =>
    (let success, let string) = _message_parser.read(buffer)
    if not success then _parent.protocol_error(peer, string) end
    
    let message = _message_parser.message = recover trn Message end
    _parent.received_message(peer, consume message)
    
    _next_state(_ProtocolAuthNullStateReadMessage)
