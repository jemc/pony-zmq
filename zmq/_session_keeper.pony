// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use net = "net"
use z85 = "z85"
use zmtp = "zmtp"
use "sodium"

class _SessionKeeper
  let _socket_opts: SocketOptions val
  
  let _session: zmtp.Session = zmtp.Session
  let _buffer: net.Buffer = net.Buffer
  
  new create(socket_opts: SocketOptions val) =>
    _socket_opts = socket_opts
  
  fun ref start(notify': zmtp.SessionNotify) =>
    _buffer.clear()
    _session.start(this, notify', _make_mechanism())
  
  fun _make_curve_key(key: String): String? =>
    match key.size()
    | 40 => z85.Z85.decode(key)
    | 32 => key
    else error
    end
  
  fun ref _make_curve_mechanism(): zmtp.Mechanism? =>
    let pk = CryptoBoxPublicKey(_make_curve_key(
               CurvePublicKey.find_in(_socket_opts)))
    let sk = CryptoBoxSecretKey(_make_curve_key(
               CurveSecretKey.find_in(_socket_opts)))
    if CurveAsServer.find_in(_socket_opts) then
      return zmtp.MechanismAuthCurveServer(_session, sk, pk)
    else
      let pks = CryptoBoxPublicKey(_make_curve_key(
                  CurvePublicKeyOfServer.find_in(_socket_opts)))
      return zmtp.MechanismAuthCurveClient(_session, sk, pk, pks)
    end
  
  fun ref _make_mechanism(): zmtp.Mechanism =>
    try _make_curve_mechanism()
    else zmtp.MechanismAuthNull.create(_session)
    end
  
  fun ref handle_input(data: Array[U8] iso) =>
    _buffer.append(consume data)
    _session.handle_input(_buffer)
  
  fun ref handle_zap_response(zap: _ZapResponse) =>
    _session.handle_zap_response(zap)
  
  fun _socket_type(): SocketType =>
    _SocketTypeAsSocketOption.find_in(_socket_opts)
  
  ///
  // Convenience methods for the underlying session
  
  fun as_server(): Bool =>
    CurveAsServer.find_in(_socket_opts)
  
  fun auth_mechanism(): String =>
    try _make_curve_key(CurveSecretKey.find_in(_socket_opts))
        _make_curve_key(CurvePublicKey.find_in(_socket_opts))
      "CURVE"
    else
      "NULL"
    end
  
  fun socket_type_string(): String =>
    _socket_type().string()
  
  fun socket_type_accepts(string: String): Bool =>
    _socket_type().accepts(string)
