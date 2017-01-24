--
-- adapted from json.lua by John Axel Eriksson https://github.com/johnae
--
-- Copyright (c) 2015 rxi
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

json = { _version:  "0.1.0" }

-------------------------------------------------------------------------------
-- Encode
-------------------------------------------------------------------------------

local encode

escape_char_map = {
  "\\": "\\\\",
  "\"": "\\\"",
  "\b": "\\b",
  "\f": "\\f",
  "\n": "\\n",
  "\r": "\\r",
  "\t": "\\t",
}

escape_char_map_inv = { ["\\/"]: "/" }
for k, v in pairs escape_char_map
  escape_char_map_inv[v] = k

escape_char = (c) -> escape_char_map[c] or string.format("\\u%04x", c\byte!)

encode_nil = (val) -> "null"

encode_table = (val, stack) ->
  res = {}
  stack = stack or {}

  -- Circular reference?
  if stack[val]
    error "circular reference"

  stack[val] = true

  if val[1] != nil or next(val) == nil
    -- Treat as array -- check keys are valid and it is not sparse
    n = 0
    for k,_ in pairs(val)
      if type(k) != "number"
        error("invalid table: mixed or invalid key types")
      n = n + 1

    if n != #val then
      error("invalid table: sparse array")

    -- Encode
    for i, v in ipairs(val)
      table.insert(res, encode(v, stack))

    stack[val] = nil
    "[#{table.concat(res, ',')}]"

  else
    -- Treat as an object
    for k, v in pairs(val)
      if type(k) != "string"
        error("invalid table: mixed or invalid key types")

      table.insert(res, encode(k, stack) .. ":" .. encode(v, stack))
    stack[val] = nil
    "{#{table.concat(res, ",")}}"

encode_string = (val) ->
  '"' .. val\gsub('[%z\1-\31\\"]', escape_char) .. '"'

encode_number = (val) ->
  -- Check for NaN, -inf and inf
  if val != val or val <= -math.huge or val >= math.huge
    error("unexpected number value '" .. tostring(val) .. "'")
  string.format("%.14g", val)

type_func_map = {
  nil:      encode_nil,
  table:    encode_table,
  string:   encode_string,
  number:   encode_number,
  boolean:  tostring
}


encode = (val, stack) ->
  t = type(val)
  f = type_func_map[t]
  if f
    return f(val, stack)
  error("unexpected type '" .. t .. "'")

json.encode = (val) -> encode(val)


-------------------------------------------------------------------------------
-- Decode
-------------------------------------------------------------------------------

local parse

create_set = (...) ->
  res = {}
  for i = 1, select("#", ...)
    res[ select(i, ...) ] = true
  res

space_chars   = create_set(" ", "\t", "\r", "\n")
delim_chars   = create_set(" ", "\t", "\r", "\n", "]", "}", ",")
escape_chars  = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")
literals      = create_set("true", "false", "null")

literal_map = {
  true:   true,
  false:  false,
  null:   nil,
}

next_char = (str, idx, set, negate) ->
  for i = idx, #str
    if set[str\sub(i, i)] != negate
      return i
  #str + 1

decode_error = (str, idx, msg) ->
  line_count = 1
  col_count = 1
  for i = 1, idx - 1
    col_count = col_count + 1
    if str\sub(i, i) == "\n"
      line_count = line_count + 1
      col_count = 1
  error( string.format("%s at line %d col %d", msg, line_count, col_count) )

codepoint_to_utf8 = (n) ->
  -- http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=iws-appendixa
  f = math.floor
  if n <= 0x7f
    return string.char(n)
  elseif n <= 0x7ff
    return string.char(f(n / 64) + 192, n % 64 + 128)
  elseif n <= 0xffff
    return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
  elseif n <= 0x10ffff
    return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128, f(n % 4096 / 64) + 128, n % 64 + 128)
  error( string.format("invalid unicode codepoint '%x'", n) )

parse_unicode_escape = (s) ->
  n1 = tonumber s\sub(3, 6),  16
  n2 = tonumber s\sub(9, 12), 16
  -- Surrogate pair?
  if n2
    return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000)
  else
    return codepoint_to_utf8(n1)

parse_string = (str, i) ->
  has_unicode_escape = false
  has_surrogate_escape = false
  has_escape = false
  local last
  for j = i + 1, #str
    x = str\byte j

    if x < 32
      decode_error str, j, "control character in string"

    if last == 92 -- "\\" (escape char)
      if x == 117 -- "u" (unicode escape sequence)
        hex = str\sub j + 1, j + 5
        unless hex\find "%x%x%x%x"
          decode_error str, j, "invalid unicode escape in string"

        if hex\find "^[dD][89aAbB]"
          has_surrogate_escape = true
        else
          has_unicode_escape = true

      else
        c = string.char x
        unless escape_chars[c]
          decode_error str, j, "invalid escape char '" .. c .. "' in string"
        has_escape = true
      last = nil

    elseif x == 34 -- '"' (end of string)
      s = str\sub i + 1, j - 1
      if has_surrogate_escape
        s = s\gsub "\\u[dD][89aAbB]..\\u....", parse_unicode_escape
      if has_unicode_escape
        s = s\gsub "\\u....", parse_unicode_escape
      if has_escape
        s = s\gsub "\\.", escape_char_map_inv

      return s, j + 1
    else
      last = x
  decode_error str, i, "expected closing quote for string"


parse_number = (str, i) ->
  x = next_char str, i, delim_chars
  s = str\sub i, x - 1
  n = tonumber s
  unless n
    decode_error str, i, "invalid number '" .. s .. "'"
  return n, x

parse_literal = (str, i) ->
  x = next_char str, i, delim_chars
  word = str\sub i, x - 1
  unless literals[word]
    decode_error str, i, "invalid literal '" .. word .. "'"
  return literal_map[word], x

parse_array = (str, i) ->
  res = {}
  n = 1
  i = i + 1
  while true do
    local x
    i = next_char str, i, space_chars, true
    -- Empty / end of array?
    if str\sub(i, i) == "]"
      i = i + 1
      break
    -- Read token
    x, i = parse str, i
    res[n] = x
    n = n + 1
    -- Next token
    i = next_char str, i, space_chars, true
    chr = str\sub i, i
    i = i + 1
    break if chr == "]"
    decode_error(str, i, "expected ']' or ','") if chr !=','
  return res, i

parse_object = (str, i) ->
  res = {}
  i = i + 1
  while true do
    local key, val
    i = next_char str, i, space_chars, true
    -- Empty / end of object?
    if str\sub(i, i) == "}"
      i = i + 1
      break
    -- Read key
    if str\sub(i, i) != '"' then
      decode_error str, i, "expected string for key"

    key, i = parse str, i
    -- Read ':' delimiter
    i = next_char str, i, space_chars, true
    if str\sub(i, i) != ":"
      decode_error str, i, "expected ':' after key"
    i = next_char str, i + 1, space_chars, true
    -- Read value
    val, i = parse str, i
    -- Set
    res[key] = val
    -- Next token
    i = next_char str, i, space_chars, true
    chr = str\sub i, i
    i = i + 1
    break if chr == "}"
    decode_error(str, i, "expected '}' or ','") if chr !=','
  return res, i

char_func_map = {
  '"': parse_string,
  "0": parse_number,
  "1": parse_number,
  "2": parse_number,
  "3": parse_number,
  "4": parse_number,
  "5": parse_number,
  "6": parse_number,
  "7": parse_number,
  "8": parse_number,
  "9": parse_number,
  "-": parse_number,
  "t": parse_literal,
  "f": parse_literal,
  "n": parse_literal,
  "[": parse_array,
  "{": parse_object,
}


parse = (str, idx) ->
  chr = str\sub idx, idx
  f = char_func_map[chr]
  return f(str, idx) if f
  decode_error str, idx, "unexpected character '" .. chr .. "'"

json.decode = (str) ->
  if type(str) != "string"
    error "expected argument of type string, got " .. type(str)
  parse(str, next_char(str, 1, space_chars, true))

json
