
use "net"
// use "./inspect"

actor _SocketBindTCP
  var _inner: TCPListener
  new create(parent: Socket, socket_type: SocketType, endpoint: EndpointTCP) =>
    _inner = TCPListener(_SocketBindTCPListenNotify(parent, socket_type),
                         endpoint.host, endpoint.port)
  be dispose() =>
    _inner.dispose()

class _SocketBindTCPListenNotify is TCPListenNotify
  let _parent: Socket
  let _socket_type: SocketType
  
  new iso create(parent: Socket, socket_type: SocketType) =>
    _parent = parent
    _socket_type = socket_type
    
  fun ref listening(listen: TCPListener ref) =>
    // Inspect.print("_SocketBindTCPListenNotify.listening")
    None // TODO: pass along to Socket
  
  fun ref not_listening(listen: TCPListener ref) =>
    // Inspect.print("_SocketBindTCPListenNotify.not_listening")
    None // TODO: pass along to Socket
  
  fun ref closed(listen: TCPListener ref) =>
    // Inspect.print("_SocketBindTCPListenNotify.closed")
    None // TODO: pass along to Socket
  
  fun ref connected(listen: TCPListener ref): TCPConnectionNotify iso^ =>
    // Inspect.print("_SocketBindTCPListenNotify.connected")
    _SocketTCPNotify(_SocketPeerTCPBound(_parent, listen), _socket_type)

actor _SocketPeerTCPBound is _SocketTCPNotifiable
  let _parent: Socket
  let _bind: TCPListener
  var _inner: (TCPConnection | None) = None
  var _active: Bool
  let _messages: _MessageQueue = _MessageQueue
  
  new create(parent: Socket, bind: TCPListener) =>
    _parent = parent
    _bind = bind
    _inner = None
    _active = false
  
  be dispose() =>
    try (_inner as TCPConnection).dispose() end
    _inner = None
    _active = false
  
  be protocol_error(string: String) =>
    dispose()
    _parent._protocol_error(this, string)
  
  be activated(conn: TCPConnection) =>
    _inner = conn
    _active = true
    _parent._connected(this)
    _messages.flush(conn)
  
  be closed() =>
    dispose()
  
  be connect_failed() =>
    dispose()
  
  be received(message: Message) =>
    _parent._received(this, message)
  
  be send(message: Message) =>
    _messages.send(message, _inner, _active)
