--[[============================================================================
main.lua

Notes

  Mentioned in API docs, but undefined: 
  - sample_mappings_observable

  Not mentioned in API docs: SampleModulationSet
  - name
  - name_observable

  BUGS
  * Copy modset doesn't detect existing set with same name

  DONE
  * Maintain sample-selection indices (also when swapping entries)
  * Paging mechanism for sample-list  
  * Ability to reconstruct cross-linked effect chains
  * "Choose this action for similar" should only be displayed when > 1 sample
  * Compare mod.set by looking at structure (name & number of devices)
  * Append phrases (with append, prompt for overwrite when no more room is present)
  * Check if (complete set of) FX chains already exist in target (overwrite)

  TODO
  * Copy phrases (merging with existing)
  * Sample list: show mute group
  * Support sliced instruments (recreate/render slices)

  
  UI shortcuts (when dialog is focused)
  ---------------------------------------------------------
  ESC         Close dialog
  ½ (tilde)   Toggle sync (default is source)
  TAB         Toggle source/target sync (only when synced)
  Numpad 0    Open instr. editor  
  INS         TODO Insert new instrument
  CTRL+INS    TODO Duplicate selected instrument
  CTRL/CMD+A  Select all/none assets
  SPACE       TODO Copy assets from source to target

  (all other keys are forwarded to Renoise)



============================================================================]]--

-- Placeholder for the dialog
local dialog = nil

-- Placeholder to expose the ViewBuilder outside the show_dialog() function
local vb = nil

-- Read from the manifest.xml file.
class "RenoiseScriptingTool" (renoise.Document.DocumentNode)
  function RenoiseScriptingTool:__init()    
    renoise.Document.DocumentNode.__init(self) 
    self:add_property("Name", "Untitled Tool")
    self:add_property("Id", "Unknown Id")
  end

local manifest = RenoiseScriptingTool()
local ok,err = manifest:load_from("manifest.xml")
local tool_name = manifest:property("Name").value
local tool_id = manifest:property("Id").value

-- table, selected samples/phrases/etc in list
local selected_samples = table.create()
local selected_phrases = table.create()
local selected_effects = table.create()
local selected_modsets = table.create()

-- int, the current page number 
local sample_paging = nil
local mod_paging = nil
local fx_paging = nil

-- int, the source/target instrument index
-- (note: one-based, while actual renoise instruments are zero-based!)
local source_instr_idx = 1
local target_instr_idx = 1

-- boolean, momentary set flags
local suppress_notifier = false

-- enum, indicate that one of the tabs need to update
local scheduled_update = nil

-- table of recreated chains/sets (used while copying, then cleared)
local recreated_sets = nil

-- remember the preferred target mod.set or fx chain
local user_choice_set = nil

-- int, the currently active tab 
local visible_tab = nil

-- enum, sync with selection
local sync_mode = nil

-- table of Observable parameters
local instr_observables = nil
local sample_observables = nil
local sample_mapping_observables = nil
local phrase_observables = nil
local device_chain_observables = nil
local modulation_set_observables = nil

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------

local TAB_SAMPLES = 1
local TAB_PHRASES = 2
local TAB_EFFECTS = 3
local TAB_MODSETS = 4

local PAGESIZE = 8

local SYNC_SOURCE = 1
local SYNC_TARGET = 2

local INFO_NAME_ONLY = 1
local INFO_NOTE = 2
local INFO_VELOCITY = 3
local INFO_MOD_SET = 4
local INFO_FX_CHAIN = 5
local INFO_BASENOTE = 6
local INFO_LAYER = 7
local INFO_SLICE_NUM = 8

local PROMPT_SET_AUTO = "Use existing set"
local PROMPT_SET_MANUAL = "Manually select"
local PROMPT_SET_CREATE = "Create new set"
local PROMPT_SET_NONE = "Do not assign"

local PROMPT_FX_AUTO = "Use existing FX chains"
local PROMPT_FX_CREATE = "Create new FX chains"

local PROMPT_ADDN_INCLUDE = "Include chains"
local PROMPT_ADDN_REJECT = "Ignore chains"

local KEY_BLACK = {0x51, 0x51, 0x51}
local KEY_WHITE = {0x77, 0x77, 0x77}

local COLOR_SELECTED = {0xc1, 0x34, 0x21}
local COLOR_BLANK = {0x00, 0x00, 0x00}

local PHRASE_BUTTON_W = 18
local LIST_H = 145
local LIST_W = 262

local PARAM_TYPE_TRACK = 1
local PARAM_TYPE_DEVICE = 2
local PARAM_TYPE_PARAM = 3

local PHRASE_MODE_COPY = 1
local PHRASE_MODE_APPEND = 2

--------------------------------------------------------------------------------
-- Utility functions
--------------------------------------------------------------------------------

local function zero_pad(str,count)
  return ("%0"..count.."s"):format(str) 
end

local function LOG(...)
  print (...) 
end

local function shorten_text(str,max_len)
  if (#str > max_len) then
    --str = ("%s%s"):format(str:sub(0,max_len),"…")
    str = ("%s%s"):format(str:sub(0,max_len),"..")
  end
  return str
end

-- obtain lowest value in a table
local get_lowest_value = function(t)
  local lowest = nil
  for _,v in ipairs(t:values()) do
    if not lowest then 
      lowest = v 
    else 
      lowest = math.min(lowest,v) 
    end
  end
  return lowest
end

-- quick'n'dirty table compare, compares values (not keys)
-- @return boolean, true if identical

function table_compare(t1,t2)
  local to_string = function(t)
    local rslt = ""
    for _,v in ipairs(table.values(t))do
      rslt = rslt..tostring(v)..","
    end
    return rslt
  end
  return (to_string(t1)==to_string(t2))
end

local function int_to_hex(val)
  if (val == 0) then
    return "00"
  end
  local b,k,rslt,i,d=16,"0123456789ABCDEF","",0
  while val>0 do
    i=i+1
    val,d=math.floor(val/b),math.mod(val,b)+1
    rslt=string.sub(k,d,d)..rslt
  end
  return zero_pad(rslt,2)
end

local function note_pitch_to_value(val)
  if(val==0) then
    return "C-0"
  else
    local note_array = { "C-","C#","D-","D#","E-","F-","F#","G-","G#","A-","A#","B-" }
    local oct = math.floor(val/12)
    local note = note_array[(val%12)+1]
    return string.format("%s%s",note,oct)
  end
end

-- obtain unique name
local function obtain_name(obj,str)
  local examine_members = function(o,s)
    for k,v in ipairs(o) do
      if (v.name == s) then
        return v
      end
    end
  end
  if (#obj ~= 0) then
    while (examine_members(obj,str)) do
      str = ("#%s"):format(str)
    end
  end
  return str
end

--------------------------------------------------------------------------------
-- Main functions
--------------------------------------------------------------------------------


local function get_instrument_list()

  local rns = renoise.song()
  local rslt = table.create()
  rslt:insert("No instrument selected")
  for k,v in ipairs(rns.instruments) do
    local display_num = zero_pad(tostring(k-1),2)
    local display_name = v.name
    if (display_name == "") then
      display_name = "(Untitled Instrument)"
    end
    rslt:insert(("%s:%s"):format(display_num,display_name))
  end
  return rslt

end

--------------------------------------------------------------------------------

-- update instr lists when needed
local function update_instr_lists()
  LOG("update_instr_lists")

  local ctrl = vb.views.instr_source_popup
  ctrl.items = get_instrument_list()

  local ctrl = vb.views.instr_target_popup
  ctrl.items = get_instrument_list()
  --ctrl.items[#ctrl.items] = "Create new instrument"

end

--------------------------------------------------------------------------------

local function count_selected(list)
  local rslt = 0
  for k,v in ipairs(list) do
    if (v) then
      rslt = rslt + 1
    end
  end
  return rslt
end

--------------------------------------------------------------------------------

local function set_page(num,items)
  LOG("set_page",num,items)

  if (num*PAGESIZE > #items) then
    num = math.floor(#items/PAGESIZE)
  elseif (num*PAGESIZE == #items) then
    num = math.floor(#items/PAGESIZE)-1
  elseif (num*PAGESIZE < 0) then
    num = 0
  end

  -- ensure we are looking at a valid page
  local pages = math.floor((#items-1)/PAGESIZE)
  if (num > pages) then
    num = pages
  end
  return num

end


--------------------------------------------------------------------------------


local function update_sample_count()
  LOG("update_sample_count()")

  local active_count = count_selected(selected_samples)

  local msg = ("Selected %d/%d samples"):
    format(active_count,#selected_samples)
  vb.views.sample_count.text = (active_count ~= 0) and msg or ""
  if (active_count == 0) then
    vb.views.sampler_select_all.value = false
  elseif (active_count == #selected_samples) then
    vb.views.sampler_select_all.value = true
  end


end

--------------------------------------------------------------------------------

local function update_phrase_count()
  LOG("update_phrase_count()")

  local active_count = count_selected(selected_phrases)

  local msg = ("Selected %d/%d phrases"):
    format(active_count,#selected_phrases)
  vb.views.phrase_count.text = (#selected_phrases ~= 0) and msg or "No phrases present"
  if (active_count == 0) then
    vb.views.phrases_select_all.value = false
  elseif (active_count == #selected_phrases) then
    vb.views.phrases_select_all.value = true
  end

end

--------------------------------------------------------------------------------


local function update_effect_count()
  LOG("update_effect_count()")

  local active_count = count_selected(selected_effects)

  local msg = ("Selected %d/%d FX chains"):
    format(active_count,#selected_effects)
  vb.views.effect_count.text = (active_count ~= 0) and msg or ""
  if (active_count == 0) then
    vb.views.effect_select_all.value = false
  elseif (active_count == #selected_effects) then
    vb.views.effect_select_all.value = true
  end

end


--------------------------------------------------------------------------------


local function update_modset_count()
  LOG("update_modset_count()")

  local active_count = count_selected(selected_modsets)

  local msg = ("Selected %d/%d modulation sets"):
    format(active_count,#selected_modsets)
  vb.views.modset_count.text = (active_count ~= 0) and msg or ""
  if (active_count == 0) then
    vb.views.modset_select_all.value = false
  elseif (active_count == #selected_modsets) then
    vb.views.modset_select_all.value = true
  end

end


--------------------------------------------------------------------------------

-- build/update sample display
local function update_sample_tab()
  LOG("update_sample_tab()")

  local rns = renoise.song()
  local display = vb.views.list_sample_info.value

  local source_instr = rns.instruments[source_instr_idx-1]

  -- ensure that sample list is complete
  if source_instr then
    for i = 1,#source_instr.samples do
      if not selected_samples[i] then
        selected_samples[i] = vb.views.sampler_select_all.value
      end
    end
    sample_paging = set_page(sample_paging,selected_samples)
  end

  vb.views.samples_scroller.visible = (#selected_samples > PAGESIZE) and true or false

  local box_parent = vb.views.samples_box_parent
  local box = vb.views.samples_box
  if box then
   
    for i = 1,#selected_samples do
      local cb = vb.views["sample_box_cb_"..i]
      if cb then
        vb.views["sample_box_cb_"..i] = nil
      end
    end

    box_parent:remove_child(box)
    vb.views.samples_box = nil
  end

  -- return if no instrument is selected
  if (source_instr_idx == 1) then

    box = vb:vertical_aligner {
      id = "samples_box",
      mode = "center",
      --style = "group",
      height = 145,
      vb:text {
        width = 242,
        align = "center",
        text = "No source instrument selected"
      }
    }
    box_parent:add_child(box)
    update_sample_count()
    return 
  end

  if (#source_instr.samples == 0) then

    box = vb:vertical_aligner {
      id = "samples_box",
      mode = "center",
      --style = "group",
      height = 145,
      vb:text {
        width = 242,
        align = "center",
        text = "No samples present",
      }
    }

  else

    box = vb:column {
      id = "samples_box",
    }

    -- display name with full width
    local col_one_full_width = false
    if (display == INFO_NAME_ONLY) then
      col_one_full_width = true
    end

    for k,v in ipairs(source_instr.samples) do
      
      -- paging decides which entries to display
      local offset = sample_paging*PAGESIZE

      if (k > offset) and (k <= (offset+PAGESIZE)) then

        local extra_info = ""

        if (display == INFO_NOTE) then
          local txt_from = note_pitch_to_value(v.sample_mapping.note_range[1])
          local txt_to = note_pitch_to_value(v.sample_mapping.note_range[2])
          if (txt_from == "C-0") and (txt_to == "B-9") then
            extra_info = "Full range"
          else
            extra_info = ("%s-%s"):format(txt_from,txt_to)
          end
        elseif (display == INFO_VELOCITY) then
          local txt_from = int_to_hex(v.sample_mapping.velocity_range[1])
          local txt_to = int_to_hex(v.sample_mapping.velocity_range[2])
          if (txt_from == "00") and (txt_to == "7F") then
            extra_info = "Full range"
          else
            extra_info = ("%s-%s"):format(txt_from,txt_to)
          end
        elseif (display == INFO_MOD_SET) then
          local mod_set = source_instr.sample_modulation_sets[v.modulation_set_index]
          if mod_set then
            local idx = zero_pad(tostring(v.modulation_set_index),2)
            extra_info = ("%s:%s"):format(idx,mod_set.name)
          else
            extra_info = "None"
          end
        elseif (display == INFO_FX_CHAIN) then
          local fx_chain = source_instr.sample_device_chains[v.device_chain_index]
          if fx_chain then
            local idx = zero_pad(tostring(v.device_chain_index),2)
            extra_info = ("%s:%s"):format(idx,fx_chain.name)
          else
            extra_info = "None"
          end
        elseif (display == INFO_BASENOTE) then
          local txt_from = note_pitch_to_value(v.sample_mapping.base_note)
          extra_info = txt_from
        elseif (display == INFO_LAYER) then

          local layer = v.sample_mapping.layer
          if (layer == renoise.Instrument.LAYER_NOTE_DISABLED) then
            extra_info = "Disabled"
          elseif (layer == renoise.Instrument.LAYER_NOTE_ON) then
            extra_info = "Note On"
          elseif (layer == renoise.Instrument.LAYER_NOTE_OFF) then
            extra_info = "Note Off"
          end

        elseif (display == INFO_SLICE_NUM) then

          if(v.is_slice_alias) then
            extra_info = ("Slice #%s"):format(int_to_hex(k-1))
          else
            extra_info = "Not sliced"
          end

        end

        if (extra_info ~= "") then
          extra_info = ("| %s"):format(extra_info)
        end

        local display_name = ""
        if (v.name == "") then
          display_name = ("Sample %02s"):format(int_to_hex(k-1))
        else
          local num_chars = col_one_full_width and 35 or 25
          display_name = shorten_text(v.name,num_chars)
        end

        -- append (empty) when sample has no data
        if not v.sample_buffer.has_sample_data then
          display_name = ("%s (empty)"):format(display_name)
        end


        local box_row = vb:row{
          vb:horizontal_aligner{
            width = 242,
            --height = 222,
            mode = "justify",
            vb:row{
              width = col_one_full_width and "100%" or "70%",
              vb:checkbox {
                value = selected_samples[k],
                id = "sample_box_cb_"..k,
                notifier = function(val)
                  selected_samples[k] = val
                  update_sample_count()
                end,
              },
              vb:text {
                text = display_name,
                tooltip = v.name
              },
            },
            vb:text {
              width = col_one_full_width and "0%" or "30%",
              text = shorten_text(extra_info,14),
              tooltip = extra_info,
              align = "left",
            },
          },
        }
        box:add_child(box_row)

      end
    end

  end

  box_parent:add_child(box)
  box.height = LIST_H
  --box.width = LIST_W
  update_sample_count()

end

--------------------------------------------------------------------------------

local function update_phrase_tab()
  LOG("update_phrase_tab()")

  local rns = renoise.song()

  -- create a row for the phrase overview
  -- @param instr, reference to renoise.Instrument object
  -- @param oct, int (the octave)
  local function create_row(instr,oct)

    local vb_row = vb:row {
      width = "100%"
    }
    local vb_button = nil
    local units_spanned = 1
    local exceeded_boundary = false

    local function create_button(phrase,units_spanned,phrase_idx)
      local name_length = math.max(units_spanned-2,0)+(2*(units_spanned-1))
      local is_selected = selected_phrases[phrase_idx]
      local short_name = shorten_text(phrase.name,name_length)
      local vb_button = vb:button{
        width = PHRASE_BUTTON_W*units_spanned,
        color = is_selected and COLOR_SELECTED or COLOR_BLANK,
        text = short_name,
        tooltip = phrase.name,
        notifier = function(val)
          selected_phrases[phrase_idx] = not selected_phrases[phrase_idx]
          update_phrase_tab()
        end
      }
      return vb_button
    end

    for i = 1,12 do

      local pitch = i+(oct*12)-1
      local phrase = nil
      local phrase_idx = nil

      if (instr) then
        for k,v in ipairs(instr.phrases) do
          if (v.mapping.note_range[1] <= pitch) and
            (v.mapping.note_range[2] >= pitch)
          then
            phrase = v
            phrase_idx = k
          end
        end
      end

      if phrase then
        if (phrase.mapping.note_range[2] > pitch) then
          if (i == 12) then
            -- stop phrase at each row boundary
            exceeded_boundary = true
            vb_button = create_button(phrase,units_spanned,phrase_idx)
          else
            -- continuing previous phrase
            units_spanned = units_spanned + 1
          end
        elseif (phrase.mapping.note_range[2] == pitch) then
          -- output phrase 
          vb_button = create_button(phrase,units_spanned,phrase_idx)
          units_spanned = 1
        end
      else
        -- no phrase present 
        vb_button = vb:button{
          width = PHRASE_BUTTON_W,
          color = ((i==2) or (i==4) or (i==7) or (i==9) or (i==11)) and KEY_BLACK or KEY_WHITE
        }
      end


      if (vb_button) then
        vb_row:add_child(vb_button)
        vb_button = nil
      end

    end

    return vb_row

  end

  local source_instr = rns.instruments[source_instr_idx-1]

  -- ensure that phrase list is complete
  if source_instr then
    for i = 1,#source_instr.phrases do
      if (selected_phrases[i]==nil) then
        selected_phrases[i] = vb.views.phrases_select_all.value
      end
    end
  end

  local phrase_rows = vb.views.phrase_rows
  local phrase_rows_parent = vb.views.phrase_rows_parent
  if phrase_rows then
    phrase_rows_parent:remove_child(phrase_rows)
    vb.views.phrase_rows = nil
  end
  phrase_rows = vb:column {
    width = "100%",
    id = "phrase_rows",
  }

  for oct = 0,9 do
    phrase_rows:add_child(create_row(source_instr,oct))
  end

  phrase_rows_parent:add_child(phrase_rows)


  update_phrase_count()

end


--------------------------------------------------------------------------------

local function update_effects_tab()
  LOG("update_effects_tab()")

  local rns = renoise.song()

  local source_instr = rns.instruments[source_instr_idx-1]

  -- ensure that list is complete
  if source_instr then
    for i = 1,#source_instr.sample_device_chains do
      if not selected_effects[i] then
        selected_effects[i] = vb.views.effect_select_all.value
      end
    end
    fx_paging = set_page(fx_paging,selected_effects)
  end

  vb.views.effect_scroller.visible = (#selected_effects > PAGESIZE) and true or false

  local box_parent = vb.views.effect_box_parent
  local box = vb.views.effect_box
  if box then
    
    for i = 1,#selected_effects do
      local cb = vb.views["effect_box_cb_"..i]
      if cb then
        vb.views["effect_box_cb_"..i] = nil
      end
    end

    box_parent:remove_child(box)
    vb.views.effect_box = nil
  end

  -- return if no instrument is selected
  if (source_instr_idx == 1) then

    box = vb:vertical_aligner {
      id = "effect_box",
      mode = "center",
      --style = "group",
      height = LIST_H,
      vb:text {
        width = 242,
        align = "center",
        text = "No source instrument selected"
      }
    }
    box_parent:add_child(box)
    update_effect_count()
    return 
  end



  if (#source_instr.sample_device_chains == 0) then

    box = vb:vertical_aligner {
      id = "effect_box",
      mode = "center",
      --style = "group",
      height = LIST_H,
      vb:text {
        width = 242,
        align = "center",
        text = "No Sample FX Chains",
      }
    }

  else

    box = vb:column {
      id = "effect_box",
    }

    for k,v in ipairs(source_instr.sample_device_chains) do
      
      -- paging decides which entries to display
      local offset = fx_paging*PAGESIZE

      if (k > offset) and (k <= (offset+PAGESIZE)) then

        local display_name = ""
        if (v.name == "") then
          display_name = ("Set %02s"):format(int_to_hex(k-1))
        else
          display_name = shorten_text(v.name,45)
        end

        local box_row = vb:row{
          vb:checkbox {
            value = selected_effects[k],
            id = "effect_box_cb_"..k,
            notifier = function(val)
              selected_effects[k] = val
              update_effect_count()
            end,
          },
          vb:text {
            width = 224,
            text = display_name,
            tooltip = v.name
          },
          --vb:horizontal_aligner{
          --},
        }
        box:add_child(box_row)

      end
    end

  end

  box_parent:add_child(box)
  box.height = LIST_H
  box.width = LIST_W
  update_effect_count()

end

--------------------------------------------------------------------------------

--

local function update_modulation_tab()
  LOG("update_modulation_tab()")

  local rns = renoise.song()

  local source_instr = rns.instruments[source_instr_idx-1]

  -- ensure that list is complete
  if source_instr then
    for i = 1,#source_instr.sample_modulation_sets do
      if not selected_modsets[i] then
        selected_modsets[i] = vb.views.modset_select_all.value
      end
    end
    mod_paging = set_page(mod_paging,selected_modsets)
  end

  vb.views.modset_scroller.visible = (#selected_modsets > PAGESIZE) and true or false

  local box_parent = vb.views.modset_box_parent
  local box = vb.views.modset_box
  if box then
    
    for i = 1,#selected_modsets do
      local cb = vb.views["modset_box_cb_"..i]
      if cb then
        vb.views["modset_box_cb_"..i] = nil
      end
    end

    box_parent:remove_child(box)
    vb.views.modset_box = nil
  end

  -- return if no instrument is selected
  if (source_instr_idx == 1) then

    box = vb:vertical_aligner {
      id = "modset_box",
      mode = "center",
      --style = "group",
      height = LIST_H,
      vb:text {
        width = 242,
        align = "center",
        text = "No source instrument selected"
      }
    }
    box_parent:add_child(box)
    update_modset_count()
    return 
  end



  if (#source_instr.sample_modulation_sets == 0) then

    box = vb:vertical_aligner {
      id = "modset_box",
      mode = "center",
      --style = "group",
      height = LIST_H,
      vb:text {
        width = 242,
        align = "center",
        text = "No modulation sets",
      }
    }

  else

    box = vb:column {
      id = "modset_box",
    }

    for k,v in ipairs(source_instr.sample_modulation_sets) do
      
      -- paging decides which entries to display
      local offset = mod_paging*PAGESIZE

      if (k > offset) and (k <= (offset+PAGESIZE)) then

        local display_name = ""
        if (v.name == "") then
          display_name = ("Set %02s"):format(int_to_hex(k-1))
        else
          display_name = shorten_text(v.name,45)
        end

        local box_row = vb:row{
          vb:checkbox {
            value = selected_modsets[k],
            id = "modset_box_cb_"..k,
            notifier = function(val)
              selected_modsets[k] = val
              update_modset_count()
            end,
          },
          vb:text {
            width = 224,
            text = display_name,
            tooltip = v.name
          },
          --vb:horizontal_aligner{
          --},
        }
        box:add_child(box_row)

      end
    end

  end

  box_parent:add_child(box)
  box.height = LIST_H
  box.width = LIST_W
  update_modset_count()


end

--------------------------------------------------------------------------------

local function update_commit_button()
  LOG("update_commit_button()")

  local ctrl = vb.views.bt_commit
  local ctrl2 = vb.views.bt_focus_editor

  if (source_instr_idx > 1) and (target_instr_idx > 1) 
  then
    ctrl.active = true
    ctrl2.active = true
  else
    ctrl.active = false
    ctrl2.active = false
  end

end

--------------------------------------------------------------------------------

-- highlight/enable 'bring focus to editor' button 

local function update_focus_editor()
  LOG("update_focus_editor()")

  if not vb then
    return
  end

  local rns = renoise.song()
  local sel_instr = rns.selected_instrument
  local ctrl = vb.views.bt_focus_editor
  --local active = false
  local highlight = false
  local middle_frame = renoise.app().window.active_middle_frame
  local w = renoise.ApplicationWindow

  if sel_instr then
    if (middle_frame == w.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EDITOR) or
      (middle_frame == w.MIDDLE_FRAME_INSTRUMENT_SAMPLE_KEYZONES) or
      (middle_frame == w.MIDDLE_FRAME_INSTRUMENT_SAMPLE_MODULATION) or
      (middle_frame == w.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EFFECTS) or
      (middle_frame == w.MIDDLE_FRAME_INSTRUMENT_PLUGIN_EDITOR) or
      (middle_frame == w.MIDDLE_FRAME_INSTRUMENT_MIDI_EDITOR)
    then
      -- we are somewhere in the instrument editor
      if (sel_instr.phrase_editor_visible) then
        highlight = (visible_tab == TAB_PHRASES) and true or false
      elseif
        ((middle_frame == w.MIDDLE_FRAME_INSTRUMENT_SAMPLE_KEYZONES) and (visible_tab == TAB_SAMPLES)) or
        ((middle_frame == w.MIDDLE_FRAME_INSTRUMENT_SAMPLE_MODULATION) and (visible_tab == TAB_MODSETS)) or
        ((middle_frame == w.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EFFECTS) and (visible_tab == TAB_EFFECTS)) 
      then
        highlight = true
      end

    end
  end

  ctrl.color = highlight and COLOR_SELECTED or COLOR_BLANK

end

--------------------------------------------------------------------------------

local function focus_editor()

  local rns = renoise.song()
  local sel_instr = rns.selected_instrument
  local middle_frame = renoise.app().window.active_middle_frame
  local w = renoise.ApplicationWindow
  local bt = vb.views.bt_focus_editor 
  
  --[[
  if (table_compare(bt.color,COLOR_SELECTED)) then
    renoise.app().window.active_middle_frame = 0
    sel_instr.phrase_editor_visible = false
  else
  ]]
    if (visible_tab == TAB_SAMPLES) then
      renoise.app().window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_KEYZONES
    elseif (visible_tab == TAB_PHRASES) then
      renoise.app().window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_KEYZONES
      sel_instr.phrase_editor_visible = true
    elseif (visible_tab == TAB_EFFECTS) then
      renoise.app().window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EFFECTS
    elseif (visible_tab == TAB_MODSETS) then
      renoise.app().window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_MODULATION
    end

  --end

  update_focus_editor()

end

--------------------------------------------------------------------------------

-- show/update the indicated tab
local function show_tab(idx)

  LOG("show_tab()",idx)

  vb.views.tab_samples.visible = (idx == TAB_SAMPLES) and true or false
  vb.views.tab_phrases.visible = (idx == TAB_PHRASES) and true or false
  vb.views.tab_effects.visible = (idx == TAB_EFFECTS) and true or false
  vb.views.tab_modulation.visible = (idx == TAB_MODSETS) and true or false

  if(idx==TAB_SAMPLES) and (visible_tab ~= TAB_SAMPLES) then
    update_sample_tab()
  elseif (idx == TAB_PHRASES) and (visible_tab ~= TAB_PHRASES) then 
    update_phrase_tab()
  elseif (idx == TAB_EFFECTS) and (visible_tab ~= TAB_EFFECTS) then
    update_effects_tab()
  elseif (idx == TAB_MODSETS) and (visible_tab ~= TAB_MODSETS) then
    update_modulation_tab()
  end

  visible_tab = idx
  update_commit_button()
  update_focus_editor()

end

--------------------------------------------------------------------------------

local function show_next_tab()
  local new_tab = visible_tab
  if (visible_tab == TAB_MODSETS) then
    new_tab = TAB_SAMPLES
  else
    new_tab = new_tab + 1
  end
  vb.views.main_switch.value = new_tab
end

--------------------------------------------------------------------------------

local function show_previous_tab()
  local new_tab = visible_tab
  if (visible_tab == TAB_SAMPLES) then
    new_tab = TAB_MODSETS
  else
    new_tab = new_tab - 1
  end
  vb.views.main_switch.value = new_tab
end

--------------------------------------------------------------------------------

-- force update of current tab

local function update_tab()
  local tab_idx = visible_tab
  visible_tab = 0
  show_tab(tab_idx)
end

--------------------------------------------------------------------------------

-- use pcall to remove notifiers (as we have no guarantee that
-- the instrument still exist when this function is invoked)

local function remove_notifiers(observables)
  LOG("remove_notifiers",observables)

  if not observables then
    return
  end
  
  for k,v in ipairs(observables) do
    pcall(function() v[1]:remove_notifier(v[2]) end)
  end

end


--------------------------------------------------------------------------------

local function attach_to_sample(sample)
  LOG("attach_to_sample",sample)

  local obs,fn = nil,nil
  sample_observables = table.create()

  fn = function(param)
    if (visible_tab == TAB_SAMPLES) then
      scheduled_update = TAB_SAMPLES
    end
  end
  obs = sample.name_observable
  obs:add_notifier(fn)
  sample_observables:insert({obs,fn})

  fn = function(param)
    if (visible_tab == TAB_SAMPLES) then
      scheduled_update = TAB_SAMPLES
    end
  end
  obs = sample.modulation_set_index_observable
  obs:add_notifier(fn)
  sample_observables:insert({obs,fn})

  fn = function(param)
    if (visible_tab == TAB_SAMPLES) then
      scheduled_update = TAB_SAMPLES
    end
  end
  obs = sample.device_chain_index_observable
  obs:add_notifier(fn)
  sample_observables:insert({obs,fn})


end

--------------------------------------------------------------------------------

local function attach_to_sample_mapping(sample_mapping)
  LOG("attach_to_sample_mapping",sample_mapping)

  local obs,fn = nil,nil
  sample_mapping_observables = table.create()

  fn = function(param)
    if (visible_tab == TAB_SAMPLES) then
      scheduled_update = TAB_SAMPLES
    end
  end
  obs = sample_mapping.layer_observable
  obs:add_notifier(fn)
  sample_mapping_observables:insert({obs,fn})

  fn = function(param)
    if (visible_tab == TAB_SAMPLES) then
      scheduled_update = TAB_SAMPLES
    end
  end
  obs = sample_mapping.base_note_observable
  obs:add_notifier(fn)
  sample_mapping_observables:insert({obs,fn})


  fn = function(param)
    if (visible_tab == TAB_SAMPLES) then
      scheduled_update = TAB_SAMPLES
    end
  end
  obs = sample_mapping.note_range_observable
  obs:add_notifier(fn)
  sample_mapping_observables:insert({obs,fn})


  fn = function(param)
    LOG("attach_to_sample_mapping: velocity_range_observable fired...",param)
    if (visible_tab == TAB_SAMPLES) then
      scheduled_update = TAB_SAMPLES
    end
  end
  obs = sample_mapping.velocity_range_observable
  obs:add_notifier(fn)
  sample_mapping_observables:insert({obs,fn})


end

--------------------------------------------------------------------------------

local function attach_to_phrase(phrase)
  LOG("attach_to_phrase",phrase)

  local obs,fn = nil,nil
  phrase_observables = table.create()

  fn = function(param)
    if (visible_tab == TAB_PHRASES) then
      scheduled_update = TAB_PHRASES
    end
  end
  obs = phrase.name_observable
  obs:add_notifier(fn)
  phrase_observables:insert({obs,fn})

  fn = function(param)
    if (visible_tab == TAB_PHRASES) then
      scheduled_update = TAB_PHRASES
    end
  end
  obs = phrase.mapping.note_range_observable
  obs:add_notifier(fn)
  phrase_observables:insert({obs,fn})


end


--------------------------------------------------------------------------------

local function attach_to_modulation_set(modulation_set)
  LOG("attach_to_modulation_set",modulation_set)

  local obs,fn = nil,nil
  modulation_set_observables = table.create()

  fn = function(param)
    if (visible_tab == TAB_SAMPLES) then
      scheduled_update = TAB_SAMPLES
    end
    if (visible_tab == TAB_MODSETS) then
      scheduled_update = TAB_MODSETS
    end
  end
  obs = modulation_set.name_observable
  obs:add_notifier(fn)
  modulation_set_observables:insert({obs,fn})


end

--------------------------------------------------------------------------------

local function attach_to_device_chain(device_chain)
  LOG("attach_to_device_chain",device_chain)

  local obs,fn = nil,nil
  device_chain_observables = table.create()

  fn = function(param)
    if (visible_tab == TAB_SAMPLES) then
      scheduled_update = TAB_SAMPLES
    end
    if (visible_tab == TAB_EFFECTS) then
      scheduled_update = TAB_EFFECTS
    end
  end
  obs = device_chain.name_observable
  obs:add_notifier(fn)
  device_chain_observables:insert({obs,fn})


  fn = function(param)
    LOG("attach_to_device_chain: devices_observable fired...",param)
  end
  obs = device_chain.devices_observable
  obs:add_notifier(fn)
  device_chain_observables:insert({obs,fn})


end

--------------------------------------------------------------------------------

-- attach to instrument notifiers (and automatically re-attach when parts are 
-- added/removed/changed)

local function attach_to_instrument(instr)
  LOG("attach_to_instrument",instr)

  local obs,fn = nil
  instr_observables = table.create()

  local function maintain_list(list,param)
    if (param.type == "insert") then
      list:insert(param.index,false)
    elseif (param.type == "remove") then
      list:remove(param.index)
    elseif (param.type == "swap") then
      list[param.index1],list[param.index2] = list[param.index2],list[param.index1] 
    end
    return list
  end

  -- Samples / Sample mappings

  local function attach_to_samples()
    remove_notifiers(sample_observables)
    for k,v in ipairs(instr.samples) do
      attach_to_sample(v)
    end
    remove_notifiers(sample_mapping_observables)
    for k,v in ipairs(instr.sample_mappings[1]) do -- note-on layer
      attach_to_sample_mapping(v) 
    end
    --remove_notifiers(sample_mapping_observables)
    for k,v in ipairs(instr.sample_mappings[2]) do -- note-off layer
      attach_to_sample_mapping(v) 
    end
  end

  fn = function(param)
    maintain_list(selected_samples,param)
    attach_to_samples()
    if (visible_tab == TAB_SAMPLES) then
      scheduled_update = TAB_SAMPLES
    end
  end
  obs = instr.samples_observable
  obs:add_notifier(fn)
  instr_observables:insert({obs,fn})

  attach_to_samples()

  -- Phrases / Phrase Mappings

  local attach_to_phrases = function()
    remove_notifiers(phrase_observables)
    for k,v in ipairs(instr.phrases) do
      attach_to_phrase(v)
    end

  end

  fn = function(param)
    maintain_list(selected_phrases,param)
    attach_to_phrases()
    if (visible_tab == TAB_PHRASES) then
      scheduled_update = TAB_PHRASES
    end
  end
  obs = instr.phrases_observable
  obs:add_notifier(fn)
  instr_observables:insert({obs,fn})

  attach_to_phrases()


  -- modulation sets

  local function attach_to_modulation_sets()
    remove_notifiers(modulation_set_observables)
    for k,v in ipairs(instr.sample_modulation_sets) do 
      attach_to_modulation_set(v) 
    end
  end

  fn = function(param)
    maintain_list(selected_modsets,param)
    attach_to_modulation_sets()
    if (visible_tab == TAB_SAMPLES) then
      scheduled_update = TAB_SAMPLES
    end
    if (visible_tab == TAB_MODSETS) then
      update_modulation_tab()
    end
  end
  obs = instr.sample_modulation_sets_observable
  obs:add_notifier(fn)
  instr_observables:insert({obs,fn})

  attach_to_modulation_sets()


  -- Device Chains

  local function attach_to_device_chains()
    remove_notifiers(device_chain_observables)
    for k,v in ipairs(instr.sample_device_chains) do 
      attach_to_device_chain(v) 
    end
  end

  fn = function(param)
    attach_to_device_chains()
    scheduled_update = visible_tab
  end
  obs = instr.sample_device_chains_observable
  obs:add_notifier(fn)
  instr_observables:insert({obs,fn})

  -- Phrase editor 

  fn = function(param)
    update_focus_editor()
  end
  obs = instr.phrase_editor_visible_observable
  obs:add_notifier(fn)
  instr_observables:insert({obs,fn})


  attach_to_device_chains()

end

--------------------------------------------------------------------------------

local function attach_to_song()
  LOG("attach_to_song")

  renoise.song().instruments_observable:add_notifier(function(param)
    update_instr_lists()
    scheduled_update = visible_tab
  end)

  renoise.song().selected_instrument_index_observable:add_notifier(function(param)
    if not vb then
      return
    end
    update_instr_lists()
    local rns = renoise.song()
    if (sync_mode) then
      local instr_idx = rns.selected_instrument_index
      if (sync_mode == SYNC_SOURCE) then
        local ctrl = vb.views.instr_source_popup
        ctrl.value = instr_idx + 1
      else
        local ctrl = vb.views.instr_target_popup
        ctrl.value = instr_idx + 1
      end
    end
  end)

end

--------------------------------------------------------------------------------

local function detach_from_instrument(instr)
  LOG("detach_from_instrument",instr)

  remove_notifiers(instr_observables)
  remove_notifiers(sample_observables)
  remove_notifiers(sample_mapping_observables)
  remove_notifiers(phrase_observables)
  remove_notifiers(device_chain_observables)
  remove_notifiers(modulation_set_observables)


end

--------------------------------------------------------------------------------

-- called when source instr. is changed
local function switched_source()
  LOG("switched_source()")

  selected_samples = table.create()
  selected_phrases = table.create()
  selected_modsets = table.create()
  selected_effects = table.create()

  local rns = renoise.song()

  local source_instr = rns.instruments[source_instr_idx-1]

  if source_instr then
    detach_from_instrument(source_instr)
  end

  local ctrl = vb.views.instr_source_popup
  source_instr_idx = ctrl.value

  local source_instr = rns.instruments[source_instr_idx-1]
  if source_instr then
    attach_to_instrument(source_instr)
    if (sync_mode == SYNC_SOURCE) then
      rns.selected_instrument_index = source_instr_idx - 1
    end
  end

  sample_paging = 0
  mod_paging = 0
  fx_paging = 0

  update_tab()

end

--------------------------------------------------------------------------------

-- called when target instr. is changed
local function switched_target()
  LOG("switched_target()")

  local rns = renoise.song()
  local ctrl = vb.views.instr_target_popup

  target_instr_idx = ctrl.value

  local target_instr = rns.instruments[target_instr_idx-1]
  if target_instr then
    if (sync_mode == SYNC_TARGET) then
      rns.selected_instrument_index = target_instr_idx - 1
    end
  end

  update_tab()


end


--------------------------------------------------------------------------------

local function set_sample_page(num)
  LOG("set_sample_page()",num)
  
  sample_paging = set_page(num,selected_samples)
  update_sample_tab()

end

--------------------------------------------------------------------------------

local function set_modulation_page(val)
  LOG("set_modulation_page()",val)
  
  mod_paging = set_page(val,selected_modsets)
  update_modulation_tab()

end

--------------------------------------------------------------------------------

-- check if similar FX chains exist (match using name/number of devices)
-- @param chain_indices (table) list of source chain indices
-- @return table (index = source, value = target), or nil if not matched

local function obtain_matching_fx(from_instr,to_instr,chain_indices)
  LOG("obtain_matching_fx",from_instr,to_instr,chain_indices)

  local matched = table.create()

  for k,v in ipairs(from_instr.sample_device_chains) do
    if (table.find(chain_indices,k)) then
      for k2,v2 in ipairs(to_instr.sample_device_chains) do
        if (v.name == v2.name) then
          -- chains bear the same name, check device layout
          local identical_devices = true
          if (#v.devices == #v2.devices) then
            for k3,v3 in ipairs(v.devices) do
              if (v3.name ~= v2.devices[k3].name) then
                identical_devices = false
                break
              end
            end
          else
            identical_devices = false
            break
          end
          if identical_devices then
            matched[k] = k2
          end
        end
      end
    end
  end

  -- check if the total number of matched chains has
  -- the same length as the chain_indices
  if (matched:count() == chain_indices:count()) then
    return matched
  else
    return nil
  end

end


--------------------------------------------------------------------------------

-- check if similar mod. set exist (match using name/number of devices)
-- @return int, index of matching mod. set

local function obtain_matching_modset(to_instr,source_set)

  local matched_set = nil
  for k,v in ipairs(to_instr.sample_modulation_sets) do
    if (source_set.name == v.name) then
      if (source_set.devices == #v.devices) then
        matched_set = k
        break
      end
    end
  end
  return matched_set
end


--------------------------------------------------------------------------------

-- copy fx chains belonging to the sample onto the target instr.
-- @param from_instr (renoise.Instrument)
-- @param to_instr (renoise.Instrument)
-- @param chain_indices (int), the device chains we want to include (value = index)
-- @param sample_indices (bool), [optional] the samples which should be relinked (index = source, value = target)

local function copy_effect_chains(from_instr,chain_indices,to_instr,sample_indices)
  LOG("copy_effect_chains",from_instr,chain_indices,to_instr,sample_indices)

  local source_chains = from_instr.sample_device_chains

  -- table of recreated chain-indices (index = source chain, value = target chain)
  local target_chains = {}

  -- table of routings (chain->device->parameter[.track/.effect/.parameter])
  local routings = {}

  local meta_devices = {"*Hydra","*Key Tracker","*LFO","*Meta Mixer","*Signal Follower","*Velocity Tracker","*XY Pad","#Send","#Multiband Send"}

  -- table of additional chains/send device (index = chain index)
  local addn_chains = {}

  -- int, the index at which we will insert chains in target instr.
  local insert_from_idx = nil

  -- int, the lowest chain index for the merge operation
  local lowest_chain_idx = get_lowest_value(chain_indices)

  -- step #1: gather information about routings...
  for k,v in ipairs(source_chains) do
    if not routings[k] then
      routings[k] = {}
    end
    for k2,v2 in ipairs(v.devices) do
      if not routings[k][k2] then
        routings[k][k2] = {}
      end
      if table.find(meta_devices,v2.name) then
        for k3,v3 in ipairs(v2.parameters) do
          if not routings[k][k2][k3] then
            routings[k][k2][k3] = {}
          end
          if (v3.name:match("Out%d Track")) or
            (v3.name:match("Receiver %d")) or
            (v3.name == "Dest. Track") or
            (v3.name == "Receiver")          
          then
            routings[k][k2][k3].track = v3.value 
            -- check if a send device refer to another chain
            -- which isn't included in 'chain_indices'
            local extra_chain
            if v3.name:find("Receiver") then
              local chain_idx = v3.value+1
              if not (table.find(chain_indices,chain_idx)) and 
                (chain_idx > lowest_chain_idx) -- chain is *below* the current
              then
                addn_chains[chain_idx] = true
              end
            end

          elseif (v3.name:match("Out%d Effect")) or
            (v3.name == "Dest. Effect") 
          then
            routings[k][k2][k3].effect = v3.value
          elseif (v3.name:match("Out%d Parameter")) or
            (v3.name == "Dest. Parameter") 
          then
            routings[k][k2][k3].parameter = v3.value
          end

        end
      end
    end
  end

  if (table.count(addn_chains) > 0) then
    local prompt_msg =  "One or more FX chains contain send devices that are"
                      .."\npointing to another chain. Include these chains?"
                      .."\n"
                      .."\n%s"
    local str_names = ""
    for k,v in pairs(addn_chains) do
      local addn_chain = from_instr.sample_device_chains[k]
      if addn_chain then
        str_names = ("%s+ %s\n"):format(str_names,addn_chain.name)
      end
    end
    local prompt_vb = vb:column{
      margin = 5,
      vb:text{
        text = prompt_msg:format(str_names)
      },
    }
    local options = {PROMPT_ADDN_INCLUDE,PROMPT_ADDN_REJECT}
    local choice = renoise.app():show_custom_prompt(tool_name,prompt_vb,options)
    if (choice == PROMPT_ADDN_INCLUDE) then
      for k,v in pairs(addn_chains) do
        chain_indices:insert(k)
      end
    end

  end

  -- before copying, check if the entire set of fx chains already
  -- exist in the target instrument, and offer to 'use existing'

  local use_existing = false
  local matched_chains = obtain_matching_fx(from_instr,to_instr,chain_indices)
  if matched_chains then
    local prompt_msg = "A matching set of FX chains already exist in the target instrument"
      .."\n"
      .."\nChoose the action to perform:"
    local prompt_vb = vb:column{
      margin = 5,
      vb:text{
        text = prompt_msg
      },
    }
    local options = {PROMPT_FX_AUTO,PROMPT_FX_CREATE}
    local choice = renoise.app():show_custom_prompt(tool_name,prompt_vb,options)
    if (choice == PROMPT_FX_AUTO) then
      use_existing = true
    end

  end

  if use_existing then
    target_chains = matched_chains
  else

    -- step #2: copy the chains
    for k,v in ipairs(source_chains) do

      local chain_count = #to_instr.sample_device_chains+1
      routings[k].target_index = chain_count

      if (table.find(chain_indices,k)) then

        local chain_name = obtain_name(to_instr.sample_device_chains,v.name)
        local target_chain = to_instr:insert_sample_device_chain_at(chain_count)
        target_chain.name = chain_name
        target_chains[k] = chain_count

        if not insert_from_idx then
          insert_from_idx = chain_count
        end
        
        for k2,v2 in ipairs(v.devices) do
          local target_device = nil
          if (v2.name ~= "InstrumentVolPan") then
            local device_count = #target_chain.devices+1
            target_device = target_chain:insert_device_at(v2.device_path,device_count)
            if (v2.display_name ~= v2.name) then -- custom name
              target_device.display_name = v2.display_name
            end
          else
            target_device = target_chain.devices[1]
          end
          target_device.active_preset_data = v2.active_preset_data
        end

      else
        
        -- when skipping a chain, maintain the routing table
        for i = 1, #routings do
          for k2,v2 in ipairs(routings[i]) do
            for k3,v3 in ipairs(v2) do
              if v3.track then

                local nullify = false
                -- decrease by one if target chain is higher 
                -- than the chain we just skipped 
                if (v3.track+1 == k) then
                  nullify = true
                elseif (v3.track+1 > k) then
                  v3.track = v3.track - 1
                end
                if nullify then
                  -- cancel this routing - don't forget to set other 
                  -- meta-routing values to -1 as well (or else 
                  -- the default settings will be applied)
                  v3.track = -1
                  if (v2[k3+1]) then
                    v2[k3+1].effect = -1
                  end
                end

              end
            end
          end
        end

      end
      
    end

    -- step #3: recreate routings...
    for k,v in ipairs(routings) do
      local target_chain = to_instr.sample_device_chains[v.target_index] 
      if (table.find(chain_indices,k)) then
        for k2,v2 in ipairs(v) do
          local target_device = target_chain.devices[k2]
          if target_device then
            for k3,v3 in ipairs(v2) do
              local target_param = target_device.parameters[k3]
              if v3.track then
                local target_chain_idx = v3.track
                if (target_chain_idx == -1) then -- 'current chain' 
                  target_param.value = -1
                else
                  local chain_offset = v.target_index - insert_from_idx
                  local chain_idx = target_chain_idx + v.target_index - chain_offset
                  if to_instr.sample_device_chains[chain_idx] then
                    target_param.value = chain_idx-1
                  else
                    LOG("*** could not link to this chain",chain_idx)
                  end
                end   
              elseif v3.effect then
                target_param.value = v3.effect
              elseif v3.parameter then
                target_param.value = v3.parameter     
              end
            end
          end
        end
      end
    end

  end


  -- step #4: relink samples (optional)

  if sample_indices then
    for k,v in pairs(sample_indices) do
      local from_sample = from_instr.samples[k]
      local to_sample = to_instr.samples[v]
      local to_chain_idx = target_chains[from_sample.device_chain_index]
      to_sample.device_chain_index = to_chain_idx
    end
  end

end

--------------------------------------------------------------------------------

-- copy the mod. set belonging to the sample onto the target instr.
-- (if sample is not specified, fewer options are exposed to the user)
-- @param from_instr, reference to renoise.Instrument 
-- @param source_set_idx, int
-- @param to_instr, reference to renoise.Instrument 
-- @param from_sample, (optional) reference to renoise.Sample
-- @return int, the resulting mod.set index 
local function copy_modulation_set(from_instr,source_set_idx,to_instr,from_sample)
  LOG("copy_modulation_set",from_instr,source_set_idx,to_instr,from_sample)

  if not source_set_idx then 
    source_set_idx = from_sample.modulation_set_index
  end

  local source_set = from_instr.sample_modulation_sets[source_set_idx]
  if not source_set then
    return 0
  end

  -- the destination mod.set 
  local assign_to_idx = user_choice_set
  
  if not assign_to_idx then
    assign_to_idx = obtain_matching_modset(to_instr,source_set)
  end

  local target_set = nil
  local create_new_set = (user_choice_set == -1) or false
  local remember_choice = false
  local str_name = source_set.name

  -- check if we have just recreated the set as part of the ongoing merge
  -- (this will suppress the user prompt for the first run)
  if (recreated_sets[assign_to_idx]) then
    user_choice_set = assign_to_idx
  end


  if not user_choice_set and not assign_to_idx then

    create_new_set = true

  elseif not user_choice_set then

    -- ask user which action to perform
    local multiple_items = count_selected(selected_modsets) > 1
    local prompt_msg = nil
    if from_sample then
      prompt_msg = ("The sample '%s' is using a modulation set ('%s')"
      .."\nwhich already seems to exist in the target instrument"
      .."\n"
      .."\nChoose the action to perform:"):
      format(from_sample.name,source_set.name)
    else
      prompt_msg = ("The modulation set ('%s') already exists in the target instrument"
      .."\n"
      .."\nChoose the action to perform:"):
      format(source_set.name)
    end

    local prompt_vb = vb:column{
      margin = 5,
      vb:text{
        text = prompt_msg
      },
      vb:row{
        visible = multiple_items,
        vb:checkbox{
          value = false,
          notifier = function(val)
            remember_choice = val
          end
        },
        vb:text{
          text = "Choose this action for all similar prompts"
        }
      }
    }
    local options = nil
    if from_sample then
      options = {PROMPT_SET_AUTO,PROMPT_SET_MANUAL,PROMPT_SET_CREATE,PROMPT_SET_NONE}
    else
      options = {PROMPT_SET_AUTO,PROMPT_SET_CREATE}
    end
    local choice = renoise.app():show_custom_prompt(tool_name,prompt_vb,options)

    if (choice == PROMPT_SET_AUTO) then

    elseif (choice == PROMPT_SET_CREATE) then

      create_new_set = true
      assign_to_idx = -1

      if from_sample then


        -- display name prompt
        local prompt_vb = vb:column{
          margin = 5,
          vb:text{
            text = "Please provide a name for the new modulation set"
          },
          vb:textfield{
            id = "mod_prompt_name",
            width = "100%",
            text = str_name,
            notifier = function()
              local ctrl = vb.views.mod_prompt_name
              str_name = ctrl.value
            end,

          },
        }
        local options = {"OK"}
        local choice = renoise.app():show_custom_prompt(tool_name,prompt_vb,options)
        
        vb.views.mod_prompt_name = nil
        prompt_vb = nil

      end

    elseif (choice == PROMPT_SET_MANUAL) then

      assign_to_idx = 0

      -- display chain selector
      local to_instr_sets = {"None"}

      for k,v in ipairs(to_instr.sample_modulation_sets) do
        to_instr_sets[k+1] = v.name
      end

      local tmp_str = ("Assign '%s' to this modulation set"):format(str_name)
      
      local prompt_vb = vb:column{
        margin = 5,
        vb:text{
          text = tmp_str
        },
        vb:row{
          vb:chooser{
            value = 1,
            items = to_instr_sets,
            notifier = function(val)
              assign_to_idx = val-1
            end
          },
        }
      }
      local options = {"OK"}
      local choice = renoise.app():show_custom_prompt(tool_name,prompt_vb,options)


    elseif (choice == PROMPT_SET_NONE) then
      assign_to_idx = 0
    end


  end


  if remember_choice then

    user_choice_set = assign_to_idx
  end

  if create_new_set then

    local str_name_target = obtain_name(to_instr.sample_modulation_sets,str_name)

    assign_to_idx = #to_instr.sample_modulation_sets+1
    target_set = to_instr:insert_sample_modulation_set_at(assign_to_idx)
    target_set:copy_from(source_set)
    target_set.name = str_name_target

    recreated_sets[assign_to_idx] = true

  end


  return assign_to_idx

end

--------------------------------------------------------------------------------

-- run prior to any copy/merge operation on a source & target
-- @return boolean (true when both source and target exist)

local function sanity_check()
  LOG("copy_samples")

  local rns = renoise.song()
  local source_instr = rns.instruments[source_instr_idx-1]
  local target_instr = rns.instruments[target_instr_idx-1]

  if not source_instr then
    renoise.app():show_warning("Oops, the source instrument does not exist")
    return false
  end

  if not target_instr then
    renoise.app():show_warning("Oops, the target instrument does not exist")
    return false
  end

  return true

end

--------------------------------------------------------------------------------

local function copy_samples()
  LOG("copy_samples")

  if not sanity_check() then
    return
  end

  local rns = renoise.song()
  local source_instr = rns.instruments[source_instr_idx-1]
  local target_instr = rns.instruments[target_instr_idx-1]

  local included_indices = table.create()
  for i=1,#selected_samples do
    if selected_samples[i] then
      included_indices:insert(i)
    end
  end

  if (table.count(included_indices) == 0) then
    renoise.app():show_warning("No samples have been selected")
    return 
  end

  -- collect indices of created content
  recreated_sets = table.create()
  local sample_indices = table.create()
  local chain_indices = table.create()

  user_choice_set = nil

  for _,v in ipairs(included_indices) do
    local source_sample = source_instr.samples[v]

    -- create samples & collect the indices
    local target_sample_idx = #target_instr.samples+1
    local target_sample = target_instr:insert_sample_at(target_sample_idx)
    target_sample:copy_from(source_sample)

    sample_indices[v] = target_sample_idx

    -- process mod. sets one by one
    local recreate_mod = vb.views.sample_recreate_modulation.value
    local target_set_idx = nil
    if recreate_mod then
      target_set_idx = copy_modulation_set(source_instr,nil,target_instr,source_sample)
      target_sample.modulation_set_index = target_set_idx or 0
    end

    chain_indices:insert(source_sample.device_chain_index)

  end

  recreated_sets = nil

  -- copy effects once we know the sample indices
  local recreate_fx = vb.views.sample_recreate_effects.value
  if recreate_fx then
    copy_effect_chains(source_instr,chain_indices,target_instr,sample_indices)
  end

end

--------------------------------------------------------------------------------

local function copy_phrases()
  LOG("copy_phrases")

  if not sanity_check() then
    return
  end

  local rns = renoise.song()
  local source_instr = rns.instruments[source_instr_idx-1]
  local target_instr = rns.instruments[target_instr_idx-1]

  --print("selected_phrases")
  --rprint(selected_phrases)

  local included_indices = table.create()
  for i=1,#selected_phrases do
    if selected_phrases[i] then
      included_indices:insert(i)
    end
  end
  if (table.count(included_indices) == 0) then
    renoise.app():show_warning("No phrases have been selected")
    return 
  end

  local ctrl = vb.views.phrase_mode_select
  if (ctrl.value == PHRASE_MODE_COPY) then

    -- TODO copy phrases, overwriting any existing ones
    --[[

    for k,v in ipairs(included_indices) do

      local from_phrase = source_instr.phrases[k]
      print("from_phrase",from_phrase.name)

      for k2,v2 in ipairs(target_instr.phrases) do
        
        print("target phrase",v2.name)

        -- check if overlapping with source phrase
        local from_rng = from_phrase.mapping.note_range
        local to_rng = v2.mapping.note_range

        if (from_rng[1] >= to_rng[1]) and
          (from_rng[2] <= to_rng[1])
        then
          -- target phrase completely covered by source
          print("target phrase completely covered by source")
          rprint(to_rng)
        elseif (from_rng[1] >= to_rng[1]) or
          (from_rng[2] <= to_rng[1])
        then
          -- target phrase partially covered by source
          print("target phrase partially covered by source")
        end

      end

    end
    ]]

  elseif (ctrl.value == PHRASE_MODE_APPEND) then

    -- append to existing phrases
    local insert_from = -1
    for k,v in ipairs(target_instr.phrases) do
      insert_from = math.max(v.mapping.note_range[2],insert_from)
    end
    --print("insert_from",insert_from)

    for k,v in ipairs(included_indices) do

      local from_phrase = source_instr.phrases[v]
      --print("from_phrase",from_phrase.name)
      local from_phrase_extent = from_phrase.mapping.note_range[2] - from_phrase.mapping.note_range[1]
      --print("from_phrase_extent",from_phrase_extent)
      local to_phrase_idx = #target_instr.phrases+1
      local to_phrase_name = obtain_name(target_instr.phrases,from_phrase.name)
      if not target_instr:can_insert_phrase_at(to_phrase_idx) then
        local err_msg = "Could not insert phrase at index %s,"
          .."\nno more room left within instrument (you can"
          .."\ndelete some phrases to create additional space)"
        renoise.app():show_error(err_msg:format(to_phrase_idx)) 
        break
      end
      local to_phrase = target_instr:insert_phrase_at(to_phrase_idx)
      to_phrase:copy_from(from_phrase)
      local base_offset = from_phrase.mapping.base_note - from_phrase.mapping.note_range[1]
      local base_note = insert_from + base_offset + 1
      if (base_note > 119) then
        local warn_msg = "The basenote of the phrase '%s' is too high,"
          .."\nwill be set to the maximum allowed pitch (119)"
        renoise.app():show_warning(warn_msg:format(to_phrase_name)) 
      end
      to_phrase.mapping.base_note = math.min(118,base_note)
      to_phrase.name = to_phrase_name

      -- adjust note range (max pitch is 119)
      local end_note = insert_from + from_phrase_extent+1
      local note_range = {insert_from+1, math.min(119,end_note)}
      to_phrase.mapping.note_range = note_range
      insert_from = to_phrase.mapping.note_range[2]

      if (end_note > 119) then
        local warn_msg = "The last phrase was resized to fit within instrument"
        renoise.app():show_warning(warn_msg) 
      end

      --print("insert_from",insert_from)

    end


  end

end

--------------------------------------------------------------------------------

local function copy_effects()
  LOG("copy_effects")

  if not sanity_check() then
    return
  end

  local rns = renoise.song()
  local source_instr = rns.instruments[source_instr_idx-1]
  local target_instr = rns.instruments[target_instr_idx-1]

  local included_indices = table.create()
  for i=1,#selected_effects do
    if selected_effects[i] then
      included_indices:insert(i)
    end
  end
  if (table.count(included_indices) == 0) then
    renoise.app():show_warning("No FX chains have been selected")
    return 
  end

  copy_effect_chains(source_instr,included_indices,target_instr)


end

--------------------------------------------------------------------------------

local function copy_modulation()
  LOG("copy_modulation")

  if not sanity_check() then
    return
  end

  local rns = renoise.song()
  local source_instr = rns.instruments[source_instr_idx-1]
  local target_instr = rns.instruments[target_instr_idx-1]

  local included_indices = table.create()
  for i=1,#selected_modsets do
    if selected_modsets[i] then
      included_indices:insert(i)
    end
  end
  if (table.count(included_indices) == 0) then
    renoise.app():show_warning("No modulation sets have been selected")
    return 
  end

  recreated_sets = {}
  user_choice_set = nil
  for _,v in ipairs(included_indices) do
    copy_modulation_set(source_instr,v,target_instr)
  end

  recreated_sets = nil

end

--------------------------------------------------------------------------------

-- copy assets for the corresponding tab

local function copy_assets()

  if (visible_tab == TAB_SAMPLES) then
    copy_samples()
  elseif (visible_tab == TAB_PHRASES) then
    copy_phrases()
  elseif (visible_tab == TAB_EFFECTS) then
    copy_effects()
  elseif (visible_tab == TAB_MODSETS) then
    copy_modulation()
  end

end

--------------------------------------------------------------------------------

-- following a click on the "select all" checkbox

local function select_all(val)
  LOG("select_all()")

  if (visible_tab == TAB_SAMPLES) then
    for i = 1,#selected_samples do
      selected_samples[i] = val
    end
    scheduled_update = TAB_SAMPLES

  elseif (visible_tab == TAB_PHRASES) then
    for i = 1,#selected_phrases do
      selected_phrases[i] = val
    end
    scheduled_update = TAB_PHRASES

  elseif (visible_tab == TAB_EFFECTS) then
    for i = 1,#selected_effects do
      selected_effects[i] = val
    end
    scheduled_update = TAB_EFFECTS

  elseif (visible_tab == TAB_MODSETS) then
    for i = 1,#selected_modsets do
      selected_modsets[i] = val
    end
    scheduled_update = TAB_MODSETS

  end

end

--------------------------------------------------------------------------------

-- get the checkbox component for the corresponding tab

local function get_all_checkbox()
  LOG("get_all_checkbox()")

  if (visible_tab == TAB_SAMPLES) then
    return vb.views.sampler_select_all
  elseif (visible_tab == TAB_PHRASES) then
    return vb.views.phrases_select_all
  elseif (visible_tab == TAB_EFFECTS) then
    return vb.views.effect_select_all
  elseif (visible_tab == TAB_MODSETS) then
    return vb.views.modset_select_all
  end

end


--------------------------------------------------------------------------------

-- if the currently selected item in the list isn't
-- "No instrument", change the active instrument in 
-- renoise to match the user selection

local function sync_with_selection(mode)
  LOG("*** sync_with_selection",mode)

  vb.views.bt_sync_source.color = COLOR_BLANK
  vb.views.bt_sync_target.color = COLOR_BLANK

  local rns = renoise.song()
  local ctrl = nil
  local instr_idx = rns.selected_instrument_index

  if sync_mode and (sync_mode == mode) then
    sync_mode = nil
    return
  elseif (mode == SYNC_SOURCE) then
    vb.views.bt_sync_source.color = COLOR_SELECTED
    sync_mode = mode
    ctrl = vb.views.instr_source_popup
  elseif (mode == SYNC_TARGET) then
    vb.views.bt_sync_target.color = COLOR_SELECTED
    sync_mode = mode
    ctrl = vb.views.instr_target_popup
  else
    sync_mode = nil
    return
  end

  -- sync selected instrument in renoise?
  if (ctrl.value >1) then
    if rns.instruments[ctrl.value-1] then
      rns.selected_instrument_index = ctrl.value-1
      update_focus_editor()
    end
  else
    ctrl.value = instr_idx + 1
  end

end



--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

local function show_dialog()

  local rns = renoise.song()

  -- if the dialog is already opened, it will be focused.
  if dialog and dialog.visible then
    dialog:show()
    return
  end
  
  vb = renoise.ViewBuilder()


  -- built-in keyhandler
  local function keyhandler(dialog, key)

    LOG("keyhandler",dialog, key)
    rprint(key)

    if key.repeated and (key.repeated == true) then
      -- repeated
    else
      if (key.modifiers == "") then
        -- non-repeated, non-modified
        if (key.name == "ins") then -- insert new instrument
          return false

        elseif (key.name == "numpad 0") then
          focus_editor()
          return false

        elseif (key.name == "space") then
          copy_assets()
          return false

        elseif (key.name == "esc") then
          dialog:close()
          return false

        end

      elseif (key.modifiers == "control") then
        -- non-repeated, CTRL modified
        if (key.name == "ins") then -- duplicate instrument
          return false
        elseif (key.name == "a") then 
          -- toggle select all
          local ctrl = get_all_checkbox()
          ctrl.value = not ctrl.value
          return false
        end
      end
    end

    if (key.modifiers == "") then
      -- repeat-agnostic, non-modified
      if (key.name == "tab") then
        if (sync_mode == SYNC_TARGET) then
          sync_with_selection(SYNC_SOURCE)
        elseif (sync_mode == SYNC_SOURCE) then
          sync_with_selection(SYNC_TARGET)
        end
        return false
      elseif (key.name == "½") then
        if not sync_mode then
          sync_with_selection(SYNC_SOURCE)
        else
          sync_with_selection()
        end
        return false
      elseif (key.name == "left") then
        show_previous_tab()
        return false
      elseif (key.name == "right") then
        show_next_tab()
        return false
      end
    end

    print("got here")
    return key

  end


  -- main dialog
  local content = vb:column {
    --width = 300,    
    margin = 5,    
    spacing = 5,
    vb:column {
      width = 280,    
      margin = 5,  
      style = "group",    
      vb:horizontal_aligner{
        width = "100%",
        vb:text {
          text = "Source",
          width = 40,
        },
        vb:popup {
          items = {},
          id = "instr_source_popup",
          value = 1,
          width = 210,
          notifier = function(idx)
            if not suppress_notifier then
              --source_instr_idx = idx
              switched_source()
            end
          end,
        },
        vb:button{
          text = "≡",
          id = "bt_sync_source",
          tooltip = "Synchronize the source with the selected instrument",
          notifier = function(val)
            sync_with_selection(SYNC_SOURCE)
          end,
        },
      },
      vb:horizontal_aligner{
        width = "100%",
        vb:text {
          text = "Target",
          width = 40,
        },
        vb:popup {
          items = {},
          id = "instr_target_popup",
          value = 1,
          width = 210,
          notifier = function(idx)
            if not suppress_notifier then
              target_instr_idx = idx
              switched_target()
            end
          end,
        },
        vb:button{
          text = "≡",
          id = "bt_sync_target",
          tooltip = "Synchronize the target with the selected instrument",
          notifier = function(val)
            sync_with_selection(SYNC_TARGET)
          end,
        },
      },
    },
    vb:switch {
      items = {"Samples","Phrases","Effects","Modulation"},    
      --height = 24,
      id = "main_switch",
      width = "100%",   
      notifier = function(new_index)
        show_tab(new_index)
      end

    },
    vb:column {
      width = 280,    
      margin = 5,  
      id = "tab_samples",
      visible = false,
      style = 'panel',
      vb:horizontal_aligner {
        mode = "left",
        width = "100%",
        vb:column {
          width = "10%",
          vb:text {
            text = "All"
          },
          vb:checkbox {
            id = "sampler_select_all",
            value = true,
            notifier = function(val)
              select_all(val)
            end,
          },
        },
        vb:column {
          --width = "80%",
          vb:text {
            id = "sample_count",
            text = "Selected 7/7 samples"
          },
          vb:row{
            vb:popup {
              id = "list_sample_info",
              notifier = function()
                update_sample_tab()
              end,
              width = 242,
              value = 2,
              items = {
                "Display name only",
                "Name + Note Range",
                "Name + Vel. Range",
                "Name + Mod. Set",
                "Name + FX Chain",
                "Name + Basenote",
                "Name + On/Off Layer",
                "Name + Slice #",
              }
            },
          },
        },
      },
      vb:space {height = 10},
      vb:row{
        width = "100%",
        style = 'border',
        margin = 3,
        vb:column{
          id = "samples_box_parent",
        },
        vb:vertical_aligner {
          width = "10%",
          height = "100%",
          margin = 0,
          spacing = 0,
          mode = "justify",
          id = "samples_scroller",
          vb:button {
            height = 20,
            width = 20,
            text = "▲",
            notifier = function()
              set_sample_page(sample_paging-1)
            end,
          },
          vb:button {
            height = 20,
            width = 20,
            text = "▼",
            notifier = function()
              set_sample_page(sample_paging+1)
            end,
          },
        },
      },

      vb:space {height = 10},
      vb:row {
        vb:checkbox {
          id = "sample_recreate_effects",
          value = true
        },
        vb:text {
          text = "Recreate effect chains",
        },
      },
      vb:row {
        vb:checkbox {
          id = "sample_recreate_modulation",
          value = true
        },
        vb:text {
          text = "Recreate modulation sets",
        },
      },

    },
    vb:column {
      width = 280,    
      margin = 5,  
      id = "tab_phrases",
      visible = false,
      style = 'panel',
      vb:horizontal_aligner{
        width = "100%",
        vb:column{
          width = "10%",
          vb:text {
            text = "All"
          },
          vb:checkbox {
            value = false,
            id = "phrases_select_all",
            notifier = function(val)
              select_all(val)
            end,
          },
          vb:space {height = 10},
          vb:text {text = "0"},
          vb:text {text = "1"},
          vb:text {text = "2"},
          vb:text {text = "3"},
          vb:text {text = "4"},
          vb:text {text = "5"},
          vb:text {text = "6"},
          vb:text {text = "7"},
          vb:text {text = "8"},
          vb:text {text = "9"},
        },
        vb:column {
          width = "90%",
          id = "phrase_rows_parent",
          vb:text {
            id = "phrase_count",
            text = ""
          },
          vb:row {

            vb:text {text = "C"},
            vb:text {text = "#"},
            vb:text {text = "D"},
            vb:text {text = "#"},
            vb:text {text = "E"},
            vb:text {text = "F"},
            vb:text {text = "#"},
            vb:text {text = "G"},
            vb:text {text = "#"},
            vb:text {text = "A"},
            vb:text {text = "#"},
            vb:text {text = "B"},
          },
          vb:space {height = 10},
        },
      },
      vb:space {height = 10},
      vb:row {
        vb:chooser {
          id = "phrase_mode_select",
          items = {
            "Replace phrases in target",
            "Append to phrases in target",
          },
          value = 1,
          notifier = function(val)
            LOG("val",val)

          end,
        },

      },
    },

    vb:column {
      width = 280,    
      margin = 5,  
      id = "tab_effects",
      visible = false,
      style = 'panel',
      vb:horizontal_aligner {
        mode = "left",
        width = "100%",
        vb:column {
          width = "10%",
          vb:text {
            text = "All"
          },
          vb:checkbox {
            id = "effect_select_all",
            value = true,
            notifier = function(val)
              select_all(val)
            end,
          },
        },
        vb:column {
          --width = "80%",
          vb:text {
            id = "effect_count",
            text = ""
          },
        },
      },
      vb:space {height = 10},
      vb:row{
        --width = 224,
        style = 'border',
        margin = 3,
        vb:column{
          id = "effect_box_parent",
          --style = 'border',
          --width = 200,
        },
        vb:vertical_aligner {
          width = "10%",
          height = "100%",
          margin = 0,
          spacing = 0,
          mode = "justify",
          id = "effect_scroller",
          vb:button {
            height = 20,
            width = 20,
            text = "▲",
            notifier = function()
              mod_paging = set_page(fx_paging-1,selected_effects)
              update_effects_tab()
            end,
          },
          vb:button {
            height = 20,
            width = 20,
            text = "▼",
            notifier = function()
              mod_paging = set_page(fx_paging-1,selected_effects)
              update_effects_tab()
            end,
          },
        },
      },
    },
    vb:column {
      width = 280,    
      margin = 5,  
      id = "tab_modulation",
      visible = false,
      style = 'panel',
      vb:horizontal_aligner {
        mode = "left",
        width = "100%",
        vb:column {
          width = "10%",
          vb:text {
            text = "All"
          },
          vb:checkbox {
            id = "modset_select_all",
            value = true,
            notifier = function(val)
              select_all(val)
            end,
          },
        },
        vb:column {
          --width = "80%",
          vb:text {
            id = "modset_count",
            text = ""
          },
        },
      },
      vb:space {height = 10},
      vb:row{
        --width = 224,
        style = 'border',
        margin = 3,
        vb:column{
          id = "modset_box_parent",
          --style = 'border',
          --width = 200,
        },
        vb:vertical_aligner {
          width = "10%",
          height = "100%",
          margin = 0,
          spacing = 0,
          mode = "justify",
          id = "modset_scroller",
          vb:button {
            height = 20,
            width = 20,
            text = "▲",
            notifier = function()
              mod_paging = set_page(mod_paging-1,selected_modsets)
              update_modulation_tab()
            end,
          },
          vb:button {
            height = 20,
            width = 20,
            text = "▼",
            notifier = function()
              mod_paging = set_page(mod_paging+1,selected_modsets)
              update_modulation_tab()
            end,
          },
        },
      },
    },
    vb:horizontal_aligner {
      vb:button {
        text = "Copy from source to target",
        id = "bt_commit",
        tooltip = "Copy selection to the instrument",
        height = 30,
        width = "90%",
        notifier = function()
          copy_assets()
        end
      },
      vb:button {
        text = "/\\/",
        id = "bt_focus_editor",
        tooltip = "Display the editing panel",
        height = 30,
        width = "10%",
        notifier = function()
          focus_editor()
        end
      },
    },

  } 

  dialog = renoise.app():show_custom_dialog(
    tool_name, content, keyhandler)  

  -- start the thing
  attach_to_song()
  update_instr_lists()
  show_tab(1)

  -- to begin with, always sync with source 
  if sync_mode then
    sync_mode = nil 
  end
  sync_with_selection(SYNC_SOURCE)

  -- also set target to selected
  local ctrl = vb.views.instr_target_popup
  ctrl.value = rns.selected_instrument_index + 1


end


-- Reload the script whenever this file is saved. 
-- Additionally, execute the attached function.
_AUTO_RELOAD_DEBUG = function()
  show_dialog()
end

--------------------------------------------------------------------------------
-- Notifiers
--------------------------------------------------------------------------------

renoise.tool().app_new_document_observable:add_notifier(function()
  --print("app_new_document_observable fired...")

  if not vb then
    return
  end

  local rns = renoise.song()

  attach_to_song()
  update_instr_lists()
  local source_instr = rns.instruments[source_instr_idx-1]
  if source_instr then
    attach_to_instrument(source_instr)
  end
  update_tab()

end)

renoise.tool().app_idle_observable:add_notifier(function()

  if not vb then
    return
  end

  if (scheduled_update) then
    if (scheduled_update == TAB_SAMPLES) then
      update_sample_tab()
    elseif (scheduled_update == TAB_PHRASES) then
      update_phrase_tab()
    elseif (scheduled_update == TAB_EFFECTS) then
      update_effects_tab()
    elseif (scheduled_update == TAB_MODSETS) then
      update_modulation_tab()
    end
    scheduled_update = nil
  end

end)

renoise.app().window.active_middle_frame_observable:add_notifier(function()

  update_focus_editor()

end)


--------------------------------------------------------------------------------
-- Menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:"..tool_name.."...",
  invoke = show_dialog  
}

renoise.tool():add_menu_entry {
  name = "Instrument Box:"..tool_name.."...",
  invoke = show_dialog
}

--------------------------------------------------------------------------------
-- Key Binding
--------------------------------------------------------------------------------

renoise.tool():add_keybinding {
  name = "Global:Tools:" .. tool_name.."...",
  invoke = show_dialog
}
--[[
--]]


--------------------------------------------------------------------------------
-- MIDI Mapping
--------------------------------------------------------------------------------

--[[
renoise.tool():add_midi_mapping {
  name = tool_id..":Show Dialog...",
  invoke = show_dialog
}
--]]
