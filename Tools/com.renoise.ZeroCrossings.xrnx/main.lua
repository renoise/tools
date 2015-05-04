--[[============================================================================
main.lua
============================================================================]]--


local SLICE_MODE = {
  DOWN_UP = 1,
  UP_DOWN = 2,
  ANY = 3,
}

local LOOP_MODE = {
  OFF = 1,
  FORWARD = 2,
  REVERSE = 3,
  PING_PONG = 4,
}

local CHANNEL = {
  LEFT = 1,
  RIGHT = 2,
}

local vb = renoise.ViewBuilder()
local dialog = nil
local dialog_content = nil

local num_crossings = 1
local start_offset = 1
local minimum_size = 10
local exact_cross_count = false
local slice_channel = CHANNEL.LEFT
local slice_mode = SLICE_MODE.DOWN_UP
local max_slices = 255
local loop_mode = LOOP_MODE.FORWARD

local helptext = [[
------------------------------------------------- 
About this tool
------------------------------------------------- 

This tool works by slicing a sample into smaller
segments when the signal is crossing the zero
threshold (also known as a 'zero crossing').

Use it to create raw wavetable materials, or 
generate microtonal harmonics from pretty much 
any type of sound. 

Note that any sliced instrument will create an 
automatic keyzone layout, according to the 
'Drumkit' settings specified in the keyzone. 

------------------------------------------------- 
Option: Detection Method
------------------------------------------------- 

This option will decide how crossings are detected

#### Below->Above
When the signal goes from below to above zero
(ignoring crossings in the opposite direction)

          1           2		<- crossings
 \        | /\        | /\
  \       |/  \       |/  \
___\______|____\______|____\____
    \    /|     \    /|     \
     \  / |      \  / |      \
      \/  |       \/  |       \
    

#### Above->Below
When the signal goes from above to below zero
(ignoring crossings in the opposite direction)

    1           2           3	<- crossings
 \  |       /\  |       /\  |
  \ |      /  \ |      /  \ |
___\|_____/____\|_____/____\|___
    |    /      |    /      |
    |\  /       |\  /       |\
    | \/        | \/        | \


#### Any Direction
When the signal goes either way...

    1     2     3     4     5	<- crossings
 \  |     | /\  |     | /\  |
  \ |     |/  \ |     |/  \ |
___\|_____|____\|_____|____\|___
    |    /|     |    /|     |
    |\  / |     |\  / |     |\
    | \/  |     | \/  |     | \
          

------------------------------------------------- 
Option: Exact #Crossings
------------------------------------------------- 

Enable this option if you want to slice the 
sample for every Nth crossing.

The number of crossings are counted according
to the Detection Method. For example, here we are
counting crossings using 'Any Direction', and
slicing the sample for every 2nd crossing:

    1     2     3     4     5    <- crossings
    v           v           v    <- slice
 \  |     | /\  |     | /\  |
  \ |     |/  \ |     |/  \ |
___\|_____|____\|_____|____\|___
    |    /|     |    /|     |
    |\  / |     |\  / |     |\
    | \/  |     | \/  |     | \

------------------------------------------------- 
Option: Offset (samples)
------------------------------------------------- 

Specify a value (in samples/frames) from which 
the detection of crossings should start. 

For example, a value of 1200 will cause the tool
to start looking for crossings after the 1200th
frame.

Note: you can set the value according to the 
currently selected range in the sample editor 
by clicking 'Set from Selection' 

------------------------------------------------- 
Option: Min.Size (samples)
------------------------------------------------- 

Specifies the minimum size for a slice. 
This option can be used in two ways: 

1. If you have a complex waveform (many crossings
   within a single 'cycle'), define a length to 
   make the tool ignore crossings until the 
   desired 'cycle' is reached. If you are using
   the tool in this way, it's a good practice to
   subtract a few samples from the value, as a
   waveform will often have small variations in
   it's length from cycle to cycle.

2. If you are using the Exact #Crossings mode,
   you can define a minimum size to avoid that
   the tool is picking up very small crossings
   (setting Min.Size to just a few samples will
   make a big difference here...)

Note: you can set the value according to the 
currently selected range in the sample editor 
by clicking 'Set from Selection' 

------------------------------------------------- 
Option: Max #Slices
------------------------------------------------- 

Tell the tool how many slices it should create.
Note: 255 is currently the limit in Renoise

------------------------------------------------- 
Option: Slice Looping
------------------------------------------------- 

For convenience, you can specify a looping mode
that should be applied to the resulting slices

The looping modes are equal to the looping modes
available in the waveform editor. 


------------------------------------------------- 
Other Notes
------------------------------------------------- 

By default, the Drumkit will use C-3 as the 
starting key, but this tool might generate more 
slices/notes than you can fit in the remaining
octaves. Lower the default note by going 
into the Keyzone tab and changing the settings
(located in the upper toolbar) - this will 
provide you with as many as 120 unique slices
accessible from the keyboard. 

If you need acccess to all the slices, you
can use the slice offset command when entering
notes into the pattern editor: S00 - SFF 


]]


--------------------------------------------------------------------------------
-- functions
--------------------------------------------------------------------------------

function show()

  attach_to_song()

  if not dialog or not dialog.visible then
    
    if not dialog_content then
      dialog_content = build()
    end

    local function keyhandler(dialog, key)
      if (key.modifiers == "" and key.name == "return") then
        perform_slicing()
      elseif (key.modifiers == "" and key.name == "esc") then
        dialog:close()
      end
    end
      
    dialog = renoise.app():show_custom_dialog("Zero Crossings", 
      dialog_content, keyhandler)

  else
    dialog:show()
  end

  update_on_sample_focus()


end

--------------------------------------------------------------------------------

function perform_slicing()

  ----------------------------
  -- sanity checks
  ----------------------------

  local sample = renoise.song().selected_sample

  if not sample then
    renoise.app():show_warning("You need to select a sample first")
    return
  end

  if sample.is_slice_alias then
    renoise.app():show_warning("This sample is a slice alias - please run the tool on a normal sample, or choose 'Slices->Destructively Render Slices' before running the tool")
    return
  end

  if (#renoise.song().selected_instrument.samples > 1) then
    local choice = renoise.app():show_prompt(
      "Overwrite/replace existing samples?",
      "Warning: this instrument contains multiple samples,"
      .."\nwhich will be replaced by slices from the currently selected sample"
      .."\nClick OK if you wish to continue",
      {"OK","Cancel"})
    if (choice == "Cancel") then
      return
    end
  end

  local sbuf = sample.sample_buffer

  if not sbuf.has_sample_data then
    renoise.app():show_warning("Could not locate any sample data")
    return
  end

  if (start_offset > sbuf.number_of_frames) then
    renoise.app():show_warning(("Cannot read from offset, please use a value which is lower than %i"):format(sbuf.number_of_frames))
    return
  end

  ----------------------------
  -- clear "all but selected sample"
  ----------------------------

  if (renoise.song().selected_instrument.samples[1].slice_markers == 0) then
    -- remove 'real' samples
    if (#renoise.song().selected_instrument.samples > 1) then
      local s_idx = renoise.song().selected_sample_index
      for i = #renoise.song().selected_instrument.samples, s_idx+1, -1 do
        renoise.song().selected_instrument:delete_sample_at(i)
      end
      for i = s_idx-1, 1,-1 do
        renoise.song().selected_instrument:delete_sample_at(1)
      end
    end
  else
    -- remove slices 
    renoise.song().selected_instrument.samples[1].slice_markers = {}
  end

  ----------------------------
  -- process
  ----------------------------

  local sframe = math.max(start_offset-1,1)
  local prev_sdata = nil
  local prev_cross = nil
  local prev_marker = nil
  local slice_markers = table.create()
  local cross_count = 0

  local insert_marker = function(sframe)
    if (#slice_markers >= max_slices) then
      return
    end
    slice_markers:insert(sframe)
  end

  while (sframe < sbuf.number_of_frames) do

    local sdata = sbuf:sample_data(slice_channel,sframe)

    -- detect crossings
    if prev_sdata then

      local cross = nil
    
      if (slice_mode == SLICE_MODE.DOWN_UP) and
        (prev_sdata < 0) and (sdata >= 0) 
      then
        cross = sframe
      elseif (slice_mode == SLICE_MODE.UP_DOWN) and
        (prev_sdata > 0) and (sdata <= 0) 
      then
        cross = sframe
      elseif (slice_mode == SLICE_MODE.ANY) and
        (((prev_sdata > 0) and (sdata <= 0)) or ((prev_sdata < 0) and (sdata >= 0)))
      then
        cross = sframe
      --[[
      ]]
      end
      
      if cross and not prev_marker then
        -- the first crossing
        insert_marker(cross)
        prev_marker = cross
      elseif cross and prev_marker and not exact_cross_count then
        if (cross-prev_marker > minimum_size) then
          insert_marker(cross)
          prev_marker = cross
        end
      elseif cross and prev_cross and prev_marker and exact_cross_count then

        if (cross_count >= num_crossings) and
          (cross-prev_marker > minimum_size)
        then
          insert_marker(cross)
          prev_marker = cross
          cross_count = 0
        end

      end

      if cross then
        cross_count = cross_count + 1
        prev_cross = cross
      end

    end 

    prev_sdata = sdata
    sframe = sframe + 1

  end 

  if (#slice_markers > 0) then
    sample.slice_markers = slice_markers
  else
    renoise.app():show_warning("Did not match any zero crossings.")
    return
  end

  ----------------------------
  -- post-steps: looping, transpose...
  ----------------------------

  for k,sample in ipairs(renoise.song().selected_instrument.samples) do
    sample.loop_mode = loop_mode

    --sample.transpose = -k

  end


end

--------------------------------------------------------------------------------

function show_help_dialog()

  local content_view = vb:column{
    margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
    vb:multiline_textfield{
      text = helptext,
      edit_mode = false,
      font = "mono",
      width = 330,
      height = 400,
    }
  }

  renoise.app():show_custom_dialog("Help", content_view)



end

--------------------------------------------------------------------------------

function is_fully_selected()

  local sample = renoise.song().selected_sample
  local num_frames = sample.sample_buffer.number_of_frames
  local sel_start = sample.sample_buffer.selection_start
  local sel_end = sample.sample_buffer.selection_end

  if (sel_start == 1) and (sel_end == num_frames) then
    return true
  else
    return false
  end

end

--------------------------------------------------------------------------------

function import_size()

  if (is_fully_selected()) then
    renoise.app():show_warning("You need to select a range within the sample")
    return
  end

  local sample = renoise.song().selected_sample
  local sel_start = sample.sample_buffer.selection_start
  local sel_end = sample.sample_buffer.selection_end
  vb.views.min_size.value = sel_end-sel_start

end

--------------------------------------------------------------------------------

function import_offset()

  if (is_fully_selected()) then
    renoise.app():show_warning("You need to select a range within the sample"
      .."\nThe offset will then use the start point of the selected range")
    return
  end

  local sample = renoise.song().selected_sample
  local sel_start = sample.sample_buffer.selection_start
  vb.views.start_offset.value = sel_start

end

--------------------------------------------------------------------------------

function build()

  local LABEL_WIDTH = 95
  local PANEL_MARGIN = 4
  local PANEL_WIDTH = 275
  local DIALOG_MARGIN = 6 
  local DIALOG_SPACING = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING
  local DIALOG_BUTTON_HEIGHT = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT
  local CONTROL_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
    
  local content = vb:column{
    margin=DIALOG_MARGIN,
    spacing=DIALOG_SPACING,
    vb:column{
      style = "group",
      margin = PANEL_MARGIN,
      width = PANEL_WIDTH,
      vb:text{
        text = "Slice Detection",
        font = "big",
      },
      vb:space{
        height = 6
      },
      vb:row{
        vb:text{
          text="Detection Method",
          width = LABEL_WIDTH
        },
        vb:popup{
          id="slice_mode", 
          items = {"Below->Above","Above->Below","Any direction"},
          width = 111,
          value = slice_mode,
          notifier = function()
            slice_mode = vb.views.slice_mode.value
          end,
        },

        vb:switch{
          id="slice_channel", 
          tooltip = "Select the left/right audio channel",
          items = {"L","R"},
          width = 50,
          value = slice_channel,
          notifier = function()
            slice_channel = vb.views.slice_channel.value
          end,
        },
      },
      vb:row{
        vb:text{
          text="Exact #Crossings",
          width = LABEL_WIDTH
        },
        vb:checkbox {
          id = "exact_cross_count",
          value = exact_cross_count,
          notifier = function()
            exact_cross_count = vb.views.exact_cross_count.value
            update_on_sample_focus()
          end,
        },
        vb:valuebox{
          id="num_crossings", 
          value = start_offset,
          min = 1,
          notifier = function()
            num_crossings = vb.views.num_crossings.value
          end,
        },
        vb:text{
          text="(every Nth)",
          width = LABEL_WIDTH
        },
      },

      vb:row{
        vb:text{
          text="Offset (samples)",
          width = LABEL_WIDTH
        },
        vb:valuebox{
          id="start_offset", 
          value = start_offset,
          min = 1,
          notifier = function()
            start_offset = vb.views.start_offset.value
          end,
        },
        vb:button {
          id = "import_offset",
          text = "Set From Selection",
          notifier = function()
            import_offset()
          end,
        },
      },
      vb:row{
        vb:text{
          text="Min.Size (samples)",
          width = LABEL_WIDTH
        },
        vb:valuebox{
          id="min_size", 
          min = 1,
          value = minimum_size,
          notifier = function()
            minimum_size = vb.views.min_size.value
          end,
        },
        vb:button {
          id = "import_size",
          text = "Set From Selection",
          notifier = function()
            import_size()
          end,
        },
      },
    },

    vb:column{
      style = "group",
      margin = PANEL_MARGIN,
      width = PANEL_WIDTH,
      vb:text{
        text = "Slice Generation",
        font = "big",
      },
      vb:space{
        height = 6
      },

      vb:row{
        vb:text{
          text="Max #Slices",
          width = LABEL_WIDTH
        },
        vb:valuebox{
          id="max_slices", 
          value = max_slices,
          min = 1,
          max = 255,
          notifier=function()
            max_slices = vb.views.max_slices.value
          end
        },
        vb:text{
          text="(between 1-255)",
        },
      },

      vb:row{
        vb:text{
          text="Slice Looping",
          width = LABEL_WIDTH
        },
        vb:popup{
          id="loop_mode", 
          items = {"Off","Forward","Reverse","Ping-pong"},
          value = loop_mode,
          notifier=function()
            loop_mode = vb.views.loop_mode.value
          end
        },

      },
    },

    vb:row{
      vb:button{
        id="slice_button",
        height=DIALOG_BUTTON_HEIGHT,
        width=80,
        text="Process",  
        notifier=function()
          perform_slicing()
        end
      },
      vb:button{
        id="help_button",
        height=DIALOG_BUTTON_HEIGHT,
        width=80,
        text="Help",  
        notifier=function()
          show_help_dialog()
        end
      },


    }
  }

  return content

end

--------------------------------------------------------------------------------
-- notifiers/observables
--------------------------------------------------------------------------------

function update_on_sample_focus()

  -- disable everything
  vb.views.slice_channel.active = false
  vb.views.slice_button.active = false
  vb.views.import_size.active = false
  vb.views.import_offset.active = false

  local sample = renoise.song().selected_sample
  if not sample then
    -- this can happen when using undo after slicing...
    return
  end

  local sbuf = sample.sample_buffer
  if not sbuf.has_sample_data then
    return
  end

  vb.views.num_crossings.active = 
    exact_cross_count and true or false

  -- set max size for offset/interval
  vb.views.min_size.max = sbuf.number_of_frames
  vb.views.start_offset.max = sbuf.number_of_frames
  
  if (sbuf.number_of_channels == 2) then
    vb.views.slice_channel.active = true
  end

  vb.views.slice_button.active = true
  vb.views.import_size.active = true
  vb.views.import_offset.active = true

end

function attach_to_song()

  renoise.song().selected_sample_observable:add_notifier(function()
    update_on_sample_focus()
  end)

end

--------------------------------------------------------------------------------
-- tool stuff
--------------------------------------------------------------------------------

renoise.tool().app_new_document_observable:add_notifier(function()
  if dialog then
    attach_to_song()
    update_on_sample_focus()
  end
end)

renoise.tool().app_became_active_observable:add_notifier(function()
  if dialog then
    update_on_sample_focus()
  end
end)

renoise.tool():add_menu_entry{
  name = "Sample Editor:Slices:Zero Crossings",
  invoke = function() show() end
}

renoise.tool():add_keybinding{
  name = "Sample Editor:Slices:Zero Crossings",
  invoke = function() show() end
}



--------------------------------------------------------------------------------
-- debug
--------------------------------------------------------------------------------

_AUTO_RELOAD_DEBUG = function()
  show()
end

