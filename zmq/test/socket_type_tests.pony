
use "ponytest"
use zmq = ".."

primitive SocketTypeTests is TestList
  fun tag tests(test: PonyTest) =>
    test(SocketTypeTestPairPair)

interface SocketTypeTest is UnitTest
  fun tag recv(h: TestHelper, rs: _SocketReactor, s: zmq.Socket, m': zmq.Message) =>
    rs.next(recover this~_recv_lambda(h, s, m') end)
  
  fun tag recv_last(h: TestHelper, rs: _SocketReactor, s: zmq.Socket, m': zmq.Message) =>
    rs.next(recover this~_recv_last_lambda(h, s, m') end)
  
  fun tag _recv_lambda(h: TestHelper, s: zmq.Socket, m': zmq.Message, m: zmq.Message) =>
    h.expect_eq[zmq.Message](m, m')
  
  fun tag _recv_last_lambda(h: TestHelper, s: zmq.Socket, m': zmq.Message, m: zmq.Message) =>
    h.expect_eq[zmq.Message](m, m')
    s.dispose()
  
  fun tag wait_2_reactors(h: TestHelper, ra: _SocketReactor, rb: _SocketReactor): LongTest =>
    ra.when_closed(recover lambda(h: TestHelper, rb: _SocketReactor) =>
      rb.when_closed(recover lambda(h: TestHelper) =>
        h.complete(true)
      end~apply(h) end)
    end~apply(h,rb) end)
    
    LongTest

class SocketTypeTestPairPair is SocketTypeTest
  new iso create() => None
  fun name(): String => "zmq.Socket (type: PAIR/PAIR)"
  
  fun apply(h: TestHelper): TestResult =>
    let ctx = zmq.Context
    let ra = _SocketReactor; let a = ctx.socket(zmq.PAIR, ra.notify())
    let rb = _SocketReactor; let b = ctx.socket(zmq.PAIR, rb.notify())
    
    a.bind("inproc://" + name())
    b.connect("inproc://" + name())
    
    a.send(recover zmq.Message.push("b1") end)
    a.send(recover zmq.Message.push("b2") end)
    a.send(recover zmq.Message.push("b3") end)
    
    b.send(recover zmq.Message.push("a1") end)
    b.send(recover zmq.Message.push("a2") end)
    b.send(recover zmq.Message.push("a3") end)
    
    recv(h,      ra, a, recover zmq.Message.push("a1") end)
    recv(h,      ra, a, recover zmq.Message.push("a2") end)
    recv_last(h, ra, a, recover zmq.Message.push("a3") end)
    
    recv(h,      rb, b, recover zmq.Message.push("b1") end)
    recv(h,      rb, b, recover zmq.Message.push("b2") end)
    recv_last(h, rb, b, recover zmq.Message.push("b3") end)
    
    wait_2_reactors(h, ra, rb)
