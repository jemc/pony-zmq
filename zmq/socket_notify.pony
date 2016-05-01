// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

interface val SocketNotify
  fun val received(socket: Socket, peer: SocketPeer, message: Message) =>
    """
    Called when a new message is received from a peer.
    """
    None
  
  fun val new_peer(socket: Socket, peer: SocketPeer) =>
    """
    Called when a new peer is added to the Socket.
    """
    None
  
  fun val lost_peer(socket: Socket, peer: SocketPeer) =>
    """
    Called when a peer is removed from the Socket.
    """
    None
  
  fun val closed(socket: Socket) =>
    """
    Called when the socket is closed.
    """
    None

class val SocketNotifyNone is SocketNotify
  new val create() => None

interface tag SocketNotifiableActor
  be received(socket: Socket, peer: SocketPeer, message: Message) => None
  be new_peer(socket: Socket, peer: SocketPeer) => None
  be lost_peer(socket: Socket, peer: SocketPeer) => None
  be closed(socket: Socket) => None

class val SocketNotifyActor is SocketNotify
  let _parent: SocketNotifiableActor
  new val create(parent: SocketNotifiableActor) => _parent = parent
  
  fun val received(s: Socket, p: SocketPeer, m: Message) => _parent.received(s, p, m)
  fun val new_peer(s: Socket, p: SocketPeer) => _parent.new_peer(s, p)
  fun val lost_peer(s: Socket, p: SocketPeer) => _parent.lost_peer(s, p)
  fun val closed(s: Socket) => _parent.closed(s)

