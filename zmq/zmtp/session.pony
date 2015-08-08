
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

interface SocketType val
  fun string(): String
  fun accepts(other: String): Bool

primitive SocketTypeNone
  fun string(): String => ""
  fun accepts(other: String): Bool => false

class Session
  var _protocol: Protocol = ProtocolNone
  var _socket_type: SocketType = SocketTypeNone
  
  var activated:      SessionHandleActivated     = SessionHandleActivatedNone
  var protocol_error: SessionHandleProtocolError = SessionHandleProtocolErrorNone
  var write:          SessionHandleWrite         = SessionHandleWriteNone
  var received:       SessionHandleReceived      = SessionHandleReceivedNone
  
  let _message_parser: MessageParser = MessageParser
  
  fun ref start(
    protocol:    Protocol,
    socket_type: SocketType,
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
    _socket_type = socket_type
    _protocol.handle_start()
  
  fun ref handle_input(buffer: _Buffer ref) =>
    _protocol.handle_input(buffer)
  
  ///
  // Convenience methods for use by Protocols
  
  fun _socket_type_string(): String =>
    _socket_type.string()
  
  fun _socket_type_accepts(string: String): Bool =>
    _socket_type.accepts(string)
  
  fun ref _write_greeting() =>
    write(_Greeting.write())
  
  fun ref _read_greeting(buffer: _Buffer ref) ? =>
    _Greeting.read(buffer, protocol_error)
  
  fun ref _write_command(command: _Command) =>
    write(_CommandParser.write(command))
  
  fun ref _read_command(buffer: _Buffer ref): _CommandUnknown? =>
    _CommandParser.read(buffer, protocol_error)
  
  fun ref _read_message(buffer: _Buffer ref): Message trn^? =>
    _message_parser.read(buffer, protocol_error)
