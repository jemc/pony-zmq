
use "ponytest"
use ".."
use "../inspect"

actor Main
  new create(env: Env) =>
    let test = PonyTest(env)
    test(_TestEndpoint(env))
    test(_TestSocket(env))
    test.complete()

class _TestEndpoint is UnitTest
  let _env: Env
  new iso create(env: Env) => _env = env
  fun name(): String => "pony-zmq/Endpoint"
  
  fun apply(h: TestHelper): TestResult =>
    assert_tcp_from_uri(h, "tcp://localhost:8899", "localhost", "8899")
    assert_tcp_from_uri(h, "tcp://127.0.0.1:1234", "127.0.0.1", "1234")
    assert_tcp_from_uri(h, "tcp://*:5555",         "*",         "5555")
    assert_tcp_from_uri(h, "tcp://eth0:*",         "eth0",      "*")
    assert_unknown_from_uri(h, "")
    assert_unknown_from_uri(h, "foo://bar")
    assert_unknown_from_uri(h, "tcp://localhost/8899")
    true
  
  fun assert_tcp_from_uri(h: TestHelper,
    uri: String, host: String, port: String)
  =>
    match EndpointParser.from_uri(uri) | let subject: EndpointTCP =>
      h.expect_eq[String](subject.host, host)
      h.expect_eq[String](subject.port, port)
      h.expect_eq[String](subject.to_uri(), uri)
    else
      h.assert_failed("failed to parse EndpointTCP from URI: " + uri)
    end
  
  fun assert_unknown_from_uri(h: TestHelper, uri: String) =>
    match EndpointParser.from_uri(uri) | let subject: EndpointUnknown =>
      h.expect_eq[String](subject.to_uri(), uri)
    else
      h.assert_failed("failed to parse EndpointUnknown from URI: " + uri)
    end

class _TestSocket is UnitTest
  let _env: Env
  new iso create(env: Env) => _env = env
  fun name(): String => "pony-zmq/Socket"
  
  fun apply(h: TestHelper): TestResult =>
    let bucket = _ExpectationBucket(h, 2)
    let a = Socket("PAIR", _SocketExpectation(h, bucket, "bar"))
    let b = Socket("PAIR", _SocketExpectation(h, bucket, "foo"))
    
    a.bind("tcp://localhost:8899")
    b.connect("tcp://localhost:8899")
    a.send_string("foo")
    b.send_string("bar")
    
    bucket.next(recover lambda(h: TestHelper, a: Socket, b: Socket) =>
      a.dispose()
      b.dispose()
      h.complete(true)
    end~apply(h,a,b) end)
    
    LongTest

interface _LambdaPartial iso
  fun ref apply() => None

class _LambdaPartialNone is _LambdaPartial
  new iso create() => None

actor _ExpectationBucket
  let _h: TestHelper
  var _count: U64
  var _next: _LambdaPartial = _LambdaPartialNone
  
  new create(h: TestHelper, count: U64) =>
    _h = h
    _count = count
  
  be reduce(diff: U64 = 1) =>
    _count = _count - diff
    if is_complete() then
      _h.complete(true)
      _next.apply()
      _next = _LambdaPartialNone
    end
  
  be next(func: _LambdaPartial) =>
    if is_complete() then (consume func)() else _next = consume func end
  
  fun is_complete(): Bool => _count <= 0

class _SocketExpectation is SocketNotify
  let _h: TestHelper
  let _bucket: _ExpectationBucket
  let _message: Message trn
  
  new iso create(h: TestHelper, bucket: _ExpectationBucket, string: String) =>
    _h = h
    _bucket = bucket
    _message = recover Message.push(string) end
  
  fun ref received(socket: Socket, message: Message) =>
    try
      _h.assert_eq[U64](message.size(), _message.size())
      var i: U64 = 0
      var j: U64 = 0
      for frame in message.values() do
        for byte in frame.values() do
          _h.assert_eq[U8](byte, _message(i)(j))
          j = j + 1
        end
        i = i + 1
      end
    end
    _bucket.reduce()
