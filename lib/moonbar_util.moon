spook = _G.spook
after = (interval, func) ->
  timer = spook\timer interval, (t) -> func!
  timer\start!

:after
