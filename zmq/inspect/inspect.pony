
use net = "net"
use "collections"

type _Inspectable is Any box

interface _StringableNoArg
  fun string(): String

primitive Inspect
  fun apply(input: _Inspectable): String val =>
    """
    Return a string with the inspect form of an object.
    The resulting string is intended for human readability and debugging,
    and is subject to change as necessary to improve future readability.
    """
    let output: String trn = recover String end
    
    match input
    | let x: String box =>
      output.push('"')
      let iter = x.values()
      try
        while iter.has_next() do
          let byte = iter.next()
          if byte < 0x10 then
            output.append("\\x0" + byte.string(FormatHexBare))
          elseif byte < 0x20 then
            output.append("\\x" + byte.string(FormatHexBare))
          elseif byte < 0x7F then
            output.push(byte)
          else
            output.append("\\x" + byte.string(FormatHexBare))
          end
        end
      end
      output.push('"')
    | let x: ReadSeq[U8] box =>
      output.push('[')
      let iter = x.values()
      try
        while iter.has_next() do
          let byte = iter.next()
          if byte < 0x10 then
            output.append("0x0" + byte.string(FormatHexBare))
          elseif byte < 0x20 then
            output.append("0x" + byte.string(FormatHexBare))
          elseif byte < 0x7F then
            output.append(" '")
            output.push(byte)
            output.append("'")
          else
            output.append("0x" + byte.string(FormatHexBare))
          end
          if iter.has_next() then output.append(", ") end
        end
      end
      output.push(']')
    | let x: ReadSeq[ReadSeq[U8]] box =>
      output.push('[')
      let iter = x.values()
      try
        while iter.has_next() do
          output.append(apply(iter.next()))
          if iter.has_next() then output.append(", ") end
        end
      end
      output.push(']')
    | let x: Map[String, _Inspectable] box =>
      output.push('{')
      let iter = x.pairs()
      try
        while iter.has_next() do
          (let key, let value) = iter.next()
          output.append(Inspect(key))
          output.push(':')
          output.append(Inspect(value))
          if iter.has_next() then
            output.append(", ")
          end
        end
      end
      output.push('}')
    | let x: Stringable box       => output.append(x.string())
    | let x: _StringableNoArg box => output.append(x.string())
    | let x: net.Buffer box =>
      let ary = Array[U8]
      for i in Range(0, x.size()) do
        ary.push(try x.peek_u8(i) else 0 end)
      end
      output.append(apply(ary))
    else
      return "<uninspectable>"
    end
    
    output
  
  fun print(string: String box) =>
    """
    Print a string (followed by a newline) to the STDOUT stream.
    This is for debugging purposes only, as it is not concurrency-safe.
    """
    _STDOUT.write_line(string)
  
  fun out(input: _Inspectable, input2: _Inspectable = None,
          input3: _Inspectable = None, input4: _Inspectable = None) =>
    """
    Print the inspect form of an object to the STDOUT stream.
    This is for debugging purposes only, as it is not concurrency-safe.
    """
    if input4 isnt None then
      print(apply(input) + ", " + apply(input2) + ", " + apply(input3) + ", " + apply(input4))
    elseif input3 isnt None then
      print(apply(input) + ", " + apply(input2) + ", " + apply(input3))
    elseif input2 isnt None then
      print(apply(input) + ", " + apply(input2))
    else
      print(apply(input))
    end
