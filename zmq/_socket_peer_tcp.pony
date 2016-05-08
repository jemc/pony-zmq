// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use "time"
use "net"

actor _SocketPeerTCP is (_SocketTCPNotifiable & _ZapResponseNotifiable)
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
    _session.start(where
      handle_activated      = this~_handle_activated(target),
      handle_protocol_error = this~_handle_protocol_error(),
      handle_write          = this~_handle_write(target),
      handle_received       = this~_handle_received(),
      handle_zap_request    = this~_handle_zap_request()
    )
  
  be notify_input(data: Array[U8] iso) =>
    _session.handle_input(consume data)
  
  be notify_closed() =>
    _active = false
    if not _disposed then _reconnect_later() end
  
  be notify_connect_failed() =>
    _active = false
    _reconnect_later()
  
  ///
  // _ZapResponseNotifiable interface behaviors
  
  be notify_zap_response(zap: _ZapResponse) =>
    _session.handle_zap_response(zap)
  
  ///
  // Session handler methods
  
  fun ref _handle_activated(target: _SocketTCPTarget, writex: _MessageWriteTransform) =>
    _inner = target
    _active = true
    _parent._connected(this)
    _messages.set_write_transform(consume writex)
    _messages.flush(target)
  
  fun ref _handle_protocol_error(string: String) =>
    _active = false
    _reconnect_later()
    _parent._protocol_error(this, string)
  
  fun ref _handle_write(target: _SocketTCPTarget, bytes: ByteSeq) =>
    target.write(bytes)
  
  fun ref _handle_received(message: Message) =>
    _parent._received(this, message)
  
  fun ref _handle_zap_request(zap: _ZapRequest) =>
    // TODO: Support external ZAP handler as socket option.
    notify_zap_response(_ZapResponse) // always just respond with 200 OK
