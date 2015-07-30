
use "ponytest"
use zmq = ".."

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

class _SocketExpectation is zmq.SocketNotify
  let _h: TestHelper
  let _bucket: _ExpectationBucket
  let _message: zmq.Message trn
  
  new iso create(h: TestHelper, bucket: _ExpectationBucket, string: String) =>
    _h = h
    _bucket = bucket
    _message = recover zmq.Message.push(string) end
  
  fun ref received(socket: zmq.Socket, message: zmq.Message) =>
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
