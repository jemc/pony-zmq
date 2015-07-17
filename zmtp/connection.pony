
use "net"
use "collections"

class _ClientConnection is TCPConnectionNotify // TODO: abstract away TCP types
  let _parent: Client tag
  let _socket_type: String val
  
  let _buffer: Buffer = Buffer
  var _protocol: Protocol = ProtocolNone
  
  new iso create(parent: Client, socket_type: String) =>
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
    _protocol.handle_input(conn, _buffer)
  
  ///
  // Private convenience methods
  
  fun ref _reset(peer: _ClientPeer ref) =>
    _protocol = ProtocolAuthNull.create(this, _socket_type)
    _protocol.handle_start(peer)
    _buffer.clear()
  
  ///
  // Callback methods from protocol
  
  fun ref write(peer: _ClientPeer ref, data: Array[U8] val) =>
    peer.write(data)
  
  fun protocol_error(peer: _ClientPeer ref, string: String) ? =>
    _parent._protocol_error(peer, string)
    peer.dispose()
    error
  
  fun handshake_complete(peer: _ClientPeer ref) =>
    _parent._connected(peer)
  
  fun received_message(peer: _ClientPeer ref, message: Message) =>
    _parent._received(peer, message)


class _ClientListenerConnection is TCPListenNotify
  let _parent: Client tag
  let _socket_type: String val
  
  new iso create(parent: Client, socket_type: String) =>
    _parent = parent
    _socket_type = socket_type
  
  fun ref connected(listen: TCPListener ref): TCPConnectionNotify iso^ =>
    _ClientConnection(_parent, _socket_type)
