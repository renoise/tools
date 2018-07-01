--[[===============================================================================================
  Testcase for xAudioDeviceAutomation
===============================================================================================]]--

_xlib_tests:insert({
  name = "xAudioDeviceAutomation",
  fn = function()
  
    LOG(">>> xAudioDeviceAutomation: starting unit-test...")
  
    --require (_clibroot.."cDocument")
    --require (_xlibroot.."xMessage")
    --require (_xlibroot.."xTrack")
    --require (_xlibroot..'xAudioDevice')
    --require (_xlibroot.."xPatternSequencer")
    --require (_xlibroot.."xParameterAutomation")
    cLib.require (_xlibroot.."xAudioDeviceAutomation")
    
    _trace_filters = {"^xAudioDevice*","^xParameter*"}
      
    -----------------------------------------------------------------------------------------------
    -- prepare
    -----------------------------------------------------------------------------------------------

    local src_patt_idx = 1
    local src_track_idx = 1
    local src_track = rns.tracks[src_track_idx]
    local src_device = nil
    local dest_device = nil
    
    -- create devices and some automation across a couple of patterns...

    local prepare = function ()
      print(">>> prepare")

      -- create two patterns 

      local patt1_idx = rns.sequencer:insert_new_pattern_at(1)
      local patt2_idx = rns.sequencer:insert_new_pattern_at(2)
      local patt1 = rns.patterns[patt1_idx]
      local patt2 = rns.patterns[patt2_idx]
      patt1.name = "xAudioDeviceAutomation test #1"
      patt2.name = "xAudioDeviceAutomation test #2"
      patt2.number_of_lines = 128

      -- create a (sequencer-)track 

      local name_of_test_track = "xAudioDeviceAutomation test"
      local src_patt = rns.selected_pattern
      local trk_auto = nil

      src_track = rns:insert_track_at(src_track_idx)
      src_track.name = name_of_test_track
      assert(src_track.type == renoise.Track.TRACK_TYPE_SEQUENCER)

      -- create devices 

      src_device = src_track:insert_device_at("Audio/Effects/Native/*XY Pad",2)
      dest_device = src_track:insert_device_at("Audio/Effects/Native/*XY Pad",3)

      local xy_param_1 = xAudioDevice.get_parameter_by_name(src_device,"X-Axis")
      local xy_param_2 = xAudioDevice.get_parameter_by_name(src_device,"Y-Axis")

      -- create automation 

      -- pattern #1
      local ptrack = patt1.tracks[src_track_idx]    
      local xy_auto_1 = ptrack:create_automation(xy_param_1)
      xy_auto_1:add_point_at(1, 0.5)
      xy_auto_1:add_point_at(5, 1.0)
      xy_auto_1:add_point_at(9, 0.0)
      local xy_auto_2 = ptrack:create_automation(xy_param_2)
      xy_auto_2:add_point_at(2.0, 0.5)
      xy_auto_2:add_point_at(2.1, 1.0)
      xy_auto_2:add_point_at(2.5, 0.0)
      
      -- pattern #2
      local ptrack = patt2.tracks[src_track_idx]  
      local xy_auto_1 = ptrack:create_automation(xy_param_1)
      xy_auto_1:add_point_at(10, 0.5)
      xy_auto_1:add_point_at(15, 1.0)
      xy_auto_1:add_point_at(19, 0.0)
      local xy_auto_2 = ptrack:create_automation(xy_param_2)
      xy_auto_2:add_point_at(12.0, 0.5)
      xy_auto_2:add_point_at(12.1, 1.0)
      xy_auto_2:add_point_at(12.5, 0.0)
      
      
    end

    local str_msg = "The xAudioDeviceAutomation test will modify the song - do you want to proceed?"
    local choice = renoise.app():show_prompt("Unit test",str_msg,{"OK","Cancel"})
    if (choice == "OK") then
      prepare()
    else
      return
    end
  
    -----------------------------------------------------------------------------------------------
    -- run tests
    -----------------------------------------------------------------------------------------------

    -- seq-range for the first few tests: use the patterns we just created
    local src_range = {
      start_sequence = 1,
      start_line = 1,
      end_sequence = 2,
      end_line = 64,
    }
    print("src_range",rprint(src_range))
    
    local src_device_idx = xTrack.get_device_index(src_track,src_device)
    local dest_device_idx = xTrack.get_device_index(src_track,dest_device)
    print("src_device_idx",src_device_idx)
    print("dest_device_idx",dest_device_idx)

    -- copy/paste between two identical devices 
    -- (src range spans two patterns, pasting should use src range)

    local device_auto = 
      xAudioDevice.copy_automation(src_track_idx,src_device_idx,src_range)
    
    local success,err = 
      xAudioDevice.paste_automation(device_auto,src_track_idx,dest_device_idx,src_range)
    assert(success,err) -- ?? why no logging of err 

    -- copy/paste between incompatible devices (should fail)
    --[[

    local device_auto = xAudioDevice.copy_automation(src_track_idx,src_device_idx)
    print("device_auto",device_auto)

    local dest_device_idx = 1 -- assume!! mixer device 
    local success,err = xAudioDevice.paste_automation(device_auto,src_track_idx,dest_device_idx)
    print(err)
    assert(not success,err)

    -- test restricted range (copy/paste middle of pattern)
    local src_range = {
      start_sequence = 1,
      start_line = 17,
      end_sequence = 1,
      end_line = 32,
    }
    print("src_range",rprint(src_range))

    local dest_device_idx = xTrack.get_device_index(src_track,dest_device)
    local device_auto = xAudioDevice.copy_automation(src_track_idx,src_device_idx,src_range)
    local success,err = xAudioDevice.paste_automation(device_auto,src_track_idx,dest_device_idx)
    print(err)
    assert(success,err) -- ?? why no logging of err 


    -- TODO copy/paste with offset (copy middle, paste to last quarter - overlap with patt#2)
    local dest_range = {
      start_sequence = 1,
      start_line = 49,
      end_sequence = 2,
      end_line = 16,
    }
    ]]

    -- TODO copy/paste while transforming length of automated data 

  
    LOG(">>> xAudioDeviceAutomation: OK - passed all tests")
  
  end
  })
  