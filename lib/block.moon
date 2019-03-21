def = require'classy'.define
log = _G.log
:after = require 'moonbar_util'

-- this is the table of i3 bar info, each
-- block adds itself to this table
blocklist = {}
named_blocks = {}

clear_blocklist = ->
  for k in pairs named_blocks
    named_blocks[k] = nil
  for k in pairs blocklist
    blocklist[k] = nil

Block = def 'Block', ->
  exports = {
    'interval'
    'label'
    'text'
    'color'
    'separator_block_width'
    'update'
    'on_update'
    'on_left_click'
    'on_middle_click'
    'on_right_click'
    'on_scroll_up'
    'on_scroll_down'
  }

  handler_exports = {
    'label'
    'text'
    'color'
  }

  instance
    initialize: (name) =>
      blocklist[#blocklist + 1] = @
      named_blocks[name] = @
      @_label = ''
      @_color = '#FFFFFF'
      @_text = ''
      @name = name
      @_separator_block_width = 30
      @left_click = ->
      @right_click = ->
      @middle_click = ->
      @scroll_up = ->
      @scroll_down = ->
      @block_env = {name, ((arg) -> @[name](@, arg)) for name in *exports}
      setmetatable @block_env, __index: _G
      @handler_env = {name, ((arg) -> @[name](@, arg)) for name in *handler_exports}
      setmetatable @handler_env, __index: _G

    color: (clr) =>
      @_color = clr if clr
      @_color

    label: (l) =>
      @_label = l if l
      @_label

    text: (t) =>
      @_text = t if t
      @_text

    separator_block_width: (w) =>
      @_separator_block_width = w if w
      @_separator_block_width

    interval: (ival) =>
      @stop!
      @timer = spook\every ival, (t) -> @update!
      @timer\start!

    update: => @_on_update! if @_on_update

    stop: => @timer\stop! if @timer

    on_update: (func) =>
      setfenv func, @handler_env
      @_on_update = -> func @

    on_left_click: (func) =>
      setfenv func, @handler_env
      @left_click = (event) -> func @, event

    on_right_click: (func) =>
      setfenv func, @handler_env
      @right_click = (event) -> func @, event

    on_middle_click: (func) =>
      setfenv func, @handler_env
      @middle_click = (event) -> func @, event

    on_scroll_up: (func) =>
      setfenv func, @handler_env
      @scroll_up = (event) -> func @, event

    on_scroll_down: (func) =>
      setfenv func, @handler_env
      @scroll_down = (event) -> func @, event

    to_table: =>
      {
        _label: label,
        _color: color,
        _text: text,
        _separator_block_width: separator_block_width
        :name
      } = @
      full_text = "#{label}#{text}"
      short_text = text
      :label, :color, :full_text, :name, :separator_block_width, :short_text

block = (name, setup) ->
  b = Block.new name
  setfenv setup, b.block_env
  setup!
  after 0.1, (t) -> b\update!
  b

:block, :blocklist, :named_blocks, :clear_blocklist
