
use "ponytest"

actor Main
  new create(env: Env) =>
    let test = PonyTest(env)
    test(EndpointTest(env))
    test(SocketTest(env))
    test.complete()
