
use "collections"
use "net"
use "../inspect"

interface _ClientPeerInterface
  be write(data: Bytes)
  be dispose()

interface _ClientBindInterface
  be dispose()

type _ClientPeer is _ClientPeerInterface tag
type _ClientBind is _ClientBindInterface tag

actor Client
  let _peers: List[_ClientPeer] = _peers.create()
  let _binds: List[_ClientBind] = _binds.create()
  let _socket_type: String
  
  new create(socket_type: String) =>
    _socket_type = socket_type
  
  be connect(host: String, port: String) =>
    _peers.push(TCPConnection(_ClientConnection(this, _socket_type), host, port))
  
  be bind(host: String, port: String) =>
    _binds.push(TCPListener(_ClientListenerConnection(this, _socket_type), host, port))
  
  be _connected(peer: _ClientPeer) =>
    Inspect.print("_connected.")
  
  be _disconnected(peer: _ClientPeer) =>
    Inspect.print("_disconnected.")
  
  be _protocol_error(peer: _ClientPeer, string: String) =>
    Inspect.print("_protocol_error: " + string)
  
  be _received(peer: _ClientPeer, message: Message) =>
    Inspect.print("_received:")
    for frame in message.values() do
      Inspect.print("  " + Inspect(frame))
    end
  
  be _bind_closed(bind': _ClientBind) =>
    for node in _binds.nodes() do
      try let other = node.apply()
        if other is bind' then
          other.dispose()
          node.remove()
        end
      end
    end
