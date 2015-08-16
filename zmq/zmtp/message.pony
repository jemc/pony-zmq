// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use "collections"
use "../inspect"

type Frame is ReadSeq[U8] val

class Message val is (Stringable & Comparable[Message box] & Seq[Frame])
  let _inner: List[Frame] = _inner.create()
  new create(len: U64 = 0) => None
  
  fun size():            U64     => _inner.size()
  fun apply(i: U64 = 0): Frame ? => _inner.apply(i)
  
  fun ref reserve(len: U64):            Message ref^     => _inner.reserve(len); this
  fun ref clear():                      Message ref^     => _inner.clear(); this
  fun ref update(i: U64, value: Frame): (Frame^ | None)? => _inner.update(i, value)
  fun ref push(value: Frame):           Message ref^     => _inner.push(value); this
  fun ref pop():                        Frame^?          => _inner.pop()
  fun ref unshift(value: Frame):        Message ref^     => _inner.unshift(value); this
  fun ref shift():                      Frame^?          => _inner.shift()
  fun ref truncate(len: U64):           Message ref^     => _inner.truncate(len); this
  fun ref append(seq: ReadSeq[Frame],
       offset: U64 = 0, len: U64 = -1): Message ref^     => _inner.append(seq, offset, len); this
  
  fun nodes():   ListNodes[Frame, this->ListNode[Frame]]^  => _inner.nodes()
  fun rnodes():  ListNodes[Frame, this->ListNode[Frame]]^  => _inner.rnodes()
  fun values():  ListValues[Frame, this->ListNode[Frame]]^ => _inner.values()
  fun rvalues(): ListValues[Frame, this->ListNode[Frame]]^ => _inner.rvalues()
  
  fun eq(that: Message box): Bool =>
    if size() != that.size() then return false end
    try for i in Range(0, size()-1) do
      if not _frame_eq(this(i), that(i)) then return false end
    end else return false end
    true
  
  fun tag _frame_eq(a: Frame, b: Frame): Bool =>
    if a.size() != b.size() then return false end
    try for i in Range(0, a.size()-1) do
      if a(i) != b(i) then return false end
    end else return false end
    true
  
  fun inspect(): String => Inspect(this)
  
  fun string(fmt: FormatDefault = FormatDefault,
    prefix: PrefixDefault = PrefixDefault, prec: U64 = -1, width: U64 = 0,
    align: Align = AlignLeft, fill: U32 = ' '): String iso^ => inspect().clone()
