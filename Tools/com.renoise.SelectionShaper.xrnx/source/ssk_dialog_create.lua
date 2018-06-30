--[[===============================================================================================
SSK_Dialog_Create
===============================================================================================]]--

--[[

Dialog for the SSK tool (create sample)

]]

--=================================================================================================

class 'SSK_Dialog_Create' (vDialog)

function SSK_Dialog_Create:__init(...)
  vDialog.__init(self,...)
  local args = cLib.unpack_args(...)
  self.vb = renoise.ViewBuilder()
  self:build()
end

---------------------------------------------------------------------------------------------------
-- methods required by vDialog
---------------------------------------------------------------------------------------------------
-- return the UI which was previously created with build()

function SSK_Dialog_Create:create_dialog()
  TRACE("SSK_Dialog_Create:create_dialog()")

  return self.vb:column{
    self.vb_content,
  }

end

---------------------------------------------------------------------------------------------------
-- populate with current buffer values 

function SSK_Dialog_Create:show()
  TRACE("SSK_Dialog_Create:show()")

  vDialog.show(self)

  local defaults = xSampleBuffer.get_default_properties()
  --print("defaults...",rprint(defaults))
  self:set_bit_depth(defaults.bit_depth)
  self:set_sample_rate(defaults.sample_rate)
  self:set_num_channels(defaults.number_of_channels)
  self:set_num_frames(defaults.number_of_frames)
end

---------------------------------------------------------------------------------------------------

function SSK_Dialog_Create:build()

  local vb = self.vb
  local view = nil

  local dlg_margin = 8
  local grid_w = 80
  local submit_button_w = 70
  local submit_button_h = 22

  view = vb:column{
    margin = dlg_margin,
    vb:row{
      vb:column{
        vb:text{
          text = "#Samples:",
        },
        vb:valuebox{
          id = "ssk_length_as_frames",
          width = grid_w,
          min = 1,
          max = 999999999,
        }
      },
    },
    vb:row{
      vb:column{
        vb:text{
          text = "Channels:",
        },
        vb:popup{
          id = "ssk_channels",
          width = grid_w,
          items = {"Mono","Stereo"}
        }
      },
      vb:column{
        vb:text{
          text = "Sample rate:",
        },
        vb:popup{
          id = "ssk_sample_rate",
          width = grid_w,
          items = SSK_Dialog_Create.get_sample_rate_items(),
        }
      },
      vb:column{
        vb:text{
          text = "Bit depth:",
        },
        vb:popup{
          id = "ssk_bit_depth",
          width = grid_w,
          items = {"8","16","24","32"},   
        }
      },
    },
    vb:space{
      height = 20,
    },
    vb:horizontal_aligner{
      mode = "distribute",
      vb:button{
        text = "Create",        
        width = submit_button_w,
        height = submit_button_h,
        notifier = function()
          self:create()
        end,
      },
      vb:button{
        text = "Cancel",
        width = submit_button_w,
        height = submit_button_h,
        notifier = function()
          self.dialog:close()
        end,
      }
    }
  }

  self.vb_content = view

end

---------------------------------------------------------------------------------------------------
-- Getters
---------------------------------------------------------------------------------------------------

function SSK_Dialog_Create:get_bit_depth()
  local ctrl = self.vb.views.ssk_bit_depth
  return xSampleBuffer.BIT_DEPTH[ctrl.value+1]
end

function SSK_Dialog_Create:set_bit_depth(val)
  local ctrl = self.vb.views.ssk_bit_depth
  local idx = table.find(xSampleBuffer.BIT_DEPTH,val)
  --print("set_bit_depth() val,idx",val,idx)
  if (idx) then
    ctrl.value = idx-1
  end
end

function SSK_Dialog_Create:get_sample_rate()
  local ctrl = self.vb.views.ssk_sample_rate
  return xSampleBuffer.SAMPLE_RATE[ctrl.value]
end

function SSK_Dialog_Create:set_sample_rate(val)
  local ctrl = self.vb.views.ssk_sample_rate
  local idx = table.find(xSampleBuffer.SAMPLE_RATE,val)
  --print("set_sample_rate() val,idx",val,idx)
  ctrl.value = idx
end

function SSK_Dialog_Create:get_num_channels()
  return self.vb.views.ssk_channels.value
end

function SSK_Dialog_Create:set_num_channels(val)
  self.vb.views.ssk_channels.value = val
end

function SSK_Dialog_Create:get_num_frames()
  return self.vb.views.ssk_length_as_frames.value
end

function SSK_Dialog_Create:set_num_frames(val)
  self.vb.views.ssk_length_as_frames.value = val
end

---------------------------------------------------------------------------------------------------
-- Class methods
---------------------------------------------------------------------------------------------------

function SSK_Dialog_Create:create()
  TRACE("SSK_Dialog_Create:create()")

  local num_frames = self:get_num_frames()
  local sample_rate = self:get_sample_rate()
  local bit_depth = self:get_bit_depth()
  local num_channels = self:get_num_channels()

  local instr = rns.selected_instrument
  local sample_idx = rns.selected_sample_index

  sample_idx = xInstrument.insert_sample(instr,sample_idx,sample_rate,bit_depth,num_channels,num_frames)
  rns.selected_sample_index = sample_idx

  self.dialog:close()

end

---------------------------------------------------------------------------------------------------
-- Static functions 
---------------------------------------------------------------------------------------------------

function SSK_Dialog_Create.get_sample_rate_items()
  local t = {}
  for k,v in ipairs(xSampleBuffer.SAMPLE_RATE) do
    table.insert(t,("%d Hz"):format(v))
  end
  return t
end

