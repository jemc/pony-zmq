
use "net"
use zmtp = "zmtp"
// use "./inspect"

interface _SocketTCPNotifiable tag
  be protocol_error(string: String)
  be activated(conn: TCPConnection)
  be closed()
  be connect_failed()
  be received(message: zmtp.Message)

class _SocketTCPNotify is TCPConnectionNotify
  let _parent: _SocketTCPNotifiable
  let _socket_type: SocketType
  
  let _buffer: Buffer = Buffer
  var _session: zmtp.Session = zmtp.Session
  
  new iso create(parent: _SocketTCPNotifiable, socket_type: SocketType) =>
    _parent = parent
    _socket_type = socket_type
  
  ///
  // TCPConnectionNotify methods
  
  fun ref accepted(conn: TCPConnection ref) =>
    // Inspect.print("_SocketTCPNotify.accepted")
    _reset(conn)
  
  fun ref connected(conn: TCPConnection ref) =>
    // Inspect.print("_SocketTCPNotify.connected")
    _reset(conn)
  
  fun ref connect_failed(conn: TCPConnection ref) =>
    // Inspect.print("_SocketTCPNotify.connect_failed")
    _parent.connect_failed()
  
  fun ref closed(conn: TCPConnection ref) =>
    // Inspect.print("_SocketTCPNotify.closed")
    _parent.closed()
  
  fun ref received(conn: TCPConnection ref, data': Array[U8] iso) =>
    let data: Array[U8] trn = recover consume data' end
    // Inspect.print("_SocketTCPNotify.received " + Inspect(data))
    _buffer.append(consume data)
    _session.handle_input(_buffer)
  
  ///
  // Private convenience methods
  
  fun ref _reset(conn: TCPConnection ref) =>
    _buffer.clear()
    _session.start(where
      protocol = zmtp.ProtocolAuthNull.create(_session, _socket_type),
      handle_activated      = this~_handle_activated(conn),
      handle_protocol_error = this~_handle_protocol_error(conn),
      handle_write          = this~_handle_write(conn),
      handle_received       = this~_handle_received(conn)
    )
  
  ///
  // Session handler methods
  
  fun ref _handle_activated(conn: TCPConnection ref) =>
    _parent.activated(conn)
  
  fun ref _handle_protocol_error(conn: TCPConnection ref, string: String) =>
    _parent.protocol_error(string)
  
  fun ref _handle_write(conn: TCPConnection ref, bytes: Bytes) =>
    conn.write(bytes)
  
  fun ref _handle_received(conn: TCPConnection ref, message: Message) =>
    _parent.received(message)
