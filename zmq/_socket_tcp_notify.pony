
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
  var _protocol: zmtp.Protocol = zmtp.ProtocolNone
  
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
    _protocol.handle_input(_buffer)
    _handle_protocol_events(conn)
  
  ///
  // Private convenience methods
  
  fun ref _reset(conn: TCPConnection ref) =>
    _protocol = zmtp.ProtocolAuthNull.create(_socket_type)
    _protocol.handle_start()
    _buffer.clear()
    _handle_protocol_events(conn)
  
  fun ref _handle_protocol_events(conn: TCPConnection ref) =>
    while true do
      match _protocol.take_event()
      | None => break
      | zmtp.ProtocolEventHandshakeComplete => _parent.activated(conn)
      | let e: zmtp.ProtocolEventError => _parent.protocol_error(e.string)
      | let o: zmtp.ProtocolOutput => conn.write(o)
      | let m: zmtp.Message => _parent.received(m)
      end
    end
