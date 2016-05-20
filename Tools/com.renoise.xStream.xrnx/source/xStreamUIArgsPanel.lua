--[[============================================================================
xStreamUIArgsPanel
============================================================================]]--
--[[

	Supporting class for xStream 

]]

--==============================================================================

class 'xStreamUIArgsPanel'

xStreamUIArgsPanel.CONTROLS = {
  "xStreamArgsAddButton",
  "xStreamModelArgsToggle",
  "xStreamArgsMoveUpButton",
  "xStreamArgsMoveUpButton",
  "xStreamArgsMoveDownButton",
  "xStreamArgsEditButton",
  "xStreamArgsRandomize",
  "xStreamArgsSelector",
}

xStreamUIArgsPanel.NO_ARGS_AVAILABLE = "No arguments"
xStreamUIArgsPanel.NO_ARG_SELECTED = "(Select argument)"
xStreamUIArgsPanel.ARGS_SELECTOR_W = 201
xStreamUIArgsPanel.ARGS_SLIDER_W = 90

function xStreamUIArgsPanel:__init(xstream,midi_prefix,vb,ui)

  self.xstream = xstream
  self.midi_prefix = midi_prefix
  self.vb = vb
  self.ui = ui

  self.arg_labels = {}
  self.arg_views = {}
  self.arg_bops = {}

  self.visible = property(self.get_visible,self.set_visible)
  self.visible_observable = renoise.Document.ObservableBoolean(false)

  self.disabled = property(self.get_disabled,self.set_disabled)

end

--------------------------------------------------------------------------------
-- Get/Set methods
--------------------------------------------------------------------------------

function xStreamUIArgsPanel:get_visible()
  return self.visible_observable.value
end

function xStreamUIArgsPanel:set_visible(val)
  TRACE("xStreamUIArgsPanel:set_visible(val)",val)

  self.ui.args_editor.visible = false

  local view_arrow = self.vb.views["xStreamModelArgsToggle"]
  local view_popup = self.vb.views["xStreamArgsSelectorRack"]
  local view_spacer = self.vb.views["xStreamArgsVerticalSpacer"]

  view_arrow.text = val and xStreamUI.ARROW_UP or xStreamUI.ARROW_DOWN
  view_popup.visible = not val

  self.visible_observable.value = val
  self:update()
  self:update_visibility()
  view_spacer.visible = not val 


end

--------------------------------------------------------------------------------

function xStreamUIArgsPanel:get_disabled()
  return
end

function xStreamUIArgsPanel:set_disabled(val)
  for k,v in ipairs(xStreamUIArgsPanel.CONTROLS) do
    self.vb.views[v].active = not val
  end
end

--------------------------------------------------------------------------------
-- Class methods
--------------------------------------------------------------------------------

function xStreamUIArgsPanel:get_label_w()

  if not self.xstream.selected_model then
    return 1
  end

  local args = self.xstream.selected_model.args
  local arg_max_length = 0
  for k,arg in ipairs(args.args) do
    arg_max_length = math.max(arg_max_length,#arg.name)
  end
  return (arg_max_length > 0) and arg_max_length*xStreamUI.MONO_CHAR_W or 30

end


--------------------------------------------------------------------------------
-- (re-)build list of arguments 

function xStreamUIArgsPanel:build_args()
  TRACE("xStreamUIArgsPanel:build_args()")

  if not self.xstream.selected_model then
    --print("*** No model selected")
    return
  end

  local vb = self.vb
  local args = self.xstream.selected_model.args

  local vb_container = vb.views["xStreamArgsContainer"]
  for k,v in ipairs(self.arg_views) do
    vb_container:remove_child(v)
  end

  self.arg_labels = {}
  self.arg_bops = {}
  self.arg_views = {}

  if (args.length == 0) then
    return
  end

  local args_label_w = self:get_label_w()

  local slider_width = xStreamUIArgsPanel.ARGS_SLIDER_W
  local full_width = xStreamUIArgsPanel.ARGS_SELECTOR_W
  local items_width = xStreamUIArgsPanel.ARGS_SELECTOR_W-60

  -- add a custom control for each argument
  for k,arg in ipairs(args.args) do

    -- custom number/string converters 
    local fn_tostring = nil
    local fn_tonumber = nil
    
    --print("arg.properties",rprint(arg.properties))
    local display_as = table.find(xStreamArg.DISPLAYS,arg.properties.display_as) 
    local integered = false

    if display_as == xStreamArg.DISPLAY_AS.HEX then
      integered = true
      fn_tostring = function(val)
        local hex_digits = xLib.get_hex_digits(arg.properties.max) 
        val = arg.properties.zero_based and val-1 or val
        return ("%."..tostring(hex_digits).."X"):format(val)
      end 
      fn_tonumber = function(str)
        local val = tonumber(str, 16)
        val = arg.properties.zero_based and val+1 or val
        return val
      end
    elseif display_as == xStreamArg.DISPLAY_AS.PERCENT then
      fn_tostring = function(val)
        return ("%.3f %%"):format(val)
      end 
      fn_tonumber = function(str)
        return tonumber(string.sub(str,1,#str-1))
      end
    elseif display_as == xStreamArg.DISPLAY_AS.NOTE then
      integered = true
      fn_tostring = function(val)
        return xNoteColumn.note_value_to_string(math.floor(val))
      end 
      fn_tonumber = function(str)
        return xNoteColumn.note_string_to_value(str)
      end
    elseif display_as == xStreamArg.DISPLAY_AS.INTEGER then
      integered = true
      fn_tostring = function(val)
        return ("%d"):format(val)
      end 
      fn_tonumber = function(str)
        return tonumber(str)
      end
    else
      fn_tostring = function(val)
        val = arg.properties.zero_based and val-1 or val
        return ("%s"):format(val)
      end 
      fn_tonumber = function(str)
        local val = tonumber(str)
        val = arg.properties.zero_based and val+1 or val
        return val
      end
    end

    local view_label = vb:text{
      text = arg.name,
      width = args_label_w,
      font = "mono",
    }

    local view_bop = vb:bitmap{
      bitmap = "./source/icons/bind_or_poll.bmp",
      mode = "body_color",
      --width = xStreamUI.BITMAP_BUTTON_W,
      height = xStreamUI.BITMAP_BUTTON_H-1,
    }

    local view_label_rack = vb:row{
      vb:checkbox{
        visible = false,
        notifier = function()
          self.xstream.selected_model.args.selected_index = k
        end,
      },
      view_label,
    }

    local view = vb:row{
      vb:column{
        vb:space{
          height = 2,
        },
        vb:checkbox{
          bind = arg.locked_observable,
          width = 14,
          height = 14,
          tooltip = "Lock value - can still be changed manually," 
                  .."\nbut prevents changes when switching presets"
                  .."\nor receiving values from the Renoise API.",
        },
      }
    }

    local arg_control = nil
    local model_name = self.xstream.selected_model.name
    local midi_mapping = ("Tools:xStream:%s:%s [Set]"):format(model_name,arg.name)
    --print(">>> midi_mapping",midi_mapping)

    if (type(arg.observable) == "ObservableNumber") then

      if arg.properties.items then -- select (default to popup)
        display_as = display_as or xStreamArg.DISPLAY_AS.POPUP
        integered = true

        if (display_as == xStreamArg.DISPLAY_AS.POPUP) then
          --print("display_as popup",arg.name)
          arg_control = vb:popup{
            items = arg.properties.items,
            value = arg.value,
            width = items_width,
            bind = arg.observable,
            midi_mapping = midi_mapping,
          }
          view:add_child(vb:row{
            tooltip = arg.description,
            view_label_rack,
            arg_control,
            view_bop,
          })
        elseif (display_as == xStreamArg.DISPLAY_AS.CHOOSER) then
          arg_control = vb:chooser{
            items = arg.properties.items,
            value = arg.value,
            width = items_width,
            bind = arg.observable,
            midi_mapping = midi_mapping,
          }

          view:add_child(vb:row{
            tooltip = arg.description,
            view_label_rack,
            arg_control,
            view_bop,
          })
        elseif (display_as == xStreamArg.DISPLAY_AS.SWITCH) then
          arg_control = vb:switch{
            items = arg.properties.items,
            value = arg.value,
            width = items_width,
            bind = arg.observable,
            midi_mapping = midi_mapping,
          }
          view:add_child(vb:row{
            tooltip = arg.description,
            view_label_rack,
            arg_control,
            view_bop,
          })
        else    
          LOG("Unsupported 'display_as' property - please review this argument:"..arg.name)
        end
      elseif (display_as == xStreamArg.DISPLAY_AS.INTEGER) 
        or (display_as == xStreamArg.DISPLAY_AS.HEX) 
      then -- whole numbers
        integered = true
        arg_control = vb:valuebox{
          tostring = fn_tostring,
          tonumber = fn_tonumber,
          value = arg.value,
          min = arg.properties.min or xStreamUI.ARGS_MIN_VALUE,
          max = arg.properties.max or xStreamUI.ARGS_MAX_VALUE,
          bind = arg.observable,
          midi_mapping = midi_mapping,
        }
        view:add_child(vb:row{
          tooltip = arg.description,
          view_label_rack,
          arg_control,
          view_bop,
        })
      else -- floating point (default to minislider)
        
        view:add_child(vb:row{
          tooltip = arg.description,
          view_label_rack,
        })

        local readout = vb:valuefield{
          tostring = fn_tostring,
          tonumber = fn_tonumber,
          value = arg.value,
          min = arg.properties.min or xStreamUI.ARGS_MIN_VALUE,
          max = arg.properties.max or xStreamUI.ARGS_MAX_VALUE,
          bind = arg.observable,
        }

        display_as = display_as or xStreamArg.DISPLAY_AS.MINISLIDER

        if (display_as == xStreamArg.DISPLAY_AS.MINISLIDER) 
          or (display_as == xStreamArg.DISPLAY_AS.PERCENT) 
          or (display_as == xStreamArg.DISPLAY_AS.NOTE) 
        then
          arg_control = vb:minislider{
            value = arg.value,
            width = slider_width,
            height = 17,
            min = arg.properties.min or xStreamUI.ARGS_MIN_VALUE,
            max = arg.properties.max or xStreamUI.ARGS_MAX_VALUE,
            bind = arg.observable,
            midi_mapping = midi_mapping,
          }
          view:add_child(vb:row{
            arg_control,
            view_bop,
            readout,
          })
        elseif (display_as == xStreamArg.DISPLAY_AS.ROTARY) then
          arg_control = vb:rotary{
            value = arg.value,
            height = 24,
            min = arg.properties.min or xStreamUI.ARGS_MIN_VALUE,
            max = arg.properties.max or xStreamUI.ARGS_MAX_VALUE,
            bind = arg.observable,
            midi_mapping = midi_mapping,
          }
          view:add_child(vb:row{
            arg_control,
            view_bop,
            readout,
          })
        elseif (display_as == xStreamArg.DISPLAY_AS.FLOAT) then
          readout.midi_mapping = midi_mapping,
          view:add_child(vb:row{
            style = "plain",
            readout,
            view_bop,
          })
        elseif (display_as == xStreamArg.DISPLAY_AS.VALUE) then
          view:add_child(vb:value{
            tostring = fn_tostring,
            value = arg.value,
            bind = arg.observable,
            midi_mapping = midi_mapping,
          })
        end

      end
    elseif (type(arg.observable) == "ObservableBoolean") then
      display_as = display_as or xStreamArg.DISPLAY_AS.CHECKBOX
      if (display_as == xStreamArg.DISPLAY_AS.CHECKBOX) then
        arg_control = vb:checkbox{
          value = arg.value,
          bind = arg.observable,
          midi_mapping = midi_mapping,
        }
        view:add_child(vb:row{
          tooltip = arg.description,
          view_label_rack,
          arg_control,
          view_bop,
        })
      end
    elseif (type(arg.observable) == "ObservableString") then
      display_as = display_as or xStreamArg.DISPLAY_AS.TEXTFIELD
      if (display_as == xStreamArg.DISPLAY_AS.TEXTFIELD) then
        view:add_child(vb:row{
          tooltip = arg.description,
          view_label_rack,
          vb:textfield{
            text = arg.value,
            width = full_width,
            bind = arg.observable,
          },
          view_bop,
        })
      end
    end

    if view then
      table.insert(self.arg_bops,view_bop)
      table.insert(self.arg_labels,view_label)
      table.insert(self.arg_views,view)
      if arg_control 
        and not renoise.tool():has_midi_mapping(midi_mapping)
      then
        renoise.tool():add_midi_mapping{
          name = midi_mapping,
          invoke = function(a) 
            if (type(arg.observable)=="ObservableNumber") then
              local range,offset,max = nil,0,nil
              if (arg.properties.items) then
                range = #arg.properties.items
                offset = 1
                max = #arg.properties.items
              elseif (arg.properties.min and arg.properties.max) then
                range = arg.properties.max - arg.properties.min
                offset = arg.properties.min
                max = arg.properties.max
              end
              if a:is_abs_value() then
                local steps = 0x7F -- 7bit
                local step_size = range/steps
                arg.value = math.min(max,offset + ((a.int_value*step_size)))
              elseif a:is_rel_value() then
                local val = nil
                if integered then 
                  -- offer precise control of 'integered' controls
                  val = arg.value+a.int_value
                else
                  -- allow finer control than with absolute 
                  val = arg.value+(a.int_value*(range/0xFF))
                end
                arg.value = xLib.clamp_value(val,arg.properties.min,arg.properties.max)
              end
            elseif (type(arg.observable)=="ObservableBoolean") then
              arg.value = a.boolean_value
            else
              LOG("Unsupported type:"..type(arg.observable))
            end

          end
        }
      end
      vb_container:add_child(view)
    end

  end

end

--------------------------------------------------------------------------------
-- build the basic panel 

function xStreamUIArgsPanel:build()

  local vb = self.vb
  return vb:column{
    style = "panel",
    id = "xStreamArgsPanel",
    margin = 4,
    height = 100,
    vb:space{
      width = xStreamUI.RIGHT_PANEL_W,    
    },
    vb:row{
      vb:button{
        text=xStreamUI.ARROW_DOWN,
        id = "xStreamModelArgsToggle",
        tooltip = "Toggle visibility of argument list",
        width = xStreamUI.BITMAP_BUTTON_W,
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function()
          self.visible = not self.visible
        end,
      },
      vb:text{
        text = "Args",
        font = "bold",
      },
      vb:row{
        vb:button{
          bitmap = "./source/icons/add.bmp",
          tooltip = "Create new argument",
          id = "xStreamArgsAddButton",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            local idx = self.xstream.selected_model.args.selected_index+1
            --print("self.xstream.selected_model.args.selected_index",self.xstream.selected_model.args.selected_index)
            local added,err = self.xstream.selected_model.args:add(nil,idx)
            --print(">>> args added,err",added,err)
            if not added then
              if err then
                renoise.app():show_warning(err)
              end
            else 
              self.xstream.selected_model.args.selected_index = idx
              self.ui.args_editor.visible = true
            end
          end,
        },
        vb:button{
          id = "xStreamArgsMoveUpButton",
          bitmap = "./source/icons/move_up.bmp",
          tooltip = "Move argument up in list",
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            local args = self.xstream.selected_model.args
            local got_moved,_ = args:swap_index(args.selected_index,args.selected_index-1)
            if got_moved then
              args.selected_index = args.selected_index - 1
            end
          end
        },
        vb:button{
          id = "xStreamArgsMoveDownButton",
          bitmap = "./source/icons/move_down.bmp",
          tooltip = "Move argument down in list",
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            local args = self.xstream.selected_model.args
            local got_moved,_ = args:swap_index(args.selected_index,args.selected_index+1)
            if got_moved then
              args.selected_index = args.selected_index + 1
            end
          end
        },
        vb:button{
          id = "xStreamArgsEditButton",
          text = "Edit",
          tooltip = "Edit selected argument",
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            self.ui.args_editor.visible = not self.ui.args_editor.visible
          end
        },
        vb:button{
          id = "xStreamArgsRandomize",
          text = "Random",--"☢ Rnd",
          tooltip = "Randomize all unlocked parameters",
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            if self.xstream.selected_model then
              self.xstream.selected_model.args:randomize()
            end
          end
        },
      },
    },
    vb:row{
      id = "xStreamArgsSelectorRack",
      vb:popup{
        items = {},
        id = "xStreamArgsSelector",
        tooltip = "Choose between available arguments",
        width = xStreamUIArgsPanel.ARGS_SELECTOR_W,
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function(idx)
          local model = self.xstream.selected_model
          if model then
            model.args.selected_index = idx-1
          end
        end,
      },
    },
    vb:text{
      id = "xStreamArgsNoneMessage",
      text = "There are no arguments to display",
    },
    vb:column{
      id = 'xStreamArgsContainer',
    },
    vb:space{
      id = 'xStreamArgsVerticalSpacer',
      height = 7,
    },
    vb:column{
      id = 'xStreamArgsEditorRack',
      visible = self.ui.args_editor.visible,
      self.ui.args_editor:build(),
    },
  }

end

--------------------------------------------------------------------------------

function xStreamUIArgsPanel:update()

  local model = self.xstream.selected_model

  -- show message if not args
  local view_msg = self.vb.views["xStreamArgsNoneMessage"]
  if model then
    view_msg.visible = self.visible 
      and (#model.args.args == 0) 
  else
    view_msg.visible = self.visible and true or false
  end

  -- update labels
  for k,v in ipairs(self.arg_labels) do
    v.text = model and model.args.args[k].name or ""
    v.font = model and (k == model.args.selected_index) 
      and "bold" or "mono"
  end

  -- update bops
  for k,v in ipairs(self.arg_bops) do
    local bop = model and model.args.args[k]:get_bop()
    v.visible = (model and bop) and true or false
    v.tooltip = (model and bop) and "This argument is bound to/polling '"..bop.."'" or ""
  end

end

--------------------------------------------------------------------------------

function xStreamUIArgsPanel:update_controls()

  local view_up = self.vb.views["xStreamArgsMoveUpButton"]
  local view_down = self.vb.views["xStreamArgsMoveDownButton"]
  local view_edit = self.vb.views["xStreamArgsEditButton"]

  local model = self.xstream.selected_model
  local has_selected = (model and model.args.selected_index > 0) and true or false
  view_up.active = has_selected
  view_down.active = has_selected
  view_edit.active = has_selected


end

--------------------------------------------------------------------------------

function xStreamUIArgsPanel:update_selector()
  TRACE("xStreamUIArgsPanel:update_selector()")

  local model = self.xstream.selected_model
  local view_popup = self.vb.views["xStreamArgsSelector"]
  if model and (#model.args.args > 0) then
    local items = model.args:get_names()
    table.insert(items,1,xStreamUIArgsPanel.NO_ARG_SELECTED)
    view_popup.items = items
    view_popup.value = model.args.selected_index+1
  else
    view_popup.items = {xStreamUIArgsPanel.NO_ARGS_AVAILABLE}
    view_popup.value = 1
  end

end

--------------------------------------------------------------------------------
-- if compact mode, display a single argument at a time

function xStreamUIArgsPanel:update_visibility()
  TRACE("xStreamUIArgsPanel:update_visibility()")

  for k,v in ipairs(self.arg_views) do
    if not self.xstream.selected_model then
      v.visible = false
    elseif self.visible 
      and not self.ui.args_editor.visible
    then 
      v.visible = true
    else
      v.visible = (k == self.xstream.selected_model.args.selected_index)
    end
  end

  local args_label_w = self:get_label_w()
  for k,v in ipairs(self.arg_labels) do
    v.width = (self.visible and not self.ui.args_editor.visible) and args_label_w or 2
    v.visible = self.visible
  end

end

