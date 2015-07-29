
use "time"
use "net"

actor _SocketPeerTCP
  let _parent: Socket
  let _socket_type: String
  let _endpoint: EndpointTCP
  var _inner: (TCPConnection | None) = None
  var _active: Bool
  let _messages: _MessageQueue = _MessageQueue
  
  var _reconnect_timer: (Timer tag | None) = None
  let _reconnect_ivl: U64 = 500000000 // 500 ms
  
  new create(parent: Socket, socket_type: String, endpoint: EndpointTCP) =>
    _parent = parent
    _socket_type = socket_type
    _endpoint = endpoint
    _active = false
    _inner = TCPConnection(_SocketTCPNotify(this, _socket_type),
                           _endpoint.host, _endpoint.port)
  
  be dispose() =>
    try (_inner as TCPConnection).dispose() end
    _inner = None
    _active = false
  
  be protocol_error(string: String) =>
    reconnect_later()
    _parent._protocol_error(this, string)
  
  be activated(conn: TCPConnection) =>
    _inner = conn
    _active = true
    _parent._connected(this)
    _messages.flush(conn)
  
  be closed() =>
    reconnect_now()
  
  be connect_failed() =>
    reconnect_later()
  
  be received(message: Message) =>
    _parent._received(this, message)
  
  be send(message: Message) =>
    _messages.send(message, _inner, _active)
  
  fun ref reconnect_now() =>
    _active = false
    try (_inner as TCPConnection).dispose() end
    _inner = TCPConnection(_SocketTCPNotify(this, _socket_type),
                           _endpoint.host, _endpoint.port)
  
  fun ref reconnect_later() =>
    _active = false
    try (_inner as TCPConnection).dispose() end
    _inner = None
    _parent.set_timer(
      Timer(_ReconnectTimerNotify(this), _reconnect_ivl, _reconnect_ivl))
  
  be _reconnect_timer_fire() =>
    if not _active then
      _inner = TCPConnection(_SocketTCPNotify(this, _socket_type),
                             _endpoint.host, _endpoint.port)
    end
