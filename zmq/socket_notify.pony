// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

interface SocketNotify iso
  fun ref sent(socket: Socket, message: Message): Message ? =>
    """
    Called when a message is sent on the connection. This gives the notifier an
    opportunity to modify sent message before it is written. The notifier can
    raise an error if the message is swallowed entirely.
    """
    message
  
  fun ref received(socket: Socket, message: Message) =>
    """
    Called when a new message is received on the connection.
    """
    None
  
  fun ref closed(socket: Socket) =>
    """
    Called when the socket is closed.
    """
    None

class SocketNotifyNone iso is SocketNotify
  new iso create() => None

interface _SocketNotifiableActor tag
  be received(socket: Socket, message: Message) => None
  be closed(socket: Socket) => None

class SocketNotifyActor iso is SocketNotify
  let _parent: _SocketNotifiableActor
  new iso create(parent: _SocketNotifiableActor) => _parent = parent
  
  fun ref received(s: Socket, m: Message) => _parent.received(s, m)
  fun ref closed(s: Socket) => _parent.closed(s)

