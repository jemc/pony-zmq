
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
  let _peers: List[_SocketPeer] = _peers.create()
  let _binds: List[_SocketBind] = _binds.create()
  let _socket_type: String
  
  new create(socket_type: String) =>
    _socket_type = socket_type
  
  be connect(host: String, port: String) =>
    _peers.push(TCPConnection(_SocketConnection(this, _socket_type), host, port))
  
  be bind(host: String, port: String) =>
    _binds.push(TCPListener(_SocketListenerConnection(this, _socket_type), host, port))
  
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
    for node in _binds.nodes() do
      try let other = node.apply()
        if other is bind' then
          other.dispose()
          node.remove()
        end
      end
    end
