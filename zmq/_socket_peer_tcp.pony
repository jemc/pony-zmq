
use "time"
use "net"

actor _SocketPeerTCP
  let _parent: Socket
  let _socket_type: SocketType
  let _endpoint: EndpointTCP
  var _inner: (TCPConnection | None) = None
  
  var _active: Bool = false
  var _disposed: Bool = false
  
  let _messages: _MessageQueue = _MessageQueue
  
  var _reconnect_timer: (Timer tag | None) = None
  let _reconnect_ivl: U64 = 500000000 // 500 ms
  
  new create(parent: Socket, socket_type: SocketType, endpoint: EndpointTCP) =>
    _parent = parent
    _socket_type = socket_type
    _endpoint = endpoint
    _inner = TCPConnection(_SocketTCPNotify(this, _socket_type),
                           _endpoint.host, _endpoint.port)
  
  be dispose() =>
    try (_inner as TCPConnection).dispose() end
    _inner = None
    _active = false
    _disposed = true
  
  be protocol_error(string: String) =>
    _active = false
    reconnect_later()
    _parent._protocol_error(this, string)
  
  be activated(conn: TCPConnection) =>
    _inner = conn
    _active = true
    _parent._connected(this)
    _messages.flush(conn)
  
  be closed() =>
    _active = false
    if not _disposed then reconnect_now() end
  
  be connect_failed() =>
    _active = false
    reconnect_later()
  
  be received(message: Message) =>
    _parent._received(this, message)
  
  be send(message: Message) =>
    _messages.send(message, _inner, _active)
  
  fun ref reconnect_now() =>
    try (_inner as TCPConnection).dispose() end
    _inner = TCPConnection(_SocketTCPNotify(this, _socket_type),
                           _endpoint.host, _endpoint.port)
  
  fun ref reconnect_later() =>
    try (_inner as TCPConnection).dispose() end
    _inner = None
    _parent.set_timer(
      Timer(_ReconnectTimerNotify(this), _reconnect_ivl, _reconnect_ivl))
  
  be _reconnect_timer_fire() =>
    if not _active and not _disposed then
      _inner = TCPConnection(_SocketTCPNotify(this, _socket_type),
                             _endpoint.host, _endpoint.port)
    end
