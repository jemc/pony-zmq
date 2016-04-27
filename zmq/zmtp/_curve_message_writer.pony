// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use "sodium"

class _CurveMessageWriter is MessageWriteTransform
  let sk: CryptoBoxSecretKey
  let pk: CryptoBoxPublicKey
  let nonce_gen: _CurveNonceGenerator
  let nonce_prefix: String
  
  new create(sk': CryptoBoxSecretKey, pk': CryptoBoxPublicKey,
    nonce_gen': _CurveNonceGenerator, nonce_prefix': String
  ) =>
    sk = sk'; pk = pk'; nonce_gen = nonce_gen'; nonce_prefix = nonce_prefix'
  
  fun ref apply(message: Message box): Array[U8] val =>
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
        command.data_box = try CryptoBox(message_box.string(), nonce, sk, pk) else
                             ""  // TODO: some way to protocol-error from here?
                           end
        output.append(CommandParser.write(command))
      end
    end
    
    output
