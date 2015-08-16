
use "../../../pony-sodium/sodium"

primitive _ProtocolAuthCurveClientStateReadGreeting
primitive _ProtocolAuthCurveClientStateReadHandshakeWelcome
primitive _ProtocolAuthCurveClientStateReadHandshakeReady
primitive _ProtocolAuthCurveClientStateReadMessage

type _ProtocolAuthCurveClientState is
  ( _ProtocolAuthCurveClientStateReadGreeting
  | _ProtocolAuthCurveClientStateReadHandshakeWelcome
  | _ProtocolAuthCurveClientStateReadHandshakeReady
  | _ProtocolAuthCurveClientStateReadMessage)

// TODO: improve performance with CryptoBox precomputation after handshake.
class ProtocolAuthCurveClient is Protocol
  let _session: Session
  let _c_pk: CryptoBoxPublicKey
  let _c_sk: CryptoBoxSecretKey
  let _s_pk: CryptoBoxPublicKey
  let _ct_pk: CryptoBoxPublicKey
  let _ct_sk: CryptoBoxSecretKey
  var _st_pk: CryptoBoxPublicKey = CryptoBoxPublicKey("")
  
  var _state: _ProtocolAuthCurveClientState = _ProtocolAuthCurveClientStateReadGreeting
  var _nonce_gen: _CurveNonceGenerator iso = _nonce_gen.create()
  
  new create(session: Session, c_pk: CryptoBoxPublicKey, c_sk: CryptoBoxSecretKey, s_pk: CryptoBoxPublicKey) =>
    _session = session
    _c_pk = c_pk
    _c_sk = c_sk
    _s_pk = s_pk
    (_ct_pk, _ct_sk) = try CryptoBox.keypair()
                       else (CryptoBoxPublicKey(""), CryptoBoxSecretKey("")) end
  
  fun ref _next_state(state: _ProtocolAuthCurveClientState) =>
    _state = state
  
  fun ref handle_input(buffer: _Buffer ref) =>
    try while true do
      match _state
      | _ProtocolAuthCurveClientStateReadGreeting         => _read_greeting(buffer)
      | _ProtocolAuthCurveClientStateReadHandshakeWelcome => _read_welcome(buffer)
      | _ProtocolAuthCurveClientStateReadHandshakeReady   => _read_ready(buffer)
      | _ProtocolAuthCurveClientStateReadMessage          => _read_message(buffer)
      end
    end end
  
  fun ref handle_start() =>
    _next_state(_ProtocolAuthCurveClientStateReadGreeting)
    _session._write_greeting()
  
  fun ref _read_greeting(buffer: _Buffer ref)? =>
    _session._read_greeting(buffer)
    _next_state(_ProtocolAuthCurveClientStateReadHandshakeWelcome)
    _write_hello()
  
  fun ref _write_hello()? =>
    let command = CommandAuthCurveHello
    let short_nonce = _nonce_gen.next_short()
    let nonce = CryptoBoxNonce("CurveZMQHELLO---" + short_nonce)
    let signature = "\x00\x00\x00\x00\x00\x00\x00\x00" +
                    "\x00\x00\x00\x00\x00\x00\x00\x00" +
                    "\x00\x00\x00\x00\x00\x00\x00\x00" +
                    "\x00\x00\x00\x00\x00\x00\x00\x00" +
                    "\x00\x00\x00\x00\x00\x00\x00\x00" +
                    "\x00\x00\x00\x00\x00\x00\x00\x00" +
                    "\x00\x00\x00\x00\x00\x00\x00\x00" +
                    "\x00\x00\x00\x00\x00\x00\x00\x00"
    command.ct_pk         = _ct_pk
    command.short_nonce   = short_nonce
    command.signature_box = try CryptoBox(signature, nonce, _s_pk, _ct_sk) else
                              _session.protocol_error("couldn't encode HELLO box")
                              error
                            end
    _session._write_command(command)
  
  fun ref _read_welcome(buffer: _Buffer ref)? =>
    // TODO: possibility of receiving ERROR command here.
    let command = _session._read_specific_command[CommandAuthCurveWelcome](buffer)
    let nonce = CryptoBoxNonce("WELCOME-" + command.long_nonce)
    let data = try CryptoBox.open(command.data_box, nonce, _s_pk, _ct_sk) else
                 _session.protocol_error("couldn't open WELCOME box")
                 error
               end
    let welcome_box = CommandAuthCurveWelcomeBox(data)
    _st_pk = welcome_box.st_pk
    _next_state(_ProtocolAuthCurveClientStateReadHandshakeReady)
    _write_initiate(welcome_box.cookie)
  
  fun ref _write_initiate(cookie: String)? =>
    let vouch_box = CommandAuthCurveInitiateVouchBox
    vouch_box.ct_pk = _ct_pk
    vouch_box.s_pk = _s_pk
    
    let initiate_box: CommandAuthCurveInitiateBox ref = CommandAuthCurveInitiateBox
    let vouch_long_nonce = _nonce_gen.next_long()
    let vouch_nonce = CryptoBoxNonce("VOUCH---" + vouch_long_nonce)
    initiate_box.c_pk = _c_pk
    initiate_box.long_nonce = vouch_long_nonce
    initiate_box.vouch_box = try CryptoBox(vouch_box.string(), vouch_nonce, _st_pk, _c_sk) else
                               _session.protocol_error("couldn't encode INITIATE vouch box")
                               error
                             end
    initiate_box.metadata("Socket-Type") = _session.keeper.socket_type_string()
    
    let command = CommandAuthCurveInitiate
    let short_nonce = _nonce_gen.next_short()
    let nonce = CryptoBoxNonce("CurveZMQINITIATE" + short_nonce)
    command.cookie = cookie
    command.short_nonce = short_nonce
    command.data_box = try CryptoBox(initiate_box.string(), nonce, _st_pk, _ct_sk) else
                         _session.protocol_error("couldn't encode INITIATE box")
                         error
                       end
    _session._write_command(command)
  
  fun ref _read_ready(buffer: _Buffer ref)? =>
    // TODO: possibility of receiving ERROR command here.
    let command = _session._read_specific_command[CommandAuthCurveReady](buffer)
    // TODO: validate that server's short nonces increment as per spec.
    let nonce = CryptoBoxNonce("CurveZMQREADY---" + command.short_nonce)
    let data = try CryptoBox.open(command.data_box, nonce, _st_pk, _ct_sk) else
                 _session.protocol_error("couldn't open READY box")
                 error
               end
    let welcome_box = CommandAuthCurveReadyBox(data)
    
    let other_type = try welcome_box.metadata("Socket-Type") else "" end
    if not _session.keeper.socket_type_accepts(other_type) then
      let this_type = _session.keeper.socket_type_string()
      _session.protocol_error(this_type+" socket cannot accept: "+other_type)
      error
    end
    
    _session.activated(_make_message_writex())
    _next_state(_ProtocolAuthCurveClientStateReadMessage)
  
  fun ref _read_message(buffer: _Buffer ref)? =>
    // TODO: possibility of receiving ERROR command here.
    let command = _session._read_specific_command[CommandAuthCurveMessage](buffer)
    // TODO: validate that server's short nonces increment as per spec.
    let nonce = CryptoBoxNonce("CurveZMQMESSAGES" + command.short_nonce)
    let data = try CryptoBox.open(command.data_box, nonce, _st_pk, _ct_sk) else
                 _session.protocol_error("couldn't open MESSAGE box")
                 error
               end
    let message_box = CommandAuthCurveMessageBox(data)
    _session._add_to_message(message_box.payload)
    
    if not message_box.has_more then
      _session.received(_session._take_message())
    end
  
  fun ref _make_message_writex(): MessageWriteTransform iso^ =>
    let st_pk = _st_pk
    let ct_sk = _ct_sk
    let nonce_gen: _CurveNonceGenerator iso = _nonce_gen = _CurveNonceGenerator
    
    recover
      lambda(st_pk: CryptoBoxPublicKey, ct_sk: CryptoBoxSecretKey,
        nonce_gen: _CurveNonceGenerator iso^, message: Message box
      ): Array[U8] val =>
        let output = recover trn Array[U8] end
        
        for node in message.nodes() do
          let frame': (Frame | None) = try node() else None end
          
          match frame' | let frame: Frame =>
            let message_box = CommandAuthCurveMessageBox
            message_box.has_more = node.has_next()
            message_box.payload = frame
            
            let command = CommandAuthCurveMessage
            let short_nonce = nonce_gen.next_short()
            let nonce = CryptoBoxNonce("CurveZMQMESSAGEC" + short_nonce)
            command.short_nonce = short_nonce
            command.data_box = try CryptoBox(message_box.string(), nonce, st_pk, ct_sk) else
                                 ""  // TODO: some way to protocol-error from here?
                               end
            output.append(CommandParser.write(command))
          end
        end
        
        output
      end~apply(st_pk, ct_sk, consume nonce_gen)
    end
