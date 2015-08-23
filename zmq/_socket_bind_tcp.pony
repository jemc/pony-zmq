// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use "net"

actor _SocketBindTCP
  var _inner: TCPListener
  new create(parent: Socket, socket_opts: SocketOptions val, endpoint: EndpointTCP) =>
    _inner = TCPListener(_SocketBindTCPListenNotify(parent, socket_opts),
                         endpoint.host, endpoint.port)
  be dispose() =>
    _inner.dispose()

class _SocketBindTCPListenNotify is TCPListenNotify
  let _parent: Socket
  let _socket_opts: SocketOptions val
  
  new iso create(parent: Socket, socket_opts: SocketOptions val) =>
    _parent = parent
    _socket_opts = socket_opts
    
  fun ref listening(listen: TCPListener ref) =>
    None // TODO: pass along to Socket
  
  fun ref not_listening(listen: TCPListener ref) =>
    None // TODO: pass along to Socket
  
  fun ref closed(listen: TCPListener ref) =>
    None // TODO: pass along to Socket
  
  fun ref connected(listen: TCPListener ref): TCPConnectionNotify iso^ =>
    _SocketTCPNotify(_SocketPeerTCPBound(_parent), _socket_opts)

actor _SocketPeerTCPBound is _SocketTCPNotifiable
  let _parent: Socket
  var _inner: (_SocketTCPTarget | None) = None
  var _active: Bool
  let _messages: _MessageQueue = _MessageQueue
  
  new create(parent: Socket) =>
    _parent = parent
    _inner = None
    _active = false
  
  be dispose() =>
    try (_inner as _SocketTCPTarget).dispose() end
    _inner = None
    _active = false
  
  be protocol_error(string: String) =>
    dispose()
    _parent._protocol_error(this, string)
  
  be activated(conn: _SocketTCPTarget, writex: _MessageWriteTransform) =>
    _inner = conn
    _active = true
    _parent._connected(this)
    _messages.set_write_transform(consume writex)
    _messages.flush(conn)
  
  be closed() =>
    dispose()
  
  be connect_failed() =>
    dispose()
  
  be received(message: Message) =>
    _parent._received(this, message)
  
  be send(message: Message) =>
    _messages.send(message, _inner, _active)
