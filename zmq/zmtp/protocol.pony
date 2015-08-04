
interface Protocol
  fun ref handle_start()
  fun ref handle_input(buffer: _Buffer ref)

class ProtocolNone is Protocol
  fun ref handle_start() => None
  fun ref handle_input(buffer: _Buffer ref) => None
