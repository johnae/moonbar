{:rshift} = require "bit"
{:round} = math
S = require "syscall"
nl = S.nl
C = require "syscall.linux.constants"
{:UNIVERSE} = C.RT_SCOPE

interfaces = ->
  ifaces = nl.getlink!
  routes = nl.routes "inet", "unspec"
  default = ([route for route in *routes when route.rtmsg.rtm_scope == UNIVERSE])[1]
  default_output = nil
  if default
    default_output = default.output
  ifaces, default_output

interface_stats = (iface) ->
  return unless iface and iface.stats
  return iface.stats.rx_bytes, iface.stats.tx_bytes

(opts={}) ->
  setmetatable {
    rx: 0,
    tx: 0,
    up: false,
    rx_rate: 0,
    tx_rate: 0,
    receive_rate: 0
    transmit_rate: 0
    rx_unit: "K",
    tx_unit: "K",
    stamp: os.time!,
    error: nil
  }, __call: (tbl) ->
    success, ifaces, default = pcall interfaces
    return nil, "Oops: #{ifaces}" unless success and ifaces
    interface = opts.interface or default
    unless interface and ifaces[interface]
      return nil, "No such interface '#{interface}'"

    tbl.rx_unit = "K"
    tbl.tx_unit = "K"
    iface = ifaces[interface]
    {rx: orx,tx: otx, stamp: ostamp} = tbl
    rx, tx = interface_stats iface
    unless rx and tx and orx and otx
      for k,v in pairs(tbl)
        if type(v) == "number"
          tbl[k] = 0
      tbl.up = false

    tbl.up = true
    tbl.rx = rx
    tbl.tx = tx
    stamp = os.time!
    elapsed = stamp - ostamp
    tbl.stamp = stamp
    rx_diff = rx - orx 
    tx_diff = tx - otx
    rx_rate = rx_diff / elapsed
    tx_rate = tx_diff / elapsed
    rx_kib = rshift rx_rate, 10
    tx_kib = rshift tx_rate, 10
    if rx_rate > 1048576
      rx_kib /= 1024
      tbl.rx_unit = "M"
    if tx_rate > 1048576
      tx_kib /= 1024
      tbl.tx_unit = "M"
    r = round rx_kib, 1
    t = round tx_kib, 1
    tbl.interface = interface
    tbl.receive_rate = r
    tbl.transmit_rate = t
    true
