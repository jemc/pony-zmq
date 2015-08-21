
use "ponytest"
use "collections"
use zmq = ".."

primitive SocketTypeTests is TestList
  fun tag tests(test: PonyTest) =>
    test(SocketTypeTestPairPair)
    test(SocketTypeTestPushNPull)
    test(SocketTypeTestPullNPush)

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
  
  fun tag recv_unordered_set(h: TestHelper, rs: _SocketReactor, s: zmq.Socket, expected_list: Array[zmq.Message] val) =>
    rs.next_n(expected_list.size(), recover lambda(h: TestHelper, s: zmq.Socket, expected_list: Array[zmq.Message] val, list: List[zmq.Message]) =>
      if list.size() != expected_list.size() then
        h.assert_failed("Expected " + expected_list.size().string() + " messages, " + 
                        "but got " + list.size().string())
      end
      
      for expected in expected_list.values() do
        for node in list.nodes() do
          try if node() == expected then
            node.remove()
            break
          end end
        end
      end
      
      for remaining in list.values() do
        h.assert_failed("Got unexpected message: "+remaining.string())
      end
      
      s.dispose()
    end~apply(h, s, expected_list) end)
  
  fun tag wait_1_reactors(h: TestHelper, ra: _SocketReactor): LongTest =>
    ra.when_closed(recover lambda(h: TestHelper) =>
      h.complete(true)
    end~apply(h) end)
    
    LongTest
  
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

class SocketTypeTestPullNPush is SocketTypeTest
  new iso create() => None
  fun name(): String => "zmq.Socket (type: 1-PULL <-- N-PUSH)"
  
  fun apply(h: TestHelper): TestResult =>
    let ctx = zmq.Context
    let rs = _SocketReactor; let s = ctx.socket(zmq.PULL, rs.notify())
    let ra = _SocketReactor; let a = ctx.socket(zmq.PUSH, ra.notify())
    let rb = _SocketReactor; let b = ctx.socket(zmq.PUSH, rb.notify())
    let rc = _SocketReactor; let c = ctx.socket(zmq.PUSH, rc.notify())
    
    a.bind("inproc://SocketTypeTestPullNPush/a")
    b.bind("inproc://SocketTypeTestPullNPush/b")
    c.bind("inproc://SocketTypeTestPullNPush/c")
    s.connect("inproc://SocketTypeTestPullNPush/a")
    s.connect("inproc://SocketTypeTestPullNPush/b")
    s.connect("inproc://SocketTypeTestPullNPush/c")
    
    a.send(recover zmq.Message.push("a1") end)
    b.send(recover zmq.Message.push("b1") end)
    c.send(recover zmq.Message.push("c1") end)
    a.send(recover zmq.Message.push("a2") end)
    b.send(recover zmq.Message.push("b2") end)
    c.send(recover zmq.Message.push("c2") end)
    a.send(recover zmq.Message.push("a3") end)
    b.send(recover zmq.Message.push("b3") end)
    c.send(recover zmq.Message.push("c3") end)
    
    recv_unordered_set(h, rs, s, recover [
      recover val zmq.Message.push("a1") end,
      recover val zmq.Message.push("b1") end,
      recover val zmq.Message.push("c1") end,
      recover val zmq.Message.push("a2") end,
      recover val zmq.Message.push("b2") end,
      recover val zmq.Message.push("c2") end,
      recover val zmq.Message.push("a3") end,
      recover val zmq.Message.push("b3") end,
      recover val zmq.Message.push("c3") end
    ] end)
    
    wait_1_reactors(h, rs)
