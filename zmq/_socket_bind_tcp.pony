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
  
  fun ref connected(listen: TCPListener ref): TCPConnectionNotify iso^ =>
    _SocketTCPNotify(_SocketPeerTCPBound(_parent, _socket_opts))

actor _SocketPeerTCPBound is _SocketTCPNotifiable
  let _parent: Socket
  var _inner: (_SocketTCPTarget | None) = None
  var _active: Bool
  let _messages: _MessageQueue = _MessageQueue
  let _session: _SessionKeeper
  
  new create(parent: Socket, socket_opts: SocketOptions val) =>
    _parent = parent
    _inner = None
    _active = false
    _session = _SessionKeeper(socket_opts)
  
  be dispose() =>
    try (_inner as _SocketTCPTarget).dispose() end
    _inner = None
    _active = false
  
  be send(message: Message) =>
    _messages.send(message, _inner, _active)
  
  ///
  // _SocketTCPNotifiable private interface behaviors
  
  be _handle_start(target: _SocketTCPTarget) =>
    _session.start(where
      handle_activated      = this~_handle_activated(target),
      handle_protocol_error = this~_handle_protocol_error(),
      handle_write          = this~_handle_write(target),
      handle_received       = this~_handle_received()
    )
  
  be _handle_input(data: Array[U8] iso) =>
    _session.handle_input(consume data)
  
  be _closed() =>
    dispose()
  
  be _connect_failed() =>
    dispose()
  
  ///
  // Session handler methods
  
  fun ref _handle_activated(target: _SocketTCPTarget, writex: _MessageWriteTransform) =>
    _inner = target
    _active = true
    _parent._connected(this)
    _messages.set_write_transform(consume writex)
    _messages.flush(target)
  
  fun ref _handle_protocol_error(string: String) =>
    dispose()
    _parent._protocol_error(this, string)
  
  fun ref _handle_write(target: _SocketTCPTarget, bytes: Bytes) =>
    target.write(bytes)
  
  fun ref _handle_received(message: Message) =>
    _parent._received(this, message)
