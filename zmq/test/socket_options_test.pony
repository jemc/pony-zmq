
use "ponytest"
use zmq = ".."

class SocketOptionsTest is UnitTest
  new iso create() => None
  fun name(): String => "zmq.SocketOptions"
  
  fun apply(h: TestHelper): TestResult =>
    // Start with an empty set of SocketOptions; all are at their defaults.
    let socket_opts = zmq.SocketOptions
    h.expect_eq[USize](socket_opts.size(), 0)
    h.expect_eq[F64](zmq.ReconnectInterval.find_in(socket_opts),
                     zmq.ReconnectInterval.default())
    h.expect_eq[F64](zmq.HeartbeatInterval.find_in(socket_opts),
                     zmq.HeartbeatInterval.default())
    
    // Set an option to grow the set and override the default for that option.
    h.expect_true(zmq.ReconnectInterval.set_in(socket_opts, 0.25))
    h.expect_eq[USize](socket_opts.size(), 1)
    h.expect_eq[F64](zmq.ReconnectInterval.find_in(socket_opts), 0.25)
    h.expect_eq[F64](zmq.HeartbeatInterval.find_in(socket_opts),
                     zmq.HeartbeatInterval.default())
    
    // Set another option to grow and override again.
    h.expect_true(zmq.HeartbeatInterval.set_in(socket_opts, 10.0))
    h.expect_eq[USize](socket_opts.size(), 2)
    h.expect_eq[F64](zmq.ReconnectInterval.find_in(socket_opts), 0.25)
    h.expect_eq[F64](zmq.HeartbeatInterval.find_in(socket_opts), 10.0)
    
    // Set an already-set option many times; takes the latest and does not grow.
    h.expect_true(zmq.ReconnectInterval.set_in(socket_opts, 0.5))
    h.expect_true(zmq.ReconnectInterval.set_in(socket_opts, 1.0))
    h.expect_true(zmq.ReconnectInterval.set_in(socket_opts, 2.0))
    h.expect_eq[USize](socket_opts.size(), 2)
    h.expect_eq[F64](zmq.ReconnectInterval.find_in(socket_opts), 2.0)
    h.expect_eq[F64](zmq.HeartbeatInterval.find_in(socket_opts), 10.0)
    
    // Set an option to an invalid value; returns false and does not grow.
    h.expect_false(zmq.CurveSecretKey.set_in(socket_opts, "not_a_key"))
    h.expect_eq[USize](socket_opts.size(), 2)
    
    // Set and find a boolean option.
    h.expect_false(zmq.CurveAsServer.find_in(socket_opts))
    h.expect_true(zmq.CurveAsServer.set_in(socket_opts, true))
    h.expect_true(zmq.CurveAsServer.find_in(socket_opts))
    h.expect_eq[USize](socket_opts.size(), 3)
    
    true
