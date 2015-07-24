
use "collections"
use "net"
use "./inspect"
use zmtp = "zmtp"

interface _SocketPeerInterface
  be write(data: Bytes)
  be dispose()

interface _SocketBindInterface
  be dispose()

type _SocketPeer is _SocketPeerInterface tag
type _SocketBind is _SocketBindInterface tag

actor Socket
  let _peers: Map[String, _SocketPeer] = _peers.create()
  let _binds: Map[String, _SocketBind] = _binds.create()
  let _socket_type: String
  
  new create(socket_type: String) =>
    _socket_type = socket_type
  
  fun box _make_peer(string: String): _SocketPeer? =>
    match _EndpointParser.from_uri(string)
    | let e: EndpointTCP => TCPConnection(_SocketConnection(this, _socket_type), "localhost", "8899")
    | let e: EndpointUnknown => error
    else
      Inspect.out("failed to parse connect endpoint: "+string)
      error
    end
  
  fun box _make_bind(string: String): _SocketBind? =>
    match _EndpointParser.from_uri(string)
    | let e: EndpointTCP => TCPListener(_SocketListenerConnection(this, _socket_type), "localhost", "8899")
    | let e: EndpointUnknown => error
    else
      Inspect.out("failed to parse bind endpoint: "+string)
      error
    end
  
  be connect(string: String) =>
    _peers(string) = try _make_peer(string) else return end
  
  be bind(string: String) =>
    _binds(string) = try _make_bind(string) else return end
  
  be _connected(peer: _SocketPeer) =>
    Inspect.print("_connected.")
  
  be _disconnected(peer: _SocketPeer) =>
    Inspect.print("_disconnected.")
  
  be _protocol_error(peer: _SocketPeer, string: String) =>
    Inspect.print("_protocol_error: " + string)
  
  be _received(peer: _SocketPeer, message: zmtp.Message) =>
    Inspect.print("_received:")
    for frame in message.values() do
      Inspect.print("  " + Inspect(frame))
    end
  
  be _bind_closed(bind': _SocketBind) =>
    for (key, other) in _binds.pairs() do
      if other is bind' then
        other.dispose()
        try _binds.remove(key) end
      end
    end
