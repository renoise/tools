--==============================================================================

--- Mlrx_note - a struct for logical note-objects in mlrx

class 'Mlrx_note' 


function Mlrx_note:__init()
  TRACE("Mlrx_note:__init()")

  --- (int) the most recently pressed trigger (1 - #Mlrx_track._num_triggers)
  self.index = nil

  --- (Mlrx_pos) quantized & normalized
  self.startpos = nil  

  --- (float) exact time when button was pressed
  self.time_pressed = nil 

  --- (float) same as above, but quantized
  self.time_quant = nil 

  --- (Mlrx_pos) when another note should be written
  self.repeatpos = nil  

  --- (Mlrx_pos) scheduled note-off (only for TRIG_WRITE/TRIG_SHOT)
  self.endpos = nil  

  --- (table) list of song positions that should be ignored when clearing
  -- (contains repeated notes within the writeahead range) 
  self.ignore_lines = table.create()

  --- (int) how many lines the note has travelled since last output 
  self.travelled = nil

  --- (int) how many lines the note has been active (including repeated notes)
  --self.travelled_total = nil

  --- (int) counts how many notes have been written since first pressed
  self.total_notes_written = 0

  --- (Mlrx_pos) last written position (or nil if not written)
  self.written = nil

  --- (bool) true once note has been written, and playback has passed it
  self.active = false 

  --- (Mlrx_pos) position where note-off were written, or nil
  self.offed = false 

end

--------------------------------------------------------------------------------

--- check the ignore list
-- @param line_idx (int)

function Mlrx_note:on_ignore_list(line_idx)

  for i,v in ipairs(self.ignore_lines) do
    if (v.line == line_idx) then
      return true
    end
  end

end

