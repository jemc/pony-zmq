
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
  let _socket_type: String val
  
  var _state: _ProtocolAuthNullState = _ProtocolAuthNullStateReadGreeting
  let _message_parser: MessageParser = MessageParser
  let _events: List[ProtocolEvent] = List[ProtocolEvent]
  
  new create(socket_type: String val) =>
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
  
  fun ref take_event(): (ProtocolEvent | None) =>
    try _events.shift() end
  
  fun ref _protocol_error(string: String)? =>
    _events.push(ProtocolEventError(string))
    error
  
  fun ref _write_greeting() =>
    _events.push(_Greeting.write())
  
  fun ref _read_greeting(buffer: Buffer ref) ? =>
    (let success, let string) = _Greeting.read(buffer)
    if not success then _protocol_error(string) end
    
    _next_state(_ProtocolAuthNullStateReadHandshakeReady)
    _write_ready_command()
  
  fun ref _write_ready_command() =>
    let command = _CommandAuthNullReady
    command.metadata.update("Socket-Type", _socket_type)
    _events.push(_CommandParser.write(command))
  
  fun ref _read_ready_command(buffer: Buffer ref) ? =>
    let command = _CommandAuthNullReady
    (let success, let string) = _CommandParser.read(command, buffer)
    if not success then _protocol_error(string) end
    
    // TODO: verify valid socket type in metadata
    let other_socket_type = try command.metadata("Socket-Type") else "" end
    
    _events.push(ProtocolEventHandshakeComplete)
    _next_state(_ProtocolAuthNullStateReadMessage)
  
  fun ref _read_message(buffer: Buffer ref) ? =>
    (let success, let string) = _message_parser.read(buffer)
    if not success then _protocol_error(string) end
    
    _events.push(_message_parser.take_message())
    _next_state(_ProtocolAuthNullStateReadMessage)
