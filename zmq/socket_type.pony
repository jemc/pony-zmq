
type SocketType is
  ( REQ    | REP
  | DEALER | ROUTER
  | PUB    | SUB
  | XPUB   | XSUB
  | PUSH   | PULL
  | PAIR   )

primitive REQ
  fun string(): String => "REQ"
  fun accepts(other: String): Bool => (other == "REP")
                                   or (other == "ROUTER")

primitive REP
  fun string(): String => "REP"
  fun accepts(other: String): Bool => (other == "REQ")
                                   or (other == "DEALER")

primitive DEALER
  fun string(): String => "DEALER"
  fun accepts(other: String): Bool => (other == "REP")
                                   or (other == "DEALER")
                                   or (other == "ROUTER")

primitive ROUTER
  fun string(): String => "ROUTER"
  fun accepts(other: String): Bool => (other == "REQ")
                                   or (other == "DEALER")
                                   or (other == "ROUTER")

primitive PUB
  fun string(): String => "PUB"
  fun accepts(other: String): Bool => (other == "SUB")
                                   or (other == "XSUB")

primitive SUB
  fun string(): String => "SUB"
  fun accepts(other: String): Bool => (other == "PUB")
                                   or (other == "XPUB")

primitive XPUB
  fun string(): String => "XPUB"
  fun accepts(other: String): Bool => (other == "SUB")
                                   or (other == "XSUB")

primitive XSUB
  fun string(): String => "XSUB"
  fun accepts(other: String): Bool => (other == "PUB")
                                   or (other == "XPUB")

primitive PUSH
  fun string(): String => "PUSH"
  fun accepts(other: String): Bool => (other == "PULL")

primitive PULL
  fun string(): String => "PULL"
  fun accepts(other: String): Bool => (other == "PUSH")

primitive PAIR
  fun string(): String => "PAIR"
  fun accepts(other: String): Bool => (other == "PAIR")
