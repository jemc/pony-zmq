
use "time"
use "net"

actor _SocketPeerTCP is _SocketTCPNotifiable
  let _parent: Socket
  let _socket_type: SocketType
  let _socket_opts: SocketOptions val
  let _endpoint: EndpointTCP
  var _inner: (TCPConnection | None) = None
  
  var _active: Bool = false
  var _disposed: Bool = false
  
  let _messages: _MessageQueue = _MessageQueue
  
  var _reconnect_timer: (Timer tag | None) = None
  
  new create(parent: Socket, socket_type: SocketType,
    socket_opts: SocketOptions val, endpoint: EndpointTCP
  ) =>
    _parent = parent
    _socket_type = socket_type
    _socket_opts = socket_opts
    _endpoint = endpoint
    _inner = TCPConnection(_SocketTCPNotify(this, _socket_type, _socket_opts),
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
  
  be activated(conn: TCPConnection, writex: _MessageWriteTransform) =>
    _inner = conn
    _active = true
    _parent._connected(this)
    _messages.set_write_transform(consume writex)
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
    _inner = TCPConnection(_SocketTCPNotify(this, _socket_type, _socket_opts),
                           _endpoint.host, _endpoint.port)
  
  fun ref reconnect_later() =>
    try (_inner as TCPConnection).dispose() end
    _inner = None
    let ns = _reconnect_interval_ns()
    _parent.set_timer(Timer(_ReconnectTimerNotify(this), ns, ns))
  
  fun _reconnect_interval_ns(): U64 =>
    (ReconnectInterval.find_in(_socket_opts) * 1e9).u64()
  
  be _reconnect_timer_fire() =>
    if not _active and not _disposed then
      _inner = TCPConnection(_SocketTCPNotify(this, _socket_type, _socket_opts),
                             _endpoint.host, _endpoint.port)
    end
