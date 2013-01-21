--[[============================================================================
gui_envelope_arp.lua, the complete layout for the envelope arpeggio components.
============================================================================]]--



function envelope_pattern_editor(vb)
  local env_pattern_header = vb:row {}
  --local env_pattern_line = vb:row {}
  local env_pattern_track = vb:column {}
  local env_pattern_control = vb:row {}
  local env_pattern_fetch = vb:row {}
  local env_pattern_sync = vb:row {}

  env_pattern_header:add_child(
    vb:button {
      id='envelope_sync_mode',
      tooltip='Switch edit-step mode between lines or points?',
      text=row_frequency_text[row_frequency_step],
      notifier=function(value)
        if row_frequency_step == FREQ_TYPE_POINTS then
          row_frequency_step = FREQ_TYPE_LINES
          ea_gui.views['envelope_sync_mode'].text = 'lines'
        else
          row_frequency_step = FREQ_TYPE_POINTS
          ea_gui.views['envelope_sync_mode'].text = 'pnts'
        end
        preferences.row_frequency_step.value = row_frequency_step
        preferences:save_as("preferences.xml")
      end
    }
  )
  env_pattern_header:add_child(
    vb:space { width=3 }
  )

  env_pattern_header:add_child(
    vb:button {
      id='envelope_note_toggle',
      width=46,
      tooltip='Toggle between note or tone registration',
      text='Note',
      notifier=function()
        save_undo_state('toggled note mode '..tostring(note_mode))
        note_mode = not note_mode
        if note_mode then
          ea_gui.views['envelope_note_toggle'].text = "Note"
          convert_note_value_tables() --prevent wrong factor values being attempted to convert to notes.
          ea_gui.views['env_multiplier'].value = ENV_X100
          ea_gui.views['env_multiplier'].active = false
        else
          ea_gui.views['envelope_note_toggle'].text = "Tone"
          ea_gui.views['env_multiplier'].active = true
          ea_gui.views['line_sync_correct'].visible = false
        end
        populate_columns()
      end
    } 
  )
--  env_pattern_header:add_child(
--    vb:space { width=4 }
--  )
  env_pattern_header:add_child(
    vb:button {
      id='envelope_volume_toggle',
      width=30,
      tooltip='Toggle volume envelope support',
      text='Vol',
      notifier=function()
        envelope_volume_toggle = not envelope_volume_toggle
        toggle_pan_vol_color()
        if env_auto_apply and change_from_tool == false then
          apply_table_to_envelope()
        end        
      end
    }
  )
  env_pattern_header:add_child(
    vb:button {
      id='envelope_panning_toggle',
      tooltip='Toggle panning envelope support',
      text='Pan',
      notifier=function()
        envelope_panning_toggle = not envelope_panning_toggle
        toggle_pan_vol_color()
        if env_auto_apply and change_from_tool == false then
          apply_table_to_envelope()
        end        
      end
    }
  )

  for t = 0, visible_lines-1 do
    local env_edit_pos = t+line_position_offset
    env_pattern_line[t] = vb:row {}

      env_pattern_line[t]:add_child(
        vb:space { width=4 }
      )
      env_pattern_line[t]:add_child(
        vb:text {
          id='track_position_'..tostring(t),
          height = ROW_HEIGHT,
          text = string.format("%04d", env_edit_pos)
        }  
      )
      env_pattern_line[t]:add_child(
        vb:space { width=4 }
      )
      env_pattern_line[t]:add_child(
        vb:button {
          id='note_pos_'..tostring(t),
          width=46,
          height = ROW_HEIGHT,
          color = note_pos_color[t],
          tooltip = '[Shift-S]: Set loop start, [Shift-E]: Set loop end\n[Cmd-S]: Set sustain, [a]: Set end marker'..
                    '\nMidi-keyboard/computer keyboard: set note',
          text='---',
          notifier=function(value)
            env_current_line.row = t
            env_current_line.col = 1
            set_cursor_location()
          end
        }
      )

      env_pattern_line[t]:add_child(
        vb:button {
          id='vol_pos_'..tostring(t),
          width = 30,
          height = ROW_HEIGHT,
          color = vol_pos_color[t],
          tooltip = '[Shift-S]: Set loop start, [Shift-E]: Set loop end\n[Cmd-S]: Set sustain, [a]: Set end marker'..
                    '\n(Numpad) figures: enter volume value 0 to 100',
          text='..',
          notifier=function(value)
            env_current_line.row = t
            env_current_line.col = 2
            set_cursor_location()
          end
        }
      )

      env_pattern_line[t]:add_child(
        vb:button {
          id='pan_pos_'..tostring(t),
          width = 30,
          height = ROW_HEIGHT,
          color = pan_pos_color[t],
          tooltip = '[Shift-S]: Set loop start, [Shift-E]: Set loop end\n[Cmd-S]: Set sustain, [a]: Set end marker'..
                    '\n(Numpad) figures: enter panning value -50 to 50',
          text='..',
          notifier=function(value)
            env_current_line.row = t
            env_current_line.col = 3
            set_cursor_location()
          end
        }
      )
    env_pattern_track:add_child(env_pattern_line[t])
  end
  
  env_pattern_control:add_child(
    vb:space { width=10 }
  )
  env_pattern_control:add_child(
    vb:valuefield {
      id='env_visible_lines',
      width=20,
      tooltip='Amount of lines to show',
      min = 5,
      max = 50,
      value = visible_lines,
      tostring = function(value)
        if value > 50 then
          value = 50
        end
        if value < 5 then
          value = 5
        end
        return string.format('%02d',value)
      end,
      tonumber = function(value)
        if tonumber(value) > 50 then
          value = 50
        end
        if tonumber(value) < 5 then
          value = 5
        end
        return tonumber(value)
      end,
      notifier=function(value)
        visible_lines = value
        preferences.opt_visible_lines.value = value
        preferences:save_as("preferences.xml")
        tool_dialog:close()
        open_main_dialog(2,1)
        line_position_offset = 0
        env_current_line.row = 0
        set_cursor_location()
      end
    }
  )
  env_pattern_control:add_child(
    vb:space { width=6 }
  )

  env_pattern_control:add_child(
    vb:button {
      id='envelope_note_loop_toggle',
      width=44,
      tooltip='Toggle pitch loop mode',
      text=ENV_LOOP_TYPE[note_loop_type],
      notifier=function()
        if note_loop_type < 4 then
          note_loop_type = note_loop_type + 1
        else
          note_loop_type = 1
        end
        if env_auto_apply and change_from_tool == false then
          configure_envelope_loop()
        end
        vb.views['envelope_note_loop_toggle'].text = ENV_LOOP_TYPE[note_loop_type]
      end
    }
  )
  env_pattern_control:add_child(
    vb:button {
      id='envelope_volume_loop_toggle',
      width=30,
      tooltip='Toggle volume loop mode',
      text=ENV_LOOP_TYPE[vol_loop_type],
      notifier=function()
        if vol_loop_type < ENV_LOOP_PINGPONG then
          vol_loop_type = vol_loop_type + 1
        else
          vol_loop_type = ENV_LOOP_OFF
        end
        if env_auto_apply and change_from_tool == false then
          configure_envelope_loop()
        end
        vb.views['envelope_volume_loop_toggle'].text = ENV_LOOP_TYPE[vol_loop_type]
      end
    }
  )
  env_pattern_control:add_child(
    vb:button {
      id='envelope_panning_loop_toggle',
      width=30,
      tooltip='Toggle panning loop mode',
      text=ENV_LOOP_TYPE[pan_loop_type],
      notifier=function()
        if pan_loop_type < ENV_LOOP_PINGPONG then
          pan_loop_type = pan_loop_type + 1
        else
          pan_loop_type = ENV_LOOP_OFF
        end
        if env_auto_apply and change_from_tool == false then
          configure_envelope_loop()
        end
        vb.views['envelope_panning_loop_toggle'].text = ENV_LOOP_TYPE[pan_loop_type]
      end
    }
  )



  env_pattern_sync:add_child(
    vb:text {
      width=36,
      text='Sync',
    }
  )


  env_pattern_sync:add_child(
    vb:valuefield {
      id='sync_pitch_column',
      width=44,
      tooltip='Synchronize to xx pattern lines',
      min = 0,
      max = 64,
      value = note_freq_val,
      tostring = function(value) 
        if value == 0 then
          return 'no'
        else
          return tostring(value)
        end
      end,
      tonumber = function(str) 
        if str == 'no' then
          return 0
        else 
          return tonumber(str)
        end
      end,      
      notifier=function(value)
        if value > 0 then
         save_undo_state('changed note-sync from '..tostring(value)..' lines')

         env_sync_mode = true
         change_line_sync(ENV_NOTE_COLUMN,value)
        end
      end
    }
  )

  env_pattern_sync:add_child(
    vb:valuefield {
      id='sync_vol_column',
      width=30,
      tooltip='Synchronize to xx pattern lines',
      min = 0,
      max = 64,
      value = vol_freq_val,
      tostring = function(value) 
        if value == 0 then
          return 'no'
        else
          return tostring(value)
        end
      end,
      tonumber = function(str) 
        if str == 'no' then
          return 0
        else 
          return tonumber(str)
        end
      end,      
      notifier=function(value)
        if value > 0 then
         save_undo_state('changed vol-sync from '..tostring(value)..' lines')
         env_sync_mode = true
         change_line_sync(ENV_VOL_COLUMN,value)
        end
      end
    }
  )
  env_pattern_sync:add_child(
    vb:valuefield {
      id='sync_pan_column',
      width=30,
      tooltip='Synchronize to xx pattern lines',
      min = 0,
      max = 64,
      value = pan_freq_val,
      tostring = function(value) 
        if value == 0 then
          return 'no'
        else
          return tostring(value)
        end
      end,
      tonumber = function(str) 
        if str == 'no' then
          return 0
        else 
          return tonumber(str)
        end
      end,      
      notifier=function(value)
        if value > 0 then
         save_undo_state('changed pan-sync from '..tostring(value)..' lines')
         env_sync_mode = true
         change_line_sync(ENV_PAN_COLUMN,value)
        end
      end
    }
  ) 




  env_pattern_fetch:add_child(
    vb:space { width = 36}
  )
  env_pattern_fetch:add_child(
    vb:button {
      width=44,
      id='fetch_notes',
      tooltip='Fetch values from pitch envelope',
      text='fetch',
      notifier=function()
        note_fetcher()
      end
    }
  )

  env_pattern_fetch:add_child(
    vb:button {
      width=30,
      id='fetch_volume',
      tooltip='Fetch values from volume envelope',
      text='fch',
      notifier=function()
        vol_fetcher()
      end
    }
  )
  env_pattern_fetch:add_child(
    vb:button {
      width=30,
      id='fetch_panning',
      tooltip='Fetch values from panning envelope',
      text='fch',
      notifier=function()
        pan_fetcher()
      end
    }
  ) 
 
  
  local scheme_area = vb:column{
    margin = CONTENT_MARGIN,
    spacing = CONTENT_SPACING,
    width = TOOL_FRAME_WIDTH,
    id='envelope_track',

    vb:horizontal_aligner {
      mode = "left",
      width = "100%",
      margin=SECTION_MARGIN,
      
      vb:column {
        spacing = 2,

        vb:row{

          vb:column{
            margin = DIALOG_MARGIN,
            style = "group",

            vb:horizontal_aligner {
              mode = "left",
              env_pattern_header
            },

            vb:horizontal_aligner {
              mode = "left",
              env_pattern_track,
            },

            vb:horizontal_aligner {
              mode = "left",
              env_pattern_control,
            },
            vb:horizontal_aligner {
              mode = "left",
              env_pattern_sync,
            },
            vb:horizontal_aligner {
              mode = "left",
              env_pattern_fetch,
            },

          },
        },
      },
      vb:column{
        id='right_column',
        vb:vertical_aligner {
          id='envelope_profile',
--          mode='left',
          vb:row{
            vb:space{width=2},
            arpeggio_properties(vb),
          },
        },
        vb:vertical_aligner {
          id='envelope_options',
--          mode='left',
          vb:space{height=2},
          vb:row{
            vb:space{width=2},
            envelope_arpeggio_options(vb),
          },
        },
        vb:vertical_aligner {
          id='envelope_preset_area',
--          mode='left',
          vb:space{height=2},
          vb:row{
            vb:space{width=2},
            envelope_preset_management(vb),
          },
        },
      }
    }
  }
  return scheme_area
    
end


---------------------------------------------------------------------------------------

function arpeggio_properties(vb)
  ---------------------------------------------------------------------------
  -- Envelope Arpeggio profile
  local scheme_header_contents = vb:row {}
  local ins_row_contents = vb:row {}
  local scheme_row_contents = vb:row {}
  local tone_factor_contents = vb:row {}
  local tone_scope_contents = vb:row {}
  local tone_sync_contents = vb:row {}


  scheme_header_contents:add_child(
    vb:text {
      align = "center",
      width = 100,
      text = "Pitch scheme properties"
    }
  )      

  ins_row_contents:add_child(
    vb:text{
      width=119,
      text='Selected instrument'
    }
  )
  ins_row_contents:add_child(
    vb:popup {
      id='instrument_selection',
      width=175,
      items={'none'},
      tooltip= 'instrument to apply the envelope arpeggio on...',
      value=processing_instrument,
--[[
      tostring = function(value) 
        return renoise.song().instruments[value].name
      end,
      tonumber = function(str) 
        return tonumber(str)
      end,      
--]]
      notifier=function(value) 
        --We are not synchronizing instrument selection changes
        --from Renoise back to this tool!
        set_envelope_notifiers(value)
        processing_instrument = value
        renoise.song().selected_instrument_index = value
      end
    }
  )

  scheme_row_contents:add_child(
    vb:text{
      width=119,
      text='Pitch scheme'
    }
  )

  tone_factor_contents:add_child(
    vb:text{
      width=119,
      text='Tone factor'
    }
  )

  tone_factor_contents:add_child(
    vb:switch {
      id='env_multiplier',
      width=175,
      tooltip='set the multiplication factor to apply on the arpeggio scheme figures',
      items={'x1','x10','x100'},
      value = env_multiplier,
      notifier=function(value)
        save_undo_state('changed multiplier factor from option '..tostring(env_multiplier))
        env_multiplier = value 
        set_pitch_table()
      end
    }
  )

  tone_scope_contents:add_child(
    vb:text{
      width=119,
      tooltip = 'If changing the scope beneath the -1200 or over the 1200,\n'..
                'the transpose is affected for all samples!',
      text='Tone scope (transpose!)'
    }
  )
  tone_scope_contents:add_child(
    vb:slider{
      id='tone_scope_slider',
      width=100,
      min = -24,
      max = 0,
      value = tone_scope_offset,
      tooltip = 'If changing the scope beneath the -1200 or over the 1200,\n'..
                'the transpose is affected for all samples!',
      notifier = function(value)
        if grace_turn == 0 then
          no_undo = false
          save_undo_state('Adjusted tone-scope from '..tostring(tone_scope_offset))
          grace_wait = os.clock()
        end
        if grace_turn ~= 1 then
          grace_wait = os.clock()
          grace_turn = 1 --Yeps, only store the initial tone_scope_offset value
        end
        no_undo = true
        if change_from_tool == false then
          tone_scope_correction = tone_scope_offset
          tone_scope_offset = math.floor(value)
        end
        alter_transpose()
        if skip_tone_scope_low == false then
          skip_tone_scope_slider = true
          vb.views['tone_scope_low'].value = value * 100
          skip_tone_scope_slider = false
        end
        no_undo = false
      
      end
    }
  )
  tone_scope_contents:add_child(
    vb:valuefield{
      id='tone_scope_low',
      width=32,
      tooltip = 'Default envelope range is -1200 to 1200.'..
                ' If you need to raise or lower the scope\nthen this will change the sample transpose'..
                ' to enlarge the range',
      min = -2400,
      max = 0,
      value = -1200,
      tostring = function(value)
        value = math.floor(value/100) * 100
        return tostring(value)
      end,
      tonumber = function(value)
        value = tonumber(math.floor(value/100) * 100)
        if tonumber(value) > 0 then
          return 0
        end
        if tonumber(value) < -2400 then
          return -2400
        end
        return tonumber(value)
        
      end,
      notifier = function (value)
        save_undo_state('Adjusted tone-scope from '..tostring(tone_scope_offset))

        if skip_tone_scope_low == false then
          local high = vb.views['tone_scope_high'].value
          value = math.floor(value/100)
          if skip_tone_scope_slider == false then
            skip_tone_scope_low = true
            vb.views['tone_scope_slider'].value = value
            skip_tone_scope_low = false
          end
          
          value = value*100
          local difference = math.abs(value - high)
          skip_tone_scope_high = true
          vb.views['tone_scope_high'].value = value + 2400
          skip_tone_scope_high = false
        else
          skip_tone_scope_low = false
        end
      end
    }
  )
  tone_scope_contents:add_child(
    vb:text{
      width=12,
      text='to'
    }
  )
  tone_scope_contents:add_child(
    vb:valuefield{
      id='tone_scope_high',
      width=28,
      tooltip = 'Default envelope range is -1200 to 1200.'..
                ' If you need to raise or lower the scope\nthen this will change the sample transpose'..
                ' to enlarge the range',
      min = 0,
      max = 2400,
      value = 1200,
      tostring = function(value)
        value = math.floor(value/100) * 100
        return tostring(value)
      end,
      tonumber = function(value)
        value = tonumber(math.floor(value/100) * 100)
        if tonumber(value) < 0 then
          return 0
        end
        if tonumber(value) > 2400 then
          
          return 2400
        end
        return tonumber(value)
      end,
      notifier = function (value)
        save_undo_state('Adjusted tone-scope from '..tostring(tone_scope_offset))

        if skip_tone_scope_high == false then
          local low = vb.views['tone_scope_low'].value
          if value < 0 then
            value = 0
          end
          if value > -2400 then
            value = 2400
          end
          value = math.floor(value/100)
          value = value*100
          local difference = math.abs(value - low)
          skip_tone_scope_low = true
          vb.views['tone_scope_low'].value = value - 2400         
          skip_tone_scope_low = false       
        else
          skip_tone_scope_high = false
        end
        
      end
    }
  )
 
  tone_sync_contents:add_child(
    vb:text{
      width=119,
      tooltip = 'When adjusting the sample transpose, the pitch scheme\n'..
                'is automatically adjusted to the opposite direction',
      text='Adjust pitch scheme'
    }
  )   
  tone_sync_contents:add_child(
    vb:checkbox{
      id='transpose_pitch_scheme',
      width=18,
      value = transpose_pitch_scheme,
      tooltip = 'When adjusting the sample transpose, the pitch scheme\n'..
                'is automatically adjusted to the opposite direction',
      notifier = function(value)
        transpose_pitch_scheme = value
        if change_from_tool == false then
          set_pitch_table()
        end
      end
    }
  )    
  tone_sync_contents:add_child(
    vb:space{width=18}
  )
  tone_sync_contents:add_child(
    vb:button {
      id='line_sync_correct',
      width=60,
      tooltip='If you use an incompatible LPB value, this button is visible.\n'..
              'If you click it, the LPB will be changed to a compatible value and\n'..
              'the bpm is also automatically adjusted to maintain the same tempo',
      visible = false,
      text='Set compatible LPB/BPM?',
      notifier=function(value) sample_envelope_line_sync(true) end
    }
  )

  local scheme_area = vb:column{
  --  margin = CONTENT_MARGIN,
    spacing = CONTENT_SPACING,
    --width = TOOL_FRAME_WIDTH,
    --id='envelope_profile',

    vb:horizontal_aligner {
      mode = "left",
      width = "100%",
   --   margin=SECTION_MARGIN,
      
      
      vb:column {
        spacing = 0,

        vb:row{

          vb:column{
            margin = DIALOG_MARGIN,
            style = "group",

            vb:horizontal_aligner {
              mode = "center",
              scheme_header_contents
            },

            vb:horizontal_aligner {
              mode = "left",
              ins_row_contents,
            },

            vb:horizontal_aligner {
              mode = "left",
              tone_factor_contents,
            },
            vb:horizontal_aligner {
              mode = "left",
              tone_scope_contents,
            },
            vb:horizontal_aligner {
              mode = "left",
              tone_sync_contents,
            },
          },
        },
      }
    }
  }
  return scheme_area
end


---------------------------------------------------------------------------------------

function set_low_scope(tone_scope_low,vb)
   vb.views['tone_scope_low'].value = tone_scope_low
end


---------------------------------------------------------------------------------------

function envelope_arpeggio_options(vb)
  ---------------------------------------------------------------------------
  -- Envelope arpeggio options

  local arp_header_contents = vb:row {}
  local arp_sync_contents = vb:row {id='env_sync_mode'}
  local arp_note_loop_contents = vb:row {}
  local arp_volume_loop_contents = vb:row {}
  local arp_panning_loop_contents = vb:row {}
  local arp_volume_header = vb:row {}
  local arp_volume_value_contents = vb:row {}
  local arp_volume_position_contents = vb:row {}
  local arp_panning_header = vb:row {}
  local arp_panning_value_contents = vb:row {}
  local arp_panning_position_contents = vb:row {}

  arp_header_contents:add_child(
    vb:text {
      align = "center",
      width = 294,
      text = "Assistant tools"
    }
  )      

  arp_sync_contents:add_child(
    vb:button {
      id='lsc',
      width=60,
      tooltip='If you use an incompatible LPB value, this button is visible.\n'..
              'If you click it, the LPB will be changed to a compatible value and\n'..
              'the bpm is also automatically adjusted to maintain the same tempo',
      visible = false,
      text='Auto-set compatible LPB/BPM?',
      notifier=function(value) sample_envelope_line_sync(true) end
    }
  )

  arp_note_loop_contents:add_child(
    vb:text{
      width=119,
      text='Auto Note Loop'
    }
  )  
  arp_note_loop_contents:add_child(
    vb:switch {
      id='auto_note_loop',
      width=50,
      items={'Off','On'},
      tooltip= 'You want your arpeggio to be auto-looped?\n'..
               '"On" means forward the arpeggio direction.',
      value=auto_note_loop,
      notifier=function(value)
        if value ~= ARP_MODE_OFF then
          save_undo_state('Turned on auto-note-loop')
        end
 
        auto_note_loop = value
        if auto_note_loop ~= ARP_MODE_OFF then
          ea_gui.views['envelope_note_loop_toggle'].active = false
          if change_from_tool == false and note_scheme_size > 0 then
            configure_envelope_loop()
          end
        else
          ea_gui.views['envelope_note_loop_toggle'].active = true
        end
      end
    }
  )  

  arp_note_loop_contents:add_child(
    vb:space{
      width=8
    }
  )  

  arp_note_loop_contents:add_child(
    vb:text{
      width=40,
      text='Chord spacing'
    }
  ) 

  arp_note_loop_contents:add_child(
    vb:space{
      width=8
    }
  )  

  arp_note_loop_contents:add_child(
    vb:valuefield {
      id='note_chord_spacing',
      width=32,
      min = 1,
      max = 24,
      value=1,
      tooltip= 'The point spacing to set for pattern-fetched chords',
      value=note_chord_spacing,
      tostring = function(value)
        value = math.round(value)
        return tostring(value)
      end,
      tonumber = function(value)
        value = math.round(tonumber(value))
        if tonumber(value) < 1 then
          return 1
        end
        if tonumber(value) > sample_envelope_line_sync(false)-1 then
          --Spacing may never superseed the amount of lines that is being grabbed.
          return sample_envelope_line_sync(false)-1
        end
        return tonumber(value)
      end,      
      notifier=function(value) 
        note_chord_spacing = value
      end
    }
  )

  arp_volume_loop_contents:add_child(
    vb:text{
      width=119,
      text='Auto Volume Loop'
    }
  )  
  arp_volume_loop_contents:add_child(
    vb:switch {
      id='auto_vol_loop',
      width=50,
      items={'Off','On'},
      tooltip= 'You want your arpeggio to be auto-looped?\n'..
               '"On" means forward the arpeggio direction.',
      value=auto_vol_loop,
      notifier=function(value) 
        if value ~= ARP_MODE_OFF then
          save_undo_state('Turned on auto-volume-loop')
        end
        auto_vol_loop = value
        if auto_vol_loop ~= ARP_MODE_OFF then
          ea_gui.views['envelope_volume_loop_toggle'].active = false
          if change_from_tool == false and vol_scheme_size > 0 then
            configure_envelope_loop()
          end
        else
          ea_gui.views['envelope_volume_loop_toggle'].active = true
        end
      end
    }
  )  
  arp_volume_loop_contents:add_child(
    vb:space{
      width=8
    }
  )  

  arp_volume_loop_contents:add_child(
    vb:text{
      width=40,
      text='Auto Pulse'
    }
  )  

  arp_volume_loop_contents:add_child(
    vb:switch {
      id='vol_pulse_mode',
      width=50,
      items={'Off','On'},
      tooltip= 'You want your arpeggio to be auto-looped?\n'..
               '"On" means forward the arpeggio direction.',
      value=vol_pulse_mode,
      notifier=function(value)
        if vol_pulse_mode == ARP_MODE_OFF then
          save_undo_state('Turned on volume pulse mode')
        end
        vol_pulse_mode = value
        if vol_pulse_mode ~= ARP_MODE_OFF and change_from_tool == false then
          change_from_tool = true
            construct_envelope_pulse(ENV_VOL_COLUMN)
          change_from_tool = false
        end
      end
    }
  )  


  arp_panning_loop_contents:add_child(
    vb:text{
      width=119,
      text='Auto Panning Loop'
    }
  )  
  arp_panning_loop_contents:add_child(
    vb:switch {
      id='auto_pan_loop',
      width=50,
      items={'Off','On'},
      tooltip= 'You want your arpeggio to be auto-looped?\n'..
               '"On" means forward the arpeggio direction.',
      value=auto_pan_loop,
      notifier=function(value) 
        if value ~= ARP_MODE_OFF then
          save_undo_state('Turned on auto-panning loop')
        end
        auto_pan_loop = value
        if auto_pan_loop ~= ARP_MODE_OFF then
          ea_gui.views['envelope_panning_loop_toggle'].active = false
          if change_from_tool == false and pan_scheme_size > 0 then
            configure_envelope_loop()
          end
        else
          ea_gui.views['envelope_panning_loop_toggle'].active = true
        end
      end
    }
  )  
  arp_panning_loop_contents:add_child(
    vb:space{
      width=8
    }
  )  

  arp_panning_loop_contents:add_child(
    vb:text{
      width=40,
      text='Auto Pulse'
    }
  )  

  arp_panning_loop_contents:add_child(
    vb:switch {
      id='pan_pulse_mode',
      width=50,
      items={'Off','On'},
      tooltip= 'You want your arpeggio to be auto-looped?\n'..
               '"On" means forward the arpeggio direction.',
      value=pan_pulse_mode,
      notifier=function(value)
        if value ~= ARP_MODE_OFF then
          save_undo_state('Turned on panning pulse mode')
        end
       
        pan_pulse_mode = value
        if pan_pulse_mode ~= ARP_MODE_OFF and change_from_tool == false then
          change_from_tool = true
            construct_envelope_pulse(ENV_PAN_COLUMN)
          change_from_tool = false
        end
      end
    }
  )  


  arp_volume_header:add_child(
    vb:text {
      align = "left",
      width = 294,
      text = "[Volume Pulse Configuration]"
    }
  )   
  arp_volume_value_contents:add_child(
    vb:text{
      width=119,
      text='Hi-val'
    }
  )  
  arp_volume_value_contents:add_child(
    vb:valuebox {
      id='vol_assist_high_val',
      width=50,
      min = 0,
      max = 100,
      value=0,
      tooltip= 'The high value to set',
      value=vol_assist_high_val,
      tostring = function(value)
        value = math.round(value)
        return tostring(value)
      end,
      tonumber = function(value)
        value = math.round(tonumber(value))
        if tonumber(value) < 0 then
          return 0
        end
        if tonumber(value) > 100 then
          
          return 100
        end
        return tonumber(value)
      end,      
      notifier=function(value) 
        vol_assist_high_val = value
        if change_from_tool == false then
          construct_envelope_pulse(ENV_VOL_COLUMN)
        end
      end
    }
  )  
  arp_volume_value_contents:add_child(
    vb:space{
      width=8
    }
  )  
  arp_volume_value_contents:add_child(
    vb:text{
      width=20,
      text='Lo-val'
    }
  )  
  arp_volume_value_contents:add_child(
    vb:valuebox {
      id='vol_assist_low_val',
      width=50,
      min = 0,
      max = 100,
      value=0,
      tooltip= 'The low value to set',
      value=vol_assist_low_val,
      tostring = function(value)
        value = math.round(value)
        return tostring(value)
      end,
      tonumber = function(value)
        value = math.round(tonumber(value))
        if tonumber(value) < 0 then
          return 0
        end
        if tonumber(value) > 100 then
          
          return 100
        end
        return tonumber(value)
      end,      
      notifier=function(value) 
        vol_assist_low_val = value
        if change_from_tool == false then
          construct_envelope_pulse(ENV_VOL_COLUMN)
        end
      end
    }
  )  


  arp_volume_position_contents:add_child(
    vb:text{
      width=119,
      text='Hi-pulse size'
    }
  )  
  arp_volume_position_contents:add_child(
    vb:valuebox {
      id='vol_assist_high_size',
      width=58,
      min = 0,
      max = 512,
      tooltip= 'The size value to set',
      value=vol_assist_high_size,
      tostring = function(value)
        value = math.round(value)
        if value == 0 then
          return "Auto"
        else
          return tostring(value)
        end
      end,
      tonumber = function(value)
        value = math.round(tonumber(value))
        if tonumber(value) < 0 then
          return 0
        end
        if tonumber(value) > 512 then
          
          return 512
        end
        return tonumber(value)
      end,      
      notifier=function(value) 
        vol_assist_high_size = value
        if change_from_tool == false then
          construct_envelope_pulse(ENV_VOL_COLUMN)
        end
      end
    }
  ) 
  arp_volume_position_contents:add_child(
    vb:text{
      width=20,
      text='Points'
    }
  )  


  arp_panning_header:add_child(
    vb:text {
      align = "left",
      width = 294,
      text = "[Panning Pulse Configuration]"
    }
  ) 


  arp_panning_value_contents:add_child(
    vb:text{
      width=119,
      text='First side val'
    }
  )  
  arp_panning_value_contents:add_child(
    vb:valuebox {
      id='pan_assist_first_val',
      width=50,
      min = -50,
      max = 50,
      tooltip= 'The first value to set',
      value=pan_assist_first_val,
      tostring = function(value)
        value = math.round(value)
        return tostring(value)
      end,
      tonumber = function(value)
        value = math.round(tonumber(value))
        if tonumber(value) < -50 then
          return -50
        end
        if tonumber(value) > 50 then
          
          return 50
        end
        return tonumber(value)
      end,      
      notifier=function(value) 
        pan_assist_first_val = value
        if change_from_tool == false then
          construct_envelope_pulse(ENV_PAN_COLUMN)
        end
        
      end
    }
  )  
  arp_panning_value_contents:add_child(
    vb:space{
      width=8
    }
  )  
  arp_panning_value_contents:add_child(
    vb:text{
      width=20,
      text='Next side val'
    }
  )  
  arp_panning_value_contents:add_child(
    vb:valuebox {
      id='pan_assist_second_val',
      width=50,
      min =-50,
      max = 50,
      value=0,
      tooltip= 'The second value to set',
      value=pan_assist_next_val,
      tostring = function(value)
        value = math.round(value)
        return tostring(value)
      end,
      tonumber = function(value)
        value = math.round(tonumber(value))
        if tonumber(value) < -50 then
          return -50
        end
        if tonumber(value) > 50 then
          
          return 50
        end
        return tonumber(value)
      end,      
      notifier=function(value) 
        pan_assist_next_val = value
        if change_from_tool == false then
          construct_envelope_pulse(ENV_PAN_COLUMN)
        end
      end
    }
  )  


  arp_panning_position_contents:add_child(
    vb:text{
      width=119,
      text='First side size'
    }
  )  
  arp_panning_position_contents:add_child(
    vb:valuebox {
      id='pan_assist_first_size',
      width=58,
      min = 0,
      max = 512,
      tooltip= 'The size value to set',
      value=pan_assist_first_size,
      tostring = function(value)
        value = math.round(value)
        if value == 0 then
          return "Auto"
        else
          return tostring(value)
        end
      end,
      tonumber = function(value)
        value = math.round(tonumber(value))
        if tonumber(value) < 0 then
          return 0
        end
        if tonumber(value) > 512 then
          
          return 512
        end
        return tonumber(value)
      end,      
      notifier=function(value) 
        pan_assist_first_size = value
        if change_from_tool == false then
          construct_envelope_pulse(ENV_PAN_COLUMN)
        end
      end
    }
  ) 
  arp_panning_position_contents:add_child(
    vb:text{
      width=20,
      text='Points'
    }
  ) 


  local arp_conf_area = vb:column{
    --margin = CONTENT_MARGIN,
    spacing = CONTENT_SPACING,
    --width = TOOL_FRAME_WIDTH,
    --id='envelope_options',

    vb:horizontal_aligner {
      mode = "justify",
      width = "100%",
      margin=0,
      
      vb:column {
        spacing = 8,

        vb:row{

          vb:column{
            margin = DIALOG_MARGIN,
            style = "group",

            vb:horizontal_aligner {
              mode = "center",
              arp_header_contents ,
            },         

            vb:horizontal_aligner {
              mode = "left",
              arp_note_loop_contents
            },
            vb:horizontal_aligner {
              mode = "left",
              arp_volume_loop_contents
            },
            vb:horizontal_aligner {
              mode = "left",
              arp_panning_loop_contents
            },
            vb:horizontal_aligner {
              mode = "left",
              arp_volume_header
            },
            vb:horizontal_aligner {
              mode = "left",
              arp_volume_value_contents
            },
            vb:horizontal_aligner {
              mode = "left",
              arp_volume_position_contents
            },
            vb:horizontal_aligner {
              mode = "left",
              arp_panning_header
            },
            vb:horizontal_aligner {
              mode = "left",
              arp_panning_value_contents
            },
            vb:horizontal_aligner {
              mode = "left",
              arp_panning_position_contents
            },
          },
        },
      }
    }
  }
  return arp_conf_area
end


---------------------------------------------------------------------------------------

function envelope_preset_management(vb)
  -------------------------------------------------------------------------
  -- Envelope Preset management
  
  local preset_area=vb:column {
    vb:row {
      vb:text {
--        width=TEXT_ROW_WIDTH,
        text='Preset'
      },
      vb:space{width=10},
      vb:popup {
        id='env_popup_preset',
        width=212,
        items=env_preset_list,
        value=1,
        tooltip="Select previously saved preset\n",
        notifier=function(value)env_preset_field = value end
      },
      vb:button {
        width=10,
        text='Load',
        tooltip='Load selected preset / '..
                'refresh presetlist (if you  have added new preset files)',
        notifier=function()
          local env_preset_file = vb.views.env_popup_preset.items[vb.views.env_popup_preset.value]
          local undo_mode = enable_undo
          enable_undo = false
            load_preset(env_preset_file,ENVELOPE,vb)
          enable_undo = undo_mode
        end
      },      
    },
    vb:horizontal_aligner {
      mode="left",
      vb:row{

        vb:button {
          width=10,
          text='Loc',
          tooltip='Show preset-folder'..
                  ' location in platform explorer',
          notifier=function()show_folder(ENVELOPE)end
        },
        vb:space {width=16},
        vb:button {
          width=10,
          id='vol_lfo_data',
          text='VoL',
          tooltip='Apply stored Volume LFO data',
          color = bool_button[vol_lfo_data],
          notifier=function()
            vol_lfo_data = not vol_lfo_data 
            ea_gui.views['vol_lfo_data'].color = bool_button[vol_lfo_data]
          end
        },
        vb:button {
          width=10,
          id='pan_lfo_data',
          text='PaL',
          tooltip='Apply stored Panning LFO data',
          color = bool_button[pan_lfo_data],
          notifier=function()
            pan_lfo_data = not pan_lfo_data 
            ea_gui.views['pan_lfo_data'].color = bool_button[pan_lfo_data]
          end
        },
        vb:button {
          width=10,
          id='note_lfo_data',
          text='PiL',
          tooltip='Apply stored Pitch LFO data',
          color = bool_button[note_lfo_data],
          notifier=function()
            note_lfo_data = not note_lfo_data 
            ea_gui.views['note_lfo_data'].color = bool_button[note_lfo_data]
          end
        },
        vb:button {
          width=10,
          id='cutoff_data',
          text='Cut',
          tooltip='Apply stored Cutoff envelope data',
          color = bool_button[cutoff_data],
          notifier=function()
            cutoff_data = not cutoff_data 
            ea_gui.views['cutoff_data'].color = bool_button[cutoff_data]
          end
        },
        vb:button {
          width=10,
          id='resonance_data',
          text='Res',
          tooltip='Apply stored Resonance envelope data',
          color = bool_button[resonance_data],
          notifier=function()
            resonance_data = not resonance_data 
            ea_gui.views['resonance_data'].color = bool_button[resonance_data]
          end
        },
        vb:button {
          width=10,
          id='cut_lfo_data',
          text='CuL',
          tooltip='Apply stored Cutoff LFO data',
          color = bool_button[cut_lfo_data],
          notifier=function()
            cut_lfo_data = not cut_lfo_data 
            ea_gui.views['cut_lfo_data'].color = bool_button[cut_lfo_data]
          end
        },
        vb:button {
          width=10,
          id='res_lfo_data',
          text='ReL',
          tooltip='Apply stored Resonance LFO data',
          color = bool_button[res_lfo_data],
          notifier=function()
            res_lfo_data = not res_lfo_data 
            ea_gui.views['res_lfo_data'].color = bool_button[res_lfo_data]
          end
        },
        vb:button {
          width=10,
          text='Save',
          tooltip='Save current configuration',
          notifier=function()
            get_current_data()
            save_dialog(ENVELOPE,vb)
          end
        },
      } 
    }
  }

  local property_area = vb:column{
--    margin = CONTENT_MARGIN,
  --  spacing = CONTENT_SPACING,
    --width = 310,
    --id='envelope_preset_area',
    vb:horizontal_aligner {
      mode = "justify",
      width = "100%",
      margin=0,
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


---------------------------------------------------------------------------------------

function envelope_arp_executor(vb)
  -------------------------------------------------------------------------
  -- Pattern arpeggio execution area (push the button!)

  local pattern_arp_action=vb:column {

    vb:row {
      vb:button {
        id='env_auto_apply',
        text='Apply changes',
        tooltip = 'Click: Synchronize changes\nShift-click: Toggle auto sync mode',
        color=COLOR_THEME,
        notifier=function()
          if key_state == 2 or key_state == 16 then
            env_auto_apply = not env_auto_apply
            if env_auto_apply == true then
              apply_table_to_envelope()
              if preset_version == "3.15" then
                apply_unattended_properties()        
              end
            end
          else 
            if preset_version == "3.15" then
              apply_unattended_properties()        
            end

            if not env_auto_apply then
              env_auto_apply = true
                apply_table_to_envelope()
              env_auto_apply = false
            else
              apply_table_to_envelope()
            end
          end
          if env_auto_apply or key_state == 2 or key_state == 16 then
            vb.views['env_auto_apply'].color = bool_button[env_auto_apply]
            vb.views['env_auto_apply'].text = "Auto-sync changes"
          else
            vb.views['env_auto_apply'].text = "Apply changes"
            vb.views['env_auto_apply'].color = COLOR_THEME
          end
        end
      }
    }
  }
  
  local property_area = vb:column{
    width = TOOL_FRAME_WIDTH,
    id='env_execution_area',
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
