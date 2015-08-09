
use "net"
use zmtp = "zmtp"

interface _SocketTCPNotifiable tag
  be protocol_error(string: String)
  be activated(conn: TCPConnection, writex: _MessageWriteTransform)
  be closed()
  be connect_failed()
  be received(message: zmtp.Message)

class _SocketTCPNotify is TCPConnectionNotify
  let _parent: _SocketTCPNotifiable
  let _session: _SessionKeeper
  
  new iso create(parent: _SocketTCPNotifiable,
    socket_type: SocketType, socket_opts: SocketOptions val
  ) =>
    _parent = parent
    _session = _SessionKeeper(socket_type, socket_opts)
  
  ///
  // TCPConnectionNotify methods
  
  fun ref accepted(conn: TCPConnection ref) =>
    _start(conn)
  
  fun ref connected(conn: TCPConnection ref) =>
    _start(conn)
  
  fun ref connect_failed(conn: TCPConnection ref) =>
    _parent.connect_failed()
  
  fun ref closed(conn: TCPConnection ref) =>
    _parent.closed()
  
  fun ref received(conn: TCPConnection ref, data: Array[U8] iso) =>
    _session.handle_input(consume data)
  
  ///
  // Private convenience methods
  
  fun ref _start(conn: TCPConnection ref) =>
    _session.start(where
      handle_activated      = this~_handle_activated(conn),
      handle_protocol_error = this~_handle_protocol_error(conn),
      handle_write          = this~_handle_write(conn),
      handle_received       = this~_handle_received(conn)
    )
  
  ///
  // Session handler methods
  
  fun ref _handle_activated(conn: TCPConnection ref, writex: _MessageWriteTransform) =>
    _parent.activated(conn, consume writex)
  
  fun ref _handle_protocol_error(conn: TCPConnection ref, string: String) =>
    _parent.protocol_error(string)
  
  fun ref _handle_write(conn: TCPConnection ref, bytes: Bytes) =>
    conn.write(bytes)
  
  fun ref _handle_received(conn: TCPConnection ref, message: Message) =>
    _parent.received(message)
