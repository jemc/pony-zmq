
use "collections"

type _Inspectable is Any box

primitive Inspect
  fun apply(input: _Inspectable): String val =>
    """
    Return a string with the inspect form of an object.
    The resulting string is intended for human readability and debugging,
    and is subject to change as necessary to improve future readability.
    """
    let output: String trn = recover String end
    
    match input
    | let x: Stringable box => output.append(x.string())
    | let x: String box =>
      output.push('"')
      let iter = x.values()
      try
        while iter.has_next() do
          let byte = iter.next()
          if byte < 0x10 then
            output.append("\\x0" + byte.string(IntHexBare))
          elseif byte < 0x20 then
            output.append("\\x" + byte.string(IntHexBare))
          elseif byte < 0x7F then
            output.push(byte)
          else
            output.append("\\x" + byte.string(IntHexBare))
          end
        end
      end
      output.push('"')
    | let x: Array[U8] box =>
      output.push('[')
      let iter = x.values()
      try
        while iter.has_next() do
          let byte = iter.next()
          if byte < 0x10 then
            output.append("0x0" + byte.string(IntHexBare))
          elseif byte < 0x20 then
            output.append("0x" + byte.string(IntHexBare))
          elseif byte < 0x7F then
            output.append("'")
            output.push(byte)
            output.append("'")
          else
            output.append("0x" + byte.string(IntHexBare) + " ")
          end
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
    else
      "<uninspectable>"
    end
    
    output
  
  fun print(string: String box) =>
    """
    Print a string (followed by a newline) to the STDOUT stream.
    This is for debugging purposes only, as it is not concurrency-safe.
    """
    _STDOUT.write_line(string)
  
  fun out(input: _Inspectable) =>
    """
    Print the inspect form of an object to the STDOUT stream.
    This is for debugging purposes only, as it is not concurrency-safe.
    """
    print(apply(input))
