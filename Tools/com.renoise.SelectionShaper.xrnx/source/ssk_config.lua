--[[===============================================================================================
SSK
===============================================================================================]]--

--[[

Manage saved configurations for the SSK tool (stored in instrument comment)

]]

--=================================================================================================

class 'SSK_Config' 

SSK_Config.TOKEN_START = "-- begin SSK"
SSK_Config.TOKEN_END = "-- end SSK"

---------------------------------------------------------------------------------------------------
-- specify generator settings + mapping

function generatorConfig(ssk,sample_mapping)
  print("generatorConfig(ssk,sample_mapping)",ssk,sample_mapping)

  local x_smap = xSampleMapping{sample_mapping}
  local t_smap = x_smap:export()

  return {
    -- generator options 
    waveform = ssk.recently_generated,
    band_limited = ssk.prefs.band_limited.value,
    mod_cycle = ssk.prefs.mod_cycle.value,
    mod_shift = ssk.prefs.mod_shift.value,
    mod_duty_onoff = ssk.prefs.mod_duty_onoff.value,
    mod_duty = ssk.prefs.mod_duty.value,
    mod_duty_var = ssk.prefs.mod_duty_var.value,
    mod_duty_var_frq = ssk.prefs.mod_duty_var_frq.value,
    -- sample mapping 
    sample_mapping = t_smap,
  }


end


---------------------------------------------------------------------------------------------------
-- check if configuration exists

function SSK_Config.instrument_has_config(ssk)
  assert(type(ssk)=="SSK")
  assert(type(ssk.instrument)=="Instrument")

  return xPersistentSettings.test(
    SSK_Config.TOKEN_START,SSK_Config.TOKEN_END,ssk.instrument)

end

---------------------------------------------------------------------------------------------------
-- load previously stored configuration
-- return boolean (success), string (error message when failed)

function SSK_Config.load_from_instrument(ssk)
  assert(type(ssk)=="SSK")
  assert(type(ssk.instrument)=="Instrument")

  local t = xPersistentSettings.retrieve(
    SSK_Config.TOKEN_START,SSK_Config.TOKEN_END,ssk.instrument)
  if not t then 
    return false
  end 

  print("t",rprint(t))

  if (t.doc_version ~= ssk.doc_version) then 
    return false, "SSK configuration not compatible"
  end 

  -- restore multi-sample layout 
  if type(t.layout)=="table" and not table.is_empty(t.layout) then
    ssk.prefs:apply_multisample_layout(t.layout)

    -- TODO
    --[[
    local extend_notes = true
    local layout = xKeyZoneLayout{
      note_steps = v.note_steps,
      note_min = v.note_min,
      note_max = v.note_max,
      vel_steps = v.vel_steps,
      vel_min = v.vel_min,
      vel_max = v.vel_max,
      extend_notes = extend_notes    
    }
    local xlayout = xKeyZone.create_multisample_layout(layout)
    print("xlayout",xlayout)

    -- restore generator (if any) based on selected sample 
    local s = rns.selected_sample 
    if s then 
      local smap = rns.selected_sample.sample_mapping
      print("smap",smap)
      local mapping = xKeyZone.find_mapping(xlayout,smap.note_range,smap.velocity_range)
      print("mapping",mapping)
    end
    ]]
    
  end


  return true

end

---------------------------------------------------------------------------------------------------
-- save/update configuration

function SSK_Config.save_to_instrument(ssk)
  assert(type(ssk)=="SSK")
  assert(type(ssk.instrument)=="Instrument")

  local layout = ssk.prefs:get_multisample_layout()

  local config = {
    doc_version = ssk.doc_version,
    layout = layout:export(),
    generators = {}
  }

  local smap = ssk.sample.sample_mapping
  table.insert(config.generators,generatorConfig(ssk,smap))


  local passed,err = xPersistentSettings.store(
    config,SSK_Config.TOKEN_START,SSK_Config.TOKEN_END,ssk.instrument)

  if not passed then 
    error(err)
  end

  print("saved config")

end


