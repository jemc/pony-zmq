
use "collections"

class _CommandAuthNullReady is _Command
  let metadata: Map[String, String] = Map[String, String]
  fun name(): String => "READY"
  fun bytes(): Array[U8] val => _CommandUtil.write_bytes_as_metadata(metadata)
  new create() => None // TODO: figure out why ponyc default constructors are now iso as of 718c37398270b1a9fafa85a7ba2af286f4d53a5f
  fun ref apply(orig: _CommandUnknown)? =>
    if orig.name() != name() then error end
    _CommandUtil.read_bytes_as_metadata(metadata, orig.bytes())
