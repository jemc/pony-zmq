// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use "net"
use zmtp = "zmtp"

interface tag _SocketTCPTarget is _MessageQueueWritable
  be dispose()

interface tag _SocketTCPNotifiable
  be notify_start(target: _SocketTCPTarget)
  be notify_input(data: Array[U8] iso)
  be notify_closed()
  be notify_connect_failed()

class _SocketTCPNotify is TCPConnectionNotify
  let _parent: _SocketTCPNotifiable
  
  new iso create(parent: _SocketTCPNotifiable) =>
    _parent = parent
  
  fun ref accepted(conn: TCPConnection ref) =>
    _parent.notify_start(conn)
  
  fun ref connected(conn: TCPConnection ref) =>
    _parent.notify_start(conn)
  
  fun ref connect_failed(conn: TCPConnection ref) =>
    _parent.notify_connect_failed()
  
  fun ref closed(conn: TCPConnection ref) =>
    _parent.notify_closed()
  
  fun ref received(conn: TCPConnection ref, data: Array[U8] iso,
    times: USize): Bool
  =>
    _parent.notify_input(consume data)
    true
