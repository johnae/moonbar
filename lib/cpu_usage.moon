:round = math
os = require'syscall'.abi.os
system = os == 'linux' and 'linux' or 'bsd'
cpu_stats = require "#{system}.cpu_stats"

cpu_total = 0
cpu_idle = 0

->
  prev_total, prev_idle = cpu_total, cpu_idle
  cpu_total, cpu_idle = cpu_stats!
  unless type(cpu_total) == 'number'
    cpu_total = 0
  unless type(cpu_idle) == 'number'
    cpu_idle = 0
  round(((cpu_total-prev_total)-(cpu_idle-prev_idle))/(cpu_total-prev_total)*100,2)
