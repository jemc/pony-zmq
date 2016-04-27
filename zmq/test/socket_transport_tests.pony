
use "ponytest"
use "net"
use zmq = ".."

primitive SocketTransportTests is TestList
  fun tag tests(test: PonyTest) =>
    
    test(SocketTransportTest("TCP",
      lambda val(net_auth: NetAuth, a: zmq.Socket, b: zmq.Socket) =>
        a(zmq.BindTCP(net_auth, "localhost", "8888"))
        a(zmq.ConnectTCP(net_auth, "localhost", "8888"))
      end))
    
    test(SocketTransportTest("TCP + Curve",
      lambda val(net_auth: NetAuth, a: zmq.Socket, b: zmq.Socket) =>
        a.set(zmq.CurvePublicKey("b8loV^tt{Wvs9Fx!xTI3[e/x1n.ud0]>9Tj*BGPt"))
        a.set(zmq.CurveSecretKey("mjr{I->@v1rhtZ<zka05x/<RUS[3s{-eN.jtVgr&"))
        a.set(zmq.CurveAsServer(true))
        
        b.set(zmq.CurvePublicKey("C.aR>9^Q5BZN7MLI50<IJ*[p)?Ahn^.]p/pfSnw8"))
        b.set(zmq.CurveSecretKey("!{(r5u+61V?(FMkLEQT{W)!{VQJhCLW>]*/Eyn]s"))
        b.set(zmq.CurvePublicKeyOfServer("b8loV^tt{Wvs9Fx!xTI3[e/x1n.ud0]>9Tj*BGPt"))
        
        a(zmq.BindTCP(net_auth, "localhost", "8899"))
        a(zmq.ConnectTCP(net_auth, "localhost", "8899"))
      end))
    
    test(SocketTransportTest("inproc",
      lambda val(net_auth: NetAuth,a: zmq.Socket, b: zmq.Socket) =>
        a(zmq.BindInProc("SocketTransportTest"))
        b(zmq.ConnectInProc("SocketTransportTest"))
      end))

interface val _SocketTransportTestsSetupLambda
  fun val apply(h: NetAuth,a: zmq.Socket, b: zmq.Socket)

class SocketTransportTest is UnitTest
  let _desc: String
  let _setup: _SocketTransportTestsSetupLambda
  new iso create(desc: String, setup: _SocketTransportTestsSetupLambda) =>
    _desc = desc
    _setup = setup
  
  fun name(): String => "zmq.Socket (transport: " + _desc + ")"
  
  fun apply(h: TestHelper)? =>
    let ctx = zmq.Context
    let ra = _SocketReactor; let a = ctx.socket(zmq.PAIR, ra.notify())
    let rb = _SocketReactor; let b = ctx.socket(zmq.PAIR, rb.notify())
    
    let net_auth = NetAuth(h.env.root as AmbientAuth)
    
    _setup(net_auth, a, b)
    
    a.send(recover zmq.Message.push("foo") end)
    b.send(recover zmq.Message.push("bar") end)
    
    ra.next(recover lambda iso(m: zmq.Message)(h,a) =>
      h.assert_eq[zmq.Message](m, recover zmq.Message.push("bar") end)
      a.dispose()
    end end)
    
    rb.next(recover lambda iso(m: zmq.Message)(h,b) =>
      h.assert_eq[zmq.Message](m, recover zmq.Message.push("foo") end)
      b.dispose()
    end end)
    
    ra.when_closed(recover lambda iso()(h,rb) =>
      rb.when_closed(recover lambda iso()(h) =>
        h.complete(true)
      end end)
    end end)
    
    h.long_test(5_000_000_000)
