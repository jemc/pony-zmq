
primitive _ProtocolAuthNullStateReadGreeting
primitive _ProtocolAuthNullStateReadHandshakeReady
primitive _ProtocolAuthNullStateReadMessage

type _ProtocolAuthNullState is
  ( _ProtocolAuthNullStateReadGreeting
  | _ProtocolAuthNullStateReadHandshakeReady
  | _ProtocolAuthNullStateReadMessage)

class ProtocolAuthNull is Protocol
  let _session: Session
  var _state: _ProtocolAuthNullState = _ProtocolAuthNullStateReadGreeting
  
  new create(session: Session) =>
    _session = session
  
  fun ref _next_state(state: _ProtocolAuthNullState) =>
    _state = state
  
  fun ref handle_input(buffer: _Buffer ref) =>
    try while true do
      match _state
      | _ProtocolAuthNullStateReadGreeting       => _read_greeting(buffer)
      | _ProtocolAuthNullStateReadHandshakeReady => _read_ready_command(buffer)
      | _ProtocolAuthNullStateReadMessage        => _read_message(buffer)
      end
    end end
  
  fun ref handle_start() =>
    _next_state(_ProtocolAuthNullStateReadGreeting)
    _session._write_greeting()
  
  fun ref _write_greeting() =>
    _session._write_greeting()
  
  fun ref _read_greeting(buffer: _Buffer ref)? =>
    _session._read_greeting(buffer)
    _next_state(_ProtocolAuthNullStateReadHandshakeReady)
    _write_ready_command()
  
  fun ref _write_ready_command() =>
    let command = _CommandAuthNullReady
    command.metadata("Socket-Type") = _session.keeper.socket_type_string()
    _session._write_command(command)
  
  fun ref _read_ready_command(buffer: _Buffer ref)? =>
    let command = _CommandAuthNullReady
    let c_data = _session._read_command(buffer)
    
    try command(c_data) else
      _session.protocol_error("Expected READY command, got: "+c_data.name())
      error
    end
    
    let other_type = try command.metadata("Socket-Type") else "" end
    if not _session.keeper.socket_type_accepts(other_type) then
      let this_type = _session.keeper.socket_type_string()
      _session.protocol_error(this_type+" socket cannot accept: "+other_type)
      error
    end
    
    _session.activated(recover MessageParser~write() end)
    _next_state(_ProtocolAuthNullStateReadMessage)
  
  fun ref _read_message(buffer: _Buffer ref) ? =>
    _session.received(_session._read_message(buffer))
    _next_state(_ProtocolAuthNullStateReadMessage)
