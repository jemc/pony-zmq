
use "collections"
use zmq = ".."

interface _LambdaPartial iso
  fun ref apply() => None

interface _MessageLambdaPartial iso
  fun ref apply(message: zmq.Message) => None

actor _SocketReactor is zmq.SocketNotifiableActor
  let _messages: List[zmq.Message]           = _messages.create()
  let _handlers: List[_MessageLambdaPartial] = _handlers.create()
  
  var _closed_handler: (_LambdaPartial | None) = None
  var _closed:             Bool = false
  var _ran_closed_handler: Bool = false
  
  fun tag notify(): zmq.SocketNotify^ =>
    zmq.SocketNotifyActor(this)
  
  be next(handler: _MessageLambdaPartial) =>
    _handlers.push(consume handler)
    maybe_run_handlers()
  
  be received(socket: zmq.Socket, peer: zmq.SocketPeer, message: zmq.Message) =>
    _messages.push(message)
    maybe_run_handlers()
  
  be when_closed(handler: _LambdaPartial) =>
    _closed_handler = consume handler
    maybe_run_closed_handler()
  
  be closed(socket: zmq.Socket) =>
    _closed = true
    maybe_run_closed_handler()
  
  fun ref maybe_run_handlers() =>
    try
      while (_handlers.size() > 0) and (_messages.size() > 0) do
        _handlers.shift()(_messages.shift())
      end
    end
  
  fun ref maybe_run_closed_handler() =>
    if _closed and not _ran_closed_handler then
      try
        (_closed_handler as _LambdaPartial).apply()
        _ran_closed_handler = true
      end
    end
