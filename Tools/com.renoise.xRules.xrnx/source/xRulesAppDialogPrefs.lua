--[[============================================================================
xRulesAppDialogPrefs
============================================================================]]--

--[[

  This is a supporting class for xRulesApp

]]

--==============================================================================

class 'xRulesAppDialogPrefs' (vDialog)

local DIALOG_W = 460
local DIALOG_MARGIN = 6
local LABEL_W = 60
local TABLE_W = DIALOG_W/2 - (DIALOG_MARGIN)
local TABLE_ROW_H = 19
local MIDI_ROWS = 5
local OSC_ROWS = 5
local OSC_LABEL_W = 70
local OSC_CONTROL_W = 90

function xRulesAppDialogPrefs:__init(ui)

  vDialog.__init(self)

  -- xRulesUI, instance of parent class
  self.ui = ui

  -- xRulesApp
  self.owner = self.ui.owner

  -- xRules
  self.xrules = self.ui.owner.xrules

  -- xRulesAppPrefs
  self.prefs = self.ui.owner.prefs

  self.title = "xRules preferences"

  -- vLib components
  self.vtable_midi_inputs = nil
  self.vtable_midi_outputs = nil
  self.vtable_osc_devices = nil
  
  -- initialize --

  -- prevent device editing while inactive
  -- (as we are exporting actual devices to the preferences,
  -- and no devices are present while disabled...)
  self.xrules.active_observable:add_notifier(function()
    if self.vtable_osc_devices then
      self.vtable_osc_devices.active = self.xrules.active
    end
    if self.vtable_midi_inputs then
      self.vtable_midi_inputs.active = self.xrules.active
    end
    if self.vtable_midi_outputs then
      self.vtable_midi_outputs.active = self.xrules.active
    end
    local bt = self.vb.views.xRulesPrefsAddOscDevice
    if bt then
      bt.active = self.xrules.active
    end
  end)


end

-------------------------------------------------------------------------------
-- find among midi inputs/outputs
-- @param port_name (string)
-- @return int or nil

function xRulesAppDialogPrefs:match_in_list(list,value)

  local matched = false
  for k = 1, #list do
    if (list[k].value == value) then
      return k
    end
  end

end

-------------------------------------------------------------------------------
-- (overridden method)
-- @return renoise.Views.Rack

function xRulesAppDialogPrefs:create_dialog()

  local vb = self.vb
  local vtable

  --print(">>> self.owner.xprefs",self.owner.xprefs)
  local profiles = self.owner.xprefs:get_profile_names()
  table.insert(profiles,1,"No profile selected")

  local automation_write_items = xLib.stringify_table(xAutomation.WRITE_MODE)
  local automation_follow_items = xLib.stringify_table(xAutomation.FOLLOW_MODE)
  local automation_playmode_items = xAutomation.PLAYMODE_NAMES

  --print(">>> automation_playmode_items",rprint(automation_playmode_items))

  local content = vb:column{
    margin = 6,
    spacing = 3,
    vb:row{
      --width = DIALOG_W,
      spacing = 6,
      vb:column{ -- general settings
        style = "group",
        margin = 6,
        vb:text{
          text = "General options",
          font = "bold",
        },
        vb:row{ -- autorun/show on startup
          vb:checkbox{
            id = "mrules_autorun_enabled",
            value = self.prefs.autorun_enabled.value,
            notifier = function(val)
              self.prefs:property("autorun_enabled").value = val
              if self.prefs:property("show_on_startup").value then
                vb.views["mrules_show_on_startup"].value = val
                --self.prefs:property("show_on_startup").value = val
              end
              vb.views["mrules_show_on_startup"].active = val
            end,
          },
          vb:text{
            text = "Autostart tool",
          },  
        },
        vb:row{
          vb:checkbox{
            id = "mrules_show_on_startup",
            value = self.prefs.show_on_startup.value,
            notifier = function(val)
              self.prefs:property("show_on_startup").value = val
            end,
          },
          vb:text{
            text = "Display user-interface on startup",
          },    
        
        },
        vb:row{ -- ruleset folder
          vb:text{
            text = "Rulesets",
          },
          vb:textfield{
            width = DIALOG_W - 354,
            bind = self.prefs:property("ruleset_folder"),
          },
          vb:button{
            text = "Browse",
            notifier = function()
              local new_path = renoise.app():prompt_for_path("Specify ruleset folder")
              if (new_path ~= "") then
                self.prefs:property("ruleset_folder").value = new_path
              end
            end,
          },
          vb:button{
            text = "Reset",
            notifier = function()
              self.prefs:property("ruleset_folder").value = xRulesAppPrefs.RULESET_FOLDER
            end,
          }
        },
      },
      vb:column{ -- profiles
        style = "group",
        margin = 6,

        vb:text{
          text = "Configurations",
          font = "bold",
        },
        vb:row{
          tooltip = "Enable or disable configuration switching",
          vb:checkbox{
            value = self.owner.xprefs.profiles_enabled,
            notifier = function(val)
              self.owner.xprefs.profiles_enabled = val
              if (val == false) then
                vb.views.xprefs_always_choose_cb.value = false
              end
              self:update_profile_switcher()
            end          
          },
          vb:text{
            text = "Enable profile switching"
          }
        },
        vb:row{
          tooltip = "Enable this feature to choose or manage profiles at startup",
          vb:checkbox{
            id = "xprefs_always_choose_cb",
            value = self.owner.xprefs.always_choose,
            notifier = function(val)
              self.owner.xprefs.always_choose = val
              if val then
                self.owner.xprefs.recall_profile = ""
              end
              self:update_profile_switcher()
            end
          },
          vb:text{
            text = "Choose profile on startup",
          },
        },
        vb:row{
          vb:popup{
            id = "xprefs_profile_selector",
            items = profiles,
            width = 140,
            --active = not self.owner.xprefs.always_choose,
            value = self.owner.xprefs.selected_profile and
              table.find(profiles,self.owner.xprefs.selected_profile.name) or 1,
            notifier = function(idx)
              if (idx == 1) then
                self.owner.xprefs.recall_profile = ""
              else
                local profile_name = self.owner.xprefs.profiles[idx-1].name
                self.owner.xprefs.recall_profile = profile_name
              end
              self:update_profile_switcher()
              local msg = "This change will take effect the next time the tool is launched" 
              renoise.app():show_message(msg)
            end,
          },
          vb:button{
            text = "Update",
            id = "xprefs_update_profile_bt",
            --active = self.owner.xprefs.selected_profile and true or false,
            tooltip = "Update the currently selected profile with the current settings",
            notifier = function()
              local passed,err = self.owner.xprefs:update_profile()
              --print("passed,err",passed,err)
              if passed then
                local msg = "Profile was updated with the current settings"
                renoise.app():show_message(msg)
              else
                local msg = ("A problem occurred while saving profile: %s"):format(err)
                renoise.app():show_warning(msg)
              end
            end
          }
        }
      },
    },
    vb:switch{
      width = 300,
      items = {
        "MIDI",
        "OSC",
        "Automation",
      },
      notifier = function(val)
        vb.views["xRulesPrefsMidiRack"].visible = (val == 1)
        vb.views["xRulesPrefsOscRack"].visible = (val == 2)
        vb.views["xRulesPrefsAutomationRack"].visible = (val == 3)
      end
    },
    vb:column{
      id ="xRulesPrefsMidiRack",
      vb:column{
        width = DIALOG_W,
        style = "group",
        margin = 6,
        vb:text{
          text = "MIDI-options",
          font = "bold",
        },
        vb:row{
          vb:checkbox{
            value = self.prefs.midi_multibyte_enabled.value,
            notifier = function(val)
              self.prefs.midi_multibyte_enabled.value = val
              self.xrules.midi_input.multibyte_enabled = val
            end,
          },
          vb:text{
            text = "Enable multi-byte support (14bit control-change)"
          },
        },
        vb:row{
          vb:checkbox{
            value = self.prefs.midi_nrpn_enabled.value,
            notifier = function(val)
              self.prefs.midi_nrpn_enabled.value = val
              self.xrules.midi_input.nrpn_enabled = val
            end,
          },
          vb:text{
            text = "Enable NRPN support (14bit messages)"
          },
        },
        vb:row{
          vb:checkbox{
            value = self.prefs.midi_terminate_nrpns.value,
            notifier = function(val)
              self.prefs.midi_terminate_nrpns.value = val
              self.xrules.midi_input.terminate_nrpns = val
            end,
          },
          vb:text{
            text = "Require NRPN messages to be terminated"
          },
        },
      },
      vb:row{
        vb:column{
          id = "xRulesPrefsMidiInputRack",
          vb:text{
            text = "MIDI Inputs",
            font = "bold",
          },
          
        },
        vb:column{
          id = "xRulesPrefsMidiOutputRack",
          vb:text{
            text = "MIDI Outputs",
            font = "bold",
          },
          
        },
      },

    },
    vb:column{
      id = "xRulesPrefsOscRack",
      visible = false,
      width = DIALOG_W,
      vb:column{
        width = DIALOG_W,
        style = "group",
        margin = 6,
        vb:text{
          text = "Configure the internal OSC server",
          font = "bold",
        },
        vb:row{
          vb:text{
            text = "IP/address",
            width = OSC_LABEL_W,
          },
          vb:textfield{
            value = self.prefs.osc_client_host.value,
            width = OSC_CONTROL_W,
            notifier = function(val)
              -- TODO check if valid 'address'
              self.prefs.osc_client_host.value = val
            end,
          },
          vb:text{
            text = "→ default is 127.0.0.1 for the local machine",
            width = OSC_LABEL_W,
          },
        },
        vb:row{
          vb:text{
            text = "Port number",
            width = OSC_LABEL_W,
          },
          vb:valuebox{
            value = self.prefs.osc_client_port.value,
            width = OSC_CONTROL_W,
            min = 0,
            max = 65535,
            notifier = function(val)
              self.prefs.osc_client_port.value = val
            end,
          },
          vb:text{
            text = "→ needs to be same as in Renoise OSC preferences!",
            width = OSC_LABEL_W,
          },

        },
      },

      vb:horizontal_aligner{
        mode = "justify",

        vb:text{
          text = "OSC Inputs/Outputs",
          font = "bold",
        },
        vb:button{
          id = "xRulesPrefsAddOscDevice",
          text = xRulesUI.TXT_ADD.." Add device",
          notifier = function()
            -- insert new device
            -- (the main app will attach and monitor changes)
            local device_name = xOscDevice.DEFAULT_DEVICE_NAME
            device_name = self.xrules:get_unique_osc_device_name(device_name)
            local device = xOscDevice{
              active = false,
              name = device_name,
              address = "127.0.0.1",
              port_in = 8000,
              port_out = 8080,
            }
            self.xrules:add_osc_device(device)
            self:update_dialog()
          end
        },
      },     

    },
    vb:column{
      id = "xRulesPrefsAutomationRack",
      visible = false,
      width = DIALOG_W,
      vb:column{
        width = DIALOG_W,
        style = "group",
        margin = 6,
        vb:text{
          text = "Automation recording",
          font = "bold",
        },
        vb:row{
          vb:checkbox{
            value = self.prefs.automation_highres_mode.value,
            notifier = function(val)
              self.prefs.automation_highres_mode.value = val
              self.xrules.automation.highres_mode = val
            end,
          },
          vb:text{
            text = "High-res mode (between lines)",
            width = OSC_LABEL_W,
          },

        },
        vb:row{
          vb:text{
            text = "Follow mode",
            width = OSC_LABEL_W,
          },
          vb:popup{
            items = automation_follow_items,
            value = table.find(automation_follow_items,self.prefs.automation_follow_mode),
            width = OSC_CONTROL_W,
            notifier = function(val)
              local str_val = automation_follow_items[val]
              --print("follow mode",str_val)
              self.prefs.automation_follow_mode.value = str_val
              self.xrules.automation.follow_mode = str_val
            end,
          },
          vb:text{
            text = "→ where to insert automation data",
            width = OSC_LABEL_W,
          },
        },
        vb:row{
          vb:text{
            text = "Write mode",
            width = OSC_LABEL_W,
          },
          vb:popup{
            items = automation_write_items,
            value = table.find(automation_write_items,self.prefs.automation_write_mode.value),
            width = OSC_CONTROL_W,
            notifier = function(val)
              local str_val = automation_write_items[val]
              self.prefs.automation_write_mode.value = str_val
              self.xrules.automation.write_mode = str_val
            end,
          },
          vb:text{
            text = "→ how to write data to envelope",
            width = OSC_LABEL_W,
          },

        },
        vb:row{
          vb:text{
            text = "Interpolation",
            width = OSC_LABEL_W,
          },
          vb:popup{
            items = automation_playmode_items,
            value = table.find(automation_playmode_items,self.prefs.automation_playmode.value),
            width = OSC_CONTROL_W,
            notifier = function(val)
              local idx = table.find(xAutomation.PLAYMODE_NAMES,automation_playmode_items[val])
              --print("idx",automation_playmode_items[val])
              self.prefs.automation_playmode.value = idx
              self.xrules.automation.playmode = idx-1
            end,
          },
          vb:text{
            text = "→ envelope interpolation mode",
            width = OSC_LABEL_W,
          },

        },
      },

    },

  }
  local buttons = vb:horizontal_aligner{
    margin = 6,
    width = DIALOG_W,
    mode = "right",
    vb:button{
      text = "Close",
      height = xRulesUI.CONTROL_H,
      width = xRulesUI.SUBMIT_BT_W,
      notifier = function()
        self.dialog:close()
        self.dialog = nil
      end
    },
  }


  -- midi inputs --

  local toggle_midi_input = function(elm,checked)
    local item = elm.owner:get_item_by_id(elm.item_id)
    if item then
      item.CHECKBOX = checked
      local matched = self:match_in_list(self.prefs.midi_inputs,item.TEXT)
      if checked and not matched then
        self.prefs.midi_inputs:insert(item.TEXT)
        self.xrules:open_midi_input(item.TEXT)
      elseif not checked and matched then
        self.prefs.midi_inputs:remove(matched)
        self.xrules:close_midi_input(item.TEXT)
      end
    end
  end

  vtable = vTable{
    id = "vtable_midi_inputs",
    vb = vb,
    width = TABLE_W,
    row_height = TABLE_ROW_H,
    num_rows = MIDI_ROWS,
    column_defs = {
      {key = "CHECKBOX", col_width=20, col_type=vTable.CELLTYPE.CHECKBOX, notifier=toggle_midi_input},
      {key = "TEXT",    col_width="auto"},
    },
    data = {},
  }
  vb.views["xRulesPrefsMidiInputRack"]:add_child(vtable.view)
  self.vtable_midi_inputs = vtable

  -- midi outputs --

  local toggle_midi_output = function(elm,checked)
    local item = elm.owner:get_item_by_id(elm.item_id)
    if item then
      item.CHECKBOX = checked
      local matched = self:match_in_list(self.prefs.midi_outputs,item.TEXT)
      if checked and not matched then
        self.prefs.midi_outputs:insert(item.TEXT)
        self.xrules:open_midi_output(item.TEXT)
      elseif not checked and matched then
        self.prefs.midi_outputs:remove(matched)
        self.xrules:close_midi_output(item.TEXT)
      end
    end
  end

  vtable = vTable{
    id = "vtable_midi_outputs",
    vb = vb,
    width = TABLE_W,
    row_height = TABLE_ROW_H,
    num_rows = MIDI_ROWS,
    column_defs = {
      {key = "CHECKBOX", col_width=20, col_type=vTable.CELLTYPE.CHECKBOX, notifier=toggle_midi_output},
      {key = "TEXT",    col_width="auto"},
    },
    data = {},
  }
  vb.views["xRulesPrefsMidiOutputRack"]:add_child(vtable.view)
  self.vtable_midi_outputs = vtable

  -- osc devices --

  local handle_active = function(elm,checked)
    --print("handle_active",elm,checked)
    local item = elm.owner:get_item_by_id(elm.item_id)
    if item then
      item.ACTIVE = checked
      self.xrules:set_osc_device_property(item.NAME,"active",checked)
    end
  end

  local handle_name = function(elm,val)
    --print("handle_name",elm,val)
    local item = elm.owner:get_item_by_id(elm.item_id)
    if item then
      local old_name = item.NAME
      item.NAME = val
      self.xrules:set_osc_device_property(old_name,"name",val)
    end
  end

  local handle_address = function(elm,val)
    --print("handle_address",elm,val)
    local item = elm.owner:get_item_by_id(elm.item_id)
    if item then
      item.ADDRESS = val
      self.xrules:set_osc_device_property(item.NAME,"address",val)
    end
  end

  local handle_prefix = function(elm,val)
    --print("handle_prefix",elm,val)
    local item = elm.owner:get_item_by_id(elm.item_id)
    if item then
      item.PREFIX = val
      self.xrules:set_osc_device_property(item.NAME,"prefix",val)
    end
  end

  local handle_port_in = function(elm,val)
    --print("handle_port_in",elm,val)
    local item = elm.owner:get_item_by_id(elm.item_id)
    if item then
      item.PORT_IN = val
      self.xrules:set_osc_device_property(item.NAME,"port_in",val)
    end
  end

  local handle_port_out = function(elm,val)
    --print("handle_port_out",elm,val)
    local item = elm.owner:get_item_by_id(elm.item_id)
    if item then
      item.PORT_OUT = val
      self.xrules:set_osc_device_property(item.NAME,"port_out",val)
    end
  end

  local remove_device = function(elm,val)
    --print("remove_device",elm,val)
    local item,index = elm.owner:get_item_by_id(elm.item_id)
    if index then
      
      self.xrules:remove_osc_device(index)
      self:update_dialog()
    end
  end

  vtable = vTable{
    id = "vtable_osc_devices",
    vb = vb,
    width = DIALOG_W,
    --height = 200,
    --scrollbar_width = 20,
    row_height = TABLE_ROW_H,
    --header_height = 30,
    show_header = true,
    num_rows = OSC_ROWS,
    header_defs = {
      ACTIVE    = {data =""},
      NAME      = {},
      ADDRESS   = {},
      PREFIX    = {},
      PORT_IN   = {},
      PORT_OUT  = {},
      REMOVE    = {data =""},
    },

    column_defs = {
      {key = "ACTIVE",    col_width=20,     col_type=vTable.CELLTYPE.CHECKBOX,    notifier=handle_active},
      {key = "NAME",      col_width="auto", col_type=vTable.CELLTYPE.TEXTFIELD,   notifier=handle_name},
      {key = "ADDRESS",   col_width=90,     col_type=vTable.CELLTYPE.TEXTFIELD,   notifier=handle_address},
      {key = "PREFIX",    col_width=70,     col_type=vTable.CELLTYPE.TEXTFIELD,   notifier=handle_prefix}, 
      {key = "PORT_IN",   col_width=60,     col_type=vTable.CELLTYPE.VALUEBOX,    notifier=handle_port_in,  min = 0,  max = 99999},
      {key = "PORT_OUT",  col_width=60,     col_type=vTable.CELLTYPE.VALUEBOX,    notifier=handle_port_out, min = 0,  max = 99999},
      {key = "REMOVE",    col_width=20,     col_type=vTable.CELLTYPE.BUTTON,      notifier=remove_device,   text = "Remove"},
    },
    data = {}
  }
  vb.views["xRulesPrefsOscRack"]:add_child(vtable.view)
  self.vtable_osc_devices = vtable


  self:update_dialog()
  self:update_profile_switcher()

  return vb:column{
    content,
    buttons,
  }

end

-------------------------------------------------------------------------------

function xRulesAppDialogPrefs:update_profile_switcher()

  local vb = self.vb
  local xprefs = self.owner.xprefs
  local profile_idx = vb.views.xprefs_profile_selector.value
  --print("profile_idx",profile_idx)
  
  if not xprefs.profiles_enabled then
    vb.views.xprefs_always_choose_cb.active = false
    vb.views.xprefs_profile_selector.active = false
    vb.views.xprefs_update_profile_bt.active = true
  else
    vb.views.xprefs_always_choose_cb.active = true
    vb.views.xprefs_profile_selector.active = not xprefs.always_choose and true or false
    vb.views.xprefs_update_profile_bt.active = (profile_idx > 1) and true or false
  end


end

-------------------------------------------------------------------------------

function xRulesAppDialogPrefs:update_dialog()

  local vb = self.vb

  -- midi inputs --

  local midi_inputs = renoise.Midi.available_input_devices()
  local midi_outputs = renoise.Midi.available_output_devices()
  local data,vtable

  data = {}
  vtable = self.vtable_midi_inputs
  for k,v in ipairs(midi_inputs) do
    data[k] = {
      CHECKBOX = (self:match_in_list(self.prefs.midi_inputs,v)) and true or false,
      TEXT = v,
    }
  end
  --rprint("midi_inputs data",rprint(data))
  vtable.data = data
  vtable.show_header = false
  vtable:update()

  -- midi outputs --

  data = {}
  vtable = self.vtable_midi_outputs
  for k,v in ipairs(midi_inputs) do
    data[k] = {
      CHECKBOX = (self:match_in_list(self.prefs.midi_outputs,v)) and true or false,
      TEXT = v,
    }
  end
  vtable.data = data
  vtable.show_header = false
  vtable:update()

  -- osc devices --

  data = {}
  vtable = self.vtable_osc_devices
  for k,v in ipairs(self.xrules.osc_devices) do
    data[k] = {
      ACTIVE = v.active,
      NAME = v.name,
      ADDRESS = v.address,
      PREFIX = v.prefix,
      PORT_IN = v.port_in,
      PORT_OUT = v.port_out,
      REMOVE = xRulesUI.TXT_CLOSE,
    }
  end
  vtable.data = data
  --vtable.show_header = false
  vtable:update()


end
