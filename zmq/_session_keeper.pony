
use net = "net"
use z85 = "z85"
use zmtp = "zmtp"
use "../../pony-sodium/sodium"

class _SessionKeeper
  let _session: zmtp.Session = zmtp.Session
  
  let _socket_type: SocketType
  let _socket_opts: SocketOptions val
  
  let _buffer: net.Buffer = net.Buffer
  
  new create(
    socket_type: SocketType,
    socket_opts: SocketOptions val
  ) =>
    _socket_type = socket_type
    _socket_opts = socket_opts
  
  fun ref start(
    handle_activated:      zmtp.SessionHandleActivated,
    handle_protocol_error: zmtp.SessionHandleProtocolError,
    handle_write:          zmtp.SessionHandleWrite,
    handle_received:       zmtp.SessionHandleReceived
  ) =>
    _buffer.clear()
    _session.start(where
      session_keeper = this,
      protocol = zmtp.ProtocolAuthNull.create(_session),
      handle_activated      = handle_activated,
      handle_protocol_error = handle_protocol_error,
      handle_write          = handle_write,
      handle_received       = handle_received
    )
  
  fun _make_curve_key(key: String): String? =>
    match key.size()
    | 40 => key
    | 32 => z85.Z85.decode(key)
    else error
    end
  
  fun ref _make_curve_protocol(): zmtp.Protocol? =>
    let curve_sk = CryptoBoxSecretKey(_make_curve_key(
                     CurveSecretKey.find_in(_socket_opts)))
    if CurveAsServer.find_in(_socket_opts) then
      return zmtp.ProtocolAuthCurveServer(_session, curve_sk)
    else
      let curve_pks = CryptoBoxPublicKey(_make_curve_key(
                        CurvePublicKeyOfServer.find_in(_socket_opts)))
      return zmtp.ProtocolAuthCurveClient(_session, curve_sk, curve_pks)
    end
  
  fun ref _make_protocol(): zmtp.Protocol =>
    try _make_curve_protocol()
    else zmtp.ProtocolAuthNull.create(_session)
    end
  
  fun ref handle_input(data: Array[U8] iso) =>
    _buffer.append(consume data)
    _session.handle_input(_buffer)
  
  ///
  // Convenience methods for the underlying session
  
  fun socket_type_string(): String =>
    _socket_type.string()
  
  fun socket_type_accepts(string: String): Bool =>
    _socket_type.accepts(string)