ffi = require 'ffi'
moon = require 'moon'
libsystemd = ffi.load 'systemd'
serpent = require 'serpent'
insert: append, :concat = table
format = (p) ->
  if type(p) == 'table'
    return serpent.block p, comment: false, sortkeys: true
  p

ffi.cdef [[
int sd_journal_print(int priority, const char *format, ...);
int sd_journal_printv(int priority, const char *format, va_list ap);
int sd_journal_send(const char *format, ...);
int sd_journal_sendv(const struct iovec *iov, int n);
int sd_journal_perror(const char *message);
]]

log = (level, ...) ->
  params = {}
  msg = {}
  for v in *{...}
    append msg, tostring(format(v))
  smsg = concat msg, ' '
  libsystemd.sd_journal_send "MESSAGE=#{smsg}",
                             "PRIORITY=#{level}",
                             "HOME=%s", os.getenv('HOME'),
                             "TERM=%s", os.getenv('TERM'), nil

EMERG = 0
ALERT = 1
CRIT = 2
ERR = 3
WARNING = 4
NOTICE = 5
INFO = 6
DEBUG = 7

log_level = INFO
{
  :EMERG
  :ALERT
  :CRIT
  :ERR
  :WARNING
  :NOTICE
  :INFO
  :DEBUG

  logger: (f) ->

  level: (l) ->
    log_level = l

  emerg: (...) ->
    log EMERG, ...

  info: (...) ->
    log INFO, ...

  error: (...) ->
    log ERR, ...

  warn: (...) ->
    log WARNING, ...

  debug: (...) ->
    log DEBUG, ...
}
