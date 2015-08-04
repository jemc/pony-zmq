
use "net"
use "collections"

primitive _ProtocolAuthNullStateReadGreeting
primitive _ProtocolAuthNullStateReadHandshakeReady
primitive _ProtocolAuthNullStateReadMessage

type _ProtocolAuthNullState is
  ( _ProtocolAuthNullStateReadGreeting
  | _ProtocolAuthNullStateReadHandshakeReady
  | _ProtocolAuthNullStateReadMessage)

interface SocketType val
  fun string(): String
  fun accepts(other: String): Bool

class ProtocolAuthNull is Protocol
  let _session: Session
  let _socket_type: SocketType
  
  var _state: _ProtocolAuthNullState = _ProtocolAuthNullStateReadGreeting
  let _message_parser: MessageParser = MessageParser
  
  new create(session: Session, socket_type: SocketType) =>
    _session = session
    _socket_type = socket_type
  
  fun ref _next_state(state: _ProtocolAuthNullState) =>
    _state = state
  
  fun ref handle_input(buffer: Buffer ref) =>
    try while true do
      match _state
      | _ProtocolAuthNullStateReadGreeting       => _read_greeting(buffer)
      | _ProtocolAuthNullStateReadHandshakeReady => _read_ready_command(buffer)
      | _ProtocolAuthNullStateReadMessage        => _read_message(buffer)
      end
    end end
  
  fun ref handle_start() =>
    _next_state(_ProtocolAuthNullStateReadGreeting)
    _write_greeting()
  
  fun ref _protocol_error(string: String)? =>
    _session.protocol_error(string)
    error
  
  fun ref _write_greeting() =>
    _session.write(_Greeting.write())
  
  fun ref _read_greeting(buffer: Buffer ref) ? =>
    (let success, let string) = _Greeting.read(buffer)
    if not success then _protocol_error(string) end
    
    _next_state(_ProtocolAuthNullStateReadHandshakeReady)
    _write_ready_command()
  
  fun ref _write_ready_command() =>
    let command = _CommandAuthNullReady
    command.metadata.update("Socket-Type", _socket_type.string())
    _session.write(_CommandParser.write(command))
  
  fun ref _read_ready_command(buffer: Buffer ref) ? =>
    let command = _CommandAuthNullReady
    (let success, let string) = _CommandParser.read(command, buffer)
    if not success then _protocol_error(string) end
    
    // TODO: verify valid socket type in metadata
    let other_socket_type = try command.metadata("Socket-Type") else "" end
    
    _session.activated()
    _next_state(_ProtocolAuthNullStateReadMessage)
  
  fun ref _read_message(buffer: Buffer ref) ? =>
    (let success, let string) = _message_parser.read(buffer)
    if not success then _protocol_error(string) end
    
    _session.received(_message_parser.take_message())
    _next_state(_ProtocolAuthNullStateReadMessage)
