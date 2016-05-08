
use "ponytest"
use "collections"
use zmq = ".."

primitive SocketTypeTests is TestList
  fun tag tests(test: PonyTest) =>
    test(SocketTypeTestPairPair)
    test(SocketTypeTestPushNPull)
    test(SocketTypeTestPullNPush)
    test(SocketTypeTestReqNRep)
    test(SocketTypeTestRepNReq)

trait SocketTypeTest is UnitTest
  fun tag recv(h: TestHelper, rs: _SocketReactor, s: zmq.Socket, m': zmq.Message) =>
    rs.next(recover this~_recv_lambda(h, s, m') end)
  
  fun tag recv_last(h: TestHelper, rs: _SocketReactor, s: zmq.Socket, m': zmq.Message) =>
    rs.next(recover this~_recv_last_lambda(h, s, m') end)
  
  fun tag _recv_lambda(h: TestHelper, s: zmq.Socket, m': zmq.Message, m: zmq.Message) =>
    h.assert_eq[zmq.Message](m, m')
  
  fun tag _recv_last_lambda(h: TestHelper, s: zmq.Socket, m': zmq.Message, m: zmq.Message) =>
    h.assert_eq[zmq.Message](m, m')
    s.dispose()
  
  fun tag recv_unordered_set(h: TestHelper, rs: _SocketReactor, s: zmq.Socket, expected_list: Array[zmq.Message] val) =>
    rs.next_n(expected_list.size(), recover lambda val(list: List[zmq.Message])(h,s,expected_list) =>
      if list.size() != expected_list.size() then
        h.fail("Expected " + expected_list.size().string() + " messages, " + 
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
        h.fail("Got unexpected message: "+remaining.string())
      end
      
      s.dispose()
    end end)
  
  fun tag wait_1_reactor(h: TestHelper, ra: _SocketReactor) =>
    ra.when_closed(recover lambda val()(h) =>
      h.complete(true)
    end end)
    
    h.long_test(5_000_000_000)
  
  fun tag wait_2_reactors(h: TestHelper, ra: _SocketReactor, rb: _SocketReactor) =>
    ra.when_closed(recover lambda val()(h, rb) =>
      rb.when_closed(recover lambda val()(h) =>
        h.complete(true)
      end end)
    end end)
    
    h.long_test(5_000_000_000)
  
  fun tag wait_3_reactors(h: TestHelper, ra: _SocketReactor, rb: _SocketReactor, rc: _SocketReactor) =>
    ra.when_closed(recover lambda val()(h, rb, rc) =>
      rb.when_closed(recover lambda val()(h, rc) =>
        rc.when_closed(recover lambda val()(h) =>
          h.complete(true)
        end end)
      end end)
    end end)
    
    h.long_test(5_000_000_000)

class SocketTypeTestPairPair is SocketTypeTest
  new iso create() => None
  fun name(): String => "zmq.Socket (type: 1-PAIR <-> 1-PAIR)"
  
  fun apply(h: TestHelper) =>
    let ra = _SocketReactor; let a = zmq.Socket(zmq.PAIR, ra.notify())
    let rb = _SocketReactor; let b = zmq.Socket(zmq.PAIR, rb.notify())
    
    let ctx = zmq.Context
    a(zmq.BindInProc(ctx, "SocketTypeTestPairPair"))
    b(zmq.ConnectInProc(ctx, "SocketTypeTestPairPair"))
    
    a.access(recover lambda val(a: zmq.Socket ref) =>
      a.send_now(recover zmq.Message.push("b1") end)
      a.send_now(recover zmq.Message.push("b2") end)
      a.send_now(recover zmq.Message.push("b3") end)
    end end)
    
    b.access(recover lambda val(b: zmq.Socket ref) =>
      b.send_now(recover zmq.Message.push("a1") end)
      b.send_now(recover zmq.Message.push("a2") end)
      b.send_now(recover zmq.Message.push("a3") end)
    end end)
    
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
  
  fun apply(h: TestHelper) =>
    let rs = _SocketReactor; let s = zmq.Socket(zmq.PUSH, rs.notify())
    let ra = _SocketReactor; let a = zmq.Socket(zmq.PULL, ra.notify())
    let rb = _SocketReactor; let b = zmq.Socket(zmq.PULL, rb.notify())
    let rc = _SocketReactor; let c = zmq.Socket(zmq.PULL, rc.notify())
    
    let ctx = zmq.Context
    a(zmq.BindInProc(ctx, "SocketTypeTestPushNPull/a"))
    b(zmq.BindInProc(ctx, "SocketTypeTestPushNPull/b"))
    c(zmq.BindInProc(ctx, "SocketTypeTestPushNPull/c"))
    s(zmq.ConnectInProc(ctx, "SocketTypeTestPushNPull/a"))
    s(zmq.ConnectInProc(ctx, "SocketTypeTestPushNPull/b"))
    s(zmq.ConnectInProc(ctx, "SocketTypeTestPushNPull/c"))
    
    s.access(recover lambda val(s: zmq.Socket ref) =>
      s.send_now(recover zmq.Message.push("a1") end)
      s.send_now(recover zmq.Message.push("b1") end)
      s.send_now(recover zmq.Message.push("c1") end)
      s.send_now(recover zmq.Message.push("a2") end)
      s.send_now(recover zmq.Message.push("b2") end)
      s.send_now(recover zmq.Message.push("c2") end)
      s.send_now(recover zmq.Message.push("a3") end)
      s.send_now(recover zmq.Message.push("b3") end)
      s.send_now(recover zmq.Message.push("c3") end)
    end end)
    
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
  
  fun apply(h: TestHelper) =>
    let rs = _SocketReactor; let s = zmq.Socket(zmq.PULL, rs.notify())
    let ra = _SocketReactor; let a = zmq.Socket(zmq.PUSH, ra.notify())
    let rb = _SocketReactor; let b = zmq.Socket(zmq.PUSH, rb.notify())
    let rc = _SocketReactor; let c = zmq.Socket(zmq.PUSH, rc.notify())
    
    let ctx = zmq.Context
    a(zmq.BindInProc(ctx, "SocketTypeTestPullNPush/a"))
    b(zmq.BindInProc(ctx, "SocketTypeTestPullNPush/b"))
    c(zmq.BindInProc(ctx, "SocketTypeTestPullNPush/c"))
    s(zmq.ConnectInProc(ctx, "SocketTypeTestPullNPush/a"))
    s(zmq.ConnectInProc(ctx, "SocketTypeTestPullNPush/b"))
    s(zmq.ConnectInProc(ctx, "SocketTypeTestPullNPush/c"))
    
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
    
    wait_1_reactor(h, rs)

class SocketTypeTestReqNRep is SocketTypeTest
  new iso create() => None
  fun name(): String => "zmq.Socket (type: 1-REQ --> N-REP)"
  
  fun apply(h: TestHelper) =>
    let rs = _SocketReactor; let s = zmq.Socket(zmq.REQ, rs.notify())
    let ra = _SocketReactor; let a = zmq.Socket(zmq.REP, ra.notify())
    let rb = _SocketReactor; let b = zmq.Socket(zmq.REP, rb.notify())
    let rc = _SocketReactor; let c = zmq.Socket(zmq.REP, rc.notify())
    
    let ctx = zmq.Context
    a(zmq.BindInProc(ctx, "SocketTypeTestReqNRep/a"))
    b(zmq.BindInProc(ctx, "SocketTypeTestReqNRep/b"))
    c(zmq.BindInProc(ctx, "SocketTypeTestReqNRep/c"))
    s(zmq.ConnectInProc(ctx, "SocketTypeTestReqNRep/a"))
    s(zmq.ConnectInProc(ctx, "SocketTypeTestReqNRep/b"))
    s(zmq.ConnectInProc(ctx, "SocketTypeTestReqNRep/c"))
    
    s.access(recover lambda val(s: zmq.Socket ref) =>
      s.send_now(recover zmq.Message.push("a") end)
      s.send_now(recover zmq.Message.push("b") end)
      s.send_now(recover zmq.Message.push("c") end)
    end end)
    
    ra.next(recover lambda val(p: zmq.SocketPeer, m: zmq.Message)(ra) =>
      p.send(recover zmq.Message.append(m).push("A") end)
    end end)
    
    rb.next(recover lambda val(p: zmq.SocketPeer, m: zmq.Message)(rb) =>
      p.send(recover zmq.Message.append(m).push("B") end)
    end end)
    
    rc.next(recover lambda val(p: zmq.SocketPeer, m: zmq.Message)(rc) =>
      p.send(recover zmq.Message.append(m).push("C") end)
    end end)
    
    recv_unordered_set(h, rs, s, recover [
      recover val zmq.Message.push("a").push("A") end,
      recover val zmq.Message.push("b").push("B") end,
      recover val zmq.Message.push("c").push("C") end
    ] end)
    
    wait_1_reactor(h, rs)

class SocketTypeTestRepNReq is SocketTypeTest
  new iso create() => None
  fun name(): String => "zmq.Socket (type: 1-REP <-- N-REQ)"
  
  fun apply(h: TestHelper) =>
    let rs = _SocketReactor; let s = zmq.Socket(zmq.REP, rs.notify())
    let ra = _SocketReactor; let a = zmq.Socket(zmq.REQ, ra.notify())
    let rb = _SocketReactor; let b = zmq.Socket(zmq.REQ, rb.notify())
    let rc = _SocketReactor; let c = zmq.Socket(zmq.REQ, rc.notify())
    
    let ctx = zmq.Context
    a(zmq.BindInProc(ctx, "SocketTypeTestRepNReq/a"))
    b(zmq.BindInProc(ctx, "SocketTypeTestRepNReq/b"))
    c(zmq.BindInProc(ctx, "SocketTypeTestRepNReq/c"))
    s(zmq.ConnectInProc(ctx, "SocketTypeTestRepNReq/a"))
    s(zmq.ConnectInProc(ctx, "SocketTypeTestRepNReq/b"))
    s(zmq.ConnectInProc(ctx, "SocketTypeTestRepNReq/c"))
    
    a.send(recover zmq.Message.push("a") end)
    b.send(recover zmq.Message.push("b") end)
    c.send(recover zmq.Message.push("c") end)
    
    for i in Range(0, 3) do
      rs.next(recover lambda val(p: zmq.SocketPeer, m: zmq.Message)(rs) =>
        p.send(recover zmq.Message.append(m).push("S") end)
      end end)
    end
    
    recv_last(h, ra, a, recover zmq.Message.push("a").push("S") end)
    recv_last(h, rb, b, recover zmq.Message.push("b").push("S") end)
    recv_last(h, rc, c, recover zmq.Message.push("c").push("S") end)
    
    wait_3_reactors(h, ra, rb, rc)
