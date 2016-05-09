// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use "collections"
use "net"

trait val Bind is (Equatable[Bind] & Hashable)

class val BindInProc is Bind
  let _ctx: Context
  let _path: String
  
  new val create(ctx': Context, path': String) =>
    _ctx = ctx'; _path = path'
  
  fun _get_ctx(): Context => _ctx
  fun _get_path(): String => _path
  
  fun hash(): U64 => (digestof _ctx).hash() xor _path.hash()
  fun eq(that': Bind): Bool =>
    match that' | let that: BindInProc =>
      (_ctx is that._ctx) and (_path == that._path)
    else false
    end

type _BindTCPAuth is (AmbientAuth | NetAuth | TCPAuth | TCPListenAuth)
class val BindTCP is Bind
  let _auth: _BindTCPAuth
  let _host: String
  let _port: String
  
  new val create(auth': _BindTCPAuth, host': String, port': String) =>
    _auth = auth'; _host = host'; _port = port'
  
  fun _get_auth(): _BindTCPAuth => _auth
  fun _get_host(): String       => _host
  fun _get_port(): String       => _port
  
  fun hash(): U64 => _host.hash() xor _port.hash()
  fun eq(that': Bind): Bool =>
    match that' | let that: BindTCP =>
      (_host == that._host) and (_port == that._port)
    else false
    end
