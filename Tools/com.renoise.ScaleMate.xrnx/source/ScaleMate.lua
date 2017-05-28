--[[============================================================================
ScaleMate_UI
============================================================================]]--
--[[

ScaleMate provides easy control of scales and keys 

]]

class 'ScaleMate'

--------------------------------------------------------------------------------
-- Constructor method

function ScaleMate:__init(...)
  TRACE("ScaleMate:__init(...)",...)

  local args = cLib.unpack_args(...)

  self.dialog = ScaleMate_UI{
    owner = self,
    dialog_title = args.dialog_title,
  }

  self.prefs = renoise.tool().preferences

  renoise.tool().app_new_document_observable:add_notifier(function()
    self:attach_to_song()
  end)

  self:attach_to_song()

end

-------------------------------------------------------------------------------
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

-------------------------------------------------------------------------------
-- Set selected instrument to the provide key
-- @param val (number)

function ScaleMate:set_key(val)
  TRACE("ScaleMate:set_key(val)",val)

  local instr = rns.selected_instrument 
  if not instr then 
   LOG("*** Could not resolve instrument")
  end 

  instr.trigger_options.scale_key = name

end

-------------------------------------------------------------------------------
-- Update pattern (cursor position) with selected scale

function ScaleMate:write_scale()
  TRACE("ScaleMate:write_scale()")
  
  local instr = rns.selected_instrument 
  local track = rns.selected_track 
  local line = rns.selected_line 
  local cmd = xMidiCommand{
      instrument_index = rns.selected_instrument_index,
      message_type = xMidiCommand.TYPE.CONTROLLER_CHANGE,
      number_value = 15,
      amount_value = xScale.get_scale_index_by_name(instr.trigger_options.scale_mode)-1,
  }
  local expand = true -- show panning if hidden
  xLinePattern.set_midi_command(track,line,cmd,expand)

end

-------------------------------------------------------------------------------

function ScaleMate:clear_commands_in_pattern()
  TRACE("ScaleMate:clear_commands_in_pattern()")

  local track = rns.selected_track
  local patt = rns.selected_pattern 
  local ptrack = patt.tracks[rns.selected_track_index]
  local index_from = 1
  local index_to = patt.number_of_lines
  local lines = ptrack:lines_in_range(index_from, index_to)
  for k,line in ipairs(lines) do
    local cmd = xLinePattern.get_midi_command(track,line)
    if cmd then 
      print("found midi command",cmd)
      xLinePattern.clear_midi_command(track,line)
    end 
  end

end

-------------------------------------------------------------------------------

function ScaleMate:attach_to_song()
  TRACE("ScaleMate:attach_to_song()")


  local instr_notifier = function()
    print(">>> instr_notifier")
    self.dialog:update()
    self:attach_to_instrument()
  end

  cObservable.attach(rns.selected_instrument_index_observable,instr_notifier)

  self:attach_to_instrument()

end

-------------------------------------------------------------------------------

function ScaleMate:attach_to_instrument()

  local scale_notifier = function()
    print(">>> scale_notifier")
    self.dialog:update()
  end

  cObservable.attach(rns.selected_instrument.trigger_options.scale_mode_observable,scale_notifier)

end
