
use "ponytest"
use zmq = ".."

class SocketTest is UnitTest
  let _env: Env
  new iso create(env: Env) => _env = env
  fun name(): String => "zmq.Socket"
  
  fun apply(h: TestHelper): TestResult =>
    let bucket = _ExpectationBucket(h, 2)
    let a = zmq.Socket("PAIR", _SocketExpectation(h, bucket, "bar"))
    let b = zmq.Socket("PAIR", _SocketExpectation(h, bucket, "foo"))
    
    a.bind("tcp://localhost:8899")
    b.connect("tcp://localhost:8899")
    a.send_string("foo")
    b.send_string("bar")
    
    bucket.next(recover lambda(h: TestHelper, a: zmq.Socket, b: zmq.Socket) =>
      a.dispose()
      b.dispose()
      h.complete(true)
    end~apply(h,a,b) end)
    
    LongTest
