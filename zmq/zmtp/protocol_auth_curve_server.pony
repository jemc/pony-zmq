
use "../../../pony-sodium/sodium"

primitive _ProtocolAuthCurveServerStateReadGreeting
primitive _ProtocolAuthCurveServerStateReadHandshakeHello
primitive _ProtocolAuthCurveServerStateReadHandshakeInitiate
primitive _ProtocolAuthCurveServerStateReadMessage

type _ProtocolAuthCurveServerState is
  ( _ProtocolAuthCurveServerStateReadGreeting
  | _ProtocolAuthCurveServerStateReadHandshakeHello
  | _ProtocolAuthCurveServerStateReadHandshakeInitiate
  | _ProtocolAuthCurveServerStateReadMessage)

class ProtocolAuthCurveServer is Protocol
  let _session: Session
  let _pk: CryptoBoxPublicKey
  let _sk: CryptoBoxSecretKey
  var _state: _ProtocolAuthCurveServerState = _ProtocolAuthCurveServerStateReadGreeting
  
  new create(session: Session, pk: CryptoBoxPublicKey, sk: CryptoBoxSecretKey) =>
    _session = session
    _pk = pk
    _sk = sk
  
  fun ref _next_state(state: _ProtocolAuthCurveServerState) =>
    _state = state
  
  fun ref handle_start() => None
  fun ref handle_input(buffer: _Buffer ref) => None
