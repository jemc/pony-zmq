
use "ponytest"
use "./inspect"

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
    match _EndpointParser.from_uri(uri) | let subject: EndpointTCP =>
      h.expect_eq[String](subject.host, host)
      h.expect_eq[String](subject.port, port)
      h.expect_eq[String](subject.to_uri(), uri)
    else
      h.assert_failed("failed to parse EndpointTCP from URI: " + uri)
    end
  
  fun assert_unknown_from_uri(h: TestHelper, uri: String) =>
    match _EndpointParser.from_uri(uri) | let subject: EndpointUnknown =>
      h.expect_eq[String](subject.to_uri(), uri)
    else
      h.assert_failed("failed to parse EndpointUnknown from URI: " + uri)
    end

class _TestSocket is UnitTest
  let _env: Env
  new iso create(env: Env) => _env = env
  fun name(): String => "pony-zmq/Socket"
  
  fun apply(h: TestHelper): TestResult =>
    let a = Socket("PAIR", lambda(m: Message) => Inspect.print("a got: " + Inspect(m)) end)
    let b = Socket("PAIR", lambda(m: Message) => Inspect.print("b got: " + Inspect(m)) end)
    a.bind("tcp://localhost:8899")
    b.connect("tcp://localhost:8899")
    a.send_string("foo")
    b.send_string("bar")
    LongTest
