
use "net"
use "collections"
use zmtp = "zmtp"

class _SocketConnection is TCPConnectionNotify // TODO: abstract away TCP types
  let _parent: Socket tag
  let _socket_type: String val
  
  let _buffer: Buffer = Buffer
  var _protocol: zmtp.Protocol = zmtp.ProtocolNone
  
  new iso create(parent: Socket, socket_type: String) =>
    _parent = parent
    _socket_type = socket_type
  
  ///
  // TCPConnectionNotify methods
  
  fun ref accepted(conn: TCPConnection ref) =>
    _reset(conn)
  
  fun ref connected(conn: TCPConnection ref) =>
    _reset(conn)
  
  fun ref connect_failed(conn: TCPConnection ref) =>
    _parent._disconnected(conn)
  
  fun ref closed(conn: TCPConnection ref) =>
    _parent._disconnected(conn)
  
  fun ref received(conn: TCPConnection ref, data: Array[U8] iso) =>
    _buffer.append(consume data)
    _protocol.handle_input(_buffer)
    _handle_protocol_events(conn)
  
  ///
  // Private convenience methods
  
  fun ref _handle_protocol_events(peer: _SocketPeer ref) =>
    while true do
      match _protocol.take_event()
      | None => break
      | zmtp.ProtocolEventHandshakeComplete => _parent._connected(peer)
      | let e: zmtp.ProtocolEventError => _protocol_error(peer, e.string)
      | let o: zmtp.ProtocolOutput => peer.write(o)
      | let m: zmtp.Message => _parent._received(peer, m)
      end
    end
  
  fun ref _reset(peer: _SocketPeer ref) =>
    _protocol = zmtp.ProtocolAuthNull.create(_socket_type)
    _protocol.handle_start()
    _buffer.clear()
  
  fun _protocol_error(peer: _SocketPeer ref, string: String) =>
    _parent._protocol_error(peer, string)
    peer.dispose()

class _SocketListenerConnection is TCPListenNotify
  let _parent: Socket tag
  let _socket_type: String val
  
  new iso create(parent: Socket, socket_type: String) =>
    _parent = parent
    _socket_type = socket_type
  
  fun ref connected(listen: TCPListener ref): TCPConnectionNotify iso^ =>
    _SocketConnection(_parent, _socket_type)
