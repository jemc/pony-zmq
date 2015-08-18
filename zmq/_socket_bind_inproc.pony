// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

actor _SocketBindInProc
  let _parent: Socket
  let _socket_opts: SocketOptions val
  
  new create(parent: Socket, socket_opts: SocketOptions val,
    endpoint: EndpointInProc, context: Context)
  =>
    _parent = parent
    _socket_opts = socket_opts
    context._inproc_bind(endpoint.path, this)
  
  be accept_connection(peer: _SocketPeerInProc) =>
    let peer' = _SocketPeerInProcBound(_parent, _socket_opts)
    peer'.activated(peer)
    peer.activated(peer')
  
  be dispose() =>
    None

actor _SocketPeerInProcBound
  let _parent: Socket
  let _socket_opts: SocketOptions val
  
  var _peer: (_SocketPeerInProc | None) = None
  var _active: Bool = false
  
  let _messages: _MessageQueueSimple = _MessageQueueSimple
  
  new create(parent: Socket, socket_opts: SocketOptions val)
  =>
    _parent = parent
    _socket_opts = socket_opts
  
  be dispose() =>
    _active = false
  
  be activated(peer: _SocketPeerInProc) =>
    _peer = peer
    _active = true
    _parent._connected(this)
    _messages.flush(peer)
  
  be received(message: Message) =>
    _parent._received(this, message)
  
  be send(message: Message) =>
    _messages.send(message, _peer, _active)
