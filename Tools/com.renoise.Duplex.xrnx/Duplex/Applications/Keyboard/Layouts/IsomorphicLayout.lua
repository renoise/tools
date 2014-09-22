--[[============================================================================
-- Duplex.Applications.Keyboard.GridLayout.IsomorphicLayout
============================================================================]]--

--[[--
Isomorphic layout for the Keyboard application. 
See also: @{Duplex.Applications.Keyboard.GridLayout} 


### Layout
     _ _ _ _ _ _ _ _
    |_|_|x|_|x|_|_|x|
    |x|_|x|_|x|_|c|x|
    |x|_|x|_|_|x|_|x|
    |x|_|x|_|c|x|_|x|
    |x|_|_|x|_|x|_|x|
    |x|_|c|x|_|x|_|_|
    |_|x|_|x|_|x|_|c|
    |c|x|_|x|_|_|x|_|


The isomorphic layout organizes notes in a way that allows you to play
chords by placing your fingers in a specific pattern. 

### Example patterns
  
     _ _ _ _ _
    |_|_|_|_|_|
    |_|_|x|_|_|  <- Major 
    |x|_|_|_|x|
     _ _ _ _ _
    |_|_|_|_|_|
    |_|_|x|_|_|  <- Minor 
    |x|_|_|x|_|
     _ _ _ _ _
    |x|_|_|_|_|
    |_|_|x|_|_|  <- Seventh 
    |x|_|_|_|x|
     _ _ _ _ _
    |_|_|_|_|_|
    |_|_|_|x|_|  <- Augmented
    |x|_|_|_|x|



Note: this layout works best when the instrument itself does not have
a harmonic scale. When this is the case, neighbouring keys will light 
up as you are playing - to show you that they have an identical pitch


--]]

--==============================================================================


class 'IsomorphicLayout' (GridLayout)


function IsomorphicLayout:__init(...)
  TRACE("IsomorphicLayout:__init()")

  self.flip_octaves = true 
  GridLayout.__init(self,...)

end


--------------------------------------------------------------------------------

--- overridden method
-- @see GridLayout.get_pitches_from_index

function IsomorphicLayout:get_pitches_from_index(idx)
  TRACE("IsomorphicLayout:get_pitches_from_index(idx)",idx)

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

  local pitch = (row*5) + col - 1
  pitch = pitch - 17 + self.kb.curr_octave*12

  return {self.kb:restrict_pitch_to_scale(pitch)}


end


