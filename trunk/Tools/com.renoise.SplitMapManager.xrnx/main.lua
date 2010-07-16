-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- content
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

local smm_debug = false

local remote_session = false
local start_sample = 1
local base_note = 48
local end_sample = 254
local start_split = 49
local low_split = 49
local lock_init_start_split = 1
local end_split = 61
local high_split = 61
local lock_init_end_split = 1
local temp_split_map = {}
local split_range = "0"
local split_distance = 1
local yield_operation = 0
local yield_lock = 0
local semi_tone_division = 1
local safe_margins = true
local leave_existing = 0
local sample_trail_start = true
local sample_trail_end = true
local vb_splitmap = nil

local splitmap_dialog = nil

local obj_textlabel = 1
local obj_button = 2 
local obj_checkbox = 3
local obj_switch = 4 
local obj_popup = 5 
local obj_chooser = 6 
local obj_valuebox = 7 
local obj_slider = 8 
local obj_minislider = 9 
local obj_textfield = 10 
local obj_valuefield = 11 

local last_attached_instrument = nil

local NUM_OCTAVES = 10
local NUM_NOTES = 12

local note_array = {}
local valid_notes = {
   [1]='C-', [2]='C#', [3]='D-', [4]='D#', [5]='E-', [6]='F-',
   [7]='F#', [8]='G-', [9]='G#', [10]='A-', [11]='A#', [12]='B-'
}


-----------------------------------------------------------------------------

function open_splitmap_dialog()

   -- only show one dialog at the same time...
   if not (splitmap_dialog and splitmap_dialog.visible) then
      splitmap_dialog = nil
      local song = renoise.song()
      local vb = renoise.ViewBuilder()
      vb_splitmap = vb
      local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
      local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
      local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
      local TEXT_ROW_WIDTH = 70
      local song = renoise.song()
      local s_instrument = song.selected_instrument_index
      local cur_ins = song.instruments[s_instrument]
      end_sample = #cur_ins.samples
      local win_title = "Split map manager (extended drumkit generator)"

      for octave = 1, NUM_OCTAVES do

         for note = 1, NUM_NOTES do
            note_array[#note_array + 1] = valid_notes[note]..tostring(octave-1)
         end

      end

      local function object_slider(ss_id,ss_text_id,ss_text, ss_value,
      ss_field_function, ss_function, ss_field_id, ss_string,ss_start,ss_end)

         return vb:row{
            create_view(obj_textlabel,'', TEXT_ROW_WIDTH,0,0,0,ss_text_id,'',
            ss_text,0,vb),

            create_view(obj_minislider,'',60,ss_start,ss_end,ss_value,ss_id,
            '',0,ss_function,vb),

            create_view(obj_textfield, '', 32,0,0,ss_string,ss_field_id,'',0,
            ss_field_function,vb),
         }

      end

      splitmap_dialog = renoise.app():show_custom_dialog(
      win_title,

      vb:column {
         margin = DIALOG_MARGIN,
         spacing = 3,
         uniform = true,

         vb:column{
            style = "group",
            margin = DIALOG_MARGIN,
            spacing = 3,
            uniform = true,

            vb:horizontal_aligner {
               mode = "center",

               vb:row {

                  vb:text {
                     width = 42,
                     text = "Sample and split configuration"
                  },
               },
            },

            vb:row {
               object_slider('start_sample','start_sample_text','Start sample', 
               1,function(value)sample_textfield(value,vb,true)end,
               function(value) sample_slider(value,vb,true) end,
               'start_sample_field',string.format("0x%X", math.floor(start_sample-1)), 
               math.floor(start_sample), math.floor(end_sample)),

               object_slider('end_sample','end_sample_text','End sample', 
               end_sample,function(value) sample_textfield(value,vb,false)end,
               function(value) sample_slider(value,vb,false) end,
               'end_sample_field',string.format("0x%X", math.floor(end_sample-1)), 
               math.floor(start_sample), math.floor(end_sample)),
            },

            vb:row {
               object_slider('start_split','start_split_text','Split start', 
               start_split,function(value)split_textfield(value,vb,true)end,
               function(value) split_slider(value,vb,true) end,
               'start_split_field',note_array[start_split], 1, 120),

               object_slider('end_split','end_split_text','Split end', 
               end_split,function(value) split_textfield(value,vb,false)end,
               function(value) split_slider(value,vb,false) end,
               'end_split_field',note_array[end_split], 1, 120),
            },
         },

         vb:column{
            style = "group",
            margin = DIALOG_MARGIN,
            spacing = 3,
            uniform = true,

            vb:horizontal_aligner {
               mode = "center",

               vb:row {
                  create_view(obj_textlabel, '', 80,0,0,0,'semitone_division_text',
                  '','Each sample should be mapped to',0,vb),

                  create_view(obj_valuebox, '', 52,1,120,semi_tone_division,
                  'semi_tone_division_value','',0,
                  function(value)semi_tone_division = value end,vb),

                  create_view(obj_textlabel, '', 42,0,0,0,'semitone_division_post_text',
                  '','semitones',0,vb),
               },
            },

            vb:horizontal_aligner {
               mode = "center",

               vb:row {
                  create_view(obj_checkbox, '', 18,0,0,sample_trail_start,
                  'trail_sample_start','',0,
                  function(value)sample_trail_start = value end,vb),

                  create_view(obj_textlabel, '', 42,0,0,0,'trail_sample_start_text',
                  '','Map first sample down till the first key',0,vb),
               },
            },

            vb:horizontal_aligner {
               mode = "center",

               vb:row {
                  create_view(obj_checkbox, '', 18,0,0,sample_trail_end,
                  'trail_sample_end','',0,
                  function(value)sample_trail_end = value end,vb),

                  create_view(obj_textlabel, '', 42,0,0,0,'trail_sample_end_text',
                  '','Map last sample up till the last key',0,vb),
               },
            },

            vb:space{height = 3*CONTENT_SPACING},

            vb:horizontal_aligner {
               mode = "center",

               vb:row {
                  create_view(obj_button, '', 60,0,0,0,'idb1','',
                  'Map sample-range to split-range',
                  function(value)map_sample_range() end,vb),
               },
            },
         },

         vb:column{
            style = "group",
            margin = DIALOG_MARGIN,
            spacing = 3,

            vb:row{
               create_view(obj_textlabel, 'center', 330,0,0,0,
               'split_range_shift_text','','Shift selected split-range in semitones',
               0,vb),
            },

            vb:horizontal_aligner {
               mode = "center",

               vb:row{
                  create_view(obj_button, '', 52,0,0,0,
                  'split_range_shift_left','Shift range to the left [left arrow] (See virtual keyboard)',
                  '<',function(value)shift_split_range(-1,vb) end,vb),

                  create_view(obj_button, '', 52,0,0,0,
                  'split_range_shift_right','Shift range to the right [right arrow] (See virtual keyboard)',
                  '>',function(value)shift_split_range(1,vb) end,vb),

--                  create_view(obj_valuebox, '', 52,-120,120,tonumber(split_range),
--                  'split_range_shift','Value is applied immediately so watch the splitmap!',
--                  0,function(value)shift_split_range(value,vb) end,vb),
--[[
                  vb:row{
                     vb:checkbox {
                        id = 'keep_safe_margins',
                        tooltip = 'Do not cross lower / upper keyboard mapping borders',
                        value = safe_margins,
                        notifier = function(value)
                           safe_margins = value
                        end,
                     },
                     vb:text {
                        id='dosafe_margins_text',
                        width = 100,
                        text = "Keep safe margins"
                     },
                  },
--]]
               },
            },
         }
      },key_handler
   )

   else
      splitmap_dialog:show()
   end
   
   -- get notified of changes that are done in the song while our dialog is open
   attach_to_song()
end


-----------------------------------------------------------------------------

function shift_split_range(value,vb)
   local song = renoise.song()
   local s_instrument = song.selected_instrument_index
   local cur_ins = song.instruments[s_instrument]

   if yield_operation == 0 then
      yield_operation = 1
      local split_distance = high_split - low_split
      local target_low = 0
      local target_high = 0
      low_split = vb.views.start_split.value
--      vb.views.split_range_shift.min = 0 - low_split
      high_split = vb.views.end_split.value
--      vb.views.split_range_shift.max = 120 - high_split
      split_distance = high_split - low_split
      value = tonumber(math.floor(value))

      if value < -120 then
         value = -120
      end

      if value > 120 then 
         value = 120
      end 

      low_split = vb.views.start_split.value
      high_split = vb.views.end_split.value

      if low_split + value > 0 then
         target_low = low_split + value

         if high_split + value < 121 then
            target_high = high_split + value
         else

            if safe_margins == true then
               target_high = 120
               target_low = 120 - split_distance
            else
               target_high = high_split + value
            end

         end

      else

         if safe_margins == true then
            target_low = 1
            target_high = split_distance + 1
         else
            target_low = low_split + value
         end

      end

      for z = 1, 120 do
         temp_split_map[z] = 1
      end

      s_instrument = song.selected_instrument_index
      cur_ins = song.instruments[s_instrument]

      for z = 1, 120 do
         temp_split_map[z] = cur_ins.split_map[z]
      end

      for t = 1, (split_distance+1) do

         if (cur_ins.split_map[low_split+ t - 1] ~= nil) and (target_low+t-1 > 1) then
            temp_split_map[target_low+t-1] = cur_ins.split_map[low_split+ t - 1]
         end 

      end
--      if table.exists(temp_split_map) then
        cur_ins.split_map = temp_split_map
--      end
      split_range = 0
--      vb.views.split_range_shift.value = 0
      yield_operation = 0
      local stop_shift = 0

      if (vb.views.start_split.value + value > 0) and 
      (vb.views.end_split.value + value <= 120) then
         vb.views.start_split.value = vb.views.start_split.value + value
         stop_shift = 0
      else
         stop_shift = 1
      end 

      if (vb.views.end_split.value + value <= 120) and 
      stop_shift == 0 then
         vb.views.end_split.value = vb.views.end_split.value + value
      end 

      set_base_notes()
   end

end


function sample_slider(value,vb, slider_one)
   local song = renoise.song()
   local cur_ins = song.instruments[song.selected_instrument_index]

   if  #cur_ins.samples ~= vb.views.start_sample.max then
      vb.views.start_sample.max = #cur_ins.samples
   end

   yield_operation = 1

   if slider_one == true then
      vb.views.start_sample_field.value = string.format("0x%X",  math.floor(value-1)) 
      start_sample = value
   else   
      vb.views.end_sample_field.value = string.format("0x%X",  math.floor(value-1)) 
      end_sample = value
   end

   yield_operation = 0

end


function split_slider(value,vb,slider_one)
   if yield_operation == 0 then

      if value < 1 then
         value = 1
      end

      if value > 120 then 
         value = 120
      end

      if slider_one == false then
         value = tonumber(math.floor(value))
      end

      yield_operation = 1

      if slider_one == true then
         local note_array_value = nil
         note_array_value = tonumber(math.floor(value))
         if note_array[note_array_value] ~= nil then
            vb.views.start_split_field.value = note_array[note_array_value]
         end
         start_split = value
      else
         vb.views.end_split_field.value = note_array[value]
         end_split = value
      end

      yield_operation = 0
   end

end


function split_textfield(value,vb,field_one)
   if yield_operation == 0 then 
      yield_operation = 1
      local valid_note = nil
      local note_num = nil

      for _ = 1,120 do

         if string.upper(value) == string.upper(note_array[_]) then
            valid_note = 1
            note_num = _
            break
         end

      end

      if valid_note == nil then

         if field_one == true then
            value = 'C-4'--note_array[start_split]
            vb.views.start_split_field.value = value
         else
            value = 'C-4' --note_array[end_split]
            vb.views.end_split_field.value = value
         end
         note_num = 49

      end

      if field_one == true then
         start_split = tonumber(note_num)
         vb.views.start_split.value = start_split
      else
         end_split = tonumber(note_num)
         vb.views.end_split.value = end_split
      end
      yield_operation = 0

   end

end


function sample_textfield(value,vb, field_one)
   local song = renoise.song()
   local cur_ins = song.instruments[song.selected_instrument_index]

   if  #cur_ins.samples ~= vb.views.start_sample.max then
      vb.views.start_sample.max = #cur_ins.samples
   end

   if  #cur_ins.samples ~= vb.views.end_sample.max then
      vb.views.end_sample.max = #cur_ins.samples
   end

   if (tonumber(value) == nil) or (tonumber(value) < 1) then
      value = "0x0"
   end

   if tonumber(value) > #cur_ins.samples then
      value = string.format("0x%X", #cur_ins.samples-1) 
   end

   if field_one == true then
    vb.views.start_sample_field.value = value
    start_sample = math.floor(tonumber(value))
   else
    vb.views.end_sample_field.value = value
    end_sample = math.floor(tonumber(value))
   end

   if yield_operation == 0 then 

      if field_one == true then

        if math.floor(start_sample+1) >= 1 then
         vb.views.start_sample.value = math.floor(start_sample+1)
        else
          vb.views.start_sample.value = 1
        end

      else

        if math.floor(end_sample + 1) <= #cur_ins.samples then
           vb.views.end_sample.value = math.floor(end_sample+1)
        else
           vb.views.end_sample.value = math.floor(end_sample)
        end

      end

   end

end


function create_view(type,pa,pw,pmi,pma,pv,pid,ptt,ptx,pn,vb)
   if pa == '' then
      pa = 'left'
   end    

   if type == obj_textlabel then
      return vb:text {id=pid,align=pa,width=pw,tooltip=ptt,text=ptx}
   end

   if type == obj_button then
      return vb:button {id=pid,width=pw,tooltip=ptt,text=ptx,notifier=pn}
   end

   if type == obj_checkbox then
      return vb:checkbox {id=pid,width=pw,tooltip=ptt,value=pv,notifier=pn}
   end

   if type == obj_switch then
      return vb:switch {id=pid,width=pw,tooltip=ptt,items=ptx,value=pv,notifier=pn}
   end

   if type == obj_popup then
      return vb:popup {id=pid,width=pw,tooltip=ptt,items=ptx,value=pv,notifier=pn}
   end

   if type == obj_chooser then
      return vb:chooser {id=pid,width=pw,tooltip=ptt,items=ptx,value=pv,notifier=pn}
   end

   if type == obj_valuebox then
      return vb:valuebox {id=pid,width=pw,tooltip=ptt,min=pmi,max=pma,value=pv,notifier=pn}
   end

   if type == obj_slider then
      return vb:slider {id=pid,width=pw,tooltip=ptt,min=pmi,max=pma,value=pv,notifier=pn}
   end

   if type == obj_minislider then
      return vb:minislider {id=pid,width=pw,tooltip=ptt,min=pmi,max=pma,value=pv,notifier=pn}   
   end

   if type == obj_textfield then
      return vb:textfield{id=pid,align=pa,width=pw,tooltip=ptt,value=pv,notifier=pn}
   end

   if type == obj_valuefield then
      return vb:valuefield{id=pid,align=pa,width=pw,tooltip=ptt,value=pv,notifier=pn}
   end

end


function set_base_notes()
   local song = renoise.song()
   local cur_ins = 1   
   local cur_sample = 1
   local temp_sample = 1
   cur_ins = song.instruments[song.selected_instrument_index]
   cur_ins.samples[cur_sample].base_note = start_split - 1

   for t = 1, 120 do
      temp_sample = cur_ins.split_map[t]

      if temp_sample ~= cur_sample then
         cur_sample = temp_sample
         cur_ins.samples[cur_sample].base_note = t - 1
      end

   end

end


function map_sample_range()
   local song = renoise.song()
   local layer_start = 1
   local split_position = start_split
   local s_instrument = 1
   local cur_ins = 1   
   start_sample = math.floor(start_sample)
   end_sample = math.floor(end_sample)   

   if sample_trail_start == true then --trail in if desired
      layer_start = math.floor(start_sample)
   end

   if leave_existing == 0 then

      for z = 1, 120 do
         temp_split_map[z] = layer_start
      end

   end

   s_instrument = song.selected_instrument_index
   cur_ins = song.instruments[s_instrument]

   if leave_existing == 1 then

      for z = 1, 120 do
         temp_split_map[z] = cur_ins.split_map[z]
      end

   end

   for z = math.floor(start_sample), math.floor(end_sample) do

      for t = 1, semi_tone_division do
         local pos = z

         if z > math.floor(end_sample) then
           pos = pos-1
         end

         if z < 1 then
           pos = 1
         end
         temp_split_map[split_position] = pos
         split_position = split_position + 1
      end      

      if split_position > end_split then
         break --We cannot assign more splits if we cross the range
      end

   end

   if leave_existing == 0 then

      if sample_trail_end == true then --trail out if desired

         for z = split_position, 120 do
            temp_split_map[z] = end_sample
         end

      end

   end
--   if table.exists(temp_split_map) then
     cur_ins.split_map = temp_split_map
     set_base_notes()
--   end
end


-----------------------------------------------------------------------------

-- update the properties of the currently selected instrument in the dialog,
-- when the isntument changed outside of the dialog, not from within our script

function update_visible_instrument()

  if (splitmap_dialog and splitmap_dialog.visible) then

    if smm_debug then
      print ("update_visible_instrument")
    end
  
    -- only ned to update, verify the end_sample in the split
    end_sample = #renoise.song().selected_instrument.samples

    vb_splitmap.views.end_sample_field.value = 
      string.format("0x%X",  math.floor(end_sample-1)) 

    vb_splitmap.views.end_sample.value = math.floor(end_sample)
  end

end


-- called as soon as a new instrument was selected

function selected_instrument_changed()

  if smm_debug then
    print ("selected_instrument_changed")
  end
  
  -- detach from a previously attached sample list
  if (last_attached_instrument) then
    last_attached_instrument.samples_observable:remove_notifier(
      selected_sample_list_changed)
  end

  -- attach to the new sample list
  last_attached_instrument = renoise.song().selected_instrument
  
  if (last_attached_instrument) then
    last_attached_instrument.samples_observable:add_notifier(
      selected_sample_list_changed)
  end

  -- and update  
  update_visible_instrument()
end


-- called as soon as the sample list of the selected instrument changed

function selected_sample_list_changed()

  if smm_debug then
    print ("selected_sample_list_changed")
  end
  
  -- only update
  update_visible_instrument()
end


-- add notifiers to the selected instruments sample list (the one we change)

function attach_to_song()

  if smm_debug then
    print ("attach_to_song")
  end
  
  local selected_instrument_observable = 
    renoise.song().selected_instrument_observable
  
  if not (selected_instrument_observable:has_notifier(
      selected_instrument_changed)) then
    
      selected_instrument_observable:add_notifier(
      selected_instrument_changed)
  end
  
  -- attach to the sample list (selected_instrument_changed will do that)
  selected_instrument_changed()
end


-- close the dialog as soon as a new song was loaded/created.
  
function handle_new_song_notification()

  if smm_debug then
    print ("handle_new_song_notification")
  end

  -- old song is gone now, so we need to reattach
  last_attached_instrument = nil
  
  if (splitmap_dialog and splitmap_dialog.visible) then
    splitmap_dialog:close()
  end

end


-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- tool registration
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

renoise.tool().app_new_document_observable:add_notifier(
  handle_new_song_notification)

renoise.tool():add_menu_entry {
  name = "Instrument Box:Split Map Manager...",
  invoke = function() 
     open_splitmap_dialog()
  end
}



function key_handler(dialog, key)

  if (key.modifiers == "" and key.name == "esc") then
      dialog:close()
  
  elseif (key.modifiers == "" and key.name == "left") then

    if (vb_splitmap.views.start_split.value -1 > 0) then
      shift_split_range(-1,vb_splitmap)
    end

  elseif (key.modifiers == "" and key.name == "right") then

    if (vb_splitmap.views.end_split.value + 1 <= 120) then
       shift_split_range(1,vb_splitmap)
    end

  end

end
