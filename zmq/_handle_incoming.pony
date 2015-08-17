// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

interface _HandleIncoming
  fun ref add_peer(p: _SocketPeer) => None
  fun ref rem_peer(p: _SocketPeer) => None
  fun apply(p: _SocketPeer, m: Message)?


class _HandleIncomingAllPeers is _HandleIncoming
  """
  Never discard messages.
  """
  fun apply(p: _SocketPeer, m: Message) => None

class _HandleIncomingSinglePeer is _HandleIncoming
  """
  Discard messages that don't come from the single most recently activated peer.
  """
  var _peer: (_SocketPeer | None) = None
  fun ref add_peer(p: _SocketPeer) => _peer = p
  fun ref rem_peer(p: _SocketPeer) => _peer = None
  fun apply(p: _SocketPeer, m: Message)? =>
    if not (p is _peer) then error end

class _HandleIncomingDiscard is _HandleIncoming
  """
  Discard all messages.
  """
  fun apply(p: _SocketPeer, m: Message)? =>
    error
