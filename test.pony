
use "ponytest"
use zmtp = "zmtp"

actor Main
  new create(env: Env) =>
    let test = PonyTest(env)
    test(_TestZMTPClient(env))
    test.complete()

class _TestZMTPClient is UnitTest
  let _env: Env
  new iso create(env: Env) => _env = env
  fun name(): String => "pony-zmq/zmtp/Client"
  
  fun apply(h: TestHelper): TestResult =>
    let a = zmtp.Client("PULL")
    a.connect("localhost", "8899")
    true
