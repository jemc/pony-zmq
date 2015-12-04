
use "ponytest"
use zmq = ".."

primitive SocketTransportTests is TestList
  fun tag tests(test: PonyTest) =>
    
    test(SocketTransportTest("TCP",
      lambda val(a: zmq.Socket, b: zmq.Socket) =>
        a.bind("tcp://localhost:8888")
        b.connect("tcp://localhost:8888")
      end))
    
    test(SocketTransportTest("TCP + Curve",
      lambda val(a: zmq.Socket, b: zmq.Socket) =>
        a.set(zmq.CurvePublicKey("b8loV^tt{Wvs9Fx!xTI3[e/x1n.ud0]>9Tj*BGPt"))
        a.set(zmq.CurveSecretKey("mjr{I->@v1rhtZ<zka05x/<RUS[3s{-eN.jtVgr&"))
        a.set(zmq.CurveAsServer(true))
        
        b.set(zmq.CurvePublicKey("C.aR>9^Q5BZN7MLI50<IJ*[p)?Ahn^.]p/pfSnw8"))
        b.set(zmq.CurveSecretKey("!{(r5u+61V?(FMkLEQT{W)!{VQJhCLW>]*/Eyn]s"))
        b.set(zmq.CurvePublicKeyOfServer("b8loV^tt{Wvs9Fx!xTI3[e/x1n.ud0]>9Tj*BGPt"))
        
        a.bind("tcp://localhost:8899")
        b.connect("tcp://localhost:8899")
      end))
    
    test(SocketTransportTest("inproc",
      lambda val(a: zmq.Socket, b: zmq.Socket) =>
        a.bind("inproc://SocketTransportTest")
        b.connect("inproc://SocketTransportTest")
      end))

interface val _SocketTransportTestsSetupLambda
  fun val apply(a: zmq.Socket, b: zmq.Socket)

class SocketTransportTest is UnitTest
  let _desc: String
  let _setup: _SocketTransportTestsSetupLambda
  new iso create(desc: String, setup: _SocketTransportTestsSetupLambda) =>
    _desc = desc
    _setup = setup
  
  fun name(): String => "zmq.Socket (transport: " + _desc + ")"
  
  fun apply(h: TestHelper): TestResult =>
    let ctx = zmq.Context
    let ra = _SocketReactor; let a = ctx.socket(zmq.PAIR, ra.notify())
    let rb = _SocketReactor; let b = ctx.socket(zmq.PAIR, rb.notify())
    
    _setup(a, b)
    
    a.send(recover zmq.Message.push("foo") end)
    b.send(recover zmq.Message.push("bar") end)
    
    ra.next(lambda iso(m: zmq.Message)(h,a) =>
      h.expect_eq[zmq.Message](m, recover zmq.Message.push("bar") end)
      a.dispose()
    end)
    
    rb.next(lambda iso(m: zmq.Message)(h,b) =>
      h.expect_eq[zmq.Message](m, recover zmq.Message.push("foo") end)
      b.dispose()
    end)
    
    ra.when_closed(lambda iso()(h,rb) =>
      rb.when_closed(lambda iso()(h) =>
        h.complete(true)
        None
      end)
    end)
    
    LongTest
