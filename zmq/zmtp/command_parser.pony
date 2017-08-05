// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
use "format"

primitive CommandParser
  fun write(command: Command box): Array[U8] val =>
    let output = recover trn Array[U8] end
    let inner = recover trn Array[U8] end
    
    // Write name size, name, and body to inner byte array.
    let name = command.name()
    inner.push(name.size().u8())
    inner.append(name)
    inner.append(command.bytes())
    
    // Determine the ident and size bytewidth based on the size itself.
    let is_short = inner.size() <= 0xFF
    let ident: U8 = if is_short then 0x04 else 0x06 end
    let size      = if is_short then inner.size().u8() else inner.size().u64() end
    
    // Write the ident, size, and the inner byte array to the output byte array.
    output.push(ident)
    output.append(_Util.make_bytes(size))
    output.append(consume inner)
    
    output
  
  fun read(buffer: _Buffer, notify: SessionNotify): CommandUnknown? =>
    var offset: USize = 0
    
    // Peek ident byte to determine number of size bytes, then peek size.
    let ident = buffer.peek_u8()?; offset = offset + 1
    let size = match ident
               | 0x04 => offset = offset + 1; USize.from[U8](buffer.peek_u8(1)?)
               | 0x06 => offset = offset + 8; buffer.peek_u64_be(1)?.usize() // TODO: this breaks for 32-bit systems - we need a better solution
               // Note that the following are not actually allowed by spec,
               // but they are used by the libzmq implementation for
               // CURVE MESSAGE commands, so we have to accept them for interop.
               | 0x00 => offset = offset + 1; USize.from[U8](buffer.peek_u8(1)?)
               | 0x01 => offset = offset + 1; USize.from[U8](buffer.peek_u8(1)?)
               | 0x02 => offset = offset + 8; buffer.peek_u64_be(1)?.usize() // TODO: this breaks for 32-bit systems - we need a better solution
               | 0x03 => offset = offset + 8; buffer.peek_u64_be(1)?.usize() // TODO: this breaks for 32-bit systems - we need a better solution
               else
                 notify.protocol_error("unknown command ident byte: " + Format.int[U8](ident, FormatHex))
                 error
               end
    
    // Raise error if not all bytes are available yet.
    if buffer.size() < (offset + size) then error end
    
    // Skip the bytes obtained by peeking.
    buffer.skip(consume offset)?
    
    // Read the name size and name string.
    let name_size = USize.from[U8](buffer.u8()?)
    let name: String trn = recover String end
    name.append(buffer.block(name_size)?)
    
    // Read the rest of the body.
    let bytes: Array[U8] val = buffer.block(size - 1 - name_size)?
    
    CommandUnknown(consume name, consume bytes)
