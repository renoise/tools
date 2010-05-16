--[[----------------------------------------------------------------------------

  Script        : Rubberband.lua
  Creation Date : 2010-05-05
  Last modified : 2010-05-05
  Version       : 0.2

----------------------------------------------------------------------------]]--


if os.platform() == 'MACINTOSH' then
    io.chmod('./bin/osx/rubberband', 755);
end

renoise.tool():add_menu_entry {
  name = "Sample Editor:Process:Timestretch",
  invoke = function()
      show_stretch_dialog()
  end
}

renoise.tool():add_menu_entry {
  name = "Sample Editor:Process:Pitch Shift",
  invoke = function() show_shift_dialog() end
}

function display_error() 
  if os.platform() == 'LINUX' then
    renoise.app():show_prompt('Rubberband missing, or bad command!',
    "To use this feature you must install Rubberband command line utility\n"..
    "On Ubuntu you must install package rubberband-cli, you can do this by\n"..
    "issuing a command: sudo apt-get install rubberband-cli\n\n"..
    "This error may also be triggered when you are trying to make too heavy\n"..
    "stretch which overloads the system, if you are sure you have rubberband\n"..
    "installed then try again with more reasonable input parameters."
    , {'Ok'})
  else
    renoise.app():show_prompt('Something went wrong!',
    "There is something wrong with installation or your system. Try reinstalling\n"..
    "the script or see Renoise error logs for more information.\n"..
    "This error may also be triggered when you are trying to make too heavy\n"..
    "stretch which overloads the system, if you can try again with more\n"..
    "reasonable input parameters."
    , {'Ok'})
  end
end

function process_rubberband(cmd)
  local exe

  if os.platform() == 'WINDOWS' then
    exe = renoise.tool().bundle_path .. 'bin/win32/rubberband.exe'
  elseif os.platform() == 'MACINTOSH' then
    exe = renoise.tool().bundle_path .. 'bin/osx/rubberband'
  else
    exe = 'rubberband'
  end

  local ofile = os.tmpname('wav')
  local ifile = os.tmpname('wav')

  renoise.song().selected_sample.sample_buffer:save_as(ofile, 'wav')

  os.execute(exe .. " " .. cmd .. " "..ofile.." "..ifile);
         
  if not io.exists(ifile) then
    display_error()
    return
  end
          
  renoise.song().selected_sample.sample_buffer:load_from(ifile)
  
  os.remove(ofile)
  os.remove(ifile)
end


function process_stretch(stretch, crisp)
  process_rubberband("--time "..stretch.." --crisp "..crisp);
end

function process_shift(shift, crisp, preserve_formant)
  local cmd = "--pitch "..shift.." --crisp "..crisp;
  if preserve_formant then
    cmd = cmd .. ' -F'
  end
  process_rubberband(cmd);
end

function show_shift_dialog()

  local vb = renoise.ViewBuilder()
  
  local semitone_selector = vb:valuebox { min = -48, max = 48, value = 0 }
  local cent_selector = vb:valuebox { min = -100, max = 100, value = 0 }
  local crisp_selector = vb:popup { 
    items = {'1', '2', '3', '4', '5'},
    value = 4 
  }
  local formant_selector = vb:checkbox {}
  
  local view = 
  vb:vertical_aligner {
    margin = 10,
    vb:horizontal_aligner{
      spacing = 10,
      vb:vertical_aligner{
        vb:text{text = 'Semitones:' },
        semitone_selector,
      },
      vb:vertical_aligner{
        vb:text{text = 'Cents:' },
        cent_selector,
      },
      vb:vertical_aligner{
        vb:text{text = 'Crispness:' },
        crisp_selector
      },
    },
    vb:horizontal_aligner{
      margin = 10,
      spacing = 5,
      formant_selector,
      vb:text{text = 'Preserve formant' },
    }
  }
  
  local res = renoise.app():show_custom_prompt  (
    "Pitch Shift",
    view,
    {'Shift', 'Cancel'}
  );
    
  if res == 'Shift' then
    process_shift(semitone_selector.value + (cent_selector.value / 100), crisp_selector.value, formant_selector.value)
  end;
end

function show_stretch_dialog()
  local bpm = renoise.song().transport.bpm
  local lpb = renoise.song().transport.lpb
  local coef = bpm * lpb / 60.0

  local sel_sample = renoise.song().selected_sample
  local nframes = sel_sample.sample_buffer.number_of_frames
  local srate = sel_sample.sample_buffer.sample_rate

  local slength = nframes / srate
  local rows = slength * coef

  local vb = renoise.ViewBuilder()
  
  local nlines_selector = vb:valuebox { min = 1, value = 16 }
  local crisp_selector = vb:popup { 
    items = {'1', '2', '3', '4', '5'},
    value = 4 
  }
  local type_selector = vb:popup {
    items = {'lines', 'beats', 'seconds'},
    value = 2
  }
  
  local view = vb:horizontal_aligner{
    margin = 10,
    spacing = 10,
    vb:vertical_aligner{
      vb:text{text = 'Length:' },
      nlines_selector,
    },
    vb:vertical_aligner{
      vb:text{text = 'Units:' },
      type_selector,
    },
    vb:vertical_aligner{
      vb:text{text = 'Crispness:' },
      crisp_selector
    },
  }
  
  local res = renoise.app():show_custom_prompt  (
    "Time Stretch",
    view,
    {'Stretch', 'Cancel'}
  );
  
  -- How long we stretch?
  local stime
  if type_selector.value == 1 then
    stime = nlines_selector.value / rows
  elseif type_selector.value == 2 then
    stime = (nlines_selector.value * lpb) / rows
  elseif type_selector.value == 3 then
    stime = nlines_selector.value / slength 
  end;
  
  if res == 'Stretch' then
    process_stretch(stime, crisp_selector.value)
  end;
end

