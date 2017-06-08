:spawn = require 'process'
:concat, insert: append = table
log = _G.log

buffer_mt = {
  __tostring: (t) ->
    concat t, ''
}

new_buffer = -> setmetatable {}, buffer_mt

new_reader = ->
  buffer = new_buffer!
  func = (data) ->
    log.debug data
    append buffer, data
  func, buffer

(cmdline) ->
  on_read, buffer = new_reader!
  success = spawn cmdline, on_err: log.error, :on_read
  return false unless success
  tostring(buffer)
