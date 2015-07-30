
use "ponytest"
use zmq = ".."

class SocketTest is UnitTest
  let _env: Env
  new iso create(env: Env) => _env = env
  fun name(): String => "zmq.Socket"
  
  fun apply(h: TestHelper): TestResult =>
    let ra = _SocketReactor; let a = zmq.Socket(zmq.PAIR, ra.notify())
    let rb = _SocketReactor; let b = zmq.Socket(zmq.PAIR, rb.notify())
    
    a.bind("tcp://localhost:8899")
    b.connect("tcp://localhost:8899")
    a.send_string("foo")
    b.send_string("bar")
    
    ra.next(recover lambda(h: TestHelper, s: zmq.Socket, m: zmq.Message) =>
      h.expect_eq[zmq.Message](m, recover zmq.Message.push("foo") end)
      s.dispose()
    end~apply(h,a) end)
    
    rb.next(recover lambda(h: TestHelper, s: zmq.Socket, m: zmq.Message) =>
      h.expect_eq[zmq.Message](m, recover zmq.Message.push("bar") end)
      s.dispose()
    end~apply(h,b) end)
    
    ra.when_closed(recover lambda(h: TestHelper, rb: _SocketReactor) =>
      rb.when_closed(recover lambda(h: TestHelper) =>
        h.complete(true)
      end~apply(h) end)
    end~apply(h,rb) end)
    
    LongTest
