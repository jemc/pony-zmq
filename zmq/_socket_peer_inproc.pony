// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

actor _SocketPeerInProc
  let _parent: Socket
  let _socket_opts: SocketOptions val
  
  var _peer: (_SocketPeerInProcBound | None) = None
  var _active: Bool = false
  
  let _messages: _MessageQueueSimple = _MessageQueueSimple
  
  new create(parent: Socket, socket_opts: SocketOptions val, endpoint: EndpointInProc)
  =>
    _parent = parent
    _socket_opts = socket_opts
    let context = _ContextAsSocketOption.find_in(socket_opts)
    context._inproc_connect(endpoint.path, this)
  
  be dispose() =>
    _active = false
  
  be activated(peer: _SocketPeerInProcBound) =>
    _peer = peer
    _active = true
    _parent._connected(this)
    _messages.flush(peer)
  
  be received(message: Message) =>
    _parent._received(this, message)
  
  be send(message: Message) =>
    _messages.send(message, _peer, _active)
