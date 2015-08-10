
use "../../../pony-sodium/sodium"

class ProtocolAuthCurveClient is Protocol
  let _session: Session
  let _sk: CryptoBoxSecretKey
  let _pks: CryptoBoxPublicKey
  
  new create(session: Session, sk: CryptoBoxSecretKey, pks: CryptoBoxPublicKey) =>
    _session = session
    _sk = sk
    _pks = pks
  
  fun ref handle_start() => None
  fun ref handle_input(buffer: _Buffer ref) => None
