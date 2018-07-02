--[[===============================================================================================
SSK_Gui
===============================================================================================]]--

--[[

Sample properties display for SSK. Used by the various 'adjust/create' dialogs...
.

]]

--=================================================================================================

class 'SSK_Gui_SampleProps'

---------------------------------------------------------------------------------------------------
-- @param args {...}
--  xsample (renoise.Sample or xSample)
--  mapping_visible (boolean)

function SSK_Gui_SampleProps:__init(...)

  local args = cLib.unpack_args(...)  
  assert(type(args.vb)=="ViewBuilder")

  -- provide defaults -----------------

  args.mapping_visible = cReflection.as_boolean(args.mapping_visible) or false

  -- assign properties ----------------

  -- renoise.ViewBuilder
  self.vb = args.vb
  -- xSample 
  self.xsample = property(self.get_xsample,self.set_xsample)
  -- toggle visibility of sample mapping
  self.mapping_visible = property(self.get_mapping_visible,self.set_mapping_visible)
  self.mapping_visible_observable = renoise.Document.ObservableBoolean(args.mapping_visible)
  -- (the following are set via xsample property)
  self.bit_depth = property(self.get_bit_depth,self.set_bit_depth)
  self.sample_rate = property(self.get_sample_rate,self.set_sample_rate)
  self.num_channels = property(self.get_num_channels,self.set_num_channels)
  self.note_min = property(self.get_note_min,self.set_note_min)
  self.note_max = property(self.get_note_max,self.set_note_max)
  self.vel_min = property(self.get_vel_min,self.set_vel_min)
  self.vel_max = property(self.get_vel_max,self.set_vel_max)
  self.num_frames = property(self.get_num_frames,self.set_num_frames)
  self._num_frames = 0 -- floating point 

  -- derived from #num_frames
  self.note = property(self.get_note) 
  self.hz = property(self.get_hz) 
  
  -- renoise.View
  self.view = nil
  -- boolean
  self.suppress_updates = false

  -- initialize -----------------------

  self:build()

  self.xsample = type(args.xsample)=="xSample" and args.xsample or xSample(args.xsample)


end

---------------------------------------------------------------------------------------------------
-- Getters & Setters 
---------------------------------------------------------------------------------------------------

function SSK_Gui_SampleProps:get_mapping_visible()
  return self.mapping_visible_observable.value
end

function SSK_Gui_SampleProps:set_mapping_visible(val)
  self.mapping_visible_observable.value = val
end

---------------------------------------------------------------------------------------------------
-- retrun a 'virtual' sample object
-- return xSample

function SSK_Gui_SampleProps:get_xsample()

  local mapping = xSampleMapping{
    note_range = {self.note_min,self.note_max},
    velocity_range = {self.vel_min,self.vel_max},
  }

  if xSampleMapping.has_full_range(mapping) then
    mapping.base_note = xSampleMapping.DEFAULT_BASE_NOTE
  else
    mapping.base_note = self.note_min
  end

  return xSample{
    sample_buffer = xSampleBuffer{
      number_of_frames = math.floor(self.num_frames),
      number_of_channels = self.num_channels,
      bit_depth = self.bit_depth,
      sample_rate = self.sample_rate,
    },
    sample_mapping = mapping,
  }
end

---------------------------------------------------------------------------------------------------
-- NB: setting this property will configure several other properties 
-- @param val (renoise.Sample or xSample)

function SSK_Gui_SampleProps:set_xsample(val)
  TRACE("SSK_Gui_SampleProps:set_xsample(val)",val)
  self._xsample = val
  -- buffer
  self.bit_depth = val.sample_buffer.bit_depth
  self.sample_rate = val.sample_buffer.sample_rate
  self.num_channels = val.sample_buffer.number_of_channels
  self.num_frames = val.sample_buffer.number_of_frames
  -- mapping
  self.note_min = val.sample_mapping.note_range[1]
  self.note_max = val.sample_mapping.note_range[2]
  self.vel_min = val.sample_mapping.velocity_range[1]
  self.vel_max = val.sample_mapping.velocity_range[2]
end

---------------------------------------------------------------------------------------------------

function SSK_Gui_SampleProps:get_bit_depth()
  local ctrl = self.vb.views.ssk_bit_depth
  return xSampleBuffer.BIT_DEPTH[ctrl.value+1]
end

function SSK_Gui_SampleProps:set_bit_depth(val)
  local ctrl = self.vb.views.ssk_bit_depth
  local idx = table.find(xSampleBuffer.BIT_DEPTH,val)
  if (idx) then
    ctrl.value = idx-1
  end
end

---------------------------------------------------------------------------------------------------

function SSK_Gui_SampleProps:get_sample_rate()
  local ctrl = self.vb.views.ssk_sample_rate
  return xSampleBuffer.SAMPLE_RATE[ctrl.value]
end

function SSK_Gui_SampleProps:set_sample_rate(val)
  print("SSK_Gui_SampleProps:set_sample_rate(val)",val)
  local ctrl = self.vb.views.ssk_sample_rate
  local idx = table.find(xSampleBuffer.SAMPLE_RATE,val)
  ctrl.value = idx

end

---------------------------------------------------------------------------------------------------

function SSK_Gui_SampleProps:get_num_frames()
  return self._num_frames
end

function SSK_Gui_SampleProps:set_num_frames(val)
  print("SSK_Gui_SampleProps:set_num_frames(val)",val)
  assert(type(val)=="number")
  self._num_frames = val
  self.suppress_updates = true
  local srate = self.sample_rate 
  self.vb.views.ssk_length_as_frames.value = cLib.clamp_value(val,1,cLib.HUGE_INT)
  self.vb.views.ssk_length_as_note.value = 
    cLib.clamp_value(cConvert.frames_to_note(val,srate),
    xSampleMapping.MIN_NOTE,xSampleMapping.MAX_NOTE)
  self.vb.views.ssk_length_as_hz.value = cConvert.frames_to_hz(val,srate)
  self.suppress_updates = false

end

---------------------------------------------------------------------------------------------------

function SSK_Gui_SampleProps:get_num_channels()
  return self.vb.views.ssk_channels.value
end

function SSK_Gui_SampleProps:set_num_channels(val)
  self.vb.views.ssk_channels.value = val
end

---------------------------------------------------------------------------------------------------

function SSK_Gui_SampleProps:get_note_min()
  return self.vb.views.ssk_note_min.value
end

function SSK_Gui_SampleProps:set_note_min(val)
  self.vb.views.ssk_note_min.value = val
end

---------------------------------------------------------------------------------------------------

function SSK_Gui_SampleProps:get_note_max()
  return self.vb.views.ssk_note_max.value
end

function SSK_Gui_SampleProps:set_note_max(val)
  self.vb.views.ssk_note_max.value = val
end

---------------------------------------------------------------------------------------------------

function SSK_Gui_SampleProps:get_vel_min()
  return self.vb.views.ssk_vel_min.value
end

function SSK_Gui_SampleProps:set_vel_min(val)
  self.vb.views.ssk_vel_min.value = val
end

---------------------------------------------------------------------------------------------------

function SSK_Gui_SampleProps:get_vel_max()
  return self.vb.views.ssk_vel_max.value
end

function SSK_Gui_SampleProps:set_vel_max(val)
  self.vb.views.ssk_vel_max.value = val
end

---------------------------------------------------------------------------------------------------

function SSK_Gui_SampleProps:get_note()
  return self.vb.views.ssk_length_as_note.value
end

---------------------------------------------------------------------------------------------------

function SSK_Gui_SampleProps:get_hz()
  return self.vb.views.ssk_length_as_hz.value
end


---------------------------------------------------------------------------------------------------
-- Class methods 
---------------------------------------------------------------------------------------------------

function SSK_Gui_SampleProps:build()

  local vb = self.vb 
  local dlg_margin = 8
  local grid_w = 80

  self.view = vb:column{
    margin = dlg_margin,
    vb:row{
      vb:column{
        vb:text{
          text = "#Samples:",
        },
        vb:valuebox{
          id = "ssk_length_as_frames",
          width = grid_w,
          value = 1,
          min = -cLib.HUGE_INT,
          max = cLib.HUGE_INT,
          notifier = function(val)
            if not self.suppress_updates then          
              self.num_frames = val
            end
          end
        }
      },
      vb:column{
        vb:text{
          text = "Note:",
        },
        vb:valuebox{
          id = "ssk_length_as_note",
          width = grid_w,
          min = 0,
          max = cLib.HUGE_INT,                    
          --min = xSampleMapping.MIN_NOTE,
          --max = xSampleMapping.MAX_NOTE,                      
          tostring = function(val)
            return xNoteColumn.note_value_to_string(val)
          end,
          tonumber = function(val)
            return xNoteColumn.note_string_to_value(val)
          end,       
          notifier = function(val)   
            if not self.suppress_updates then
              local _,frames = cConvert.note_to_frames(val,self.sample_rate)
              self.num_frames = frames 
            end
          end
        }
      },
      vb:column{
        vb:text{
          text = "Hz:",
        },
        vb:valuebox{
          id = "ssk_length_as_hz",
          width = grid_w,
          min = 0,
          max = cLib.HUGE_INT,
          tostring = function(x)
            return tostring(cLib.round_with_precision(x,3))
          end,
          tonumber = function(x)
            return cReflection.evaluate_string(x)
          end,
          -- tostring = function(val)
          --   return tostring(val)
          -- end,
          -- tonumber = function(val)
          --   return tonumber(val)*100
          -- end,
          notifier = function(val)
            if not self.suppress_updates then      
              local _,frames = cConvert.hz_to_frames(val,self.sample_rate)      
              self.num_frames = frames
            end
          end
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
          items = SSK_Gui_SampleProps.get_sample_rate_items(),
          notifier = function(idx)
            -- when possible, change #frames based on the current hertz 
            print("*** self.note",self.note,idx)
            if self.note then
              local srate = xSampleBuffer.SAMPLE_RATE[idx]
              print("*** srate",srate)
              local _,frames = cConvert.note_to_frames(self.note,srate)
              self.num_frames = frames
            end

          end
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
    vb:row{
      vb:column{
        vb:text{
          text = "Mapping:",
          width = grid_w,
        },
      },
      vb:column{
        vb:text{
          text = "Note-range:",
        },
        vb:valuebox{
          id = "ssk_note_min",
          width = grid_w,
          min = xSampleMapping.MIN_VEL,
          max = xSampleMapping.MAX_VEL,                      
          tostring = function(val)
            return xNoteColumn.note_value_to_string(val)
          end,
          tonumber = function(val)
            return xNoteColumn.note_string_to_value(val)
          end,          
        },
        vb:valuebox{
          id = "ssk_note_max",
          width = grid_w,
          min = xSampleMapping.MIN_VEL,
          max = xSampleMapping.MAX_VEL,                      
          tostring = function(val)
            return xNoteColumn.note_value_to_string(val)
          end,
          tonumber = function(val)
            return xNoteColumn.note_string_to_value(val)
          end,          
        }
      },
      vb:column{
        vb:text{
          text = "Vel-range:",
        },
        vb:valuebox{
          id = "ssk_vel_min",
          width = grid_w,
          min = xSampleMapping.MIN_VEL,
          max = xSampleMapping.MAX_VEL,                        
          tostring = function(val)
            return ("%02X"):format(val)
          end,
          tonumber = function(val)
            return tonumber(val)
          end,                    
        },
        vb:valuebox{
          id = "ssk_vel_max",
          width = grid_w,
          min = xSampleMapping.MIN_VEL,
          max = xSampleMapping.MAX_VEL,                        
          tostring = function(val)
            return ("%02X"):format(val)
          end,
          tonumber = function(val)
            return tonumber(val)
          end,                  
        }
      },
    },
  }

end

---------------------------------------------------------------------------------------------------
-- Static functions 
---------------------------------------------------------------------------------------------------

function SSK_Gui_SampleProps.get_sample_rate_items()
  local t = {}
  for k,v in ipairs(xSampleBuffer.SAMPLE_RATE) do
    table.insert(t,("%d Hz"):format(v))
  end
  return t
end

