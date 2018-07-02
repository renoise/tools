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

  --- number, multiply mod_cycle when producing "perfectly tuned" waves
  self.cycle_multiplier = 1

  --- function, last random generator (for re-use)
  self.random_wave_fn = nil 
  self.random_generated_observable = renoise.Document.ObservableBang()  

  --- cWaveform.FORM, last selected wave generator (0 means none)
  self.recently_generated = property(self.get_recently_generated,self.set_recently_generated)
  self.recently_generated_observable = renoise.Document.ObservableNumber(0)

  --- boolean, true while sample(s) are being generated 
  self.in_progress = property(self.get_in_progress,self.set_in_progress)
  self.in_progress_observable = renoise.Document.ObservableBoolean(false)

  --- boolean, true when the waveform should update
  self.update_wave_requested = false

  -- == Observables ==

  self.prefs.mod_cycle:add_notifier(function()
    self.mod_cycle = cReflection.evaluate_string(self.prefs.mod_cycle.value)
  end)

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

function SSK_Generator:get_in_progress()
  return self.in_progress_observable.value
end 

function SSK_Generator:set_in_progress(val)
  self.in_progress_observable.value = val
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
    if self.prefs.auto_generate.value then 
      self.update_wave_requested = true
    end
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

  if self.prefs.multisample_mode.value
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

  if self.in_progress then 
    -- take no further action
    return true,"Sample generation is already in progress"
  end 

  if not self:can_generate_multisample() then 
    -- proceed with single waveform 
    return false,"Not currently able to generate multisamples"
  end

  self:generate_multisample(form)

  return true

end

---------------------------------------------------------------------------------------------------
-- generate multi-samples using the specified form and current layout 
-- note: runs as sliced process...
-- @param cWaveform.FORM

function SSK_Generator:generate_multisample(form)
  TRACE("SSK_Generator:generate_multisample(form)",form)

  local xmappings = xKeyZone.create_multisample_layout(self.prefs:get_multisample_layout())
  --print("xmappings",xmappings)

  -- use props from the current sample, or fallback to defaults
  local defaults = xSampleBuffer()
  local buffer = self.owner:get_sample_buffer() 
  local sample_rate = buffer and buffer.sample_rate or defaults.sample_rate
  local bit_depth = buffer and buffer.bit_depth or defaults.bit_depth
  local num_channels = buffer and buffer.number_of_channels or defaults.number_of_channels
  --print("sample_rate,bit_depth",sample_rate,bit_depth)

  local has_samples = self.owner.instrument 
    and (#self.owner.instrument.samples > 0) 
    and true or false
  --print("has_samples",has_samples)

  -- create instrument (if none)
  local instr = self.owner.instrument
  if not instr then 
    instr = rns.insert_instrument_at(xInstrument.get_first_available())
    instr.name = "Untitled instrument"
  end 

  local layer = renoise.Instrument.LAYER_NOTE_ON
  local mappings = xKeyZone.memoize_mappings(instr.sample_mappings[layer]) 
  local cached_sample_idx = rns.selected_sample_index

  -- create samples, or re-use existing ones 
  for k,v in ipairs(xmappings) do 
    --print(k,v)
    local sample
    local sample_idx 
    if has_samples then 
      -- attempt to match with instrument 
      local mapping = xKeyZone.find_mapping(mappings,v.note_range,v.velocity_range)
      if mapping then 
        sample = mapping.sample
        sample_idx = mapping.index -- ?? is this safe ? 
      end
    end

     local num_frames, repeats = SSK_Generator.ideal_buffer_length(v.base_note,sample_rate)
     self.cycle_multiplier = repeats
    

    --print("num_frames",num_frames)
    if not sample then 
      --print("create sample")
      sample_idx = #instr.samples -- insert at end 
      sample_idx = xInstrument.insert_sample(instr,sample_idx,sample_rate,bit_depth,num_channels,num_frames)
      if sample_idx then 
        sample = instr.samples[sample_idx]
        sample.name = ("SSK %d %d (%d)"):format(v.base_note,num_frames,repeats)
        sample.sample_mapping.base_note = v.base_note
        sample.sample_mapping.note_range = v.note_range
        sample.sample_mapping.velocity_range = v.velocity_range
      end 
    else 
      -- verify that sample has the right length 
      -- TODO replace with right length (but retain index)
      local tmp_buffer = xSample.get_sample_buffer(sample)
      if not tmp_buffer then 
        error("Encountered sample without data")
      elseif (tmp_buffer.number_of_frames ~= num_frames) then 
        error("Encountered sample with unexpected length")
      end 
    end 
    --print("#2 sample,sample_idx",sample,sample_idx)

    -- bring focus to sample and call our waveform generator 
    rns.selected_instrument_index = self.owner.instrument_index
    rns.selected_sample_index = sample_idx

    -- select buffer
    -- TODO make it relative to initial range 
    local tmp_buffer = xSample.get_sample_buffer(sample)
    xSampleBuffer.select_all(tmp_buffer)

    self:update_wave(form,true)

  end

  -- done, restore the selected sample (if any)
  if instr.samples[cached_sample_idx] then 
    rns.selected_sample_index = cached_sample_idx
  end

  self.cycle_multiplier = 1

end


---------------------------------------------------------------------------------------------------
-- Generators 
---------------------------------------------------------------------------------------------------
-- (auto-)update recently generated, or specific waveform 
-- @param form (cWaveform.FORM)
-- @param force (boolean), true when generating multisamples

function SSK_Generator:update_wave(form,force)
  TRACE("SSK_Generator:update_wave(form,force)",form,force)

  if not form then 
    form = self.recently_generated
  end

  local buffer = self.owner:get_sample_buffer() 
  if buffer then
    local choice = {
      [cWaveform.FORM.SIN] = function()
        self:sine_wave(force)
      end,
      [cWaveform.FORM.SAW] = function()
        self:saw_wave(force)
      end,
      [cWaveform.FORM.SQUARE] = function()
        self:square_wave(force)
      end,
      [cWaveform.FORM.TRIANGLE] = function()
        self:triangle_wave(force)
      end,
      [cWaveform.FORM.BROWN_NOISE] = function()
        self:brown_noise(force)
      end,
      [cWaveform.FORM.VIOLET_NOISE] = function()
        self:violet_noise(force)
      end,
      [cWaveform.FORM.WHITE_NOISE] = function()
        self:white_noise(force)
      end,
      -- [cWaveform.FORM.RANDOM] = function()
      --   self:white_noise()
      -- end,
    }
    if choice[form] then 
      choice[form]()
    end 
  end
end    


---------------------------------------------------------------------------------------------------

function SSK_Generator:set_wave_fn(form)
  TRACE("SSK_Generator:set_wave_fn(form)",form)

  self.wave_fn = cWaveform.wave_fn(form,
    self.mod_cycle * self.cycle_multiplier,
    self.prefs.mod_shift.value/100,
    self.prefs.mod_duty_onoff.value,
    self.prefs.mod_duty.value,
    self.prefs.mod_duty_var.value,
    self.prefs.mod_duty_var_frq.value * self.cycle_multiplier,
    self.prefs.band_limited.value,
    self.owner.selection:get_range())
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

  if not force and self:invoke_multisample(cWaveform.FORM.WHITE_NOISE) then 
    return
  end
  
  self.recently_generated = 0 --cWaveform.FORM.WHITE_NOISE
  self.owner:make_wave(cWaveform.white_noise_fn)
end 

---------------------------------------------------------------------------------------------------

function SSK_Generator:brown_noise(force)
  TRACE("SSK_Generator:brown_noise(force)",force)

  if not force and self:invoke_multisample(cWaveform.FORM.BROWN_NOISE) then 
    return
  end
  
  self.recently_generated = 0 --cWaveform.FORM.BROWN_NOISE
  self.owner:make_wave(cWaveform.brown_noise_fn)
end 

---------------------------------------------------------------------------------------------------

function SSK_Generator:violet_noise(force)
  TRACE("SSK_Generator:violet_noise(force)",force)

  if not force and self:invoke_multisample(cWaveform.FORM.VIOLET_NOISE) then 
    return
  end
  
  self.recently_generated = 0 --cWaveform.FORM.VIOLET_NOISE
  self.owner:make_wave(cWaveform.violet_noise_fn)
end 

---------------------------------------------------------------------------------------------------

function SSK_Generator:sine_wave(force)
  TRACE("SSK_Generator:sine_wave(force)",force)

  if not force and self:invoke_multisample(cWaveform.FORM.SIN) then 
    return
  end
  
  self.recently_generated = cWaveform.FORM.SIN
  self:set_wave_fn(cWaveform.FORM.SIN)
  self.mod_fn = self.owner:make_wave(self.wave_fn,self.mod_fn)
end 

---------------------------------------------------------------------------------------------------

function SSK_Generator:saw_wave(force)
  TRACE("SSK_Generator:saw_wave(force)",force)

  if not force and self:invoke_multisample(cWaveform.FORM.SAW) then 
    return
  end

  self.recently_generated = cWaveform.FORM.SAW
  self:set_wave_fn(cWaveform.FORM.SAW)
  self.mod_fn = self.owner:make_wave(self.wave_fn,self.mod_fn)
end 

---------------------------------------------------------------------------------------------------

function SSK_Generator:square_wave(force)
  TRACE("SSK_Generator:square_wave(force)",force)

  if not force and self:invoke_multisample(cWaveform.FORM.SQUARE) then 
    return
  end
  
  self.recently_generated = cWaveform.FORM.SQUARE
  self:set_wave_fn(cWaveform.FORM.SQUARE)
  self.mod_fn = self.owner:make_wave(self.wave_fn,self.mod_fn)
end 

---------------------------------------------------------------------------------------------------

function SSK_Generator:triangle_wave(force)
  TRACE("SSK_Generator:triangle_wave(force)",force)

  if not force and self:invoke_multisample(cWaveform.FORM.TRIANGLE) then 
    return
  end
  
  self.recently_generated = cWaveform.FORM.TRIANGLE
  self:set_wave_fn(cWaveform.FORM.TRIANGLE)
  self.mod_fn = self.owner:make_wave(self.wave_fn,self.mod_fn)

end 

---------------------------------------------------------------------------------------------------
-- find the ideal buffer length for a precisely tuned waveform 
-- @return number (number of frames)
-- @return number (how many times length has been multiplied/repeated)

function SSK_Generator.ideal_buffer_length(note,sample_rate)

  --print("#1 sample,sample_idx",sample,sample_idx)
  local num_frames,num_frames_fract = cConvert.note_to_frames(note,sample_rate)

  local fundamental,repeats = cLib.fundamental(num_frames_fract,10)
  if (fundamental < 2000) then 
    num_frames = fundamental
    repeats = repeats+1
  else
    repeats = 1
  end

  return num_frames,repeats

end
