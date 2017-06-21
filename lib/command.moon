:spawn = require 'process'
:concat, insert: append = table
log = _G.log

(cmdline) ->
  buf = {}
  success = spawn cmdline, on_err: log.error, on_read: (data) ->
    log.debug data
    append buf, data
  return false unless success
  concat buf, ''
