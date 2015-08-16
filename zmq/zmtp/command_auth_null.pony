// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use "collections"

class CommandAuthNullReady is Command
  let metadata: CommandMetadata = metadata.create()
  fun name(): String => "READY"
  fun bytes(): Array[U8] val => CommandUtil.write_bytes_as_metadata(metadata)
  new create() => None // TODO: figure out why ponyc default constructors are now iso as of 718c37398270b1a9fafa85a7ba2af286f4d53a5f
  fun ref apply(orig: CommandUnknown)? =>
    if orig.name() != name() then error end
    CommandUtil.read_bytes_as_metadata(metadata, orig.bytes())
