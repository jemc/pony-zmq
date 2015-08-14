
use "../../../pony-sodium/sodium"

primitive _ProtocolAuthCurveClientStateReadGreeting
primitive _ProtocolAuthCurveClientStateReadHandshakeWelcome
primitive _ProtocolAuthCurveClientStateReadHandshakeReady
primitive _ProtocolAuthCurveClientStateReadMessage

type _ProtocolAuthCurveClientState is
  ( _ProtocolAuthCurveClientStateReadGreeting
  | _ProtocolAuthCurveClientStateReadHandshakeWelcome
  | _ProtocolAuthCurveClientStateReadHandshakeReady
  | _ProtocolAuthCurveClientStateReadMessage)

class ProtocolAuthCurveClient is Protocol
  let _session: Session
  let _pk: CryptoBoxPublicKey
  let _sk: CryptoBoxSecretKey
  let _pks: CryptoBoxPublicKey
  var _state: _ProtocolAuthCurveClientState = _ProtocolAuthCurveClientStateReadGreeting
  
  new create(session: Session, pk: CryptoBoxPublicKey, sk: CryptoBoxSecretKey, pks: CryptoBoxPublicKey) =>
    _session = session
    _pk = pk
    _sk = sk
    _pks = pks
  
  fun ref _next_state(state: _ProtocolAuthCurveClientState) =>
    _state = state
  
  fun ref handle_start() => None
  fun ref handle_input(buffer: _Buffer ref) => None
