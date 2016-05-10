// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

interface ref _MessageWriteTransform
  fun ref apply(message: Message): Array[U8] val

interface SessionNotify
  fun ref activated(writex: _MessageWriteTransform)
  fun ref protocol_error(string: String)
  fun ref write(bytes: ByteSeq)
  fun ref received(message: Message)
  fun ref zap_request(zap: ZapRequest)

class _SessionNotifyNone is SessionNotify
  fun ref activated(writex: _MessageWriteTransform) => None
  fun ref protocol_error(string: String) => None
  fun ref write(bytes: ByteSeq) => None
  fun ref received(message: Message) => None
  fun ref zap_request(zap: ZapRequest) => None

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
  var notify: SessionNotify = _SessionNotifyNone
  var _mechanism: Mechanism = MechanismNone
  
  let _message_parser: MessageParser = MessageParser
  
  fun ref start(k: _SessionKeeper, n: SessionNotify, m: Mechanism) =>
    keeper = k
    notify = n
    _mechanism = m
    _mechanism.handle_start()
  
  fun ref handle_input(buffer: _Buffer ref) =>
    _mechanism.handle_input(buffer)
  
  fun ref handle_zap_response(zap: ZapResponse) =>
    _mechanism.handle_zap_response(zap)
  
  ///
  // Convenience methods for use by Mechanisms
  
  fun ref _write_greeting() =>
    notify.write(Greeting.write(keeper.auth_mechanism(), keeper.as_server()))
  
  fun ref _read_greeting(buffer: _Buffer ref)? =>
    Greeting.read(buffer, notify, keeper.auth_mechanism(), keeper.as_server())
  
  fun ref _write_command(command: Command) =>
    notify.write(CommandParser.write(command))
  
  fun ref _read_command(buffer: _Buffer ref): CommandUnknown? =>
    CommandParser.read(buffer, notify)
  
  fun ref _read_specific_command[A: Command ref](buffer: _Buffer ref): A? =>
    let c_data = _read_command(buffer)
    let command = A.create()
    
    try command(c_data) else
      notify.protocol_error("Expected "+command.name()+" command, got: "+c_data.name())
      error
    end
    
    command
  
  fun ref _read_message(buffer: _Buffer ref): Message trn^? =>
    _message_parser.read(buffer, notify)
  
  fun ref _add_to_message(frame: Frame) =>
    _message_parser.add_to_message(frame)
  
  fun ref _take_message(): Message trn^ =>
    _message_parser.take_message()
