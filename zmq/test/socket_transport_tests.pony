
use "pony_test"
use "net"
use zmq = ".."
use zmtp = "../zmtp"

primitive SocketTransportTests is TestList
  fun tag tests(test: PonyTest) =>
    
    test(SocketTransportTest("InProc",
      {(ctx: zmq.Context, a: zmq.Socket, b: zmq.Socket) =>
        a(zmq.BindInProc(ctx, "SocketTransportTest"))
        b(zmq.ConnectInProc(ctx, "SocketTransportTest"))
      } val))
    
    test(SocketTransportTest("TCP",
      {(net_auth: NetAuth, a: zmq.Socket, b: zmq.Socket) =>
        a(zmq.BindTCP(net_auth, "localhost", "8888"))
        b(zmq.ConnectTCP(net_auth, "localhost", "8888"))
      } val))
    
    test(SocketTransportTest("TCP + Curve",
      {(net_auth: NetAuth, a: zmq.Socket, b: zmq.Socket) =>
        a.set(zmq.CurvePublicKey("b8loV^tt{Wvs9Fx!xTI3[e/x1n.ud0]>9Tj*BGPt"))
        a.set(zmq.CurveSecretKey("mjr{I->@v1rhtZ<zka05x/<RUS[3s{-eN.jtVgr&"))
        a.set(zmq.CurveAsServer(true))
        
        b.set(zmq.CurvePublicKey("C.aR>9^Q5BZN7MLI50<IJ*[p)?Ahn^.]p/pfSnw8"))
        b.set(zmq.CurveSecretKey("!{(r5u+61V?(FMkLEQT{W)!{VQJhCLW>]*/Eyn]s"))
        b.set(zmq.CurvePublicKeyOfServer("b8loV^tt{Wvs9Fx!xTI3[e/x1n.ud0]>9Tj*BGPt"))
        
        a(zmq.BindTCP(net_auth, "localhost", "8889"))
        b(zmq.ConnectTCP(net_auth, "localhost", "8889"))
      } val))
    
    test(SocketTransportTest("TCP + Curve + Zap",
      {(net_auth: NetAuth, a: zmq.Socket, b: zmq.Socket) =>
        let zap_handler =
          object is zmtp.ZapRequestNotifiable
            be handle_zap_request(req: zmtp.ZapRequest, respond: zmtp.ZapRespond) =>
              // TODO: check public key (field of req)
              respond(zmtp.ZapResponse.success("bob"))
          end
        
        a.set(zmq.CurvePublicKey("b8loV^tt{Wvs9Fx!xTI3[e/x1n.ud0]>9Tj*BGPt"))
        a.set(zmq.CurveSecretKey("mjr{I->@v1rhtZ<zka05x/<RUS[3s{-eN.jtVgr&"))
        a.set(zmq.CurveAsServer(true))
        a.set(zmq.ZapHandler(zap_handler))
        
        b.set(zmq.CurvePublicKey("C.aR>9^Q5BZN7MLI50<IJ*[p)?Ahn^.]p/pfSnw8"))
        b.set(zmq.CurveSecretKey("!{(r5u+61V?(FMkLEQT{W)!{VQJhCLW>]*/Eyn]s"))
        b.set(zmq.CurvePublicKeyOfServer("b8loV^tt{Wvs9Fx!xTI3[e/x1n.ud0]>9Tj*BGPt"))
        
        a(zmq.BindTCP(net_auth, "localhost", "8890"))
        b(zmq.ConnectTCP(net_auth, "localhost", "8890"))
      } val))

interface val _SocketTransportTestsSetupNetLambda
  fun val apply(net_auth: NetAuth, a: zmq.Socket, b: zmq.Socket)

interface val _SocketTransportTestsSetupContextLambda
  fun val apply(ctx: zmq.Context, a: zmq.Socket, b: zmq.Socket)

type _SocketTransportTestsSetupLambda is
  (_SocketTransportTestsSetupNetLambda | _SocketTransportTestsSetupContextLambda)

class SocketTransportTest is UnitTest
  let _desc: String
  let _setup: _SocketTransportTestsSetupLambda
  new iso create(desc: String, setup: _SocketTransportTestsSetupLambda) =>
    _desc = desc
    _setup = setup
  
  fun name(): String => "zmq.Socket (transport: " + _desc + ")"
  
  fun apply(h: TestHelper)? =>
    let ra = _SocketReactor; let a = zmq.Socket(zmq.PAIR, ra.notify())
    let rb = _SocketReactor; let b = zmq.Socket(zmq.PAIR, rb.notify())
    
    let net_auth = NetAuth(h.env.root as AmbientAuth)
    let ctx = zmq.Context
    
    match _setup
    | let setup: _SocketTransportTestsSetupNetLambda => setup(net_auth, a, b)
    | let setup: _SocketTransportTestsSetupContextLambda => setup(ctx, a, b)
    end
    
    a.send(recover zmq.Message.>push("foo") end)
    b.send(recover zmq.Message.>push("bar") end)
    
    ra.next({(m: zmq.Message) =>
      h.assert_eq[zmq.Message](m, recover zmq.Message.>push("bar") end)
      a.dispose()
    } val)
    
    rb.next({(m: zmq.Message) =>
      h.assert_eq[zmq.Message](m, recover zmq.Message.>push("foo") end)
      b.dispose()
    } val)
    
    ra.when_closed({()(h,rb) =>
      rb.when_closed({()(h) =>
        h.complete(true)
      } val)
    } val)
    
    h.long_test(5_000_000_000)
