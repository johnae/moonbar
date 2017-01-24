S = require "syscall"
:Read, :epoll_fd = require 'event_loop'
insert: append = table

create_pipe = ->
  _, err, p_read, p_write = S.pipe!
  error err if err
  p_read, p_write

stdio_pipes = ->
  in_read, in_write = create_pipe!
  out_read, out_write = create_pipe!
  err_read, err_write = create_pipe!
  in_read, in_write, out_read, out_write, err_read, err_write

close_all = (...) -> stream\close! for stream in *{...}

--
read = (fd, count = 4096) -> ->
  bytes, err = fd\read nil, count
  error err if bytes == -1 -- weird return type (as mentioned in ljsyscall) - either a string or -1
  return nil if #bytes == 0
  bytes

env = ["#{k}=#{v}" for k, v in pairs S.environ!]

execute = (cmdline) ->
  args = {"/usr/bin/sh", "-c", cmdline}
  cmd = args[1]
  thread, main = coroutine.running!
  assert not main, "Error can't suspend main thread"
  in_read, in_write, out_read, out_write, err_read, err_write = stdio_pipes!

  child = ->
    epoll_fd\close!
    in_read\dup2 0
    out_write\dup2 1
    err_write\dup2 2
    close_all in_read, in_write, out_read, out_write, err_read, err_write
    S.execve cmd, args, env
    -- Normally we should never get here but we might if the cmd is missing for example
    error "Oopsie - exec error, perhaps #{cmd} can't be found?"

  parent = (child_pid) ->
    local err_data
    close_all in_read, in_write, out_write, err_write

    out = Read.new out_read, (r, fd) ->
      data = ""
      data ..= bytes for bytes in read(fd)
      r\stop!
      out_read\close!
      _, _, status = S.waitpid child_pid
      coroutine.resume thread, data, err_data, tonumber(status.status)

    err = Read.new err_read, (r, fd) ->
      data = ""
      data ..= bytes for bytes in read(fd)
      r\stop!
      err_read\close!
      err_data = data

    out\start!
    err\start!

  pid = S.fork!
  if pid == 0
    child!
  else if pid > 0
    parent pid
    coroutine.yield!
  else
    error "fork error"

command = (cmdline, ...) ->
  stdout, stderr, status = execute cmdline, ...
  if status > 0
    error "exit(#{status}): #{stderr}"
  stdout

:execute, :command
