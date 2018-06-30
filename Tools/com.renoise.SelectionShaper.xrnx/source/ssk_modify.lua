--[[===============================================================================================
SSK_Modify
===============================================================================================]]--

--[[

Waveform modifiers for the SSK tool 

]]

--=================================================================================================

-- allow access through static methods
local _prefs_ = nil

---------------------------------------------------------------------------------------------------

class 'SSK_Modify'

function SSK_Modify:__init(owner)
  TRACE("SSK_Modify:__init(owner)",owner)

  assert(type(owner)=="SSK")

  self.owner = owner 
  self.prefs = owner.prefs 
  _prefs_ = owner.prefs 

  --- function, draw modulated wave
  self.mod_fade_fn = nil
  --- mod_fade_shift:[-1,1]
  self.mod_fade_cycle = cReflection.evaluate_string(self.prefs.mod_fade_cycle.value)

end

---------------------------------------------------------------------------------------------------

function SSK_Modify:phase_shift_with_ratio(ratio)
  TRACE("SSK_Modify:phase_shift_with_ratio(ratio)",ratio)

  local buffer = self.owner:get_sample_buffer() 
  if buffer then 
    local range = xSampleBuffer.get_selection_range(buffer)
    self:phase_shift_fine(range*ratio)
  end 

end

---------------------------------------------------------------------------------------------------

function SSK_Modify:phase_shift_fine(frame)
  TRACE("SSK_Modify:phase_shift_fine(frame)",frame)

  local buffer = self.owner:get_sample_buffer() 
  if not buffer then 
    return 
  end 

  local on_complete = function()
    TRACE("[SSK_Modify:phase_shift_with_ratio] on_complete - ")
  end    

  local bop = xSampleBufferOperation{
    instrument_index = self.owner.instrument_index,
    sample_index = self.owner.sample_index,
    restore_selection = true,
    restore_loop = true,
    restore_zoom = true,
    operations = {
      xSampleBuffer.phase_shift{
        buffer=buffer,
        frame=frame,
      },
    }
  }
  bop:run()

end

---------------------------------------------------------------------------------------------------
-- apply fade operation to buffer 
-- @param fn 

function SSK_Modify:set_fade(fn,mod_fn)
  TRACE("SSK_Modify:set_fade(fn,mod_fn)",fn,mod_fn)
  local buffer = self.owner:get_sample_buffer() 
  if buffer then 

    local bop = xSampleBufferOperation{
      instrument_index = self.owner.instrument_index,
      sample_index = self.owner.sample_index,
      restore_selection = true,
      restore_loop = true,
      restore_zoom = true,
      operations = {
        xSampleBuffer.set_fade{
          buffer=buffer,
          fn=fn,
          mod_fn=mod_fn,
        }
      },
      on_complete = function()
        TRACE("[set_fade] process_done")
      end
    }
    bop:run()

  end 
end

---------------------------------------------------------------------------------------------------

function SSK_Modify:fade_mod_sin()
  self.mod_fade_fn = cWaveform.mod_fn_fn(
    self.mod_fade_cycle,
    self.prefs.mod_fade_shift.value,
    self.prefs.mod_pd_duty_onoff.value,
    self.prefs.mod_pd_duty.value,
    self.prefs.mod_pd_duty_var.value,
    self.prefs.mod_pd_duty_var_frq.value)
  self:set_fade(cWaveform.sin_2pi_fn,self.mod_fade_fn)
end 

---------------------------------------------------------------------------------------------------

function SSK_Modify:fade_mod_saw()
  self.mod_fade_fn = cWaveform.mod_fn_fn(
    self.mod_fade_cycle,
    self.prefs.mod_fade_shift.value,
    self.prefs.mod_pd_duty_onoff.value,
    self.prefs.mod_pd_duty.value,
    self.prefs.mod_pd_duty_var.value,
    self.prefs.mod_pd_duty_var_frq.value)
  self:set_fade(cWaveform.saw_fn,self.mod_fade_fn)
end 

---------------------------------------------------------------------------------------------------

function SSK_Modify:fade_mod_square()
  self.mod_fade_fn = cWaveform.mod_fn_fn(
    self.mod_fade_cycle,
    self.prefs.mod_fade_shift.value,
    self.prefs.mod_pd_duty_onoff.value,
    self.prefs.mod_pd_duty.value,
    self.prefs.mod_pd_duty_var.value,
    self.prefs.mod_pd_duty_var_frq.value)
  self:set_fade(cWaveform.square_fn,self.mod_fade_fn)
end 

---------------------------------------------------------------------------------------------------

function SSK_Modify:fade_mod_triangle()
  self.mod_fade_fn = cWaveform.mod_fn_fn(
    self.mod_fade_cycle,
    self.prefs.mod_fade_shift.value,
    self.prefs.mod_pd_duty_onoff.value,
    self.prefs.mod_pd_duty.value,
    self.prefs.mod_pd_duty_var.value,
    self.prefs.mod_pd_duty_var_frq.value)
  self:set_fade(cWaveform.triangle_fn,self.mod_fade_fn)
end 

---------------------------------------------------------------------------------------------------
--[[
function SSK_Modify:pd_copy()  
  local buffer = self.owner:get_sample_buffer() 
  local mod = cWaveform.mod_fn_fn(
    self.mod_fade_cycle,
    self.prefs.mod_fade_shift.value,
    self.prefs.mod_pd_duty_onoff.value,
    self.prefs.mod_pd_duty.value,
    self.prefs.mod_pd_duty_var.value,
    self.prefs.mod_pd_duty_var_frq.value)
  local fn = xSampleBuffer.copy_fn_fn(
    self.buffer,nil,buffer.selection_start,buffer.selection_end)
  self:make_wave(fn,mod)
end 
]]

---------------------------------------------------------------------------------------------------
-- Static methods
---------------------------------------------------------------------------------------------------
-- quadratic square
function SSK_Modify.qsq(x,factor)
  return (1/2) * (x-(1/2))^2 + factor
end

-- quadratic square (inverted)
function SSK_Modify.qsq_inv(x,factor)
  return (-1/2) * (x-(1/2))^2 + factor
end

---------------------------------------------------------------------------------------------------

function SSK_Modify.raise_factor(factor)
  local y = 100/factor
  return y
end

function SSK_Modify.lower_factor(factor)
  local y = factor/100
  return y
end

function SSK_Modify.diff_factor(factor)
  local y = (100-factor)/100
  return y
end

---------------------------------------------------------------------------------------------------

function SSK_Modify.multiply_raise_fn(x)
  return SSK_Modify.raise_factor(_prefs_.multiply_percent.value)
end

function SSK_Modify.multiply_lower_fn(x)
  return SSK_Modify.lower_factor(_prefs_.multiply_percent.value)
end

---------------------------------------------------------------------------------------------------

function SSK_Modify.fade_in_fn(x)
  local diff_factor = SSK_Modify.diff_factor(_prefs_.fade_percent.value)
  local lower_factor = SSK_Modify.lower_factor(_prefs_.fade_percent.value)
  return diff_factor*x + lower_factor
end

function SSK_Modify.fade_out_fn(x)
  local diff_factor = SSK_Modify.diff_factor(_prefs_.fade_percent.value)
  local y = -diff_factor*x + 1
  return y
end

---------------------------------------------------------------------------------------------------

function SSK_Modify.center_fade_fn(x)
  local factor = SSK_Modify.lower_factor(_prefs_.center_fade_percent.value)
  local mul = 1/SSK_Modify.qsq(0,factor)
  local y = SSK_Modify.qsq(x,factor)*mul
  return y
end

function SSK_Modify.center_amplify_fn(x)
  local factor = SSK_Modify.lower_factor(_prefs_.center_fade_percent.value)
  local mul = 1/SSK_Modify.qsq_inv(0,factor)
  local y = SSK_Modify.qsq_inv(x,factor)*mul
  return y
end
