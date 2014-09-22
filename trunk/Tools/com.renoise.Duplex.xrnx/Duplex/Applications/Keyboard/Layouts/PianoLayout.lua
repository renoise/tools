--[[============================================================================
-- Duplex.Applications.Keyboard.GridLayout.PianoLayout
============================================================================]]--

--[[--
Piano-style layout for the Keyboard application.
See also: @{Duplex.Applications.Keyboard.GridLayout} 


### Layout

         chromatic ►
         _ _ _ _ _ _ _ _
    ▲   |_|#|#|_|#|#|#|_| 
    o   |c|d|e|f|g|a|b|c|
    c   |_|#|#|_|#|#|#|_|
    t   |c|d|e|f|g|a|b|c|
    a   |_|#|#|_|#|#|#|_|
    v   |c|d|e|f|g|a|b|c|
    e   |_|#|#|_|#|#|#|_|
    ▼   |c|d|e|f|g|a|b|c|


This layout attemps to emulate a traditional piano keyboard in a grid. 
As such, this type of layout will require at least two rows of buttons
(one for the black and one for the white keys). 

Note: this layout works best when the instrument itself does not have
a harmonic scale. When this is the case, neighbouring keys will light 
up as you are playing - to show you that they have an identical pitch


--]]

--==============================================================================


class 'PianoLayout' (GridLayout)


function PianoLayout:__init(...)
  TRACE("PianoLayout:__init()")

  self.flip_octaves = false 

  GridLayout.__init(self,...)


end


--------------------------------------------------------------------------------

--- overridden method
-- @see GridLayout.get_pitches_from_index

function PianoLayout:get_pitches_from_index(idx)
  --print("PianoLayout:get_pitches_from_index(idx)",idx)

  if not table.is_empty(self._cached_indexes) and
    self._cached_indexes[idx]
  then
    return self._cached_indexes[idx]
  end

  local unit_count = self.kb.grid_w*self.kb.grid_h
  local row = math.ceil((idx/unit_count) * self.kb.grid_w)
  local col = idx%self.kb.grid_h
  col = (col == 0) and self.kb.grid_h or col
  if self.flip_octaves then
    row = (self.kb.grid_w - row) + 1
  end

  local black_keys = {nil,2,4,nil,7,9,11}
  local white_keys = {1,3,5,6,8,10,12}

  local pitch = (row%2 == 0) and 
    white_keys[(col-1)%7+1] or black_keys[(col-1)%7+1]

  if pitch then
    pitch = pitch -37
    pitch = pitch + math.ceil(col/7)*12
    pitch = pitch + math.ceil(row/2)*12
    pitch = pitch + self.kb.curr_octave*12
    return {self.kb:restrict_pitch_to_scale(pitch)}

  else
    return {}
  end

end
