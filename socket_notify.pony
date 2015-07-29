
use zmtp = "zmtp"

class SocketNotifyNone iso is SocketNotify
  new iso create() => None

interface SocketNotify iso
  fun ref sent(socket: Socket, message: zmtp.Message): zmtp.Message ? =>
    """
    Called when a message is sent on the connection. This gives the notifier an
    opportunity to modify sent message before it is written. The notifier can
    raise an error if the message is swallowed entirely.
    """
    message
  
  fun ref received(socket: Socket, message: zmtp.Message) =>
    """
    Called when a new message is received on the connection.
    """
    None
  
  fun ref closed(socket: Socket) =>
    """
    Called when the socket is closed.
    """
    None
