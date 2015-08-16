
use "collections"
use "../../../pony-sodium/sodium"

class CommandAuthCurveHello is Command
  var version_major: U8 = 1
  var version_minor: U8 = 0
  var tpkc: CryptoBoxPublicKey = CryptoBoxPublicKey("")
  var short_nonce: String = ""
  var signature_box: String = ""
  
  new create() => None
  fun name(): String => "HELLO"
  
  fun bytes(): Array[U8] val =>
    let output = recover trn Array[U8] end
    output.push(version_major)
    output.push(version_minor)
    output.append(recover [as U8: 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                                  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                                  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                                  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0] end)
    output.append(tpkc.string())
    output.append(short_nonce)
    output.append(signature_box)
    output
  
  fun ref apply(orig: CommandUnknown)? =>
    if orig.name() != name() then error end
    let orig_bytes = orig.bytes()
    let buffer = recover iso _Buffer.append(orig_bytes) end
    
    version_major = buffer.u8()
    version_minor = buffer.u8()
    buffer.skip(72) // anti-amplification padding
    tpkc = CryptoBoxPublicKey(recover String.append(buffer.block(32)) end)
    short_nonce = recover String.append(buffer.block(8)) end
    signature_box = recover String.append(buffer.block(80)) end

class CommandAuthCurveWelcome is Command
  var long_nonce: String = ""
  var data_box: String = ""
  
  new create() => None
  fun name(): String => "WELCOME"
  
  fun bytes(): Array[U8] val =>
    let output = recover trn Array[U8] end
    output.append(long_nonce)
    output.append(data_box)
    output
  
  fun ref apply(orig: CommandUnknown)? =>
    if orig.name() != name() then error end
    let orig_bytes = orig.bytes()
    let buffer = recover iso _Buffer.append(orig_bytes) end
    
    long_nonce = recover String.append(buffer.block(16)) end
    data_box = recover String.append(buffer.block(144)) end

class CommandAuthCurveInitiate is Command
  var cookie: String = ""
  var short_nonce: String = ""
  var data_box: String = ""
  
  new create() => None
  fun name(): String => "INITIATE"
  
  fun bytes(): Array[U8] val =>
    let output = recover trn Array[U8] end
    output.append(cookie)
    output.append(short_nonce)
    output.append(data_box)
    output
  
  fun ref apply(orig: CommandUnknown)? =>
    if orig.name() != name() then error end
    let orig_bytes = orig.bytes()
    let buffer = recover iso _Buffer.append(orig_bytes) end
    
    cookie = recover String.append(buffer.block(96)) end
    short_nonce = recover String.append(buffer.block(8)) end
    data_box = recover String.append(buffer.block(buffer.size())) end

class CommandAuthCurveReady is Command
  var short_nonce: String = ""
  var data_box: String = ""
  
  new create() => None
  fun name(): String => "READY"
  
  fun bytes(): Array[U8] val =>
    let output = recover trn Array[U8] end
    output.append(short_nonce)
    output.append(data_box)
    output
  
  fun ref apply(orig: CommandUnknown)? =>
    if orig.name() != name() then error end
    let orig_bytes = orig.bytes()
    let buffer = recover iso _Buffer.append(orig_bytes) end
    
    short_nonce = recover String.append(buffer.block(8)) end
    data_box = recover String.append(buffer.block(buffer.size())) end

class CommandAuthCurveError is Command
  var reason: String = ""
  
  new create() => None
  fun name(): String => "ERROR"
  
  fun bytes(): Array[U8] val =>
    let output = recover trn Array[U8] end
    output.append(reason)
    output
  
  fun ref apply(orig: CommandUnknown)? =>
    if orig.name() != name() then error end
    let orig_bytes = orig.bytes()
    reason = recover String.append(orig_bytes) end

class CommandAuthCurveMessage is Command
  var short_nonce: String = ""
  var data_box: String = ""
  
  new create() => None
  fun name(): String => "MESSAGE"
  
  fun bytes(): Array[U8] val =>
    let output = recover trn Array[U8] end
    output.append(short_nonce)
    output.append(data_box)
    output
  
  fun ref apply(orig: CommandUnknown)? =>
    if orig.name() != name() then error end
    let orig_bytes = orig.bytes()
    let buffer = recover iso _Buffer.append(orig_bytes) end
    
    short_nonce = recover String.append(buffer.block(8)) end
    data_box = recover String.append(buffer.block(buffer.size())) end

///
// Encrypted boxes inside of Commands

class CommandAuthCurveWelcomeBox
  var tpks: CryptoBoxPublicKey = CryptoBoxPublicKey("")
  var cookie: String = ""
  
  fun string(): String =>
    let output = recover trn String end
    output.append(tpks.string())
    output.append(cookie)
    output
  
  fun ref apply(data: String): CommandAuthCurveWelcomeBox =>
    tpks = CryptoBoxPublicKey(data.substring(0, 31))
    cookie = data.substring(32, -1)
    this

class CommandAuthCurveInitiateBox
  var pkc: CryptoBoxPublicKey = CryptoBoxPublicKey("")
  var long_nonce: String = ""
  var vouch_box: String = ""
  let metadata: CommandMetadata = metadata.create()
  
  fun string(): String =>
    let output = recover trn String end
    output.append(pkc.string())
    output.append(long_nonce)
    output.append(vouch_box)
    output.append(CommandUtil.write_bytes_as_metadata(metadata))
    output
  
  fun ref apply(data: String): CommandAuthCurveInitiateBox =>
    pkc = CryptoBoxPublicKey(data.substring(0, 31))
    long_nonce = data.substring(32, 47)
    vouch_box = data.substring(48, 127)
    CommandUtil.read_string_as_metadata(metadata, data.substring(128, -1))
    this

class CommandAuthCurveInitiateVouchBox
  var tpkc: CryptoBoxPublicKey = CryptoBoxPublicKey("")
  var pks: CryptoBoxPublicKey = CryptoBoxPublicKey("")
  
  fun string(): String =>
    let output = recover trn String end
    output.append(tpkc.string())
    output.append(pks.string())
    output
  
  fun ref apply(data: String): CommandAuthCurveInitiateVouchBox =>
    tpkc = CryptoBoxPublicKey(data.substring(0, 31))
    pks = CryptoBoxPublicKey(data.substring(32, 63))
    this

class CommandAuthCurveReadyBox
  let metadata: CommandMetadata = metadata.create()
  
  fun string(): String =>
    let output = recover trn String end
    output.append(CommandUtil.write_bytes_as_metadata(metadata))
    output
  
  fun ref apply(data: String): CommandAuthCurveReadyBox =>
    CommandUtil.read_string_as_metadata(metadata, data)
    this

class CommandAuthCurveMessageBox
  var has_more: Bool = false
  var payload: Frame = ""
  
  fun string(): String =>
    let output = recover trn String end
    let flags: U8 = if has_more then 0x01 else 0x00 end
    output.push(flags)
    output.append(payload)
    output
  
  fun ref apply(data: String): CommandAuthCurveMessageBox =>
    let flags = try data(0) else 0x00 end
    has_more = flags != 0x00
    payload = data.substring(1, -1)
    this
