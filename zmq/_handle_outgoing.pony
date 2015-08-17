// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

interface _HandleOutgoing val
  fun tag handle() => None // TODO: flesh out this interface

primitive _HandleOutgoingAllPeers is _HandleOutgoing
primitive _HandleOutgoingRoundRobin is _HandleOutgoing
primitive _HandleOutgoingSubscribedPeers is _HandleOutgoing
primitive _HandleOutgoingRoutingFrame is _HandleOutgoing
primitive _HandleOutgoingSinglePeer is _HandleOutgoing
primitive _HandleOutgoingDiscard is _HandleOutgoing
