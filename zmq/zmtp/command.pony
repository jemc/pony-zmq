// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use "collections"

interface Command
  new ref create()
  fun name(): String val
  fun bytes(): Array[U8] val
  fun ref apply(orig: CommandUnknown)?

type CommandMetadata is Map[String, String]

class CommandUtil
  fun tag read_string_as_metadata(metadata: CommandMetadata, string: String) =>
    let bytes = recover trn Array[U8] end
    for byte in string.values() do
      bytes.push(byte)
    end
    read_bytes_as_metadata(metadata, consume bytes)
  
  fun tag write_string_as_metadata(metadata: CommandMetadata box): String =>
    let bytes = write_bytes_as_metadata(metadata)
    recover val String.>append(bytes) end
  
  fun tag read_bytes_as_metadata(metadata: CommandMetadata, bytes: Array[U8] val) =>
    let buffer = _Buffer.>append(bytes)
    if metadata.size() > 0 then metadata.clear() end
    
    while buffer.size() > 0 do
      try
        let key   = recover iso String end
        let value = recover iso String end
        
        let key_size = USize.from[U8](buffer.u8()?)
        key.append(buffer.block(key_size)?)
        let value_size = USize.from[U32](buffer.u32_be()?)
        value.append(buffer.block(value_size)?)
        
        metadata(consume key) = consume value
      end
    end
  
  fun tag write_bytes_as_metadata(metadata: CommandMetadata box): Array[U8] val =>
    let output = recover trn Array[U8] end
    
    for (key, value) in metadata.pairs() do
      output.push(key.size().u8())
      output.append(key)
      output.append(_Util.make_bytes(value.size().u32()))
      output.append(value)
    end
    
    output

class CommandUnknown
  let _name: String
  let _bytes: Array[U8] val
  fun name(): String => _name
  fun bytes(): Array[U8] val => _bytes
  new create(name': String, bytes': Array[U8] val) =>
    _name = name'
    _bytes = bytes'
