-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- tool registration
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
--
-- This is a very simple example of how to create a quick personal shortcut 
-- table for various options. In this case the sample-slots are a target.
-- No menu option as most menu options already exists.
-- Lesson orders: 
-- 1: Go to the preferences, Keys -> Instrument Box -> Navigation/Edit
--    Assign personal shortcuts to all "~" prefixed shortcuts
-- 2: Add shortcuts for select last and select first sample
-- 3: Add context menu entries for the lacking shortcuts (move up / move down)
--
-- Hints:
-- Documentation\Renoise.ScriptingTool.API.txt & com.renoise.ExampleTool\main.lua
--
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

renoise.tool():add_keybinding {
  name = "Instrument Box:Navigation:Select previous sample",
  invoke = function() sample("selectprevious") end
}
renoise.tool():add_keybinding {
  name = "Instrument Box:Navigation:Select next sample",
  invoke = function() sample("selectnext") end
}
renoise.tool():add_keybinding {
  name = "Instrument Box:Edit:Move sample up",
  invoke = function() sample("moveup") end
}
renoise.tool():add_keybinding {
  name = "Instrument Box:Edit:Move sample down",
  invoke = function() sample("movedown") end
}
renoise.tool():add_keybinding {
  name = "Instrument Box:Edit:Insert new sample",
  invoke = function() sample("insert") end
}

renoise.tool():add_keybinding {
  name = "Instrument Box:Edit:Delete sample",
  invoke = function() sample("delete") end
}

renoise.tool():add_keybinding {
  name = "Instrument Box:Edit:Rename sample",
  invoke = function() sample("rename") end
}

renoise.tool():add_keybinding {
  name = "Instrument Box:Edit:Clear sample",
  invoke = function() sample("clear") end
}


-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- main content
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=


function sample(choice)
  local song = renoise.song()
  local selected_instrument = song.selected_instrument_index
  local selected_sample = song.selected_sample_index

  if choice == "selectprevious" then
    if song.selected_sample_index > 1 then
      song.selected_sample_index = song.selected_sample_index - 1
    end
  end
  if choice == "selectnext" then
    local max_samples = #song.instruments[selected_instrument].samples
    if song.selected_sample_index < max_samples then
      song.selected_sample_index = song.selected_sample_index +1
    end
  end
  if choice == "rename" then
    song.instruments[selected_instrument].samples[selected_sample].name = name_dialog(song.instruments[selected_instrument].samples[selected_sample].name, selected_sample)
  end
  if choice == "moveup" then
    if song.selected_sample_index > 2 then
      song.selected_sample_index = song.selected_sample_index - 1
      song.instruments[selected_instrument]:swap_samples_at(selected_sample, selected_sample - 1)
    end 
  end
  if choice == "movedown" then
    local max_samples = #song.instruments[selected_instrument].samples
    if song.selected_sample_index < max_samples-1 then
      song.selected_sample_index = song.selected_sample_index +1
      song.instruments[selected_instrument]:swap_samples_at(selected_sample, selected_sample +1)
    end
  end
  if choice == "insert" then
    song.instruments[selected_instrument]:insert_sample_at(selected_sample)
  end
  if choice == "delete" then
    song.instruments[selected_instrument]:delete_sample_at(selected_sample)
  end
  if choice == "clear" then
    song.instruments[selected_instrument].samples[selected_sample]:clear()
  end
  
end

function name_dialog(old_name, sample)
  local application = renoise.app()
  local vb = renoise.ViewBuilder()
  local title = "Rename sample ".. string.format("0x%X",  math.floor(sample-1)) 
  local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN

  local TEXT_ROW_WIDTH = 150

  local name_input = vb:column{
    margin = DIALOG_MARGIN,
    spacing = CONTENT_SPACING,
    uniform = true,
    vb:row{
      vb:textfield{
        id = 'sample_name',
        width = TEXT_ROW_WIDTH,
        value = old_name,
        notifier = function(value) return value end
      },
    }
  }
  application:show_custom_prompt(title, name_input, {'ok'},key_handler)
  
  return vb.views.sample_name.text
end

function key_handler(dialog, mod, key)
  if (mod == "" and key == "esc") or (mod == "" and key == "enter") then
    dialog:close()
  end
end



