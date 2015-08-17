// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

interface _HandleIncoming val
  fun tag handle() => None // TODO: flesh out this interface

primitive _HandleIncomingAllPeers is _HandleIncoming
primitive _HandleIncomingSinglePeer is _HandleIncoming
primitive _HandleIncomingDiscard is _HandleIncoming
