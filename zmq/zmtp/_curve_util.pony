
use "../../../pony-sodium/sodium"

primitive _CurveUtil
  fun tag message_writex(pk: CryptoBoxPublicKey, sk: CryptoBoxSecretKey,
    nonce_gen: _CurveNonceGenerator iso^, nonce_prefix: String,
    message: Message box
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
        let nonce = CryptoBoxNonce(nonce_prefix + short_nonce)
        command.short_nonce = short_nonce
        command.data_box = try CryptoBox(message_box.string(), nonce, pk, sk) else
                             ""  // TODO: some way to protocol-error from here?
                           end
        output.append(CommandParser.write(command))
      end
    end
    
    output
