
use "net"
use "collections"

interface Protocol
  fun ref handle_start(peer: _ClientPeer ref)
  fun ref handle_input(peer: _ClientPeer ref, buffer: Buffer ref)

class ProtocolNone is Protocol
  fun ref handle_start(peer: _ClientPeer ref) => None
  fun ref handle_input(peer: _ClientPeer ref, buffer: Buffer ref) => None
