// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

primitive Z85
  // Maps base 256 to base 85
  fun tag encode_table(): Array[U8] val => recover [as U8:
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
    'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't',
    'u', 'v', 'w', 'x', 'y', 'z', 'A', 'B', 'C', 'D',
    'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
    'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
    'Y', 'Z', '.', '-', ':', '+', '=', '^', '!', '/',
    '*', '?', '&', '<', '>', '(', ')', '[', ']', '{',
    '}', '@', '%', '$', '#'
  ] end
  
  // Maps base 85 to base 256 (over a partial range starting with 33 at idx 0)
  fun tag decode_table(): Array[(U8 | None)] val => recover [as (U8 | None):
    None, 0x44, None, 0x54, 0x53, 0x52, 0x48, None, 
    0x4B, 0x4C, 0x46, 0x41, None, 0x3F, 0x3E, 0x45, 
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 
    0x08, 0x09, 0x40, None, 0x49, 0x42, 0x4A, 0x47, 
    0x51, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 
    0x2B, 0x2C, 0x2D, 0x2E, 0x2F, 0x30, 0x31, 0x32, 
    0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 
    0x3B, 0x3C, 0x3D, 0x4D, None, 0x4E, 0x43, None, 
    None, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10, 
    0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 
    0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F, 0x20, 
    0x21, 0x22, 0x23, 0x4F, None, 0x50, None, None
  ] end
  
  fun tag encode(input: ReadSeq[U8]): String? =>
    if (input.size() % 4) != 0 then error end
    
    let table = encode_table()
    var output = recover trn String end
    
    var u32: U32 = 0
    var idx: U8 = 0
    for byte in input.values() do
      u32 = (u32 << 8) + byte.u32()
      if idx == 3 then
        output.push(table(((u32 / 52200625) % 85).usize()))
        output.push(table(((u32 /   614125) % 85).usize()))
        output.push(table(((u32 /     7225) % 85).usize()))
        output.push(table(((u32 /       85) % 85).usize()))
        output.push(table(((u32           ) % 85).usize()))
      u32 = 0 end
    idx = (idx + 1) % 4 end
    
    output
  
  fun tag decode(input: ReadSeq[U8]): String? =>
    if (input.size() % 5) != 0 then error end
    
    let table = decode_table()
    var output = recover trn String end
    
    var u32: U32 = 0
    var idx: U8 = 0
    for byte in input.values() do
      u32 = (u32 * 85) + (table(byte.usize() - 32) as U8).u32()
      if idx == 4 then
        output.push((u32 >> 24).u8())
        output.push((u32 >> 16).u8())
        output.push((u32 >>  8).u8())
        output.push((u32      ).u8())
      u32 = 0 end
    idx = (idx + 1) % 5 end
    
    output
