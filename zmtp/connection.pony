
use "net"
use "collections"
use "../inspect"

primitive _ConnectionStateReadGreeting
primitive _ConnectionStateReadHandshakeReady
primitive _ConnectionStateReadMessage

type _ConnectionState is
  ( _ConnectionStateReadGreeting
  | _ConnectionStateReadMessage
  | _ConnectionStateReadHandshakeReady)

class _ClientConnection is TCPConnectionNotify
  let _parent: Client tag
  let _buffer: Buffer = Buffer
  
  var _state: _ConnectionState = _ConnectionStateReadGreeting
  var _command: _Command = _CommandUnknown
  
  new iso create(parent: Client) =>
    _parent = parent
  
  fun ref next_state(state: _ConnectionState) =>
    _state = state
  
  fun ref _read_greeting(conn: TCPConnection ref) =>
    try
      (let success, let string) = _Greeting.read(_buffer)
      if success then
        next_state(_ConnectionStateReadHandshakeReady)
      else
        _protocol_error(conn, string)
      end
    end
  
  fun ref _read_command(conn: TCPConnection ref) =>
    try
      _command = _CommandAuthNullReady
      (let success, let string) = _CommandParser.read(_command, _buffer)
      if success then
        Inspect.print("command name " + Inspect(_command.name()))
        try
          let c = _command as _CommandAuthNullReady
          Inspect.print("command metadata " + Inspect(c.metadata))
        end
        next_state(_ConnectionStateReadMessage)
      else
        _protocol_error(conn, string)
      end
    end
  
  fun ref _protocol_error(conn: TCPConnection ref, message: String val) =>
    Inspect.print("protocol_error " + message)
    conn.close()
    next_state(_ConnectionStateReadGreeting)
  
  fun ref accepted(conn: TCPConnection ref) =>
    Inspect.print("accepted!")
  
  fun ref connected(conn: TCPConnection ref) =>
    Inspect.print("connected!")
    conn.write(_Greeting.write())
    Inspect.print("greeted!")
  
  fun ref connect_failed(conn: TCPConnection ref) =>
    Inspect.print("connect_failed!")
  
  fun ref closed(conn: TCPConnection ref) =>
    Inspect.print("closed!")
  
  fun ref received(conn: TCPConnection ref, data: Array[U8] iso) =>
    match _state
    | _ConnectionStateReadGreeting       => _buffer.append(consume data); _read_greeting(conn)
    | _ConnectionStateReadHandshakeReady => _buffer.append(consume data); _read_command(conn)
    else
      let data_ref: Array[U8] ref = (consume data)
      Inspect.print("received " + Inspect(data_ref))
    end
