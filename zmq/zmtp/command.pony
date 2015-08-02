
use "net"
use "collections"

interface _Command
  fun name(): String val
  fun write_bytes(): Array[U8] val
  fun ref read_bytes(bytes: Array[U8] val)

class _CommandUtil
  fun tag read_bytes_as_metadata(metadata: Map[String, String], bytes: Array[U8] val) =>
    let buffer = Buffer.append(bytes)
    if metadata.size() > 0 then metadata.clear() end
    
    while buffer.size() > 0 do
      try
        let key   = recover iso String end
        let value = recover iso String end
        
        let key_size = U64.from[U8](buffer.u8())
        key.append(buffer.block(key_size))
        let value_size = U64.from[U32](buffer.u32_be())
        value.append(buffer.block(value_size))
        
        metadata.update(consume key, consume value)
      end
    end
  
  fun tag write_bytes_as_metadata(metadata: Map[String, String] box): Array[U8] val =>
    let output = recover trn Array[U8] end
    
    for (key, value) in metadata.pairs() do
      output.push(key.size().u8())
      output.append(key)
      output.append(_Util.make_bytes(value.size().u32()))
      output.append(value)
    end
    
    output

class _CommandUnknown is _Command
  var bytes: Array[U8] val = recover Array[U8] end
  fun name(): String => ""
  fun write_bytes(): Array[U8] val          => bytes
  fun ref read_bytes(bytes': Array[U8] val) => bytes = bytes'

class _CommandAuthNullReady is _Command
  let metadata: Map[String, String] = Map[String, String]
  new create() => None // TODO: figure out why ponyc default constructors are now iso as of 718c37398270b1a9fafa85a7ba2af286f4d53a5f
  fun name(): String => "READY"
  fun write_bytes(): Array[U8] val         => _CommandUtil.write_bytes_as_metadata(metadata)
  fun ref read_bytes(bytes: Array[U8] val) => _CommandUtil.read_bytes_as_metadata(metadata, bytes)

primitive _CommandParser
  fun write(command: _Command box): Array[U8] val =>
    let output = recover trn Array[U8] end
    let inner = recover trn Array[U8] end
    
    // Write name size, name, and body to inner byte array.
    let name = command.name()
    inner.push(name.size().u8())
    inner.append(name)
    inner.append(command.write_bytes())
    
    // Determine the ident and size bytewidth based on the size itself.
    let is_short = inner.size() <= 0xFF
    let ident: U8 = if is_short then 0x04 else 0x06 end
    let size      = if is_short then inner.size().u8() else inner.size() end
    
    // Write the ident, size, and the inner byte array to the output byte array.
    output.push(ident)
    output.append(_Util.make_bytes(size))
    output.append(inner)
    
    output
  
  fun read(command: _Command, buffer: Buffer): (Bool, String) ? =>
    var offset: U64 = 0
    
    // Peek ident byte to determine number of size bytes, then peek size.
    let ident = buffer.peek_u8(); offset = offset + 1
    let size = match ident
               | 0x04 => offset = offset + 1; U64.from[U8](buffer.peek_u8(1))
               | 0x06 => offset = offset + 8; buffer.peek_u64_be(1)
               else
                 return (false, "unknown command ident byte: " + ident.string(IntHex))
               end
    
    // Raise error if not all bytes are available yet.
    if buffer.size() < (offset + size) then error end
    
    // Skip the bytes obtained by peeking.
    buffer.skip(consume offset)
    
    // Read the name size and name string.
    let name_size = U64.from[U8](buffer.u8())
    let name: String trn = recover String end
    name.append(buffer.block(name_size))
    
    // Read the rest of the body.
    let body: Array[U8] val = buffer.block(size - 1 - name_size)
    
    // Compare to the given command's name
    if name != command.name() then return (false, consume name) end
    
    // Apply the body to the given command's name and return success
    command.read_bytes(body)
    (true, consume name)
