-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- menu registration
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
local OPTION_CHANGE_SELECTED = 1
local OPTION_CHANGE_ALL = 2

renoise.tool():add_menu_entry {
  name = "Instrument Box:Edit all Samples in Current Instrument...",
  invoke = function() 
    open_sample_dialog(OPTION_CHANGE_SELECTED)
  end
}

renoise.tool():add_menu_entry {
  name = "Instrument Box:Edit all Samples in All Instruments...",
  invoke = function() 
    open_sample_dialog(OPTION_CHANGE_ALL)
  end
}

-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- content
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

local sync_mode = false
local safe_mode = true
local base_note_val = 'C-4'
local fine_tune_val = 0
local sync_val = 0
local pan_val = 0
local amp_val = 0
local nna_index = 1
local loop_index = 1
local interpolation_index = 1

local sample_dialog = nil
local do_nna = true
local do_base_note = false
local do_loop = false
local do_fine_tuning = false
local do_interpolate = false
local do_sync = false
local do_amplify = false
local do_panning = false

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

note_array = {}
valid_notes = {
   [1]='C-', [2]='C#', [3]='D-', [4]='D#', [5]='E-', [6]='F-',
   [7]='F#', [8]='G-', [9]='G#', [10]='A-', [11]='A#', [12]='B-'
}


-------------------------------------------------------------------------------

function open_sample_dialog(option)
   -- only show one dialog at the same time...
   if not (sample_dialog and sample_dialog.visible) then
      sample_dialog = nil
      local vb = renoise.ViewBuilder()

      local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
      local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
      local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN

      local TEXT_ROW_WIDTH = 60
      local song = renoise.song()
      local s_instrument = song.selected_instrument_index
      local win_title = ''
      if option == OPTION_CHANGE_SELECTED then
         win_title = "Global sample properties (selected instrument)"
      else
        assert(option == OPTION_CHANGE_ALL, "unexpected option")
         win_title = "Global sample properties (all instruments)"
      end

      sample_dialog = renoise.app():show_custom_dialog(
         win_title,
         vb:column {
            margin = DIALOG_MARGIN,
            spacing = 1,
            uniform = true,
            vb:row {
               create_view(obj_checkbox,'',18,0,0,do_nna,'id6',
               'Set NNA for all samples in instrument(s)?','',
               function(value) do_nna = value end,vb),
               create_view(obj_textlabel,'',TEXT_ROW_WIDTH,0,0,'novalue','id7',
               '','NNA','',vb),
               create_view(obj_popup,'',80,0,0,nna_index,
               'nna_mode','',{"Cut", "Noteoff", "Continue"}, 
               function(value) nna_index = value end,vb),
               create_view(obj_checkbox,'',18,0,0,do_base_note,'dobasenote',
               'Set base note for all samples in selected instrument?','',
               function(value) do_base_note = value end,vb),
               create_view(obj_textlabel,'',TEXT_ROW_WIDTH,0,0,'novalue','dobasenotetext',
               '','Basenote','',vb),
               vb:valuebox {
                min = 0,
                max = 119,
                value = 48,
                id='base_note',
                tostring = function(value) 
                  local octave_num = math.floor(value / 12)
                  local note_num = value % 12
                  note_num = note_num+1
                  local base_note = valid_notes[note_num]
                  base_note_val = base_note..tostring(octave_num)
                  return (base_note_val)
                end,
                tonumber = function(str) 
                  local octave = tonumber(str:sub(3, 3))
                  if (octave) then
                    local note_string = str:sub(1, 2)
                    for val,str in pairs(valid_notes) do
                      if (str:lower() == note_string:lower()) then
                        return 12 * octave + val - 1
                      end
                    end
                  end
                  
                  return nil -- can not convert
                end,
               },
            },
            vb:row {
               create_view(obj_checkbox,'',18,0,0,do_loop,'doloop',
               'Set loop for all samples in instrument(s)?','',
               function(value) do_loop = value end,vb),
               create_view(obj_textlabel,'',TEXT_ROW_WIDTH,0,0,'novalue','id5',
               '','Loop','',vb),
               create_view(obj_popup,'',80,0,0,loop_index,
               'loop_mode','',{"Off", "Forward", "Backward", "PingPong"}, 
               function(value) loop_index = value end,vb),
               create_view(obj_checkbox,'',18,0,0,do_fine_tuning,'dofinetuning',
               'Set fine-tuning for all samples in selected instrument?','',
               function(value) do_fine_tuning = value end,vb),
               create_view(obj_textlabel,'',TEXT_ROW_WIDTH,0,0,'novalue','dofinetuningtext',
               '','Finetuning','',vb),
               create_view(obj_valuebox,'',60,-127,127,fine_tune_val,'fine_tune_val',
               '','',function(value) fine_tune_val = value end,vb),
            },
            vb:row {
               create_view(obj_checkbox,'',18,0,0,do_interpolate,'dointerpolate',
               'Set interpolation level for all samples in instrument(s)?','',
               function(value) do_interpolate = value end,vb),
               create_view(obj_textlabel,'',TEXT_ROW_WIDTH,0,0,'novalue','id4',
               '','Interpolate','',vb),
               create_view(obj_popup,'',80,0,0,interpolation_index,
               'interpolation_mode','',{"None", "Linear", "Cubic"}, 
               function(value) interpolation_index = value end,vb),
               create_view(obj_checkbox,'',18,0,0,do_sync,'dosync',
               'Set Sync for all samples in selected instrument?','',
               function(value) do_sync = value end,vb),
               create_view(obj_textlabel,'',42,0,0,'novalue','dosynctext',
               '','Sync','',vb),
               create_view(obj_checkbox,'',18,0,0,sync_mode,'do_sync_mode',
               '','',function(value) sync_mode = value end,vb),
               create_view(obj_valuebox,'',60,0,512,sync_val,'sync_value',
               '','',function(value) sync_val = value end,vb),
            },         
            vb:space{height = 3*CONTENT_SPACING},
            vb:row {
               create_view(obj_checkbox,'',18,0,0,do_panning,'id1',
               'Set amplification for all samples in selected instrument?','',
               function(value) do_amplify = value end,vb),
               create_view(obj_textlabel,'',TEXT_ROW_WIDTH,0,0,'novalue','id2',
               '','Amplify','',vb),
               create_view(obj_slider,'',140,0,4,1,'amplification_level',
               '','',function(value)slide_volume(vb, value)end,vb),
               create_view(obj_textlabel,'',TEXT_ROW_WIDTH,0,0,'','db_value',
               '',string.format('%.1f',LinToDb(1)),'',vb),
            },
            vb:row {
               create_view(obj_checkbox,'',18,0,0,do_panning,'dopanning',
               'Set panning for all samples in selected instrument?','',
               function(value) do_panning = value end,vb),
               create_view(obj_textlabel,'',TEXT_ROW_WIDTH,0,0,'','dopanningtext',
               '','Panning','',vb),
               create_view(obj_slider,'',140,-50,50,0,'panning_level','','',
               function(value) slide_panning(vb, value) end,vb),
               create_view(obj_textlabel,'',TEXT_ROW_WIDTH,0,0,'','pan_value',
               '',tostring(vb.views.panning_level.value),'',vb),
            },
            vb:space{height = 3*CONTENT_SPACING},
            vb:row {
               vb:space {width = 70},
               create_view(obj_button,'',60,0,0,0,'id8','','Change the selected properties',
               function() change_sample_properties(option) end,vb),
               vb:space {width = 15},
               create_view(obj_textlabel,'right',30,0,0,'novalue','id_safe_text',
               '','Safe','',vb),
               create_view(obj_checkbox,'',18,0,0,safe_mode,'id_safe_mode',
               'Show/hide options that create unawarely subtile changes\nChanges that your are sure of to apply to *all* samples in *all* instruments','',
               function(value) toggle_safe_mode(value, vb) end,vb)
            }
         }
      )
      if option == 2 then
         vb.views.id_safe_text.visible = true
         vb.views.id_safe_mode.visible = true

         if safe_mode == true then
           disable_unsafe_options(vb)
         end
            
      else
         vb.views.id_safe_text.visible = false
         vb.views.id_safe_mode.visible = false
         enable_unsafe_options(vb)
      end
   else
      sample_dialog:show()
   end
end


function toggle_safe_mode(value,vb)
  safe_mode = value
  if value == false then
    enable_unsafe_options(vb)
  else
    disable_unsafe_options(vb)  
  end
end


function disable_unsafe_options(vb)
  vb.views.dopanning.visible = false
  vb.views.dopanning.value = false
  vb.views.dopanningtext.visible = false
  vb.views.panning_level.visible = false
  vb.views.pan_value.visible = false
  do_panning = false
         
  vb.views.dofinetuning.visible = false
  vb.views.dofinetuning.value = false
  vb.views.dofinetuningtext.visible = false
  vb.views.fine_tune_val.visible = false
  do_fine_tuning = false
   
  vb.views.dosync.visible = false
  vb.views.dosync.value = false
  vb.views.dosynctext.visible = false
  vb.views.do_sync_mode.visible = false
  vb.views.sync_value.visible = false
  do_sync = false
         
  vb.views.dobasenote.visible = false
  vb.views.dobasenote.value = false
  vb.views.dobasenotetext.visible = false
  vb.views.base_note.visible = false
  do_base_note = false
end


function enable_unsafe_options(vb)
  vb.views.dopanning.visible = true
  vb.views.dopanningtext.visible = true
  vb.views.panning_level.visible = true
  vb.views.pan_value.visible = true
   
  vb.views.dofinetuning.visible = true
  vb.views.dofinetuningtext.visible = true
  vb.views.fine_tune_val.visible = true
   
  vb.views.dosync.visible = true
  vb.views.dosynctext.visible = true
  vb.views.do_sync_mode.visible = true
  vb.views.sync_value.visible = true
   
  vb.views.dobasenote.visible = true
  vb.views.dobasenotetext.visible = true
  vb.views.base_note.visible = true
end


function slide_panning(vb, value)
   local disp_val = string.format('%.0f',value)
   if value == 0 then
      disp_val = 'Center'
   elseif value < 0 then
      disp_val = disp_val .. 'L'
   elseif value > 0 then
      disp_val = disp_val .. 'R'
   end
   vb.views.pan_value.text = disp_val
   pan_val = value
end


function slide_volume(vb,value)
   local disp_val = string.format('%.1f',LinToDb(value))
   if tonumber(disp_val) <= -200 then
      disp_val = '-INF'
   end
   disp_val = disp_val .. ' dB'
   vb.views.db_value.text = disp_val
   amp_val = value
end


function create_view(type,palign,pwidth,pmin,pmax,pvalue, pid,ptooltip,ptext,pnotifier, vb)
    if palign == '' then
      palign = 'left'
    end
   if type == obj_textlabel then
      return vb:text {id=pid, align=palign, width = pwidth, tooltip = ptooltip, text = ptext}
   end
   if type == obj_button then
      return vb:button {id=pid, width = pwidth, tooltip = ptooltip, text = ptext,
         notifier = pnotifier}
   end
   if type == obj_checkbox then
      return vb:checkbox {id = pid, width = pwidth, tooltip = ptooltip, 
      value = pvalue, notifier = pnotifier}
   end
   if type == obj_switch then
      return vb:switch {id = pid, width = pwidth, tooltip = ptooltip,
         items = ptext, value = pvalue, notifier = pnotifier}
   end
   if type == obj_popup then
      return vb:popup {id = pid, width = pwidth, tooltip = ptooltip,
         items = ptext, value = pvalue, notifier = pnotifier}
   end
   if type == obj_chooser then
      return vb:chooser {id = pid, width = pwidth, tooltip = ptooltip,
         value = pvalue, items = ptext, notifier = pnotifier}
   end
   if type == obj_valuebox then
      return vb:valuebox {id=pid, width = pwidth, tooltip = ptooltip,
         min = pmin, max = pmax, value = pvalue, notifier = pnotifier}
   end
   if type == obj_slider then
      return vb:slider {id=pid, width = pwidth, tooltip = ptooltip,
         min = pmin, max = pmax, value = pvalue, notifier = pnotifier}
   end
   if type == obj_minislider then
      return vb:minislider {id=pid, width = pwidth, tooltip = ptooltip,
         min = pmin, max = pmax, value = pvalue, notifier = pnotifier}   
   end
   if type == obj_textfield then
      return vb:textfield{id = pid, width = pwidth, tooltip = ptooltip,
         value = pvalue, notifier = pnotifier}
   end
end

-----------------------------------------------------------------------------


local EPSILON = 1e-12
local MINUSINFDB = -200.0

function LinToDb(Value)
  if (Value > EPSILON) then
    return math.log10(Value) * 20.0
  else
    return MINUSINFDB
  end
end


function DbToLin(Value)
  if (Value > MINUSINFDB) then
    return math.pow(10.0, Value * 0.05)
  else
    return 0.0
  end
end


function change_sample_properties(option)
   local song = renoise.song()
   local range_start = 1
   local range_end = song.selected_instrument_index
   local cur_ins = nil --song.instruments[song.selected_instrument_index]
   local send = nil --#s_instrument.samples
   if option == OPTION_CHANGE_SELECTED then
      range_start = song.selected_instrument_index
   else
       assert(option == OPTION_CHANGE_ALL, "unexpected option")
      range_end = #song.instruments
   end

   for _ = range_start,range_end do
      local my_splitmap = {}
      local base_note_figure = nil
      cur_ins =song.instruments[_]
      local s_instrument = cur_ins
      send = #cur_ins.samples      
      for octave = 0, 9 do
         for note = 1, 12 do
            note_array[#note_array+1] = valid_notes[note]..tostring(octave)
         end
      end
   
      if do_base_note == true then
         for t = 1, 120 do
            my_splitmap[t] = 1
         end
         for t = 1, 120 do
            if tonumber(base_note_val) ~= nil then
              local shift = t + tonumber(base_note_val)
              if shift > 0 and shift < 121 then
                 my_splitmap[shift] = cur_ins.split_map[t]
              end
            end
         end
         
      else
         my_splitmap = cur_ins.split_map
      end
         
      for t = 1, send do
         if do_nna == true then
            s_instrument.samples[t].new_note_action = nna_index
         end
         if do_base_note == true then
            if tonumber(base_note_val) ~= nil then
               local cur_base_note = s_instrument.samples[t].base_note
               base_note_figure = cur_base_note + tonumber(base_note_val) + 1
   
               if base_note_figure ~= nil and base_note_figure > 0 and 
               base_note_figure < 121 then
                  s_instrument.samples[t].base_note = base_note_figure-1
               end
              
            else
               for nt = 1,10*12 do
                  if note_array[nt] == string.upper(base_note_val) then
                     base_note_figure = nt-1
                     break
                  end
               end
               if base_note_figure ~= nil then
                  s_instrument.samples[t].base_note = base_note_figure
               end
            end 
         end
         if do_loop == true then
            s_instrument.samples[t].loop_mode = loop_index
         end
         if do_fine_tuning == true then
            s_instrument.samples[t].fine_tune = fine_tune_val
         end
         if do_interpolate == true then
            s_instrument.samples[t].interpolation_mode = interpolation_index
         end
         if do_sync == true then
            s_instrument.samples[t].beat_sync_enabled = sync_mode
            s_instrument.samples[t].beat_sync_lines = sync_val
         end
         if do_amplify == true then
            s_instrument.samples[t].volume = amp_val
         end
         if do_panning == true then
            local pan_result = 0.5
            if pan_val > 0 then
               pan_result = pan_val / 100 + pan_result
            elseif pan_val < 0 then
               pan_result = pan_result - (pan_val / -100) 
            end         
            s_instrument.samples[t].panning = pan_result
         end
      end

      cur_ins.split_map = my_splitmap
   end
end
