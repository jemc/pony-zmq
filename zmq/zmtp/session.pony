// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

interface _MessageWriteTransform iso
  fun ref apply(message: Message): Array[U8] val

interface SessionHandleActivated     fun ref apply(writex: _MessageWriteTransform) => None
interface SessionHandleProtocolError fun ref apply(string: String)                 => None
interface SessionHandleWrite         fun ref apply(bytes: Bytes)                   => None
interface SessionHandleReceived      fun ref apply(message: Message)               => None

class SessionHandleActivatedNone     is SessionHandleActivated
class SessionHandleProtocolErrorNone is SessionHandleProtocolError
class SessionHandleWriteNone         is SessionHandleWrite
class SessionHandleReceivedNone      is SessionHandleReceived

interface _SessionKeeper
  fun as_server(): Bool
  fun auth_mechanism(): String
  fun socket_type_string(): String
  fun socket_type_accepts(string: String): Bool

class _SessionKeeperNone is _SessionKeeper
  fun as_server(): Bool => false
  fun auth_mechanism(): String => ""
  fun socket_type_string(): String => ""
  fun socket_type_accepts(string: String): Bool => false

class Session
  var keeper: _SessionKeeper = _SessionKeeperNone
  var _protocol: Protocol = ProtocolNone
  
  var activated:      SessionHandleActivated     = SessionHandleActivatedNone
  var protocol_error: SessionHandleProtocolError = SessionHandleProtocolErrorNone
  var write:          SessionHandleWrite         = SessionHandleWriteNone
  var received:       SessionHandleReceived      = SessionHandleReceivedNone
  
  let _message_parser: MessageParser = MessageParser
  
  fun ref start(
    session_keeper: _SessionKeeper,
    protocol: Protocol,
    handle_activated:      SessionHandleActivated,
    handle_protocol_error: SessionHandleProtocolError,
    handle_write:          SessionHandleWrite,
    handle_received:       SessionHandleReceived
  ) =>
    activated      = handle_activated
    protocol_error = handle_protocol_error
    write          = handle_write
    received       = handle_received
    keeper = session_keeper
    _protocol = protocol
    _protocol.handle_start()
  
  fun ref handle_input(buffer: _Buffer ref) =>
    _protocol.handle_input(buffer)
  
  ///
  // Convenience methods for use by Protocols
  
  fun ref _write_greeting() =>
    write(Greeting.write(keeper.auth_mechanism(), keeper.as_server()))
  
  fun ref _read_greeting(buffer: _Buffer ref)? =>
    Greeting.read(buffer, protocol_error,
      keeper.auth_mechanism(), keeper.as_server())
  
  fun ref _write_command(command: Command) =>
    write(CommandParser.write(command))
  
  fun ref _read_command(buffer: _Buffer ref): CommandUnknown? =>
    CommandParser.read(buffer, protocol_error)
  
  fun ref _read_specific_command[A: Command ref](buffer: _Buffer ref): A? =>
    let command = A.create()
    let c_data = _read_command(buffer)
    
    try command(c_data) else
      protocol_error("Expected "+command.name()+" command, got: "+c_data.name())
      error
    end
    
    command
  
  fun ref _read_message(buffer: _Buffer ref): Message trn^? =>
    _message_parser.read(buffer, protocol_error)
  
  fun ref _add_to_message(frame: Frame) =>
    _message_parser.add_to_message(frame)
  
  fun ref _take_message(): Message trn^ =>
    _message_parser.take_message()
