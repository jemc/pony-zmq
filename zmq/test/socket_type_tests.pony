
use "ponytest"
use zmq = ".."

primitive SocketTypeTests is TestList
  fun tag tests(test: PonyTest) =>
    test(SocketTypeTestPairPair)
    test(SocketTypeTestPushNPull)

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
  
  fun tag wait_3_reactors(h: TestHelper, ra: _SocketReactor, rb: _SocketReactor, rc: _SocketReactor): LongTest =>
    ra.when_closed(recover lambda(h: TestHelper, rb: _SocketReactor, rc: _SocketReactor) =>
      rb.when_closed(recover lambda(h: TestHelper, rc: _SocketReactor) =>
        rc.when_closed(recover lambda(h: TestHelper) =>
          h.complete(true)
        end~apply(h) end)
      end~apply(h,rc) end)
    end~apply(h,rb,rc) end)
    
    LongTest

class SocketTypeTestPairPair is SocketTypeTest
  new iso create() => None
  fun name(): String => "zmq.Socket (type: 1-PAIR <-> 1-PAIR)"
  
  fun apply(h: TestHelper): TestResult =>
    let ctx = zmq.Context
    let ra = _SocketReactor; let a = ctx.socket(zmq.PAIR, ra.notify())
    let rb = _SocketReactor; let b = ctx.socket(zmq.PAIR, rb.notify())
    
    a.bind("inproc://SocketTypeTestPairPair")
    b.connect("inproc://SocketTypeTestPairPair")
    
    a.access(recover lambda(a: zmq.Socket ref) =>
      a.send_now(recover zmq.Message.push("b1") end)
      a.send_now(recover zmq.Message.push("b2") end)
      a.send_now(recover zmq.Message.push("b3") end)
    end~apply() end)
    
    b.access(recover lambda(b: zmq.Socket ref) =>
      b.send_now(recover zmq.Message.push("a1") end)
      b.send_now(recover zmq.Message.push("a2") end)
      b.send_now(recover zmq.Message.push("a3") end)
    end~apply() end)
    
    recv(h,      ra, a, recover zmq.Message.push("a1") end)
    recv(h,      ra, a, recover zmq.Message.push("a2") end)
    recv_last(h, ra, a, recover zmq.Message.push("a3") end)
    
    recv(h,      rb, b, recover zmq.Message.push("b1") end)
    recv(h,      rb, b, recover zmq.Message.push("b2") end)
    recv_last(h, rb, b, recover zmq.Message.push("b3") end)
    
    wait_2_reactors(h, ra, rb)

class SocketTypeTestPushNPull is SocketTypeTest
  new iso create() => None
  fun name(): String => "zmq.Socket (type: 1-PUSH --> N-PULL)"
  
  fun apply(h: TestHelper): TestResult =>
    let ctx = zmq.Context
    let rs = _SocketReactor; let s = ctx.socket(zmq.PUSH, rs.notify())
    let ra = _SocketReactor; let a = ctx.socket(zmq.PULL, ra.notify())
    let rb = _SocketReactor; let b = ctx.socket(zmq.PULL, rb.notify())
    let rc = _SocketReactor; let c = ctx.socket(zmq.PULL, rc.notify())
    
    a.bind("inproc://SocketTypeTestPushNPull/a")
    b.bind("inproc://SocketTypeTestPushNPull/b")
    c.bind("inproc://SocketTypeTestPushNPull/c")
    
    s.access(recover lambda(s: zmq.Socket ref) =>
      s.connect_now("inproc://SocketTypeTestPushNPull/a")
      s.connect_now("inproc://SocketTypeTestPushNPull/b")
      s.connect_now("inproc://SocketTypeTestPushNPull/c")
      
      s.send_now(recover zmq.Message.push("a1") end)
      s.send_now(recover zmq.Message.push("b1") end)
      s.send_now(recover zmq.Message.push("c1") end)
      s.send_now(recover zmq.Message.push("a2") end)
      s.send_now(recover zmq.Message.push("b2") end)
      s.send_now(recover zmq.Message.push("c2") end)
      s.send_now(recover zmq.Message.push("a3") end)
      s.send_now(recover zmq.Message.push("b3") end)
      s.send_now(recover zmq.Message.push("c3") end)
    end~apply() end)
    
    recv(h,      ra, a, recover zmq.Message.push("a1") end)
    recv(h,      ra, a, recover zmq.Message.push("a2") end)
    recv_last(h, ra, a, recover zmq.Message.push("a3") end)
    
    recv(h,      rb, b, recover zmq.Message.push("b1") end)
    recv(h,      rb, b, recover zmq.Message.push("b2") end)
    recv_last(h, rb, b, recover zmq.Message.push("b3") end)
    
    recv(h,      rc, c, recover zmq.Message.push("c1") end)
    recv(h,      rc, c, recover zmq.Message.push("c2") end)
    recv_last(h, rc, c, recover zmq.Message.push("c3") end)
    
    wait_3_reactors(h, ra, rb, rc)
