
use "../../../pony-sodium/sodium"

class ProtocolAuthCurveServer is Protocol
  let _session: Session
  let _sk: CryptoBoxSecretKey
  
  new create(session: Session, sk: CryptoBoxSecretKey) =>
    _session = session
    _sk = sk
  
  fun ref handle_start() => None
  fun ref handle_input(buffer: _Buffer ref) => None
