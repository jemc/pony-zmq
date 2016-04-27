// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

primitive _MechanismAuthNullStateReadGreeting
primitive _MechanismAuthNullStateReadHandshakeReady
primitive _MechanismAuthNullStateReadMessage

type _MechanismAuthNullState is
  ( _MechanismAuthNullStateReadGreeting
  | _MechanismAuthNullStateReadHandshakeReady
  | _MechanismAuthNullStateReadMessage)

class MechanismAuthNull is Mechanism
  let _session: Session
  var _state: _MechanismAuthNullState = _MechanismAuthNullStateReadGreeting
  
  new create(session: Session) =>
    _session = session
  
  fun ref _next_state(state: _MechanismAuthNullState) =>
    _state = state
  
  fun ref handle_input(buffer: _Buffer ref) =>
    try while true do
      match _state
      | _MechanismAuthNullStateReadGreeting       => _read_greeting(buffer)
      | _MechanismAuthNullStateReadHandshakeReady => _read_ready_command(buffer)
      | _MechanismAuthNullStateReadMessage        => _read_message(buffer)
      end
    end end
  
  fun ref handle_start() =>
    _next_state(_MechanismAuthNullStateReadGreeting)
    _session._write_greeting()
  
  fun ref _write_greeting() =>
    _session._write_greeting()
  
  fun ref _read_greeting(buffer: _Buffer ref)? =>
    _session._read_greeting(buffer)
    _next_state(_MechanismAuthNullStateReadHandshakeReady)
    _write_ready_command()
  
  fun ref _write_ready_command() =>
    let command = CommandAuthNullReady
    command.metadata("Socket-Type") = _session.keeper.socket_type_string()
    _session._write_command(command)
  
  fun ref _read_ready_command(buffer: _Buffer ref)? =>
    let command = _session._read_specific_command[CommandAuthNullReady](buffer)
    
    let other_type = try command.metadata("Socket-Type") else "" end
    if not _session.keeper.socket_type_accepts(other_type) then
      let this_type = _session.keeper.socket_type_string()
      _session.protocol_error(this_type+" socket cannot accept: "+other_type)
      error
    end
    
    _session.activated(recover MessageWriter end)
    _next_state(_MechanismAuthNullStateReadMessage)
  
  fun ref _read_message(buffer: _Buffer ref) ? =>
    _session.received(_session._read_message(buffer))
    _next_state(_MechanismAuthNullStateReadMessage)
