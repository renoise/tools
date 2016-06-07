--[[===========================================================================
ExpDelay.lua
===========================================================================]]--

return {
arguments = {
  {
      ["locked"] = false,
      ["name"] = "single_column",
      ["linked"] = false,
      ["value"] = false,
      ["properties"] = {},
      ["description"] = "Limit output to a single column",
  },
  {
      ["locked"] = false,
      ["name"] = "fit_columns",
      ["linked"] = false,
      ["value"] = false,
      ["properties"] = {},
      ["description"] = "Only display actually used note-columns",
  },
  {
      ["locked"] = false,
      ["name"] = "reversed",
      ["linked"] = false,
      ["value"] = true,
      ["properties"] = {},
      ["description"] = "Reverse gravity (fast -> slow)",
  },
  {
      ["locked"] = false,
      ["name"] = "gravity",
      ["linked"] = false,
      ["value"] = 1.1,
      ["properties"] = {
          ["min"] = 1,
          ["max"] = 4,
      },
      ["description"] = "Amount of downward force",
  },
  {
      ["locked"] = false,
      ["name"] = "energy",
      ["linked"] = false,
      ["value"] = 11.115217391304,
      ["properties"] = {
          ["min"] = 0.25,
          ["max"] = 32,
      },
      ["description"] = "Initial movement energy",
  },
  {
      ["locked"] = false,
      ["name"] = "resting",
      ["linked"] = false,
      ["value"] = 0.30054347826087,
      ["properties"] = {
          ["min"] = 0.01,
          ["max"] = 1,
      },
      ["description"] = "Decide when movement has come to a rest",
  },
  {
      ["locked"] = false,
      ["name"] = "vol_decay",
      ["linked"] = false,
      ["value"] = 2.1426086956522,
      ["properties"] = {
          ["min"] = 0,
          ["max"] = 20,
      },
      ["description"] = "Amount of volume attenuation",
  },
  {
      ["locked"] = false,
      ["name"] = "vol_reverse",
      ["linked"] = false,
      ["value"] = false,
      ["properties"] = {},
      ["description"] = "Swap low/high volume",
  },
  {
      ["locked"] = false,
      ["name"] = "limit_to",
      ["linked"] = false,
      ["value"] = 263,
      ["properties"] = {
          ["min"] = 1,
          ["display_as"] = "integer",
          ["max"] = 500,
      },
      ["description"] = "Limit the number of bounces",
  },
  {
      ["locked"] = false,
      ["name"] = "instr_mode",
      ["linked"] = false,
      ["value"] = 1,
      ["properties"] = {
          ["min"] = 1,
          ["max"] = 500,
          ["display_as"] = "popup",
          ["items"] = {
              "Use instrument in pattern",
              "Use selected instrument",
          },
      },
      ["description"] = "Which instrument(s) to use",
  },
  {
      ["locked"] = false,
      ["name"] = "instr_idx",
      ["linked"] = false,
      ["value"] = 1,
      ["properties"] = {
          ["min"] = 1,
          ["max"] = 255,
          ["display_as"] = "hex",
          ["zero_based"] = true,
      },
      ["bind"] = "rns.selected_instrument_index_observable",
      ["description"] = "Specify the instrument number",
  },
},
presets = {
  {
      ["instr_idx"] = 1,
      ["limit_to"] = 263,
      ["gravity"] = 1.1,
      ["name"] = "",
      ["momentum"] = 0.86304347826087,
      ["reversed"] = true,
      ["resting"] = 0.30054347826087,
      ["fit_columns"] = false,
      ["energy"] = 11.115217391304,
      ["vol_reverse"] = false,
      ["vol_decay"] = 2.1426086956522,
      ["instr_mode"] = 1,
      ["single_column"] = false,
  },
  {
      ["instr_idx"] = 1,
      ["limit_to"] = 263,
      ["gravity"] = 1.1,
      ["name"] = "",
      ["momentum"] = 0.47252173913043,
      ["reversed"] = true,
      ["resting"] = 0.03324347826087,
      ["fit_columns"] = false,
      ["energy"] = 15.204347826087,
      ["vol_reverse"] = false,
      ["vol_decay"] = 1.7773913043478,
      ["instr_mode"] = 1,
      ["single_column"] = false,
  },
  {
      ["instr_idx"] = 1,
      ["limit_to"] = 263,
      ["gravity"] = 1.1,
      ["reversed"] = false,
      ["name"] = "",
      ["resting"] = 0.09264347826087,
      ["fit_columns"] = false,
      ["vol_decay"] = 4.5652173913043,
      ["vol_reverse"] = false,
      ["energy"] = 4,
      ["instr_mode"] = 1,
      ["single_column"] = false,
  },
  {
      ["instr_idx"] = 1,
      ["limit_to"] = 263,
      ["gravity"] = 1.03,
      ["reversed"] = false,
      ["name"] = "",
      ["resting"] = 0.09264347826087,
      ["fit_columns"] = false,
      ["vol_decay"] = 6.93,
      ["vol_reverse"] = false,
      ["energy"] = 0.25,
      ["instr_mode"] = 1,
      ["single_column"] = false,
  },
  {
      ["instr_idx"] = 1,
      ["limit_to"] = 263,
      ["gravity"] = 1.03,
      ["reversed"] = true,
      ["name"] = "",
      ["resting"] = 0.1929347826087,
      ["fit_columns"] = false,
      ["vol_decay"] = 6.93,
      ["vol_reverse"] = false,
      ["energy"] = 0.25,
      ["instr_mode"] = 1,
      ["single_column"] = false,
  },
  {
      ["instr_idx"] = 1,
      ["limit_to"] = 263,
      ["gravity"] = 1.1,
      ["reversed"] = true,
      ["name"] = "",
      ["resting"] = 0.09264347826087,
      ["fit_columns"] = false,
      ["vol_decay"] = 4.5652173913043,
      ["vol_reverse"] = false,
      ["energy"] = 4,
      ["instr_mode"] = 1,
      ["single_column"] = false,
  },
},
data = {
},
events = {
},
options = {
 color = 0xA54A24,
},
callback = [[
-------------------------------------------------------------------------------
-- Exponential Delay
-- Use this model to create delays that accellerate or decelerate over time,
-- suitable for "bouncing ball" type effects or complex rhythmic patterns. 
-- The model reads any existing notes in the first note column, and applies the
-- output to the second/etc. note columns. 
-- Note: the bounce is recalculated as new notes are encountered 
-------------------------------------------------------------------------------
function create_bounces()
  local energy = args.energy
  local t = {}
  while (energy > args.resting) do
    energy = energy/args.gravity
    table.insert(t,energy)
    if (#t > args.limit_to) then
      break
    end
  end
  local max_cols = 0
  local num_bounces = 0
  local insert_in_table = function(rslt,val)
    local line = math.floor(val)
    if not rslt[line] then
      rslt[line] = {}
    end
    table.insert(rslt[line],val-line)
    max_cols = math.max(max_cols,#rslt[line])
    num_bounces = num_bounces+1
  end
  local total = 0  
  local rslt = {}
  if args.reversed then
    for k,v in ripairs(t) do
      insert_in_table(rslt,total)
      total = total + v
    end
    insert_in_table(rslt,total)
  else
    for k,v in ipairs(t) do
      insert_in_table(rslt,total)
      total = total + v
    end
    insert_in_table(rslt,total)
  end
  return rslt,math.floor(total),max_cols,num_bounces
end
--
-- volume is scaled according to the 'vol_decay' argument
--
function volume_factor(from,to,current)
  local range = to-from
  if args.vol_reverse then
    return 1/math.exp((args.vol_decay/range)*(to-current))
  else
    return 1/math.exp((args.vol_decay/range)*(current-from))
  end
end
--
-- main loop
--
if (xline.note_columns[1].note_value < 119) then
  -- initialize bounce table
  data.current_bounce = 0
  data.trig_pos = xinc
  data.trig_note = xline.note_columns[1]
  data.bounces,data.linespan,data.max_cols,data.num_bounces = create_bounces()
  --rprint(data.bounces)
end

if data.trig_pos then
  -- produce bounce notes
  local num_used_columns = 1
  local bounce = data.bounces[xinc-data.trig_pos]
  if bounce then
    local source_volume = (data.trig_note.volume_value > 0x80) 
      and 0x80 or data.trig_note.volume_value
    for k,v in ipairs(bounce) do
      local instr_idx = (args.instr_mode == 1) and 
        data.trig_note.instrument_value or args.instr_idx
      if args.single_column and (k > 1) then
        break
      end
      local target_volume = math.floor(source_volume * 
        volume_factor(0,data.num_bounces,data.current_bounce))    
      if (target_volume > 0) then
        if (data.current_bounce == 0) then
          -- skip first entry
        else
          xline.note_columns[1+k] = {
            note_value = data.trig_note.note_value,
            instrument_value = instr_idx,
            volume_value = target_volume,
            panning_value = data.trig_note.panning_value,
            delay_value = math.floor(bounce[k]*0xFF),
          }
          num_used_columns = num_used_columns + 1
        end
        data.current_bounce = data.current_bounce + 1
      end
    end
  end
  
  -- fit/clear columns 
  local visible_note_cols
  if args.fit_columns then
    visible_note_cols = args.single_column and 1 or num_used_columns
  else
    visible_note_cols = rns.tracks[track_index].visible_note_columns
  end
  for k = num_used_columns,visible_note_cols do
    xline.note_columns[1+k] = {}
  end
  if args.fit_columns then
    rns.tracks[track_index].visible_note_columns = visible_note_cols
  end

end
]],
}