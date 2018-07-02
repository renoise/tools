--[[============================================================================
-- xRulesUIEditor
============================================================================]]--

--[[--

  This is a supporting class for xRulesUI

--]]

--==============================================================================


class 'xRulesUIEditor'

xRulesUIEditor.TAB = {
  DESCRIPTION = 1,
  VOICE_MGR = 2,
  MIDI_ENABLED = 3,
  OSC_ENABLED = 4,
}

--------------------------------------------------------------------------------
--- constructor, called whenever we refresh the rule editor 

function xRulesUIEditor:__init(...)

	local args = cLib.unpack_args(...)

  self.vb = args.vb
  self.ui = args.ui
  self.owner = args.ui.owner
  self.xrules = args.ui.owner.xrules
  self.xrule = args.xrule

  -- xMidiMessage.TYPE - set as we encounter MIDI message aspects
  self.last_msg_type = nil

  -- xOscValue.tag - set as we encounter OSC message aspects
  self.last_osc_type = nil

  -- int, how many values to display (set when building rule)
  self.active_value_count = #xRule.VALUES

  -- viewbuilder elements...
  self.vb_revert_ruleset_button = nil
  self.vb_save_ruleset_button = nil
  self.vb_osc_input_pattern = nil
  self.vb_osc_output_pattern = nil
  self.vb_osc_input_warning = nil
  self.vb_osc_output_warning = nil
  self.vb_rule_description_button = nil
  self.vb_rule_description_input = nil
  self.vb_rule_description_row = nil
  self.vb_rule_description_toggle = nil
  self.vb_osc_options = nil
  self.vb_voice_options = nil
  self.vb_toggle_options_button = nil
  self.vb_rule_options_midi_row = nil
  self.vb_rule_options_switch = nil
  self.vb_rule_options_tab_description = nil
  self.vb_rule_options_tab_voice = nil
  self.vb_rule_options_tab_midi = nil
  self.vb_rule_options_tab_osc = nil
  self.vb_rule_options = nil
  self.vb_action_label_elm = nil
  self.vb_action_buttons = nil
  self.vb_action_missing_output = nil
  self.vb_rule = nil

end


--------------------------------------------------------------------------------
-- add view to the rules container
-- @param xrule (xRule)

function xRulesUIEditor:build_rule()

  local vb = self.vb

  local xrule = self.xrule
  local xruleset = self.xrules.selected_ruleset
  local rule_idx = self.xrules.selected_rule_index
  local ruleset_idx = self.xrules.selected_ruleset_index

  self:attach_to_rule(xrule)

  local option_row_w = xRulesUI.MAIN_PANEL_W - 8

  self.vb_revert_ruleset_button = vb:button{
    text = "Revert",
    tooltip = "Click to revert to the last saved version",
    notifier = function()
      self.owner.suppress_ruleset_notifier = true
      local passed,err = self.xrules:revert_ruleset()
      self.owner.suppress_ruleset_notifier = false
      --print(">>> revert - passed,err",passed,err)
      if not passed then
        renoise.app():show_warning(err)
      else
        self.xrules.selected_rule_index = rule_idx
        --self.xrules.selected_ruleset_index = self.xrules.selected_ruleset_index
        self.ui._build_rulesets_requested = true
        self.ui._build_rule_requested = true
      end
    end
  }

  self.vb_save_ruleset_button = vb:button{
    text = "Save changes",
    tooltip = "Click to save the ruleset",
    notifier = function()
      
      self.owner.suppress_ruleset_notifier = true
      local passed,err = self.xrules:save_ruleset()
      self.owner.suppress_ruleset_notifier = false

      if not passed then
        renoise.app():show_warning(err)
      else
        self.ui._update_rule_options_requested = true
        self.ui._build_rulesets_requested = true
      end
    end
  }

  --== description ==--

  self.vb_rule_description_button = vb:button{
    text = "Done",
    active = false,
    notifier = function()
      xruleset.description = self.vb_rule_description_input.text
    end
  }

  local calculate_height = function()
    local min_lines = 3
    local line_height = 16
    local elm = self.vb_rule_description_input
    elm.height = math.max(min_lines,#elm.paragraphs)*line_height
  end

  self.vb_rule_description_input = vb:multiline_textfield{
    text = xruleset.description,
    width = xRulesUI.MAIN_PANEL_W-66,
    font = "mono",
    height = 40,
    notifier = function()
      self.vb_rule_description_button.active = true
      calculate_height()
    end,
  }
  calculate_height()

  self.vb_rule_description_row = vb:row{
    self.vb_rule_description_input,
    self.vb_rule_description_button,
  }

  self.vb_rule_description_toggle = vb:checkbox{
    value = (xruleset.description ~= "") and true or false,
    notifier = function(val)
      if val then
        if (self.vb_rule_description_input.text == "") then
          self.vb_rule_description_input.text = "Enter description..."
        end
        xruleset.description = self.vb_rule_description_input.text
      elseif not val then
        xruleset.description = ""
      end
      self.ui._update_rule_options_requested = true
    end
  }

  self.vb_rule_options_tab_description = vb:column{
    visible = false,
    vb:column{
      margin = 3,
      vb:row{
        self.vb_rule_description_toggle,
        vb:text{
          text = "Enter a description for this ruleset",
        },
      },
      self.vb_rule_description_row,
    },
  }


  --== voice manager options ==--

  local voice_text_w = 160

  self.vb_voice_options = vb:column{
    visible = xruleset.manage_voices,
    style = "group",
    margin = 6,
    width = option_row_w,
    vb:text{
      text = "TODO - here will be options to maintain voices, linking note-on/off messages, etc.",
      width = voice_text_w,
    },

    --[[
    vb:row{
      vb:text{
        text = "Note length (0 = unlimited)",
        width = voice_text_w,
      },
      vb:valuebox{
        value = 0,
        min = 0,
        max = 100000,
      },
    },
    vb:row{
      vb:text{
        text = "Link incoming/outgoing notes",
        width = voice_text_w,
      },
      vb:checkbox{
        value = true
      },
    },
    ]]

  }

  self.vb_rule_options_tab_voice = vb:column{ 
    visible = false,
    vb:column{
      margin = 3,
      vb:row{
        tooltip = "Enable the voice-manager for this ruleset",
        vb:checkbox{
          value = xruleset.manage_voices,
          notifier = function(val)
            xruleset.manage_voices = val
          end,
        },
        vb:text{
          text = "Enable Voice Manager",
        },
      },
      self.vb_voice_options,
    }
  }

  --== midi options ==--

  self.vb_rule_options_midi_row = vb:column{
    style = "group",
    margin = 6,
    vb:multiline_text{
      width = option_row_w - 12,
      height = 20,
      text = "MIDI input is enabled for this rule, receiving from active devices",
    },
  }

  self.vb_rule_options_tab_midi = vb:row{ 
    visible = false,
    vb:column{
      margin = 3,
      vb:row{
        vb:checkbox{
          value = xrule.midi_enabled,
          tooltip = "Enable MIDI input for this rule",
          notifier = function(val)
            xrule.midi_enabled = val
            self.ui._build_rulesets_requested = true
          end,
        },
        vb:text{
          text = "Enable MIDI input for this rule",
        },
      },
      self.vb_rule_options_midi_row,
    },
  }


  --== osc options ==--

  local osc_control_w = xRulesUI.MAIN_PANEL_W - (xRulesUI.OSC_LABEL_W+50)

  self.vb_osc_input_pattern = vb:textfield{
    width = osc_control_w,
    text = xrule.osc_pattern.pattern_in,
    tooltip = "Enter your osc input pattern here,"
            .."\ne.g. 'renoise/trigger/midi %i'",
    notifier = function(str)
      local is_valid = xOscPattern.test_pattern(str)
      if is_valid or (str == "") then
        xrule.osc_pattern.pattern_in = str
      else
        LOG("input pattern is not valid",str)
      end
      self.ui._build_rulesets_requested = true
      self.ui._build_rule_requested = true
    end
  }


  self.vb_osc_output_pattern = vb:textfield{
    width = osc_control_w,
    text = xrule.osc_pattern.pattern_out,
    tooltip = "Enter your osc output pattern here,"
            .."\ne.g. 'renoise/trigger/midi $1'",
    notifier = function(str)
      local is_valid = xOscPattern.test_pattern(str)
      if is_valid or (str == "") then
        xrule.osc_pattern.pattern_out = str
      else
        LOG("output pattern is not valid",str)
      end
      self.ui._update_rule_options_requested = true
      self.ui._build_rulesets_requested = true
    end
  }

  self.vb_osc_input_warning = vb:row{
    tooltip = "This is not a valid OSC pattern",
    vb:text{
      text = xRulesUI.TXT_WARNING,
    }
  }
  self.vb_osc_output_warning = vb:row{
    tooltip = "This is not a valid OSC pattern",
    vb:text{
      text = xRulesUI.TXT_WARNING,
    }
  }

  self.vb_osc_options = vb:column{
    style = "group",
    margin = 6,
    width = option_row_w,
    vb:row{ 
      vb:text{
        text = "Input Pattern",
        width = xRulesUI.OSC_LABEL_W,
      },
      self.vb_osc_input_pattern,
      self.vb_osc_input_warning,
    },
    vb:row{ 
      vb:text{
        text = "Output Pattern",
        width = xRulesUI.OSC_LABEL_W,
      },
      self.vb_osc_output_pattern,
      self.vb_osc_output_warning,
    },
  }

  self.vb_rule_options_tab_osc = vb:row{ 
    visible = false,
    vb:column{
      margin = 3,
      width = option_row_w,
      vb:row{
        vb:checkbox{
          value = xruleset.osc_enabled,
          tooltip = "Enable Open Sound Protocol (OSC) features for this ruleset",
          notifier = function(val)
            xruleset.osc_enabled = val
          end,
        },
        vb:text{
          text = "Enable OSC Features for this ruleset",
        },
      },
      self.vb_osc_options,
    },
  }

  --== rule options & header ==--

  self.vb_toggle_options_button = vb:button{
    text = xRulesUI.TXT_ARROW_DOWN,
    tooltip = "Click to show rule/ruleset options",
    notifier = function()
      self:toggle_options()
    end
  }

  self.vb_rule_options_switch = vb:switch{
    items = {
      "Description",
      "Voice Manager",
      "MIDI Input",
      "OSC Features",
    },
    value = self.ui.rule_options_tab_index,
    width = option_row_w,
    notifier = function(idx)
      self:set_rule_options_tab(idx)
    end
  }

  self.vb_rule_options = vb:column{
    vb:space{
      height = 4,
    },
    self.vb_rule_options_switch,
    self.vb_rule_options_tab_description,
    self.vb_rule_options_tab_voice,
    self.vb_rule_options_tab_midi,
    self.vb_rule_options_tab_osc,
  }

  local vb_ruleset_name = vb:text{
    text = self.ui:get_ruleset_name(ruleset_idx),
    font = "italic",
  }

  local vb_rule_name = vb:text{
    text = self.xrules.selected_ruleset:get_rule_name(rule_idx),
    font = "italic",
  }

  self.ui:fit_element_width(vb_ruleset_name,150)
  self.ui:fit_element_width(vb_rule_name,150)

  local vb_rule_header = vb:column{
    vb:space{
      width = xRulesUI.MAIN_PANEL_W-18,
    },
    vb:row{
      vb:horizontal_aligner{ -- rule/set 
        width = xRulesUI.MAIN_PANEL_W-170,
        vb:row{ 
          style = "plain",
          vb:space{width=3},
          vb:checkbox{
            visible = false,
            notifier = function()
              self.ui:rename_selected_ruleset()
            end
          },
          vb_ruleset_name,
          vb:space{width=3},
        },
        vb:button{
          tooltip = "Remove ruleset",
          width = xRulesUI.CONTROL_SM,
          height = xRulesUI.CONTROL_SM,
          text = xRulesUI.TXT_CLOSE,
          notifier = function()
            local str_msg = "Are you sure you want to remove this ruleset?"
                          .."\n(the file can still be loaded back from disk)"
            local choice = renoise.app():show_prompt("Remove ruleset", str_msg, {"OK","Cancel"})
            if (choice == "OK") then
              self.ui:remove_selected_ruleset()
            end
          end

        },
        vb:row{ -- rule name
          style = "plain",
          vb:space{width=3},
          vb:checkbox{ -- click
            visible = false,
            notifier = function()
              self.ui:rename_selected_rule()
            end
          },
          vb_rule_name,
          vb:space{width=3},
        },
        vb:button{ 
          tooltip = "Remove this rule",
          width = xRulesUI.CONTROL_SM,
          height = xRulesUI.CONTROL_SM,
          text = xRulesUI.TXT_CLOSE,
          notifier = function()
            self.ui:remove_selected_rule()
          end
        },
        vb:button{
          tooltip = "Add new rule",
          width = xRulesUI.CONTROL_SM,
          height = xRulesUI.CONTROL_SM,
          text = xRulesUI.TXT_ADD,
          notifier = function()
            self.ui:add_rule()
          end
        },
      },
      vb:row{
        self.vb_save_ruleset_button,
        self.vb_revert_ruleset_button,
        self.vb_toggle_options_button,
      },
    }
  }

  local view = vb:column{
    margin = xRulesUI.MARGIN_SM,
    vb:column{ -- header
      style = "panel",
      margin = xRulesUI.MARGIN_SM,
      vb_rule_header,
      self.vb_rule_options,
    },
    --self.vb_rule_description_container,
    vb:space{
      height = xRulesUI.MARGIN_SM,
    }

  }

  --== conditions ==--

  local vb_add_condition = vb:button{
    text = "Add Condition",
    height = xRulesUI.CONTROL_H,
    width = xRulesUI.SUBMIT_BT_W,
    notifier = function()
      self:add_condition()
    end,
  }


  if (#xrule.conditions == 0) then
    -- initial/empty 
    view:add_child(vb:row{
      vb:row{        
        vb:space{
          width = xRulesUI.MARGIN_SM,
        },
        vb:text{
          width = xRulesUI.RULE_MARGIN_W,
          text = "WHEN",
          align = "right",
          font = "italic",
        },
        vb:space{
          width = xRulesUI.MARGIN_SM,
        },
      },
      vb_add_condition,
      vb:checkbox{
        value = xrule.match_any,
        notifier = function(val)
          xrule.match_any = val
        end,
      },
      vb:text{
        text = "Match any message",
      }
    })
  else
    
    --print("xrule.conditions",rprint(xrule.conditions))

    xrule:fix_conditions()

    local last_was_logic = false
    local yet_to_output_first_row = true
    local logic_label 
    local done = false
    local count = 1
    while not done do
      local v = xrule.conditions[count]
      --print("*** PRE count,v",count,rprint(v))

      if (#v == 1) then
        -- encountered logic
        if (v[1] == xRule.LOGIC.AND) then
          logic_label = "AND"
        elseif (v[1] == xRule.LOGIC.OR) then
          logic_label =  "OR"
        end
        count = count+1
        v = xrule.conditions[count]
      else
        if (count == 1) then
          logic_label = "WHEN"
        else
          logic_label = "AND"
        end
      end

      if (#v == 0) then
        local xrow = xRulesUICondition{
          vb = self.vb,
          ui = self.ui,
          editor = self,
          xrule = self.xrules.selected_rule,
        }
        local row = xrow:build_condition_row(count,v,logic_label)

        --print("row",row)
        if row then
          view:add_child(row)
        end
        yet_to_output_first_row = false
      end

      if not xrule.conditions[count+1] then
        done = true
      else
        count = count+1
      end

    end

    view:add_child(vb:row{
      margin = xRulesUI.MARGIN,
      vb:space{
        width = xRulesUI.RULE_MARGIN_W,
      },
      vb_add_condition,
      vb:button{
        text = "Remove All",
        height = xRulesUI.CONTROL_H,
        width = xRulesUI.SUBMIT_BT_W,
        notifier = function()
          self:remove_all_conditions()
        end,
      },
    })

  end

  --== actions ==--

  local show_missing_output_warning = (#xrule.conditions > 0)

  self.vb_action_label_elm = vb:text{
    width = xRulesUI.RULE_MARGIN_W,
    text = "",
    align = "right",
    font = "italic",
  }

  --self.vb_action_buttons = nil
  self.vb_action_buttons = vb:row{
    vb:row{
      vb:space{
        width = xRulesUI.MARGIN_SM,
      },
      self.vb_action_label_elm,
      vb:space{
        width = xRulesUI.MARGIN_SM,
      },
    },
    vb:button{
      text = "Add Action",
      height = xRulesUI.CONTROL_H,
      width = xRulesUI.SUBMIT_BT_W,
      notifier = function()
        self:add_action()
      end,
    },
  }

  if (#xrule.actions == 0) then
    -- initial/empty 
    view:add_child(self.vb_action_buttons)
    self.vb_action_label_elm.text = "THEN"

  else

    for k,action in ipairs(xrule.actions) do
      local label = (k == 1) and "THEN" or ""
      local xrow = xRulesUIAction{
        vb = self.vb,
        ui = self.ui,
        editor = self,
        xrule = self.xrules.selected_rule,
      }
      local row = xrow:build_action_row(k,action,label)
      if row then
        view:add_child(row)
      end
      if show_missing_output_warning 
        and (table.keys(action)[1] == xRule.ACTIONS.OUTPUT_MESSAGE) 
      then
        show_missing_output_warning = false
      end
    end
    view:add_child(vb:space{
      height = xRulesUI.MARGIN_SM,
    })

    self.vb_action_buttons:add_child(vb:button{
      text = "Remove All",
      height = xRulesUI.CONTROL_H,
      width = xRulesUI.SUBMIT_BT_W,
      notifier = function()
        self:remove_all_actions()
      end,
    })

    --pcall(function()
      view:add_child(self.vb_action_buttons)
    --end)

  end

  self.vb_action_missing_output = vb:row{
    tooltip = "Warning: no output defined for this rule. This means that messages that match the above conditions will never be passed on to Renoise",
    vb:text{
      text = "⚠ No output defined",
    },
  }

  self.vb_action_buttons:add_child(self.vb_action_missing_output)
  self.vb_action_missing_output.visible = show_missing_output_warning

  self.vb_rule = view

  self:set_rule_options_tab(self.ui.rule_options_tab_index)

  self.ui._update_rule_options_requested = true

  return view

end

--------------------------------------------------------------------------------

function xRulesUIEditor:attach_to_rule(xrule)

  xrule.midi_enabled_observable:add_notifier(function()
    --print(">>> xRulesUIEditor:xrule.midi_enabled_observable fired...")
    self.ui._update_rule_options_requested = true
  end)

  xrule.modified_observable:add_notifier(function()
    --print(">>> xRulesUIEditor:xrule.midi_enabled_observable fired...")
    self.ui._build_rulesets_requested = true
    self.ui._update_rule_options_requested = true
  end)


end

--------------------------------------------------------------------------------

function xRulesUIEditor:set_rule_options_tab(idx)

  self.vb_rule_options_tab_description.visible = false
  self.vb_rule_options_tab_voice.visible = false
  self.vb_rule_options_tab_midi.visible = false
  self.vb_rule_options_tab_osc.visible = false
  if (idx == xRulesUIEditor.TAB.DESCRIPTION) then
    self.vb_rule_options_tab_description.visible = true
  elseif (idx == xRulesUIEditor.TAB.VOICEMGR_ENABLED) then
    self.vb_rule_options_tab_voice.visible = true
  elseif (idx == xRulesUIEditor.TAB.MIDI_ENABLED) then
    self.vb_rule_options_tab_midi.visible = true
  elseif (idx == xRulesUIEditor.TAB.OSC_ENABLED) then
    self.vb_rule_options_tab_osc.visible = true
  end

  self.ui.rule_options_tab_index = idx

end


--------------------------------------------------------------------------------

--- Hide the dialog

function xRulesUIEditor:toggle_options()

  self.ui.show_rule_options = not self.ui.show_rule_options  
  self.ui._update_rule_options_requested = true

  -- select the first "defined" tab 
  local xruleset = self.xrules.selected_ruleset
  local has_description = (xruleset.description ~= "")
  if has_description then
    self:set_rule_options_tab(xRulesUIEditor.TAB.DESCRIPTION)
  elseif xruleset.manage_voices then
    self:set_rule_options_tab(xRulesUIEditor.TAB.VOICEMGR_ENABLED)
  elseif self.xrule.midi_enabled then
    self:set_rule_options_tab(xRulesUIEditor.TAB.MIDI_ENABLED)
  elseif xruleset.osc_enabled then
    self:set_rule_options_tab(xRulesUIEditor.TAB.OSC_ENABLED)
  end


end


--------------------------------------------------------------------------------
-- update the options for this rule

function xRulesUIEditor:update_rule_options()

  self.vb_rule_options.visible = self.ui.show_rule_options
  
  local xrule = self.xrule
  local xruleset = self.xrules.selected_ruleset
  --print("xruleset",xruleset)
  if self.xrule and xruleset then
    self.vb_voice_options.visible = xruleset.manage_voices 
    self.vb_osc_options.visible = xruleset.osc_enabled 

    -- display description (if any)
    local has_description = (xruleset.description ~= "")
    self.vb_rule_description_row.visible = has_description
    self.vb_rule_description_toggle.value = has_description
    --self.vb_rule_description_input.text = 

    self.vb_rule_options_midi_row.visible = xrule.midi_enabled

    -- test OSC syntax and display warning if somehow broken
    if xruleset.osc_enabled then
      local input_valid = xOscPattern.test_pattern(self.vb_osc_input_pattern.text) 
      local output_valid = (self.vb_osc_output_pattern.text == "") and true
        or xOscPattern.test_pattern(self.vb_osc_output_pattern.text) 
      --print("input_valid",input_valid)
      --print("output_valid",output_valid)
      self.vb_osc_input_warning.visible = not input_valid
      self.vb_osc_output_warning.visible = not output_valid
    end
  

  end

  self.vb_save_ruleset_button.active = xruleset and xruleset.modified or false
  self.vb_revert_ruleset_button.active = xruleset.modified or false

  self.vb_toggle_options_button.text = ("More %s"):format(self.ui.show_rule_options and
    xRulesUI.TXT_ARROW_UP or xRulesUI.TXT_ARROW_DOWN)

  self.vb_rule_options_switch.value = self.ui.rule_options_tab_index

end

--------------------------------------------------------------------------------
--- insert new action into rule
-- @param row_idx (int)

function xRulesUIEditor:add_action(row_idx)

  local xrule = self.xrule
  if row_idx then
    table.insert(xrule.actions,row_idx,{
      set_channel = 1,
    })
  else
    table.insert(xrule.actions,{
      output_message = 1,
    })
  end
  local success,err = xrule:compile()
  if err then
    LOG(err)
  end
  self.ui._build_rule_requested = true

end

--------------------------------------------------------------------------------
--- insert new condition into rule
-- @param row_idx (int)

function xRulesUIEditor:add_condition(row_idx)

  local xrule = self.xrule
  local def = {
    channel = {
      equal_to = 1,
    }
  }

  if row_idx then
    table.insert(xrule.conditions,row_idx,def)
  else
    table.insert(xrule.conditions,def)
  end

  local success,err = xrule:compile()
  if err then
    LOG(err)
  end
  self.ui._build_rule_requested = true

end

--------------------------------------------------------------------------------
-- get the contextual labels - e.g. 
--  MIDI: {"note","velocity"}
--  OSC: {'foo','bar','baz')
-- @return table, list of names

function xRulesUIEditor:get_contextual_labels()

  local midi_labels,osc_labels 
  --print("self.last_msg_type",self.last_msg_type)
  if self.last_msg_type then
    local msg_type = string.upper(self.last_msg_type)
    midi_labels = xMidiMessage.VALUE_LABELS[msg_type]
  end
  local xrule = self.xrule
  local xruleset = self.xrules.selected_ruleset
  --print("xrule.osc_pattern",xrule.osc_pattern)

  if xruleset 
    and xrule 
    and xruleset.osc_enabled 
    and xrule.osc_pattern.complete
  then
    osc_labels = xrule.osc_pattern.arg_names
    for k,v in ipairs(osc_labels) do
      if (v == "") then
        osc_labels[k] = ("$%x"):format(k)
      else
        osc_labels[k] = ("$%s"):format(v)
      end
    end
  end

  return osc_labels or midi_labels or {}

end

--------------------------------------------------------------------------------
-- provided with a string (e.g. "value_1"), return the contextual value
-- @param aspect (string)
-- @return string,int

function xRulesUIEditor:get_contextual_aspect(aspect)

  local context_labels = self:get_contextual_labels()
  local value_idx = xRule.get_value_index(aspect)
  return context_labels[value_idx],value_idx

end

--------------------------------------------------------------------------------
-- go through, and replace 'certain values' in a table of strings
-- we look for a name such as "value_1" or "decrease_value_1", and replace
-- the "value_x" part with the contextual name
-- @param t (table)
-- @return table

function xRulesUIEditor:add_context(t)

  local rslt = table.copy(t)
  local labels = self:get_contextual_labels()
  for k,v in ipairs(rslt) do
    local val_index = xRule.get_value_index(v)
    if val_index and labels[val_index] then
      rslt[k] = labels[val_index] or ""
    end
  end
  return rslt

end

--------------------------------------------------------------------------------

function xRulesUIEditor:remove_all_conditions()

  local str_msg = "Are you sure you want to remove all conditions"
  local choice = renoise.app():show_prompt("Remove conditions", str_msg, {"OK","Cancel"})
  if (choice == "OK") then
    local xrule = self.xrule
    xrule.conditions = {}
    local success,err = xrule:compile()
    if err then
      LOG(err)
    end
    self.ui._build_rule_requested = true

  end

end

--------------------------------------------------------------------------------

function xRulesUIEditor:remove_all_actions()

  local str_msg = "Are you sure you want to remove all actions?"
  local choice = renoise.app():show_prompt("Remove actions", str_msg, {"OK","Cancel"})
  if (choice == "OK") then
    local xrule = self.xrule
    xrule.actions = {}
    local success,err = xrule:compile()
    if err then
      LOG(err)
    end
    self.ui._build_rule_requested = true

  end

end


--==============================================================================
-- Static Methods
--==============================================================================

-- as actions/aspects are changed, attempt to convert existing value
-- (otherwise, provide a default value)
-- @param val, number/string/boolean
-- @param key, string - name of aspect/action, e.g. "set_track_index"
-- @param basetype, table 

function xRulesUIEditor.change_value_assist(val,key,val_type)

  local basetypes
  if (val_type == "aspect") then
    basetypes = xRule.ASPECT_BASETYPE
  elseif (val_type == "action") then
    basetypes = xRule.ACTION_BASETYPE
  else
    error("Unexpected val_type")
  end

  local new_type = basetypes[string.upper(key)]
  new_type = new_type and new_type or "number"
  --print("new_type",new_type)
  local untranslateable = xRulesUI.ACTION_UNTRANSLATEABLE[string.upper(key)]
  if (val_type == "action") and untranslateable then
    return untranslateable
  elseif (new_type == "number") and (type(tonumber(val)) == "number") then
    return tonumber(val)
  elseif (new_type == "string") then
    return tostring(val)
  else
    -- attempt to provide a sensible default value
    if (val_type == "action") then
      key = xRule.ACTIONS_TO_ASPECT_MAP[string.upper(key)]
    end
    if (key) then
      local aspect_default = xRule.ASPECT_DEFAULTS[string.upper(key)]
      local default = (type(aspect_default) == "table") and aspect_default[1] or aspect_default
      return default
    else
      LOG("Provide a default value")
      return 1
    end
  end

end

--------------------------------------------------------------------------------
-- custom number/string converters 
-- @param msg_type (xMidiMessage.TYPE)
-- @param value_idx (int)
-- @return function,function

function xRulesUIEditor.get_custom_converters(msg_type,value_idx)

  local fn_tostring = nil
  local fn_tonumber = nil
  if (((msg_type == xMidiMessage.TYPE.NOTE_ON) 
    or (msg_type == xMidiMessage.TYPE.NOTE_OFF))
    and (value_idx == 1)) 
    or ((msg_type == xMidiMessage.TYPE.KEY_AFTERTOUCH)
    and (value_idx == 2)) 
  then
    fn_tostring = function(val)
      return xNoteColumn.note_value_to_string(math.floor(val))
    end 
    fn_tonumber = function(str)
      return xNoteColumn.note_string_to_value(str)
    end
  end
  return fn_tostring,fn_tonumber

end

--------------------------------------------------------------------------------
-- determine the maximum value for a given message type 
-- @param msg_type (xMidiMessage.TYPE)
-- @param value_idx (int)
-- @return function,function

function xRulesUIEditor.get_maximum_value(msg_type,value_idx)

  if (msg_type == xMidiMessage.TYPE.NOTE_ON) 
    or (msg_type == xMidiMessage.TYPE.NOTE_OFF)
    or (msg_type == xMidiMessage.TYPE.KEY_AFTERTOUCH)
    or (msg_type == xMidiMessage.TYPE.PROGRAM_CHANGE)
  then
    return 127
  elseif msg_type then
    return 16383
  else
    return cLib.HUGE_INT
  end

end

--------------------------------------------------------------------------------
-- validate sysex string: a row of strings, separated by space, in which
--  each part is either an asterisk or a value between 0x00 - 0xFF
-- @param str (string), e.g. "F0 01 * 06 F7"
-- @return boolean,string

function xRulesUIEditor.validate_sysex_string(str)

  local t = cString.split(str," ")
  if (t[1] ~= "F0") then
    return false, "Sysex string must begin with 'F0'"
  end
  if (t[#t] ~= "F7") then
    return false, "Sysex string must end with 'F7'"
  end

  for k = 2,#t-1 do
    local part = t[k]
    if (part == "*") then
      -- wildcard
    else
      local num = tonumber("0x"..tostring(t[k]))
      if not num then
        return false, "Each sysex value must be either a hexadecimal value (e.g. 7F) or a wildcard (* asterisk)"
      end
      if (num > 0xFF) then
        return false, "Sysex values cannot be higher than FF (decimal 255)"
      end
    end
  end

  return true

end

--------------------------------------------------------------------------------
-- "inject" missing port names into list of midi devices
-- @param devices (table<string>)
-- @param str_name (string)
-- @return table<string>

function xRulesUIEditor:inject_port_name(devices,str_name)

  if not str_name then
    return devices -- why do we end up here ?? 
  end

  if not table.find(devices,str_name) then
    table.insert(devices,1,str_name.." (N/A)")
  end

  return devices

end


