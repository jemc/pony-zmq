// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

interface SocketType val
  fun string(): String
  fun accepts(other: String): Bool

primitive REQ is SocketType
  fun string(): String => "REQ"
  fun accepts(other: String): Bool => (other == "REP")
                                   or (other == "ROUTER")

primitive REP is SocketType
  fun string(): String => "REP"
  fun accepts(other: String): Bool => (other == "REQ")
                                   or (other == "DEALER")

primitive DEALER is SocketType
  fun string(): String => "DEALER"
  fun accepts(other: String): Bool => (other == "REP")
                                   or (other == "DEALER")
                                   or (other == "ROUTER")

primitive ROUTER is SocketType
  fun string(): String => "ROUTER"
  fun accepts(other: String): Bool => (other == "REQ")
                                   or (other == "DEALER")
                                   or (other == "ROUTER")

primitive PUB is SocketType
  fun string(): String => "PUB"
  fun accepts(other: String): Bool => (other == "SUB")
                                   or (other == "XSUB")

primitive SUB is SocketType
  fun string(): String => "SUB"
  fun accepts(other: String): Bool => (other == "PUB")
                                   or (other == "XPUB")

primitive XPUB is SocketType
  fun string(): String => "XPUB"
  fun accepts(other: String): Bool => (other == "SUB")
                                   or (other == "XSUB")

primitive XSUB is SocketType
  fun string(): String => "XSUB"
  fun accepts(other: String): Bool => (other == "PUB")
                                   or (other == "XPUB")

primitive PUSH is SocketType
  fun string(): String => "PUSH"
  fun accepts(other: String): Bool => (other == "PULL")

primitive PULL is SocketType
  fun string(): String => "PULL"
  fun accepts(other: String): Bool => (other == "PUSH")

primitive PAIR is SocketType
  fun string(): String => "PAIR"
  fun accepts(other: String): Bool => (other == "PAIR")
