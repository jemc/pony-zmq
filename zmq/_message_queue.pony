// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use "collections"

interface _MessageQueueWritable tag
  be write(data: Bytes)

class _MessageQueue
  let _inner: List[Message] = _inner.create()
  var _empty: Bool = true
  var _write_transform: _MessageWriteTransform = recover _MessageParser~write() end
  
  fun ref set_write_transform(writex: _MessageWriteTransform) =>
    _write_transform = consume writex
  
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
        target.write(_write_transform(_inner.shift()))
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
        target.write(_write_transform(message))
      else
        push(message)
      end
    else
      push(message)
    end
