
use "collections"

interface _MessageQueueWritable tag
  be write(data: Bytes)

class _MessageQueue
  let _inner: List[Message] = _inner.create()
  var _empty: Bool = true
  
  fun ref push(message: Message) =>
    """
    Push a message to send at the next flush.
    """
    _inner.push(message)
    _empty = false
  
  fun ref flush(target: _MessageQueueWritable) =>
    """
    Send all queued messages to target.
    """
    if _empty then return end
    try
      while true do
        target.write(_MessageParser.write(_inner.shift()))
      end
      _empty = true
    end
  
  fun ref send(message: Message, target': (_MessageQueueWritable | None), active: Bool) =>
    """
    If active and target is not None, send message to target, else push for later.
    """
    if active then
      try
        let target = target' as _MessageQueueWritable
        flush(target as _MessageQueueWritable)
        target.write(_MessageParser.write(message))
      else
        push(message)
      end
    else
      push(message)
    end
