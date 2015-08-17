// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

interface SocketType val
  fun tag string(): String
  fun tag accepts(other: String): Bool
  fun tag handle_outgoing(): _HandleOutgoing
  fun tag handle_incoming(): _HandleIncoming
  fun tag observe_outgoing(): _ObserveOutgoing => _ObserveOutgoingNone
  fun tag observe_incoming(): _ObserveIncoming => _ObserveIncomingNone

///
// SocketTypes

primitive REQ is SocketType
  fun tag string(): String => "REQ"
  fun tag accepts(other: String): Bool => (other == "REP")
                                       or (other == "ROUTER")
  fun tag handle_outgoing(): _HandleOutgoing => _HandleOutgoingRoundRobin
  fun tag handle_incoming(): _HandleIncoming => _HandleIncomingAllPeers

primitive REP is SocketType
  fun tag string(): String => "REP"
  fun tag accepts(other: String): Bool => (other == "REQ")
                                       or (other == "DEALER")
  fun tag handle_outgoing(): _HandleOutgoing => _HandleOutgoingDiscard // only allow by promise or peer
  fun tag handle_incoming(): _HandleIncoming => _HandleIncomingAllPeers

primitive DEALER is SocketType
  fun tag string(): String => "DEALER"
  fun tag accepts(other: String): Bool => (other == "REP")
                                       or (other == "DEALER")
                                       or (other == "ROUTER")
  fun tag handle_outgoing(): _HandleOutgoing => _HandleOutgoingRoundRobin
  fun tag handle_incoming(): _HandleIncoming => _HandleIncomingAllPeers
  fun tag observe_outgoing(): _ObserveOutgoing => _ObserveOutgoingRoutingFrame

primitive ROUTER is SocketType
  fun tag string(): String => "ROUTER"
  fun tag accepts(other: String): Bool => (other == "REQ")
                                       or (other == "DEALER")
                                       or (other == "ROUTER")
  fun tag handle_outgoing(): _HandleOutgoing => _HandleOutgoingRoutingFrame
  fun tag handle_incoming(): _HandleIncoming => _HandleIncomingAllPeers
  fun tag observe_incoming(): _ObserveIncoming => _ObserveIncomingRoutingFrame

primitive PUB is SocketType
  fun tag string(): String => "PUB"
  fun tag accepts(other: String): Bool => (other == "SUB")
                                       or (other == "XSUB")
  fun tag handle_outgoing(): _HandleOutgoing => _HandleOutgoingSubscribedPeers
  fun tag handle_incoming(): _HandleIncoming => _HandleIncomingDiscard
  fun tag observe_incoming(): _ObserveIncoming => _ObserveIncomingSubscriptionFilter

primitive SUB is SocketType
  fun tag string(): String => "SUB"
  fun tag accepts(other: String): Bool => (other == "PUB")
                                       or (other == "XPUB")
  fun tag handle_outgoing(): _HandleOutgoing => _HandleOutgoingDiscard
  fun tag handle_incoming(): _HandleIncoming => _HandleIncomingAllPeers

primitive XPUB is SocketType
  fun tag string(): String => "XPUB"
  fun tag accepts(other: String): Bool => (other == "SUB")
                                       or (other == "XSUB")
  fun tag handle_outgoing(): _HandleOutgoing => _HandleOutgoingAllPeers
  fun tag handle_incoming(): _HandleIncoming => _HandleIncomingAllPeers

primitive XSUB is SocketType
  fun tag string(): String => "XSUB"
  fun tag accepts(other: String): Bool => (other == "PUB")
                                       or (other == "XPUB")
  fun tag handle_outgoing(): _HandleOutgoing => _HandleOutgoingAllPeers
  fun tag handle_incoming(): _HandleIncoming => _HandleIncomingAllPeers

primitive PUSH is SocketType
  fun tag string(): String => "PUSH"
  fun tag accepts(other: String): Bool => (other == "PULL")
  fun tag handle_outgoing(): _HandleOutgoing => _HandleOutgoingRoundRobin
  fun tag handle_incoming(): _HandleIncoming => _HandleIncomingDiscard

primitive PULL is SocketType
  fun tag string(): String => "PULL"
  fun tag accepts(other: String): Bool => (other == "PUSH")
  fun tag handle_outgoing(): _HandleOutgoing => _HandleOutgoingDiscard
  fun tag handle_incoming(): _HandleIncoming => _HandleIncomingAllPeers

primitive PAIR is SocketType
  fun tag string(): String => "PAIR"
  fun tag accepts(other: String): Bool => (other == "PAIR")
  fun tag handle_outgoing(): _HandleOutgoing => _HandleOutgoingSinglePeer
  fun tag handle_incoming(): _HandleIncoming => _HandleIncomingSinglePeer

///
// SocketType-intrinsic strategies for handling messages and peer routing.

interface _HandleOutgoing val
  fun tag handle() => None // TODO: flesh out this interface

primitive _HandleOutgoingAllPeers is _HandleOutgoing
primitive _HandleOutgoingRoundRobin is _HandleOutgoing
primitive _HandleOutgoingSubscribedPeers is _HandleOutgoing
primitive _HandleOutgoingRoutingFrame is _HandleOutgoing
primitive _HandleOutgoingSinglePeer is _HandleOutgoing
primitive _HandleOutgoingDiscard is _HandleOutgoing

interface _HandleIncoming val
  fun tag handle() => None // TODO: flesh out this interface

primitive _HandleIncomingAllPeers is _HandleIncoming
primitive _HandleIncomingSinglePeer is _HandleIncoming
primitive _HandleIncomingDiscard is _HandleIncoming

interface _ObserveOutgoing val
  fun tag observe() => None // TODO: flesh out this interface

primitive _ObserveOutgoingNone is _ObserveOutgoing
primitive _ObserveOutgoingRoutingFrame is _ObserveOutgoing

interface _ObserveIncoming val
  fun tag observe() => None // TODO: flesh out this interface

primitive _ObserveIncomingNone is _ObserveIncoming
primitive _ObserveIncomingRoutingFrame is _ObserveIncoming
primitive _ObserveIncomingSubscriptionFilter is _ObserveIncoming
