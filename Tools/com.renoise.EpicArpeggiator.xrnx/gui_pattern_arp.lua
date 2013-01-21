--[[============================================================================
gui_pattern_arp.lua, the complete layout for the pattern arpeggio components.
============================================================================]]--



function note_octave_properties(vb)
  ---------------------------------------------------------------------------
  -- Note profile

  local note_header_contents = vb:row {}
  local picker_row_contents = vb:row {}
  local note_row_contents = vb:row {}
  local button_row_contents = vb:row {margin=5}

  note_header_contents:add_child(
    vb:text {
      align = "center",
      width = 323,
      text = "Custom note profile"
    }
  )      


  note_row_contents:add_child(
    vb:text{
      id='custom_note_profile_title',
      width=119,
      text='Custom note profile'
    }
  )

  note_row_contents:add_child(
    vb:textfield {
      id='custom_note_profile',
      width=309,
      tooltip= 'Figures go from C to B, Octave figures are accepted as well',
      value=custom_note_field,
      notifier=function(value) custom_note_field = value end
    }
  )

  button_row_contents:add_child(
    vb:button {
      id='custom_fetch',
      width=80,
      tooltip='Read all notes in track and copy them into the note-profile',
      text='Fetch from current track',
      notifier=function(value)fetch_notes_from_track(vb)end
    }
  )
  
  local note_and_octave_area = vb:column{
    margin = CONTENT_MARGIN,
    spacing = CONTENT_SPACING,
    width = TOOL_FRAME_WIDTH,
    id='note_and_octave_props',

    vb:horizontal_aligner {
      mode = "justify",
      width = "100%",
      margin=SECTION_MARGIN,
      
      vb:column {
        spacing = 8,

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
      }
    }
  }
  return note_and_octave_area
end



function ins_vol_properties(vb)
  ---------------------------------------------------------------------------
  -- Instrument and velocity pool

  local header_content = vb:row{}
  local ins_pool_content = vb:row{}
  local vel_pool_content = vb:row{}

  header_content:add_child(
    vb:text{
      align='center',
      width=425,
      text='Instrument & volume pool selection'
    }         
  )  
  
  ins_pool_content:add_child(
    vb:text{
      width=65,
      text='Inst. pool'
    }
  )
  ins_pool_content:add_child(
    vb:textfield {
      id='popup_procins',
      width=230,
      tooltip= "Insert instrument numbers, comma separated. The range of "..        
               "00-128 will do,\nhexadecimal notation 0x00 - 0x80 is also fine."..
               "If no instrument is filled in,\nthe current selected instrument"..
               "will be used instead.",
      value=pinstruments_field,
      notifier=function(value)pinstruments_field = value end
    }
  )

  ins_pool_content:add_child(
    vb:popup {
      id='popup_ins_insertion',
      width=70,
      tooltip='How should instrument numbers be inserted from the pool?',
      items={"TopDown", "DownTop", "TopDownTop","DownTopDown", "Random"},
      value=instrument_insertion_index,
      notifier=function(value) change_instrument_insertion(value,vb) end 
    }
  )

  ins_pool_content:add_child(
    vb:text{
      id='repeat_instrument_title',
      align='right',
      width=40,
      text='Repeat'
    }
  )

  ins_pool_content:add_child(
    vb:checkbox {
      id='repeat_instrument',
      width=18,
      tooltip='Repeat first and end sequence of the instrument TdT and DtD sequence',
      value=repeat_se_instrument,
      notifier=function(value)
        if value == true then
          repeat_se_instrument = true
        else
          repeat_se_instrument = false
        end                    
      end
    }
  )

  vel_pool_content:add_child(
    vb:text{
      width=65,
      text='Volume pool'
    }
  )

  vel_pool_content:add_child(
    vb:textfield {
      id='popup_procvel',
      width=230,
      tooltip= "Insert velocity and fx values either hex or decimal.\n".. 
               "If the line remains empty or example then the full volume"..
               " will be used.",
      value=pvelocity_field,
      notifier=function(value)pvelocity_field = value end
    }
  )

  vel_pool_content:add_child(
    vb:popup {
      id='popup_vel_insertion',
      width=70,
      tooltip='How should velocity layers be inserted from the pool?',
      items={"TopDown", "DownTop", "TopDownTop","DownTopDown", "Random"},
      value=velocity_insertion_index,
      notifier=function(value) change_velocity_insertion(value,vb) end 
    }
  )

  vel_pool_content:add_child(
    vb:text{
      id='repeat_velocity_title',
      align='right',
      width=40,
      text='Repeat'
    }
  )

  vel_pool_content:add_child(
    vb:checkbox {
      id='repeat_velocity',
      width=18,
      tooltip='Repeat first and end sequence of the velocity TdT and DtD sequence',
      value=repeat_se_velocity,
      notifier=function(value)
        if value == true then
          repeat_se_velocity = true
        else
          repeat_se_velocity = false
        end                        
      end
    }
  )

  local property_area = vb:column{
    margin = CONTENT_MARGIN,
    spacing = CONTENT_SPACING,
    width = TOOL_FRAME_WIDTH,
    id='ins_vol_props',

    vb:horizontal_aligner {
      mode = "justify",
      width = "100%",
      margin=SECTION_MARGIN,
      
      vb:column {
        spacing = 8,

        vb:row{

          vb:column{
            margin = DIALOG_MARGIN,
            style = "group",

            vb:horizontal_aligner {
              mode = "center",
              header_content
            },

            vb:horizontal_aligner {
              mode = "left",
              ins_pool_content,
            },

            vb:horizontal_aligner {
              mode = "left",
              vel_pool_content,
            },

          },
        },
      }
    }
  }
  change_instrument_insertion(instrument_insertion_index,vb)
  change_velocity_insertion(velocity_insertion_index,vb)
  return property_area
end




function arpeggio_options(vb)
  -------------------------------------------------------------------------
  -- Pattern arpeggio options
  
  local arp_header_contents = vb:row {}
  local distance_row_contents = vb:row {}
  local termination_row_header_contents = vb:column {}
  local termination_row_contents = vb:row {}

  arp_header_contents:add_child(
    vb:text{
      align='center',
      width=425,
      text='Arpeggiator options'
    }
  )      

  distance_row_contents:add_child(
    vb:text{
      width=140,
      text='Min. distance between notes'
    }
  )

  distance_row_contents:add_child(
    vb:valuebox {
      id='vbox_distance_step',
      width=50,
      min=0,
      max=MAX_PATTERN_LINES,
      value=distance_step,
      tooltip='Amount of lines or delay-values before next note is inserted',
      notifier=function(value) change_distance_step(value, vb)end
    }
  )

  distance_row_contents:add_child(
    vb:popup {
      id='popup_distance_mode',
      width=37,
      items={"Lin", "Del"},
      value=popup_distance_mode_index,
      tooltip='Lin = Lines, Del = Delay. Delay requires more notecolumns',
      notifier=function(value)change_distance_mode(value,vb)end
    }
  )

  distance_row_contents:add_child(
    vb:text{
      id='popup_octave_order_text',
      width=60,
      text='Octave order'
    }
  )

  distance_row_contents:add_child(
    vb:popup {
      id='popup_octave_order',
      width=70,
      items= {"TopDown", "DownTop", "TopDownTop","DownTopDown", "Random"},
      value=popup_octave_index,
      tooltip= 'Which order should the octave numbers be generated?',
      notifier=function(value)change_octave_order(value,vb)end
    }
  )

  distance_row_contents:add_child(
    vb:text{
      id='octave_repeat_mode_text',
      align='right',
      width=40,
      text='Repeat'
    }
  )

  distance_row_contents:add_child(
    vb:checkbox {
      id='octave_repeat_mode',
      width=18,
      value=repeat_se_octave,
      tooltip='Repeat first and end sequence of the octave TdT and DtD sequence',
      notifier=function(value)
        if value == true then
          repeat_se_octave = true
        else
          repeat_se_octave = false
        end      
      end
    }
  )

  termination_row_header_contents:add_child(
    vb:text{
      width=142,
      text='Note termination each'
    }
  )

  termination_row_contents:add_child(
    vb:valuebox {
      id='vbox_termination_step',
      width=50,
      min=0,
      max=MAX_PATTERN_LINES,
      value=termination_step,
      tooltip='Amount of lines or pan/vol fx cut-values',
      notifier=function(value) set_termination_step(value,vb)end
    }
  )

  termination_row_contents:add_child(
    vb:popup {
      id='popup_note_termination_mode',
      width=37,
      items={'Lin', 'Tck'},
      value=termination_index,
      tooltip="Tck = Ticks will cut (apply note-off) before end of line\n"..
              "Lin = Lines will apply note-off every xx lines",
      notifier=function(value)set_termination_minmax(value,vb)end
    }
  )

  termination_row_contents:add_child(
    vb:text{
      width=68,
      text='Note Order'
    }
  )

  termination_row_contents:add_child(
    vb:popup {
      id='popup_note_order',
      width=70,
      items={"TopDown", "DownTop", "TopDownTop","DownTopDown", "Random"},
      value=popup_note_index,
      tooltip='Which order should the notes be generated?',
      notifier=function(value)change_note_order(value,vb)end
    }
  )

  termination_row_contents:add_child(
    vb:text{
      id='repeat_note_title',
      align='right',
      width=40,
      text='Repeat'
    }
  )
  termination_row_contents:add_child(
    vb:checkbox {
      id='repeat_note',
      width=18,
      value=repeat_se_note,
      tooltip='Repeat first and end sequence of the note scheme TdT and DtD sequence',
      notifier=function(value)
        if value == true then
          repeat_se_note = true
        else
          repeat_se_note = false
        end      
      end
    }
  )

  local arpeggiator_area = vb:column{
    margin = CONTENT_MARGIN,
    spacing = CONTENT_SPACING,
    uniform = true,
    width = TOOL_FRAME_WIDTH,
    id='arpeggiator_options',
    vb:horizontal_aligner {
      mode = "justify",
      width = "100%",

      vb:column {
        spacing = 8,
        uniform = true,

        vb:row{
          margin=SECTION_MARGIN,
          
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

                vb:text{
                  width=90,
                  text='Arpeggio Pattern'
                },
                vb:switch {
                  id='switch_arp_pattern',
                  width=160,
                  items={"Distance", "Random", "Custom"},
                  value=switch_arp_pattern_index,
                  tooltip="Distance:Place each note straight at minimum distance.\n"..
                  "Random:Place notes on random lines, (keeping minimum distance!).\n"..
                  "Custom:defined in the textfield below.",
                  notifier=function(value)toggle_custom_arpeggiator_profile_visibility(value, vb)end
                },
                vb:text{
                  width=66,
                  text='Note cols'
                },
                vb:valuebox {
                  id='max_note_colums',
                  width=51,
                  min=1,
                  max=MAX_NOTE_COLUMNS,
                  value=max_note_columns,
                  tooltip="The maximum amount of note-columns that will be\n"..
                          "generated when using delay-distance",
                  notifier=function(value)toggle_chord_mode_visibility(value,vb)end
                },
                vb:text{
                  id='chord_mode_box_title',
                  width=40,
                  text='Chord'
                },
                vb:checkbox {
                  id='chord_mode_box',
                  width=18,
                  value=chord_mode,
                  tooltip="Should all notes be placed in chord mode or "..
                          "keep row-distance between each note?",
                  notifier=function(value)chord_mode = value end
                }
              }
            },

            vb:row {
              id='custom_arpeggiator_layout',
              vb:text{
                id='custom_arpeggiator_profile_title',
                width=98,
                text='Custom pattern'
              },
              vb:textfield {
                id='custom_arpeggiator_profile',
                width=327,
                value=custom_arpeggiator_field,
                tooltip="each figure represents a line, after the last line\n"..
                        "the pattern restarts using the note-off value as "..
                        "the distance (nt) or minimum\nlines between notes (bn)."..
                        " Undefined means restart directly after the last line",
                notifier=function(value)custom_arpeggiator_field = value end
              }
            }
          }
        }
      }
    } 
  }
  change_octave_order(popup_octave_index,vb)
  change_note_order(popup_note_index,vb)
  toggle_chord_mode_visibility(max_note_columns,vb)
  toggle_custom_arpeggiator_profile_visibility(switch_arp_pattern_index, vb)
  return arpeggiator_area
end



function application_area(vb)
  -------------------------------------------------------------------------
  -- Area of application

  local application_area = vb:column {
    vb:row {
      vb:text{
        align='right',
        width=TEXT_ROW_WIDTH,
        text='Which area'
      },
      vb:chooser {
        id='chooser',
        width=247,
        items= {"Selection in track","Track in pattern", "Track in song",
                "Column in track", "Column in song"},
        value=area_to_process,
        notifier=function(value) set_area_selection(value,vb) end
      },
      vb:column{

        vb:row {
          vb:checkbox {
            width=18,
            value=skip_fx,
            tooltip="When checked, pan/vol/delay values will *not* be\n" ..
                    "over written with new values, if they contain "..
                    "an existing value.\n(except old note-cut commands!)",
            notifier=function(value)skip_fx = value end
          },
          vb:text {
            width=TEXT_ROW_WIDTH,
            text='Skip pan/vol/del'
          }
        },
        vb:row {
          vb:checkbox {
            width=18,
            value=overwrite_alias,
            tooltip="When checked, alias tracks will be overwritten\n" ..
                    "NOT supported with track in song and "..
                    "column in song!!!",
            notifier=function(value)overwrite_alias = value end
          },
          vb:text {
            width=TEXT_ROW_WIDTH,
            text='Overwrite Alias'
          }
        },
        vb:row {
          vb:checkbox {
            width=18,
            value=clear_track,
            tooltip='Clear area before generating new notes',
            notifier=function(value) clear_track = value end
          },
          vb:text {
            width=TEXT_ROW_WIDTH,
            text='Clear area'
          }
        },
        vb:row {
           vb:checkbox {
            width=18,
            value=auto_play_pattern,
            tooltip='Auto-play created sequence',
            notifier=function(value)auto_play_pattern = value end
          },
          vb:text {
            width=TEXT_ROW_WIDTH,
            text='Auto play result'
          }
        }
      }
    }
  }
  

  local property_area = vb:column{
    margin = CONTENT_MARGIN,
    spacing = CONTENT_SPACING,
    width = TOOL_FRAME_WIDTH,
    id='application_area',
    vb:horizontal_aligner {
      mode = "justify",
      width = "100%",
      margin=SECTION_MARGIN,
      vb:column {
        vb:row{
          vb:column{
            margin = DIALOG_MARGIN,
            style = "group",

            vb:horizontal_aligner {
              mode = "center",
              application_area
            }
          }
        }
      }
    }
  }
  return property_area
end



function preset_management(vb)
  -------------------------------------------------------------------------
  -- Preset management
  
  local preset_area=vb:column {
    vb:row {
      vb:text {
        width=TEXT_ROW_WIDTH,
        text='Preset'
      },
      vb:popup {
        id='popup_preset',
        width=235,
        items=pat_preset_list,
        value=1,
        tooltip="Select previously saved preset\n",
        notifier=function(value)pat_preset_field = value end
      },
      vb:space {width = 10,},
      vb:button {
        width=10,
        text='Load',
        tooltip='Load selected preset / '..
                'refresh presetlist (if you  have added new preset files)',
        notifier=function()
          local preset_file = vb.views.popup_preset.items[vb.views.popup_preset.value]
          load_preset(preset_file,PATTERN,vb)
        end
      },
      vb:button {
        width=10,
        text='Save',
        tooltip='Save current configuration',
        notifier=function()save_dialog(PATTERN,vb)end
      },
      vb:button {
        width=10,
        text='Loc',
        tooltip='Show preset-folder'..
                ' location in platform explorer',
        notifier=function()show_folder(PATTERN)end
      }
    }
  }

  local property_area = vb:column{
    margin = CONTENT_MARGIN,
    spacing = CONTENT_SPACING,
    width = TOOL_FRAME_WIDTH,
    id='preset_area',
    vb:horizontal_aligner {
      mode = "justify",
      width = "100%",
      margin=SECTION_MARGIN,
      vb:column {
        vb:row{
          vb:column{
            margin = DIALOG_MARGIN,
            style = "group",

            vb:horizontal_aligner {
              mode = "center",
              preset_area
            }
          }
        }
      }
    }
  }  
  return property_area
end




function note_matrix_properties(vb)
  -------------------------------------------------------------------------
  -- Tone Matrix

  -- Defining the matrix dialog frame
  local figure_matrix = vb:column {
    margin = CONTENT_MARGIN,
    uniform = true,
    style = "border",
  }

  -- header column
  local header_content = vb:row {}
  header_content:add_child(
    vb:space {
      width = CHECKBOX_WIDTH + 40
    }
  )
  -- Creating a dynamic header for each note
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
        vb:text{
          id='id_note'..tostring(note),
          width=ALTERED_WIDTH,
          text=note_matrix[note]
        }
      }
    )

  end

  --Gathering the header content into the main matrix frame
  figure_matrix:add_child(header_content)

  --Building octave text & note checkbox columns
  local done_content = vb:column {}

  for octave = 1,NUM_OCTAVES do

    local area_content = vb:row {
    }

    -- octave text
    area_content:add_child(
      vb:row{
        vb:text{
          id='id_oct'..tostring(octave),
          width=CHECKBOX_WIDTH,
          text=tostring(octave-1)
        },
        vb:button {
          id='id_but'..tostring(octave),
          width=CHECKBOX_WIDTH,
          text='>',
          notifier=function() toggle_octave_row(vb, octave) end
        }
      }
    )

    -- Building dynamic note checkboxes
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
        vb:checkbox {
          id=note_id,
          width=CHECKBOX_WIDTH,
          tooltip=note_tooltip,
          value=note_state(octave, note),
          notifier=function(value)set_note_state(octave, note, value)end
        }
      )
    end
    done_content:add_child(area_content)
     
  end

  local ntrigger_area = vb:row {}

  -- Building generic matrix trigger checkboxes (to toggle all checkboxes)
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
      vb:button {
        id='id_butt'..tostring(tbutton),
        width=CHECKBOX_WIDTH,
        tooltip = btooltip,
        text=btext,
        notifier=function() set_all_row_state(vb, btext) end
      }
    )

    ntrigger_area:add_child(trigger_content)

  end

  -- Building individual note/octave trigger checkboxes
  for note = 1, NUM_NOTES do
    local note_tooltip
    local trigger_content = vb:column {}

    if string.find(note_matrix[note], "#") then
      note_tooltip = note_matrix[note]
    else
      note_tooltip = note_matrix[note]
    end

    trigger_content:add_child(
      vb:button {
        id='id_butn'..tostring(note),
        width=CHECKBOX_WIDTH,
        tooltip=note_tooltip,
        text='^',
        notifier=function() toggle_note_row(vb, note) end
      }
    )

    ntrigger_area:add_child(trigger_content)

  end
  local fetch_button = vb:horizontal_aligner{
    mode='center',
    margin=8,
    vb:row{
      vb:button {
        id='custom_fetch_matrix',      
        width=80,
        tooltip='Read all notes in track and select them in the matrix',
        text='Fetch from current track',
        notifier=function(value)fetch_notes_from_track(vb)end
      }  
    }
  }
  -- Adding note header row, octave side-column, triggers and matrix into one layout
  local matrix_layout = vb:column{
    done_content,
    ntrigger_area,
    fetch_button
  }      

  -- Adding layout to matrix dialog frame
  figure_matrix:add_child(matrix_layout)

    local matrix_area = vb:column{
    margin = 2,
    width = TOOL_FRAME_WIDTH,
    id='complete_matrix',

    vb:horizontal_aligner {
      mode = "justify",
      width = "100%",

      vb:column {
        vb:row{
          vb:column{
            margin = SECTION_MARGIN,
            style = "group",

            vb:horizontal_aligner {
              mode = "center",
              figure_matrix
            },
          },
        },
      }
    }
  }
   
  return matrix_area
end



function profile_selection(vb)
  -------------------------------------------------------------------------
  -- Note profile selection switch:Tone matrix or custom note profile?
  
  local picker_row_area = vb:horizontal_aligner{mode='center', margin=2, id='profile_selection'}
  local picker_row_contents = vb:column {}
  

  -- Note matrix or note profile?
  picker_row_contents:add_child(
    vb:horizontal_aligner{
      mode='center',
      vb:row{
        vb:text{
          text='Applied profile'
        }
      }
    }
  )

  picker_row_contents:add_child(
    vb:horizontal_aligner{
      mode='center',
      vb:row{
        vb:switch{
          id='switch_note_pattern',
          width=160,
          tooltip= "Matrix (pgUp):Pick note and octave order from the note-matrix.\n"..
          "Custom (pgDn):defined in the textfields below.",
          items={"Matrix", "Custom"},
          value=switch_note_pattern_index,
          notifier= function(value)
            switch_note_pattern_index = value
            toggle_note_matrix_visibility(value)
          end
        }
      }
    }
  )
  picker_row_area:add_child(picker_row_contents)
  
  return picker_row_area
end



function pattern_arp_executor(vb)
  -------------------------------------------------------------------------
  -- Pattern arpeggio execution area (push the button!)

  local pattern_arp_action=vb:column {
    vb:row {
      vb:button {
        text='Arpeggiate!',
        notifier=function()
          local seq_status = 0
        
          if vb.views.chooser.value == 3 or vb.views.chooser.value == 5 then
            seq_status = check_unique_pattern(vb)
          end
  
          if seq_status == 0 then
            add_notes(1,1,vb)
            note_pool = {} 
            noteoct_pool = {} 
            octave_pool = {}
            instrument_pool = {}
            velocity_pool = {}
          end
        end
      }
    }
  }
  
  local property_area = vb:column{
    width = TOOL_FRAME_WIDTH,
    id='pat_execution_area',
    vb:horizontal_aligner {
      mode = "justify",
      width = "100%",
      margin=2,
      vb:column {
        vb:row{
          vb:column{
            margin = DIALOG_MARGIN,
 --           style = "group",

            vb:horizontal_aligner {
              mode = "center",
              pattern_arp_action
            }
          }
        }
      }
    }
  }  
  return property_area
end



--------------------------------------------------------------------------------
--      End of teh road...
--------------------------------------------------------------------------------

