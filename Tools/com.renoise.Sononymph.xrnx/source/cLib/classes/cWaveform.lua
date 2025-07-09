--[[===============================================================================================
cWaveform
===============================================================================================]]--

--[[--

Static methods for generating waveforms

]]

--=================================================================================================

class 'cWaveform'

--cWaveform.random_seed = 0

cWaveform.x_pre = 0
cWaveform.x_next = 0

cWaveform.brown_parameter = (1/6)

cWaveform.FORM = {
  SIN = 1,
  SAW = 2,
  SQUARE = 3,
  TRIANGLE = 4,
  WHITE_NOISE = 5,
  BROWN_NOISE = 6,
  VIOLET_NOISE = 7,
  COPY = 8,
}

---------------------------------------------------------------------------------------------------
-- Waveform generators
---------------------------------------------------------------------------------------------------
-- sine wave function
function cWaveform.sin_2pi_fn(x)
  return math.sin(x*2*math.pi) 
end
-- cosine wave function
function cWaveform.cos_fn(x)
  return math.cos(x*2*math.pi) 
end
-- saw wave function
function cWaveform.saw_fn(x)
  return 2*(x - math.floor(x + (1/2)))
end
-- Square wave function (op = pulse width)
function cWaveform.square_fn(x)
  local x = cWaveform.cycle_fmod(x)
  if 0 <= x and x<(1/2)  then 
    return 1 
  elseif (1/2) <= x and x < 1 then 
    return -1
  end
  return 0
end
-- triangle wave function
function cWaveform.triangle_fn(x)
  local x = cWaveform.cycle_fmod(x)
  if 0 <= x and x <(1/4) then 
    return 4*x
  elseif (1/4)<= x and x < (3/4) then 
    return -4*x +2
  elseif (3/4)<= x and x <=1 then 
    return 4*x -4
  end
  return 0 
end

-- white noise
function cWaveform.white_noise_fn()
  local y = math.random()
  return 2*y -1
end

-- brown noise
function cWaveform.brown_noise_fn()
  local r = (2*math.random() -1) * cWaveform.brown_parameter -- [-1,1] variable. default 1/6
  cWaveform.x_next = cWaveform.x_pre + r
  if cWaveform.x_next > 1 then
    cWaveform.x_next = 1
  elseif cWaveform.x_next < -1 then
   cWaveform.x_next = -1
  end 
  cWaveform.x_pre = cWaveform.x_next
  return cWaveform.x_next
end

-- violet noise
function cWaveform.violet_noise_fn()
  local r = (2*math.random()-1)
  cWaveform.x_next = (r - cWaveform.x_pre)/2
  cWaveform.x_pre = r
  return cWaveform.x_next
end

-- pink noise
function cWaveform.pink_noise_fn()
  local r = (2*math.random() -1)
  *(1/100) -- [-1,1] variable.
  local tmax = math.modf(biased_noise() *5)
  for t = 1,tmax+1 do
    cWaveform.x_next = cWaveform.x_pre + r
    cWaveform.x_pre = cWaveform.x_next
  end
  if cWaveform.x_next >1 then
    cWaveform.x_next = 1
  elseif cWaveform.x_next < -1 then
   cWaveform.x_next = -1
  end 
  return cWaveform.x_next
end

-- Pink noise(not finished)
-- The Voss-McCartney algorithm
-- http://www.firstpr.com.au/dsp/pink-noise/
--[[
function cWaveform.biased_noise()
  local r, r1, r2 =  nil, math.random(), math.random()
  if r2 <= r1 then r = r1
  elseif r2 > r1 then r = (1- r1)
  end
  return r
end
]]
  
---------------------------------------------------------------------------------------------------

function cWaveform.mix_fn_fn(fn1,fn2,deg)
  local d = (1/2)
  if type(deg) == 'number' then d = deg end
  return function(x,ch)
    --print("fn1",x,ch,fn1(x,ch)*d)
    --print("fn2",x,ch,fn2(x,ch)*(1-d))
    return fn1(x,ch)*d + fn2(x,ch)*(1-d)
  end
end

---------------------------------------------------------------------------------------------------

function cWaveform.band_limited_fn_fn(
  form,cycle,shift,duty_onoff,
  duty_fiducal,duty_var,duty_var_frq,range)

  if not duty_onoff then
    duty_fiducal,duty_var,duty_var_frq = 50,0,1
  end
  local fn,mod_fn

  if (form == cWaveform.FORM.SIN) then
    fn = cWaveform.sin_2pi_fn
    mod_fn = cWaveform.cycle_phase_duty_mod(cycle,shift,duty_fiducal,duty_var,duty_var_frq)
    return fn,mod_fn
  end

  local partition_duty_mod = function()
    return function(x)
      local xx = cycle*x + (shift)
      local xxx = duty_fiducal + duty_var*(1/2)*(-1*cWaveform.cos_fn(duty_var_frq*x)+1)
      xxx = cWaveform._duty_shape(xxx,range)
      return (math.floor(xx) + cWaveform._duty_phase(math.fmod(xx,1),xxx))/cycle 
    end
  end

  local tbl ={{},{}}
  local _fn,_mod_fn
  _fn = cWaveform._blit_duty_fn_fn(form,range/cycle,duty_fiducal,range)
  _mod_fn = partition_duty_mod(cycle,0,duty_fiducal,duty_var,duty_var_frq,range)
  fn = function(x) 
    return _fn(_mod_fn(x)) 
  end
  if (shift ~= 0) then
    local p = math.floor(range*shift/cycle)
    for i = 1,range -p do
      tbl[1][i] = fn((i-1+p)/range)
    end
    for j = range-p+1,range+1 do
      tbl[1][j] = fn((j-1+p-range)/range)
    end
    fn = cWaveform.table2fn(tbl)  
  end

  local maximize_fn_fn = function (fn,m,a)
    if (a == nil) then 
      a = 1 
    end
    local max = 1/32767
    for i = 1,m do
      local y = math.abs(fn((i-1)/m))
      if (y >= max) then 
        max = y 
      end
    end
    local aa = 1/max
    return function (x)
      return aa*a* fn(x)
    end
  end

  fn =  maximize_fn_fn(fn,range,0.95)
  return fn,mod_fn

end  

---------------------------------------------------------------------------------------------------
-- Utility for changing modulate-function
-- @return function or nil

function cWaveform.mod_fn_fn(cycle,shift,duty_onoff,duty,duty_var,duty_var_frq)
  if not duty_onoff then
    return cWaveform.cycle_phase_mod(cycle,shift)
  else
    return cWaveform.cycle_phase_duty_mod(cycle,shift,duty,duty_var,duty_var_frq)
  end
end


---------------------------------------------------------------------------------------------------
-- change wave_fn & mod_fn
-- @return function

function cWaveform.wave_fn(
  form,cycle,shift,duty_onoff,
  duty,duty_var,duty_var_frq,band_limited,range)

  TRACE("cWaveform.wave_fn() - ",form,cycle,shift,duty_onoff,duty,duty_var,duty_var_frq,band_limited,range)

  local fn
  local mod = cWaveform.mod_fn_fn(cycle,shift,duty_onoff,duty,duty_var,duty_var_frq)
  
  if (form == cWaveform.FORM.WHITE_NOISE) then 
    return cWaveform.white_noise_fn
  elseif (form == cWaveform.FORM.BROWN_NOISE) then 
    return cWaveform.brown_noise_fn
  elseif (form == cWaveform.FORM.VIOLET_NOISE) then 
    return cWaveform.violet_noise_fn
  elseif (form == cWaveform.FORM.COPY) then 
    -- TODO
    -- return xSampleBuffer.copy_fn_fn()
    return cWaveform.sin_2pi_fn 
  end
    
  if not band_limited then
    if (form == cWaveform.FORM.SIN) then 
      fn = cWaveform.sin_2pi_fn
    elseif (form == cWaveform.FORM.SAW) then 
      fn = cWaveform.saw_fn
    elseif (form == cWaveform.FORM.SQUARE) then 
      fn = cWaveform.square_fn
    elseif (form == cWaveform.FORM.TRIANGLE) then 
      fn = cWaveform.triangle_fn
    end
  else
    fn,mod = cWaveform.band_limited_fn_fn(form,cycle,shift,duty_onoff,duty,duty_var,duty_var_frq,range)
  end
  if (type(mod) == 'function') then 
    return function(x) 
      return fn(mod(x)) 
    end  
  else
    return fn
  end
end


---------------------------------------------------------------------------------------------------
-- 
-- @return function

function cWaveform.cycle_phase_duty_mod (cycle,shift,duty_fiducal,duty_var,duty_var_frq)

  return function(x)
    local xx = cWaveform.cycle_fmod(cWaveform.cycle_phase_mod(cycle,shift)(x))
    local xxx = duty_fiducal + duty_var*(1/2)*(-1*cWaveform.cos_fn(duty_var_frq*x)+1) 
    local y= cWaveform._duty_phase(xx,xxx)
    return y
  end
end


---------------------------------------------------------------------------------------------------
-- @return boolean, true when x less or equal to 0 

function cWaveform._torf(x) 
  return (x <= 0) and true or false
end  

---------------------------------------------------------------------------------------------------
-- multi-random generator 
-- rndm({{0,1,1},{100,1000}}) -> 0.2, 320, 0.3 ...

function cWaveform.rndm(tbl)
  local cnt = #tbl
  local tp = math.random(cnt)
  local x1,x2,idp = tbl[tp][1],tbl[tp][2],tbl[tp][3]
  local y = (x2-x1)*math.random() + x1
  return cLib.round_with_precision(y,idp)
end

---------------------------------------------------------------------------------------------------
-- wv table

function cWaveform.rtn_random_wave(wv)
  local s = cWaveform.rndm({{1,1},{2,4},{1,4},{1,4},{1,8}})
  if (s == 1) then
    wv.form = cWaveform.FORM.SIN
  elseif (s == 2) then
    wv.form = cWaveform.FORM.SAW
  elseif (s == 3) then
    wv.form = cWaveform.FORM.SQUARE
  elseif (s == 4) then
    wv.form = cWaveform.FORM.TRIANGLE
  elseif (s == 5) then
    wv.form = cWaveform.FORM.WHITE_NOISE
  elseif (s == 6) then
    wv.form = cWaveform.FORM.BROWN_NOISE
  elseif (s == 7) then
    wv.form = cWaveform.FORM.VIOLET_NOISE
  end
  return wv
end

---------------------------------------------------------------------------------------------------
-- @param wv (table)
-- @param a (number, the coefficient for long sample)
-- @return function,table or function (when modulated)

function cWaveform.random_fn(wv,a,duty_off,range)
  TRACE("cWaveform.random_fn(wv,a,duty_off,range)",wv,a,duty_off,range)

  if a == nil then 
    a = 1 
  end

  --wv = cWaveform.rtn_rndm_mod(wv,a)
  wv.cycle = cWaveform.rndm({{2,9},{1,8},{1,4}})*a
  wv.shift = cWaveform.rndm({{0,0},{-1,1,2}})
  wv.duty = cWaveform.rndm({{50,50},{1,99},{50,52,1},{48,50,1},{10,90}})
  wv.duty_v = cWaveform.rndm({{0,0},{0,0},{-0.5,0.5,1},{-1,1,2},{0,10,2},{10,100}})
  wv.duty_v_f = cWaveform.rndm({{1,1},{-8,8},{-2000,2000}})
  wv.band_limited = cWaveform._torf(cWaveform.rndm({{1,1}}))
  wv.duty_onoff = cWaveform._torf(cWaveform.rndm({{0,0},{0,0},{0,0},{0,0},{1,1}}))
    
  if (duty_off == true) then 
    wv.duty_onoff = false 
  end
  wv = cWaveform.rtn_random_wave(wv)

  local _fn,_mod = cWaveform.wave_fn(
    wv.form,wv.cycle,wv.shift,wv.duty_onoff,
    wv.duty,wv.duty_v,wv.duty_v_f,wv.band_limited,range)
    
  if type(_mod) == 'function' then 
    return function(x) 
      return _fn(_mod(x)) 
    end  
  else
    return _fn,wv
  end

end


---------------------------------------------------------------------------------------------------
-- create random wave
-- @return function,table or function (when modulated)

function cWaveform.random_copy_fn(range)
  TRACE("cWaveform.random_copy_fn(range)",range)

  local wv = {}
  wv.cycle = cWaveform.rndm({{1,4},{0.5,0.5},{0.5,0.5}})
  wv.shift = cWaveform.rndm({{0,0}})
  wv.duty = cWaveform.rndm({{50,50},{50,50},{50,52,1},{48,50,1},{10,90}})
  wv.duty_v = cWaveform.rndm({{0,0},{0,0},{0,0},{-0.5,0.5,1},{-1,1,2},{0,10,2},{10,100}})
  wv.duty_v_f = cWaveform.rndm({{1,1},{-8,8},{-2000,2000}})
  wv.band_limited = cWaveform._torf(cWaveform.rndm({{1,1}}))
  wv.duty_onoff = cWaveform._torf(cWaveform.rndm({{0,0},{1,1},{1,1}}))
  wv.form = cWaveform.FORM.COPY

  local _fn,_mod = cWaveform.wave_fn(
    wv.form,wv.cycle,wv.shift,wv.duty_onoff,
    wv.duty,wv.duty_v,wv.duty_v_f,wv.band_limited,range)

  if (type(_mod) == 'function') then 
    return function(x) 
      return _fn(_mod(x)) 
    end  
  else
    return _fn,wv
  end

end

---------------------------------------------------------------------------------------------------
-- e.g. make_wave(cWaveform.table2fn({{0,1,0,-1,0},{}})

function cWaveform.table2fn(wave_tbl)

  local another = function(num,a,b)
    if (num == a) then 
      return b
    elseif (num == b) then 
      return a
    else 
      return nil
    end
  end

  local count_tbl = {}
  for i = 1,2 do
    count_tbl[i] = table.count(wave_tbl[i])
  end
  
  return function (x,ch)
    local _ch = ch
    if (_ch == nil) then 
      _ch = 1 
    end
    if (count_tbl[_ch] == 0) then 
      _ch = another(_ch,1,2)
    end
    if (count_tbl[_ch] == 0) then 
      return 0
    end
    local count = count_tbl[_ch]
    -- wave_tbl[_ch][count] is reference data for the last point.
    local xx = cWaveform.cycle_fmod(x*(count-1),count)
    local x1 = math.floor(xx) +1  -- first index is 1
    local x2 = x1 +1
    if (x2 >= count) then 
      x2 = count -- Near the last point
    end 
    local d = xx - (x1 -1)
    return (wave_tbl[_ch][x1]) * (1-d) + (wave_tbl[_ch][x2]) * d
  end
end  

---------------------------------------------------------------------------------------------------
-- Create random waveform 

function cWaveform.random_wave(range)
  TRACE("cWaveform.random_wave(range)",range)

  -- a: the coefficient for long sample
  local a = cLib.round_value(range/167)
  if a  < 5 then a = 1 end
  local fn = cWaveform.random_fn({},a,false,range) 
  for i= 1,5 do
    fn = cWaveform.mix_fn_fn(
      fn,cWaveform.random_fn({},a,false,range),math.random())
  end
  
  local wv_last = cWaveform.rtn_random_wave{}
  local fn_last = cWaveform.wave_fn(
    wv_last.form, a * cWaveform.rndm({{1,2},{1,4},{8,8},{16,16}}),0,false,
    50,0,1,true,range)
  
  return cWaveform.mix_fn_fn(fn,fn_last,math.random()*0.9+0.1) 
  
end

---------------------------------------------------------------------------------------------------
-- Helper functions  
---------------------------------------------------------------------------------------------------

function cWaveform._duty_shape(duty,m)
  -- d/50 integer*(1/m)
  local d = cLib.round_value((duty/50)*m)/m*50
  if d< (1/m)*50 then 
    return (1/m)*50
  elseif d > 100 then 
    return 100
  end  
  return d
end

---------------------------------------------------------------------------------------------------

function cWaveform._duty_phase(x,dty)
  local d = dty/100
  local y = 0
  if (0 <= x and x < d) then 
    return (1/(2*d))*x 
  elseif (d <= x and x <= 1) then 
    return (1/(2*(1-d)))*(x-1)+1 
  end
  return 0
end

---------------------------------------------------------------------------------------------------

function cWaveform._max_even(num)
 local n = math.floor(num)
 if (math.fmod(n,2) == 1) then 
  return n -1
 else 
  return n
 end
end

---------------------------------------------------------------------------------------------------
-- cycle_fmod (-0.2) -> 0.8

function cWaveform.cycle_fmod(x,m)
  if not m then 
    m = 1 
  end
  return math.fmod((math.fmod(x,m)+m),m)
end

---------------------------------------------------------------------------------------------------

function cWaveform.cycle_phase_mod(cycl,phs)
  return function (x)
    return cycl*x + phs
  end
end


---------------------------------------------------------------------------------------------------
-- BLITs (used for band limited waveforms)
---------------------------------------------------------------------------------------------------

function cWaveform._sinc_m_fn_fn(m)
  if m == nil then m =1 end
  return function(x)
    local xx = math.sin(math.pi * x / m)
    local y
    if math.abs(xx) <= 1e-12  then
      return math.cos(math.pi*x)/math.cos(math.pi*x/m) 
    else
      return math.sin(math.pi * x) / (m * xx) 
    end
  end
end

---------------------------------------------------------------------------------------------------
--[[
function cWaveform.blit_m_p_tbl(m,p,range)
  local sincm = cWaveform._sinc_m_fn_fn(m)
  local tbl ={{},{}}
  for i = 1,range+1 do
    tbl[1][i] =(m/p)*sincm((i-1)*(m/p))
  end
  return tbl
end
]]

---------------------------------------------------------------------------------------------------
--y(n+1) = y(n) + sin( PI * M / P * n) / (sin(PI / P * n) * P) - 1/P  

function cWaveform._blit_saw_tbl(p,shift,a,range)
  
  if (a == nil) then 
    a =1 
  end

  local max_odd = function(num)
    local n = math.floor(num)
    if (math.fmod(n,2) == 1) then 
      return n
    else 
      return n -1
    end
  end

  p = p*a
  range = range*a
  
  if (shift==nil) then 
    shift =0 
  end
  local sft = math.floor(p*cWaveform.cycle_fmod(shift+0.5))    
  local m = max_odd(p/2)
  if (m <=3) then 
    m =3 
  end  
  
  local sincm = cWaveform._sinc_m_fn_fn(m)
  local tbl_pre ={}
  local tbl ={{},{}}
  local y,y_pre =0,(m/p/2)
  local d = 1/p
  local m_p = m/p
  for i = 1,cLib.round_value(range+1+sft) do  
    y = (y_pre -(m_p)*sincm((i-1)*(m/p)) +d)
    tbl_pre[i]=y *(1/m_p*0.58)
    y_pre = y
  end
  for j = 1,cLib.round_value(range+1) do
    tbl[1][j]= tbl_pre[j+sft]
  end
  return tbl
end  

---------------------------------------------------------------------------------------------------
  
function cWaveform._blit_square_tbl(p,shift,a,range)
  if (a == nil) then 
    a = 1 
  end
  p= p*a
  range = range*a   

  if (shift==nil) then 
    shift =0 
  end
  local sft = math.floor(p*cWaveform.cycle_fmod(shift))
  local p = p/2        
  local m =  cWaveform._max_even(p/2)
  if (m <= 2) then 
    m =2 
  end
  local sincm = cWaveform._sinc_m_fn_fn(m)
  local tbl_pre ={}
  local tbl ={{},{}}
  local y,y_pre =0,-(m/p/2)
  local m_p = m/p
  for i = 1,cLib.round_value(range+1+sft) do  
    y = (y_pre +(m_p)*sincm((i-1)*(m/p)) )
    tbl_pre[i]=y *(1/m_p*0.58)
    y_pre = y
  end
  for j = 1,cLib.round_value(range+1) do
    tbl[1][j]= tbl_pre[j+sft]
  end  
  return tbl
end  

---------------------------------------------------------------------------------------------------

function cWaveform._blit_triangle_tbl(p,shift,a,range)
  if (a == nil) then 
    a =1 
  end
  p= p*a
  range = range*a  

  if (shift==nil) then 
    shift =0 
  end
  local sft = math.floor(p*cWaveform.cycle_fmod(shift+0.25))
  local pp = p/2        
  local m =  cWaveform._max_even(pp/2)
  if (m <= 2) then 
    m =2 
  end  
  local sincm = cWaveform._sinc_m_fn_fn(m)
  local square = {}
  local tbl_pre ={}
  local tbl ={{},{}}
  local m_pp = m/pp  
  local y,y_pre =0,-(m_pp/2)
  local yy,yy_pre = 0,-(m_pp/2)
  for i = 1,cLib.round_value(range+1+sft) do  
    y = (y_pre +(m_pp)*sincm((i-1)*(m/pp)) )
    square[i]=y 
    y_pre = y
  end      
  for j = 1,cLib.round_value(range+1+sft) do 
    yy= yy_pre + square[j]/pp
    tbl_pre[j] = yy*(1/(m_pp/2)*0.8)
    yy_pre = yy
  end
  for k = 1,cLib.round_value(range+1) do
    tbl[1][k]= tbl_pre[k+sft]
  end  
  return tbl 
end   

---------------------------------------------------------------------------------------------------
-- @return function

function cWaveform._blit_duty_fn_fn(form,p,duty,range)
  TRACE("cWaveform._blit_duty_fn_fn(form,p,duty,range)",form,p,duty,range)
  --print("duty "..duty)
  local form_f = cWaveform._blit_square_tbl
  if (form == cWaveform.FORM.SAW) then 
    form_f = cWaveform._blit_saw_tbl
  elseif (form == cWaveform.FORM.SQUARE) then 
    form_f = cWaveform._blit_square_tbl
  elseif (form == cWaveform.FORM.TRIANGLE) then 
    form_f = cWaveform._blit_triangle_tbl
  end
  
  duty = cWaveform._duty_shape(duty,range)
  local half = cWaveform._duty_shape(50,range) 
  local a1,a2  
  a1 = (duty/50) ;a2 = 2 - a1
  local fn_1,fn_2,m_1,m_2
  fn_1 = cWaveform.table2fn(form_f(p,0,a1,range))
  fn_2 = cWaveform.table2fn(form_f(p,0,a2,range))
  return function(x)
    local xx = math.fmod(x,(p/range))/(p/range)
    local out
    if (xx < 0.5) then 
      return fn_1(x,1)
    elseif (xx >= 0.5) then 
      return fn_2(x,1)
    else 
      return 0
    end
  end 
end

