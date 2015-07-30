
use "collections"
use "time"
use "net"
use "./inspect"

interface _SocketPeer tag
  be send(message: Message)
  be dispose()

interface _SocketBind tag
  be dispose()

actor Socket
  let _notify: SocketNotify ref
  
  let _peers:      Map[String, _SocketPeer]              = _peers.create()
  let _binds:      Map[String, _SocketBind]              = _binds.create()
  let _bind_peers: MapIs[_SocketBind, List[_SocketPeer]] = _bind_peers.create()
  let _open_peers: List[_SocketPeer]                     = _open_peers.create()
  
  let _timers:   Timers        = _timers.create()
  let _outgoing: List[Message] = _outgoing.create()
  
  let _socket_type: String
  
  new create(socket_type: String, notify: SocketNotify = SocketNotifyNone) =>
    _socket_type = socket_type
    _notify = consume notify
  
  be dispose() =>
    _timers.dispose()
    for peer in _peers.values() do
      peer.dispose()
    end
    for peer in _binds.values() do
      peer.dispose()
    end
    for peers in _bind_peers.values() do
      for peer in peers.values() do
        peer.dispose()
      end
    end
    _notify.closed(this)
  
  fun box _make_peer(string: String): _SocketPeer? =>
    match EndpointParser.from_uri(string)
    | let e: EndpointTCP => _SocketPeerTCP(this, _socket_type, e)
    | let e: EndpointUnknown => error
    else
      Inspect.out("failed to parse connect endpoint: "+string)
      error
    end
  
  fun box _make_bind(string: String): _SocketBind? =>
    match EndpointParser.from_uri(string)
    | let e: EndpointTCP => _SocketBindTCP(this, _socket_type, e)
    | let e: EndpointUnknown => error
    else
      Inspect.out("failed to parse bind endpoint: "+string)
      error
    end
  
  be connect(string: String) =>
    try _peers(string) else
      _peers(string) = try _make_peer(string) else return end
    end
  
  be bind(string: String) =>
    try _binds(string) else
      _binds(string) = try _make_bind(string) else return end
    end
  
  be send_string(string: String) =>
    _outgoing.push(recover Message.push(string) end)
    _maybe_send_messages()
  
  be set_timer(timer: Timer iso) =>
    _timers(consume timer)
  
  be _protocol_error(peer: _SocketPeer, string: String) =>
    Inspect.print("_protocol_error: " + string)
  
  be _connected(peer: _SocketPeer) =>
    _add_open_peer(peer)
    _maybe_send_messages()
  
  be _received(peer: _SocketPeer, message: Message) =>
    _notify.received(this, consume message)
  
  be _connected_from_bind(bind': _SocketBind, peer: _SocketPeer) =>
    (try _bind_peers(bind') else
      let list = List[_SocketPeer]
      _bind_peers(bind') = list
      list
    end).push(peer)
    _add_open_peer(peer)
  
  be _bind_closed(bind': _SocketBind) =>
    for (key, other) in _binds.pairs() do
      if other is bind' then
        try _binds.remove(key) end
      end
    end
    try
      for peer in _bind_peers(bind').values() do
        _lost_open_peer(peer)
      end
    end
    bind'.dispose()
  
  fun ref _maybe_send_messages() =>
    """
    If and while messages and peers are available (non-erroring), send them.
    """
    try while true do
      let peer = _choose_next_peer()
      peer.send(_outgoing.shift())
    end end
  
  fun ref _choose_next_peer(): _SocketPeer? =>
    _open_peers(0)
  
  fun ref _add_open_peer(peer: _SocketPeer) =>
    _open_peers.push(peer)
  
  fun ref _lost_open_peer(peer: _SocketPeer) =>
    for node in _open_peers.nodes() do
      try
        if node() is peer then
          node.remove()
          return
        end
      end
    end
    peer.dispose()
