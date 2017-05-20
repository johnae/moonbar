->
  p = io.popen("sysctl kern.cp_times")
  c = p\read!
  p\close!
  c = c\gsub "kern%.cp_times: ", ""
  values = c\split ' '
  n_cpus = #values / 5
  user = 0
  nice = 0
  sys = 0
  intr = 0
  idle = 0
  for i=1,#values,5
    user += tonumber(values[i])
    nice += tonumber(values[i+1])
    sys += tonumber(values[i+2])
    intr += tonumber(values[i+3])
    idle += tonumber(values[i+4])
  non_idle = user + nice + sys + intr
  total = idle + non_idle
  total, idle
