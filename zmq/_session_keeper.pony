
use net = "net"
use zmtp = "zmtp"

class _SessionKeeper
  let _session: zmtp.Session = zmtp.Session
  
  let _socket_type: SocketType
  let _socket_opts: SocketOptions val
  
  let _buffer: net.Buffer = net.Buffer
  
  new create(
    socket_type: SocketType,
    socket_opts: SocketOptions val
  ) =>
    _socket_type = socket_type
    _socket_opts = socket_opts
  
  fun ref start(
    handle_activated:      zmtp.SessionHandleActivated,
    handle_protocol_error: zmtp.SessionHandleProtocolError,
    handle_write:          zmtp.SessionHandleWrite,
    handle_received:       zmtp.SessionHandleReceived
  ) =>
    _buffer.clear()
    _session.start(where
      keeper' = this,
      protocol = zmtp.ProtocolAuthNull.create(_session),
      handle_activated      = handle_activated,
      handle_protocol_error = handle_protocol_error,
      handle_write          = handle_write,
      handle_received       = handle_received
    )
  
  fun ref handle_input(data: Array[U8] iso) =>
    _buffer.append(consume data)
    _session.handle_input(_buffer)
  
  ///
  // Convenience methods for the underlying session
  
  fun socket_type_string(): String =>
    _socket_type.string()
  
  fun socket_type_accepts(string: String): Bool =>
    _socket_type.accepts(string)