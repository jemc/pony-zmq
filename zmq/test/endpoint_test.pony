
use "ponytest"
use zmq = ".."

class EndpointTest is UnitTest
  new iso create() => None
  fun name(): String => "zmq.Endpoint"
  
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
    match zmq.EndpointParser.from_uri(uri) | let subject: zmq.EndpointTCP =>
      h.expect_eq[String](subject.host, host)
      h.expect_eq[String](subject.port, port)
      h.expect_eq[String](subject.to_uri(), uri)
    else
      h.assert_failed("failed to parse zmq.EndpointTCP from URI: " + uri)
    end
  
  fun assert_unknown_from_uri(h: TestHelper, uri: String) =>
    match zmq.EndpointParser.from_uri(uri) | let subject: zmq.EndpointUnknown =>
      h.expect_eq[String](subject.to_uri(), uri)
    else
      h.assert_failed("failed to parse zmq.EndpointUnknown from URI: " + uri)
    end
