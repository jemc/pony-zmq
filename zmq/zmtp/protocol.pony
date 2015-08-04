
use "net"

interface Protocol
  fun ref handle_start()
  fun ref handle_input(buffer: Buffer ref)

class ProtocolNone is Protocol
  fun ref handle_start() => None
  fun ref handle_input(buffer: Buffer ref) => None
