
use "net"
use "collections"

type ProtocolEvent is
  ( ProtocolEventHandshakeComplete
  | ProtocolEventError
  | ProtocolOutput
  | Message)

primitive ProtocolEventHandshakeComplete

class ProtocolEventError val
  var string: String = ""
  new val create(string': String) =>
    string = string'

type ProtocolOutput is Array[U8] val

interface Protocol
  fun ref handle_start()
  fun ref handle_input(buffer: Buffer ref)
  fun ref take_event(): (ProtocolEvent | None)

class ProtocolNone is Protocol
  fun ref handle_start() => None
  fun ref handle_input(buffer: Buffer ref) => None
  fun ref take_event(): (ProtocolEvent | None) => None
