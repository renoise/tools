--[[ Math ]]--

-- greatest common divisor
function gcd(m,n)
  while n ~= 0 do
    local q = m
    m = n
    n = q % n
  end
  return m
end

-- least common multiplier (2 args)
function lcm(m,n)
  return ( m ~= 0 and n ~= 0 ) and m * n / gcd( m, n ) or 0
end

-- find least common multiplier with N args
function least_common(...)
  local cm = arg[1]
  for i=1,#arg-1,1 do
    cm = lcm(cm,arg[i+1])
  end
  return cm
end


--[[ Midi ]]--

function midi_debug(message)

  print(("  message:is_trigger(): %s)"):format(
    message:is_trigger() and "yes" or "no"))
  print(("  message:is_switch(): %s)"):format(
    message:is_switch() and "yes" or "no"))
  print(("  message:is_rel_value(): %s)"):format(
    message:is_rel_value() and "yes" or "no"))
  print(("  message:is_abs_value(): %s)"):format(
    message:is_abs_value() and "yes" or "no"))
  print(("  message.int_value: %d)"):format(
    message.int_value))
  print(("  message.boolean_value: %s)"):format(
    message.boolean_value and "true" or "false"))
  print("---------------------------------------------------------------------")

end