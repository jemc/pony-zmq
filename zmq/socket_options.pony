// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use "collections"
use "./inspect"

///
// Generic structures

type SocketOptionValue is
  ( Bool
  | U64
  | F64
  | String
  | (String | None))

interface SocketOption[A: SocketOptionValue] tag
  fun tag apply(value: A): _SocketOptionWithValue[A] =>
    _SocketOptionWithValue[A](this, value)
  
  fun tag default(): A
  fun tag validate(value: A)? => None
  fun tag validate_error(): String => "Invalid socket option value."
  
  fun tag find_in(list: SocketOptions box): A =>
    try
      var iter = list.values()
      while iter.has_next() do
        try var optval = iter.next() as _SocketOptionWithValue[A]
          if optval.option_tag() is this then
            return optval.value
          end
        end
      end
      error
    else
      default()
    end
  
  fun tag set_in(list: SocketOptions, value: A): Bool =>
    apply(value).set_in(list)

class _SocketOptionWithValue[A: SocketOptionValue] val
  let option: SocketOption[A]
  let value: A
  fun option_tag(): Any tag => option
  new val create(option': SocketOption[A], value': A) =>
    option = option'
    value = value'
  
  fun val set_in(list: SocketOptions): Bool =>
    try option.validate(value) else return false end
    
    match this | let optval: SocketOptionWithValue =>
      for other_node in list.nodes() do
        try
          let other = other_node()
          if other.option_tag() is option then
            other_node.remove()
          end
        end
      end
      
      list.push(optval)
      true
    else
      false
    end

interface SocketOptionWithValue val
  fun option_tag(): Any tag
  fun val set_in(list: SocketOptions): Bool

type SocketOptions is List[SocketOptionWithValue]

///
// Socket option shared behaviors

interface _SocketOptionCurveKey is SocketOption[String]
  fun tag default(): String => ""
  fun tag validate(value: String)? =>
    match value.size()
    | 0 | 32 | 40 => true // TODO: validate Z85 encoding when size == 40
    else error
    end
  fun tag validate_error(): String =>
    "CURVE keys must be either 32-byte binary or 40-byte Z85-encoded strings."

///
// Socket options

primitive CurveAsServer is SocketOption[Bool]
  """
  NOT YET IMPLEMENTED.
  Indicates that the socket should act as a server for CURVE encryption.
  If set to true, the other socket must act as a client, and must know the
  public key of the server socket prior to connecting.
  """
  fun tag default(): Bool => false

primitive CurvePublicKey is _SocketOptionCurveKey
  """
  NOT YET IMPLEMENTED.
  The local public key to use for CURVE encryption, as a string.
  Both the server and the client socket must set a public key,
  which may be distributed to others to establish a trusted identity.
  Each public key is associated with a secret key, which must be
  kept secret to maintain security.
  """

primitive CurveSecretKey is _SocketOptionCurveKey
  """
  NOT YET IMPLEMENTED.
  The local secret key to use for CURVE encryption, as a string.
  Both the server and the client socket must set a secret key,
  and must keep their secret key secret to maintain security.
  Each secret key is associated with a public key, which may be
  distributed to others to establish a trusted identity.
  """

primitive CurvePublicKeyOfServer is _SocketOptionCurveKey
  """
  NOT YET IMPLEMENTED.
  The expected public key of the remote server when using CURVE encryption.
  The client socket must set this option before connecting to a server
  and it must correlate to the secret key of the server socket
  for the CURVE encryption handshake to complete successfully.
  """

primitive HandshakeTimeout is SocketOption[F64]
  """
  NOT YET IMPLEMENTED.
  The maximum time to allow for new connections to complete their handshake.
  Handshaking establishes the ZMTP protocol version, exchanges configuration
  between sockets, and establishes authentication or encryption when applicable.
  If handshake does not complete within the timeout, the connection is dropped.
  Values are given in seconds, with 0 indicating no time limit.
  """
  fun tag default(): F64 => 30.0

primitive HeartbeatInterval is SocketOption[F64]
  """
  NOT YET IMPLEMENTED.
  NOT YET DOCUMENTED.
  """
  fun tag default(): F64 => 0.0

primitive HeartbeatTimeout is SocketOption[F64]
  """
  NOT YET IMPLEMENTED.
  NOT YET DOCUMENTED.
  """
  fun tag default(): F64 => 0.0

primitive HeartbeatTTL is SocketOption[U64]
  """
  NOT YET IMPLEMENTED.
  NOT YET DOCUMENTED.
  """
  fun tag default(): U64 => 0

primitive MaxMessageSize is SocketOption[U64]
  """
  NOT YET IMPLEMENTED.
  The maximum size of message to receive, in bytes.
  A peer that sends a message larger than this size will be disconnected.
  A value of 0 indicates no size limit.
  """
  fun tag default(): U64 => 0

primitive MulticastMaxHops is SocketOption[U64]
  """
  NOT YET IMPLEMENTED.
  NOT YET DOCUMENTED.
  """
  fun tag default(): U64 => 0

primitive MulticastMaxRate is SocketOption[U64]
  """
  NOT YET IMPLEMENTED.
  NOT YET DOCUMENTED.
  """
  fun tag default(): U64 => 0

primitive MulticastRecoveryInterval is SocketOption[F64]
  """
  NOT YET IMPLEMENTED.
  NOT YET DOCUMENTED.
  """
  fun tag default(): F64 => 0

primitive ProbeRouter is SocketOption[Bool]
  """
  NOT YET IMPLEMENTED.
  If true, the socket will automatically send an empty message after
  completing a connection handshake with a ROUTER socket, providing the
  ROUTER application with a signal that a new peer has connected.
  """
  fun tag default(): Bool => false

primitive QueueOutgoingMax is SocketOption[U64]
  """
  NOT YET IMPLEMENTED.
  NOT YET DOCUMENTED.
  """
  fun tag default(): U64 => 0

primitive ReconnectInterval is SocketOption[F64]
  """
  NOT YET IMPLEMENTED.
  NOT YET DOCUMENTED.
  """
  fun tag default(): F64 => 0.1

primitive ReconnectIntervalMax is SocketOption[F64]
  """
  NOT YET IMPLEMENTED.
  NOT YET DOCUMENTED.
  """
  fun tag default(): F64 => 0.1

primitive RouterHandover is SocketOption[Bool]
  """
  NOT YET IMPLEMENTED.
  NOT YET DOCUMENTED.
  """
  fun tag default(): Bool => false

primitive RouterMandatory is SocketOption[Bool]
  """
  NOT YET IMPLEMENTED.
  NOT YET DOCUMENTED.
  """
  fun tag default(): Bool => false

primitive RoutingIdentity is SocketOption[String]
  """
  NOT YET IMPLEMENTED.
  NOT YET DOCUMENTED.
  """
  fun tag default(): String => ""
  fun tag validate(value: String)? =>
    if value.size() > 255 then error end
  fun tag validate_error(): String =>
    "Routing identity strings may not be longer than 255 bytes."

primitive Subscribe is SocketOption[String]
  """
  NOT YET IMPLEMENTED.
  Add a string to the set of subscriptions received by a SUB socket.
  If the given string already exists in the set, the set is not changed.
  Messages whose first frame prefix-matches any of the subscribe set strings
  will be received by the SUB socket; all other messages will be filtered.
  If no subscriptions are added, the SUB socket will receive no messages.
  Subscribing with an empty string implies all messages should be received.
  """
  fun tag default(): String => ""

primitive SubscribeInverse is SocketOption[Bool]
  """
  NOT YET IMPLEMENTED.
  If true, the semantics of the set of given subscribe strings are inverted.
  All messages which would otherwise be received will be filtered, and
  all messages which would otherwise be filtered will be received.
  """
  fun tag default(): Bool => false

primitive Unsubscribe is SocketOption[String]
  """
  NOT YET IMPLEMENTED.
  Remove a string to the set of subscriptions received by a SUB socket.
  If the given string isn't currently in the set, the set is not changed.
  Messages whose first frame prefix-matches any of the subscribe set strings
  will be received by the SUB socket; all other messages will be filtered.
  If no subscriptions are added, the SUB socket will receive no messages.
  Subscribing with an empty string implies all messages should be received.
  """
  fun tag default(): String => ""

primitive XPubManual is SocketOption[Bool]
  """
  NOT YET IMPLEMENTED.
  NOT YET DOCUMENTED.
  """
  fun tag default(): Bool => false

primitive XPubVerboseSubscribe is SocketOption[Bool]
  """
  NOT YET IMPLEMENTED.
  If true, an XPUB will forward all subscription messages to the application.
  Otherwise, only additions to the subscription set will be forwarded.
  """
  fun tag default(): Bool => false

primitive XPubVerboseUnsubscribe is SocketOption[Bool]
  """
  NOT YET IMPLEMENTED.
  If true, an XPUB will forward all unsubscription messages to the application.
  Otherwise, only removals from the subscription set will be forwarded.
  """
  fun tag default(): Bool => false

primitive XPubWelcomeMessage is SocketOption[(String | None)]
  """
  NOT YET IMPLEMENTED.
  NOT YET DOCUMENTED.
  """
  fun tag default(): (String | None) => None
