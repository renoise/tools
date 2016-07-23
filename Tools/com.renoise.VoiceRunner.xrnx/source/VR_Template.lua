--[[============================================================================
VoiceRunner
============================================================================]]--
--[[

Template-editor for VoiceRunner 

]]


class 'VR_Template'

--------------------------------------------------------------------------------

function VR_Template:__init(vb)

  -- renoise.ViewBuilder
  self.vb = vb

  -- table, list of entries
  self.entries = {}

  -- when entries have changed somehow (update UI)
  self.entries_observable = renoise.Document.ObservableBang()

end

--------------------------------------------------------------------------------
-- @param src (string) lua table 

function VR_Template:load(src)

end


--------------------------------------------------------------------------------
-- 

function VR_Template:build_pitch_table()
  print("VR_Template:build_pitch_table()")

  local vb = self.vb

  local vb_view = vb:column{
    spacing = 2,
  }

  local fn_col_tostring = function(val)
    return (val == 0) and "--" or ("%.2d"):format(val)
  end 
  local fn_col_tonumber = function(str)
    return (str == "--") and 0 or tonumber(str)
  end

  local fn_note_tostring = function(val)
    return xNoteColumn.note_value_to_string(math.floor(val))
  end 
  local fn_note_tonumber = function(str)
    return xNoteColumn.note_string_to_value(str)
  end

  --local pitch_map_left = vb:column{}
  --local pitch_map_right = vb:column{}
  local pitch_items = {}

  local create_pitch_row = function(k)
    return vb:row{
      --style = "border",
      vb:valuebox{
        value = 0,
        width = 48,
        min = 0,
        max = 12,
        tostring = fn_col_tostring,
        tonumber = fn_col_tonumber,
      },
      vb:column{
        vb:textfield{        
          text = "Note",
          width = 80,
        },
      },
      --[[
      vb:checkbox{
        value = true,
      },
      ]]
      vb:valuebox{
        --items = pitch_items,
        value = 48+k-1,
        tostring = fn_note_tostring,
        tonumber = fn_note_tonumber,
        width = 60,
      },
      --[[
      vb:popup{
        items = pitch_items,
        width = "100%",
      },
      ]]
    }
  end

  for k = 1,12 do
    vb_view:add_child(create_pitch_row(k))
  end

  return vb_view

end

--------------------------------------------------------------------------------

function VR_Template:build_instrument_table()
  print("VR_Template:build_instrument_table()")

  local vb = self.vb

  local vb_view = vb:column{}
  local instrument_map_items = {
    ["Kick"] = 1,
    ["Snare"] = 2,
    ["Hihat"] = 3,
  }

  local track_items = {
    "Auto",
    "Track 01",
    "Track 02",
    "Track 03",
  }

  for k = 1,4 do
    vb_view:add_child(vb:row{
      --[[
      vb:checkbox{
        value = true,
      },
      ]]
      vb:popup{
        items = table.keys(instrument_map_items),
        width = "100%",
      },
      vb:popup{
        items = track_items,
        width = "100%",
      },
      --[[
      vb:popup{
        items = pitch_items,
        width = "100%",
      },
      ]]
    })
  end

  return vb_view

end

