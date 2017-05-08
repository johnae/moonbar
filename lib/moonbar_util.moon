spook = _G.spook
after = (interval, func) ->
  timer = spook\timer interval, (t) -> func!
  timer\start!

coro = (func, ...) -> coroutine.wrap(func) ...

:after, :coro
