
use "collections"
use "../inspect"
use zmq = ".."

interface _LambdaPartial iso
  fun ref apply() => None

interface _MessageLambdaPartial iso
  fun ref apply(message: zmq.Message) => None

interface _MessageListLambdaPartial iso
  fun ref apply(message: List[zmq.Message]) => None

type _SocketReactorHandler is
  ( _MessageLambdaPartial
  | (U64, _MessageListLambdaPartial))

actor _SocketReactor is zmq.SocketNotifiableActor
  let _messages: List[zmq.Message]           = _messages.create()
  let _handlers: List[_SocketReactorHandler] = _handlers.create()
  
  var _closed_handler: (_LambdaPartial | None) = None
  var _closed:             Bool = false
  var _ran_closed_handler: Bool = false
  
  fun tag notify(): zmq.SocketNotify^ =>
    zmq.SocketNotifyActor(this)
  
  be next(handler: _MessageLambdaPartial) =>
    _handlers.push(consume handler)
    maybe_run_handlers()
  
  be next_n(n: U64, handler: _MessageListLambdaPartial) =>
    _handlers.push((n, consume handler))
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
        match _handlers.shift()
        | let h: _MessageLambdaPartial =>
          (consume h)(_messages.shift())
        
        | (var n: U64, let h: _MessageListLambdaPartial) =>
          if _messages.size() < n then _handlers.unshift((n, consume h)); error end
          
          let list = List[zmq.Message]
          while n > 0 do
            n = n - 1
            list.push(_messages.shift())
          end
          (consume h)(list)
        end
      end
    end
  
  fun ref maybe_run_closed_handler() =>
    if _closed and not _ran_closed_handler then
      try
        (_closed_handler as _LambdaPartial).apply()
        _ran_closed_handler = true
      end
    end
