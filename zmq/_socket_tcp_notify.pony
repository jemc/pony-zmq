// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use "net"
use zmtp = "zmtp"

interface _SocketTCPTarget tag is _MessageQueueWritable
  be dispose()

interface _SocketTCPNotifiable tag
  be protocol_error(string: String)
  be activated(target: _SocketTCPTarget, writex: _MessageWriteTransform)
  be closed()
  be connect_failed()
  be received(message: zmtp.Message)
  // be _handle_start()

class _SocketTCPNotify is TCPConnectionNotify
  let _parent: _SocketTCPNotifiable
  let _session: _SessionKeeper
  
  new iso create(parent: _SocketTCPNotifiable, socket_opts: SocketOptions val) =>
    _parent = parent
    _session = _SessionKeeper(socket_opts)
  
  ///
  // TCPConnectionNotify methods
  
  fun ref accepted(conn: TCPConnection ref) =>
    _start(conn)
  
  fun ref connected(conn: TCPConnection ref) =>
    _start(conn)
  
  fun ref connect_failed(conn: TCPConnection ref) =>
    _parent.connect_failed()
  
  fun ref closed(conn: TCPConnection ref) =>
    _parent.closed()
  
  fun ref received(conn: TCPConnection ref, data: Array[U8] iso) =>
    _session.handle_input(consume data)
  
  ///
  // Private convenience methods
  
  fun ref _start(target: _SocketTCPTarget) =>
    _session.start(where
      handle_activated      = this~_handle_activated(target),
      handle_protocol_error = this~_handle_protocol_error(target),
      handle_write          = this~_handle_write(target),
      handle_received       = this~_handle_received(target)
    )
  
  ///
  // Session handler methods
  
  fun ref _handle_activated(target: _SocketTCPTarget, writex: _MessageWriteTransform) =>
    _parent.activated(target, consume writex)
  
  fun ref _handle_protocol_error(target: _SocketTCPTarget, string: String) =>
    _parent.protocol_error(string)
  
  fun ref _handle_write(target: _SocketTCPTarget, bytes: Bytes) =>
    target.write(bytes)
  
  fun ref _handle_received(target: _SocketTCPTarget, message: Message) =>
    _parent.received(message)
