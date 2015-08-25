// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use "../../../pony-sodium/sodium"

primitive _MechanismAuthCurveServerStateReadGreeting
primitive _MechanismAuthCurveServerStateReadHandshakeHello
primitive _MechanismAuthCurveServerStateReadHandshakeInitiate
primitive _MechanismAuthCurveServerStateAwaitZapResponse
primitive _MechanismAuthCurveServerStateReadMessage

type _MechanismAuthCurveServerState is
  ( _MechanismAuthCurveServerStateReadGreeting
  | _MechanismAuthCurveServerStateReadHandshakeHello
  | _MechanismAuthCurveServerStateReadHandshakeInitiate
  | _MechanismAuthCurveServerStateAwaitZapResponse
  | _MechanismAuthCurveServerStateReadMessage)

// TODO: improve performance with CryptoBox precomputation after handshake.
class MechanismAuthCurveServer is Mechanism
  let _session: Session
  let _s_pk: CryptoBoxPublicKey
  let _s_sk: CryptoBoxSecretKey
  let _st_pk: CryptoBoxPublicKey
  let _st_sk: CryptoBoxSecretKey
  var _ct_pk: CryptoBoxPublicKey = CryptoBoxPublicKey("")
  var _c_pk: CryptoBoxPublicKey = CryptoBoxPublicKey("")
  var _cookie_key: CryptoSecretBoxKey = CryptoSecretBoxKey("")
  
  var _state: _MechanismAuthCurveServerState = _MechanismAuthCurveServerStateReadGreeting
  var _nonce_gen: _CurveNonceGenerator iso = _nonce_gen.create()
  
  new create(session: Session, s_pk: CryptoBoxPublicKey, s_sk: CryptoBoxSecretKey) =>
    _session = session
    _s_pk = s_pk
    _s_sk = s_sk
    (_st_pk, _st_sk) = try CryptoBox.keypair()
                   else (CryptoBoxPublicKey(""), CryptoBoxSecretKey("")) end
  
  fun ref _next_state(state: _MechanismAuthCurveServerState) =>
    _state = state
  
  fun ref handle_input(buffer: _Buffer ref) =>
    try while true do
      match _state
      | _MechanismAuthCurveServerStateReadGreeting          => _read_greeting(buffer)
      | _MechanismAuthCurveServerStateReadHandshakeHello    => _read_hello(buffer)
      | _MechanismAuthCurveServerStateReadHandshakeInitiate => _read_initiate(buffer)
      | _MechanismAuthCurveServerStateAwaitZapResponse      => error
      | _MechanismAuthCurveServerStateReadMessage           => _read_message(buffer)
      end
    end end
  
  fun ref handle_zap_response(zap: ZapResponse) =>
    if _state is _MechanismAuthCurveServerStateAwaitZapResponse then
      if zap.is_success() then
        try _write_ready() end // TODO: handle zap.metadata
      else
        _session.protocol_error("ZAP authentication failure") // TODO: more details
      end
    end
  
  fun ref handle_start() =>
    _next_state(_MechanismAuthCurveServerStateReadGreeting)
    _session._write_greeting()
  
  fun ref _read_greeting(buffer: _Buffer ref)? =>
    _session._read_greeting(buffer)
    _next_state(_MechanismAuthCurveServerStateReadHandshakeHello)
  
  fun ref _read_hello(buffer: _Buffer ref)? =>
    let command = _session._read_specific_command[CommandAuthCurveHello](buffer)
    
    if not ((command.version_major == 1) and (command.version_minor == 0)) then
      _session.protocol_error("unknown CurveZMQ version: " +
                              command.version_major.string() + "." +
                              command.version_minor.string())
      error
    end
    
    _ct_pk = command.ct_pk
    let nonce = CryptoBoxNonce("CurveZMQHELLO---" + command.short_nonce)
    let data = try CryptoBox.open(command.signature_box, nonce, _ct_pk, _s_sk) else
                 _session.protocol_error("couldn't open HELLO box")
                 error
               end
    
    _next_state(_MechanismAuthCurveServerStateReadHandshakeInitiate)
    _write_welcome()
  
  fun ref _write_welcome()? =>
    _cookie_key = CryptoSecretBox.key()
    let cookie_nonce = _nonce_gen.next_long()
    let welcome_box = CommandAuthCurveWelcomeBox
    welcome_box.st_pk = _st_pk
    welcome_box.cookie = cookie_nonce +
      CryptoSecretBox(_ct_pk.string() + _st_sk.string(),
        CryptoSecretBoxNonce("COOKIE--" + cookie_nonce), _cookie_key)
    
    let command = CommandAuthCurveWelcome
    let long_nonce = _nonce_gen.next_long()
    let nonce = CryptoBoxNonce("WELCOME-" + long_nonce)
    command.long_nonce = long_nonce
    command.data_box = try CryptoBox(welcome_box.string(), nonce, _ct_pk, _s_sk) else
                         _session.protocol_error("couldn't encode WELCOME box")
                         error
                       end
    _session._write_command(command)
  
  fun ref _read_initiate(buffer: _Buffer ref)? =>
    let command = _session._read_specific_command[CommandAuthCurveInitiate](buffer)
    
    let cookie = try CryptoSecretBox.open(command.cookie.substring(16, -1),
                       CryptoSecretBoxNonce("COOKIE--" + command.cookie.substring(0, 15)),
                         _cookie_key) else
                   _session.protocol_error("couldn't open INITIATE cookie box")
                   error
                 end
    if (cookie.substring(0, 31) != _ct_pk.string())
    or (cookie.substring(32, 63) != _st_sk.string()) then
      _session.protocol_error("got incorrect INITIATE cookie")
      error
    end
    _cookie_key = CryptoSecretBoxKey("") // forget cookie key
    
    // TODO: verify incrementing short nonces
    let nonce = CryptoBoxNonce("CurveZMQINITIATE" + command.short_nonce)
    let data = try CryptoBox.open(command.data_box, nonce, _ct_pk, _st_sk) else
                 _session.protocol_error("couldn't open INITIATE box")
                 error
               end
    let initate_box = CommandAuthCurveInitiateBox(data)
    
    let other_type = try initate_box.metadata("Socket-Type") else "" end
    if not _session.keeper.socket_type_accepts(other_type) then
      let this_type = _session.keeper.socket_type_string()
      _session.protocol_error(this_type+" socket cannot accept: "+other_type)
      error
    end
    
    _c_pk = initate_box.c_pk
    let vouch_nonce = CryptoBoxNonce("VOUCH---" + initate_box.long_nonce)
    let vouch = try CryptoBox.open(initate_box.vouch_box, vouch_nonce, _c_pk, _st_sk) else
                  _session.protocol_error("couldn't open INITIATE vouch box")
                  error
                end
    let vouch_box = CommandAuthCurveInitiateVouchBox(vouch)
    
    if (vouch_box.ct_pk.string() != _ct_pk.string())
    or (vouch_box.s_pk.string() != _s_pk.string()) then
      _session.protocol_error("contents of INITIATE vouch box are incorrect")
      error
    end
    
    let zap: ZapRequest trn = ZapRequest
    // TODO: zap.domain = 
    // TODO: zap.address = 
    // TODO: zap.identity = 
    zap.mechanism = "CURVE"
    zap.push_credential(_c_pk.string())
    _session.zap_request(consume zap)
    
    _next_state(_MechanismAuthCurveServerStateAwaitZapResponse)
    error // Don't read any more buffer input until ZapResponse returns
  
  fun ref _write_ready()? =>
    let ready_box: CommandAuthCurveReadyBox ref = CommandAuthCurveReadyBox
    ready_box.metadata("Socket-Type") = _session.keeper.socket_type_string()
    
    let command = CommandAuthCurveReady
    let short_nonce = _nonce_gen.next_short()
    let nonce = CryptoBoxNonce("CurveZMQREADY---" + short_nonce)
    command.short_nonce = short_nonce
    command.data_box = try CryptoBox(ready_box.string(), nonce, _ct_pk, _st_sk) else
                         _session.protocol_error("couldn't encode READY box")
                         error
                       end
    _session._write_command(command)
    
    _session.activated(_make_message_writex())
    _next_state(_MechanismAuthCurveServerStateReadMessage)
  
  fun ref _read_message(buffer: _Buffer ref)? =>
    let command = _session._read_specific_command[CommandAuthCurveMessage](buffer)
    // TODO: validate that client's short nonces increment as per spec.
    let nonce = CryptoBoxNonce("CurveZMQMESSAGEC" + command.short_nonce)
    let data = try CryptoBox.open(command.data_box, nonce, _ct_pk, _st_sk) else
                 _session.protocol_error("couldn't open MESSAGE box")
                 error
               end
    let message_box = CommandAuthCurveMessageBox(data)
    _session._add_to_message(message_box.payload)
    
    if not message_box.has_more then
      _session.received(_session._take_message())
    end
  
  fun ref _make_message_writex(): MessageWriteTransform iso^ =>
    let pk = _ct_pk
    let sk = _st_sk
    // TODO: make the new local _nonce_gen unusable (to avoid dups with moved one)
    let nonce_gen: _CurveNonceGenerator iso = _nonce_gen = _CurveNonceGenerator
    
    recover
      _CurveUtil~message_writex(pk, sk, consume nonce_gen, "CurveZMQMESSAGES")
    end
