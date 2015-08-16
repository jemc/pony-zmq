
use "../../../pony-sodium/sodium"

class _NonceGenerator
  var _next_short: U64 = 1
  
  new iso create() => None
  
  fun ref next_short(): String =>
    let out = recover trn String end
    out.push((_next_short >> 56).u8())
    out.push((_next_short >> 48).u8())
    out.push((_next_short >> 40).u8())
    out.push((_next_short >> 32).u8())
    out.push((_next_short >> 24).u8())
    out.push((_next_short >> 16).u8())
    out.push((_next_short >>  8).u8())
    out.push((_next_short >>  0).u8())
    _next_short = _next_short + 1 // TODO: reconnect on overflow
    consume out
  
  fun tag next_long(): String =>
    recover CryptoBox.random_bytes(16) end
