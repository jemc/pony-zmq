// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use "collections"
use "inspect"

type Frame is String

class val Message is (Stringable & Equatable[Message box] & Seq[Frame])
  let _inner: List[Frame] = _inner.create()
  new create(len: USize = 0) => None
  
  fun size():              USize  => _inner.size()
  fun apply(i: USize = 0): Frame? => _inner.apply(i)?
  
  fun ref reserve(len: USize)                     => _inner.reserve(len); this
  fun ref clear()                                 => _inner.clear(); this
  fun ref update(i: USize, value: Frame): Frame^? => _inner.update(i, value)?
  fun ref push(value: Frame)                      => _inner.push(value); this
  fun ref pop():                          Frame^? => _inner.pop()?
  fun ref unshift(value: Frame)                   => _inner.unshift(value); this
  fun ref shift():                        Frame^? => _inner.shift()?
  fun ref truncate(len: USize)                    => _inner.truncate(len); this
  fun ref concat(iter: Iterator[Frame^], offset: USize = 0, len: USize = -1) =>
    _inner.concat(iter, offset, len); this
  fun ref append(seq: ReadSeq[Frame], offset: USize = 0, len: USize = -1) =>
    _inner.append(seq, offset, len); this
  
  fun nodes():   ListNodes[Frame, this->ListNode[Frame]]^  => _inner.nodes()
  fun rnodes():  ListNodes[Frame, this->ListNode[Frame]]^  => _inner.rnodes()
  fun values():  ListValues[Frame, this->ListNode[Frame]]^ => _inner.values()
  fun rvalues(): ListValues[Frame, this->ListNode[Frame]]^ => _inner.rvalues()
  
  fun eq(that: Message box): Bool =>
    if size() != that.size() then return false end
    try for i in Range(0, size()) do
      if not _frame_eq(this(i)?, that(i)?) then return false end
    end else return false end
    true
  
  fun tag _frame_eq(a: Frame, b: Frame): Bool =>
    if a.size() != b.size() then return false end
    try for i in Range(0, a.size()) do
      if a(i)? != b(i)? then return false end
    end else return false end
    true
  
  fun inspect(): String => Inspect(this)
  
  fun string(): String iso^ =>
    inspect().clone()
