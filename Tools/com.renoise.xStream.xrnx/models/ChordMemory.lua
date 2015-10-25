--[[===========================================================================
ChordMemory.lua
===========================================================================]]--

return {
arguments = {
  {
      name = "mode",
      value = 2,
      properties = {
          max = 2,
          min = 1,
          display_as = "switch",
          items = {
              "read",
              "write",
          },
      },
      description = "Set the model operating mode \n'read' = interpret existing pattern data \n'write' = expand existing notes into chords",
  },
  {
      name = "num_keys",
      value = 3,
      properties = {
          max = 6,
          min = 1,
          display_as = "switch",
          items = {
              "2",
              "3",
              "4",
              "5",
              "6",
              "7",
          },
      },
      description = "Number of keys in this chord",
  },
  {
      name = "interval_2",
      value = 3,
      properties = {
          max = 119,
          display_as = "integer",
          min = 0,
      },
      description = "Amount of semitones between 1 & 2",
  },
  {
      name = "interval_3",
      value = 4,
      properties = {
          max = 119,
          display_as = "integer",
          min = 0,
      },
      description = "Amount of semitones between 2 & 3",
  },
  {
      name = "interval_4",
      value = 2,
      properties = {
          max = 119,
          display_as = "integer",
          min = 0,
      },
      description = "Amount of semitones between 3 & 4",
  },
  {
      name = "interval_5",
      value = 0,
      properties = {
          max = 119,
          display_as = "integer",
          min = 0,
      },
      description = "Amount of semitones between 4 & 5",
  },
  {
      name = "interval_6",
      value = 0,
      properties = {
          max = 119,
          min = 0,
          display_as = "integer",
          zero_based = false,
      },
      description = "Amount of semitones between 5 & 6",
  },
  {
      name = "interval_7",
      value = 0,
      properties = {
          max = 119,
          min = 0,
          display_as = "integer",
          zero_based = false,
      },
      description = "Amount of semitones between 6 & 7",
  },
  {
      name = "note_order",
      value = 2,
      properties = {
          max = 3,
          min = 1,
          display_as = "switch",
          items = {
              "low > high",
              "high > low",
          },
      },
      description = "Decide the ordering of notes",
  },
  {
      name = "line_space",
      value = 2,
      properties = {
          max = 8,
          min = 0,
          display_as = "integer",
          zero_based = false,
      },
      description = "Space (in lines) between notes - a.k.a. strumming",
  },
  {
      name = "human_vol",
      value = 0,
      properties = {
          max = 100,
          display_as = "percent",
          min = 0,
      },
      description = "Humanize volume (relative to source note)",
  },
  {
      name = "human_pan",
      value = 0,
      properties = {
          max = 100,
          display_as = "percent",
          min = 0,
      },
      description = "Humanize panning (relative to source note)",
  },
  {
      name = "human_dly",
      value = 0,
      properties = {
          max = 100,
          display_as = "percent",
          min = 0,
      },
      description = "Humanize delay (relative to source note)",
  },
},
presets = {
  {
      num_keys = 2,
      interval_2 = 4,
      interval_4 = 0,
      interval_5 = 0,
      human_pan = 0,
      interval_7 = 0,
      interval_3 = 3,
      human_dly = 0,
      name = "Major",
      interval_6 = 0,
      human_vol = 0,
      mode = 2,
      note_order = 1,
      line_space = 0,
  },
  {
      num_keys = 2,
      interval_2 = 3,
      interval_4 = 0,
      interval_5 = 0,
      human_pan = 0,
      interval_7 = 0,
      interval_3 = 4,
      human_dly = 0,
      name = "Minor",
      interval_6 = 0,
      human_vol = 0,
      mode = 2,
      note_order = 1,
      line_space = 0,
  },
  {
      num_keys = 3,
      interval_2 = 4,
      interval_4 = 3,
      interval_5 = 0,
      human_pan = 0,
      interval_7 = 0,
      interval_3 = 3,
      human_dly = 0,
      name = "Seventh",
      interval_6 = 0,
      human_vol = 0,
      mode = 2,
      note_order = 1,
      line_space = 0,
  },
  {
      num_keys = 4,
      interval_2 = 4,
      interval_4 = 3,
      interval_5 = 4,
      human_pan = 0,
      interval_7 = 0,
      interval_3 = 3,
      human_dly = 0,
      name = "Ninth",
      interval_6 = 0,
      human_vol = 0,
      mode = 2,
      note_order = 1,
      line_space = 0,
  },
  {
      num_keys = 5,
      interval_2 = 4,
      interval_4 = 3,
      interval_5 = 4,
      human_pan = 0,
      interval_7 = 0,
      interval_3 = 3,
      human_dly = 0,
      name = "Eleventh",
      interval_6 = 3,
      human_vol = 0,
      mode = 2,
      note_order = 1,
      line_space = 0,
  },
  {
      num_keys = 3,
      interval_2 = 4,
      interval_4 = 4,
      interval_5 = 0,
      human_pan = 0,
      interval_7 = 0,
      interval_3 = 3,
      human_dly = 0,
      name = "Major7th",
      interval_6 = 0,
      human_vol = 0,
      mode = 2,
      note_order = 1,
      line_space = 0,
  },
  {
      num_keys = 4,
      interval_2 = 4,
      interval_4 = 4,
      interval_5 = 3,
      human_pan = 0,
      interval_7 = 0,
      interval_3 = 3,
      human_dly = 0,
      name = "Major9th",
      interval_6 = 0,
      human_vol = 0,
      mode = 2,
      note_order = 1,
      line_space = 0,
  },
  {
      num_keys = 5,
      interval_2 = 4,
      interval_4 = 4,
      interval_5 = 3,
      human_pan = 0,
      interval_7 = 0,
      interval_3 = 3,
      human_dly = 0,
      name = "Major11th",
      interval_6 = 3,
      human_vol = 0,
      mode = 2,
      note_order = 1,
      line_space = 0,
  },
  {
      num_keys = 4,
      interval_2 = 2,
      interval_4 = 4,
      interval_5 = 3,
      human_pan = 0,
      interval_7 = 0,
      interval_3 = 1,
      human_dly = 0,
      name = "Minor9th",
      interval_6 = 0,
      human_vol = 0,
      mode = 2,
      note_order = 1,
      line_space = 0,
  },
  {
      num_keys = 3,
      interval_2 = 3,
      interval_4 = 2,
      interval_5 = 0,
      human_pan = 0,
      interval_7 = 0,
      interval_3 = 4,
      human_dly = 0,
      name = "Minor6th",
      interval_6 = 0,
      human_vol = 0,
      mode = 2,
      note_order = 1,
      line_space = 0,
  },
  {
      num_keys = 3,
      interval_2 = 3,
      interval_4 = 3,
      interval_5 = 0,
      human_pan = 0,
      interval_7 = 0,
      interval_3 = 4,
      human_dly = 0,
      name = "Minor7th",
      interval_6 = 0,
      human_vol = 0,
      mode = 2,
      note_order = 1,
      line_space = 0,
  },
  {
      num_keys = 3,
      interval_2 = 5,
      interval_4 = 3,
      interval_5 = 0,
      human_pan = 0,
      interval_7 = 0,
      interval_3 = 2,
      human_dly = 0,
      name = "Sustained",
      interval_6 = 0,
      human_vol = 0,
      mode = 2,
      note_order = 1,
      line_space = 0,
  },
  {
      num_keys = 3,
      interval_2 = 3,
      interval_4 = 3,
      interval_5 = 0,
      human_pan = 0,
      interval_7 = 0,
      interval_3 = 3,
      human_dly = 0,
      name = "Diminished",
      interval_6 = 0,
      human_vol = 0,
      mode = 2,
      note_order = 1,
      line_space = 0,
  },
  {
      num_keys = 3,
      interval_2 = 4,
      interval_4 = 2,
      interval_5 = 0,
      human_pan = 0,
      interval_7 = 0,
      interval_3 = 4,
      human_dly = 0,
      name = "Augmented",
      interval_6 = 0,
      human_vol = 0,
      mode = 2,
      note_order = 1,
      line_space = 0,
  },
},
data = {
},
options = {
 color = 0x000000,
},
callback = [[
-------------------------------------------------------------------------------
-- Chord Memory
-- This model has two modes: read and write. When in read mode, any chords 
-- present in the track are applied to the arguments (easily stored as presets)
-- Write mode turns the process around - it will look for a single note in the 
-- first note column, and expand this into a chord
-------------------------------------------------------------------------------
if (args.mode == 1) then 

  -- initialize data
  if not data.recent_col_idx then
    print("initialize data")
    data.notes = {} -- note pitches
    data.lines = {} -- note xinc-value
    data.columns = {} -- note column indices
  end

  local least_vol,most_vol = 0x80,0x00
  local least_pan,most_pan = 0x80,0x00
  local least_dly,most_dly = 0xFF,0x00
  
  print("xinc",xinc)
  
  for col_idx = 1,12 do
    local xcol = xline.note_columns[col_idx]
    if xcol then 
    
      -- determine note-on
    
      --print("col_idx",col_idx)
      if (xcol.note_value < 119) then
      
        -- save the progress through columns (this lets us resume
        -- search at a later line, when looking for strummed chords)
        data.recent_col_idx = col_idx
      
        table.insert(data.notes,xcol.note_value)
        table.insert(data.lines,xinc)
        table.insert(data.columns,col_idx)
        
        --print(">>> columns",rprint(data.columns))
        
        -- volume
        local vol = (xcol.volume_value <= 0x80) 
          and xcol.volume_value or 0x80
        least_vol = math.min(least_vol,vol)
        most_vol = math.max(most_vol,vol)
        
        -- panning
        local pan = (xcol.panning_value <= 0x80) 
          and xcol.panning_value or 0x40
        least_pan = math.min(least_pan,pan)
        most_pan = math.max(most_pan,pan)
        
        -- delay    
        local dly = xcol.delay_value 
        least_dly = math.min(least_dly,dly)
        most_dly = math.max(most_dly,dly)
        
      end
            
    end
  end
  
  -- determine if we are strumming, and if so, spacing/direction...
  local line_spacing = 0
  local going_upwards = false
  if (#data.lines > 1) then
    for k = 2,#data.lines do
      line_spacing = math.max(line_spacing,data.lines[k]-data.lines[k-1])
      going_upwards = (data.notes[k] > data.notes[k-1])
    end
  end
  print("line_spacing",line_spacing)
  
  -- update arguments as information is received...
  
  -- sort notes before determining intervals    
  local sorted = table.copy(data.notes)
  table.sort(sorted) -- sort low -> high
  
  if (#sorted > 1) then
    args.num_keys = #sorted
    for k = 2,#sorted do
      args["interval_"..k] = sorted[k] - sorted[k-1] 
    end
    for k = #sorted+1,7 do -- set others to '0'
      args["interval_"..k] = 0
    end
    args.note_order = (line_spacing > 0) and going_upwards and 2 or 1
    args.line_space = line_spacing
    args.human_vol = ((most_vol-least_vol)/0x80)*100
    args.human_pan = ((most_pan-least_pan)/0x80)*100
    args.human_dly = ((most_dly-least_dly)/0xFF)*100
  end
  
else 

  -- produce output

  local xcol = xline.note_columns[1]
  if (xcol.note_value < 119) then
    data.source_xcol = xcol
    data.source_xinc = xinc
  end
  
  if data.source_xcol then
  
    local get_note_pitch = function(idx)
      local pitch = data.source_xcol.note_value
      if (args.note_order == 2) then
        idx = args.num_keys - (idx) +3
      end
      for k = 1,idx-1 do
        pitch = pitch + args["interval_"..k+1] 
      end
      return pitch
    end

    local humanize = function(val,var,min,max)  
      local range = max-min
      local random = (math.random(0,range) * (var/100))-(var/2)
      val = math.floor(math.min(max,math.max(min,val+random)))
      print(val)
      return val
    end
    
    local output_note = function(col_idx)

      xcol = xline.note_columns[col_idx]
      
      -- note/instrument
      xcol.note_value = get_note_pitch(col_idx)
      xcol.instrument_value = data.source_xcol.instrument_value
      
      -- volume (humanized relative to itself)
      local vol = (data.source_xcol.volume_value <= 0x80) 
        and data.source_xcol.volume_value or 0x80      
      local vol_var = args.human_vol * (vol/0x80)
      vol = humanize(vol,vol_var,0x00,0x80)
      xcol.volume_value = (vol == 0x80) and 255 or vol
      
      -- panning 
      local pan = (data.source_xcol.panning_value <= 0x80) 
        and data.source_xcol.panning_value or 0x40      
      pan = humanize(pan,args.human_pan,0x00,0x80)
      xcol.panning_value = (pan == 0x40) and 255 or pan
      
      -- delay
      local dly = data.source_xcol.delay_value      
      xcol.delay_value = humanize(dly,args.human_dly,0x00,0xFF)
      
    end    
    
    for col_idx = 2,args.num_keys+1 do
      local note_written = false
      if (args.line_space == 0) then
        if (data.source_xinc == xinc) then            
          output_note(col_idx)
          note_written = true
        end
      else -- strum up/down
        local strum_range = (args.num_keys*args.line_space)
        local strum_to = data.source_xinc+strum_range
        local count = 1
        for k = data.source_xinc,strum_to,args.line_space do
          if (count == col_idx) and (xinc == k) then
            output_note(col_idx)
            note_written = true
          end
          count = count + 1
        end
      end
      
      if not note_written then
        xline.note_columns[col_idx] = {}
      end   
         
    end -- iterate through columns

    for col_idx = args.num_keys+2,6 do
      local xcol = xline.note_columns[col_idx]
      if xcol then
        if (xinc == data.source_xinc) then
          xcol.note_string  = "OFF"
        else
          xline.note_columns[col_idx] = {}        
        end
      end
    end
      
  end
  
end










]],
}