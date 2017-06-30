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

log = (req_level, level, ...) ->
  return if req_level < level
  params = {}
  info = {}
  append info, tostring(format(v)) for v in *{...}
  libsystemd.sd_journal_send "MESSAGE=#{concat info, ' '}",
                             "PRIORITY=#{level}",
                             "HOME=#{os.getenv('HOME')}",
                             "TERM=#{os.getenv('TERM')}"

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
    log log_level, EMERG, ...

  info: (...) ->
    log log_level, INFO, ...

  error: (...) ->
    log log_level, ERR, ...

  warn: (...) ->
    log log_level, WARNING, ...

  debug: (...) ->
    log log_level, DEBUG, ...
}
