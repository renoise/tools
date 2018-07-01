--[[===============================================================================================
SSK_Gui
===============================================================================================]]--

--[[

User interface for the SSK tool 
.

]]

--=================================================================================================

local prefs = renoise.tool().preferences

--=================================================================================================

class 'SSK_Gui' (vDialog)

-- how large a selection before we display in the strip
SSK_Gui.MIN_SELECTION_RATIO = 1/64

SSK_Gui.DISPLAY_AS = {
  OS_EFFECT = 1,
  BEATS = 2,
  SAMPLES = 3,
}

SSK_Gui.COLOR_SELECTED = {0xf1,0x6a,0x32} -- active in strip (same as waveform selection)
SSK_Gui.COLOR_DESELECTED = {0x16,0x16,0x16} -- 
SSK_Gui.COLOR_NONE = {0x00,0x00,0x00}


SSK_Gui.DIALOG_WIDTH = 400
SSK_Gui.DIALOG_MARGIN = 3
SSK_Gui.DIALOG_SPACING = 3
SSK_Gui.INPUT_WIDTH = 80
SSK_Gui.LABEL_WIDTH = 64
SSK_Gui.FORMULA_WIDTH = 120
SSK_Gui.TOGGLE_SIZE = 16
SSK_Gui.KEYZONE_HEIGHT = 120
SSK_Gui.KEYZONE_LABEL_WIDTH = 52
SSK_Gui.MINUS_PLUS_W = 34
SSK_Gui.MULTISAMPLE_SWITCH_W = 107
SSK_Gui.SMALL_LABEL_WIDTH = 44
SSK_Gui.STRIP_HEIGHT = 36
SSK_Gui.PANEL_INNER_MARGIN = 3
SSK_Gui.ITEM_MARGIN = 6
SSK_Gui.ITEM_SPACING = 3
SSK_Gui.ITEM_HEIGHT = 20
SSK_Gui.NULL_SPACING = -3
SSK_Gui.SMALL_BT_WIDTH = 32
SSK_Gui.WIDE_BT_WIDTH = 60
SSK_Gui.TALL_BT_HEIGHT = 18
SSK_Gui.ROW_STYLE = "invisible" --"body"
SSK_Gui.ROW_SPACING = 0
SSK_Gui.ROW_MARGIN = 1
SSK_Gui.PANEL_STYLE = "group"
SSK_Gui.PANEL_HEADER_FONT = "bold"
-- derived 
SSK_Gui.SMALL_BT_X2_WIDTH = SSK_Gui.SMALL_BT_WIDTH*2 + SSK_Gui.NULL_SPACING
SSK_Gui.DIALOG_INNER_WIDTH = SSK_Gui.DIALOG_WIDTH - 2*SSK_Gui.DIALOG_MARGIN
SSK_Gui.KEYZONE_WIDTH = SSK_Gui.DIALOG_INNER_WIDTH - 2*SSK_Gui.KEYZONE_LABEL_WIDTH - 3

SSK_Gui.MSG_GET_LENGTH_BEAT_TIP = [[
Input the number or the formula 
that represents the selection range, 
e.g. '168*4' , 'c#4' , '400*((1/2)^(7/12))'
]]

SSK_Gui.MSG_GET_LENGTH_FRAME_ERR = [[
Enter a number greater than zero, 
or a numerical formula - e.g. '162*8' , '400*1.4/4' , '400*((1/2)^(7/12))'
]]

SSK_Gui.MSG_MULTIPLY_TIP = [[
Input the number or the formula by that
the selection range is multiplied, e.g. '44800/200' , '(1/2)^(7/12)'
]] 

SSK_Gui.MSG_MULTIPLY_ERR = [[
Enter a number that is greater than zero,
or a numerical formula, e.g. '44100/168' ,'(1/2)^(7/12)'
]]

SSK_Gui.MSG_FADE_SHIFT = [[
Input the number or the formula that
represent the starting phase point of the wave.
100% means 1 cycle .
]]

SSK_Gui.MSG_MOD_CYCLE = [[
Enter a number or a numerical formula.
1 means 1 cycle, e.g. 1/4' , '44100/168'
]]

SSK_Gui.MSG_MOD_SHIFT = [[
Input number or formula that
represent the starting phase point of the wave.
100% means 1cycle .
]]

SSK_Gui.MSG_DUTY_VAR = [[
Input duty cycle variation value.
Duty cycle fluctuates between fiducial value
and this value plus fiducial value with minus cosine curve.
]]

SSK_Gui.MSG_DUTY_FRQ = [[
Input duty variation frequency.
Duty cycle fluctuates between fiducial value
and variation value plus fiducial value with minus cosine curve.
this frequency is used in this cosine curve. 
]]

SSK_Gui.MSG_MOD_DUTY_VAR = [[
Input duty cycle variation value.
Duty cycle fluctuates between fiducial value
and this value plus fiducial value with minus cosine curve.
]]

SSK_Gui.MSG_MOD_DUTY_FRQ = [[
Input duty variation frequency.
Duty cycle fluctuates between fiducial value
and variation value plus fiducial value with minus cosine curve.
this frequency is used in this cosine curve.
]]

SSK_Gui.MSG_COPY_PD = [[
Superscribing copy with phase distortion 
(useful with Duty cycle settings)
]]

SSK_Gui.MSG_FADE_TIP = [[
Input the number or the formula that represent the cycle of the wave.
1 means 1 cycle, e.g. '1/2' , '44100/168'
]]



---------------------------------------------------------------------------------------------------

function SSK_Gui:__init(...)
  TRACE("SSK_Gui:__init(...)",...)

  local args = cLib.unpack_args(...)

  assert(type(args.owner) == "SSK")

  self.dialog_title = "Selection Shaper Kai"

  -- Viewbuilder
  self.vb = renoise.ViewBuilder()
  -- SSK (SelectionShaper)
  self.owner = args.owner 
  -- Bitmap location table
  self.btmp = bitmap_util()
  -- boolean, scheduled updates
  self.update_strip_requested = false
  self.update_toolbar_requested = false
  self.update_selection_requested = false
  self.update_select_panel_requested = true
  self.update_modify_panel_requested = true
  self.update_generate_panel_requested = true
  self.update_selection_header_requested = false

  -- boolean, true we are displaying strip in "loop mode"
  self.display_buffer_as_loop = property(self.get_display_buffer_as_loop,self.set_display_buffer_as_loop)
  self.display_buffer_as_loop_observable = renoise.Document.ObservableBoolean(false)

  -- renoise.Dialog
  --self.dialog = nil  
  -- renoise.view, dialog content 
  --self.vb_content = nil

  -- SSK_Gui_Keyzone
  self.vkeyzone = nil

  -- boolean
  self.reset_spinner_requested = false

  -- == Observables == 

  self.display_buffer_as_loop_observable:add_notifier(function()
    TRACE(">>> SSK_Gui:display_buffer_as_loop_observable fired...")
    self:update_selection_strip_controls()
  end)
  self.owner.tempo_changed_observable:add_notifier(function()
    TRACE(">>> SSK_Gui:tempo_changed_observable fired...")
    self.update_selection_requested = true
  end)
  self.owner.selection_changed_observable:add_notifier(function()
    TRACE(">>> SSK_Gui:selection_changed_observable fired...")
    self.update_strip_requested = true
    self.update_selection_header_requested = true
  end)
  self.owner.samples_changed_observable:add_notifier(function()
    TRACE(">>> SSK_Gui:samples_changed_observable fired...")
  self.update_toolbar_requested = true
    self.update_strip_requested = true
    self.update_selection_header_requested = true
  end)
  self.owner.memorized_changed_observable:add_notifier(function()
    TRACE(">>> SSK_Gui:memorized_changed_observable fired...")
    self:update_buffer_controls()
  end)
  self.owner.buffer_changed_observable:add_notifier(function()
    TRACE(">>> SSK_Gui:buffer_changed_observable fired...")
    -- this can be the only way to update after sample becomes available  
    -- (request same updates as when sample_index has triggered...)
    self.update_toolbar_requested = true    
    self.update_strip_requested = true
    self.update_select_panel_requested = true
    self.update_modify_panel_requested = true
    self.update_generate_panel_requested = true
    self.update_selection_header_requested = true
  end)
  self.owner.selection.length_frames_observable:add_notifier(function()
    TRACE(">>> SSK_Gui:selection.length_frames_observable fired...")
    self.update_selection_requested = true    
  end)
  self.owner.selection.start_frames_observable:add_notifier(function()
    TRACE(">>> SSK_Gui: start_frames_observable fired...")
    self.update_selection_requested = true    
  end)
  self.owner.sample_name_observable:add_notifier(function()
    TRACE(">>> SSK_Gui:sample_name_observable fired...")
    self.update_toolbar_requested = true    
    self.update_selection_header_requested = true
  end)
  self.owner.sample_loop_changed_observable:add_notifier(function()
    TRACE(">>> SSK_Gui:sample_loop_changed_observable fired...")
    self.update_strip_requested = true    
    self.update_selection_header_requested = true
  end)
  self.owner.sample_tuning_changed_observable:add_notifier(function()
    TRACE(">>> SSK_Gui:sample_tuning_changed_observable fired...")
    self.update_selection_header_requested = true
  end)
  self.owner.instrument_name_observable:add_notifier(function()
    TRACE(">>> SSK_Gui:instrument_name_observable fired...")
    self.update_toolbar_requested = true
    self.update_selection_header_requested = true
    self.update_strip_requested = true
  end)
  self.owner.sample_index_observable:add_notifier(function()
    TRACE(">>> SSK_Gui:sample_index_observable fired...")
    self.update_toolbar_requested = true    
    self.update_strip_requested = true
    self.update_select_panel_requested = true
    self.update_modify_panel_requested = true
    self.update_generate_panel_requested = true
    self.update_selection_header_requested = true
  end)  
  self.owner.generator.random_generated_observable:add_notifier(function()
    self.update_generate_panel_requested = true
  end)
  self.owner.generator.recently_generated_observable:add_notifier(function()
    self.update_generate_panel_requested = true
  end)
  prefs.auto_generate:add_notifier(function()
    self.update_generate_panel_requested = true
  end)

  prefs.sync_with_renoise:add_notifier(function()
    self.update_select_panel_requested = true
  end)
  prefs.mod_duty_onoff:add_notifier(function()
    self:update_duty_cycle()
  end)
  prefs.mod_pd_duty_onoff:add_notifier(function()
    self:update_pd_duty_cycle()
  end)
  prefs.multisample_mode:add_notifier(function()
    self.update_toolbar_requested = true
    self:update_panel_visibility()
  end)
  prefs.display_selection_panel:add_notifier(function()
    self:update_panel_visibility()
  end)
  prefs.display_generate_panel:add_notifier(function()
    self:update_panel_visibility()
  end)
  prefs.display_modify_panel:add_notifier(function()
    self:update_panel_visibility()
  end)
  prefs.display_options_panel:add_notifier(function()
    self:update_panel_visibility()
  end)
  prefs.display_selection_as:add_notifier(function()
    local as_os_fx = self.owner.selection:display_as_os_fx()
    if as_os_fx and prefs.sync_with_renoise.value then 
      -- prevent value from being interpreted (changed)
      -- when switching from frames to offsets
      self.owner.selection:obtain_start_from_editor()
      self.owner.selection:obtain_length_from_editor()
    end    
    self.update_selection_requested = true
    self.update_strip_requested = true
  end)
  renoise.tool().app_idle_observable:add_notifier(function()
    self:idle_notifier()
  end)

  --== initialize ==--


  vDialog.__init(self,...)

  
end 

---------------------------------------------------------------------------------------------------
-- Getters and Setters
---------------------------------------------------------------------------------------------------

function SSK_Gui:get_display_buffer_as_loop()
  return self.display_buffer_as_loop_observable.value
end 

function SSK_Gui:set_display_buffer_as_loop(val)
  self.display_buffer_as_loop_observable.value = val
end 

---------------------------------------------------------------------------------------------------
-- vDialog methods
---------------------------------------------------------------------------------------------------

function SSK_Gui:show()
  TRACE("SSK_Gui:show()")

  vDialog.show(self)
  self:update_all()

end

---------------------------------------------------------------------------------------------------

function SSK_Gui:create_dialog()
  TRACE("SSK_Gui:create_dialog()")

  local vb = self.vb
  return vb:column{
    margin = SSK_Gui.DIALOG_MARGIN,
    spacing = SSK_Gui.DIALOG_SPACING,
    vb:column{
      style = "border",
      self:build_toolbar(),
      self:build_keyzone(),
    },    
    self:build_buffer_panel(),
    self:build_selection_panel(),    
    self:build_generate_panel(),
    self:build_modify_panel(),  
  }

end 

---------------------------------------------------------------------------------------------------
-- Class methods
---------------------------------------------------------------------------------------------------

function SSK_Gui:dialog_keyhandler(dlg,key)
  TRACE("SSK_Gui:dialog_keyhandler(dlg,key)",dlg,key)
  rprint(key)
  
  if (key.modifiers == "") then 
    -- pure keys (repeat allowed)
    if (key.name == "left") then 
      self.owner.selection:flick_back()
      return
    elseif (key.name == "right") then
      self.owner.selection:flick_forward()
      return
    elseif (key.name == "up") then
      self.owner.selection:multiply_length()
      return
    elseif (key.name == "down") then
      self.owner.selection:divide_length()
      return
    end 
    -- pure keys (no repeat)
    if (key.repeated == false) then
      if (key.name == "return") then 
        local sample = self.owner.sample
        if sample then
          xSample.set_loop_to_selection(sample)
        end
        return
      elseif (key.name == "del") then
        self.owner:sync_del()
        return
      elseif (key.name == "ins") then
        self.owner:sweep_ins()
        return
      end 
    end 
  end 

  if (key.modifiers == "control") 
    and (key.repeated == false)
  then 
    if (key.name == "c") then 
      self.owner:buffer_memorize()
      return
    elseif (key.name == "v") then 
      self.owner:buffer_redraw()
      return
    end
  end

  if (key.modifiers == "shift") then 
    -- keys with shift modifier (repeat allowed)
    if (key.name == "left") then 
      self.owner.selection:nudge_start(-1)
      return
    elseif (key.name == "right") then 
      self.owner.selection:nudge_start(1)
      return
    end
    if (key.name == "up") then 
      self.owner.selection:nudge_length(1)
      return
    elseif (key.name == "down") then 
      self.owner.selection:nudge_length(-1)
      return
    end
  end

  if (key.modifiers == "shift + control") then 
    -- keys with shift modifier (repeat allowed)
    if (key.name == "left") then 
      self.owner.selection:nudge_start(-10)
      return
    elseif (key.name == "right") then 
      self.owner.selection:nudge_start(10)
      return
    end
    if (key.name == "up") then 
      self.owner.selection:nudge_length(10)
      return
    elseif (key.name == "down") then 
      self.owner.selection:nudge_length(-10)
      return
    end
  end

  -- forward key to Renoise 
  return key

end

---------------------------------------------------------------------------------------------------

function SSK_Gui:update_all()
  TRACE("SSK_Gui:update_all()")

  if not self.dialog_content then 
    return
  end

  self:update_panel_visibility()
  self:update_duty_cycle()
  self:update_pd_duty_cycle()
  self.update_select_panel_requested = true
  self.update_modify_panel_requested = true
  self.update_generate_panel_requested = true
  self.update_modify_panel_requested = true
  self.update_selection_requested = true
  self.update_toolbar_requested = true
  self.update_strip_requested = true

end

---------------------------------------------------------------------------------------------------

function SSK_Gui:update_panel_visibility()
  TRACE("SSK_Gui:update_panel_visibility()")
  local vb = self.vb
  vb.views.ssk_selection_panel.visible = prefs.display_selection_panel.value
  vb.views.ssk_generate_panel.visible = prefs.display_generate_panel.value
  vb.views.ssk_modify_panel.visible = prefs.display_modify_panel.value
  vb.views.ssk_multisample_editor.visible = prefs.multisample_mode.value
end

---------------------------------------------------------------------------------------------------

function SSK_Gui:update_select_panel()
  TRACE("SSK_Gui:update_select_panel()")

  local is_active = self.owner:get_sample_buffer() and true or false
  local sync_enabled = prefs.sync_with_renoise.value
  local vb = self.vb
  
  -- header 
  vb.views.ssk_sync_with_renoise.active = is_active
  vb.views.ssk_selection_unit_popup.active = is_active
  -- start 
  vb.views.ssk_get_selection_start.active = is_active and not sync_enabled
  vb.views.ssk_selection_start.active = is_active
  vb.views.ssk_sel_start_spinner.active = is_active
  vb.views.ssk_selection_apply_start.active = is_active
  -- length 
  vb.views.ssk_get_selection_length.active = is_active and not sync_enabled
  vb.views.ssk_selection_length.active = is_active
  vb.views.ssk_sel_length_spinner.active = is_active
  vb.views.ssk_selection_apply_length.active = is_active
  vb.views.ssk_selection_multiply_length.active = is_active
  vb.views.ssk_selection_divide_length.active = is_active
  vb.views.multiply_setend.active = is_active

end

---------------------------------------------------------------------------------------------------

function SSK_Gui:update_generate_panel()
  TRACE("SSK_Gui:update_generate_panel()")

  local can_generate_multisample = self.owner.generator:can_generate_multisample()
  local can_generate = self.owner:get_sample_buffer() and true or can_generate_multisample
  local can_repeat_rnd = self.owner.generator.random_wave_fn 
  local vb = self.vb

  vb.views.ssk_generate_random_bt.active = can_generate
  vb.views.ssk_generate_repeat_random_bt.active = (can_generate and can_repeat_rnd) and true or false
  vb.views.ssk_generate_white_noise_bt.active = can_generate
  vb.views.ssk_generate_brown_noise_bt.active = can_generate
  vb.views.ssk_generate_violet_noise_bt.active = can_generate
  vb.views.ssk_generate_sin_wave_bt.active = can_generate
  vb.views.ssk_generate_saw_wave_bt.active = can_generate
  vb.views.ssk_generate_square_wave_bt.active = can_generate
  vb.views.ssk_generate_triangle_wave_bt.active = can_generate

  -- highlight recently generated 
  local recent_sin = (self.owner.generator.recently_generated == cWaveform.FORM.SIN)
  local recent_saw = (self.owner.generator.recently_generated == cWaveform.FORM.SAW)
  local recent_square = (self.owner.generator.recently_generated == cWaveform.FORM.SQUARE)
  local recent_triangle = (self.owner.generator.recently_generated == cWaveform.FORM.TRIANGLE)
  vb.views.ssk_generate_sin_wave_bt.color = 
    prefs.auto_generate.value and recent_sin and SSK_Gui.COLOR_SELECTED or SSK_Gui.COLOR_NONE
  vb.views.ssk_generate_saw_wave_bt.color = 
    prefs.auto_generate.value and recent_saw and SSK_Gui.COLOR_SELECTED or SSK_Gui.COLOR_NONE
  vb.views.ssk_generate_square_wave_bt.color = 
    prefs.auto_generate.value and recent_square and SSK_Gui.COLOR_SELECTED or SSK_Gui.COLOR_NONE
  vb.views.ssk_generate_triangle_wave_bt.color = 
    prefs.auto_generate.value and recent_triangle and SSK_Gui.COLOR_SELECTED or SSK_Gui.COLOR_NONE

end

---------------------------------------------------------------------------------------------------

function SSK_Gui:update_modify_panel()
  TRACE("SSK_Gui:update_modify_panel()")

  local is_active = self.owner:get_sample_buffer() and true or false
  local vb = self.vb
  
  vb.views.ssk_generate_shift_plus_bt.active = is_active
  vb.views.ssk_generate_shift_minus_bt.active = is_active
  vb.views.ssk_generate_shift_plus_fine_bt.active = is_active
  vb.views.ssk_generate_shift_minus_fine_bt.active = is_active
  vb.views.ssk_generate_fade_center_a_bt.active = is_active
  vb.views.ssk_generate_fade_center_b_bt.active = is_active
  vb.views.ssk_generate_fade_out_bt.active = is_active
  vb.views.ssk_generate_fade_in_bt.active = is_active
  vb.views.ssk_generate_multiply_lower_bt.active = is_active
  vb.views.ssk_generate_multiply_raise_bt.active = is_active
  --vb.views.ssk_resize_expand_bt.active = is_active
  --vb.views.ssk_resize_shrink_bt.active = is_active
  vb.views.ssk_generate_rm_sin_bt.active = is_active
  vb.views.ssk_generate_rm_saw_bt.active = is_active
  vb.views.ssk_generate_rm_square_bt.active = is_active
  vb.views.ssk_generate_rm_triangle_bt.active = is_active
  vb.views.ssk_generate_pd_copy_bt.active = false --is_active

end

---------------------------------------------------------------------------------------------------

function SSK_Gui:update_duty_cycle()
  TRACE("SSK_Gui:update_duty_cycle()")
  local is_active = prefs.mod_duty_onoff.value 
  local vb = self.vb
  
  vb.views.duty_fiducial.active = is_active
  vb.views.duty_variation.active = is_active
  vb.views.duty_var_frq.active = is_active
end

---------------------------------------------------------------------------------------------------

function SSK_Gui:update_pd_duty_cycle()
  TRACE("SSK_Gui:update_pd_duty_cycle()")

  local is_active = prefs.mod_pd_duty_onoff.value 
  local vb = self.vb
  
  vb.views.pd_duty_fiducial.active = is_active
  vb.views.pd_duty_variation.active = is_active
  vb.views.pd_duty_var_frq.active = is_active
end

---------------------------------------------------------------------------------------------------

function SSK_Gui:update_toolbar()
  TRACE("SSK_Gui:update_toolbar()")

  local has_samples = false
  local instr = self.owner.instrument
  local vb = self.vb

  local get_sample_info = function(instr_name,sample_idx)
    local txt = ""
    local sample = instr.samples[sample_idx]
    print("sample",sample,sample_idx)
    if sample then 
      local sample_name = xSample.get_display_name(sample,sample_idx)
      local buffer = self.owner:get_sample_buffer()
      if not buffer then 
        sample_name = ("%s (empty)"):format(sample_name)
      end 
      txt = ("%s - %s"):format(instr_name,sample_name)
    elseif not has_samples then 
      txt = ("%s (no samples)"):format(instr_name)
    else 
      error("Unexpected condition")
    end 
    return txt
  end

  local vb_selector = vb.views.ssk_sample_selector
  local infos = {}
  if instr then
    local instr_name = (instr.name == "") 
      and "Untitled instrument" or instr.name
    local has_samples = #instr.samples > 0
    if has_samples then
      infos = {("%s - no sample selected"):format(instr_name)}
      for k,v in ipairs(instr.samples) do
        table.insert(infos,get_sample_info(instr_name,k))
      end 
    else
      infos = {("%s - (no samples)"):format(instr_name)}
    end
  else
    infos = {("Instrument N/A")}
  end
  local sample_idx = rns.selected_sample_index--self.owner.sample_index
  vb_selector.items = table.is_empty(infos) and {} or infos
  vb_selector.value = infos[sample_idx] and sample_idx+1 or 1

  -- force width of instr/sample readout (crop text)
  vb_selector.width = SSK_Gui.DIALOG_INNER_WIDTH - 
    (SSK_Gui.MINUS_PLUS_W + SSK_Gui.MULTISAMPLE_SWITCH_W)

  vb.views.ssk_sample_delete.active = (self.owner.sample and has_samples) and true or false

  local vb_multisample = vb.views.ssk_status_multisample
  local multi_on = prefs.multisample_mode.value 

  vb_multisample.text = multi_on and "Multisample ON" or "Multisample OFF"
  vb_multisample.font = multi_on and "bold" or "normal"
  vb_multisample.width = SSK_Gui.MULTISAMPLE_SWITCH_W

end 

---------------------------------------------------------------------------------------------------
-- update buttons in buffer panel 

function SSK_Gui:update_buffer_controls()
  TRACE("SSK_Gui:update_buffer_controls()")

  local buffer = self.owner:get_sample_buffer() and true or false
  local memorized = self.owner.clip_wv_fn and true or false
  local vb = self.vb
  
  vb.views.ssk_buffer_delete.active = buffer
  vb.views.ssk_buffer_insert.active = buffer
  vb.views.ssk_buffer_trim.active = buffer
  vb.views.ssk_buffer_copy.active = buffer
  vb.views.ssk_buffer_copy_to_new.active = buffer
  vb.views.ssk_buffer_paste.active = buffer and memorized
  vb.views.ssk_buffer_mix_paste.active = buffer and memorized
  vb.views.ssk_buffer_swap.active = buffer and memorized

end

---------------------------------------------------------------------------------------------------
-- update additional buttons in selection-strip (prev/next/loop/etc)

function SSK_Gui:update_selection_strip_controls()
  TRACE("SSK_Gui:update_selection_strip_controls()")

  local buffer = self.owner:get_sample_buffer() 
  local is_active = buffer and true or false
  local vb = self.vb
  
  vb.views.ssk_flick_forward.active = is_active
  vb.views.ssk_flick_back.active = is_active

  local loop_bt = vb.views.ssk_strip_set_loop
  loop_bt.active = is_active
  loop_bt.text = self.display_buffer_as_loop and "Clr.Loop" or "Set Loop"
  loop_bt.tooltip = self.display_buffer_as_loop and
    "Click to remove the currently set loop"
    or "Click to loop the selected region"

  --== update channel toggle-buttons ==--

  local toggle_right_bt = vb.views.ssk_selection_toggle_right
  local toggle_left_bt = vb.views.ssk_selection_toggle_left

  if (not buffer or buffer.number_of_channels == 1) then 
    -- mono
    local tooltip = "Toggle channel (available when in stereo)"
    toggle_left_bt.active = false
    toggle_left_bt.color = SSK_Gui.COLOR_NONE
    toggle_left_bt.tooltip = tooltip

    toggle_right_bt.active = false
    toggle_right_bt.color = SSK_Gui.COLOR_NONE  
    toggle_right_bt.tooltip = tooltip

  else
    -- stereo
    toggle_left_bt.tooltip = "Click to toggle selection in left channel"
    toggle_right_bt.tooltip = "Click to toggle selection in right channel"

    local right_is_selected = xSampleBuffer.right_is_selected(buffer)
    local left_is_selected = xSampleBuffer.left_is_selected(buffer)
    local can_toggle_right = 
      (buffer.selected_channel == renoise.SampleBuffer.CHANNEL_LEFT_AND_RIGHT)
      or (buffer.selected_channel == renoise.SampleBuffer.CHANNEL_LEFT)
    local can_toggle_left = 
      (buffer.selected_channel == renoise.SampleBuffer.CHANNEL_LEFT_AND_RIGHT)
      or (buffer.selected_channel == renoise.SampleBuffer.CHANNEL_RIGHT)
    toggle_left_bt.active = can_toggle_left
    toggle_left_bt.color = left_is_selected and SSK_Gui.COLOR_SELECTED or SSK_Gui.COLOR_NONE
    toggle_right_bt.active = can_toggle_right
    toggle_right_bt.color = right_is_selected and SSK_Gui.COLOR_SELECTED or SSK_Gui.COLOR_NONE
  end

end

---------------------------------------------------------------------------------------------------
-- produce visual overview over selection 

function SSK_Gui:update_selection_strip()
  TRACE("SSK_Gui:update_selection_strip()")

  local vb = self.vb
  local vb_strip = vb.views.ssk_selection_strip
  local total_w = SSK_Gui.DIALOG_WIDTH - 
    (SSK_Gui.SMALL_BT_X2_WIDTH + 24)

  if not self.owner:get_sample_buffer() then 
    self.selection_strip.items = {}
    self.selection_strip.placeholder_message = "Sample N/A"
    self.selection_strip:update()  
    return 
  end        

  local sample = self.owner.sample
  local buffer = sample.sample_buffer
  local range = xSampleBuffer.get_selection_range(buffer) 
  local is_fully_looped = xSample.is_fully_looped(sample)

  -- abort if too small a selection 
  local sel_ratio = range/buffer.number_of_frames
  if (sel_ratio < SSK_Gui.MIN_SELECTION_RATIO) then 
    self.selection_strip.items = {}
    self.selection_strip.placeholder_message = "Selection is too small to display"
    self.selection_strip:update()  
    return 
  end

  -- required for weighing  
  local segment_length = nil
  local num_segments = 1
  local lead = nil 
  local trail = nil 
  local looped_segment_index = 0
  local selected_segment_index = 0

  -- different handling for OS Effects 
  -- (avoid rounding artifacts)
  local as_os_fx = self.owner.selection:display_as_os_fx()

  -- check for perfect lead/trail (used with 0S Effect)
  local is_perfect_lead,is_perfect_trail = false,false
  if as_os_fx then 
    is_perfect_lead = self.owner.selection:is_perfect_lead() 
    is_perfect_trail = self.owner.selection:is_perfect_trail()
    --print("is_perfect_lead,is_perfect_trail",is_perfect_lead,is_perfect_trail)
  end

  if (range == buffer.number_of_frames) and not is_fully_looped then 
    -- define leading/trailing as space before/after loop 
    self.display_buffer_as_loop = true
    num_segments = 1
    if (sample.loop_start > 1) then
      lead = sample.loop_start-1
    end
    if (sample.loop_end < buffer.number_of_frames) then
      trail = buffer.number_of_frames-sample.loop_end
    end
    segment_length = sample.loop_end - sample.loop_start + 1
    looped_segment_index = lead and 2 or 1
  else 
    self.display_buffer_as_loop = false
    segment_length = range

    local num_lead_segments = function()
      return self.owner.selection.start_offset/self.owner.selection.length_offset
    end
    
    if as_os_fx and is_perfect_lead then
      num_segments = num_segments + num_lead_segments()
    else
      -- do we have leading space (how much) ?
      if (buffer.selection_start > 1) then 
        lead = buffer.selection_start - 1
        while lead > 0 do 
          lead = lead - segment_length
          num_segments = num_segments + 1
        end 
        if (lead < 0) then 
          lead = lead + segment_length 
          num_segments = num_segments - 1
        elseif (lead == 0) then 
          lead = nil
        end
      end 
    end

    local num_trail_segments = function()
      local start = self.owner.selection.start_offset
      local length = self.owner.selection.length_offset
      return (256-(start+length))/length
    end

    if as_os_fx and is_perfect_trail then
      num_segments = num_segments + num_trail_segments()
    else
      -- do we have trailing space (how much) ?
      if (buffer.selection_end < buffer.number_of_frames) then 
        trail = buffer.selection_end
        while trail <= buffer.number_of_frames do 
          trail = trail + segment_length
          num_segments = num_segments + 1
        end 
        if (trail > buffer.number_of_frames) then 
          trail = trail - segment_length
          num_segments = num_segments - 1
        elseif (trail == buffer.number_of_frames) then 
          trail = nil
        end 
      end
      if trail then 
        trail = buffer.number_of_frames - trail
      end 
    end 
  end

  --print("num_segments",num_segments)
  -- we have our segments - now create the weights
  -- check if active/looped segment 
  local weights = {}  -- table<vButtonStripMember> 
  local tmp_frame = 0
  if lead then 
    table.insert(weights,vButtonStripMember{weight = lead})
    tmp_frame = lead
  end   
  for k = 1, num_segments do 

    local seg_start,seg_end
    if as_os_fx and not self.display_buffer_as_loop then 
      if (num_segments == 1) then 
        segment_length = range
      elseif is_perfect_lead then
        -- get length for each individual segment
        -- (avoid rounding artifacts)
        seg_start,seg_end = self.owner.selection:get_nth_segment_by_offset(k-1,num_segments)        
        segment_length = seg_end-seg_start
        --print("segment_length",segment_length,seg_end,seg_start)
      end
    end

    table.insert(weights,vButtonStripMember{weight = segment_length})

    -- figure out if selected
    if self.display_buffer_as_loop then
      selected_segment_index = 0 -- never selected in loop mode 
    elseif seg_start and seg_end then 
      -- previous computed offset length 
      --print("*** buffer.selection_start",buffer.selection_start,seg_start)
      --print("*** buffer.selection_end",buffer.selection_end,seg_end)
      if (buffer.selection_start == seg_start 
        and buffer.selection_end == seg_end) 
      then 
        selected_segment_index = k 
      end 
    else -- normal, sample based 
      if (buffer.selection_start == tmp_frame+1 
        and buffer.selection_end == tmp_frame + segment_length) 
      then 
        selected_segment_index = lead and k + 1 or k
      end     
    end
    -- segment is looped?
    local sample = self.owner.sample 
    if (sample.loop_mode ~= renoise.Sample.LOOP_MODE_OFF) then
      if (sample.loop_start == tmp_frame+1 
        and sample.loop_end == tmp_frame + segment_length) 
      then 
        looped_segment_index = lead and k+1 or k
      end
    end           
    tmp_frame = tmp_frame + segment_length
  end 
  if trail then 
    table.insert(weights,vButtonStripMember{weight = trail})
  end 
  
  local tmp_frame = 0
  for k,v in ipairs(weights) do

    local sel_end = tmp_frame+v.weight
  
    -- selected when range matches, and not the only one
    local fully_selected = (#weights == 1) and true or false
    --local length_equal_to_range = (v.weight == range)
    --print("range,weight,length_equal_to_range",range,v.weight,length_equal_to_range)
    local is_looped = (looped_segment_index == k)
    local is_lead = lead and (k == 1)
    local is_trail = trail and (k == #weights)
    local is_selected = (selected_segment_index == 0) and false 
      or (fully_selected or (k == selected_segment_index)) and true 
      or false
    local title_txt = ""
    if self.display_buffer_as_loop then 
      title_txt = is_looped and "Loop" or "-"
    else
      --title_txt = ("%d%s"):format(k,length_equal_to_range and "" or "~") 
      title_txt = ("%d"):format(k) 
    end
    local subline_txt = is_looped and "⟲" or is_lead and "‹‹" or is_trail and "››" or ""
    
    -- configure item 
    v.text = not fully_selected and ("%s\n%s"):format(title_txt,subline_txt) or "-"
    v.tooltip = ("Segment #%d: [%d - %d] %d"):format(k,tmp_frame,sel_end,v.weight)
    v.color = is_selected and SSK_Gui.COLOR_SELECTED or 
      is_looped and SSK_Gui.COLOR_NONE or SSK_Gui.COLOR_DESELECTED

    tmp_frame = tmp_frame + v.weight

  end 
  --print("weights...",rprint(weights))
  self.selection_strip.items = weights
  self.selection_strip:update()

end 

---------------------------------------------------------------------------------------------------
-- update the selection start/length inputs with frames,beats,offset

function SSK_Gui:update_selection_length()
  TRACE("SSK_Gui:update_selection_length()")

  local vb = self.vb
  
  if self.owner.selection:display_as_samples() then 
    vb.views.ssk_selection_start.value = tostring(self.owner.selection.start_frames) 
    vb.views.ssk_selection_length.value = tostring(self.owner.selection.length_frames) 
  elseif self.owner.selection:display_as_beats() then
    vb.views.ssk_selection_start.value = tostring(self.owner.selection.start_beats) 
    vb.views.ssk_selection_length.value = tostring(self.owner.selection.length_beats) 
  elseif self.owner.selection:display_as_os_fx() then
    vb.views.ssk_selection_start.value = ("0x%X"):format(self.owner.selection.start_offset) 
    vb.views.ssk_selection_length.value = ("0x%X"):format(self.owner.selection.length_offset) 
  else 
    vb.views.ssk_selection_start.value = ""
    vb.views.ssk_selection_length.value = ""
  end
end 

---------------------------------------------------------------------------------------------------
-- update the selected range readout 

function SSK_Gui:update_selection_header()
  TRACE("SSK_Gui:update_selection_header()")

  local sel_start,sel_end,sel_length
  local vb = self.vb
  
  local vb_textfield = vb.views.ssk_selection_header_txt
  if self.owner:get_sample_buffer() then 
    local buffer = self.owner.sample.sample_buffer
    sel_start = buffer.selection_start - 1
    sel_end = buffer.selection_end
    sel_length = sel_end - sel_start
    local sel_hz = self.owner.selection:get_hz_from_range()
    if self.owner.selection:display_as_os_fx() then 
      sel_start = xSampleBuffer.get_offset_by_frame(buffer,buffer.selection_start)
      sel_end = self.owner.selection:obtain_end_offset(buffer)
      sel_length = sel_end - sel_start
      vb_textfield.text = (" [%X - %X] (%X) - %.2fHz"):format(sel_start,sel_end,sel_length,sel_hz)
    elseif self.owner.selection:display_as_samples() then 
      vb_textfield.text = (" [%d - %d] (%d) - %.2fHz"):format(sel_start,sel_end,sel_length,sel_hz)
    elseif self.owner.selection:display_as_beats() then
      sel_start = 1 + xSampleBuffer.get_beat_by_frame(buffer,sel_start)
      sel_end = 1 + xSampleBuffer.get_beat_by_frame(buffer,sel_end)
      sel_length = 1 + sel_end - sel_start
      vb_textfield.text = (" [%s - %s] (%s) - %.2fHz"):format(
        cString.format_beat(sel_start),
        cString.format_beat(sel_end),
        cString.format_beat(sel_length),
        sel_hz)
    end
    vb_textfield.tooltip = "Display selection [Start - End] (Length)"
                        .."\n+ Frequency of selection in Hz (including transpose/fine-tune) "
  else 
    vb_textfield.text = ""
    vb_textfield.tooltip = ""
  end

end 

---------------------------------------------------------------------------------------------------

function SSK_Gui:build_toolbar()

  local vb = self.vb

  return vb:horizontal_aligner{
    id = "ssk_header_aligner",
    mode = "justify",
    margin = SSK_Gui.DIALOG_MARGIN,
    vb:row{
      spacing = SSK_Gui.NULL_SPACING,
      vb:button{
        id = "ssk_sample_delete",    
        text = "‒",
        tooltip = "Delete the selected sample.",
        notifier = function()
          self.owner:delete_sample()
        end,          
      },
      vb:button{ 
        id = "ssk_sample_insert",    
        text = "+",
        tooltip = "Create/insert a new sample",
        notifier = function ()  
          self.owner:insert_sample()
        end,
      },       
      vb:space{
        width = 6,
      },      
      -- vb:text{
      --   id = "ssk_status_sample_name",
      --   text = "",
      --   font = "normal",
      -- },
      vb:popup{
        id = "ssk_sample_selector",
        notifier = function(idx)
          local instr = self.owner.instrument
          if instr then 
            local sample_idx = idx-1
            local sample = instr.samples[sample_idx]
            if sample then 
              rns.selected_sample_index = sample_idx
            else 
              -- selected 'none', restore current sample 
              vb.views.ssk_sample_selector.value = rns.selected_sample_index+1
            end 
          end
          
        end
      }
    },
    vb:text{
      id = "ssk_status_multisample",
      text = "",
      font = "normal",
      align = "center"
    },
    vb:checkbox{
      visible = false,
      bind = prefs.multisample_mode,
    },
  }

end

---------------------------------------------------------------------------------------------------

function SSK_Gui:build_keyzone()

  local vb = self.vb 

  self.vkeyzone = SSK_Gui_Keyzone{
    vb = vb,
    width = SSK_Gui.KEYZONE_WIDTH,
    height = SSK_Gui.KEYZONE_HEIGHT,
    note_steps = prefs.multisample_note_steps.value,
    note_min = prefs.multisample_note_min.value,
    note_max = prefs.multisample_note_max.value,
    vel_steps = prefs.multisample_vel_steps.value,
    vel_min = prefs.multisample_vel_min.value,
    vel_max = prefs.multisample_vel_max.value,
  }

  return vb:row{
    id = "ssk_multisample_editor",
    vb:space{
      width = 3,
      height = SSK_Gui.KEYZONE_HEIGHT+3,
    },   
    vb:column{
      self.vkeyzone.view,
      vb:space{
        height = 1,
        width = SSK_Gui.KEYZONE_WIDTH+3,
      },
    },
    vb:column{
      vb:text{
        text = "Note Range"
      },
      vb:row{
        vb:valuebox{
          min = xSampleMapping.MIN_NOTE,
          max = xSampleMapping.MAX_NOTE,
          bind = prefs.multisample_note_min,
          width = SSK_Gui.KEYZONE_LABEL_WIDTH,
          tostring = function(val)
            return xNoteColumn.note_value_to_string(val)
          end,
          tonumber = function(val)
            return xNoteColumn.note_string_to_value(val)
          end,
          notifier = function(val)
            --print("note_min notifier...",val)
            self.vkeyzone.note_min = val
          end
        },
        vb:valuebox{
          min = xSampleMapping.MIN_NOTE,
          max = xSampleMapping.MAX_NOTE,            
          bind = prefs.multisample_note_max,
          width = SSK_Gui.KEYZONE_LABEL_WIDTH,
          tostring = function(val)
            return xNoteColumn.note_value_to_string(val)
          end,
          tonumber = function(val)
            return xNoteColumn.note_string_to_value(val)
          end,          
          notifier = function(val)
            self.vkeyzone.note_max = val
          end          
        }
      },
      vb:row{
        vb:text{
          text = "Steps",
          align = "right",
          width = SSK_Gui.KEYZONE_LABEL_WIDTH,
        },
        vb:valuebox{
          min = SSK_Prefs.MIN_NOTE_STEPS,
          max = SSK_Prefs.MAX_NOTE_STEPS,          
          bind = prefs.multisample_note_steps,
          width = SSK_Gui.KEYZONE_LABEL_WIDTH,
          notifier = function(val)
            self.vkeyzone.note_steps = val
          end          
        }
      },
      vb:text{
        text = "Vel Range"
      },
      vb:row{
        vb:valuebox{
          min = xSampleMapping.MIN_VELOCITY,
          max = xSampleMapping.MAX_VELOCITY,            
          bind = prefs.multisample_vel_min,
          width = SSK_Gui.KEYZONE_LABEL_WIDTH,
          tostring = function(val)
            return ("%02X"):format(val)
          end,
          tonumber = function(val)
            return tonumber(val)
          end,          
          notifier = function(val)
            self.vkeyzone.vel_min = val
          end          
        },
        vb:valuebox{
          min = xSampleMapping.MIN_VELOCITY,
          max = xSampleMapping.MAX_VELOCITY,                        
          bind = prefs.multisample_vel_max,
          width = SSK_Gui.KEYZONE_LABEL_WIDTH,
          tostring = function(val)
            return ("%02X"):format(val)
          end,
          tonumber = function(val)
            return tonumber(val)
          end,                    
          notifier = function(val)
            self.vkeyzone.vel_max = val
          end          
        }
      },
      vb:row{
        vb:text{
          text = "Steps",
          align = "right",
          width = SSK_Gui.KEYZONE_LABEL_WIDTH,
        },
        vb:valuebox{
          min = SSK_Prefs.MIN_VEL_STEPS,
          max = SSK_Prefs.MAX_VEL_STEPS,
          bind = prefs.multisample_vel_steps,
          width = SSK_Gui.KEYZONE_LABEL_WIDTH,
          notifier = function(val)
            self.vkeyzone.vel_steps = val
          end                    
        }
      }
    }
  }

end

---------------------------------------------------------------------------------------------------
-- handle clicks on the selection strip 

function SSK_Gui:select_by_segment(idx,strip)
  TRACE("SSK_Gui:select_by_segment(idx,strip)",idx,strip)

  local buffer = self.owner:get_sample_buffer()
  local sample = self.owner.sample 
  if not buffer or not sample then 
    return
  end 
  local is_perfect_lead = self.owner.selection:is_perfect_lead()
  local is_perfect_trail = self.owner.selection:is_perfect_trail()

  if is_perfect_lead and is_perfect_trail and not self.display_buffer_as_loop then 
    -- select by offset index 
    local seg_start,seg_end = self.owner.selection:get_nth_segment_by_offset(idx-1,#strip.items)
    sample.sample_buffer.selection_range = {seg_start,seg_end}
  else
    -- select by assigned weight 
    local item = strip.items[idx]
    local start = strip:get_item_offset(idx)
    sample.sample_buffer.selection_range = {start+1,start+item.weight}
  end
end

---------------------------------------------------------------------------------------------------

function SSK_Gui:build_buffer_panel()

  local vb = self.vb

  self.selection_strip = vButtonStrip{
    vb = vb,
    height = SSK_Gui.STRIP_HEIGHT,
    width = SSK_Gui.DIALOG_INNER_WIDTH - 75,
    spacing = vLib.NULL_SPACING,    
    pressed = function(idx,_strip_)
      self:select_by_segment(idx,_strip_)
    end,
    released = function(idx)
    end,
  }

  return vb:column{
    vb:row{
      vb:row{
        id = "ssk_selection_strip",
        spacing = SSK_Gui.NULL_SPACING-1,
        self.selection_strip.view,
      },       
      vb:row{
        vb:column{          
          vb:button{
            id = "ssk_selection_toggle_left",
            text = "L",
            notifier = function()
              self.owner.selection:toggle_left()
            end,
          },
          vb:button{
            id = "ssk_selection_toggle_right",
            text = "R",
            notifier = function()
              self.owner.selection:toggle_right()
            end,
          },
        },
        vb:column{
          vb:row{
            spacing = SSK_Gui.NULL_SPACING,
            vb:button{
              id = "ssk_flick_back",
              text = "←",
              width = SSK_Gui.SMALL_BT_WIDTH,    
              tooltip = "Flick the selection range leftward.",      
              notifier = function()
                self.owner.selection:flick_back()
              end,          
            },
            vb:button{
              id = "ssk_flick_forward",
              text = "→",
              width = SSK_Gui.SMALL_BT_WIDTH,
              tooltip = "Flick the selection range rightward.",
              notifier = function()
                self.owner.selection:flick_forward()
              end,          
            },
          },
          vb:button{
            id = "ssk_strip_set_loop",
            width = SSK_Gui.SMALL_BT_X2_WIDTH,
            notifier = function()
              local sample = self.owner.sample
              if (self.display_buffer_as_loop) then
                xSample.clear_loop(sample)
              else
                xSample.set_loop_to_selection(sample)
              end
            end,          
          },
        }
      },        
    },    
    vb:row{
      --id = "ssk_buffer_panel",
      vb:text{
        text = "Buffer"
      },
      vb:row{
        spacing = SSK_Gui.NULL_SPACING,
        vb:button{
          id = "ssk_buffer_delete",    
          text = "‒",
          tooltip = "Clear the selection range without changing the sample length",
          notifier = function()
            self.owner:sync_del()
          end,          
        },
        vb:button{ 
          id = "ssk_buffer_insert",    
          text = "+",
          tooltip = "Insert silence without changing the sample length",
          notifier = function ()  
            self.owner:sweep_ins()
          end,
        },        
      },
      vb:space{
        width = SSK_Gui.ITEM_SPACING,
      },   
      vb:button{
        id = "ssk_buffer_trim",
        text = "Trim",
        tooltip = "Trim sample to the selected range.",
        notifier = function(x)
          self.owner:trim()
        end
      }, 
      vb:button{
        id = "ssk_buffer_copy",
        text = "Copy",
        tooltip = "Memorize the waveform in a selection range.",
        notifier = function(x)
          self.owner:buffer_memorize()
        end
      }, 
      vb:button{
        id = "ssk_buffer_copy_to_new",
        text = "Copy to new",
        tooltip = "Copy the selection range into new sample.",
        notifier = function()
          self.owner:copy_to_new()
        end,
      },        
      vb:button{
        id = "ssk_buffer_paste",
        text = 'Paste',
        tooltip = "Redraw the memorized (clipped) waveform to the selected range.",
        notifier =
        function(x)
          self.owner:buffer_redraw()
        end
      }, 
      vb:button{
        id = "ssk_buffer_mix_paste",
        text = 'Mix-Paste',
        tooltip = "Mix the memorized (clipped) waveform with the selected range.",
        notifier =
        function(x)
          self.owner:buffer_mixdraw()
        end
      },        
      vb:button{
        id = "ssk_buffer_swap",
        text = 'Swap',
        tooltip = "Swap the memorized (clipped) waveform with the selected range.",
        notifier =
        function(x)
          self.owner:buffer_swap()
        end
      },        
    },  
  }
end

---------------------------------------------------------------------------------------------------

function SSK_Gui:build_selection_panel()

  local vb = self.vb

  return vb:column{     
    style = SSK_Gui.PANEL_STYLE,
    margin = SSK_Gui.PANEL_INNER_MARGIN,
    vb:space{
      width = SSK_Gui.DIALOG_INNER_WIDTH,
    },
    vb:row{
      vb:row{
        self:build_panel_header("Selection",function()
          --             
        end,prefs.display_selection_panel),          
        vb:text{
          id = "ssk_selection_header_txt",
          width = SSK_Gui.DIALOG_INNER_WIDTH - 200,
        },
      },    
      vb:row{
        tooltip = "Sync selection with waveform editor",
        vb:text{
          text = "Sync"
        },
        vb:checkbox{
          id = "ssk_sync_with_renoise",
          bind = prefs.sync_with_renoise,
        },          
      },  
      vb:popup{
        id = "ssk_selection_unit_popup",
        tooltip = "Choose how the selection should be displayed",
        items = {
          "0xOffset",
          "Beats",
          "Samples",
        },
        bind = prefs.display_selection_as,
      }        
    },
    
    vb:column{
      id = "ssk_selection_panel",
      visible = false,
      vb:space{
        height = SSK_Gui.ITEM_SPACING,
      },
      vb:column{
        self:build_selection_start_row(),
        self:build_selection_length_row(),
      },
    },
  }
end 

---------------------------------------------------------------------------------------------------

function SSK_Gui:build_generate_panel()

  local vb = self.vb

  return vb:column{
    style = SSK_Gui.PANEL_STYLE,
    margin = SSK_Gui.PANEL_INNER_MARGIN,
    vb:space{
      width = SSK_Gui.DIALOG_INNER_WIDTH,
    },
    self:build_panel_header("Generate",function()
    end,prefs.display_generate_panel),
    vb:column{
      id = "ssk_generate_panel",
      visible = false,
      vb:row{
        vb:text{
          width = SSK_Gui.LABEL_WIDTH,
          text = "Random",
        },
        vb:button{
          id = "ssk_generate_random_bt",
          bitmap = self.btmp.run_random,
          width = SSK_Gui.WIDE_BT_WIDTH,
          height = SSK_Gui.TALL_BT_HEIGHT,
          text = 'Random',
          tooltip = "Apply random waves to the selected range",
          notifier = function()
            self.owner.generator:random_wave()
          end
        },
        vb:button{
          id = "ssk_generate_repeat_random_bt",
          width = SSK_Gui.WIDE_BT_WIDTH,
          height = SSK_Gui.TALL_BT_HEIGHT,
          text = "Repeat",
          tooltip = "Apply the last generated random wave to the selected range",
          notifier = function()
            self.owner.generator:repeat_random_wave()
          end
        },
      },
      vb:row{
        vb:text{
          width = SSK_Gui.LABEL_WIDTH,
          text = "Noise",
        },
        self:build_white_noise(),
        self:build_brown_noise(), 
        self:build_violet_noise(), 
        --self:build_pink_noise(),
      },
      vb:row{
        --spacing = SSK_Gui.NULL_SPACING,
        vb:text{
          width = SSK_Gui.LABEL_WIDTH,
          text = "Wave",
        },
        self:build_sin_2pi(),
        self:build_saw_wave(),
        self:build_square_wave(),
        self:build_triangle_wave(), 
      },
      vb:space{
        height = SSK_Gui.ITEM_SPACING,
      },
      vb:row{
        vb:space{
          width = 20,
        },
        vb:column{
          vb:row{
            tooltip = "When enabled, changes to cycle/shift etc. will automatically"
                    .."\ncause the selected waveform to be re-calculated",            
            vb:checkbox{
              id = 'ssk_auto_generate',
              bind = prefs.auto_generate,
            },
            vb:text{
              text = "Apply changes in real-time",
              width = SSK_Gui.LABEL_WIDTH,
            },  
          },         
          vb:row{
            tooltip = "When enabled, waveforms will be generated using band-limiting",
            vb:checkbox{
              id = 'band_limited',
              bind = prefs.band_limited,
            },
            vb:text{
              text = "Band-limiting",
              width = SSK_Gui.LABEL_WIDTH,
            },  
          }, 
          self:build_cycle_shift_set(),
        },
        self:build_duty_cycle(), 
      },
      vb:space{
        height = SSK_Gui.ITEM_SPACING,
      },      
    },
  }

  -- Karplus-Strong 
  --[[
  local ks_btn = self:build_ks_btn()
  local ks_len_input = self:build_ks_len_input()
  local ks_mix_input = self:build_ks_mix_input()
  local ks_amp_input = self:build_ks_amp_input()
  local ks_reset = self:build_ks_reset()

  local appendix
  = self.vb:row{
    id = 'appendix',
    visible = false,
    ks_btn, ks_len_input, ks_mix_input, ks_amp_input, ks_reset,
    margin = 6}

  local app_btn =
  self.vb:button
  {
    id = 'app_btn',
    width = 3,
    text = "App.",
    tooltip =
    "Appendix",
    
    notifier = 
    function()
      if
        self.vb.views.appendix.visible == false
      then
        self.vb.views.appendix.visible = true
        self.vb.views.app_btn.text = 'close'
      else
        self.vb.views.appendix.visible = false
        self.vb.views.app_btn.text = 'app.'
      end
    end
  }
  ]]  

end 


---------------------------------------------------------------------------------------------------
-- build generic "infinite spinner"

function SSK_Gui:build_spinner(id,fn,tooltip)
  return self.vb:valuebox{
    id = id,
    tooltip = tooltip,
    width = 20,
    height = 16,
    min = -99,
    max = 99,
    notifier = function(val)
      if not self.reset_spinner_requested then
        fn(val) 
        self.reset_spinner_requested = true
      end
    end,
  }
end

---------------------------------------------------------------------------------------------------
-- build generic percent valuebox

function SSK_Gui:build_percent_factor(label,obs)  

  local vb = self.vb

  return vb:row{
    spacing = SSK_Gui.NULL_SPACING,
    vb:text{
      text = "Factor",
      width = SSK_Gui.SMALL_LABEL_WIDTH,
    },
    vb:valuebox{
      min = 0,
      max = 100,
      bind = obs,
    },
    vb:space{
      width = SSK_Gui.ITEM_MARGIN,
    },
    vb:text{
      text = "%",
    }
  }

end

---------------------------------------------------------------------------------------------------

function SSK_Gui:build_modify_panel()

  local vb = self.vb

  return vb:column{
    style = SSK_Gui.PANEL_STYLE,
    margin = SSK_Gui.PANEL_INNER_MARGIN,
    vb:space{
      width = SSK_Gui.DIALOG_INNER_WIDTH,
    },
    vb:row{
      self:build_panel_header("Modify",function()
      end,prefs.display_modify_panel),
    },    
    vb:column{    
      id = "ssk_modify_panel",
      visible = false, 
      vb:column{
        vb:row{
          style = SSK_Gui.ROW_STYLE,
          margin = SSK_Gui.ROW_MARGIN,
          spacing = SSK_Gui.ROW_SPACING,
          vb:text{
            text = "Shift",
            width = SSK_Gui.LABEL_WIDTH,
          },
          self:build_phase_shift_plus(),
          self:build_phase_shift_minus(),
          self:build_phase_shift_fine_plus(),
          self:build_phase_shift_fine_minus(), 
        },         
        vb:row{
          style = SSK_Gui.ROW_STYLE,
          margin = SSK_Gui.ROW_MARGIN,
          spacing = SSK_Gui.ROW_SPACING,
          vb:text{
            text = "Center",
            width = SSK_Gui.LABEL_WIDTH,
          },
          vb:button{
            id = "ssk_generate_fade_center_a_bt",
            width = SSK_Gui.WIDE_BT_WIDTH,
            bitmap = self.btmp.center_fade,
            height = SSK_Gui.TALL_BT_HEIGHT,
            tooltip = "Fade center",
            notifier = function()
              self.owner.modify:set_fade(SSK_Modify.center_fade_fn)
            end,
          },
          vb:button{
            id = "ssk_generate_fade_center_b_bt",
            width = SSK_Gui.WIDE_BT_WIDTH,
            bitmap = self.btmp.center_amplify,
            height = SSK_Gui.TALL_BT_HEIGHT,
            tooltip = "Amplify center",
            notifier = function()
              self.owner.modify:set_fade(SSK_Modify.center_amplify_fn)
            end,
          }, 
          self:build_percent_factor("Factor",prefs.center_fade_percent),           
        },
        vb:row{
          style = SSK_Gui.ROW_STYLE,
          margin = SSK_Gui.ROW_MARGIN,
          spacing = SSK_Gui.ROW_SPACING,
          vb:text{
            text = "Multiply",
            width = SSK_Gui.LABEL_WIDTH,
          },
          vb:button{
            id = "ssk_generate_multiply_lower_bt",
            width = SSK_Gui.WIDE_BT_WIDTH,
            bitmap = self.btmp.multiply_lower,
            height = SSK_Gui.TALL_BT_HEIGHT,
            tooltip = "Lower amplitude",
            notifier = function()
              self.owner.modify:set_fade(SSK_Modify.multiply_lower_fn)
            end,
          },
          vb:button{
            id = "ssk_generate_multiply_raise_bt",
            width = SSK_Gui.WIDE_BT_WIDTH,
            bitmap = self.btmp.multiply_raise,
            height = SSK_Gui.TALL_BT_HEIGHT,
            tooltip = "Raise amplitude",
            notifier = function()
              self.owner.modify:set_fade(SSK_Modify.multiply_raise_fn)
            end,
          },
          self:build_percent_factor("Factor",prefs.multiply_percent),           
        },
        vb:row{
          style = SSK_Gui.ROW_STYLE,
          margin = SSK_Gui.ROW_MARGIN,
          spacing = SSK_Gui.ROW_SPACING,
          vb:text{
            text = "Fade",
            width = SSK_Gui.LABEL_WIDTH,
          },
          vb:button{
            id = "ssk_generate_fade_in_bt",
            width = SSK_Gui.WIDE_BT_WIDTH,
            bitmap = self.btmp.fade_in,
            height = SSK_Gui.TALL_BT_HEIGHT,
            tooltip = "Fade in",
            notifier = function()
              self.owner.modify:set_fade(SSK_Modify.fade_in_fn)
            end,
          },
          vb:button{
            id = "ssk_generate_fade_out_bt",
            width = SSK_Gui.WIDE_BT_WIDTH,
            bitmap = self.btmp.fade_out,
            height = SSK_Gui.TALL_BT_HEIGHT,
            tooltip = "Fade out",
            notifier = function()
              self.owner.modify:set_fade(SSK_Modify.fade_out_fn)
            end,
          }, 
          self:build_percent_factor("Factor",prefs.fade_percent),           
        },
        --[[
        vb:row{
          style = SSK_Gui.ROW_STYLE,
          margin = SSK_Gui.ROW_MARGIN,
          --width = "100%",
          spacing = SSK_Gui.ROW_SPACING,
          vb:text{
            text = "Resize",
            width = SSK_Gui.LABEL_WIDTH,
            --align = "center"
          },
          vb:button{
            id = "ssk_resize_expand_bt",
            width = SSK_Gui.WIDE_BT_WIDTH,
            bitmap = self.btmp.resize_expand,
            height = SSK_Gui.TALL_BT_HEIGHT,
            tooltip = "Expand selection",
            notifier = function()
              self.owner:resize_expand()
            end,
          },           
          vb:button{
            id = "ssk_resize_shrink_bt",
            width = SSK_Gui.WIDE_BT_WIDTH,
            bitmap = self.btmp.resize_shrink,
            height = SSK_Gui.TALL_BT_HEIGHT,
            tooltip = "Shrink selection",
            notifier = function()
              self.owner:resize_shrink()
            end,
          }, 
          self:build_percent_factor("Factor",prefs.resize_percent),           
        },
        ]]
        vb:row{
          style = SSK_Gui.ROW_STYLE,
          margin = SSK_Gui.ROW_MARGIN,
          spacing = SSK_Gui.ROW_SPACING,
          vb:text{
            text = "Ringmod",
            width = SSK_Gui.LABEL_WIDTH,
          },
          self:build_ring_mod_sin(),
          self:build_ring_mod_saw(),
          self:build_ring_mod_square(),
          self:build_ring_mod_triangle(),
          vb:button{
            id = "ssk_generate_pd_copy_bt",
            text = "PD Copy",
            width = SSK_Gui.WIDE_BT_WIDTH,
            height = SSK_Gui.TALL_BT_HEIGHT,
            tooltip = SSK_Gui.MSG_COPY_PD,
            notifier = function()
              self.owner.modify:pd_copy()
            end,
          },
        },
        vb:row{      
          vb:space{
            width = SSK_Gui.ITEM_HEIGHT,
          },        
          self:build_fade_cycle_shift_set(), 
          vb:space{
            height = SSK_Gui.ITEM_SPACING,
          },
          self:build_pd_duty_cycle(), 
        },
      }
    }
  }

end 

---------------------------------------------------------------------------------------------------
-- set selection start 

function SSK_Gui:build_selection_start_row()

  local vb = self.vb

  return vb:row{ 
    vb:text{
      width = SSK_Gui.LABEL_WIDTH - SSK_Gui.TOGGLE_SIZE - 2,
      text = "Start"
    },    
    vb:button{
      text = "➙",
      id = "ssk_get_selection_start",
      tooltip = "Get selection start in the waveform editor.",
      notifier = function()
        self.owner.selection:obtain_start_from_editor()        
      end,
    },    
    vb:row{
      spacing = vLib.NULL_SPACING,
      vb:textfield{ 
        id = "ssk_selection_start",
        width = SSK_Gui.INPUT_WIDTH,
        tooltip = SSK_Gui.MSG_GET_LENGTH_BEAT_TIP, 
        notifier = function(x)
          --print("ssk_selection_start notifier",x)
          local buffer = self.owner:get_sample_buffer()
          if not buffer then 
            return
          end
          local is_start = true -- allow first frame
          local offset,beat,frame = self.owner.selection:interpret_input(x,is_start)
          if (not frame or not beat or not offset) then 
            renoise.app():show_error(SSK_Gui.MSG_GET_LENGTH_FRAME_ERR)
          else 
            self.owner.selection.start_frames = frame
            self.owner.selection.start_beats = beat
            self.owner.selection.start_offset = offset
          end
        end
      },
      self:build_spinner("ssk_sel_start_spinner",function(val)
        self.owner.selection:nudge_start(val)
      end,"Increase/decrease the selection start"),    
    },
    vb:button{
      text = "Set",
      id = "ssk_selection_apply_start",
      tooltip = "Click to update the selection start (and extend the sample if needed).",
      notifier = function()
        local sel_start = self.owner.selection.start_frames
        local sel_end = sel_start + self.owner.selection.length_frames
        self.owner.selection:apply_range(sel_start,sel_end)
      end
    },

  }
end 

---------------------------------------------------------------------------------------------------
-- set selection length 

function SSK_Gui:build_selection_length_row()

  local vb = self.vb

  return vb:row{ 
    vb:text{
      width = SSK_Gui.LABEL_WIDTH - SSK_Gui.TOGGLE_SIZE - 2,
      text = "Length"
    },    
    vb:button{
      text = "➙",
      id = "ssk_get_selection_length",
      tooltip = "Get length of selection in the waveform editor.",
      notifier = function()
        self.owner.selection:obtain_length_from_editor()        
      end,
    },    
    vb:row{
      spacing = vLib.NULL_SPACING,
      vb:textfield{ 
        id = "ssk_selection_length",
        width = SSK_Gui.INPUT_WIDTH,
        tooltip = SSK_Gui.MSG_GET_LENGTH_BEAT_TIP, 
        notifier = function(x)
          --print("ssk_selection_length notifier",x)
          local buffer = self.owner:get_sample_buffer()
          if not buffer then 
            return
          end
          local offset,beat,frame = self.owner.selection:interpret_input(x)
          if (not frame or not beat or not offset) then 
            renoise.app():show_error(SSK_Gui.MSG_GET_LENGTH_FRAME_ERR)
          else 
            self.owner.selection.length_frames = frame
            self.owner.selection.length_beats = beat
            self.owner.selection.length_offset = offset
          end
        end
      },
      self:build_spinner("ssk_sel_length_spinner",function(val)
        self.owner.selection:nudge_length(val)
      end,"Increase/decrease the selection length"),
    },
    vb:button{
      text = "Set",
      id = "ssk_selection_apply_length",
      tooltip = "Click to update the selection length (and extend the sample if needed).",
      notifier = function()
        local sel_start = self.owner.selection.start_frames
        local sel_end = sel_start + self.owner.selection.length_frames
        self.owner.selection:apply_range(sel_start,sel_end)
      end
    },
    vb:button{
      id = "ssk_selection_multiply_length",
      text = "*",
      tooltip = "Multiply the length of the selection range .",
      notifier = function()
        self.owner.selection:multiply_length()
      end,
    },
    vb:button{
      id = "ssk_selection_divide_length",
      text = "/",
      tooltip = "Reset the length of the selection range with reciprocal number.",
      notifier = function()
        self.owner.selection:divide_length()
      end,
    },
    vb:textfield{ 
      id = "multiply_setend",
      text = tostring(prefs.multiply_setend.value),
      tooltip = SSK_Gui.MSG_MULTIPLY_TIP,
      notifier = function(x)
        local xx = cReflection.evaluate_string(x) 
        if xx == nil
        then
          renoise.app():show_error(SSK_Gui.MSG_MULTIPLY_ERR)
        else 
          self.owner.multiply_setend = xx
        end
      end
    },
  }
end 

---------------------------------------------------------------------------------------------------
-- Generators
---------------------------------------------------------------------------------------------------
  -- Draw sin wave 2pi
  
function SSK_Gui:build_sin_2pi()  
  return self.vb:button{
    id = "ssk_generate_sin_wave_bt",
    width = SSK_Gui.WIDE_BT_WIDTH,
    bitmap = self.btmp.sin_2pi,
    height = SSK_Gui.TALL_BT_HEIGHT,
    tooltip = "Draw sin wave.",
    notifier = function()
      self.owner.generator:sine_wave()
    end,
  }
end

---------------------------------------------------------------------------------------------------
  -- saw wave

function SSK_Gui:build_saw_wave()  
  
  return self.vb:button{
    id = "ssk_generate_saw_wave_bt",
    width = SSK_Gui.WIDE_BT_WIDTH,
    bitmap = self.btmp.saw,
    height = SSK_Gui.TALL_BT_HEIGHT,
    tooltip = "Draw saw wave.",
    notifier = function()
      self.owner.generator:saw_wave()
    end,
  }
end

---------------------------------------------------------------------------------------------------
-- square wave

function SSK_Gui:build_square_wave()  

  return self.vb:button{
    id = "ssk_generate_square_wave_bt",
    width = SSK_Gui.WIDE_BT_WIDTH,
    bitmap = self.btmp.square,
    height = SSK_Gui.TALL_BT_HEIGHT,
    tooltip = "Draw square wave.",
    notifier = function()
      self.owner.generator:square_wave()
    end,
  }
end

---------------------------------------------------------------------------------------------------
-- triangle wave

function SSK_Gui:build_triangle_wave()
  return self.vb:button{
    id = "ssk_generate_triangle_wave_bt",
    width = SSK_Gui.WIDE_BT_WIDTH,
    bitmap = self.btmp.triangle,
    height = SSK_Gui.TALL_BT_HEIGHT,
    tooltip = "Draw triangle wave.",
    notifier = function()
      self.owner.generator:triangle_wave()
    end,
  }
end

---------------------------------------------------------------------------------------------------
-- Wave modulating values input

function SSK_Gui:build_cycle_shift_set()

  local vb = self.vb

  return vb:column{
    vb:row{
      vb:text{
        text = "Cycle",
        width = SSK_Gui.SMALL_LABEL_WIDTH,
      },
      vb:textfield{
        id = 'mod_cycle',
        text = tostring(prefs.mod_cycle.value),
        width = SSK_Gui.FORMULA_WIDTH,
        tooltip = SSK_Gui.MSG_MOD_CYCLE,
        notifier = function(x)
          local xx = cReflection.evaluate_string(x)
          if xx == nil then
            local msg = SSK_Gui.MSG_MOD_CYCLE
            renoise.app():show_error(msg)
          else
            self.owner.mod_cycle = xx
          end
        end
      },
    },
    vb:row{
      vb:text{
        text = "Shift",
        width = SSK_Gui.SMALL_LABEL_WIDTH,
      },
      vb:valuebox{
        id = 'mod_shift',
        bind = prefs.mod_shift,
        min = -100,
        max = 100,
        tostring = function(x)
          return tostring(cLib.round_with_precision(x,3))
        end,
        tonumber = function(x)
          return cReflection.evaluate_string(x)
        end,
        tooltip = SSK_Gui.MSG_MOD_SHIFT,
        notifier = function(x)       
          --prefs.mod_shift.value = x/100
        end
      },
      vb:text {
        text = "% "
      },      
      vb:button{
        text = "Reset",
        tooltip = "Reset values.",
        notifier = function()
          vb.views.mod_cycle.text = '1'
          prefs.mod_shift.value= 0
        end,
      },      
       
    }
  }

end 

---------------------------------------------------------------------------------------------------
-- Duty Cycle variation in the range

function SSK_Gui:build_duty_cycle()

  local vb = self.vb

  return vb:column{
    vb:row{
      tooltip = "When enabled, duty cycle applies to the generated waveforms",
      vb:checkbox{
        id = 'duty_onoff',
        bind = prefs.mod_duty_onoff,
      },  
      vb:text{
        text = "Duty cycle",
      },  
    },
    -- Input duty cycle 
    vb:row{
      vb:text{
        text = "Cycle",
        width = SSK_Gui.SMALL_LABEL_WIDTH,
      },
      vb:valuebox{
        id = 'duty_fiducial',
        value = prefs.mod_duty.value,
        min = 0,
        max = 100,
        tostring = function(x)
          return tostring(cLib.round_with_precision(x,3))
        end,
        tonumber = function(x)
          return cReflection.evaluate_string(x)
        end,
        tooltip = "Input duty cycle (fiducial value)",
        notifier = function(x)       
          prefs.mod_duty.value = tonumber(x)
        end
      },
      vb:text{
        text = "% "
      },
      vb:button{
        text = "Reset",
        tooltip = "Reset duty cycle values.",
        notifier = function()
          vb.views.duty_fiducial.value = 50
          vb.views.duty_variation.value = 0
          vb.views.duty_var_frq.value = 1
        end,
      },
    },    
    vb:row{
      vb:text{
        text = "Var",
        width = SSK_Gui.SMALL_LABEL_WIDTH,
      },
      vb:valuebox{
        id = 'duty_variation',
        value = prefs.mod_duty_var.value,
        min = -100,
        max = 100,
        tostring = function(x)
          return tostring(cLib.round_with_precision(x,3))
        end,
        tonumber = function(x)
          return cReflection.evaluate_string(x)
        end,
        tooltip = SSK_Gui.MSG_DUTY_VAR,
        notifier = function(x)       
          prefs.mod_duty_var.value = x
        end
      },
      vb:text{
        text = "% "
      },
    },
    vb:row{
      vb:text{
        text = "Freq",
        width = SSK_Gui.SMALL_LABEL_WIDTH,
      },
      vb:valuebox{
        id = 'duty_var_frq',
        value = prefs.mod_duty_var_frq.value,
        min = -10000,
        max = 10000,
        tostring = function(x)
          return tostring(cLib.round_with_precision(x,3))
        end,
        tonumber = function(x)
          return cReflection.evaluate_string(x)
        end,
        tooltip = SSK_Gui.MSG_DUTY_FRQ,
        notifier = function(x)       
          prefs.mod_duty_var_frq.value = x
        end
      },
    },
  }
end 

---------------------------------------------------------------------------------------------------

function SSK_Gui:build_white_noise()
  return self.vb:button{
    id = "ssk_generate_white_noise_bt",
    width = SSK_Gui.WIDE_BT_WIDTH,
    height = SSK_Gui.TALL_BT_HEIGHT,
    bitmap = self.btmp.white_noise,
    tooltip = "White noise",
    notifier = function()
      self.owner.generator:white_noise()
    end,
  }
end

---------------------------------------------------------------------------------------------------

function SSK_Gui:build_brown_noise()
  return self.vb:button{
    id = "ssk_generate_brown_noise_bt",
    width = SSK_Gui.WIDE_BT_WIDTH,
    height = SSK_Gui.TALL_BT_HEIGHT,
    bitmap = self.btmp.brown_noise,
    tooltip = "Brown noise",
    notifier = function()
      self.owner.generator:brown_noise()    
    end,
  }
end 

---------------------------------------------------------------------------------------------------

function SSK_Gui:build_violet_noise()
  return self.vb:button{
    id = "ssk_generate_violet_noise_bt",
    width = SSK_Gui.WIDE_BT_WIDTH,
    height = SSK_Gui.TALL_BT_HEIGHT,
    bitmap = self.btmp.violet_noise,
    tooltip = "Violet noise",
    notifier = function()
      self.owner.generator:violet_noise()    
    end,
  }
end 

---------------------------------------------------------------------------------------------------
-- Pink noise (Unfinished)
--[[
function SSK_Gui:build_pink_noise()  
  return self.vb:button{
    width = SSK_Gui.WIDE_BT_WIDTH,
    height = SSK_Gui.TALL_BT_HEIGHT,
    tooltip = "Pink noise",
    notifier = function()
      self.owner:make_wave(cWaveform.pink_noise_fn)
      random_seed = 0
    end,
  }
end 
]]

---------------------------------------------------------------------------------------------------
-- Modifiers
---------------------------------------------------------------------------------------------------
-- Phase shift 1/24 +

function SSK_Gui:build_phase_shift_plus()  
  return self.vb:button{
    id = "ssk_generate_shift_plus_bt",
    width = SSK_Gui.WIDE_BT_WIDTH,
    bitmap = self.btmp.phase_shift_plus,
    tooltip = "Phase shift +1/24",
    notifier = function()
      self.owner.modify:phase_shift_with_ratio(1/24)
    end,
  }
end  

---------------------------------------------------------------------------------------------------
-- Phase shift 1/24 +

function SSK_Gui:build_phase_shift_minus()  
  return self.vb:button{
    id = "ssk_generate_shift_minus_bt",
    width = SSK_Gui.WIDE_BT_WIDTH,
    bitmap = self.btmp.phase_shift_minus,
    tooltip = "Phase shift -1/24",
    notifier = function()
      self.owner.modify:phase_shift_with_ratio(-1/24)
    end,
  }
end 

---------------------------------------------------------------------------------------------------
--  Phase shift +1sample

function SSK_Gui:build_phase_shift_fine_plus()  
  return self.vb:button{
    id = "ssk_generate_shift_plus_fine_bt",
    width = SSK_Gui.WIDE_BT_WIDTH,
    bitmap = self.btmp.phase_shift_fine_plus,
    tooltip = "Phase shift +1sample",
    notifier = function()
      self.owner.modify:phase_shift_fine(1)
    end,
  }
end 

---------------------------------------------------------------------------------------------------
-- Phase shift -1sample

function SSK_Gui:build_phase_shift_fine_minus()  
  return self.vb:button{
    id = "ssk_generate_shift_minus_fine_bt",
    width = SSK_Gui.WIDE_BT_WIDTH,
    bitmap = self.btmp.phase_shift_fine_minus,
    tooltip = "Phase shift -1sample",
    notifier = function()
      self.owner.modify:phase_shift_fine(-1)
    end,
  }
end 

---------------------------------------------------------------------------------------------------
--Fade with sin wave

function SSK_Gui:build_ring_mod_sin()
  return self.vb:button{
    id = "ssk_generate_rm_sin_bt",
    width = SSK_Gui.WIDE_BT_WIDTH,
    bitmap = self.btmp.ring_mod_sin,
    height = SSK_Gui.TALL_BT_HEIGHT,
    tooltip = "Fade (Ring modulation) with sin",
    notifier = function()
      self.owner.modify:fade_mod_sin()
    end,
  }
end 

---------------------------------------------------------------------------------------------------
-- Fade with saw wave

function SSK_Gui:build_ring_mod_saw()
  return self.vb:button{
    id = "ssk_generate_rm_saw_bt",
    width = SSK_Gui.WIDE_BT_WIDTH,
    bitmap = self.btmp.ring_mod_saw,
    height = SSK_Gui.TALL_BT_HEIGHT,
    tooltip = "Fade (Ring modulation) witn saw",
    notifier = function()
      self.owner.modify:fade_mod_saw()
    end,
  }
end 

---------------------------------------------------------------------------------------------------
-- Fade with square wave

function SSK_Gui:build_ring_mod_square()  
  return self.vb:button{
    id = "ssk_generate_rm_square_bt",
    width = SSK_Gui.WIDE_BT_WIDTH,
    bitmap = self.btmp.ring_mod_square,
    height = SSK_Gui.TALL_BT_HEIGHT,
    tooltip = "Fade (Ring modulation) witn square",
    notifier = function()
      self.owner.modify:fade_mod_square()
    end,
  }
end 

---------------------------------------------------------------------------------------------------
-- Fade with triangle wave

function SSK_Gui:build_ring_mod_triangle()  
  return self.vb:button{
    id = "ssk_generate_rm_triangle_bt",
    width = SSK_Gui.WIDE_BT_WIDTH,
    bitmap = self.btmp.ring_mod_triangle,
    height = SSK_Gui.TALL_BT_HEIGHT,
    tooltip = "Fade (Ring modulation) witn triangle",
    notifier = function()
      self.owner.modify:fade_mod_triangle()
    end,
  }
end 


---------------------------------------------------------------------------------------------------
-- Set phase distortion values in feding & PD-copy 

function SSK_Gui:build_fade_cycle_shift_set()

  local vb = self.vb

  return vb:column{
    vb:row{
      vb:text{
        text = "Cycle",  
        width = SSK_Gui.SMALL_LABEL_WIDTH,
      },
      vb:textfield{
        id = 'mod_fade_cycle',
        width = SSK_Gui.FORMULA_WIDTH,
        text = tostring(prefs.mod_fade_cycle.value),
        tooltip = SSK_Gui.MSG_FADE_TIP, 
        notifier = function(x)
          local xx = cReflection.evaluate_string(x)
          if xx == nil
          then
            local msg = SSK_Gui.MSG_FADE
            renoise.app():show_error(err)
          else
            self.owner.mod_fade_cycle = xx
          end
        end
      },
    },
    vb:row{
      vb:text{
        text = "Shift",
        width = SSK_Gui.SMALL_LABEL_WIDTH,
      },
      vb:valuebox{
        id = 'mod_fade_shift',
        value = prefs.mod_fade_shift.value*100,
        min = -100,
        max = 100,
        tostring = function(x)
          return tostring(cLib.round_with_precision(x,3))
        end,
        tonumber = function(x)
          return cReflection.evaluate_string(x)
        end,
        tooltip = SSK_Gui.MSG_FADE_SHIFT,      
        notifier = function(x)       
          prefs.mod_fade_shift.value = x/100
        end
      },
      vb:text{
        text = "% "
      },    
      vb:button{
        text = "Reset",
        tooltip = "Reset values.",
        notifier = function()
          vb.views.mod_fade_cycle.text = '1'
          prefs.mod_fade_shift.value = 0
        end,
      },
    }
  }
end 

---------------------------------------------------------------------------------------------------
-- Duty cycle for fade & phase distortion copy

function SSK_Gui:build_pd_duty_cycle()

  local vb = self.vb 

  return vb:column{
    vb:row{
      tooltip = "When enabled, duty cycle applies to the generated waveforms",      
      vb:checkbox{
        id = 'pd_duty_onoff',
        bind = prefs.mod_pd_duty_onoff,
      },  
      vb:text{
        text = "Duty Cycle"
      },  
    },
    vb:row{    
      vb:text{
        text = "Cycle",     
        width = SSK_Gui.SMALL_LABEL_WIDTH, 
      },
      vb:valuebox{
        id = 'pd_duty_fiducial',
        value = prefs.mod_pd_duty.value,
        min = 0,
        max = 100,
        tostring = function(x)
          return tostring(cLib.round_with_precision(x,3))
        end,
        tonumber = function(x)
          return cReflection.evaluate_string(x)
        end,
        tooltip = "Input duty cycle (fiducial value)",
        notifier = function(x)       
          prefs.mod_pd_duty.value = tonumber(x)
        end
      },
      vb:text{
        text = "% "
      },
      vb:button{
        text = "Reset",
        tooltip = "Reset values.",
        notifier = function()
          vb.views.pd_duty_fiducial.value = 50
          vb.views.pd_duty_variation.value = 0
          vb.views.pd_duty_var_frq.value = 1
        end,
      },      
    },
    vb:row{
      vb:text{
        text = "Var",
        width = SSK_Gui.SMALL_LABEL_WIDTH,
      },
      vb:valuebox{
        id = 'pd_duty_variation',
        value = self.owner.mod_pd_duty_var,
        min = -100,
        max = 100,
        tostring = function(x)
          return tostring(cLib.round_with_precision(x,3))
        end,
        tonumber = function(x)
          return cReflection.evaluate_string(x)
        end,
        tooltip = SSK_Gui.MSG_MOD_DUTY_VAR,
        notifier = function(x)       
          self.owner.mod_pd_duty_var = tonumber(x)
        end
      },
      vb:text{
        text = "% "
      },
    },
    vb:row{
      vb:text{
        text = "Freq",
        width = SSK_Gui.SMALL_LABEL_WIDTH,
      },
      vb:valuebox{
        id = 'pd_duty_var_frq',
        value = self.owner.mod_pd_duty_var_frq,
        min = -10000,
        max = 10000,
        tostring = function(x)
          return tostring(cLib.round_with_precision(x,3))
        end,
        tonumber = function(x)
          return cReflection.evaluate_string(x)
        end,      
        tooltip = SSK_Gui.MSG_MOD_DUTY_FRQ,
        notifier = function(x)       
          self.owner.mod_pd_duty_var_frq = x
        end
      },
    }    
  }
end 

---------------------------------------------------------------------------------------------------
-- Karplus-Strong String
--[[
function SSK_Gui:build_ks_btn()
  return self.vb:button{
    --width = 80,
    text = 'KS String',
    tooltip = "This modulates the sample with Karplus-Strong string synthesis." 
            .."\nPlease prepare selection length that is longer than ks-length value.",
    notifier = function(x)       
      local fn = ks_copy_fn_fn(
        self.owner.ks_len_var,
        self.owner.ks_mix_var,
        self.owner.ks_amp_var)
      self.owner:make_wave(fn)
    end    
  }  
end 

---------------------------------------------------------------------------------------------------
-- Input K-s string first pulse length

function SSK_Gui:build_ks_len_input()
  return self.vb:row{
    self.vb:text{
      text = "length:"
    },
    self.vb:textfield{
      id = 'ks_len',
      --edit_mode = true,
      text = tostring(self.owner.ks_len_var),
      tooltip = "Input the length of K-S synthesis first pulse."
              .."\nThis determines the pitch."
              .."\nYou can use some letters that represents pitch, e.g.'C#4'.",      
      notifier = function(x)
        local xx = SSK_Selection.string_to_frames(x,prefs.A4hz.value) 
        if xx == nil
        then
          renoise.app():show_error("Enter a  non-zero number, or a numerical formula. This decides string pitch.")
        else
          self.owner.ks_len_var = xx
        end
      end
    }
  }
end 

---------------------------------------------------------------------------------------------------
-- Input dry-mix value in K-s string

function SSK_Gui:build_ks_mix_input()
  return self.vb:row{
    self.vb:text{
      text = " mix:"
    },    
    self.vb:valuebox{
      id = 'ks_mix',
      value = self.owner.ks_mix_var,
      min = 0,
      max = 100,
      tostring = function(x)
        return tostring(cLib.round_with_precision(x,3))
      end,
      tonumber = function(x)
        return cReflection.evaluate_string(x)
      end,
      tooltip = "Input dry-mix value for K-S string.",      
      notifier = function(x)       
        self.owner.ks_mix_var = x/100
      end
    },
    self.vb:text{
      text = "% "
    }
  }
end 

---------------------------------------------------------------------------------------------------
-- Input amplification value in K-s string

function SSK_Gui:build_ks_amp_input()
  return self.vb:row{
    self.vb:text{
      text = "amp:"
    },    
    self.vb:valuebox{
      id = 'ks_amp',
      value = self.owner.ks_amp_var,
      min = 0,
      max = 1000,
      tostring = function(x)
        return tostring(cLib.round_with_precision(x,3))
      end,
      tonumber = function(x)
        return cReflection.evaluate_string(x)
      end,
      tooltip = "Input amplification value for K-S string",      
      notifier = function(x)       
        self.owner.ks_amp_var = x/1000
      end
    },
    
  }
end 

---------------------------------------------------------------------------------------------------
-- Reset K-S string values 

function SSK_Gui:build_ks_reset()
  return self.vb:button{
    text = "Reset",
    tooltip = "Reset values.",
    notifier = function()
      self.vb.views.ks_len.text = tostring(SSK_Selection.string_to_frames('C-4',prefs.A4hz.value))
      self.vb.views.ks_mix.value = 0
      self.vb.views.ks_amp.value = 0
    end,
  }
end 
]]

---------------------------------------------------------------------------------------------------
-- Make random waves

function SSK_Gui:build_panel_header(title,callback,cb_binding)
  return self.vb:row{
    self.vb:checkbox{
      bind = cb_binding,
      width = SSK_Gui.TOGGLE_SIZE,
      height = SSK_Gui.TOGGLE_SIZE,        
      notifier = callback, 
    },
    self.vb:text{
      text = title,
      font = SSK_Gui.PANEL_HEADER_FONT,
    },
  }  
end 

---------------------------------------------------------------------------------------------------

function SSK_Gui:idle_notifier()

  if self.dialog then
    if self.reset_spinner_requested then 
      self.vb.views.ssk_sel_start_spinner.value = 0
      self.vb.views.ssk_sel_length_spinner.value = 0
      self.reset_spinner_requested = false 
    end
    if self.update_strip_requested then 
      self.update_strip_requested = false
      self:update_selection_strip()
      self:update_buffer_controls()    
      self:update_selection_strip_controls()
    end 
    if self.update_toolbar_requested then 
      self.update_toolbar_requested = false
      self:update_toolbar()
    end 
    if self.update_selection_requested then 
      self.update_selection_header_requested = true
      self.update_selection_requested = false
      self:update_selection_length()
    end 
    if self.update_selection_header_requested then 
      self.update_selection_header_requested = false
      self:update_selection_header()
    end 
    if self.update_select_panel_requested then 
      self.update_select_panel_requested = false 
      self:update_select_panel()
    end 
    if self.update_generate_panel_requested then 
      self.update_generate_panel_requested = false 
      self:update_generate_panel()
    end 
    if self.update_modify_panel_requested then 
      self.update_modify_panel_requested = false 
      self:update_modify_panel()
    end 
  end 

end

