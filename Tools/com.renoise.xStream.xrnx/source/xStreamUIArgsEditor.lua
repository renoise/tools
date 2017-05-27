--[[============================================================================
xStreamUIArgsEditor
============================================================================]]--
--[[

	Supporting class for xStream 

]]

--==============================================================================

local PANEL_W = xStreamUI.ARGS_PANEL_W - 8 -- margins

class 'xStreamUIArgsEditor'

function xStreamUIArgsEditor:__init(xstream,vb)

  assert(type(xstream)=="xStream","Expected 'xstream' as argument")
  assert(type(vb)=="ViewBuilder","Expected 'ViewBuilder' as argument")

  self.vb = vb
  self.xstream = xstream

  self.visible = property(self.get_visible,self.set_visible)
  self.visible_observable = renoise.Document.ObservableBoolean(false)

end

--------------------------------------------------------------------------------

function xStreamUIArgsEditor:get_visible()
  return self.visible_observable.value
end

function xStreamUIArgsEditor:set_visible(val)
  TRACE("xStreamUIArgsEditor:set_visible(val)",val)

  local view_button = self.vb.views["xStreamArgsEditButton"]
  local view_popup = self.vb.views["xStreamArgsSelectorRack"]
  local view_editor = self.vb.views["xStreamArgsEditorRack"]
  local view_arrow = self.vb.views["xStreamModelArgsToggle"]

  local args = self.xstream.ui.args_panel

  if val and not args.visible then
    view_arrow.text = xStreamUI.ARROW_UP 
  elseif not args.visible then
    view_arrow.text = xStreamUI.ARROW_DOWN
  end

  view_button.color = val and xLib.COLOR_ENABLED or xLib.COLOR_DISABLED
  if val and args.visible then
    view_popup.visible = true
  elseif not val and args.visible then
    view_popup.visible = false
  end
  view_editor.visible = val

  self.visible_observable.value = val

  self:update()
  args:update_visibility()

end

-------------------------------------------------------------------------------

function xStreamUIArgsEditor:build()

  local vb = self.vb
  local label_w = 75
  local control_w = PANEL_W-label_w
  local control_short_w = 80
  local display_as_items = table.copy(xStreamArg.DISPLAYS)
  table.insert(display_as_items,1,"(select)")
  local content = vb:column{
    vb:space{
      height = 6,
    },
    vb:column{
      style = "group",
      width = PANEL_W,
      margin = 4,
      spacing = 1,
      vb:row{
        tooltip = "Enter a name for the argument - it will be accessed in the"
                .."\ncallback using this syntax: 'args.your_name_here'"
                .."\n(note: xStream will offer to update the callback when you"
                .."\nare assigning a new name to an existing argument)",
        vb:text{
          text = "name",
          font = "mono",
          width = label_w,
        },
        vb:textfield{
          id = "xStreamArgsEditorName",
          value = "...",
          width = control_w,
        },
      },
      vb:row{
        tooltip = "Enter a description for the argument (this will appear"
                .."\nas a tooltip when you hover the mouse over the control)",
        vb:text{
          text = "description",
          font = "mono",
          width = label_w,
        },
        vb:multiline_textfield{
          id = "xStreamArgsEditorDescription",
          text = "...",
          width = control_w,
          height = 34,
        }
      },
      vb:column{ -- bind or poll
        vb:row{
          tooltip = "Determine if the argument is bound to, or polling some"
                  .."\nvalue in Renoise. Choosing either option will cause"
                  .."\nthe value to be automatically set/synchronized"
                  .."\n(note: can restrict min/max to a valid range)",
          vb:text{
            text = "poll/bind",
            font = "mono",
            width = label_w,
          },
          vb:popup{
            id = "xStreamArgsEditorBindOrPoll",
            width = 50,
            items = {
              "off",
              "bind",
              "poll",
            },
            notifier = function(idx)
              local view_text = vb.views["xStreamArgsEditorBindOrPollValue"]
              local view_min = vb.views["xStreamArgsEditorMinValue"]
              local view_max = vb.views["xStreamArgsEditorMaxValue"]
              view_min.active = (idx ~= 2) 
              view_max.active = (idx ~= 2) 
              if (renoise.API_VERSION > 4) then
                view_text.active = (idx > 1) 
              else
                view_text.visible = (idx > 1) 
              end
            end,
          },
          vb:textfield{
            id = "xStreamArgsEditorBindOrPollValue",
            text = "...",
            --font = "mono",
            width = control_w-50,
          },
        },

      },

      vb:column{ -- impacts_buffer
        vb:row{
          tooltip = "When this is enabled, the buffer is recalculated each time"
                  .."\nthe argument value has changed. This ensures that changes"
                  .."\nare written to the pattern as fast as possible"
                  .."\nDefault value is 'enabled'",
          vb:text{
            text = "re-buffer",
            font = "mono",
            width = label_w,
          },
          vb:checkbox{
            id = "xStreamArgsEditorImpactsBuffer",
            value = false,
          },

        },

      },


      vb:row{ -- value-type
        tooltip = "Determine the basic type of value",
        vb:text{
          text = "value-type",
          font = "mono",
          width = label_w,
        },
        vb:popup{
          id = "xStreamArgsEditorType",
          items = xStreamArg.BASE_TYPES,
          notifier = function()
            local view_props = self.vb.views["xStreamArgsEditorPropControls"]
            local view_popup = self.vb.views["xStreamArgsEditorDisplayAs"]
            local view_bop = self.vb.views["xStreamArgsEditorBindOrPoll"]
            local view_bop_value = self.vb.views["xStreamArgsEditorBindOrPollValue"]
            view_props.visible = false
            view_popup.value = 1
            view_bop.value = 1
            view_bop_value.text = ""
          end,
        },
      },
      vb:row{ -- display as
        tooltip = "Choose a supported display/edit control",
        vb:text{
          text = "display_as",
          font = "mono",
          width = label_w,
        },
        vb:popup{
          id = "xStreamArgsEditorDisplayAs",
          items = display_as_items,
          notifier = function(idx)
            --print("idx",idx)
            self:show_relevant_arg_edit_controls(idx-1)
            local view_props = self.vb.views["xStreamArgsEditorPropControls"]
            view_props.visible = true
          end
        },
      },
      vb:column{
        id = "xStreamArgsEditorPropControls",
        vb:row{
          tooltip = "Specify the minimum value"
                  .."\nNote: 'bind' sets this value automatically)",
          id = "xStreamArgsEditorMinValueRow",
          vb:text{
            text = "min",
            font = "mono",
            width = label_w,
          },
          vb:row{
            style = "plain",
            vb:valuefield{
              id = "xStreamArgsEditorMinValue",
              value = 0,
              min = xStreamUI.ARGS_MIN_VALUE,
              max = xStreamUI.ARGS_MAX_VALUE,
              width = control_short_w,
            },
          },
        },
        vb:row{
          id = "xStreamArgsEditorMaxValueRow",
          tooltip = "Specify the maximum value"
                  .."\nNote: 'bind' sets this value automatically)",
          vb:text{
            text = "max",
            font = "mono",
            width = label_w,
          },
          vb:row{
            style = "plain",
            vb:valuefield{
              id = "xStreamArgsEditorMaxValue",
              value = 0,
              min = xStreamUI.ARGS_MIN_VALUE,
              max = xStreamUI.ARGS_MAX_VALUE,
              width = control_short_w,
            },
          },
        },
        vb:row{
          tooltip = "Specify if value is zero-based",
          id = "xStreamArgsEditorZeroBasedRow",
          vb:text{
            text = "zero-based",
            font = "mono",
            width = label_w,
          },
          vb:checkbox{
            id = "xStreamArgsEditorZeroBased",
            value = false,
          },
        },
        vb:row{
          tooltip = "Link with similarly-named arguments",
          id = "xStreamArgsEditorLinkedRow",
          vb:text{
            text = "linked",
            font = "mono",
            width = label_w,
          },
          vb:checkbox{
            id = "xStreamArgsEditorLinked",
            value = false,
          },
        },
        vb:row{
          tooltip = "Lock - prevent changes to value",
          id = "xStreamArgsEditorLockedRow",
          vb:text{
            text = "locked",
            font = "mono",
            width = label_w,
          },
          vb:checkbox{
            id = "xStreamArgsEditorLocked",
            value = false,
          },
        },
        vb:row{
          id = "xStreamArgsEditorItemsRow",
          tooltip = "Specify items for a popup/chooser/switch",
          vb:text{
            text = "items",
            font = "mono",
            width = label_w,
          },
          vb:multiline_textfield{
            id = "xStreamArgsEditorItems",
            value = "...",
            width = control_w,
            height = 60,
          },
        },

        vb:column{ -- fire_on_start
          vb:row{
            tooltip = "When enabled, the argument will fire its value once loaded,"
                    .."\ncalling any associated event handlers as a result."
                    .."\nDefault value is 'enabled'",
            vb:text{
              text = "fire-start",
              font = "mono",
              width = label_w,
            },
            vb:checkbox{
              id = "xStreamArgsEditorFireOnStart",
              value = false,
            },

          },

        },

      },
      vb:column{
        vb:space{
          height = 6,
        },
        vb:row{
          vb:button{
            id = "xStreamArgsEditorRemoveButton",
            tooltip = "Remove this argument",
            text = "Remove",
            notifier = function()
              local str_msg = "Are you sure you want to remove this argument?"
                            .."\n(the model might stop working if it's in use...)"
              local choice = renoise.app():show_prompt("Remove argument",str_msg,{"OK","Cancel"})
              if (choice == "OK") then
                local idx = self.xstream.selected_model.args.selected_index
                self.xstream.selected_model.args:remove(idx)
                self.visible = false
              end
            end
          },
          vb:button{
            id = "xStreamArgsEditorApplyButton",
            tooltip = "Update the argument with current settings",
            text = "Apply changes",
            notifier = function()
              local applied,err = self:apply_arg_settings()
              if not applied and err then
                renoise.app():show_warning(err)
              elseif applied then
                --self.visible = false
              end
            end
          }
        }
      }
    },
  }

  return content

end


--------------------------------------------------------------------------------

function xStreamUIArgsEditor:show_relevant_arg_edit_controls(display_as)
  TRACE("xStreamUIArgsEditor:show_relevant_arg_edit_controls(display_as)",display_as)

  local view_min_value_row  = self.vb.views["xStreamArgsEditorMinValueRow"]
  local view_max_value_row  = self.vb.views["xStreamArgsEditorMaxValueRow"]
  local view_zero_based_row = self.vb.views["xStreamArgsEditorZeroBasedRow"]
  local view_items_row      = self.vb.views["xStreamArgsEditorItemsRow"]

  local supports_min_max = table.find(xStreamArg.SUPPORTS_MIN_MAX,display_as) and true or false
  view_min_value_row.visible = supports_min_max
  view_max_value_row.visible = supports_min_max
  
  local supports_zero_based = table.find(xStreamArg.SUPPORTS_ZERO_BASED,display_as) and true or false
  view_zero_based_row.visible = supports_zero_based

  local items_required = table.find(xStreamArg.REQUIRES_ITEMS,display_as) and true or false
  view_items_row.visible = items_required 

end

--------------------------------------------------------------------------------
-- create arg from the current state of the argument editor 
-- @param arg_index
-- @return table or false 
-- @return string, error message when failed

function xStreamUIArgsEditor:create_arg_descriptor(arg_index,arg_value)

  local view_name           = self.vb.views["xStreamArgsEditorName"]
  local view_description    = self.vb.views["xStreamArgsEditorDescription"]
  local view_type           = self.vb.views["xStreamArgsEditorType"]
  local view_display_as     = self.vb.views["xStreamArgsEditorDisplayAs"]
  local view_buffer         = self.vb.views["xStreamArgsEditorImpactsBuffer"]
  local view_fire_on_start  = self.vb.views["xStreamArgsEditorFireOnStart"]
  local view_min_value      = self.vb.views["xStreamArgsEditorMinValue"]
  local view_max_value      = self.vb.views["xStreamArgsEditorMaxValue"]
  local view_zero_based     = self.vb.views["xStreamArgsEditorZeroBased"]
  local view_linked         = self.vb.views["xStreamArgsEditorLinked"]
  local view_locked         = self.vb.views["xStreamArgsEditorLocked"]
  local view_items          = self.vb.views["xStreamArgsEditorItems"]
  local view_bop   = self.vb.views["xStreamArgsEditorBindOrPoll"]
  local view_bop_value = self.vb.views["xStreamArgsEditorBindOrPollValue"]

  local args = self.xstream.selected_model.args
  local str_type = xStreamArg.BASE_TYPES[view_type.value]

  local supported_types = function(t)
    local rslt = {}
    for k,v in ipairs(t) do
      table.insert(rslt,xStreamArg.DISPLAYS[v])
    end
    return ("Unsupported 'display_as' value - please change the value-type."
      .."\nSupported: %s"):format(table.concat(rslt,","))
  end

  -- if we have changed value type, set to default value
  if type(arg_value) ~= str_type then
    if (str_type == "number") then
      arg_value = view_min_value.value
    elseif (str_type == "boolean") then
      arg_value = false
    elseif (str_type == "string") then
      arg_value = ""
    end
  end

  --print("*** xStreamUIArgsEditor:apply_arg_settings - arg_value",arg_value)

  -- *enabled* bind/poll should not contain blank lines

  local arg_bind,arg_poll
  if (view_bop.value == 2) then
    arg_bind = view_bop_value.text
    if (arg_bind == "") then
      local keys = table.concat(cObservable.get_keys_by_type(str_type,"rns."),"\n")
      return false, ("Error: 'bind' needs an observable property, try one of these: \n%s"):format(keys)
    end
  elseif (view_bop.value == 3) then
    arg_poll = view_bop_value.text
    if (arg_poll == "") then
      return false, "Error: 'poll' should reference a property that match the type of value, e.g."
                  .."\n'rns.selected_instrument_index' for a number, or "
                  .."\n'rns.transport.edit_mode' for a boolean value"
    end
  end

  local arg_props = {}
  
  -- validate display_as (correct type)

  local base_type = view_type.value
  local display_as = view_display_as.value-1
  local err
  if (base_type == xStreamArg.BASE_TYPE.NUMBER) then
    if not table.find(xStreamArg.NUMBER_DISPLAYS,display_as) then
      err =  supported_types(xStreamArg.NUMBER_DISPLAYS)
    else
      if table.find(xStreamArg.SUPPORTS_MIN_MAX,display_as) then
        arg_props.min = view_min_value.value
        arg_props.max = view_max_value.value
        if (arg_props.max < arg_props.min) then
          return false, "Error: 'max' needs to be higher than 'min'"
        end
      end
      if table.find(xStreamArg.SUPPORTS_ZERO_BASED,display_as) then
        arg_props.zero_based = view_zero_based.value
      end
      if table.find(xStreamArg.REQUIRES_ITEMS,display_as) then
        local arg_items = {}
        for k,v in ipairs(view_items.paragraphs) do
          if (v == "") then
            return false, "Error: 'items' should not contain blank lines"
          end
          table.insert(arg_items,cString.trim(v))
        end
        if (#arg_items == 1) then
          return false, "Error: 'items' needs at least two lines/items"
        end
        arg_props.min = 1
        arg_props.max = #arg_items
        arg_props.items = arg_items
      end
    end
  elseif (base_type == xStreamArg.BASE_TYPE.BOOLEAN) then
    if not table.find(xStreamArg.BOOLEAN_DISPLAYS,display_as) then
      err = supported_types(xStreamArg.BOOLEAN_DISPLAYS)
    end
  elseif (base_type == xStreamArg.BASE_TYPE.STRING) then
    if not table.find(xStreamArg.STRING_DISPLAYS,display_as) then
      err =  supported_types(xStreamArg.STRING_DISPLAYS)
    end
  end
  if err then
    return false, err
  end

  arg_props.display_as = xStreamArg.DISPLAYS[display_as]

  -- validate bind + poll

  if arg_bind then
    local is_valid,err = args:is_valid_bind_value(arg_bind,str_type)
    if not is_valid then
      return false,err
    end
  end

  if arg_poll then
    local is_valid,err = args:is_valid_poll_value(arg_poll)
    if not is_valid then
      return false,err
    end
  end


  -- props: min,max
  --print("arg_value pre",arg_value)

  if type(arg_value)=="number" and arg_props.min and arg_props.max then
    arg_value = math.min(arg_props.max,arg_value)
    arg_value = math.max(arg_props.min,arg_value)
  end

  arg_props.impacts_buffer = view_buffer.value
  arg_props.fire_on_start = view_fire_on_start.value

  -- return table 

  local descriptor = {
    name = view_name.value,
    description = view_description.text,
    value = arg_value,
    bind = arg_bind,
    poll = arg_poll,
    linked = view_linked.value,
    locked = view_locked.value,
    properties = arg_props,
  }

  return descriptor

end

--------------------------------------------------------------------------------
-- @return bool, true when applied
-- @return string, error message when failed

function xStreamUIArgsEditor:apply_arg_settings()
  TRACE("xStreamUIArgsEditor:apply_arg_settings()")

  local model = self.xstream.selected_model
  local arg_idx = model.args.selected_index

  -- changed value type? 
  local old_value = model.args.args[arg_idx].value
  local arg_descriptor,err = self:create_arg_descriptor(arg_idx,old_value)
  if not arg_descriptor then
    return false,err
  end

  local replaced,err = model.args:replace(arg_idx,arg_descriptor)
  if not replaced and err then
    return false,err
  end

  return true

end

--------------------------------------------------------------------------------

function xStreamUIArgsEditor:update()
  TRACE("xStreamUIArgsEditor:update()")

  if not self.xstream.selected_model then
    --print("*** xStreamUIArgsEditor:update - no model selected...")
    return
  end

  if not self.visible then
    --print("*** xStreamUIArgsEditor:update - editor not visible")
    return
  end

  local model = self.xstream.selected_model
  if (model.args.selected_index == 0) then 
    self.visible = false
  end

  local view_name         = self.vb.views["xStreamArgsEditorName"]
  local view_description  = self.vb.views["xStreamArgsEditorDescription"]
  local view_type         = self.vb.views["xStreamArgsEditorType"]
  local view_display_as   = self.vb.views["xStreamArgsEditorDisplayAs"]
  local view_buffer       = self.vb.views["xStreamArgsEditorImpactsBuffer"]
  local view_fire_on_start= self.vb.views["xStreamArgsEditorFireOnStart"]
  local view_props        = self.vb.views["xStreamArgsEditorPropControls"]
  local view_min_value    = self.vb.views["xStreamArgsEditorMinValue"]
  local view_max_value    = self.vb.views["xStreamArgsEditorMaxValue"]
  local view_zero_based   = self.vb.views["xStreamArgsEditorZeroBased"]
  local view_linked       = self.vb.views["xStreamArgsEditorLinked"]
  local view_locked       = self.vb.views["xStreamArgsEditorLocked"]
  local view_items        = self.vb.views["xStreamArgsEditorItems"]
  local view_poll_or_bind = self.vb.views["xStreamArgsEditorBindOrPoll"]
  local view_bop_value    = self.vb.views["xStreamArgsEditorBindOrPollValue"]
  local view_remove_bt    = self.vb.views["xStreamArgsEditorRemoveButton"]
  local view_apply_bt     = self.vb.views["xStreamArgsEditorApplyButton"]

  local has_selected = (self.xstream.selected_model.args.selected_index > 0)

  if (renoise.API_VERSION > 4) then
    view_name.active = has_selected
    view_description.active = has_selected
    view_items.active = has_selected
    --view_bop_value.active = has_selected
  else
    view_name.visible = has_selected
    view_description.visible = has_selected
    view_items.visible = has_selected
  end
  view_apply_bt.active = has_selected
  view_remove_bt.active = has_selected
  view_type.active = has_selected
  view_display_as.active = has_selected
  view_buffer.active = has_selected
  view_fire_on_start.active = has_selected
  view_min_value.active = has_selected
  view_max_value.active = has_selected
  view_zero_based.active = has_selected
  view_linked.active = has_selected
  view_locked.active = has_selected
  view_poll_or_bind.active = has_selected

  local arg = self.xstream.selected_model.args.selected_arg
  if not arg then
    --print("*** xStreamUIArgsEditor:update - no arg selected...")
    return
  end
  
  -- TODO deduce valid range from all known renoise observables (cObservable)
  if (view_poll_or_bind.value == 1) then
    view_min_value.active = true
  else
    view_min_value.active = false
    view_min_value.value = 1
  end

  --view_locked.value = arg.locked
  view_name.text = arg.tab_name and arg.tab_name.."."..arg.name or arg.name
  view_description.text = arg.description or ""
  
  local base_type
  if (type(arg.observable) == "ObservableNumber") then
    base_type = xStreamArg.BASE_TYPE.NUMBER
  elseif (type(arg.observable) == "ObservableBoolean") then
    base_type = xStreamArg.BASE_TYPE.BOOLEAN
  elseif (type(arg.observable) == "ObservableString") then
    base_type = xStreamArg.BASE_TYPE.STRING
  else
    --print("unexpected base type",arg.observable,type(arg.observable))
    return
  end
  view_type.value = base_type

  view_props.visible = true

  -- supply a default display 
  local display_as = table.find(xStreamArg.DISPLAYS,arg.properties.display_as)
  if not display_as then
    if (base_type == xStreamArg.BASE_TYPE.NUMBER) then
      display_as = arg.properties.items and xStreamArg.DISPLAY_AS.POPUP
        or xStreamArg.DISPLAY_AS.FLOAT
    elseif (base_type == xStreamArg.BASE_TYPE.BOOLEAN) then
      display_as = xStreamArg.DISPLAY_AS.CHECKBOX
    elseif (base_type == xStreamArg.BASE_TYPE.STRING) then
      display_as = xStreamArg.DISPLAY_AS.STRING
    end
  end
  --print("display_as",display_as)
  view_display_as.value = display_as+1

  local bop_value,bop_str
  if (arg.bind_str) then
    bop_value = 2
    bop_str = arg.bind_str
  elseif (arg.poll_str) then
    bop_value = 3
    bop_str = arg.poll_str
  else
    bop_value = 1
    bop_str = ""
  end
  view_poll_or_bind.value = bop_value
  view_bop_value.text = bop_str
  if (renoise.API_VERSION > 4) then
    view_bop_value.active = (bop_value > 1)
  else
    view_bop_value.visible = (bop_value > 1)
  end

  view_buffer.value = arg.properties.impacts_buffer
  view_fire_on_start.value = arg.properties.fire_on_start

  self:show_relevant_arg_edit_controls(display_as)
  
  view_min_value.value = arg.properties.min or xStreamUI.ARGS_MIN_VALUE
  view_max_value.value = arg.properties.max or xStreamUI.ARGS_MAX_VALUE
  view_zero_based.value = arg.properties.zero_based or false
  view_linked.value = arg.linked or false
  view_locked.value = arg.locked or false
  view_items.text = arg.properties.items and table.concat(arg.properties.items,"\n") or ""
  
end

