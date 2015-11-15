// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

interface val _ObserveOutgoing
  fun tag observe() => None // TODO: flesh out this interface

primitive _ObserveOutgoingNone is _ObserveOutgoing
primitive _ObserveOutgoingRoutingFrame is _ObserveOutgoing
