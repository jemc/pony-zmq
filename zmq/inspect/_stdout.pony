
primitive _STDOUT
  """
  Give global access to the STDOUT stream (private to this package).
  This is for debugging purposes only, as it is not concurrency-safe.
  """
  fun write(data: String box) =>
    @os_std_write[None](@os_stdout[Pointer[U8]](), data.cstring(), data.size())
  
  fun write_line(data: String box) =>
    write(data + "\n")
