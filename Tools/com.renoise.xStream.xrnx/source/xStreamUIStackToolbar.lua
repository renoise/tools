--[[============================================================================
xStreamUIStackToolbar
============================================================================]]--
--[[

	Supporting class for xStream 

]]

--==============================================================================

local MEMBER_W = 84
local POPUP_W = 100
local PANEL_W = xStreamUI.FULL_PANEL_W - 6 -- margins

class 'xStreamUIStackToolbar'

---------------------------------------------------------------------------------------------------

function xStreamUIStackToolbar:__init(xstream,vb,ui)
  TRACE("xStreamUIStackToolbar:__init(xstream,vb,ui)",xstream,vb,ui)

  assert(type(xstream)=="xStream")
  assert(type(vb)=="ViewBuilder")
  assert(type(ui)=="xStreamUI")

  self.xstream = xstream
  self.vb = vb
  self.prefs = renoise.tool().preferences

  --== notifiers ==--

  ui.show_stack_observable:add_notifier(function()
    TRACE("xStreamUIStackToolbar - show_stack_observable fired...")  
    self:update()
  end)

  ui.stack_has_focus_observable:add_notifier(function()
    TRACE("xStreamUIStackToolbar - stack_has_focus_observable fired...")  
    self:update()
  end)

  --== initialize ==--

  self:attach_to_process()

end

---------------------------------------------------------------------------------------------------

function xStreamUIStackToolbar:build_stack_member(idx,name)
  TRACE("xStreamUIStackToolbar:build_stack_member(idx,name)",idx,name)

  local vb = self.vb

  local select_member = function()
    --print(">>> select_member",idx)
    self.xstream.selected_member_index = idx
    self.xstream.ui.stack_has_focus = false
  end

  return vb:column{
    vb:space{
      width = MEMBER_W,
      height = 3,
    },    
    vb:row{
      vb:row{
        vb:bitmap{
          id = ("xStreamUIStackToolbarMember%dBitmapIn"):format(idx),
          bitmap = "./source/icons/stack_input_none.bmp",
          mode = "body_color",
          notifier = function()
            select_member()
          end,          
        },
        vb:row{
          margin = -3,
          vb:space{
            width = 3,
          },
          vb:checkbox{
            id = ("xStreamUIStackToolbarMember%dLabelCB"):format(idx),
            visible = false,
            notifier = function()
              select_member()
            end,
          },
          vb:text{
            id = ("xStreamUIStackToolbarMember%dLabel"):format(idx),
            text = name,
            width = MEMBER_W - 29,
          },
        },
      },
      vb:column{
        spacing = -12,
        vb:row{
          margin = -3,
          vb:text{
            visible = false,
            id = ("xStreamUIStackToolbarMember%dTextOut"):format(idx),
            font = "mono",
          },
        },
        vb:bitmap{
          visible = false,
          id = ("xStreamUIStackToolbarMember%dBitmapOut"):format(idx),
          bitmap = "./source/icons/stack_output_none.bmp",
          mode = "body_color",
          notifier = function()
            select_member()
          end,         
        },
      },
    },
    vb:space{
      width = MEMBER_W,
      height = 1,
    },    
    vb:row{
      vb:popup{
        id = ("xStreamUIStackToolbarMember%dModelSelector"):format(idx),
        items = {},
        width = MEMBER_W,
        notifier = function(val)
          self:set_model(idx,val-1)
        end
      }
      --[[
      spacing = -3,
      vb:button{
        width = MEMBER_W-20,
        text = "None",
      },
      vb:popup{
        width = 20,
        items = nil,
      }
      ]]
    }
  }

end

---------------------------------------------------------------------------------------------------
-- Set (or unset) model 

function xStreamUIStackToolbar:set_model(member_idx,model_idx)
  TRACE("xStreamUIStackToolbar:set_model(member_idx,model_idx)",member_idx,model_idx)

  assert(type(member_idx)=="number")
  assert(type(model_idx)=="number")

  local member = self.xstream.stack:get_member_at(member_idx)
  if (model_idx == 0) then 
    --print(">>> unset member")
    if member then 
      self.xstream.stack:unset_member(member_idx)
    end
  else 
    if member then 
      member.model_index = model_idx
    else
      --print(">>> create member on the fly ")
      member = xStreamStackMember(self.xstream,member_idx)    
      member.model_index = model_idx
      member.input = self.vb.views["xStreamUIStackToolbarInputs"].value
      member.output = self.vb.views["xStreamUIStackToolbarOutputs"].value
      self.xstream.stack:set_member(member_idx,member)
    end 
  end

end

---------------------------------------------------------------------------------------------------

function xStreamUIStackToolbar:build()
  TRACE("xStreamUIStackToolbar:build()")

  local vb = self.vb
  return vb:column{
    id = "xStreamUIStackToolbar",    
    margin = 3,
    style = "plain",
    vb:space{
      width = PANEL_W,
      height = 1,
    },
    vb:horizontal_aligner{
      mode = "justify",
      vb:row{
        vb:space{
          width = 6,
        },
        self:build_stack_member(1,"Model A"),
        self:build_stack_member(2,"Model B"),
        self:build_stack_member(3,"Model C"),
        self:build_stack_member(4,"Model D"),
      },
      vb:column{
        vb:row{
          vb:text{
            text = "IN",
            width = 30,
          },
          vb:popup{
            id = "xStreamUIStackToolbarInputs",
            items = nil,
            width = POPUP_W,
            notifier = function(val)
              local member = self.xstream.stack:get_selected_member()
              if member then 
                member.input = val
              end
            end
          }
        },
        vb:row{
          vb:text{
            text = "OUT",
            width = 30,
          },
          vb:popup{
            id = "xStreamUIStackToolbarOutputs",
            items = nil,
            width = POPUP_W,
            notifier = function(val)
              local member = self.xstream.stack:get_selected_member()
              if member then 
                member.output = val         
              end
            end,
          }

        },
      },
    },
  }

end

---------------------------------------------------------------------------------------------------

function xStreamUIStackToolbar:update()
  TRACE("xStreamUIStackToolbar:update()")

  local stack_tb = self.vb.views["xStreamUIStackToolbar"]
  if stack_tb then 
    stack_tb.visible = self.xstream.ui.show_stack 
  end

  local model_items = self.xstream.models:get_available()
  table.insert(model_items,1,"None")
  --print("model_items...",rprint(model_items))

  for k = 1,xStreamStack.MAX_MEMBERS do 
    
    -- highlight active member 
    local vb_label = self.vb.views[("xStreamUIStackToolbarMember%dLabel"):format(k)]
    --print(">>> vb_label",vb_label)
    if vb_label then 
      local selected_font_style = self.xstream.ui.stack_has_focus_observable.value 
        and "normal" or "bold"
      vb_label.font = (k==self.xstream.selected_member_index) 
        and selected_font_style or "italic"
    end 
    
    -- update model selectors 
    local vb_selector = self.vb.views[("xStreamUIStackToolbarMember%dModelSelector"):format(k)]
    if vb_selector then 
      vb_selector.items = model_items
      local member = self.xstream.stack:get_member_at(k)
      local model_idx = 0
      if member then 
        model_idx = member.model_index
      end
      vb_selector.value = (model_idx == 0) and 1 or model_idx+1
    end 
  end 

  self:update_inputs()
  self:update_outputs()

end


---------------------------------------------------------------------------------------------------
-- update input 

function xStreamUIStackToolbar:update_inputs()
  TRACE("xStreamUIStackToolbar:update_inputs()")

  local member = self.xstream.stack:get_selected_member()

  -- popup items
  -- add "N/A" suffix for invalid choices 
  local get_inputs = function()
    local member_idx = self.xstream.selected_member_index
    local inputs = table.copy(xStreamStackMember.INPUTS)
    for k = 1,#inputs do 
      local suffix = ""
      if ((k == xStreamStackMember.INPUT.MODEL_A) and (member_idx < 2))
        or ((k == xStreamStackMember.INPUT.MODEL_B) and (member_idx < 3))
        or ((k == xStreamStackMember.INPUT.MODEL_C) and (member_idx < 4))
        or ((k == xStreamStackMember.INPUT.MODEL_D) and (member_idx < 5)) 
      then
        suffix = " (N/A)"
      end
      inputs[k] = inputs[k] .. suffix
    end 
    for k = 1,16 do 
      table.insert(inputs,("Track %.2d"):format(k))
    end 
    return inputs
  end
  
  local vb_popup = self.vb.views["xStreamUIStackToolbarInputs"]
  vb_popup.items = get_inputs()

  if member then 
    vb_popup.value = member.input
  else 
    vb_popup.value = xStreamStackMember.INPUT.NONE
  end


  -- bitmaps 
  for k = 1,xStreamStack.MAX_MEMBERS do
    local member = self.xstream.stack:get_member_at(k)
    local vb_bitmap = self.vb.views[("xStreamUIStackToolbarMember%dBitmapIn"):format(k)]
    if vb_bitmap then 
      local str_bitmap = ""
      if not member or (member.input == xStreamStackMember.INPUT.NONE) then
        str_bitmap = "stack_input_none.bmp"
      elseif (member.input == xStreamStackMember.INPUT.MODEL_A) then
        str_bitmap = "stack_input_a.bmp"
      elseif (member.input == xStreamStackMember.INPUT.MODEL_B) then
        str_bitmap = "stack_input_b.bmp"
      elseif (member.input == xStreamStackMember.INPUT.MODEL_C) then
        str_bitmap = "stack_input_c.bmp"
      elseif (member.input == xStreamStackMember.INPUT.MODEL_D) then
        str_bitmap = "stack_input_d.bmp"
      --elseif (member.output == xStreamStackMember.INPUT.SELECTED_TRACK) then
      --  str_bitmap = "stack_output_patt.bmp"
      else
        str_bitmap = "stack_input_patt.bmp"
      end
      vb_bitmap.bitmap = "./source/icons/"..str_bitmap
    end 
  end

end

---------------------------------------------------------------------------------------------------
-- update outputs

function xStreamUIStackToolbar:update_outputs()
  TRACE("xStreamUIStackToolbar:update_outputs()")

  local member = self.xstream.stack:get_selected_member()

  -- popup items 
  local outputs = table.rcopy(xStreamStackMember.OUTPUTS)
  for k = 1,32 do 
    table.insert(outputs,("Track %.2d"):format(k))
  end 
  local vb_popup = self.vb.views["xStreamUIStackToolbarOutputs"]
  vb_popup.items = outputs

  if member then 
    vb_popup.value = member.output
  else 
    vb_popup.value = xStreamStackMember.OUTPUT.NONE
  end

  -- bitmaps 
  for k = 1,xStreamStack.MAX_MEMBERS do
    local member = self.xstream.stack:get_member_at(k)
    local vb_text_out = self.vb.views[("xStreamUIStackToolbarMember%dTextOut"):format(k)]
    local vb_bitmap = self.vb.views[("xStreamUIStackToolbarMember%dBitmapOut"):format(k)]    
    vb_text_out.visible = false
    vb_bitmap.visible = false

    if member and (member.output > xStreamStackMember.OUTPUT.PASS_ON) then 
      -- text for direct-to-track routing 
      if member then
        vb_text_out.text = ("%.2d"):format(member.output - xStreamStackMember.OUTPUT.PASS_ON)
      end
      vb_text_out.visible = true
    else
      -- bitmap representation
      local str_bitmap = ""
      if not member or (member.output == xStreamStackMember.OUTPUT.NONE) then
        str_bitmap = "stack_output_none.bmp"
      elseif (member.output == xStreamStackMember.OUTPUT.PASS_ON) then
        str_bitmap = "stack_output_pass_on.bmp"
      --elseif (member.output == xStreamStackMember.OUTPUT.SELECTED_TRACK) then
      --  str_bitmap = "stack_output_patt.bmp"
      else
        str_bitmap = "stack_output_patt.bmp"
      end
      vb_bitmap.bitmap = "./source/icons/"..str_bitmap
      vb_bitmap.visible = true
    end 

    --[[
    ]]
  end

end

---------------------------------------------------------------------------------------------------

function xStreamUIStackToolbar:attach_to_member()
  TRACE("xStreamUIStackToolbar:attach_to_member()")

  local model_index_notifier = function()
    --print("xStreamUIStackToolbar - model_index_notifier fired...")
    self:update()
  end

  local handle_member_changed = function()
    --print("xStreamUIStackToolbar - handle_member_changed fired...")
    self:update()
  end

  local member = self.xstream.stack:get_selected_member()
  --print(">>> member",member)
  if member then
    cObservable.attach(member.model_index_observable,model_index_notifier)
    cObservable.attach(member.input_observable,handle_member_changed)
    cObservable.attach(member.output_observable,handle_member_changed)
  end

end

---------------------------------------------------------------------------------------------------

function xStreamUIStackToolbar:attach_to_process()
  TRACE("xStreamUIStackToolbar:attach_to_process()")

  local handle_selected_member = function()
    TRACE("xStreamUIStackToolbar - handle_selected_member fired...")
    self:update()
    self:attach_to_member()
  end

  local obs = self.xstream.stack.selected_member_index_observable
  cObservable.attach(obs,handle_selected_member)

  self:attach_to_member()

end

---------------------------------------------------------------------------------------------------
--[[
function xStreamUIStackToolbar:prompt_convert()
  TRACE("xStreamUIStackToolbar:prompt_convert()")

  local vb = self.vb

  local content_view = vb:column{
    margin = 8,
    vb:text{
      text = This will convert the model into a stack

From the toolbar, you can return to single
model mode by choosing ‘Single Model’ instead of 
‘Stacked Models’.,
    },
    vb:horizontal_aligner{
      mode = "justify",
      vb:button{
        text = "OK",
        width = vPrompt.generic_button_width,
        height = vPrompt.generic_button_height,
        notifier = function()
          vPrompt.close_custom_prompt()
          self.xstream.stack:convert_to_stack()
        end,
      },
      vb:button{
        text = "Cancel",
        width = vPrompt.generic_button_width,
        height = vPrompt.generic_button_height,
        notifier = function()
          vPrompt.close_custom_prompt()
        end,
      }
    }
  }

  vPrompt.show_custom_prompt("Convert model?",content_view)


end 
]]
