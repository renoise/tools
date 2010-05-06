--[[----------------------------------------------------------------------------

  Script        : Rubberband.lua
  Creation Date : 2010-05-05
  Last modified : 2010-05-05
  Version       : 0.2

----------------------------------------------------------------------------]]--

manifest = {}
manifest.api_version = 0.2
manifest.author = "ClySuva | clysuva@gmail.com"
manifest.description = "adds rubberband interface to Renoise"
manifest.actions = {}

manifest.actions[#manifest.actions + 1] = {
  name = "SampleEditor:Process:Timestretch",
  description = 'Stretches sample length without changing pitch',
  invoke = function() show_stretch_dialog() end
}

-- Does file exist?
function exists(filename)
  return true
end


function display_error() 
  local res = renoise.app():show_prompt('Rubberband missing!',
  "To use this feature you must download Rubberband executable and\n"..
  "copy it to your operating system path!\n\n"..
  "On Ubuntu you must install package rubberband-cli\n\n"..
  "On other systems, you can download binaries or the source code from:\n"..
  "http://www.breakfastquay.com/rubberband/"
  , {'Visit website', 'Ok'})
  
  
  if res == 'Visit website' then
    local urlopencmd; 
    if os.platform() == 'WINDOWS' then urlopencmd = 'start'; end
    if os.platform() == 'MACINTOSH' then urlopencmd = 'open'; end
    if os.platform() == 'LINUX' then urlopencmd = 'xdg-open'; end
    
    os.execute(urlopencmd .. ' http://www.breakfastquay.com/rubberband/');
  end
end

function processRubberBand(stretch, crisp)

  local ofile = os.tmpname()
  local ifile = os.tmpname()..'.wav'

  renoise.song().selected_sample.sample_buffer:save_as(ofile, 'wav')


  print('Input is: ' .. ifile)
  print('Output is: ' .. ofile)
  
  os.execute("/Users/dac514/bin/rubberband --time "..stretch.." --crisp "..crisp..
         " "..ofile.." "..ifile);
         
  if not exists(ifile) then
    display_error()
    return
  end
          
  renoise.song().selected_sample.sample_buffer:load_from(ifile)
  
  os.remove(ofile)
  os.remove(ifile)
end


function show_stretch_dialog()
  local bpm = renoise.song().transport.bpm
  local lpb = renoise.song().transport.lpb
  local coef = bpm * lpb / 60.0

  local selSample = renoise.song().selected_sample
  local nframes = selSample.sample_buffer.number_of_frames
  local srate = selSample.sample_buffer.sample_rate

  local slength = nframes / srate
  local rows = slength * coef

  local vb = renoise.ViewBuilder()
  
  local numLinesSelector = vb:valuebox { min = 1, value = 16 }
  local crispSelector = vb:popup { 
    items = {'1', '2', '3', '4', '5'},
    value = 4 
  }
  local typeSelector = vb:popup {
    items = {'lines', 'beats', 'seconds'},
    value = 2
  }
  
  local view = vb:horizontal_aligner{
    margin = 10,
    spacing = 10,
    vb:vertical_aligner{
      vb:text{text = 'Length:' },
      numLinesSelector,
    },
    vb:vertical_aligner{
      vb:text{text = 'Units:' },
      typeSelector,
    },
    vb:vertical_aligner{
      vb:text{text = 'Crispness:' },
      crispSelector
    },
  }
   
  
  local res = renoise.app():show_custom_prompt  (
    "Time Stretch",
    view,
    {'Stretch', 'Cancel'}
  );
  
  -- How long we stretch?
  local stime
  if typeSelector.value == 1 then
    stime = numLinesSelector.value / rows
  elseif typeSelector.value == 2 then
    stime = (numLinesSelector.value * lpb) / rows
  elseif typeSelector.value == 3 then
    stime = numLinesSelector.value / slength 
  end;
  
  if res == 'Stretch' then
    processRubberBand(stime, crispSelector.value)
  end;
end

