--[[===========================================================================
Convergence.lua
===========================================================================]]--

return {
arguments = {
  {
      ["locked"] = false,
      ["name"] = "sync_instr",
      ["linked"] = false,
      ["value"] = true,
      ["properties"] = {
          ["display_as"] = "checkbox",
          ["impacts_buffer"] = false,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "sync_track",
      ["linked"] = false,
      ["value"] = true,
      ["properties"] = {
          ["display_as"] = "checkbox",
          ["impacts_buffer"] = false,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "import_song",
      ["linked"] = false,
      ["value"] = true,
      ["properties"] = {
          ["impacts_buffer"] = false,
          ["display_as"] = "checkbox",
          ["fire_on_start"] = false,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "set_instr",
      ["linked"] = false,
      ["value"] = false,
      ["properties"] = {
          ["impacts_buffer"] = false,
          ["display_as"] = "checkbox",
          ["fire_on_start"] = false,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "track_01",
      ["linked"] = false,
      ["value"] = "",
      ["properties"] = {
          ["impacts_buffer"] = false,
          ["display_as"] = "textfield",
          ["fire_on_start"] = false,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "track_02",
      ["linked"] = false,
      ["value"] = "",
      ["properties"] = {
          ["impacts_buffer"] = false,
          ["display_as"] = "textfield",
          ["fire_on_start"] = false,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "track_03",
      ["linked"] = false,
      ["value"] = "",
      ["properties"] = {
          ["impacts_buffer"] = false,
          ["display_as"] = "textfield",
          ["fire_on_start"] = false,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "track_04",
      ["linked"] = false,
      ["value"] = "",
      ["properties"] = {
          ["impacts_buffer"] = false,
          ["display_as"] = "textfield",
          ["fire_on_start"] = false,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "track_05",
      ["linked"] = false,
      ["value"] = "",
      ["properties"] = {
          ["impacts_buffer"] = false,
          ["display_as"] = "textfield",
          ["fire_on_start"] = false,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "track_06",
      ["linked"] = false,
      ["value"] = "",
      ["properties"] = {
          ["impacts_buffer"] = false,
          ["display_as"] = "textfield",
          ["fire_on_start"] = false,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "track_07",
      ["linked"] = false,
      ["value"] = "",
      ["properties"] = {
          ["impacts_buffer"] = false,
          ["display_as"] = "textfield",
          ["fire_on_start"] = false,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "track_08",
      ["linked"] = false,
      ["value"] = "",
      ["properties"] = {
          ["impacts_buffer"] = false,
          ["display_as"] = "textfield",
          ["fire_on_start"] = false,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "track_09",
      ["linked"] = false,
      ["value"] = "",
      ["properties"] = {
          ["impacts_buffer"] = false,
          ["display_as"] = "textfield",
          ["fire_on_start"] = false,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "track_10",
      ["linked"] = false,
      ["value"] = "",
      ["properties"] = {
          ["impacts_buffer"] = false,
          ["display_as"] = "textfield",
          ["fire_on_start"] = false,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "track_11",
      ["linked"] = false,
      ["value"] = "",
      ["properties"] = {
          ["impacts_buffer"] = false,
          ["display_as"] = "textfield",
          ["fire_on_start"] = false,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "track_12",
      ["linked"] = false,
      ["value"] = "",
      ["properties"] = {
          ["impacts_buffer"] = false,
          ["display_as"] = "textfield",
          ["fire_on_start"] = false,
      },
      ["description"] = "",
  },
},
presets = {
  {
      ["track_05"] = "",
      ["track_06"] = "",
      ["sync_instr"] = true,
      ["track_10"] = "",
      ["track_07"] = "",
      ["import_song"] = false,
      ["sync_track"] = true,
      ["set_instr"] = false,
      ["name"] = "Empty",
      ["track_11"] = "",
      ["track_04"] = "",
      ["track_03"] = "",
      ["track_02"] = "",
      ["track_01"] = "",
      ["track_09"] = "",
      ["track_08"] = "",
      ["track_12"] = "",
  },
},
data = {
  ["get_arg_name"] = [[return function(k)
  return ("track_%.2d"):format(k)
end]],
  ["total_count"] = [[-- how many tracks/instrument we have covered
return 12]],
},
events = {
  ["rns.selected_instrument_index_observable"] = [[------------------------------------------------------------------------------
-- When selecting an instrument, try to match the track
------------------------------------------------------------------------------
if not args.sync_instr then return end
if not data.suppress_notifier then
  data.suppress_notifier = true
  for k = 1,data.total_count do
    local arg_name = data.get_arg_name(k)
    local instr_name = rns.selected_instrument.name
    if (instr_name ~= "") then
      for k,v in ipairs(rns.instruments) do
        if (v.name == instr_name) then
          local track = rns.tracks[k]
          if track then
            rns.selected_track_index = k
          end
        end
      end
    end
  end
  data.suppress_notifier = false
end]],
  ["args.import_song"] = [[------------------------------------------------------------------------------
-- respond to argument 'import_song' changes
-- @param val (number/boolean/string)}
------------------------------------------------------------------------------
if args.import_song then
  for k = 1,data.total_count do
    local arg_name = data.get_arg_name(k)
    local instr_name = ""
    local instr = rns.instruments[k]    
    if instr then
      instr_name = instr.name
    end
    args[arg_name] = instr_name
  end
end]],
  ["rns.selected_track_index_observable"] = [[------------------------------------------------------------------------------
-- When arriving in track, try to match the instrument
-- (matching is done with lua string-matching patterns)
------------------------------------------------------------------------------
if not args.sync_track then return end
if not data.suppress_notifier then
  data.suppress_notifier = true  
  for k = 1,data.total_count do
    local arg_name = data.get_arg_name(k)
    local instr_name = args[arg_name]
    if arg_name and (instr_name ~="") then
      for k2 = 1,data.total_count do
        local instr = rns.instruments[k2]
        if instr 
          and string.find(instr.name,instr_name,nil,true) 
          and (k2 == rns.selected_track_index) 
        then
          rns.selected_instrument_index = k2
        end
      end
    end
  end
  data.suppress_notifier = false
end]],
  ["args.set_instr"] = [[------------------------------------------------------------------------------
-- respond to argument 'set_instr' changes
-- @param val (number/boolean/string)}
------------------------------------------------------------------------------
if args.set_instr then
  local offset = 4 -- before the track-args
  if (args.selected_index < 1+offset) then
    renoise.app():show_warning("Please select one of the arguments below,"
      .."\n(click one of the 'track_xx' label to select it)"
      .."\nand the instrument you want to associate with it")
    return
  end
  local arg_name = data.get_arg_name(args.selected_index-offset)
  if args[arg_name] then
    args[arg_name] = rns.selected_instrument.name
  end

      
end]],
},
options = {
 color = 0xA54A24,
},
callback = [[
-------------------------------------------------------------------------------
-- Linking tracks to instruments 
-------------------------------------------------------------------------------

-- How to use:
-- Specify your instrument <-> track bindings in the arguments below,
-- or hit 'import_song' to set all instruments (order of arrival).
-- You can also hit 'set_instr' to set a value for the selected track only

-- Options:
-- 'sync_instr' -> synchronize track when instrument has changed
-- 'sync_track' -> synchronize instrument when track has changed





]],
}