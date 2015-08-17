// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

interface SocketType val
  fun tag string(): String
  fun tag accepts(other: String): Bool

primitive REQ is SocketType
  fun tag string(): String => "REQ"
  fun tag accepts(other: String): Bool => (other == "REP")
                                       or (other == "ROUTER")

primitive REP is SocketType
  fun tag string(): String => "REP"
  fun tag accepts(other: String): Bool => (other == "REQ")
                                       or (other == "DEALER")

primitive DEALER is SocketType
  fun tag string(): String => "DEALER"
  fun tag accepts(other: String): Bool => (other == "REP")
                                       or (other == "DEALER")
                                       or (other == "ROUTER")

primitive ROUTER is SocketType
  fun tag string(): String => "ROUTER"
  fun tag accepts(other: String): Bool => (other == "REQ")
                                       or (other == "DEALER")
                                       or (other == "ROUTER")

primitive PUB is SocketType
  fun tag string(): String => "PUB"
  fun tag accepts(other: String): Bool => (other == "SUB")
                                       or (other == "XSUB")

primitive SUB is SocketType
  fun tag string(): String => "SUB"
  fun tag accepts(other: String): Bool => (other == "PUB")
                                       or (other == "XPUB")

primitive XPUB is SocketType
  fun tag string(): String => "XPUB"
  fun tag accepts(other: String): Bool => (other == "SUB")
                                       or (other == "XSUB")

primitive XSUB is SocketType
  fun tag string(): String => "XSUB"
  fun tag accepts(other: String): Bool => (other == "PUB")
                                       or (other == "XPUB")

primitive PUSH is SocketType
  fun tag string(): String => "PUSH"
  fun tag accepts(other: String): Bool => (other == "PULL")

primitive PULL is SocketType
  fun tag string(): String => "PULL"
  fun tag accepts(other: String): Bool => (other == "PUSH")

primitive PAIR is SocketType
  fun tag string(): String => "PAIR"
  fun tag accepts(other: String): Bool => (other == "PAIR")
