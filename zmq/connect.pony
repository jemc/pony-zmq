// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use "collections"
use "net"

trait val Connect is (Equatable[Connect] & Hashable)

class val ConnectInProc is Connect
  let _ctx: Context
  let _path: String
  
  new val create(ctx': Context, path': String) =>
    _ctx = ctx'; _path = path'
  
  fun _get_ctx(): Context => _ctx
  fun _get_path(): String => _path
  
  fun hash(): U64 => (identityof _ctx).hash() xor _path.hash()
  fun eq(that': Connect): Bool =>
    match that' | let that: ConnectInProc =>
      (_ctx is that._ctx) and (_path == that._path)
    else false
    end

type _ConnectTCPAuth is (AmbientAuth | NetAuth | TCPAuth | TCPConnectAuth)
class val ConnectTCP is Connect
  let _auth: _ConnectTCPAuth
  let _host: String
  let _port: String
  
  new val create(auth': _ConnectTCPAuth, host': String, port': String) =>
    _auth = auth'; _host = host'; _port = port'
  
  fun _get_auth(): _ConnectTCPAuth => _auth
  fun _get_host(): String          => _host
  fun _get_port(): String          => _port
  
  fun hash(): U64 => _host.hash() xor _port.hash()
  fun eq(that': Connect): Bool =>
    match that' | let that: ConnectTCP =>
      (_host == that._host) and (_port == that._port)
    else false
    end
