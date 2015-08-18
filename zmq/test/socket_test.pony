
use "ponytest"
use zmq = ".."

class SocketTest is UnitTest
  new iso create() => None
  fun name(): String => "zmq.Socket"
  
  fun apply(h: TestHelper): TestResult =>
    let ra = _SocketReactor; let a = zmq.Socket(zmq.PAIR, ra.notify())
    let rb = _SocketReactor; let b = zmq.Socket(zmq.PAIR, rb.notify())
    
    a.bind("tcp://localhost:8888")
    b.connect("tcp://localhost:8888")
    a.send(recover zmq.Message.push("foo") end)
    b.send(recover zmq.Message.push("bar") end)
    
    ra.next(recover lambda(h: TestHelper, s: zmq.Socket, m: zmq.Message) =>
      h.expect_eq[zmq.Message](m, recover zmq.Message.push("bar") end)
      s.dispose()
    end~apply(h,a) end)
    
    rb.next(recover lambda(h: TestHelper, s: zmq.Socket, m: zmq.Message) =>
      h.expect_eq[zmq.Message](m, recover zmq.Message.push("foo") end)
      s.dispose()
    end~apply(h,b) end)
    
    ra.when_closed(recover lambda(h: TestHelper, rb: _SocketReactor) =>
      rb.when_closed(recover lambda(h: TestHelper) =>
        h.complete(true)
      end~apply(h) end)
    end~apply(h,rb) end)
    
    LongTest

class SocketTestCurve is UnitTest
  new iso create() => None
  fun name(): String => "zmq.Socket (Curve)"
  
  fun apply(h: TestHelper): TestResult =>
    let ra = _SocketReactor; let a = zmq.Socket(zmq.PAIR, ra.notify())
    let rb = _SocketReactor; let b = zmq.Socket(zmq.PAIR, rb.notify())
    
    a.set(zmq.CurvePublicKey("b8loV^tt{Wvs9Fx!xTI3[e/x1n.ud0]>9Tj*BGPt"))
    a.set(zmq.CurveSecretKey("mjr{I->@v1rhtZ<zka05x/<RUS[3s{-eN.jtVgr&"))
    a.set(zmq.CurveAsServer(true))
    
    b.set(zmq.CurvePublicKey("C.aR>9^Q5BZN7MLI50<IJ*[p)?Ahn^.]p/pfSnw8"))
    b.set(zmq.CurveSecretKey("!{(r5u+61V?(FMkLEQT{W)!{VQJhCLW>]*/Eyn]s"))
    b.set(zmq.CurvePublicKeyOfServer("b8loV^tt{Wvs9Fx!xTI3[e/x1n.ud0]>9Tj*BGPt"))
    
    a.bind("tcp://localhost:8899")
    b.connect("tcp://localhost:8899")
    a.send(recover zmq.Message.push("foo") end)
    b.send(recover zmq.Message.push("bar") end)
    
    ra.next(recover lambda(h: TestHelper, s: zmq.Socket, m: zmq.Message) =>
      h.expect_eq[zmq.Message](m, recover zmq.Message.push("bar") end)
      s.dispose()
    end~apply(h,a) end)
    
    rb.next(recover lambda(h: TestHelper, s: zmq.Socket, m: zmq.Message) =>
      h.expect_eq[zmq.Message](m, recover zmq.Message.push("foo") end)
      s.dispose()
    end~apply(h,b) end)
    
    ra.when_closed(recover lambda(h: TestHelper, rb: _SocketReactor) =>
      rb.when_closed(recover lambda(h: TestHelper) =>
        h.complete(true)
      end~apply(h) end)
    end~apply(h,rb) end)
    
    LongTest

class SocketTestInProc is UnitTest
  new iso create() => None
  fun name(): String => "zmq.Socket (inproc)"
  
  fun apply(h: TestHelper): TestResult =>
    let ctx = zmq.Context
    let ra = _SocketReactor; let a = ctx.socket(zmq.PAIR, ra.notify())
    let rb = _SocketReactor; let b = ctx.socket(zmq.PAIR, rb.notify())
    
    a.bind("inproc://SocketTestInProc")
    b.connect("inproc://SocketTestInProc")
    a.send(recover zmq.Message.push("foo") end)
    b.send(recover zmq.Message.push("bar") end)
    
    ra.next(recover lambda(h: TestHelper, s: zmq.Socket, m: zmq.Message) =>
      h.expect_eq[zmq.Message](m, recover zmq.Message.push("bar") end)
      s.dispose()
    end~apply(h,a) end)
    
    rb.next(recover lambda(h: TestHelper, s: zmq.Socket, m: zmq.Message) =>
      h.expect_eq[zmq.Message](m, recover zmq.Message.push("foo") end)
      s.dispose()
    end~apply(h,b) end)
    
    ra.when_closed(recover lambda(h: TestHelper, rb: _SocketReactor) =>
      rb.when_closed(recover lambda(h: TestHelper) =>
        h.complete(true)
      end~apply(h) end)
    end~apply(h,rb) end)
    
    LongTest
