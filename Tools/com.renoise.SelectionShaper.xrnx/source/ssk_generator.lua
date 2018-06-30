--[[===============================================================================================
SSK
===============================================================================================]]--

--[[

Waveform generators for the SSK tool 

]]

--=================================================================================================

class 'SSK_Generator'

function SSK_Generator:__init(owner)

  assert(type(owner)=="SSK")

  self.owner = owner 
  self.prefs = owner.prefs 

  --- function, draw modulated wave
  self.wave_fn = nil
  self.mod_fn = nil

  --- mod_shift:[-1,1]
  self.mod_cycle = cReflection.evaluate_string(self.prefs.mod_cycle.value)

  --- function, last random generator (for re-use)
  self.random_wave_fn = nil 
  self.random_generated_observable = renoise.Document.ObservableBang()  

  --- cWaveform.FORM, last selected wave generator (0 means none)
  self.recently_generated = property(self.get_recently_generated,self.set_recently_generated)
  self.recently_generated_observable = renoise.Document.ObservableNumber(0)

  --- boolean, true when the waveform should update
  self.update_wave_requested = false

  --- boolean, true while sample(s) are being generated 
  self.generation_in_progress = false

  -- == Observables ==

  renoise.tool().app_idle_observable:add_notifier(function()
    self:idle_notifier()
  end)

  self:attach_realtime_methods()

end

---------------------------------------------------------------------------------------------------
-- Getters & setters
---------------------------------------------------------------------------------------------------

function SSK_Generator:get_recently_generated()
  return self.recently_generated_observable.value
end 

function SSK_Generator:set_recently_generated(val)
  self.recently_generated_observable.value = val
end 

---------------------------------------------------------------------------------------------------
-- Class methods
---------------------------------------------------------------------------------------------------
-- execute realtime generating waveforms

function SSK_Generator:attach_realtime_methods()
  TRACE("SSK_Generator:attach_realtime_methods()")

  -- schedule update 
  local update_wave = function()
    --print("*** update_wave")
    self.update_wave_requested = true
  end

  self.prefs.band_limited:add_notifier(update_wave)
  self.prefs.mod_cycle:add_notifier(update_wave)
  self.prefs.mod_shift:add_notifier(update_wave)
  self.prefs.mod_duty_onoff:add_notifier(update_wave)
  self.prefs.mod_duty:add_notifier(update_wave)
  self.prefs.mod_duty_var:add_notifier(update_wave)
  self.prefs.mod_duty_var_frq:add_notifier(update_wave)

end

---------------------------------------------------------------------------------------------------

function SSK_Generator:idle_notifier()
  --TRACE("SSK_Generator:idle_notifier()")

  if self.update_wave_requested 
    and self.wave_fn and self.recently_generated 
  then 
    self.update_wave_requested = false
    self:update_wave()
  end 

end

---------------------------------------------------------------------------------------------------
-- Multisample methods 
---------------------------------------------------------------------------------------------------
-- detect if we have the ability to generate multisamples 
-- @return boolean

function SSK_Generator:can_generate_multisample()
  TRACE("SSK_Generator:can_generate_multisample()")

  if not self.prefs.multisample_mode.value 
    or not self.owner.instrument
  then
    return false
  end

  local buffer = self.owner:get_sample_buffer()
  if buffer 
    or (#self.owner.instrument.samples == 0) 
    or (self.owner.sample_index == 0)
  then 
    return true
  end 

  return false

end

---------------------------------------------------------------------------------------------------
-- begin generating multisamples if possible, and not already in progress
-- @param cWaveform.FORM
-- @return boolean 

function SSK_Generator:invoke_multisample(form)
  TRACE("SSK_Generator:invoke_multisample(form)",form)

  if self.generation_in_progress then 
    return false,"Multisample generation is already in progress"
  end 

  if not self:can_generate_multisample() then 
    return false,"Not currently able to generate multisamples"
  end

  self:generate(form)

  return true

end

---------------------------------------------------------------------------------------------------
-- generate multi-samples using the specified form and current layout 
-- note: runs as sliced process...
-- @param cWaveform.FORM

function SSK_Generator:generate(form)
  TRACE("SSK_Generator:generate(form)",form)

  local xlayout = xKeyZone.create_multisample_layout(self.prefs:get_multisample_layout())
  print("xlayout",xlayout)

  -- use props from the current sample, or fallback to defaults
  local defaults = xSampleBuffer.get_default_properties()
  local buffer = self.owner:get_sample_buffer() 
  local srate = buffer and buffer.sample_rate or defaults.sample_rate
  

  for k,v in ipairs(xlayout) do 
    -- TODO
  end

end


---------------------------------------------------------------------------------------------------
-- Generators 
---------------------------------------------------------------------------------------------------
-- (auto-)update recently generated

function SSK_Generator:update_wave()
  TRACE("SSK_Generator:update_wave()")
  local buffer = self.owner:get_sample_buffer() 
  if buffer then
    local choice = {
      [cWaveform.FORM.SIN] = function()
        self:sine_wave()
      end,
      [cWaveform.FORM.SAW] = function()
        self:saw_wave()
      end,
      [cWaveform.FORM.SQUARE] = function()
        self:square_wave()
      end,
      [cWaveform.FORM.TRIANGLE] = function()
        self:triangle_wave()
      end,
    }
    if choice[self.recently_generated] then 
      choice[self.recently_generated]()
    end 
  end
end    


---------------------------------------------------------------------------------------------------
-- Create random waveform 

function SSK_Generator:random_wave()
  TRACE("SSK_Generator:random_wave()")

  local range = self.owner.selection:get_range()
  -- TODO move from cWaveform to here...
  self.random_wave_fn = cWaveform.random_wave(range)
  self.owner:make_wave(self.random_wave_fn)
  self.random_generated_observable:bang()

  -- 1/10th chance of additional spice 
  --[[
  if (math.random() < 0.1) then
    local max = math.random(3)
    for i = 1,max do
      self.owner:make_wave(cWaveform.random_copy_fn(range))
    end
  end
  ]]

end

---------------------------------------------------------------------------------------------------
-- Create random waveform 

function SSK_Generator:repeat_random_wave()
  TRACE("SSK_Generator:repeat_random_wave()")

  if not self.random_wave_fn then 
    return 
  end 

  local range = self.owner.selection:get_range()
  self.owner:make_wave(self.random_wave_fn)

end

---------------------------------------------------------------------------------------------------

function SSK_Generator:white_noise(force)
  TRACE("SSK_Generator:white_noise(force)",force)

  if not force and self:invoke_multisample(cWaveform.FORM.SAW) then 
    return
  end
  
  self.recently_generated = cWaveform.FORM.WHITE_NOISE
  self.owner:make_wave(cWaveform.white_noise_fn)
end 

---------------------------------------------------------------------------------------------------

function SSK_Generator:brown_noise(force)
  TRACE("SSK_Generator:brown_noise(force)",force)

  if not force and self:invoke_multisample(cWaveform.FORM.SAW) then 
    return
  end
  
  self.recently_generated = cWaveform.FORM.BROWN_NOISE
  self.owner:make_wave(cWaveform.brown_noise_fn)
end 

---------------------------------------------------------------------------------------------------

function SSK_Generator:violet_noise(force)
  TRACE("SSK_Generator:violet_noise(force)",force)

  if not force and self:invoke_multisample(cWaveform.FORM.SAW) then 
    return
  end
  
  self.recently_generated = cWaveform.FORM.VIOLET_NOISE
  self.owner:make_wave(cWaveform.violet_noise_fn)
end 

---------------------------------------------------------------------------------------------------

function SSK_Generator:sine_wave(force)
  TRACE("SSK_Generator:sine_wave(force)",force)

  if not force and self:invoke_multisample(cWaveform.FORM.SAW) then 
    return
  end
  
  self.recently_generated = cWaveform.FORM.SIN
  self.wave_fn = cWaveform.wave_fn(cWaveform.FORM.SIN,
    self.mod_cycle,
    self.prefs.mod_shift.value/100,
    self.prefs.mod_duty_onoff.value,
    self.prefs.mod_duty.value,
    self.prefs.mod_duty_var.value,
    self.prefs.mod_duty_var_frq.value,
    self.prefs.band_limited.value,
    self.owner.selection:get_range())
  self.mod_fn = self.owner:make_wave(self.wave_fn,self.mod_fn)
end 

---------------------------------------------------------------------------------------------------

function SSK_Generator:saw_wave(force)
  TRACE("SSK_Generator:saw_wave(force)",force)

  if not force and self:invoke_multisample(cWaveform.FORM.SAW) then 
    return
  end

  self.recently_generated = cWaveform.FORM.SAW
  self.wave_fn = cWaveform.wave_fn(cWaveform.FORM.SAW,
    self.mod_cycle,
    self.prefs.mod_shift.value/100,
    self.prefs.mod_duty_onoff.value,
    self.prefs.mod_duty.value,
    self.prefs.mod_duty_var.value,
    self.prefs.mod_duty_var_frq.value,
    self.prefs.band_limited.value,
    self.owner.selection:get_range())
  self.mod_fn = self.owner:make_wave(self.wave_fn,self.mod_fn)
end 

---------------------------------------------------------------------------------------------------

function SSK_Generator:square_wave(force)
  TRACE("SSK_Generator:square_wave(force)",force)

  if not force and self:invoke_multisample(cWaveform.FORM.SAW) then 
    return
  end
  
  self.recently_generated = cWaveform.FORM.SQUARE
  self.wave_fn = cWaveform.wave_fn(cWaveform.FORM.SQUARE,
    self.mod_cycle,
    self.prefs.mod_shift.value/100,
    self.prefs.mod_duty_onoff.value,
    self.prefs.mod_duty.value,
    self.prefs.mod_duty_var.value,
    self.prefs.mod_duty_var_frq.value,
    self.prefs.band_limited.value,
    self.owner.selection:get_range())
  self.mod_fn = self.owner:make_wave(self.wave_fn,self.mod_fn)
end 

---------------------------------------------------------------------------------------------------

function SSK_Generator:triangle_wave(force)
  TRACE("SSK_Generator:triangle_wave(force)",force)

  if not force and self:invoke_multisample(cWaveform.FORM.SAW) then 
    return
  end
  
  self.recently_generated = cWaveform.FORM.TRIANGLE
  self.wave_fn = cWaveform.wave_fn(cWaveform.FORM.TRIANGLE,
    self.mod_cycle,
    self.prefs.mod_shift.value/100,
    self.prefs.mod_duty_onoff.value,
    self.prefs.mod_duty.value,
    self.prefs.mod_duty_var.value,
    self.prefs.mod_duty_var_frq.value,
    self.prefs.band_limited.value,
    self.owner.selection:get_range())
  self.mod_fn = self.owner:make_wave(self.wave_fn,self.mod_fn)

end 

