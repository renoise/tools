--[[============================================================================
-- xRulesUI
============================================================================]]--

--[[--

  This is a supporting class for xRulesApp

--]]

--==============================================================================


class 'xRulesUI'

xRulesUI.MARGIN = 6
xRulesUI.MARGIN_SM = 3
xRulesUI.CONTROL_SM = 18
xRulesUI.CONTROL_H = 22
xRulesUI.ASPECTS_W = 122
xRulesUI.SUBMIT_BT_W = 82
xRulesUI.OPERATOR_W = 80
xRulesUI.VALUE_SELECT_W = 98
xRulesUI.VALUEBOX_W = 70
xRulesUI.TEXTAREA_W = 380
xRulesUI.TEXTAREA_H = 90
xRulesUI.VALUE_POPUP_W = 158
xRulesUI.RULE_MARGIN_W = 50
xRulesUI.OSC_LABEL_W = 80
xRulesUI.SIDE_PANEL_W = 155
xRulesUI.MAIN_PANEL_W = 433
xRulesUI.TOTAL_W = xRulesUI.SIDE_PANEL_W + xRulesUI.MAIN_PANEL_W

-- UTF characters
xRulesUI.TXT_ADD = "+"
xRulesUI.TXT_CLOSE = "⨯"
xRulesUI.TXT_CONTRACT = "─"
xRulesUI.TXT_EXPAND = "□"
xRulesUI.TXT_ARROW_DOWN = "▾"
xRulesUI.TXT_ARROW_UP = "▴"
xRulesUI.TXT_WARNING = "⚠"
xRulesUI.TXT_ARROW_LEFT = "→"

xRulesUI.LOGO_ENABLED = "./source/icons/logo.png"
xRulesUI.LOGO_DISABLED = "./source/icons/logo-disabled.png"

-- provide defaults for untranslateable actions
xRulesUI.ACTION_UNTRANSLATEABLE = {
  CALL_FUNCTION = "-- enter lua code here",
  OUTPUT_MESSAGE = xRules.OUTPUT_OPTIONS.INTERNAL_AUTO,
  SET_PORT = "Select a port",
}

-- 'stringified' tables (for display in popups)
xRulesUI.ASPECT_ITEMS = xLib.stringify_table(xRule.ASPECT)
xRulesUI.ASPECT_DEFAULTS = xLib.stringify_table(xRule.ASPECT_DEFAULTS.CHANNEL)
xRulesUI.ASPECT_DEFAULT_TRACKS = xLib.stringify_table(xRule.ASPECT_DEFAULTS.TRACK_INDEX)
xRulesUI.ASPECT_DEFAULT_INSTRUMENTS = xLib.stringify_table(xRule.ASPECT_DEFAULTS.INSTRUMENT_INDEX)
xRulesUI.ACTION_ITEMS = xLib.stringify_table(xRule.ACTIONS)
xRulesUI.TYPE_ITEMS = xLib.stringify_table(xMidiMessage.TYPE)
xRulesUI.TYPE_OPERATOR_ITEMS = xLib.stringify_table(xRule.TYPE_OPERATORS)
xRulesUI.VALUE_OPERATOR_ITEMS = xLib.stringify_table(xRule.VALUE_OPERATORS)
xRulesUI.OUTPUT_ITEMS = xLib.stringify_table(xRules.OUTPUT_OPTIONS)
xRulesUI.TYPE_ITEMS = xLib.stringify_table(xMidiMessage.TYPE)

table.sort(xRulesUI.ASPECT_ITEMS)
table.sort(xRulesUI.TYPE_ITEMS)
table.sort(xRulesUI.TYPE_OPERATOR_ITEMS)
table.sort(xRulesUI.VALUE_OPERATOR_ITEMS)
table.sort(xRulesUI.ACTION_ITEMS)


--------------------------------------------------------------------------------

function xRulesUI:__init(owner)

  --- xRulesApp, instance of main class
  self.owner = owner

  --- xRules
  self.xrules = owner.xrules

  -- xRulesAppPrefs
  self.prefs = owner.prefs

  --- renoise.ViewBuilder
  self._vb = renoise.ViewBuilder()

  --- renoise.Dialog, reference to the main dialog 
  self._dialog = nil

  --- xDialog
  self._create_dialog = xRulesAppDialogCreate(self)
  self._export_dialog = xRulesAppDialogExport(self)
  self._help_dialog   = xRulesAppDialogHelp(self)
  self._log_dialog    = xRulesAppDialogLog(self)
  self._prefs_dialog  = xRulesAppDialogPrefs(self)

  --- xRulesUIEditor
  self.editor = nil

  --- renoise.Views.View
  self._view = self:build()

  -- boolean, update flag
  self._build_rulesets_requested = false
  self._build_rule_requested = false
  self._update_rule_options_requested = false

  -- boolean
  self.minimized = property(self.get_minimized,self.set_minimized)
  self.minimized_observable = renoise.Document.ObservableBoolean(true)

  -- boolean
  self.show_rule_options = false

  -- integer
  self.rule_options_tab_index = 1

  -- string, output message in statusbar (on idle)
  self.scheduled_status_message = nil

  -- table, state of indicator LEDs 
  -- {timestamp,ruleset_idx,rule_idx}
  self.midi_indicators = {}
  self.osc_indicators = {}

  self.suppress_description_notifier = false

  -- array with this structure
  --  {
  --    rack_elm
  --    [0] = {
  --      midi_indicator,
  --      osc_indicator
  --    },
  --  }
  self.vb_rulesets = {}

  -- initialize --

  renoise.tool().app_idle_observable:add_notifier(function()
    self:on_idle()
  end)

  -- when active state has changed, update logo 
  self.xrules.active_observable:add_notifier(function()
    self:update_logo()
    local msg = "Message from xRules: active = ".. tostring(self.xrules.active)
    self.scheduled_status_message = msg
  end)

  -- when rulesets are added/removed/swapped
  self.xrules.ruleset_observable:add_notifier(function(args)
    --print(">>> xrules.ruleset_observable fired...",rprint(args))

    self:clear_rulesets()

    if (args.type == "remove") then
      table.remove(self.vb_rulesets,args.index)
      for k,v in ripairs(self.midi_indicators) do
        if (v.ruleset_idx == args.index) then
          table.remove(self.midi_indicators,k)
        end
      end 
      for k,v in ripairs(self.osc_indicators) do
        if (v.ruleset_idx == args.index) then
          table.remove(self.osc_indicators,k)
        end
      end 
      
      -- select previous/first ruleset 
      local ruleset_idx = self.xrules.selected_ruleset_index - 1
      self.xrules.selected_ruleset_index = math.max(1,ruleset_idx)

    elseif (args.type == "insert") then
      local xruleset = self.xrules.rulesets[args.index]
      self:attach_to_ruleset(xruleset)
      self:update_minimized()
    end

    self:update_minimized()
    self._build_rulesets_requested = true
    self._build_rule_requested = true

  end)

  -- attach to selected ruleset
  self.xrules.selected_ruleset_index_observable:add_notifier(function()
    local xruleset = self.xrules.selected_ruleset
    self:attach_to_ruleset(xruleset)
    self:update_minimized()
  end)

  self:update_minimized()

end


--------------------------------------------------------------------------------

--- Show the dialog

function xRulesUI:show()

  if (not self._dialog or not self._dialog.visible) then
    assert(self._view, "Internal Error. Please report: " .. 
      "no valid content view")
    local function keyhandler(dialog, key)
      --rprint(key)
      return key
    end
    self._dialog = renoise.app():show_custom_dialog(
      "xRules", self._view,keyhandler)
  else
    self._dialog:show()
  end
  self:update_logo()

end

--------------------------------------------------------------------------------

--- Hide the dialog

function xRulesUI:hide()
  --TRACE("xRulesUI:hide()")

  if (self._dialog and self._dialog.visible) then
    self._dialog:close()
  end
  self._dialog = nil

end

--------------------------------------------------------------------------------

function xRulesUI:toggle_minimized()

  self.minimized = not self.minimized
  self:update_minimized()

end

--------------------------------------------------------------------------------
--- Build

function xRulesUI:build()
  --TRACE("xRulesUI:build()")

  local vb = self._vb
  local view = vb:column{
    id = 'xrules_rootnode',
    margin = 1,
    vb:space{
      width = xRulesUI.TOTAL_W,
    },
    vb:horizontal_aligner{
      id = "xrules_top_row",
      mode = "justify",
      vb:row{
        vb:row{
          margin = 4,
          vb:bitmap{
            id = "xrules_logo",
            bitmap = "./source/icons/logo.png",
            mode = "main_color",
            notifier = function()
              if self.xrules.active then
                self.owner:shutdown()
              else
                self.owner:launch()
              end
            end
          },
        },
        vb:row{
          margin = 2,
          vb:text{
            id = "xrules_status_text",
            text = "", 
            font = "italic",
          },
        },
      },
      vb:row{
        vb:button{
          text = "Add...",
          tooltip = "Click to create/import rulesets",
          width = 60,
          height = xRulesUI.CONTROL_H,
          notifier = function()
            self._create_dialog:show()
          end
        },
        vb:button{
          id = "xrules_export_button",
          text = "Export",
          tooltip = "Click for export dialog",
          height = xRulesUI.CONTROL_H,
          width = 60,
          notifier = function()
            self._export_dialog:show()
          end
        },
        vb:button{
          text = "Options",
          tooltip = "Click for options dialog",
          height = xRulesUI.CONTROL_H,
          width = 70,
          notifier = function()
            self._prefs_dialog:show()
          end
        },

        vb:button{
          text = "Log",
          width = xRulesUI.CONTROL_H,
          height = xRulesUI.CONTROL_H,
          notifier = function()
            self._log_dialog:show()
          end,
        },
        vb:button{
          id = "xrules_compact_button",
          tooltip = "Toggle between normal/minimized user-interface",
          text = xRulesUI.TXT_CONTRACT,
          width = xRulesUI.CONTROL_H,
          height = xRulesUI.CONTROL_H,
          notifier = function()
            self:toggle_minimized()
          end,
        }
      },
    },
    vb:space{
      height = xRulesUI.MARGIN_SM
    },
    vb:row{ -- side/main panel
      id = "xrules_panels",
      style = "group",
      vb:column{ -- side panel  
        style = "plain",
        id = "xrules_sidepanel",
        vb:space{
          width = xRulesUI.SIDE_PANEL_W,
        },
        vb:column{ 
          id = "xrules_ruleset_container",
        }
      },
      vb:column{ -- main panel
        id = "xrules_rules_container",
      }
    },
  }

  return view

end


--------------------------------------------------------------------------------

function xRulesUI:clear_rulesets()

  local vb = self._vb
  local vb_container = vb.views["xrules_ruleset_container"]
  for k,v in ipairs(self.vb_rulesets) do
    vb_container:remove_child(v.rack_elm)
  end

  self.vb_rulesets = {}

end


--------------------------------------------------------------------------------

function xRulesUI:build_rulesets()
  --TRACE("xRulesUI:build_rulesets()")

  local vb = self._vb
  local vb_container = vb.views["xrules_ruleset_container"]
  --print("xrules_ruleset_container",vb_container)
  --print("xrules_ruleset_container.height",vb_container.height)

  self:clear_rulesets()

  for k,xruleset in ipairs(self.xrules.rulesets) do
    local view = self:build_ruleset(k,xruleset)
    vb_container:add_child(view)
  end

end

--------------------------------------------------------------------------------
-- switch rule and set in a one go

function xRulesUI:select_rule_within_set(ruleset_idx,rule_idx)
  
  if not ruleset_idx then
    ruleset_idx = 1
  end
  if not rule_idx then
    local ruleset = self.xrules.rulesets[ruleset_idx]
    rule_idx = ruleset.selected_rule_index
  end

  -- just an extra precaution - we should always have an active rule
  assert(rule_idx > 0,"We should always have an active rule: "..tostring(rule_idx))
  --[[
  if (rule_idx == 0) then
    rule_idx = 1
  end
  ]]

  if (ruleset_idx == self.xrules.selected_ruleset_index) 
    and (rule_idx == self.xrules.selected_rule_index) 
  then
    return -- nothing to do
  end

  self.xrules.selected_ruleset_index = ruleset_idx
  self.xrules.selected_rule_index = rule_idx
  self._build_rulesets_requested = true
  self._build_rule_requested = true

end

--------------------------------------------------------------------------------
-- when elements are automatically sized, call this to restrict width 

function xRulesUI:fit_element_width(elm,max_width)
  if (elm.width > max_width) then
    elm.width = max_width
  end
end

--------------------------------------------------------------------------------
-- create entry for a single ruleset

function xRulesUI:build_ruleset(ruleset_idx,xruleset)

  local vb = self._vb

  local name = (xruleset.name == "") and "Untitled set" or xruleset.name
  if xruleset.modified then
    name = "*" .. name
  end

  local vb_ruleset_name = vb:text{
    text = name,
    font = (ruleset_idx == self.xrules.selected_ruleset_index)
      and "bold" or "normal",
  }

  -- leave enough room for checkbox + voicemanager icon
  local reduce_by = xruleset.manage_voices and 45 or 25
  self:fit_element_width(vb_ruleset_name,xRulesUI.SIDE_PANEL_W-reduce_by)

  self.vb_rulesets[ruleset_idx] = {}


  local vb_view = vb:column{
    width = xRulesUI.SIDE_PANEL_W,
    vb:row{
      vb:row{
        margin = xRulesUI.MARGIN_SM,
        vb:checkbox{
          value = xruleset.active,
          notifier = function()
            self.xrules:toggle_ruleset(ruleset_idx)
          end
        },
        vb:bitmap{
          tooltip = "Voice-manager",
          bitmap = "./source/icons/key_small.bmp",
          mode = "body_color",
          visible = xruleset.manage_voices,
        },
        vb:checkbox{
          visible = false,
          value = true,
          notifier = function()
            self:select_rule_within_set(ruleset_idx)
          end
        },
        vb_ruleset_name,
      },
    },
  }

  for rule_idx,v in ipairs(xruleset.rules) do

    self.vb_rulesets[ruleset_idx][rule_idx] = {}

    local xrule = self.xrules.rulesets[ruleset_idx].rules[rule_idx] 
    --print("xrule",xrule)
    local selected = (self.xrules.selected_ruleset_index == ruleset_idx) 
      and (self.xrules.selected_rule_index == rule_idx) 
  
    self.vb_rulesets[ruleset_idx][rule_idx].midi_indicator = vb:bitmap{
      tooltip = "MIDI activity",
      bitmap = "./source/icons/midi_small.bmp",
      mode = "body_color",
      visible = xrule.midi_enabled,
    }
    self.vb_rulesets[ruleset_idx][rule_idx].osc_indicator = vb:bitmap{
      tooltip = "OSC activity",
      bitmap = "./source/icons/osc_small.bmp",
      mode = "body_color",
      visible = (xruleset.osc_enabled and xrule.osc_pattern.complete) and true or false,
    }

    local vb_rule_name = vb:text{
      text = xruleset:get_rule_name(rule_idx),
      font = selected and "bold" or "normal"
    }
    self:fit_element_width(vb_ruleset_name,xRulesUI.SIDE_PANEL_W)

    vb_view:add_child(vb:row{
      vb:space{
        width = 4,
      },
      self.vb_rulesets[ruleset_idx][rule_idx].midi_indicator,
      self.vb_rulesets[ruleset_idx][rule_idx].osc_indicator,
      vb:checkbox{
        value = true,
        visible = false,
        notifier = function()
          self:select_rule_within_set(ruleset_idx,rule_idx)
        end
      },
      vb_rule_name,
    })

  end

  self.vb_rulesets[ruleset_idx].rack_elm = vb_view
  return vb_view

end

--------------------------------------------------------------------------------
-- clear selected rule 

function xRulesUI:clear_rule()

  local vb = self._vb
  if self.vb_rule then
    local vb_rule_container = vb.views["xrules_rules_container"]
    vb_rule_container:remove_child(self.vb_rule)
    self.vb_rule = nil
  end

end

--------------------------------------------------------------------------------

function xRulesUI:disable_indicator(ruleset_idx,rule_idx,str_key)
  local indicator = self.vb_rulesets[ruleset_idx][rule_idx][str_key]
  if indicator then
    indicator.mode = "body_color"
  end
end

--------------------------------------------------------------------------------

function xRulesUI:match_indicator(ruleset_idx,rule_idx,type)

  local indicator,indicators
  if self.vb_rulesets[ruleset_idx] 
    and self.vb_rulesets[ruleset_idx][rule_idx]
  then
    if (type == "osc") then
      indicator = self.vb_rulesets[ruleset_idx][rule_idx].osc_indicator
      indicators = self.osc_indicators
    elseif (type == "midi") then
      indicator = self.vb_rulesets[ruleset_idx][rule_idx].midi_indicator
      indicators = self.midi_indicators
    end
  end

  if indicator then
    -- extend time for already-active indicator
    local matched = false
    for k,v in ipairs(indicators) do
      if (v.ruleset_idx == ruleset_idx)
        and (v.rule_idx == rule_idx)
      then
        v.timestamp = os.clock()
        matched = true
      end
    end
    if not matched then
      table.insert(indicators,{
        timestamp = os.clock(),
        ruleset_idx = ruleset_idx,
        rule_idx = rule_idx,
      })
      indicator.mode = "transparent"
    end
  end

end

--------------------------------------------------------------------------------
--- display when a rule got matched, somehow
--  when UI is visible: flashing LEDs 
--  when UI is hidden: message in status bar

function xRulesUI:enable_indicator(ruleset_idx,rule_idx,type)

  local xruleset = self.xrules.rulesets[ruleset_idx]
  if xruleset.active then
    if self._dialog and self._dialog.visible then -- flash indicator
      self:match_indicator(ruleset_idx,rule_idx,type)
    else -- status bar
      local msg = "Message from xRules: matched rule#%d in ruleset '%s'"
      local xruleset = self.xrules.rulesets[ruleset_idx]
      self.scheduled_status_message = msg:format(rule_idx,xruleset.name)
    end
  end

end

--------------------------------------------------------------------------------
-- update top row + minimized state

function xRulesUI:update_logo()

  local vb = self._vb
  local vb_logo = vb.views["xrules_logo"]
  --print("vb_logo",vb_logo)

  vb_logo.bitmap = self.xrules.active and
    xRulesUI.LOGO_ENABLED or xRulesUI.LOGO_DISABLED

end

--------------------------------------------------------------------------------
-- update top row + minimized state

function xRulesUI:update_minimized()

  local vb = self._vb
  local vb_panels = vb.views["xrules_panels"]
  local vb_status_text = vb.views["xrules_status_text"]
  local vb_compact_button = vb.views["xrules_compact_button"]
  local vb_export_button = vb.views["xrules_export_button"]

  local num_rulesets = #self.xrules.rulesets

  if self.minimized or (num_rulesets == 0) then
    vb_panels.visible = false
    vb_compact_button.text = xRulesUI.TXT_EXPAND
  else
    vb_panels.visible = true
    vb_compact_button.text = xRulesUI.TXT_CONTRACT
  end

  --print("self.owner.xprefs",self.owner.xprefs)
  --print("selected_profile",self.owner.xprefs.selected_profile)
  local str_profile = self.owner.xprefs.selected_profile
    and "("..self.owner.xprefs.selected_profile.name..")" or ""
  --print("str_profile",str_profile)

  vb_status_text.text = ("- MIDI+OSC utility v%s %s"):format(
    self.owner.version,str_profile)

  vb_compact_button.active = (num_rulesets > 0) and true or false
  if (num_rulesets > 0) then
    vb_export_button.active = (self.xrules.selected_ruleset_index > 0) and true or false
  else
    vb_export_button.active = false
  end

  self:update_logo()

end

--------------------------------------------------------------------------------
-- sync height of sidepanel 

function xRulesUI:update_sidepanel()

  local min_size = 100
  local padding = 20

  local vb = self._vb
  local vb_main = vb.views["xrules_rules_container"]
  local vb_ruleset = vb.views["xrules_ruleset_container"]
  local vb_sidepanel = vb.views["xrules_sidepanel"]
  --print("*** update_sidepanel - vb_ruleset.height",vb_ruleset.height)
  --print("*** update_sidepanel - vb_main.height",vb_main.height)

  local new_h = padding + math.max(min_size,math.max(vb_ruleset.height,vb_main.height))
  vb_sidepanel.height = new_h
  --print("*** update_sidepanel - vb_sidepanel.height",vb_sidepanel.height)

end


--------------------------------------------------------------------------------
-- attach to the selected ruleset

function xRulesUI:attach_to_ruleset(xruleset)

  if not xruleset then
    return
  end

  local osc_enabled_notifier = function()
    --print("xRulesUI:xruleset.osc_enabled_observable fired...")
    --self._update_rule_options_requested = true
    self._build_rule_requested = true
    self._build_rulesets_requested = true
  end

  local manage_voices_notifier = function()
    --print("xRulesUI:xruleset.manage_voices_notifier fired...")
    --self._update_rule_options_requested = true
    self._build_rule_requested = true
    self._build_rulesets_requested = true
  end

  local description_notifier = function(args)
    --print("xRulesUI:xruleset.description_notifier fired...",args)
    if not self.suppress_description_notifier then
      self._update_rule_options_requested = true
    end

  end

  local name_notifier = function()
    --print("xRulesUI:xruleset.name_observable fired...")
  end

  local active_notifier = function()
    --print("xRulesUI:xruleset.active_observable fired...")
  end

  local rules_notifier = function()
    --print("xRulesUI:xruleset.rules_observable fired...")
  end

  local selected_rule_index_notifier = function()
    --print("xRulesUI:xruleset.selected_rule_index_observable fired...")
    self._build_rulesets_requested = true
    self._build_rule_requested = true
  end

  cObservable.attach(xruleset.osc_enabled_observable,osc_enabled_notifier)
  cObservable.attach(xruleset.manage_voices_observable,manage_voices_notifier)
  cObservable.attach(xruleset.description_observable,description_notifier)
  cObservable.attach(xruleset.name_observable,name_notifier)
  cObservable.attach(xruleset.active_observable,active_notifier)
  cObservable.attach(xruleset.rules_observable,rules_notifier)
  cObservable.attach(xruleset.selected_rule_index_observable,selected_rule_index_notifier)

  self._build_rulesets_requested = true
  self._build_rule_requested = true

end


--------------------------------------------------------------------------------

function xRulesUI:get_minimized()
  return self.minimized_observable.value
end

function xRulesUI:set_minimized(val)
  self.minimized_observable.value = val
end

--------------------------------------------------------------------------------

function xRulesUI:remove_selected_ruleset()
  local ruleset_idx = self.xrules.selected_ruleset_index
  local passed,err = self.xrules:remove_ruleset(ruleset_idx)
  if err then
    renoise.app():show_warning(err)
    return
  end
end

--------------------------------------------------------------------------------

function xRulesUI:remove_selected_rule()

  local xruleset = self.xrules.selected_ruleset
  if (#xruleset.rules == 1) then
    renoise.app():show_warning("Can't remove - there needs to be at least one rule in a set")
    return
  end

  local rule_idx = self.xrules.selected_rule_index
  local passed,err = xruleset:remove_rule(rule_idx)
  if err then
    renoise.app():show_warning(err)
    return
  end

  if (rule_idx > 1) and (rule_idx > #xruleset.rules) then
    rule_idx = rule_idx - 1
  end
  self.xrules.selected_rule_index = rule_idx

  self._build_rulesets_requested = true
  self._build_rule_requested = true

end

--------------------------------------------------------------------------------

function xRulesUI:add_rule()

  local xruleset = self.xrules.selected_ruleset
  local rule_idx = self.xrules.selected_rule_index+1
  xruleset:add_rule({},rule_idx)
  self.xrules.selected_rule_index = rule_idx
  self._build_rulesets_requested = true
  self._build_rule_requested = true

end

-------------------------------------------------------------------------------
-- @return string, a name such as "Untitled Ruleset (1)"

function xRulesUI:get_ruleset_name(ruleset_idx)

  assert(type(ruleset_idx)=="number", "Expected number as argument")

  local xruleset = self.xrules.rulesets[ruleset_idx]
  if (xruleset.name == "") then
    return xRuleset.get_suggested_name()
  else
    return xruleset.name
  end

end

--------------------------------------------------------------------------------
-- @param xruleset (xRuleset)

function xRulesUI:rename_selected_ruleset(str_name)

  local xruleset = self.xrules.selected_ruleset
  str_name = str_name or xruleset.name
  local new_name = vPrompt.prompt_for_string(str_name,"Enter new name","Rename ruleset") 
  if new_name then
    local passed,err = xruleset:rename(new_name)
    if not passed then
      if err then
        renoise.app():show_warning(err)
        self:rename_selected_ruleset(new_name)
      end
    else
      self._build_rulesets_requested = true
      self._build_rule_requested = true
      self.owner:store_ruleset_prefs()
    end
  end
end

--------------------------------------------------------------------------------
-- @param xruleset (xRuleset)

function xRulesUI:rename_selected_rule(str_name)

  local xrule = self.xrules.selected_rule
  str_name = str_name or self.xrules.selected_ruleset:get_rule_name(self.xrules.selected_rule_index)
  local new_name = vPrompt.prompt_for_string(str_name,"Enter new name","Rename rule") 
  if new_name then
    xrule.name = new_name
    self._build_rulesets_requested = true
    self._build_rule_requested = true
  end

end

--------------------------------------------------------------------------------

function xRulesUI:get_osc_device_names()

  local rslt = {}
  for k,v in ipairs(self.xrules.osc_devices) do
    table.insert(rslt,v.name)
  end 
  return rslt

end

--------------------------------------------------------------------------------
-- @return table

function xRulesUI:_create_midi_in_list()
  --TRACE("xRulesUI:_create_midi_in_list()")

  local rslt = {xRulesAppPrefs.NO_INPUT}
  for k,v in ipairs(renoise.Midi.available_input_devices()) do
    rslt[#rslt+1] = v
  end
  return rslt

end

--------------------------------------------------------------------------------

function xRulesUI:on_idle()
  --TRACE("xRulesUI:on_idle()")

  if self._build_rulesets_requested then
    self._build_rulesets_requested = false
    self:build_rulesets()
    self:update_sidepanel()
  end

  if self._build_rule_requested 
    -- these might temporarily be missing (wait)
    and self.xrules.selected_ruleset
    and self.xrules.selected_rule
  then

    --print(">>> build rule requested")
    
    self._build_rule_requested = false

    self:clear_rule()

    local rule_idx = self.xrules.selected_rule_index
    local ruleset_idx = self.xrules.selected_ruleset_index
    self.editor = xRulesUIEditor{
      vb = self._vb,
      ui = self,
      xrule = self.xrules.selected_rule,
    }
    self.vb_rule = self.editor:build_rule()
    local xrules_rules_container = self._vb.views["xrules_rules_container"]
    xrules_rules_container:add_child(self.vb_rule)

    self:update_minimized()
    self:update_sidepanel()

  end

  if (self._update_rule_options_requested) then
    self._update_rule_options_requested = false
    self.editor:update_rule_options()
    self:update_sidepanel()
  end

  if (#self.midi_indicators > 0) then
    for k,v in ripairs(self.midi_indicators) do
      if (os.clock() - v.timestamp > 0.1) then
        self:disable_indicator(v.ruleset_idx,v.rule_idx,"midi_indicator")
        table.remove(self.midi_indicators,k)
      end
    end
  end
  if (#self.osc_indicators > 0) then
    for k,v in ripairs(self.osc_indicators) do
      if (os.clock() - v.timestamp > 0.1) then
        self:disable_indicator(v.ruleset_idx,v.rule_idx,"osc_indicator")
        table.remove(self.osc_indicators,k)
      end
    end
  end

  if self.scheduled_status_message then
    renoise.app():show_status(self.scheduled_status_message)
    self.scheduled_status_message = nil
  end

end

