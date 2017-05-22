S = require "syscall"
fs = require 'fs'
:spawn = require 'process'
:floor = math
rbsnap = "#{os.getenv('HOME')}/Local/bin/rbsnap"
remote = os.getenv('RBSNAP_REMOTE')
port = os.getenv('RBSNAP_PORT')

(log) ->
  (remote, port, backup, backup_every) ->
    unless backup_every
      log.info "Note: using default backup time of 30 minutes"
      backup_every = 60*30

    backing_up = false
    successful = true
    latest_backup_path = "#{backup}/.backup-latest"

    last_status = -> successful
    
    can_backup = ->
      return false unless (backup and backup != "")
      return false unless (port and port != "")
      return false unless (remote and remote != "")
      fs.is_present(backup)

    human_time = (time_left_secs) ->
      days = floor(time_left_secs / 3600 / 24 % 24)
      hours = floor(time_left_secs / 3600 % 60)
      mins = floor(time_left_secs / 60 % 60)
      secs = time_left_secs % 60
      return days, hours, mins, secs

    cached_time = 0
    time_of_last_backup = ->
      return cached_time if os.time! - cached_time < 60
      cached_time = if fs.is_present latest_backup_path
        S.stat(latest_backup_path).ctime
      else
        os.time!-(86400*30) -- ~a month ago by default
      cached_time

    human_time_until_next_backup = ->
      time_left_secs = backup_every - (os.time! - time_of_last_backup!)
      days, hours, mins, secs = human_time time_left_secs
      "#{mins}m #{secs}s to next"

    human_time_of_last_backup = ->
      msg = last_status! and 'last' or 'failed'
      os.date("#{msg}: %b-%d %H:%M", time_of_last_backup!)

    time_since_last_backup = ->
      os.time! - time_of_last_backup!

    backup_is_due = ->
      return false if backing_up
      time_since_last_backup! > backup_every

    backup_now = ->
      return if backing_up
      backing_up = true
      status = spawn "/usr/bin/sudo #{rbsnap} #{backup} #{remote} #{port}", on_err: log.error, on_read: log.info
      backing_up = false
      successful = status == 0
      successful

    return {
      backing_up: -> backing_up
      :can_backup
      :time_since_last_backup
      :human_time_until_next_backup
      :human_time_of_last_backup
      :backup_is_due
      :backup_now
      :last_status
    }
