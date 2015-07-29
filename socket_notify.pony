
use zmtp = "zmtp"

class SocketSimpleNotifyNone val is SocketSimpleNotify
  new val create() => None

interface SocketSimpleNotify val
  fun apply(message: zmtp.Message) =>
    None
