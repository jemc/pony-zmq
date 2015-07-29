
use "time"

interface _ReconnectTimerNotifiable tag
  be _reconnect_timer_fire()

class _ReconnectTimerNotify is TimerNotify
  let _parent: _ReconnectTimerNotifiable
  new iso create(parent: _ReconnectTimerNotifiable) =>
    _parent = parent
  fun ref apply(timer: Timer, count: U64): Bool =>
    _parent._reconnect_timer_fire()
    false
