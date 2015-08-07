
interface SessionHandleActivated     fun ref apply()                 => None
interface SessionHandleProtocolError fun ref apply(string: String)   => None
interface SessionHandleWrite         fun ref apply(bytes: Bytes)     => None
interface SessionHandleReceived      fun ref apply(message: Message) => None

class SessionHandleActivatedNone     is SessionHandleActivated
class SessionHandleProtocolErrorNone is SessionHandleProtocolError
class SessionHandleWriteNone         is SessionHandleWrite
class SessionHandleReceivedNone      is SessionHandleReceived

class Session
  var _protocol: Protocol = ProtocolNone
  
  var activated:      SessionHandleActivated     = SessionHandleActivatedNone
  var protocol_error: SessionHandleProtocolError = SessionHandleProtocolErrorNone
  var write:          SessionHandleWrite         = SessionHandleWriteNone
  var received:       SessionHandleReceived      = SessionHandleReceivedNone
  
  let _message_parser: MessageParser = MessageParser
  
  fun ref start(
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
    _protocol = protocol
    _protocol.handle_start()
  
  fun ref handle_input(buffer: _Buffer ref) =>
    _protocol.handle_input(buffer)
  
  ///
  // Convenience methods for use by Protocols
  
  fun ref _write_greeting() =>
    write(_Greeting.write())
  
  fun ref _read_greeting(buffer: _Buffer ref) ? =>
    _Greeting.read(buffer, protocol_error)
  
  fun ref _read_message(buffer: _Buffer ref): Message trn^? =>
    _message_parser.read(buffer, protocol_error)
