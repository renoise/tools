--[[============================================================================
xDialog
============================================================================]]--
--[[

  Standard prompts for xLib

]]


class 'xDialog'


-------------------------------------------------------------------------------
-- @param str_default (string), suggested name
-- @param str_description (string), text above textfield
-- @param str_title (string), title of dialog
-- @return string or nil if user aborted

function xDialog.prompt_for_string(str_default,str_description,str_title)
  TRACE("xDialog.prompt_for_string(str_default,str_description,str_title)",str_default,str_title)

  local vb = renoise.ViewBuilder()
  local str_value = str_default
  local content_view = vb:column{
    margin = 8,
    vb:text{
      text = str_description,
    },
    vb:textfield{
      text = str_default,
      width = 100,
      notifier = function(str)
        str_value = str
      end,
    }
  }
  local key_handler = nil
  local title = str_title
  local button_labels = {"OK","Cancel"}
  local choice = renoise.app():show_custom_prompt(
    title, content_view, button_labels, key_handler)

  if (choice == "Cancel") then
    return
  end

  -- TODO validate that this name is without special characters
  -- needs to be able to save to disk

  return str_value

end