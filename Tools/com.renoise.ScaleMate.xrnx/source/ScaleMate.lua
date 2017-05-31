--[[===============================================================================================
ScaleMate_UI
===============================================================================================]]--
--[[

ScaleMate provides easy control of scales and keys 

]]

--=================================================================================================

class 'ScaleMate'

---------------------------------------------------------------------------------------------------
-- Constructor method

function ScaleMate:__init(...)
  TRACE("ScaleMate:__init(...)",...)

  local args = cLib.unpack_args(...)

  self.prefs = renoise.tool().preferences
  self.ui = ScaleMate_UI{
    owner = self,
    dialog_title = args.dialog_title,
    midi_prefix = args.midi_prefix,
  }

  -- while true, don't output to pattern
  self.suppress_write = true 

  --== initialize ==--

  renoise.tool().app_new_document_observable:add_notifier(function()
    rns = renoise.song()
    self:attach_to_song()
  end)

  self:attach_to_song()

end

---------------------------------------------------------------------------------------------------
-- Set selected instrument to the provide scale
-- @param name (string)

function ScaleMate:set_scale(name)
  TRACE("ScaleMate:set_scale(name)",name)

  local instr = rns.selected_instrument 
  if not instr then 
   LOG("*** Could not resolve instrument")
  end 

  instr.trigger_options.scale_mode = name

  if self.prefs.write_to_pattern.value then
    self:write_scale()
  end

end

---------------------------------------------------------------------------------------------------
-- Set selected instrument to the provide key
-- @param val (number)

function ScaleMate:set_key(val)
  TRACE("ScaleMate:set_key(val)",val)

  local instr = rns.selected_instrument 
  if not instr then 
   LOG("*** Could not resolve instrument")
  end 

  instr.trigger_options.scale_key = val

  if self.prefs.write_to_pattern.value then
    self:write_key()
  end

end

---------------------------------------------------------------------------------------------------
-- Perform a few checks before writing
-- @return boolean, true when we are able to write output 

function ScaleMate:pre_write_check(track,line)
  TRACE("ScaleMate:pre_write_check(track,line)",track,line)

  if self.suppress_write then 
    return false
  end

  if (track.type ~= renoise.Track.TRACK_TYPE_SEQUENCER) then 
    return false,"*** Error: unable to write scale mode to a non-sequencer track"
  end 

  if xLinePattern.get_midi_command(track,line) then 
    return false, "*** Warning: the selected line already contains a MIDI command"
                .." (hint: use a different line and/or track)"
  end 

  return true

end

---------------------------------------------------------------------------------------------------
-- Update pattern (cursor position) with selected scale
-- If not able to produce output (e.g. wrong track type), then display an error message in 
-- the status bar / scripting console

function ScaleMate:write_scale()
  TRACE("ScaleMate:write_scale()")
  
  local track = rns.selected_track 
  local line = rns.selected_line 
  
  local checked,err = self:pre_write_check(track,line)
  if not checked then 
    if err then 
      renoise.app():show_status(err)
      LOG(err)  
    end
    return 
  end 

  local instr = rns.selected_instrument 
  local cmd = xMidiCommand{
    instrument_index = rns.selected_instrument_index,
    message_type = xMidiCommand.TYPE.CONTROLLER_CHANGE,
    number_value = 15,
    amount_value = xScale.get_scale_index_by_name(instr.trigger_options.scale_mode)-1,
  }
  xLinePattern.set_midi_command(track,line,cmd)

end

---------------------------------------------------------------------------------------------------
-- Update pattern (cursor position) with selected scale
-- If not able to produce output (e.g. wrong track type), then display an error message in 
-- the status bar / scripting console

function ScaleMate:write_key()
  TRACE("ScaleMate:write_key()")
  
  local track = rns.selected_track 
  local line = rns.selected_line 

  local checked,err = self:pre_write_check(track,line)
  if not checked then 
    if err then 
      renoise.app():show_status(err)
      LOG(err)  
    end
    return 
  end 
  
  local instr = rns.selected_instrument 
  local cmd = xMidiCommand{
    instrument_index = rns.selected_instrument_index,
    message_type = xMidiCommand.TYPE.CONTROLLER_CHANGE,
    number_value = 14,
    amount_value = instr.trigger_options.scale_key-1,
  }
  xLinePattern.set_midi_command(track,line,cmd)

end

---------------------------------------------------------------------------------------------------

function ScaleMate:clear_pattern_track()
  TRACE("ScaleMate:clear_pattern_track()")

  local track = rns.selected_track
  local patt = rns.selected_pattern 
  local ptrack = patt.tracks[rns.selected_track_index]
  local index_from = 1
  local index_to = patt.number_of_lines
  local lines = ptrack:lines_in_range(index_from, index_to)
  for k,line in ipairs(lines) do
    if not line.is_empty then 
      local cmd = xLinePattern.get_midi_command(track,line)
      if cmd then 
        xLinePattern.clear_midi_command(track,line)
      end 
    end
  end

end

---------------------------------------------------------------------------------------------------

function ScaleMate:instrument_notifier()
  TRACE(">>> ScaleMate:instrument_notifier")
  self:attach_to_instrument()
end

---------------------------------------------------------------------------------------------------

function ScaleMate:scale_key_notifier()
  TRACE(">>> ScaleMate:scale_key_notifier")
  -- temporarily suppress output while updating UI 
  self.suppress_write = true
  self.ui:update()
  self.suppress_write = false
end

---------------------------------------------------------------------------------------------------

function ScaleMate:attach_to_song()
  TRACE("ScaleMate:attach_to_song()")
  local obs = rns.selected_instrument_index_observable
  cObservable.attach(obs,self,self.instrument_notifier)
  self:attach_to_instrument()
end

---------------------------------------------------------------------------------------------------

function ScaleMate:attach_to_instrument()
  TRACE("ScaleMate:attach_to_instrument()")
  local obs = nil
  obs = rns.selected_instrument.trigger_options.scale_mode_observable
  cObservable.attach(obs,self,self.scale_key_notifier)
  obs = rns.selected_instrument.trigger_options.scale_key_observable
  cObservable.attach(obs,self,self.scale_key_notifier)
  self:scale_key_notifier()
end
