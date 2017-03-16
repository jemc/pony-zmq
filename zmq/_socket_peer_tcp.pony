// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use "time"
use "net"
use zmtp = "zmtp"

actor _SocketPeerTCP is (_SocketTCPNotifiable & zmtp.SessionNotify)
  let _parent: Socket
  let _socket_opts: SocketOptions val
  let _endpoint: ConnectTCP
  var _inner: (_SocketTCPTarget | None) = None
  let _session: _SessionKeeper
  
  var _active: Bool = false
  var _disposed: Bool = false
  
  let _messages: _MessageQueue = _MessageQueue
  
  var _reconnect_timer: (Timer tag | None) = None
  
  new create(parent: Socket, socket_opts: SocketOptions val, endpoint: ConnectTCP) =>
    _parent = parent
    _socket_opts = socket_opts
    _endpoint = endpoint
    _inner = TCPConnection(
      _endpoint._get_auth(),
      _SocketTCPNotify(this),
      _endpoint._get_host(),
      _endpoint._get_port())
    _session = _SessionKeeper(socket_opts)
  
  be dispose() =>
    try (_inner as _SocketTCPTarget).dispose() end
    _inner = None
    _active = false
    _disposed = true
  
  be send(message: Message) =>
    _messages.send(message, _inner, _active)
  
  fun ref _reconnect_later() =>
    try (_inner as _SocketTCPTarget).dispose() end
    _inner = None
    let ns = _reconnect_interval_ns()
    _parent.set_timer(Timer(_ReconnectTimerNotify(this), ns, ns))
  
  fun _reconnect_interval_ns(): U64 =>
    (ReconnectInterval.find_in(_socket_opts) * 1e9).u64()
  
  be _reconnect_timer_fire() =>
    if not _active and not _disposed then
      _inner = TCPConnection(
        _endpoint._get_auth(),
        _SocketTCPNotify(this),
        _endpoint._get_host(),
        _endpoint._get_port())
    end
  
  ///
  // _SocketTCPNotifiable interface behaviors
  
  be notify_start(target: _SocketTCPTarget) =>
    _inner = target
    _session.start(this)
  
  be notify_input(data: Array[U8] iso) =>
    _session.handle_input(consume data)
  
  be notify_closed() =>
    _active = false
    if not _disposed then _reconnect_later() end
  
  be notify_connect_failed() =>
    _active = false
    _reconnect_later()
  
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
    _active = false
    _reconnect_later()
    _parent._protocol_error(this, string)
  
  fun ref write(bytes: ByteSeq) =>
    try (_inner as _SocketTCPTarget).write(bytes) end
  
  fun ref received(message: Message) =>
    _parent._received(this, message)
  
  fun ref zap_request(zap: _ZapRequest) =>
    let t: _SocketPeerTCP = this
    let respond: _ZapRespond =
      {(res: _ZapResponse) => t.notify_zap_response(res) } val
    
    let handler = ZapHandler.find_in(_socket_opts)
    try (handler as _ZapRequestNotifiable).handle_zap_request(zap, respond)
    else notify_zap_response(_ZapResponse) // no handler, so respond with 200 OK
    end
