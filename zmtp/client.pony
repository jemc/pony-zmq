
use "net"

actor Client
  let _conn: TCPConnection tag

  new create(host: String val, port: String val) =>
    _conn = TCPConnection(_ClientConnection(this), host, port)
