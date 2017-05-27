--[[============================================================================
xStreamUICallbackCreate
============================================================================]]--

--[[

Supporting UI class for xStream

]]

--==============================================================================

local EVENTS_LABEL_W = 80
local EVENTS_POPUP_W = 175

local EVENT_TYPE = {
  ARGUMENT = 1,
  RENOISE = 2,
  OTHER = 3,
}

local ARG_TYPES = {"number","table","boolean","string","function"}

--------------------------------------------------------------------------------

require (_clibroot.."cObservable")

class 'xStreamUICallbackCreate' (vDialogWizard)

--------------------------------------------------------------------------------

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
              "Add data (value or function)",
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
                  text = "Arguments",
                  width = EVENTS_LABEL_W,
                },
                vb:popup{
                  id = "xStreamDialogArgumentsPopup",
                  width = EVENTS_POPUP_W,
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
                text = "Model events",
                width = EVENTS_LABEL_W,
              },
              vb:popup{
                id = "xStreamDialogEventChooser",
                width = EVENTS_POPUP_W,
                --items = self:get_available_event_names(),
                --value = 1,
                active = false
              },
            },

            vb:row{
              vb:checkbox{
                id = "xStreamDialogEventSwitcherRenoise",
                value = false,
                notifier = function(val)
                  if val then
                    self:event_switcher(EVENT_TYPE.RENOISE)
                  end
                end
              },

              vb:text{
                text = "Renoise events",
                width = EVENTS_LABEL_W,
              },
              vb:popup{
                id = "xStreamDialogRenoiseEvents",
                width = EVENTS_POPUP_W,
                active = false,
              }
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
  local vb_argument_items = self.xstream.selected_model.args:get_names()

  -- update page

  local args = vb.views["xStreamDialogArguments"]
  local args_popup = vb.views["xStreamDialogArgumentsPopup"]
  args.visible = false

  local vb_chooser = self.vb.views["xStreamDialogEventChooser"]
  vb_chooser.items = self:get_available_event_names()

  local vb_renoise_events = self.vb.views["xStreamDialogRenoiseEvents"]
  vb_renoise_events.items = cObservable.get_song_names()

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

    -- enable arguments as default when present
    self.event_type = not table.is_empty(vb_argument_items) 
      and EVENT_TYPE.ARGUMENT or EVENT_TYPE.OTHER

  elseif (self.dialog_page == 2) then
    
    view_page_2.visible = true
    
    if (self.cb_type == xStreamModel.CB_TYPE.DATA) then
      
      view_page_2_opt1.visible = true
      
      local str_name = self.xstream.selected_model:get_suggested_callback_name("my_data",self.cb_type)
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

  -- 

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
    
      -- create data 

      local view_name = vb.views["xStreamDialogName"]
      if not self:validate_callback_name(view_name.text) then
        renoise.app():show_warning("Error: a callback already exists with this name, or you provided an invalid name")
        return
      else

        -- pick a template
        local vb_arg_types = vb.views["xStreamDialogArgumentTypes"]
        local arg_type = vb_arg_types.items[vb_arg_types.value]
        local str_fn = self:get_data_template(arg_type)

        self.xstream.selected_model:add_data(view_name.text,str_fn)
        self.ui.lua_editor.editor_view = ("data.%s"):format(view_name.text)
        self.ui.lua_editor:update()
        self.dialog:close()
        self.dialog = nil
      end

    elseif (self.cb_type == xStreamModel.CB_TYPE.EVENTS) then 
    
      -- create event

      local str_name = nil
      
      if (self.event_type == EVENT_TYPE.ARGUMENT) then
        local vb_popup = self.vb.views["xStreamDialogArgumentsPopup"]
        str_name = "args."..vb_popup.items[vb_popup.value]
      elseif (self.event_type == EVENT_TYPE.OTHER) then
        local vb_chooser = self.vb.views["xStreamDialogEventChooser"]
        str_name = vb_chooser.items[vb_chooser.value]
      elseif (self.event_type == EVENT_TYPE.RENOISE) then
        local vb_renoise = self.vb.views["xStreamDialogRenoiseEvents"]
        str_name = vb_renoise.items[vb_renoise.value]
      end
      --print("str_name",str_name)

      if not self:validate_callback_name(str_name) then
        renoise.app():show_warning("Error: a callback already exists with this name, or you provided an invalid name")
        return
      else

        self.xstream.selected_model:add_event(str_name)
        self.ui.lua_editor.editor_view = ("events.%s"):format(str_name)
        self.ui.lua_editor:update()
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

  local str_name_validate = self.xstream.selected_model:get_suggested_callback_name(str_name,self.cb_type)
  --print("str_name,str_name_validate",str_name,str_name_validate)
  return (str_name == str_name_validate) 

end

-------------------------------------------------------------------------------
-- get list of 'model events' 

function xStreamUICallbackCreate:get_available_event_names()
  TRACE("xStreamUICallbackCreate:get_available_event_names()")

  local rslt = {}

  local midi_events = cLib.stringify_table(xMidiMessage.TYPE,"midi.")
  local voice_events = cLib.stringify_table(xVoiceManager.EVENTS,"voice.")

  for k,v in pairs(midi_events) do 
    rslt[k] = v 
  end
  for k,v in pairs(voice_events) do 
    rslt[k] = v 
  end

  for k,v in pairs(self.xstream.selected_model.events) do 
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
  TRACE("xStreamUICallbackCreate:event_switcher()",evt)
  
  local vb = self.vb
  
  local args_popup = vb.views["xStreamDialogArgumentsPopup"]
  local event_chooser = vb.views["xStreamDialogEventChooser"]
  local renoise_events = vb.views["xStreamDialogRenoiseEvents"]
  local event_switcher_renoise = vb.views["xStreamDialogEventSwitcherRenoise"]
  local event_switcher_other = vb.views["xStreamDialogEventSwitcherOther"]
  local event_switcher_args = vb.views["xStreamDialogEventSwitcherArgs"]
  args_popup.active = false
  event_chooser.active = false
  renoise_events.active = false

  if (evt == EVENT_TYPE.ARGUMENT) then
    args_popup.active = true
    event_switcher_other.value = false
    event_switcher_renoise.value = false
  elseif (evt == EVENT_TYPE.OTHER) then
    event_chooser.active = true
    event_switcher_args.value = false
    event_switcher_renoise.value = false
  elseif (evt == EVENT_TYPE.RENOISE) then
    renoise_events.active = true
    event_switcher_args.value = false
    event_switcher_other.value = false
  end

  self.event_type = evt

end

-------------------------------------------------------------------------------
-- @param arg_type (int)

function xStreamUICallbackCreate:get_data_template(arg_type)

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