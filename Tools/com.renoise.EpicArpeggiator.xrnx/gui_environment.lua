
-------------------------------------------------------------------------------
-- The GUI dialogs
-------------------------------------------------------------------------------
---                        Main dialog                                     ----
-------------------------------------------------------------------------------
function open_arp_dialog()

      track_index = renoise.song().selected_track_index
      max_note_columns = renoise.song().tracks[track_index].visible_note_columns
      column_offset = renoise.song().selected_note_column_index 
      if max_note_columns < 1 then -- Cursor on Master / sendtrack?
         max_note_columns = 1
         column_offset = 1
      end
      local vb = renoise.ViewBuilder()
      
      local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
      local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
      local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
      local CHECKBOX_WIDTH = 30
      local TEXT_ROW_WIDTH = 80
--[[------------------------------------------------------------------------
Tone Matrix
--------------------------------------------------------------------------]]
      local figure_matrix = vb:column {
         margin = CONTENT_MARGIN,
         uniform = true,
         style = "border"
      }
   --- header column
      local header_content = vb:row {}
      header_content:add_child(
         vb:space {
            width = CHECKBOX_WIDTH + 40
         }
      )
      for note = 1, NUM_NOTES do
         local ALTERED_WIDTH = nil
         --Centering note-ID's above the checkbox columns
         if note == 1 then
            ALTERED_WIDTH = CHECKBOX_WIDTH-3
         elseif note == 2 then       
            ALTERED_WIDTH = CHECKBOX_WIDTH+3
         elseif note == 3 then
            ALTERED_WIDTH = CHECKBOX_WIDTH-3
         elseif note == 4 then       
            ALTERED_WIDTH = CHECKBOX_WIDTH+3
         elseif note == 5 then
            ALTERED_WIDTH = CHECKBOX_WIDTH+2
         elseif note == 6 then       
            ALTERED_WIDTH = CHECKBOX_WIDTH-2
         elseif note == 7 then       
            ALTERED_WIDTH = CHECKBOX_WIDTH-2
         elseif note == 8 then
            ALTERED_WIDTH = CHECKBOX_WIDTH-2
         elseif note == 9 then       
            ALTERED_WIDTH = CHECKBOX_WIDTH+4
         elseif note == 10 then
            ALTERED_WIDTH = CHECKBOX_WIDTH-2
         elseif note == 11 then       
            ALTERED_WIDTH = CHECKBOX_WIDTH+2
         elseif note == 12 then
            ALTERED_WIDTH = CHECKBOX_WIDTH
         end
         header_content:add_child(
            vb:column {
               create_obj(obj_textlabel, '', ALTERED_WIDTH,0,0,0,'id_note'..tostring(note),
               '',note_matrix[note],'',vb),
            }
         )
      end
   
      figure_matrix:add_child(header_content)
   
   --- octave text & note checkbox columns
      local done_content = vb:column {}
      for octave = 1,NUM_OCTAVES do
         local area_content = vb:row {
         }
         -- octave text
         area_content:add_child(
            vb:row{
               create_obj(obj_textlabel, '', CHECKBOX_WIDTH,0,0,'novalue','id_oct'..tostring(octave),
               '',tostring(octave-1),'',vb),
               create_obj(obj_button, '', CHECKBOX_WIDTH,0,0,0,'id_but'..tostring(octave),
               '','>', function() toggle_octave_row(vb, octave) end,vb),
            }
         )
         -- note checkboxes
         for note = 1, NUM_NOTES  do
            local note_tooltip, note_id
   
            if string.find(note_matrix[note], "#") then
               note_tooltip = note_matrix[note]..tostring(octave-1)
               note_id = note_matrix[note-1].."f"..tostring(octave-1)
            else
               note_tooltip = note_matrix[note].."-"..tostring(octave-1)
               note_id = note_matrix[note].."_"..tostring(octave-1)
            end
            
            area_content:add_child(
               create_obj(obj_checkbox, '', CHECKBOX_WIDTH,0,0,
               note_state(octave, note),note_id,note_tooltip,'', 
               function(value)set_note_state(octave, note, value)end,vb)
            )
         end
         done_content:add_child(area_content)
          
      end

      local ntrigger_area = vb:row {}

      -- note/octave row trigger checkboxes
      for tbutton = 0, 1 do
         local btooltip, btext
         local trigger_content = vb:column {}
         if tbutton == 0 then
           btooltip = "Toggle all off"
           btext = "off"
         else
           btooltip = "Invert all (what is on turns off and what is off turns on)"
           btext = "inv"
         end
   
         trigger_content:add_child(
            create_obj(obj_button, '',CHECKBOX_WIDTH,0,0,0,'id_butt'..tostring(tbutton),
            btooltip,btext, function() set_all_row_state(vb, btext) end,vb)
         )
         ntrigger_area:add_child(trigger_content)
      end

      -- note row trigger checkboxes
      for note = 1, NUM_NOTES do
         local note_tooltip
         local trigger_content = vb:column {}
         if string.find(note_matrix[note], "#") then
           note_tooltip = note_matrix[note]
         else
           note_tooltip = note_matrix[note]
         end
   
         trigger_content:add_child(
            create_obj(obj_button, '', CHECKBOX_WIDTH,0,0,0,'id_butn'..tostring(note),
            note_tooltip,'^', function() toggle_note_row(vb, note) end,vb)
         )
         ntrigger_area:add_child(trigger_content)
      end

      local matrix_layout = vb:column{
         id = 'total_matrix',
         done_content,
         ntrigger_area
      }      
      figure_matrix:add_child(matrix_layout)

--[[------------------------------------------------------------------------
Main Dialog
--------------------------------------------------------------------------]]
      local note_header_contents = vb:row {}
      local picker_row_contents = vb:row {}
      local note_row_contents = vb:row {}
      local button_row_contents = vb:row {}
      note_header_contents:add_child(
         vb:text {
            align = "center",
            width = 325,
            text = "Note & Octave properties"
         }
      )      
      picker_row_contents:add_child(
         create_obj(obj_textlabel,'', 95,0,0,0,'idpr1','','Note & Octave scheme',0,vb)
      )
      picker_row_contents:add_child(
         create_obj(obj_switch, '', 160,0,0,switch_note_pattern_index,
         'switch_note_pattern',
         "Matrix:Pick note and octave order from the note-matrix.\n"..
         "Custom:defined in the textfields below.",
         {"Matrix", "Custom"},
         function(value)
            switch_note_pattern_index = value
            arpeg_option_dialog:close()
            open_arp_dialog()
         end,vb)
      )
      picker_row_contents:add_child(
         create_obj(obj_textlabel, 'right', 48,0,0,0,'idprt2','','',0,vb)
      )
      note_row_contents:add_child(
         create_obj(obj_textlabel, '', 119,0,0,0,'custom_note_profile_title',
         '','Custom note profile',0,vb)
      )
      note_row_contents:add_child(
         create_obj(obj_textfield, '', 309,0,0,custom_note_field,'custom_note_profile',
         'Figures go from C to B, Octave figures are accepted as well',0,
         function(value) custom_note_field = value end,vb)
      )
      button_row_contents:add_child(
         create_obj(obj_button, '', 80,0,0,0,'custom_fetch',
         'Read all notes in track and copy them into the note-profile',
         'Fetch from current track',function(value)fetch_notes_from_track(vb)end,vb)
      )
      local arp_header_contents = vb:row {}
      local distance_row_contents = vb:row {}
      local termination_row_header_contents = vb:column {}
      local termination_row_contents = vb:row {}
      arp_header_contents:add_child(
         create_obj(obj_textlabel, 'center', 325,0,0,0,'idaht1','',
         'Arpeggiator options',0,vb)
      )      
      distance_row_contents:add_child(
         create_obj(obj_textlabel, '', 140,0,0,0,'iddr1','',
         'Min. distance between notes',0,vb)
      )
      distance_row_contents:add_child(
         create_obj(obj_valuebox, '', 50,0,512,distance_step,'vbox_distance_step',
         'Amount of lines or delay-values before next note is inserted',0,
         function(value) change_distance_step(value, vb)end,vb)
      )
      distance_row_contents:add_child(
         create_obj(obj_popup, '', 37,0,0,popup_distance_mode_index,'popup_distance_mode',
         'Lin = Lines, Del = Delay. Delay requires more notecolumns',{"Lin", "Del"},
         function(value)change_distance_mode(value,vb)end,vb)
      )
      distance_row_contents:add_child(
         create_obj(obj_textlabel, '', 60,0,0,0,'popup_octave_order_text','',
         'Octave order',0,vb)
      )
      distance_row_contents:add_child(
         create_obj(obj_popup, '', 70,0,0,popup_octave_index,'popup_octave_order',
         'Which order should the octave numbers be generated?',
         {"TopDown", "DownTop", "TopDownTop","DownTopDown", "Random"},
         function(value)change_octave_order(value,vb)end,vb)
      )
      distance_row_contents:add_child(
         create_obj(obj_textlabel, 'right', 40,0,0,0,'octave_repeat_mode_text',
         '','Repeat',0,vb)
      )
      distance_row_contents:add_child(
         create_obj(obj_checkbox, '', 18,0,0,repeat_se_octave,'octave_repeat_mode',
         'Repeat first and end sequence of the octave TdT and DtD sequence',0,
         function(value)
            if value == true then
               repeat_se_octave = true
            else
               repeat_se_octave = false
            end
         end,vb)
      )
      termination_row_header_contents:add_child(
         create_obj(obj_textlabel, '', 142,0,0,0,'idtrt4','','Note termination each',
         0,vb)
      )
      termination_row_contents:add_child(
         create_obj(obj_valuebox, '', 50,0,511,termination_step,'vbox_termination_step',
         'Amount of lines or pan/vol fx cut-values',0,
         function(value) set_termination_step(value,vb)end,vb)
      )

      termination_row_contents:add_child(
         create_obj(obj_popup, '', 37,0,0,termination_index,'popup_note_termination_mode',
         "Tck = Ticks will cut (apply note-off) before end of line\n"..
         "Lin = Lines will apply note-off every xx lines",{'Lin', 'Tck'},
         function(value)set_termination_minmax(value,vb)end,vb)
      )
      termination_row_contents:add_child(
         create_obj(obj_textlabel, '', 68,0,0,0,'idtrct1','','Note Order',0,vb)
      )
      termination_row_contents:add_child(
         create_obj(obj_popup, '', 70,0,0,popup_note_index,'popup_note_order',
         'Which order should the notes be generated?',
         {"TopDown", "DownTop", "TopDownTop","DownTopDown", "Random"},
         function(value)change_note_order(value,vb)end,vb)
      )
      termination_row_contents:add_child(
         create_obj(obj_textlabel, 'right', 40,0,0,0,'repeat_note_title','',
         'Repeat',0,vb)
      )
      termination_row_contents:add_child(
         create_obj(obj_checkbox, '', 18,0,0,repeat_se_note,'repeat_note',
         'Repeat first and end sequence of the note scheme TdT and DtD sequence',
         0,function(value)
            if value == true then
               repeat_se_note = true
            else
               repeat_se_note = false
            end                  
         end,vb)
      )
      local arpeggiator_area = vb:column{
         margin = CONTENT_MARGIN,
         spacing = CONTENT_SPACING,
         uniform = true,
         width = "100%",
         vb:horizontal_aligner {
            mode = "justify",
            width = "100%",
            vb:column {
               spacing = 8,
               uniform = true,
               vb:row{
                  vb:column{
                     margin = DIALOG_MARGIN,
                     style = "group",
                     vb:horizontal_aligner {
                        mode = "center",
                        note_header_contents
                     },
                     vb:horizontal_aligner {
                        mode = "left",
                        picker_row_contents,
                     },
                     vb:horizontal_aligner {
                        mode = "left",
                        note_row_contents,
                     },
                     vb:horizontal_aligner {
                        mode = "center",
                        button_row_contents,
                     },
                  },
               },
               vb:row{
                  vb:column{
                     margin = DIALOG_MARGIN,
                     style = "group",
                     vb:horizontal_aligner {
                        mode = "center",
                        arp_header_contents
                     },
                     vb:horizontal_aligner {
                        mode = "left",
                        distance_row_contents,
                     },
                     vb:horizontal_aligner{
                        mode = "left",
                        termination_row_header_contents,
                        termination_row_contents,
                     },
                     vb:row {
                        vb:horizontal_aligner {
                           mode = "left",
                           create_obj(obj_textlabel, '', 90,0,0,0,'idtt1','',
                           'Arpeggio Pattern',0,vb),
                           create_obj(obj_switch, '', 160,0,0,switch_arp_pattern_index,
                           'switch_arp_pattern',
                           "Distance:Place each note straight at minimum distance.\n"..
                           "Random:Place notes on random lines, (keeping minimum distance!).\n"..
                           "Custom:defined in the textfield below.",
                           {"Distance", "Random", "Custom"},
                           function(value)toggle_custom_arpeggiator_profile_visibility(value, vb)end,vb),
                           create_obj(obj_textlabel, '', 66,0,0,0,'idtt2','',
                           'Note cols.',0,vb),
                           create_obj(obj_valuebox, '', 51,1,12,max_note_columns,
                           'max_note_colums',
                           "The maximum amount of note-columns that will be\n"..
                           "generated when using delay-distance",
                           0,function(value)toggle_chord_mode_visibility(value,vb)end,vb),
                           create_obj(obj_textlabel, '', 40,0,0,0,'chord_mode_box_title',
                           '','Chord',0,vb),
                           create_obj(obj_checkbox, '', 18,0,0,chord_mode,
                           'chord_mode_box',
                           'Should all notes be placed in chord mode or keep row-distance between each note?',
                           0,function(value)chord_mode = value end,vb),
                        },
                     },
                     vb:row {
                        create_obj(obj_textlabel, '', 98,0,0,0,'custom_arpeggiator_profile_title',
                        '','Custom pattern',0,vb),
                        create_obj(obj_textfield, '', 330,0,0,custom_arpeggiator_field,
                        'custom_arpeggiator_profile',
                        "each figure represents a line, after the last line\n"..
                        "the pattern restarts using the note-off value as "..
                        "the distance (nt) or minimum\nlines between notes (bn)."..
                        " Undefined means restart directly after the last line",
                        0,function(value)custom_arpeggiator_field = value end,vb),
                     },
                  },
               },
            }
         } 
      }
      local property_area = vb:column {
         margin = CONTENT_MARGIN,
         spacing = CONTENT_SPACING,
         uniform = true,
         vb:column {
            style = "group",
            margin = DIALOG_MARGIN,
            uniform = true,
            vb:row {
               width = 325,
               vb:row {
                  width= ((325)/2)-(65)
               },
               create_obj(obj_textlabel, 'center', 410,0,0,0,'idpatl1','',
               'Instrument & volume pool selection',0,vb),
            },
            vb:row {
               create_obj(obj_textlabel, '', 65,0,0,0,'idpatl2','','Inst. pool',0,vb),
               create_obj(obj_textfield, '', 230,0,0,pinstruments_field,
               'popup_procins',
               "Insert instrument numbers, comma separated. The range of "..
               "00-128 will do,\nhexadecimal notation 0x00 - 0x80 is also fine."..
               "If no instrument is filled in,\nthe current selected instrument"..
               "will be used instead.",
               0,function(value)pinstruments_field = value end,vb),
               create_obj(obj_popup, '', 70,0,0,instrument_insertion_index,
               'popup_ins_insertion','How should instrument numbers be inserted from the pool?',
               {"TopDown", "DownTop", "TopDownTop","DownTopDown", "Random"},
               function(value) change_instrument_insertion(value,vb) end,vb),
               create_obj(obj_textlabel, 'right', 40,0,0,0,'repeat_instrument_title',
               '','Repeat',0,vb),
               create_obj(obj_checkbox, '', 18,0,0,repeat_se_instrument,
               'repeat_instrument',
               'Repeat first and end sequence of the instrument TdT and DtD sequence',
               0,function(value)
                  if value == true then
                     repeat_se_instrument = 0
                  else
                     repeat_se_instrument = 1
                  end                  
               end,vb),
            },
            vb:row{
               create_obj(obj_textlabel, '', 65,0,0,0,'idpatl3','','Volume pool',0,vb),
               create_obj(obj_textfield, '', 230,0,0,pvelocity_field,'popup_procvel',
               "Insert velocity and fx values either hex or decimal.\n".. 
               "If the line remains empty or example then the full volume"..
               " will be used.",
               0,function(value)pvelocity_field = value end,vb),
               create_obj(obj_popup, '', 70,0,0,velocity_insertion_index,
               'popup_vel_insertion','How should velocity layers be inserted from the pool?',
               {"TopDown", "DownTop", "TopDownTop","DownTopDown", "Random"},
               function(value) change_velocity_insertion(value,vb) end,vb),
               create_obj(obj_textlabel, 'right', 40,0,0,0,'repeat_velocity_title',
               '','Repeat',0,vb),
               create_obj(obj_checkbox, '', 18,0,0,repeat_se_velocity,'repeat_velocity',
               'Repeat first and end sequence of the velocity TdT and DtD sequence',
               0,function(value)
                  if value == true then
                     repeat_se_velocity = 0
                  else
                     repeat_se_velocity = 1
                  end                  
               end,vb),
            },
         },
         vb:row {
            create_obj(obj_textlabel, '', TEXT_ROW_WIDTH,0,0,0,'idpatl4','','Which area',0,vb),
            create_obj(obj_chooser, '', 265,0,0,area_to_process,'chooser','',
            {"Selection in track","Track in pattern", "Track in song", "Column in track", "Column in song"},
            function(value) set_area_selection(value,vb) end,vb),
            vb:column{
               vb:row {
                  create_obj(obj_checkbox, '', 18,0,0,skip_fx,'pacbx1',
                  "When checked, pan/vol/delay values will *not* be\n" ..
                  "over written with new values, if they contain "..
                  "an existing value.\n(except old note-cut commands!)",
                  0,function(value)skip_fx = value end,vb),
                  create_obj(obj_textlabel, '', TEXT_ROW_WIDTH,0,0,0,'idpatl6','',
                  'Skip pan/vol/del',0,vb),
               },
               vb:row {
                  create_obj(obj_checkbox, '', 18,0,0,clear_track,'idpacb2',
                  'Clear track before generating new notes',0,
                  function(value) clear_track = value end,vb),
                  create_obj(obj_textlabel, '', TEXT_ROW_WIDTH,0,0,0,'idpatl7',
                  '','Clear track',0,vb),
               },
               vb:row {
                  create_obj(obj_checkbox,'',18,0,0,auto_play_pattern,'idpacb3',
                  'Auto-play created sequence',0,
                  function(value)auto_play_pattern = value end,vb),
                  create_obj(obj_textlabel, '', TEXT_ROW_WIDTH,0,0,0,'idpatl8','',
                  'Auto play result',0,vb),
               },
            },
         },
         vb:space{height = 3*CONTENT_SPACING},
      --- Let's do it!!
         vb:row {
            vb:space {width = 185},
            create_obj(obj_button, '', 60,0,0,0,'idpabu1','','Arpeggiate!',
            function()add_notes(1,1,vb)end,vb),
            vb:space {width = 165,},
      --- Any help?
            create_obj(obj_button, '', 10,0,0,0,'idpabu2','','?',
            function()show_help() end,vb),
         }
      }
      local operation_area = vb:column {
         arpeggiator_area,
         property_area
      }
      local total_layout = vb:column {
         margin = CONTENT_MARGIN,
         spacing = CONTENT_SPACING,
         uniform = true,
      }
      if switch_note_pattern_index == 2 then
         --Make sure the "show matrix" button won't be visible if the main dialog
         --would be closed and then reopened
         total_layout:add_child(operation_area)
      else
         total_layout:add_child(figure_matrix)
         total_layout:add_child(operation_area)
      end
      if switch_arp_pattern_index == 3 then
         toggle_custom_arpeggiator_profile_visibility(3, vb)         
      else
         toggle_custom_arpeggiator_profile_visibility(1, vb)         
      end
      if max_note_columns < 2 then
         toggle_chord_mode_visibility(1,vb)
      else
         toggle_chord_mode_visibility(2,vb)
      end
      if velocity_insertion_index >= 3 and velocity_insertion_index <= 4 then
         vb.views.repeat_velocity.visible = true
         vb.views.repeat_velocity_title.visible = true
      else
         vb.views.repeat_velocity.visible = false
         vb.views.repeat_velocity_title.visible = false
      end      
      if instrument_insertion_index >= 3 and instrument_insertion_index <= 4 then
         vb.views.repeat_instrument.visible = true
         vb.views.repeat_instrument_title.visible = true
      else
         vb.views.repeat_instrument.visible = false
         vb.views.repeat_instrument_title.visible = false
      end
      if popup_note_index >= 3 and popup_note_index <= 4 then
            vb.views.repeat_note.visible = true
            vb.views.repeat_note_title.visible = true
      else
         vb.views.repeat_note.visible = false
         vb.views.repeat_note_title.visible = false
      end
      if popup_octave_index >= 3 and popup_octave_index <= 4 then
         if switch_note_pattern_index == 1 then
            vb.views.octave_repeat_mode.visible = true
            vb.views.octave_repeat_mode_text.visible = true
         else
            toggle_octave_visibility(false, vb)
         end
      else
         vb.views.octave_repeat_mode.visible = false
         vb.views.octave_repeat_mode_text.visible = false
      end
      if switch_note_pattern_index == 1 then
         toggle_note_profile_visibility(false, vb)
         toggle_octave_visibility(true, vb)
      else
         toggle_note_profile_visibility(true, vb)
         toggle_octave_visibility(false, vb)
      end
      if first_show == false then
         toggle_chord_mode_visibility(1,vb)
         toggle_custom_arpeggiator_profile_visibility(1, vb)         
         toggle_note_profile_visibility(false, vb)
         first_show = true
      end
      if (arpeg_option_dialog and arpeg_option_dialog.visible) then
         arpeg_option_dialog:show()
      else 
         arpeg_option_dialog = nil
         arpeg_option_dialog = renoise.app():show_custom_dialog("Epic Arpeggiator", 
         total_layout)
      end
end


-------------------------------------------------------------------------------
---                     Main dialog visibility toggles                     ----
-------------------------------------------------------------------------------
function change_distance_step(value, vb)
   distance_step = value
   if popup_distance_mode_index == 2 then
      vb.views.vbox_distance_step.max = 255
   else
      vb.views.vbox_distance_step.max = 511
   end
end
function change_distance_mode(value,vb)
   popup_distance_mode_index = value
   if value == 2 then
      vb.views.vbox_distance_step.max = 255
      if vb.views.vbox_distance_step.value > 255 then
         vb.views.vbox_distance_step.value = 255
      end
   else
      vb.views.vbox_distance_step.max = 511
   end
end
function change_octave_order(value,vb)
   popup_octave_index = value
   if value >= 3 and value <= 4 then
      vb.views.octave_repeat_mode.visible = true
      vb.views.octave_repeat_mode_text.visible = true
   else
      vb.views.octave_repeat_mode.visible = false
      vb.views.octave_repeat_mode_text.visible = false
   end
end
function set_termination_step(value,vb)
   if termination_index == NOTE_OFF_DISTANCE_TICKS then
      if value > 15 then
         value = 15
      end
      vb.views.vbox_termination_step.max = 14
      vb.views.vbox_termination_step.min = 1
   else
      vb.views.vbox_termination_step.min = 0
      vb.views.vbox_termination_step.max = 511                     
   end
   termination_step = value
end
function set_termination_minmax(value,vb)
   termination_index = value
   if value == NOTE_DISTANCE_DELAY then
      if vb.views.vbox_termination_step.value > 15 then
         vb.views.vbox_termination_step.value = 14
      end
      vb.views.vbox_termination_step.max = 14
      vb.views.vbox_termination_step.min = 1
   else
      vb.views.vbox_termination_step.min = 0
      vb.views.vbox_termination_step.max = 511
   end
end
function change_note_order(value,vb)
   popup_note_index = value
   if value >= PLACE_TOP_DOWN_TOP and value <= PLACE_DOWN_TOP_DOWN then
      vb.views.repeat_note.visible = true
      vb.views.repeat_note_title.visible = true
   else
      vb.views.repeat_note.visible = false
      vb.views.repeat_note_title.visible = false
   end
end
function change_instrument_insertion(value,vb)
   instrument_insertion_index = value
   if value >= PLACE_TOP_DOWN_TOP and value <= PLACE_DOWN_TOP_DOWN then
      vb.views.repeat_instrument.visible = true
      vb.views.repeat_instrument_title.visible = true
   else
      vb.views.repeat_instrument.visible = false
      vb.views.repeat_instrument_title.visible = false
   end
end
function change_velocity_insertion(value,vb)
   velocity_insertion_index = value
   if value >= PLACE_TOP_DOWN_TOP and value <= PLACE_DOWN_TOP_DOWN then
      vb.views.repeat_velocity.visible = true
      vb.views.repeat_velocity_title.visible = true
   else
      vb.views.repeat_velocity.visible = false
      vb.views.repeat_velocity_title.visible = false
   end
end
function set_area_selection(value,vb)
   local chooser = vb.views.chooser
   if value==OPTION_TRACK_IN_SONG or value==OPTION_COLUMN_IN_SONG then
      local seq_status = check_unique_pattern()
      if seq_status== -1 then
         vb.views.chooser.value = area_to_process
      else
         area_to_process = value
         vb.views.chooser.value = value
      end
   else
      area_to_process = value
   end
end
function toggle_custom_arpeggiator_profile_visibility(value, vb)
   switch_arp_pattern_index = value
   if value == ARPEGGIO_PATTERN_CUSTOM then
      value = true
   else         
      value = false
   end

   if value == true then
      vb.views.custom_arpeggiator_profile_title.visible = true
      vb.views.custom_arpeggiator_profile.visible = true
   else
      vb.views.custom_arpeggiator_profile_title.visible = false
      vb.views.custom_arpeggiator_profile.visible = false
   end
end
function toggle_note_profile_visibility(show, vb)
   if show == true then
      vb.views.custom_note_profile_title.visible = true
      vb.views.custom_note_profile.visible = true
   else
      vb.views.custom_note_profile_title.visible = false
      vb.views.custom_note_profile.visible = false
   end
end
function toggle_chord_mode_visibility(value,vb)
   max_note_columns = value
   if value < 2 then
      value = false
   else
      value = true
   end
   if value == true then
      vb.views.chord_mode_box_title.visible = true
      vb.views.chord_mode_box.visible = true
   else
      vb.views.chord_mode_box_title.visible = false
      vb.views.chord_mode_box.visible = false
   end

end
function toggle_octave_visibility(show, vb)
   if show == true then
      vb.views.popup_octave_order_text.visible = true
      vb.views.popup_octave_order.visible = true
      vb.views.octave_repeat_mode_text.visible = true
      local pidx = vb.views.popup_octave_order.value
      if pidx >= PLACE_TOP_DOWN_TOP and pidx <= PLACE_DOWN_TOP_DOWN then
         vb.views.octave_repeat_mode.visible = true
         vb.views.octave_repeat_mode_text.visible = true
      else
         vb.views.octave_repeat_mode.visible = false
         vb.views.octave_repeat_mode_text.visible = false
      end
   else
      vb.views.popup_octave_order_text.visible = false
      vb.views.popup_octave_order.visible = false
      vb.views.octave_repeat_mode_text.visible = false
      vb.views.octave_repeat_mode.visible = false
   end
end
function create_obj(type,pa,pw,pmi,pma,pv,pid,ptt,ptx,pn,vb)
--This is the main GUI creation function
--It is not necessary to have a function like this, you can always embed the below vb:code
--into your source-snippets, this was just a test to see if structurizing it made things
--clearer. The abbreviations obviously do not, but they have been shortened after the program was finished.
--This is what they were named before the program got tagged "finished":
--p stands for Property, id = Identity, a = alignment, w = width, tt = tooltip, tx = text, v = value
--mi = min, ma = max, n = notifier, vb stands for ViewBuilder
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
end

-------------------------------------------------------------------------------
---                     Warning dialog pattern sequence                    ----
-------------------------------------------------------------------------------
function cross_write_dialog(return_val, double, doubles)
   local vb = renoise.ViewBuilder() 
   local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
   local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
   local dialog_title = "Cross-write warning"
   local dialog_content = vb:column { 
      margin = CONTENT_MARGIN,
      spacing = CONTENT_SPACING,
      uniform = true,
      vb:text {
         align="center",
         text = "You have "..#double.." patterns that repeat on "..doubles..
         " positions\n".."If you arpeggiate across the song, you"..
         " might\nunawarely overwrite previously filled areas.\n\nDo you want to"..
         " make the pattern order\nunique in the pattern sequencer?"
      },
      vb:horizontal_aligner{
         mode = "center",
         vb:row{
            spacing = 8,
            create_obj(obj_button, '', 50,0,0,0,'idwdbut1',
            'Making all patterns unique by copying the pattern to a new instance',
            'Make unique',function()
               make_unique_pattern()
               pseq_warn_dialog:close()
               pseq_warn_dialog = nil
               return_val = 0
            end,vb),
            create_obj(obj_button, '', 50,0,0,0,'idwdbut2',
            'reverts to previous area choice','Cancel',function()
               pseq_warn_dialog:close()
               pseq_warn_dialog = nil
            end,vb)
         }
      }
   }
   if (pseq_warn_dialog and pseq_warn_dialog.visible)then
      pseq_warn_dialog:show()
   else
      pseq_warn_dialog = nil
      pseq_warn_dialog = renoise.app():show_custom_dialog(dialog_title,
      dialog_content)
   end
   return return_val
end

-------------------------------------------------------------------------------
---                           Help dialog                                  ----
-------------------------------------------------------------------------------
function show_help()
   local vb = renoise.ViewBuilder()

   local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
   local DIALOG_SPACING = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING

   renoise.app():show_prompt(
      "About Epic Arpeggiator",
            [[
The Epic Arpeggiator allows you to generate notes in different octave ranges and
different note-ranges using different instruments. What is explained here are a 
few things you should know in advance before using this tool Let's start with 
the note matrix:

Each note can be toggled individually. Then you can click on each ">" button and
each "^" button which invert the whole octave or note-row selection. This also
means that what was turned on, will be turned off and vice versa. The "inv" 
button will inverse the complete matrix, similar to what the octave or note-row 
toggle buttons do.

Custom note profile
You can set notes in the note profile, they should all be full notes (meaning:
C-4 or C#4). The note profile offers you to set up note-schemes that the matrix
does not offer you space for. Like percussion patterns with repeative notes on
several places in the sequence.

Fetch from current track
Fetching notes from the current track also depends on the area selection.
If you selected Track from song, it will gather all notes entered in that track
scattered across the whole song. If you only selected an area, only the notes
in the area will be gathered if selection in track has been toggled. The only
exception is fetching notes for the custom note profile where only notes are
fetched from the current pattern or selection.

TopDown, DownTop, etc... -> What are those?
If you are known to arpeggiators, the phrase Up/Down is more common which
ain't much different here:
Note/octave/instrument and velocity queues are placed in blocks depending on the
order. This is how these directions work: Td means order 123 will be repeated as
[123][123]. Dt repeats as [321][321] TdT repeats 123 as [1232][1232] and DtD 
repeats as [3212][3212]. With the TdT and DtD selected, also the repeat 
checkboxes will become available. If you check the repeat box, the first and last
in the order will also be repeated: 123 will then be repeated in TdT as [123321]
[123321] and in DtD as [321123][321123].If you use the tone-matrix, beware that
the order is always oriented from the octave row and then the note. For arbitrary
note orders that the matrix does not put up for you:use the custom note profile
instead.

The arpeggiator options
The minimum distance between notes can be in "lines" or "delay" value. If you 
use the "delay" value, you need to raise the "note cols." valuebox in order to 
make this work. The note-cols value will match the value of the current available
note-columns in the track. If you change this, the change will be directly 
reflected towards the track if you execute the arpeggiation process!  If you 
raise the note columns, the Chord checkbox becomes available, if you check it,
all note-columns on the respective fill-line are filled until the last notecolumn 
has been reached. If you want to create different sized chordprogressions, use 
the custom note-profile for this, however, keep in mind to keep the amount of 
notes per chord exactly the same.If you however are in for some surprises and 
like to experiment with shifted 3-note chord progressions spanned across on 4 or
5 notecolumns or other random outcome, then specially don't use this tool by the
book ;). 


Arpeggio pattern
Custom:places notes according to your personal line-scheme inserted in the text-
line. using nt means closing with a line-termination (note-off or cut defined above)
using bn means uphold the minimum defined distance between the last defined 
row position and the next repetition of your custom pattern. The pattern will be 
repeated until the pattern has been filled out. In song mode only the notes are
shifted across the song, the custom pattern will be restarted from each pattern.
If you do not insert any values in the custom pattern field (leaving the demo 
contents there), distance mode will be automatically selected. You have to add a
pattern. Also, you can't use nt and nb in the same pattern, you also have to close 
your pattern with either "nt" or "bn". If you want your last note directly being 
followed, select bn and set the distance between notes to 00. If you desire 
surprises, attempt to disobey the rules. 

Instrument and volume pool
No instruments or volume values inserted in the textfield result in the current
selected instrument as value and maximum volume as value. You can also insert
the other effect values in the volume pool!


Skip Pan/vol/delay
This function only covers the note distance mode and note termination mode 
routines when note delay and note-cuts are used. When this checkbox is checked, 
the delay column remains untouched if there are existing values. Panning and 
volume columns are not touched by the routine that tries to insert note-cut 
values on either panning or volume column, however fx values filled in the custom 
velocity will always overwrite the existing effect. Ofcourse, the "Clear track" 
checkbox should not be toggled in this case!


                                                                                                                         vV   
]],
      {"OK"}
   )

end
