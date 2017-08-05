
use "collections"
use zmq = ".."

interface val _Handler
  fun val apply()

interface val _MessageHandler
  fun val apply(message: zmq.Message)

interface val _PeerMessageHandler
  fun val apply(peer: zmq.SocketPeer, message: zmq.Message)

interface val _MessageListHandler
  fun val apply(message: List[zmq.Message])

type _SocketReactorHandler is
  ( _MessageHandler
  | _PeerMessageHandler
  | (USize, _MessageListHandler))

actor _SocketReactor is zmq.SocketNotifiableActor
  let _messages: List[(zmq.SocketPeer, zmq.Message)] = _messages.create()
  let _handlers: List[_SocketReactorHandler]         = _handlers.create()
  
  var _closed_handler: (_Handler | None) = None
  var _closed:             Bool = false
  var _ran_closed_handler: Bool = false
  
  fun tag notify(): zmq.SocketNotify^ =>
    zmq.SocketNotifyActor(this)
  
  be next(handler: (_MessageHandler | _PeerMessageHandler)) =>
    _handlers.push(consume handler)
    maybe_run_handlers()
  
  be next_n(n: USize, handler: _MessageListHandler) =>
    _handlers.push((n, consume handler))
    maybe_run_handlers()
  
  be received(socket: zmq.Socket, peer: zmq.SocketPeer, message: zmq.Message) =>
    _messages.push((peer, message))
    maybe_run_handlers()
  
  be when_closed(handler: _Handler) =>
    _closed_handler = consume handler
    maybe_run_closed_handler()
  
  be closed(socket: zmq.Socket) =>
    _closed = true
    maybe_run_closed_handler()
  
  fun ref maybe_run_handlers() =>
    try
      while (_handlers.size() > 0) and (_messages.size() > 0) do
        match _handlers.shift()?
        | let h: _MessageHandler =>
          (let peer, let message) = _messages.shift()?
          (consume h)(message)
        
        | let h: _PeerMessageHandler =>
          (let peer, let message) = _messages.shift()?
          (consume h)(peer, message)
        
        | (let n': USize, let h: _MessageListHandler) =>
          var n = n'
          if _messages.size() < n then _handlers.unshift((n, consume h)); error end
          
          let list = List[zmq.Message]
          while n > 0 do
            n = n - 1
            (let peer, let message) = _messages.shift()?
            list.push(message)
          end
          (consume h)(list)
        end
      end
    end
  
  fun ref maybe_run_closed_handler() =>
    if _closed and not _ran_closed_handler then
      match (_closed_handler = None) | let closed_handler: _Handler =>
        (consume closed_handler)()
        _ran_closed_handler = true
      end
    end
