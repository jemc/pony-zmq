// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use "net"
use zmtp = "zmtp"

actor _SocketBindTCP
  var _inner: TCPListener
  new create(parent: Socket, socket_opts: SocketOptions val, endpoint: BindTCP) =>
    _inner = TCPListener(
      endpoint._get_auth(),
      _SocketBindTCPListenNotify(parent, socket_opts),
      endpoint._get_host(),
      endpoint._get_port())
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

actor _SocketPeerTCPBound is (_SocketTCPNotifiable & zmtp.SessionNotify)
  let _parent: Socket
  let _socket_opts: SocketOptions val
  var _inner: (_SocketTCPTarget | None) = None
  var _active: Bool
  let _messages: _MessageQueue = _MessageQueue
  let _session: _SessionKeeper
  
  new create(parent: Socket, socket_opts: SocketOptions val) =>
    _parent = parent
    _socket_opts = socket_opts
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
  // _SocketTCPNotifiable interface behaviors
  
  be notify_start(target: _SocketTCPTarget) =>
    _inner = target
    _session.start(this)
  
  be notify_input(data: Array[U8] iso) =>
    _session.handle_input(consume data)
  
  be notify_closed() =>
    dispose()
  
  be notify_connect_failed() =>
    dispose()
  
  ///
  // Zap support helper behaviours
  
  be notify_zap_response(zap: _ZapResponse) =>
    _session.handle_zap_response(zap)
  
  ///
  // Session handler methods
  
  fun ref activated(writex: _MessageWriteTransform) =>
    _active = true
    _parent._connected(this)
    _messages.set_write_transform(consume writex)
    try _messages.flush(_inner as _SocketTCPTarget) end
  
  fun ref protocol_error(string: String) =>
    dispose()
    _parent._protocol_error(this, string)
  
  fun ref write(bytes: ByteSeq) =>
    try (_inner as _SocketTCPTarget).write(bytes) end
  
  fun ref received(message: Message) =>
    _parent._received(this, message)
  
  fun ref zap_request(zap: _ZapRequest) =>
    let t: _SocketPeerTCPBound = this
    let respond: _ZapRespond =
      {(res: _ZapResponse) => t.notify_zap_response(res) } val
    
    let handler = ZapHandler.find_in(_socket_opts)
    try (handler as _ZapRequestNotifiable).handle_zap_request(zap, respond)
    else notify_zap_response(_ZapResponse) // no handler, so respond with 200 OK
    end
