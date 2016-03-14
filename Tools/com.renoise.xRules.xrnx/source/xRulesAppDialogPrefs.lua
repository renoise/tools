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
  --self.owner = self.ui.owner

  -- xRules
  self.xrules = self.ui.owner.xrules

  -- xRulesAppPrefs
  self.prefs = self.ui.owner.prefs

  self.title = "xRules preferences"

  -- vLib components
  self.vtable_midi_inputs = nil
  self.vtable_midi_outputs = nil
  self.vtable_osc_devices = nil
  

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

  local content = vb:column{
    margin = 6,
    spacing = 3,
    vb:column{
      width = DIALOG_W,
      style = "group",
      margin = 6,
      vb:text{
        text = "General options",
        font = "bold",
      },
      vb:row{
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
      vb:row{
        --width = DIALOG_W,
        spacing = 2,
        vb:space{
          width = 16,
        },
        vb:text{
          text = "Ruleset folder",
        },
        vb:textfield{
          --text = self.prefs:property("ruleset_folder").value,
          width = DIALOG_W - 200,
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
    vb:switch{
      width = 200,
      items = {
        "MIDI",
        "OSC",
      },
      notifier = function(val)
        vb.views["xRulesPrefsMidiRack"].visible = (val == 1)
        vb.views["xRulesPrefsOscRack"].visible = (val == 2)
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
          --margin = 6,
          --width = TABLE_W,
          --style = "group",
          id = "xRulesPrefsMidiInputRack",
          vb:text{
            text = "MIDI Inputs",
            font = "bold",
          },
          
        },
        vb:column{
          --margin = 6,
          --width = TABLE_W,
          --style = "group",
          id = "xRulesPrefsMidiOutputRack",
          vb:text{
            text = "MIDI Outputs",
            font = "bold",
          },
          
        },
      },

    },
    vb:column{
      --style = "group",
      id = "xRulesPrefsOscRack",
      visible = false,
      --margin = 6,
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
        --width = DIALOG_W,
        mode = "justify",

        vb:text{
          text = "OSC Inputs/Outputs",
          font = "bold",
        },
        vb:button{
          text = xRulesUI.TXT_ADD.." Add device",
          notifier = function()
            self.xrules:add_osc_device()
            self:update_dialog()
          end
        },
        --[[ TODO
        ]]
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
    --print("toggle_midi_input(elm,checked)",elm,checked)
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
    --height = 200,
    --scrollbar_width = 20,
    row_height = TABLE_ROW_H,
    --header_height = 30,
    --show_header = false,
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
    --print("toggle_midi_output(elm,checked)",elm,checked)
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
    --height = 200,
    --scrollbar_width = 20,
    row_height = TABLE_ROW_H,
    --header_height = 30,
    --show_header = false,
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

  return vb:column{
    content,
    buttons,
  }

end

-------------------------------------------------------------------------------

function xRulesAppDialogPrefs:update_dialog()

  local vb = self.vb

  --print("xRulesAppDialogPrefs:update_dialog - vb.views PRE",rprint(vb.views))

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
