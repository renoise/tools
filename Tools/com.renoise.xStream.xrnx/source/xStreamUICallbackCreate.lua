--[[============================================================================
xStreamUICallbackCreate
============================================================================]]--

--[[

Supporting UI class for xStream

]]

--==============================================================================

local EVENT_TYPE = {
  ARGUMENT = 1,
  OTHER = 2,
}

local ARG_TYPES = {"number","table","boolean","string","function"}

class 'xStreamUICallbackCreate' (vDialogWizard)

function xStreamUICallbackCreate:__init(ui)
  TRACE("xStreamUICallbackCreate:__init(ui)",ui)

  vDialogWizard.__init(self)

  self.title = "Create callback"

  self.ui = ui
  self.xstream = self.ui.xstream

  -- xStreamModel.CB_TYPE
  self.cb_type = nil

  -- EVENT_TYPE.xxx
  self.event_type = nil

end

--------------------------------------------------------------------------------
-- as a consequence of dialog option being changed

function xStreamUICallbackCreate:update_cb_type()

  if (self.dialog_option == 1) then 
    self.cb_type = xStreamModel.CB_TYPE.EVENTS
  elseif (self.dialog_option == 2) then 
    self.cb_type = xStreamModel.CB_TYPE.DATA
  end

end

--------------------------------------------------------------------------------
-- (overridden method)

function xStreamUICallbackCreate:show()

  vDialogWizard.show(self)

  self.dialog_page = 1
  self.dialog_option = 1
  self:update_cb_type()
  self:update_dialog()

end

-------------------------------------------------------------------------------
-- (overridden method)
-- @return renoise.Views.Rack

function xStreamUICallbackCreate:create_dialog()
  TRACE("xStreamUICallbackCreate:create_dialog()")

  local vb = self.vb

  local PAGE_W = 250
  local PAGE_H = 70
  local TEXT_H = 150

  local content = vb:column{
    vb:space{
      width = PAGE_W,
    },
    vb:row{
      margin = 6,
      vb:row{
        vb:space{
          height = PAGE_H,
        },
        vb:column{
          id = "xStreamNewModelDialogPage1",
          vb:text{
            text = "Please choose:",
          },
          vb:chooser{
            id = "xStreamNewModelDialogOptionChooser",
            value = self.dialog_option,
            items = {
              "Add event handler",
              "Add userdata (value or function)",
            },
            notifier = function(idx)
              self.dialog_option = idx
              self:update_cb_type()
            end
          },
        },
        vb:column{
          visible = false,
          id = "xStreamNewModelDialogPage2",
          vb:column{
            id = "xStreamNewModelDialogPage2Option1",
            vb:text{
              text = "Specify a name for the argument",
            },
            vb:textfield{
              id = "xStreamDialogName",
              text = "",
              width = PAGE_W-20,
            },
            vb:text{
              text = "Choose a type (template)",
            },
            vb:chooser{
              id = "xStreamDialogArgumentTypes",
              items = ARG_TYPES,
            }
          },
          vb:column{
            id = "xStreamNewModelDialogPage2Option2",
            vb:column{
              id = "xStreamDialogArguments",
              vb:row{
                vb:checkbox{
                  id = "xStreamDialogEventSwitcherArgs",
                  value = true,
                  notifier = function(val)
                    if val then
                      self:event_switcher(EVENT_TYPE.ARGUMENT)
                    end
                  end,
                },
                vb:text{
                  text = "Attach to argument",
                },
                vb:popup{
                  id = "xStreamDialogArgumentsPopup",
                  --items = vb_argument_items,
                }
              }
            },
            vb:row{
              vb:checkbox{
                id = "xStreamDialogEventSwitcherOther",
                value = false,
                notifier = function(val)
                  if val then
                    self:event_switcher(EVENT_TYPE.OTHER)
                  end
                end
              },
              vb:text{
                text = "Or choose from the available events",
              },
            },

            vb:chooser{
              id = "xStreamDialogEventChooser",
              items = self:get_available_event_names(),
              value = 1,
              active = false
            }
          },

        }
      },
    }
  }
  local navigation = vb:row{
    margin = 6,
    vb:button{
      id = "xStreamDialogPrevButton",
      text = "Previous",
      active = false,
      notifier = function()
        self:show_prev_page()
      end
    },
    vb:button{
      id = "xStreamDialogNextButton",
      text = "Next",
      notifier = function()
        self:show_next_page()
      end
    },
    vb:button{
      id = "xStreamNewModelDialogCancelButton",
      text = "Cancel",
      notifier = function()
        self.dialog:close()
        self.dialog = nil
      end
    },
  }

  return vb:column{
    content,
    navigation,
  }

end

-------------------------------------------------------------------------------

function xStreamUICallbackCreate:update_dialog()
  TRACE("xStreamUICallbackCreate:update_dialog()")

  local vb = self.vb
  local model = self.xstream.selected_model
  local vb_argument_items = model.args:get_names()

  -- update page

  local args = vb.views["xStreamDialogArguments"]
  local args_popup = vb.views["xStreamDialogArgumentsPopup"]
  args.visible = false

  local view_page_1       = vb.views["xStreamNewModelDialogPage1"]
  local view_page_2       = vb.views["xStreamNewModelDialogPage2"]
  local view_page_2_opt1  = vb.views["xStreamNewModelDialogPage2Option1"]
  local view_page_2_opt2  = vb.views["xStreamNewModelDialogPage2Option2"]
  local view_opt_chooser  = vb.views["xStreamNewModelDialogOptionChooser"]

  view_page_1.visible = false
  view_page_2.visible = false
  view_page_2_opt1.visible = false
  view_page_2_opt2.visible = false

  if (self.dialog_page == 1) then
    
    view_page_1.visible = true
    
    view_opt_chooser.value = self.dialog_option
    self.event_type = not table.is_empty(vb_argument_items) 
      and EVENT_TYPE.ARGUMENT or EVENT_TYPE.OTHER

  elseif (self.dialog_page == 2) then
    
    view_page_2.visible = true
    
    if (self.cb_type == xStreamModel.CB_TYPE.DATA) then
      
      view_page_2_opt1.visible = true
      
      local str_name = model:get_suggested_callback_name("my_userdata",self.cb_type)
      local view_name = vb.views["xStreamDialogName"]
      view_name.text = str_name

    elseif (self.cb_type == xStreamModel.CB_TYPE.EVENTS) then

      view_page_2_opt2.visible = true

      self:event_switcher(self.event_type)
      args_popup.items = vb_argument_items
      args.visible = true

    end
  end

  -- update navigation

  local view_prev_button  = vb.views["xStreamDialogPrevButton"]
  local view_next_button  = vb.views["xStreamDialogNextButton"]
  view_prev_button.active = (self.dialog_page > 1) and true or false
  view_next_button.text = (self.dialog_page == 2) and "Done" or "Next"

end


-------------------------------------------------------------------------------
-- (overridden method)

function xStreamUICallbackCreate:show_prev_page()
  TRACE("xStreamUICallbackCreate:show_prev_page()")

  if (self.dialog_page > 1) then
    self.dialog_page = self.dialog_page - 1
  else
    self.cb_type = nil
  end
  self:update_dialog()

end

-------------------------------------------------------------------------------
-- (overridden method)

function xStreamUICallbackCreate:show_next_page()
  TRACE("xStreamUICallbackCreate:show_next_page()")

  local vb = self.vb
  local model = self.xstream.selected_model

  --[[
  if (self.dialog_option == 1) then 
    self.cb_type = xStreamModel.CB_TYPE.DATA
  elseif (self.dialog_option == 2) then 
    self.cb_type = xStreamModel.CB_TYPE.EVENTS
  end
  ]]
  --print("self.cb_type",self.cb_type)

  if (self.dialog_page == 1) then

    -- wait for user choise

  elseif (self.dialog_page == 2) then

    if (self.cb_type == xStreamModel.CB_TYPE.DATA) then 
    
      -- create userdata 

      local view_name = vb.views["xStreamDialogName"]
      if not self:validate_callback_name(view_name.text) then
        renoise.app():show_warning("Error: a callback already exists with this name, or you provided an invalid name")
        return
      else

        -- pick a template
        local vb_arg_types = vb.views["xStreamDialogArgumentTypes"]
        local arg_type = vb_arg_types.items[vb_arg_types.value]
        print(">>> vb_arg_types",vb_arg_types)
        print(">>> vb_arg_types",vb_arg_types)
        print(">>> arg_type",arg_type)
        local str_fn = self:get_userdata_template(arg_type)
        print(">>> str_fn",str_fn)

        model:add_userdata(view_name.text,str_fn)
        self.ui.editor_view = ("data.%s"):format(view_name.text)
        self.ui:update_editor()
        --self.ui.update_editor_view_popup = true
        self.dialog:close()
        self.dialog = nil
      end

    elseif (self.cb_type == xStreamModel.CB_TYPE.EVENTS) then 
    
      -- create event

      local str_name = nil
      
      if (self.event_type == EVENT_TYPE.ARGUMENT) then
        local vb_popup = self.vb.views["xStreamDialogArgumentsPopup"]
        str_name = "args."..vb_popup.items[vb_popup.value]
      else
        local vb_chooser = self.vb.views["xStreamDialogEventChooser"]
        str_name = vb_chooser.items[vb_chooser.value]
      end
      print("str_name",str_name)

      if not self:validate_callback_name(str_name) then
        renoise.app():show_warning("Error: a callback already exists with this name, or you provided an invalid name")
        return
      else

        model:add_event(str_name)
        self.ui.editor_view = ("events.%s"):format(str_name)
        self.ui:update_editor()
        self.dialog:close()
        self.dialog = nil
      end

    end

  end

  self.dialog_page = self.dialog_page + 1
  self:update_dialog()

end


-------------------------------------------------------------------------------

function xStreamUICallbackCreate:validate_callback_name(str_name)
  TRACE("xStreamUICallbackCreate:validate_callback_name(str_name)",str_name)

  local model = self.xstream.selected_model
  local str_name_validate = model:get_suggested_callback_name(str_name,self.cb_type)
  --print("str_name,str_name_validate",str_name,str_name_validate)
  return (str_name == str_name_validate) 

end

-------------------------------------------------------------------------------

function xStreamUICallbackCreate:get_available_event_names()
  TRACE("xStreamUICallbackCreate:get_available_event_names()")

  local rslt = {}

  local midi_events = xLib.stringify_table(xMidiMessage.TYPE,"midi.")
  local voice_events = xLib.stringify_table(xVoiceManager.EVENTS,"voice.")

  for k,v in pairs(midi_events) do 
    rslt[k] = v 
  end
  for k,v in pairs(voice_events) do 
    rslt[k] = v 
  end

  local model = self.xstream.selected_model
  for k,v in pairs(model.events) do 
    local cb_type,cb_key,cb_subtype = xStream.parse_callback_type("events."..k)
    --print(">>> get_available_event_names - cb_type,cb_key,cb_subtype",cb_type,cb_key,cb_subtype)
    local event_key = cb_subtype and cb_key.."."..cb_subtype or cb_key
    local event_idx = table.find(rslt,event_key)
    --print(">>> event_idx",event_idx)
    if not event_idx then
      rslt[event_key] = nil
    end
  end
  --print(">>> rslt",rprint(rslt))
  return rslt

end

-------------------------------------------------------------------------------
-- update on switching

function xStreamUICallbackCreate:event_switcher(evt)
  print("xStreamUICallbackCreate:event_switcher()",evt)
  
  local vb = self.vb
  
  local args_popup = vb.views["xStreamDialogArgumentsPopup"]
  local event_chooser = vb.views["xStreamDialogEventChooser"]
  local event_switcher_other = vb.views["xStreamDialogEventSwitcherOther"]
  local event_switcher_args = vb.views["xStreamDialogEventSwitcherArgs"]
  args_popup.active = false
  event_chooser.active = false

  if (evt == EVENT_TYPE.ARGUMENT) then
    args_popup.active = true
    event_switcher_other.value = false
  elseif (evt == EVENT_TYPE.OTHER) then
    event_chooser.active = true
    event_switcher_args.value = false
  end

  self.event_type = evt

end

-------------------------------------------------------------------------------
-- @param arg_type (int)

function xStreamUICallbackCreate:get_userdata_template(arg_type)

  local arg_types = {
    ["number"]   = '-- return a value of some kind \nreturn 42',
    ["table"]    = '-- return a value of some kind \nreturn {"some_value"}',
    ["boolean"]  = '-- return a value of some kind \nreturn true',
    ["string"]   = '-- return a value of some kind \nreturn "hello world"',
    ["function"] = [[-- return a value of some kind
return function(arg)
  return "you provided this value: "..tostring(arg)
end
]],
  }

  return arg_types[arg_type]

end