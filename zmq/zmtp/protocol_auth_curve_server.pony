
use "../../../pony-sodium/sodium"

primitive _ProtocolAuthCurveServerStateReadGreeting
primitive _ProtocolAuthCurveServerStateReadHandshakeHello
primitive _ProtocolAuthCurveServerStateReadHandshakeInitiate
primitive _ProtocolAuthCurveServerStateReadMessage

type _ProtocolAuthCurveServerState is
  ( _ProtocolAuthCurveServerStateReadGreeting
  | _ProtocolAuthCurveServerStateReadHandshakeHello
  | _ProtocolAuthCurveServerStateReadHandshakeInitiate
  | _ProtocolAuthCurveServerStateReadMessage)

class ProtocolAuthCurveServer is Protocol
  let _session: Session
  let _pk: CryptoBoxPublicKey
  let _sk: CryptoBoxSecretKey
  let _tpk: CryptoBoxPublicKey
  let _tsk: CryptoBoxSecretKey
  var _tpkc: CryptoBoxPublicKey = CryptoBoxPublicKey("")
  var _pkc: CryptoBoxPublicKey = CryptoBoxPublicKey("")
  
  var _state: _ProtocolAuthCurveServerState = _ProtocolAuthCurveServerStateReadGreeting
  var _nonce_gen: _NonceGenerator iso = _nonce_gen.create()
  
  new create(session: Session, pk: CryptoBoxPublicKey, sk: CryptoBoxSecretKey) =>
    _session = session
    _pk = pk
    _sk = sk
    (_tpk, _tsk) = try CryptoBox.keypair()
                   else (CryptoBoxPublicKey(""), CryptoBoxSecretKey("")) end
  
  fun ref _next_state(state: _ProtocolAuthCurveServerState) =>
    _state = state
  
  fun _make_cookie(): String =>
    // TODO: real cookie
    recover String.append([as U8: 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                                  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                                  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                                  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                                  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                                  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]) end
  
  fun ref handle_input(buffer: _Buffer ref) =>
    try while true do
      match _state
      | _ProtocolAuthCurveServerStateReadGreeting          => _read_greeting(buffer)
      | _ProtocolAuthCurveServerStateReadHandshakeHello    => _read_hello(buffer)
      | _ProtocolAuthCurveServerStateReadHandshakeInitiate => _read_initiate(buffer)
      | _ProtocolAuthCurveServerStateReadMessage           => _read_message(buffer)
      end
    end end
  
  fun ref handle_start() =>
    _next_state(_ProtocolAuthCurveServerStateReadGreeting)
    _session._write_greeting()
  
  fun ref _read_greeting(buffer: _Buffer ref)? =>
    _session._read_greeting(buffer)
    _next_state(_ProtocolAuthCurveServerStateReadHandshakeHello)
  
  fun ref _read_hello(buffer: _Buffer ref)? =>
    let command = _session._read_specific_command[CommandAuthCurveHello](buffer)
    
    if not ((command.version_major == 1) and (command.version_minor == 0)) then
      _session.protocol_error("unknown CurveZMQ version: " +
                              command.version_major.string() + "." +
                              command.version_minor.string())
      error
    end
    
    _tpkc = command.tpkc
    let nonce = CryptoBoxNonce("CurveZMQHELLO---" + command.short_nonce)
    let data = try CryptoBox.open(command.signature_box, nonce, _tpkc, _sk) else
                 _session.protocol_error("couldn't open HELLO box")
                 error
               end
    
    _next_state(_ProtocolAuthCurveServerStateReadHandshakeInitiate)
    _write_welcome()
  
  fun ref _write_welcome()? =>
    let welcome_box = CommandAuthCurveWelcomeBox
    welcome_box.tpks = _tpk
    welcome_box.cookie = _make_cookie()
    
    let command = CommandAuthCurveWelcome
    let long_nonce = _nonce_gen.next_long()
    let nonce = CryptoBoxNonce("WELCOME-" + long_nonce)
    command.long_nonce = long_nonce
    command.data_box = try CryptoBox(welcome_box.string(), nonce, _tpkc, _sk) else
                         _session.protocol_error("couldn't encode WELCOME box")
                         error
                       end
    _session._write_command(command)
  
  fun ref _read_initiate(buffer: _Buffer ref)? =>
    let command = _session._read_specific_command[CommandAuthCurveInitiate](buffer)
    
    if command.cookie != _make_cookie() then
      _session.protocol_error("got incorrect INITIATE cookie")
      error
    end
    
    // TODO: verify incrementing short nonces
    let nonce = CryptoBoxNonce("CurveZMQINITIATE" + command.short_nonce)
    let data = try CryptoBox.open(command.data_box, nonce, _tpkc, _tsk) else
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
    
    // TODO: optionally authenticate client key with application
    _pkc = initate_box.pkc
    let vouch_nonce = CryptoBoxNonce("VOUCH---" + initate_box.long_nonce)
    let vouch = try CryptoBox.open(initate_box.vouch_box, vouch_nonce, _pkc, _tsk) else
                  _session.protocol_error("couldn't open INITIATE vouch box")
                  error
                end
    let vouch_box = CommandAuthCurveInitiateVouchBox(vouch)
    
    if (vouch_box.tpkc.string() != _tpkc.string())
    or (vouch_box.pks.string() != _pk.string()) then
      _session.protocol_error("contents of INITIATE vouch box are incorrect")
      error
    end
    
    _write_ready()
  
  fun ref _write_ready()? =>
    let ready_box: CommandAuthCurveReadyBox ref = CommandAuthCurveReadyBox
    ready_box.metadata("Socket-Type") = _session.keeper.socket_type_string()
    
    let command = CommandAuthCurveReady
    let short_nonce = _nonce_gen.next_short()
    let nonce = CryptoBoxNonce("CurveZMQREADY---" + short_nonce)
    command.short_nonce = short_nonce
    command.data_box = try CryptoBox(ready_box.string(), nonce, _tpkc, _tsk) else
                         _session.protocol_error("couldn't encode READY box")
                         error
                       end
    _session._write_command(command)
    
    _session.activated(_make_message_writex())
    _next_state(_ProtocolAuthCurveServerStateReadMessage)
  
  fun ref _read_message(buffer: _Buffer ref)? =>
    let command = _session._read_specific_command[CommandAuthCurveMessage](buffer)
    // TODO: validate that client's short nonces increment as per spec.
    let nonce = CryptoBoxNonce("CurveZMQMESSAGEC" + command.short_nonce)
    let data = try CryptoBox.open(command.data_box, nonce, _tpkc, _tsk) else
                 _session.protocol_error("couldn't open MESSAGE box")
                 error
               end
    let message_box = CommandAuthCurveMessageBox(data)
    _session._add_to_message(message_box.payload)
    
    if not message_box.has_more then
      _session.received(_session._take_message())
    end
  
  // TODO: consolidate as common code with client class
  fun ref _make_message_writex(): MessageWriteTransform iso^ =>
    let tpkc = _tpkc
    let tsk = _tsk
    // TODO: initialize the new nonce gen at the same state as the current
    let nonce_gen: _NonceGenerator iso = _nonce_gen = _NonceGenerator
    
    recover
      lambda(tpkc: CryptoBoxPublicKey, tsk: CryptoBoxSecretKey,
        nonce_gen: _NonceGenerator iso^, message: Message box
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
            let nonce = CryptoBoxNonce("CurveZMQMESSAGES" + short_nonce)
            command.short_nonce = short_nonce
            command.data_box = try CryptoBox(message_box.string(), nonce, tpkc, tsk) else
                                 ""  // TODO: some way to protocol-error from here?
                               end
            output.append(CommandParser.write(command))
          end
        end
        
        output
      end~apply(tpkc, tsk, consume nonce_gen)
    end
