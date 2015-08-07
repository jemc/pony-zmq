
use "collections"
use "../inspect"


interface _Command
  fun name(): String val
  fun bytes(): Array[U8] val

class _CommandUtil
  fun tag read_bytes_as_metadata(metadata: Map[String, String], bytes: Array[U8] val) =>
    let buffer = _Buffer.append(bytes)
    if metadata.size() > 0 then metadata.clear() end
    
    while buffer.size() > 0 do
      try
        let key   = recover iso String end
        let value = recover iso String end
        
        let key_size = U64.from[U8](buffer.u8())
        key.append(buffer.block(key_size))
        let value_size = U64.from[U32](buffer.u32_be())
        value.append(buffer.block(value_size))
        
        metadata(consume key) = consume value
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
  let _name: String
  let _bytes: Array[U8] val
  fun name(): String => _name
  fun bytes(): Array[U8] val => _bytes
  new create(name': String, bytes': Array[U8] val) =>
    _name = name'
    _bytes = bytes'

class _CommandAuthNullReady is _Command
  let metadata: Map[String, String] = Map[String, String]
  fun name(): String => "READY"
  fun bytes(): Array[U8] val => _CommandUtil.write_bytes_as_metadata(metadata)
  new create() => None // TODO: figure out why ponyc default constructors are now iso as of 718c37398270b1a9fafa85a7ba2af286f4d53a5f
  fun ref apply(orig: _CommandUnknown): _CommandAuthNullReady^? =>
    if orig.name() != name() then error end
    _CommandUtil.read_bytes_as_metadata(metadata, orig.bytes())
    this
