--[[============================================================================
main.lua
============================================================================]]--

if os.platform() == 'MACINTOSH' then
    io.chmod(renoise.tool().bundle_path .. 'bin/osx/rubberband', 755);
end


--------------------------------------------------------------------------------
-- tool registration
--------------------------------------------------------------------------------


renoise.tool():add_menu_entry {
  name = "Sample Editor:Process:Change tempo...",
  invoke = function()
      show_tempochange_dialog()
  end
}


renoise.tool():add_menu_entry {
  name = "Sample Editor:Process:Timestretch...",
  invoke = function()
      show_stretch_dialog()
  end
}

renoise.tool():add_menu_entry {
  name = "Sample Editor:Process:Pitch Shift...",
  invoke = function() show_shift_dialog() end
}

--------------------------------------------------------------------------------
-- processing
--------------------------------------------------------------------------------

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


--------------------------------------------------------------------------------

function process_rubberband(cmd)
  local exe

  if os.platform() == 'WINDOWS' then
    exe = '"' .. renoise.tool().bundle_path .. 'bin/win32/rubberband.exe"'
  elseif os.platform() == 'MACINTOSH' then
    exe = '"' .. renoise.tool().bundle_path .. 'bin/osx/rubberband"'
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


--------------------------------------------------------------------------------

function process_stretch(stretch, crisp, bool_precise)
  if stretch > 100 then
    local conf = renoise.app():show_prompt('Too big stretch!', 'You want to multiply sample length by '.. stretch ..'! Doing this may freeze Renoise for several minutes or even indefinitely. Are you sure you want to continue?', {'Sure', 'No way!'});
    if conf ~= 'Sure' then
      return
    end
  end

  local cmd = "--time "..stretch.." --crisp "..crisp;
  if bool_precise then
    cmd = cmd .. ' -P'
  end
  process_rubberband(cmd);
end



--------------------------------------------------------------------------------

function process_shift(shift, crisp, preserve_formant)
  local cmd = "--pitch "..shift.." --crisp "..crisp;
  if preserve_formant then
    cmd = cmd .. ' -F'
  end
  process_rubberband(cmd);
end


--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

function show_shift_dialog()

  local vb = renoise.ViewBuilder()

  local semitone_selector = vb:valuebox { min = -48, max = 48, value = 0 }
  local cent_selector = vb:valuebox { min = -100, max = 100, value = 0 }
  local crisp_selector = vb:popup {
    items = {'1', '2', '3', '4', '5', '6'},
    value = 5
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


--------------------------------------------------------------------------------
function show_stretch_dialog()
  local bpm = renoise.song().transport.bpm
  local lpb = renoise.song().transport.lpb
  local coef = bpm * lpb / 60.0
  local real_duration = 16
  local sel_sample = renoise.song().selected_sample
  local nframes = sel_sample.sample_buffer.number_of_frames
 
  -- local nframes = sel_sample.sample_buffer.selection_end - sel_sample.sample_buffer.selection_start + 1
  -- Will study the selection handling bit later
 
  local srate = sel_sample.sample_buffer.sample_rate

  local slength = nframes / srate
  local rows = slength * coef
  
  local bool_precise = false
  
  local vb = renoise.ViewBuilder()
  
  local crisp_selector = vb:popup {
    width = 180,
    items = {'Piano', 'Smooth', 'Balanced multitimbral mixture', 'Unpitched percussion with stable notes', 'Crisp monophonic instrumental', 'Unpitched solo percussion'},
    value = 5
  }
  local type_selector = vb:popup {
    items = {'lines', 'beats', 'seconds', 'percent'},
    value = 2
  }

  local nlines_selector = 
      vb:textfield {
      id = 'txtDuration',
      tooltip = "The desired duration",
      align = "right",
      width = 90,
      value = tostring(real_duration),
      notifier = function(real_value)
        real_duration = tonumber(real_value)
      end      
  }

  local view = 

  vb:column
  {
    vb:horizontal_aligner
    {
      margin = 5,
      spacing = 10,
      mode = "center",
      nlines_selector,
      type_selector,
    },
    vb:horizontal_aligner
    {
      margin = 5,
      spacing = 10,
      mode = "center",
      crisp_selector,
    },
    vb:horizontal_aligner
    {
      margin = 3,
      spacing = 10,
      mode = "center",
      vb:checkbox {
        id = "chkPrecise",
        value = bool_precise,
        notifier = function(boolean_value)
           bool_precise = boolean_value
        end
      },
      vb:text { text = 'Minimal time distortion' },
    }
  }

  local res = renoise.app():show_custom_prompt  (
    "Time Stretch",
    view,
    {'Stretch', 'Cancel'}
  );
  
  if res ~= 'Stretch' then return end

  -- How long we stretch?
  local real_stretch_factor

  -- calculate factor from desired time
  if type_selector.value == 1 then
    real_stretch_factor = real_duration / rows -- Lines
  elseif type_selector.value == 2 then
    real_stretch_factor = (real_duration * lpb) / rows -- Beats
  elseif type_selector.value == 3 then
    real_stretch_factor = real_duration / slength -- Seconds
  elseif type_selector.value == 4 then
    real_stretch_factor = real_duration / 100 -- Percentage
  end
  
  process_stretch(real_stretch_factor, crisp_selector.value, bool_precise)
end
--------------------------------------------------------------------------------

local from_dur = 120
function show_tempochange_dialog()
  local bool_precise = false
  local to_dur = renoise.song().transport.bpm
  
  local vb = renoise.ViewBuilder()
  
  local crisp_selector = vb:popup {
    width = 180,
    items = {'Piano', 'Smooth', 'Balanced multitimbral mixture', 'Unpitched percussion with stable notes', 'Crisp monophonic instrumental', 'Unpitched solo percussion'},
    value = 5
  }
  
  local type_selector = vb:popup {
    items = {'lines', 'beats', 'seconds', 'percent'},
    value = 2
  }

  local from_selector = vb:textfield {
    id = 'txtFrom',
    tooltip = "From",
    align = "right",
    width = 40,
    value = tostring(from_dur),
    notifier = function(real_value)
      from_dur = tonumber(real_value)
    end      
  }
  
  local to_selector = vb:textfield {
    id = 'txtTo',
    tooltip = "To",
    align = "right",
    width = 40,
    value = tostring(to_dur),
    notifier = function(real_value)
      to_dur = tonumber(real_value)
    end      
  }

  local view = vb:column {
    vb:horizontal_aligner{
      margin = 5,
      spacing = 10,
      mode = "center",
      from_selector,
      to_selector,
    },
    vb:horizontal_aligner {
      margin = 5,
      spacing = 10,
      mode = "center",
      crisp_selector,
    },
    vb:horizontal_aligner {
      margin = 3,
      spacing = 10,
      mode = "center",
      vb:checkbox {
        id = "chkPrecise",
        value = bool_precise,
        notifier = function(boolean_value)
           bool_precise = boolean_value
        end
      },
      vb:text { text = 'Minimal time distortion' },
    }
  }

  local res = renoise.app():show_custom_prompt  (
    "Time Stretch",
    view,
    {'Stretch', 'Cancel'}
  );
  
  if res ~= 'Stretch' then return end
  
  local real_stretch_factor = from_dur / to_dur;
  
  process_stretch(real_stretch_factor, crisp_selector.value, bool_precise)
end

