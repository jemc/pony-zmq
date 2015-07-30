
use "net"
use "collections"

type Frame is ReadSeq[U8] val

class Message val is Seq[Frame]
  let _inner: List[Frame] = _inner.create()
  new create(len: U64 = 0) => None
  
  fun size():            U64     => _inner.size()
  fun apply(i: U64 = 0): Frame ? => _inner.apply(i)
  
  fun ref reserve(len: U64):            Message ref^     => _inner.reserve(len); this
  fun ref clear():                      Message ref^     => _inner.clear(); this
  fun ref update(i: U64, value: Frame): (Frame^ | None)? => _inner.update(i, value)
  fun ref push(value: Frame):           Message ref^     => _inner.push(value); this
  fun ref pop():                        Frame^?          => _inner.pop()
  fun ref unshift(value: Frame):        Message ref^     => _inner.unshift(value); this
  fun ref shift():                      Frame^?          => _inner.shift()
  fun ref truncate(len: U64):           Message ref^     => _inner.truncate(len); this
  fun ref append(seq: ReadSeq[Frame],
       offset: U64 = 0, len: U64 = -1): Message ref^     => _inner.append(seq, offset, len); this
  
  fun nodes():   ListNodes[Frame, this->ListNode[Frame]]^  => _inner.nodes()
  fun rnodes():  ListNodes[Frame, this->ListNode[Frame]]^  => _inner.rnodes()
  fun values():  ListValues[Frame, this->ListNode[Frame]]^ => _inner.values()
  fun rvalues(): ListValues[Frame, this->ListNode[Frame]]^ => _inner.rvalues()

class MessageParser
  var _message: Message trn = recover Message end
  
  fun ref take_message(): Message trn^ =>
    """
    Transfer ownership of the current message to the caller and start a new one.
    """
    _message = recover Message end
  
  fun tag write(message: Message box): Array[U8] val =>
    let output = recover trn Array[U8] end
    let frame_count = message.size()
    
    for node in message.nodes() do
      let frame': (Frame | None) = try node() else None end
      let has_more = node.has_next()
      
      match frame' | let frame: Frame =>
        // Determine the ident and size bytewidth based on the size and more flag.
        let is_short  = frame.size() <= 0xFF
        let more:  U8 = if has_more then 0x01 else 0x00 end
        let ident: U8 = if is_short then 0x00 or more else 0x02 or more end
        let size      = if is_short then frame.size().u8() else frame.size() end
        
        // Write the ident, size, and the data byte array to the output byte array.
        output.push(ident)
        output.append(_Util.make_bytes(size))
        output.append(frame)
      end
    end
    
    output
  
  fun ref read(buffer: Buffer): (Bool, String) ? =>
    var has_more: Bool = true
    
    while has_more do
      var offset: U64 = 0
      
      // Peek ident byte to determine number of size bytes, then peek size.
      let ident = buffer.peek_u8(); offset = offset + 1
      let size = match ident
                 | 0x00 | 0x01 => offset = offset + 1; U64.from[U8](buffer.peek_u8(1))
                 | 0x02 | 0x03 => offset = offset + 8; buffer.peek_u64_be(1)
                 else
                   return (false, "unknown frame ident byte: " + ident.string(IntHex))
                 end
      
      // Raise error if not all bytes are available yet.
      if buffer.size() < (offset + size) then error end
      
      // Skip the bytes obtained by peeking.
      buffer.skip(consume offset)
      
      // Read the frame body and append it to the ongoing message.
      let frame = buffer.block(size)
      _message.push(consume frame)
      
      // Get has_more flag from ident byte
      has_more = (0 != (ident and 0x01))
    end
    
    (true, "")
