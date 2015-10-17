--[[============================================================================
xDialog
============================================================================]]--
--[[

  Standard prompts for xLib

]]


class 'xDialog'


--- "pseudo-modal" dialogs are registered here 
-- to avoid launching multiple times
xDialog.color_prompt = {}

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

  -- TODO validate using callback function

  return str_value

end

-------------------------------------------------------------------------------
-- color prompt is pseudo-modal: will re-use an already opened dialog
-- (not 'real' modal since we need to receive idle time notifications...)
-- @param callback (function)
-- @param active_color (table{r,g,b}) 
-- @param palette (table<table{r,g,b}>) predefined palette entries (max. 8)

function xDialog.prompt_for_color(callback,active_color,palette)
  TRACE("xDialog.prompt_for_color(callback,active_color,palette)",callback,active_color,palette)

  local t = xColor.value_to_color_table(active_color)
  local red = renoise.Document.ObservableNumber(t[1])
  local green = renoise.Document.ObservableNumber(t[2])
  local blue = renoise.Document.ObservableNumber(t[3])
  local scheduled_hex--,scheduled_val
  local suppress_notifier = false

  local vb = renoise.ViewBuilder()

  local get_active_color = function()
    return {
      math.floor(red.value),
      math.floor(green.value),
      math.floor(blue.value),
    }
  end

  local set_active_color = function(t)
    red.value = t[1]
    green.value = t[2]
    blue.value = t[3]
  end

  local vb_palette
  if (type(palette)=="table") then
    vb_palette = vb:column{}
    local vb_row1 = vb:row{}
    local vb_row2 = vb:row{}
    for i = 1,4 do
      vb_row1:add_child(vb:button{
        color = palette[i],
        notifier = function()
          set_active_color(palette[i])
        end
      })
    end 
    for i = 5,8 do
      vb_row2:add_child(vb:button{
        color = palette[i],
        notifier = function()
          set_active_color(palette[i])
        end
      })
    end
    vb_palette:add_child(vb_row1)
    vb_palette:add_child(vb_row2)
    --print("vb_palette",vb_palette)
  end


  local update_preview = function()
    --TRACE("*** update_preview")
    local view_bt = vb.views["color_preview"]
    view_bt.color = get_active_color()
    local val = xColor.color_table_to_value(view_bt.color)
    local view_str = vb.views["color_preview_hex"]
    suppress_notifier = true
    view_str.text = xColor.value_to_hex_string(val)
    suppress_notifier = false
    --scheduled_val = val
    --callback(scheduled_val)
  end

  red:add_notifier(update_preview)
  green:add_notifier(update_preview)
  blue:add_notifier(update_preview)

  local fn_tostring = function(val)
    return ("%X"):format(val)
  end 
  local fn_tonumber = function(str)
    local val = tonumber(str, 16)
    return val
  end
  local on_idle = function()
    if scheduled_hex then
      --print("*** on_idle - scheduled_hex...",scheduled_hex)
      local value = xColor.hex_string_to_value(scheduled_hex)
      --print("*** on_idle - value",value)
      if value then
        local t = xColor.value_to_color_table(value)
        red.value = t[1]
        green.value = t[2]
        blue.value = t[3]
      else
        -- revert to last good known color...
        local view_str = vb.views["color_preview_hex"]
        suppress_notifier = true
        view_str.text = xColor.color_table_to_hex_string(get_active_color())
        suppress_notifier = false
      end
      scheduled_hex = nil
    end

  end

  if not renoise.tool().app_idle_observable:has_notifier(on_idle) then
    renoise.tool().app_idle_observable:add_notifier(on_idle)
  end

  -- check for existing dialog and re-use
  if xDialog.color_prompt.dialog and xDialog.color_prompt.dialog.visible then  
    vb = xDialog.color_prompt.vb
    xDialog.color_prompt.dialog:show()
  else
    local content_view
    if xDialog.color_prompt.dialog and xDialog.color_prompt.view then
      vb = xDialog.color_prompt.vb
      content_view = xDialog.color_prompt.view
    else
      content_view = vb:column{
        margin = 8,
        vb:row{
          vb:column{
            vb:button{
              id = "color_preview",     
              width = 70,
              height = 37,
              text = "Text",
            },
            vb:textfield{
              id = "color_preview_hex",
              width = 70,
              notifier = function(str_val)
                if suppress_notifier then
                  return
                end
                --print("scheduled_hex",str_val)
                scheduled_hex = str_val
              end
            }
          },
          vb_palette,
        },
        vb:column{
          vb:row{
            vb:text{text = "R"},
            vb:minislider{min = 0,max = 255,width = 100,bind = red},
            vb:valuefield{bind = red,tostring = fn_tostring,tonumber = fn_tonumber},
          },
          vb:row{
            vb:text{text = "G"},
            vb:minislider{min = 0,max = 255,width = 100,bind = green},
            vb:valuefield{bind = green,tostring = fn_tostring,tonumber = fn_tonumber},
          },
          vb:row{
            vb:text{text = "B"},
            vb:minislider{min = 0,max = 255,width = 100,bind = blue},
            vb:valuefield{bind = blue,tostring = fn_tostring,tonumber = fn_tonumber},
          },
        },
        vb:row{
          vb:button{
            text = "Apply",
            notifier = function()
              local val = xColor.color_table_to_value(get_active_color())
              callback(val)
              xDialog.color_prompt.dialog:close()
            end
          },
          --[[
          vb:button{
            text = "Cancel",
            notifier = function()
              xDialog.color_prompt.dialog:close()
            end
          }
          ]]
        }

      }
    end

    local key_handler = nil
    local title = "Pick a color"

    xDialog.color_prompt = {
      dialog = renoise.app():show_custom_dialog(
        title, content_view, key_handler),
      view = content_view,
      vb = vb,
    }
  end
  
  update_preview()

end

