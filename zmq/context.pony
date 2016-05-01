// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use "collections"

actor Context
  let _inproc_router: _ContextInProcRouter = _ContextInProcRouter
  
  fun tag socket(socket_type: SocketType, notify: SocketNotify = SocketNotifyNone): Socket =>
    Socket._create_in(this, socket_type, notify)
  
  be _zap_request(receiver: _ZapResponseNotifiable, zap: _ZapRequest) =>
    if _inproc_router._has_bind("zeromq.zap.01") then
      let s = Socket._create_in(this, REQ, _ContextZapResponseNotify(receiver))
      s.send(zap.as_message())
    else // no ZAP handler is bound, just return 200 OK
      receiver.notify_zap_response(_ZapResponse)
    end
  
  be _inproc_bind(string: String, bind: _SocketBindInProc) =>
    _inproc_router._bind(string, bind)
  
  be _inproc_connect(string: String, peer: _SocketPeerInProc) =>
    _inproc_router._connect(string, peer)

class _ContextInProcRouter
  let _ready_binds: Map[String, _SocketBindInProc]       = _ready_binds.create()
  let _ready_peers: Map[String, List[_SocketPeerInProc]] = _ready_peers.create()
  
  fun _has_bind(string: String): Bool =>
    try _ready_binds(string); true else false end
  
  fun ref _bind(string: String, bind: _SocketBindInProc) =>
    // If there is not already a bind for this string
    if not _ready_binds.contains(string) then
      // Set this bind as the bind for this string
      _ready_binds(string) = bind
      
      // Connect peers that are already waiting for a bind
      try let peers = _ready_peers(string)
        for peer in peers.values() do
          bind.accept_connection(peer)
        end
      end
    end
  
  fun ref _connect(string: String, peer: _SocketPeerInProc) =>
    // Add this peer to peer list for this string
    let peer_list = try _ready_peers(string) else
                      let list = List[_SocketPeerInProc]
                      _ready_peers(string) = list
                      list
                    end
    peer_list.push(peer)
    
    // Connect to a bind if there is one available
    try _ready_binds(string).accept_connection(peer) end

class val _ContextZapResponseNotify is SocketNotify
  let _parent: _ZapResponseNotifiable
  new val create(parent: _ZapResponseNotifiable) => _parent = parent
  
  fun val received(s: Socket, p: SocketPeer, m: Message) =>
    _parent.notify_zap_response(try
      _ZapResponse.from_message(m)
    else
      _ZapResponse.server_error("Incorrectly formatted ZAP response message")
    end)
