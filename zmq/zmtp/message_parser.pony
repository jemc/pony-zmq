// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
use "format"

interface ref MessageWriteTransform
  fun ref apply(message: Message): Array[U8] val

class MessageWriter is MessageWriteTransform
  fun ref apply(message: Message box): Array[U8] val =>
    let output = recover trn Array[U8] end
    let frame_count = message.size()
    
    for node in message.nodes() do
      let frame': (Frame | None) = try node()? else None end
      let has_more = node.has_next()
      
      match frame' | let frame: Frame =>
        // Determine the ident and size bytewidth based on the size and more flag.
        let is_short  = frame.size() <= 0xFF
        let more:  U8 = if has_more then 0x01 else 0x00 end
        let ident: U8 = if is_short then 0x00 or more else 0x02 or more end
        let size      = if is_short then frame.size().u8() else frame.size() end
        
        // Write the ident, size, and the data byte array to the output byte array.
        output.push(ident)
        output.append(_Util.make_bytes(size))
        output.append(frame)
      end
    end
    
    output

class MessageParser
  var _message: Message trn = recover Message end
  
  fun ref read(buffer: _Buffer, notify: SessionNotify): Message trn^? =>
    var has_more: Bool = true
    
    while has_more do
      var offset: USize = 0
      
      // Peek ident byte to determine number of size bytes, then peek size.
      let ident = buffer.peek_u8()?; offset = offset + 1
      let size = match ident
                 | 0x00 | 0x01 => offset = offset + 1; USize.from[U8](buffer.peek_u8(1)?)
                 | 0x02 | 0x03 => offset = offset + 8; buffer.peek_u64_be(1)?.usize() // TODO: this breaks for 32-bit systems - we need a better solution
                 else
                   notify.protocol_error("unknown frame ident byte: " + Format.int[U8](ident, FormatHex))
                   error
                 end
      
      // Raise error if not all bytes are available yet.
      if buffer.size() < (offset + size) then error end
      
      // Skip the bytes obtained by peeking.
      buffer.skip(consume offset)?
      
      // Read the frame body and append it to the ongoing message.
      let frame = recover trn String end
      frame.append(buffer.block(size)?)
      _message.push(consume frame)
      
      // Get has_more flag from ident byte
      has_more = (0 != (ident and 0x01))
    end
    
    // Transfer ownership of the current message to the caller and start a new one.
    _message = recover Message end
  
  fun ref add_to_message(frame: Frame) =>
    _message.push(consume frame)
  
  fun ref take_message(): Message trn^ =>
    // Transfer ownership of the current message to the caller and start a new one.
    _message = recover Message end
