
primitive _STDOUT
  """
  Give global access to the STDOUT stream (private to this package).
  This is for debugging purposes only, as it is not concurrency-safe.
  """
  fun write(data: _STDOUTable) =>
    @os_std_write[None](@os_stdout[Pointer[U8]](), data.cstring(), data.size())
  
  fun write_line(data: _STDOUTable) =>
    write(data)
    write("\n")

interface _STDOUTable box
  """
  Any object that can provide a cstring and size to pass to the OS.
  """
  fun cstring(): Pointer[U8] tag
  fun size(): U64
