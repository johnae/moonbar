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

read = (fd, count = 4096) -> ->
  bytes, err = fd\read nil, count
  return "", err if err
  return nil if #bytes == 0
  bytes

process_env = (opts={}) ->
  env = {k, v for k, v in pairs S.environ!}
  if opts.env
    for k, v in pairs opts.env
      env[k] = v
  ["#{k}=#{v}" for k, v in pairs env]

execute = (cmdline, opts={}) ->
  args = {"/bin/sh", "-c", cmdline}
  env = process_env(opts)
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
    local err_data, out_data
    close_all in_read, in_write, out_write, err_write
    out_read\nonblock!
    err_read\nonblock!
    on_read = opts.on_read or ->
    on_err = opts.on_err or ->

    out = Read.new out_read, (r, fd) ->
      for bytes, err in read(fd)
        return if err and err.again
        error err if err
        out_data = "" unless out_data
        on_read bytes
        out_data ..= bytes
      r\stop!
      out_read\close!
      _, _, status = S.waitpid child_pid
      coroutine.resume thread, out_data, err_data, status.EXITSTATUS

    err = Read.new err_read, (r, fd) ->
      for bytes, err in read(fd)
        return if err and err.again
        error err if err
        err_data = "" unless err_data
        on_err bytes
        err_data ..= bytes
      r\stop!
      err_read\close!

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
