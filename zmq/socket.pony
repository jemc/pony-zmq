// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use "collections"
use "time"
use "inspect"

interface tag SocketPeer // public, limited
  be send(message: Message)

interface tag _SocketPeer
  be send(message: Message)
  be dispose()

interface tag _SocketBind
  be dispose()

interface iso SocketAccessLambda
  fun iso apply(socket: Socket ref)

actor Socket
  let _notify: SocketNotify ref
  
  let _peers:      Map[String, _SocketPeer]              = _peers.create()
  let _binds:      Map[String, _SocketBind]              = _binds.create()
  let _bind_peers: MapIs[_SocketBind, List[_SocketPeer]] = _bind_peers.create()
  
  let _timers:   Timers        = _timers.create()
  let _outgoing: List[Message] = _outgoing.create()
  
  let _socket_opts: SocketOptions = _socket_opts.create()
  
  let _handle_in:  _HandleIncoming
  let _handle_out: _HandleOutgoing
  let _observe_in:  _ObserveIncoming
  let _observe_out: _ObserveOutgoing
  
  new create(socket_type: SocketType, notify: SocketNotify = SocketNotifyNone) =>
    _notify = consume notify
    _handle_in = socket_type.handle_incoming()
    _handle_out = socket_type.handle_outgoing()
    _observe_in = socket_type.observe_incoming()
    _observe_out = socket_type.observe_outgoing()
    _SocketOptionsUtil.set_in(_SocketTypeAsSocketOption(socket_type), _socket_opts)
  
  new _create_in(context: Context, socket_type: SocketType, notify: SocketNotify) =>
    _notify = consume notify
    _handle_in = socket_type.handle_incoming()
    _handle_out = socket_type.handle_outgoing()
    _observe_in = socket_type.observe_incoming()
    _observe_out = socket_type.observe_outgoing()
    _SocketOptionsUtil.set_in(_ContextAsSocketOption(context), _socket_opts)
    _SocketOptionsUtil.set_in(_SocketTypeAsSocketOption(socket_type), _socket_opts)
  
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
  
  fun _socket_opts_clone(): SocketOptions iso^ =>
    let clone = recover iso SocketOptions end
    for v in _socket_opts.values() do
      clone.push(v)
    end
    clone
  
  fun _make_peer(string: String): _SocketPeer? =>
    match EndpointParser.from_uri(string)
    | let e: EndpointTCP => _SocketPeerTCP(this, _socket_opts_clone(), e)
    | let e: EndpointInProc => _SocketPeerInProc(this, _socket_opts_clone(), e)
    | let e: EndpointUnknown => error
    else
      Inspect.out("failed to parse connect endpoint: "+string)
      error
    end
  
  fun _make_bind(string: String): _SocketBind? =>
    match EndpointParser.from_uri(string)
    | let e: EndpointTCP => _SocketBindTCP(this, _socket_opts_clone(), e)
    | let e: EndpointInProc => _SocketBindInProc(this, _socket_opts_clone(), e)
    | let e: EndpointUnknown => error
    else
      Inspect.out("failed to parse bind endpoint: "+string)
      error
    end
  
  be access(f: SocketAccessLambda) =>
    (consume f)(this)
  
  be set(optval: SocketOptionWithValue) => set_now(optval)
  fun ref set_now(optval: SocketOptionWithValue) =>
    _SocketOptionsUtil.set_in(optval, _socket_opts)
  
  be connect(string: String) => connect_now(string)
  fun ref connect_now(string: String) =>
    try _peers(string) else
      let peer = try _make_peer(string) else return end
      _peers(string) = peer
      _new_peer(peer)
    end
  
  be bind(string: String) => bind_now(string)
  fun ref bind_now(string: String) =>
    try _binds(string) else
      _binds(string) = try _make_bind(string) else return end
    end
  
  be send(message: Message) => send_now(message)
  fun ref send_now(message: Message) =>
    _outgoing.push(message)
    _maybe_send_messages()
  
  be set_timer(timer: Timer iso) =>
    _timers(consume timer)
  
  be _protocol_error(peer: _SocketPeer, string: String) =>
    Inspect.print("_protocol_error: " + string)
  
  be _connected(peer: _SocketPeer) =>
    _new_peer(peer)
    _maybe_send_messages()
  
  be _received(peer: _SocketPeer, message: Message) =>
    try _handle_in(peer, message)
      _notify.received(this, peer, consume message)
    end
  
  be _connected_from_bind(bind': _SocketBind, peer: _SocketPeer) =>
    (try _bind_peers(bind') else
      let list = List[_SocketPeer]
      _bind_peers(bind') = list
      list
    end).push(peer)
    _new_peer(peer)
  
  be _bind_closed(bind': _SocketBind) =>
    for (key, other) in _binds.pairs() do
      if other is bind' then
        try _binds.remove(key) end
      end
    end
    try
      for peer in _bind_peers(bind').values() do
        _lost_peer(peer)
      end
    end
    bind'.dispose()
  
  fun ref _maybe_send_messages() =>
    try while true do
      let m = _outgoing.shift()
      try _handle_out(m)
      else _outgoing.unshift(m)
        error
      end
    end end
  
  fun ref _new_peer(peer: _SocketPeer) =>
    _handle_in.new_peer(peer)
    _handle_out.new_peer(peer)
    _notify.new_peer(this, peer)
  
  fun ref _lost_peer(peer: _SocketPeer) =>
    _handle_in.lost_peer(peer)
    _handle_out.lost_peer(peer)
    _notify.lost_peer(this, peer)
    peer.dispose()
