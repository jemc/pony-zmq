// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use "collections"
use zmtp = "zmtp"

interface tag _MessageQueueWritable
  be write(data: ByteSeq)

class _MessageQueue
  let _inner: List[Message] = _inner.create()
  var _empty: Bool = true
  var _write_transform: _MessageWriteTransform = recover zmtp.MessageWriter end
  
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
    while true do
      let msg = try _inner.shift() else (_empty = true; return) end
      target.write(_write_transform(msg))
    end
  
  fun ref send(message: Message, target: (_MessageQueueWritable | None), active: Bool) =>
    """
    If active and target is not None, send message to target, else push for later.
    """
    if active then
      match target | let target': _MessageQueueWritable =>
        flush(target')
        target'.write(_write_transform(message))
      else
        push(message)
      end
    else
      push(message)
    end

interface tag _MessageQueueSimpleReceivable
  be received(message: Message)

// TODO: Remove this class and reconcile with refactored _MessageQueue above.
class _MessageQueueSimple
  let _inner: List[Message] = _inner.create()
  var _empty: Bool = true
  
  fun ref push(message: Message) =>
    """
    Push a message to send at the next flush.
    """
    _inner.push(message)
    _empty = false
  
  fun ref flush(target: _MessageQueueSimpleReceivable) =>
    """
    Send all queued messages to target.
    """
    if _empty then return end
    while true do
      let msg = try _inner.shift() else (_empty = true; return) end
      target.received(msg)
    end
  
  fun ref send(message: Message, target: (_MessageQueueSimpleReceivable | None), active: Bool) =>
    """
    If active and target is not None, send message to target, else push for later.
    """
    if active then
      match target | let target': _MessageQueueSimpleReceivable =>
        flush(target')
        target'.received(message)
      else
        push(message)
      end
    else
      push(message)
    end
