--[[============================================================================
-- Duplex.GridLayout
============================================================================]]--

--[[--
Custom grid layouts for the Keyboard application.

### About

Override this class with your own implementation to create custom layouts
for the Keyboard class

Any class inside the 'Layouts' subfolder will automatically be included on 
startup, and made available from the Keyboard options panel


See also: @{Duplex.Applications.Keyboard} 


--]]

--==============================================================================


class 'GridLayout'

GridLayout.HIGHLIGHT_NONE = 1
GridLayout.HIGHLIGHT_BASEKEY = 2
GridLayout.HIGHLIGHT_SAMPLE = 3

GridLayout.SHOW_INFO_NONE = 1
GridLayout.SHOW_INFO_NOTE_NAME = 2
GridLayout.SHOW_INFO_MIDI_PITCH = 3

function GridLayout:__init(kb)
  TRACE("GridLayout:__init(kb)",kb)

  assert(kb,"Internal Error. Please report: " ..
    "expected an instance of Keyboard as argument")

  self.kb = kb
  self.highlighting = GridLayout.HIGHLIGHT_BASEKEY
  self.show_note_info = GridLayout.SHOW_INFO_MIDI_PITCH

  self._cached_indexes = nil
  self:cache()

end

--------------------------------------------------------------------------------

--- call this to rebuild the pitch <-> index cache 
-- (for example, when transposing or otherwise changing the layout)

function GridLayout:cache()

  self._cached_indexes = {}
  for idx = 1, (self.kb.grid_w * self.kb.grid_h) do
    self._cached_indexes[idx] = self:get_pitches_from_index(idx)
  end

end

--------------------------------------------------------------------------------

-- if we want to visualize playing notes
-- @return <int>table, 

function GridLayout:get_indexes_from_pitch(pitch)
  TRACE("GridLayout:get_indexes_from_pitch(pitch)",pitch)

  return {}

end

--------------------------------------------------------------------------------

--- when the user is pressing a key, or while updating display 
-- @param idx (int) the control index
-- @return table, matching note pitch(es)

function GridLayout:get_pitches_from_index(idx)
  TRACE("GridLayout:get_pitches_from_index(idx)",idx)

  return {}

end


--------------------------------------------------------------------------------

--- update the display of the controller 

function GridLayout:update_grid()
  TRACE("GridLayout:update_grid()")


  local rns = renoise.song()
  local instr_idx = self.kb:get_instrument_index()
  local instr = rns.instruments[instr_idx]

  local get_pitch = function(idx)
    local pitches = self:get_pitches_from_index(idx)
    if not table.is_empty(pitches) then
      return pitches[1]+12
    end
  end

  --print("*** GridLayout:update_grid - playing voices",#self.kb.voice_mgr.playing)

  for idx = 1,#self.kb._controls.grid do
    local palette = nil
    local ui_obj = self.kb._controls.grid[idx]
    local pitch = get_pitch(idx)
    local inside_range = false
    if not pitch then
      palette = self.kb.palette.key_out_of_bounds
    else
      inside_range = self.kb:inside_note_range(pitch-12)
      if inside_range then
        --print("idx, pitch, active",idx, pitch,self.kb.voice_mgr:note_is_active(instr_idx,pitch))
        if self.kb.voice_mgr:note_is_active(instr_idx,pitch) then
          palette = self.kb.palette.key_pressed
        elseif (self.highlighting == GridLayout.HIGHLIGHT_BASEKEY) and
          (pitch%12 - (self.kb.scale_key-1) == 0)
        then
          palette = self.kb.palette.key_released_content
        else
          palette = self.kb.palette.key_released
        end
        --print("ui_obj",ui_obj)
        if (self.show_note_info == GridLayout.SHOW_INFO_NONE) then
          palette.text = ""
        elseif (self.show_note_info == GridLayout.SHOW_INFO_NOTE_NAME) then
          palette.text = note_pitch_to_value(pitch)
        elseif (self.show_note_info == GridLayout.SHOW_INFO_MIDI_PITCH) then
          palette.text = tostring(pitch+12)
        end
      else
        palette = self.kb.palette.key_out_of_bounds
      end
    end
    ui_obj:set(palette)
  end

  if (self.highlighting == GridLayout.HIGHLIGHT_SAMPLE) then
    -- TODO optimize this so that overlapping notes are not
    -- updated multiple times (only display selected sample?)
    for s_index,s_map in ipairs(instr.sample_mappings[1]) do
      for idx = 1,#self.kb._controls.grid do
        local pitch = get_pitch(idx)
        if (s_map.note_range[1]<=pitch) and
          (s_map.note_range[2]>=pitch) 
        then
          local inside_range = self.kb:inside_note_range(pitch-12)
          if inside_range then
            local palette = nil
            local ui_obj = self.kb._controls.grid[idx]
            local sample_index = rns.selected_sample_index
            if self.kb.voice_mgr:note_is_active(self.kb,instr_idx,pitch) then
              palette = self.kb.palette.key_pressed_content
            elseif (sample_index == s_index) then
              palette = self.kb.palette.key_released_selected
            else
              palette = self.kb.palette.key_released_content
            end
            ui_obj:set(palette)
          end
        end
      end
    end

  end

end


