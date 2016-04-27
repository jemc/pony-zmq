
use "ponytest"
use zmq = ".."

class MessageTest is UnitTest
  new iso create() => None
  fun name(): String => "zmq.Message"
  
  fun apply(h: TestHelper) =>
    h.assert_eq[zmq.Message](
      recover zmq.Message.push("foo") end,
      recover zmq.Message.push("foo") end
    )
    
    h.assert_false(
      recover zmq.Message.push("foo") end ==
      recover zmq.Message.push("bar") end,
      "expected "  + zmq.Message.push("foo").string() + " " +
      "not to eq " + zmq.Message.push("bar").string()
    )
