// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use "collections"

interface _HandleOutgoing
  fun ref new_peer(p: _SocketPeer) => None
  fun ref lost_peer(p: _SocketPeer) => None
  fun ref apply(m: Message)?

class _HandleOutgoingAllPeers is _HandleOutgoing
  """
  Route each outgoing message to all active peers.
  """
  let _peers: List[_SocketPeer] = _peers.create()
  
  fun ref new_peer(p: _SocketPeer) => _peers.push(p)
  
  fun ref lost_peer(p: _SocketPeer) =>
    for node in _peers.nodes() do
      try
        if node() is p then
          node.remove()
          return
        end
      end
    end
  
  fun ref apply(m: Message) =>
    for peer in _peers.values() do
      peer.send(m)
    end

class _HandleOutgoingRoundRobin is _HandleOutgoing
  """
  Route each outgoing message to a different peer in a round-robin order.
  """
  let _peers: List[_SocketPeer] = _peers.create()
  var _robin: USize = 0 // TODO: Linked-list-oriented implementation.
  
  fun ref new_peer(p: _SocketPeer) => _peers.push(p)
  
  fun ref lost_peer(p: _SocketPeer) =>
    for node in _peers.nodes() do
      try
        if node() is p then
          node.remove()
          return
        end
      end
    end
  
  fun ref apply(m: Message)? =>
    (try _peers(_robin = _robin + 1)
    else _robin = 1; _peers(0)
    end).send(m)

class _HandleOutgoingSubscribedPeers is _HandleOutgoing
  """
  Route outgoing messages to peers with a subscription matching the first frame.
  """
  fun ref apply(m: Message) => None

class _HandleOutgoingRoutingFrame is _HandleOutgoing
  """
  Route outgoing messages using the first frame as a peer identity.
  """
  fun ref apply(m: Message) => None

class _HandleOutgoingSinglePeer is _HandleOutgoing
  """
  Route all outgoing messages to the most recently activated peer.
  """
  var _peer: (_SocketPeer | None) = None
  fun ref new_peer(p: _SocketPeer) => _peer = p
  fun ref lost_peer(p: _SocketPeer) => _peer = None
  fun ref apply(m: Message)? =>
    (_peer as _SocketPeer).send(m)

class _HandleOutgoingDiscard is _HandleOutgoing
  """
  Discard all messages.
  """
  fun ref apply(m: Message) => None
