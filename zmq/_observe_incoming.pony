// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

interface val _ObserveIncoming
  fun tag observe() => None // TODO: flesh out this interface

primitive _ObserveIncomingNone is _ObserveIncoming
primitive _ObserveIncomingRoutingFrame is _ObserveIncoming
primitive _ObserveIncomingSubscriptionFilter is _ObserveIncoming
