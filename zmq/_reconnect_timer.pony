// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use "time"

interface tag _ReconnectTimerNotifiable
  be _reconnect_timer_fire()

class _ReconnectTimerNotify is TimerNotify
  let _parent: _ReconnectTimerNotifiable
  new iso create(parent: _ReconnectTimerNotifiable) =>
    _parent = parent
  fun ref apply(timer: Timer, count: U64): Bool =>
    _parent._reconnect_timer_fire()
    false
