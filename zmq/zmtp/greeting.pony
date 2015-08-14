
primitive Greeting
  fun write(mechanism: String, as_server: Bool): Array[U8] val =>
    let output: Array[U8] trn = recover Array[U8] end
    
    output.append(recover [as U8:
      0xFF, // signature-start
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // signature-padding
      0x7F, // signature-end
      0x03, 0x00 // version(major, minor)
    ] end)
    
    for byte in mechanism.values() do output.push(byte) end
    output.append(recover Array[U8].init(0x00, 20 - mechanism.size()) end)
    
    output.push(if as_server then 0x01 else 0x00 end)
    
    output.append(recover [as U8:
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // filler
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // filler
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // filler
      0x00 // filler
    ] end)
    
    output
  
  fun read(buffer: _Buffer ref, protocol_error: SessionHandleProtocolError,
    mechanism: String, as_server: Bool
  ): String? =>
    if buffer.size() < 64 then error end // try again later
    
    if buffer.u8() != 0xFF then protocol_error("signature-start"); error end
    buffer.skip(8) // signature-padding
    if buffer.u8() != 0x7F then protocol_error("signature-end"); error end
    
    let version = buffer.u8()
    if version <  0x03 then
      protocol_error("version-major: " + version.string())
      error
    end
    buffer.skip(1) // version-minor
    
    let other_mechanism = String
    other_mechanism.append(buffer.block(20)).strip(String.push(0))
    if mechanism != other_mechanism then
      protocol_error("other mechanism: " + mechanism)
      error
    end
    
    // TODO: reinstate as-server check here
    buffer.skip(1) // as-server
    // let other_as_server: Bool = buffer.u8() != 0x00
    // if (mechanism != "NULL") and (as_server is other_as_server) then
    //   protocol_error("other as-server: " + as_server.string())
    //   error
    // end
    
    buffer.skip(31) // filler
    
    version.string()
