round = math.round
:define = require 'classy'
insert: append = table
:command = require "command"
log = _G.log

define 'PulseAudio', ->
  vol_cmd = (sink, val) -> "/usr/bin/pacmd set-sink-volume #{sink} #{val}"
  mute_cmd = (sink, val) -> "/usr/bin/pacmd set-sink-mute #{sink} #{val}"

  parse_list_sinks = (str) ->
    lines = str\split "\n"
    sinks = {}
    for idx, line in ipairs lines
      if index = line\match 'index: (%d+)'
        current = line\match('*%s+index') and true or false
        name = lines[idx+1]
        name = name\gsub 'name: ', ''
        name = name\gsub '[<>]', ''
        name = name\trim!
        sink = :current, :name, :index
        append sinks, sink
    sinks

  parse_list_sink_inputs = (str) ->
    lines = str\split "\n"
    inputs = {}
    for idx, line in ipairs lines
      if index = line\match 'index: (%d+)'
        current = line\match('*%s+index') and true or false
        sink = lines[idx+4]
        input = :sink, :index
        append inputs, input
    inputs


  static
    list_sinks: =>
      -- using synchronous built-in here since this
      -- is intended to be used in a setup context
      reader = io.popen "/usr/bin/pacmd list-sinks"
      out = reader\read '*a'
      parse_list_sinks out

  properties
    is_current: =>
      success, out = pcall command, "/usr/bin/pacmd list-sinks"
      return false unless success
      sink_list = parse_list_sinks out
      for sink in *sink_list
        if sink.name == @name
          return sink.current

    volume:
      get: =>
        success, out = pcall command, "/usr/bin/pacmd dump"
        return unless success
        for sink, value in out\gmatch 'set%-sink%-volume ([^%s]+) (0x%x+)'
          if sink == @name
            return tonumber(value) / 65536

      set: (val) =>
        val = 1 if val > 1
        val = 0 if val < 0
        vol = round val * 65536
        pcall command, vol_cmd @name, vol

    mute:=>
      success, out = pcall command, "/usr/bin/pacmd dump"
      return unless success
      for sink, value in out\gmatch 'set%-sink%-mute ([^%s]+) (%a+)'
        if sink == @name
          return value == "yes"

  instance
    -- name should be name of a sink this will control
    -- so list_sinks is a good way of doing that
    initialize: (sink) =>
      @name = sink.name
      @index = sink.index

    toggle_mute: =>
      if @mute
        pcall command, mute_cmd @name, 0
      else
        pcall command, mute_cmd @name, 1

    make_current: =>
      pcall command, "/usr/bin/pacmd set-default-sink #{@name}"
      success, out = pcall command, "/usr/bin/pacmd list-sink-inputs"
      inputs = parse_list_sink_inputs out
      for input in *inputs
        pcall command, "/usr/bin/pacmd move-sink-input #{input.index} #{@index}"
