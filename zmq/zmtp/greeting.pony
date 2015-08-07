
primitive _Greeting
  fun write(mechanism: String = "NULL", as_server: Bool = false): Array[U8] val =>
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
  
  fun read(buffer: _Buffer ref, protocol_error: SessionHandleProtocolError): String? =>
    if buffer.size() < 64 then error end // try again later
    
    if buffer.u8() != 0xFF then protocol_error("signature-start"); error end
    buffer.skip(8) // signature-padding
    if buffer.u8() != 0x7F then protocol_error("signature-end"); error end
    
    let version = buffer.u8()
    if version <  0x03 then protocol_error("version-major: " + version.string()); error end
    buffer.skip(1) // version-minor
    
    let mechanism = String; mechanism.append(buffer.block(20)).strip(String.push(0))
    if mechanism != "NULL" then protocol_error("mechanism: " + mechanism); error end
    
    // TODO: reinstate as-server check
    buffer.skip(1) // as-server
    // let as_server = buffer.u8()
    // if as_server != 0x01 then protocol_error("as-server: " + as_server.string()); error end
    
    buffer.skip(31) // filler
    
    version.string()
