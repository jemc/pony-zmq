
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
  fun name(): String => "ponyzmq/zmtp.Client"
  
  fun apply(h: TestHelper): TestResult =>
    let a = zmtp.Client("localhost", "8899")
    h.expect_eq[U8](0xFF, 0xFF)
    true
