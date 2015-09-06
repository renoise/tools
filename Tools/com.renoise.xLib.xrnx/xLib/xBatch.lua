--[[============================================================================
xBatch
============================================================================]]--
--[[



]]

class 'xBatch'

xBatch.sample_compensate_volume = true
xBatch.sample_normalize_group = true

xBatch.ADJUST_COL1_W = 70
xBatch.ADJUST_COL2_W = 100
xBatch.PROPS_COL1_W = 120
xBatch.PROPS_COL2_W = 60

--------------------------------------------------------------------------------

function xBatch:__init()

  -- viewbuilder stuff
  self.vb = renoise.ViewBuilder()
  self.dialog = nil
  self.dialog_content = nil

  -- (function) define an external method which will supply
  -- the neccesary data before we actually run our batch
  self.on_before_task = nil

end

--------------------------------------------------------------------------------

function xBatch:build()

  local vb = self.vb

  local content = 
  vb:column{
    margin = 6,
    vb:column{
      margin = 6,
      style = "group",
      vb:text{
        text = "Adjust Sample",
        font = "bold",
      },
      vb:row{
        vb:checkbox{
          value = false
        },
        vb:text{
          text = "Set bit depth to",
          width = xBatch.ADJUST_COL1_W,
        },
        vb:popup{
          items = {
            "8 bit",
            "16 bit", 
            "24 bit", 
            "32 bit"
          },
          width = xBatch.ADJUST_COL2_W,
        },
      },
      vb:row{
        vb:checkbox{
          value = false
        },
        vb:text{
          text = "Adjust channels",
          width = xBatch.ADJUST_COL1_W,
        },
        vb:popup{
          items = {"Mono (mix)","Mono (keep L)", "Mono (keep R)", "Stereo"},
          width = xBatch.ADJUST_COL2_W,
        },
      },
      vb:row{
        vb:checkbox{
          value = false
        },
        vb:text{
          text = "Swap channels (when stereo)",
        },
      },
      vb:row{
        vb:checkbox{
          value = false
        },
        vb:text{
          text = "Normalize",
        },
        vb:column{
          vb:row{
            vb:checkbox{
              value = xBatch.sample_normalize_group
            },
            vb:text{
              text = "Distributed peak",
            },
          },
          vb:row{
            vb:checkbox{
              value = xBatch.sample_compensate_volume
            },
            vb:text{
              text = "Compensate volume",
            },
          }
        }
      },

    },
    vb:space{
      height = 6,
    },
    vb:column{
      margin = 6,
      style = "group",
      id = "sample_props",
      vb:text{
        text = "Sample Properties",
        font = "bold",
      },
      -- insert row here...
    },
    vb:space{
      height = 6,
    },
    vb:button{
      text = "Run batch on selected items",
      width = "100%",
      height = 26,
      notifier = function()
        self:prepare_task()
      end
    },
  }

  -- HMM, what if we have no samples? 
  local sample_props_elm = vb.views.sample_props
  local sample = rns.selected_sample
  if not sample then
      sample_props_elm:add_child(vb:row{
        vb:text{
          text = "No samples in current instrument"
        },
      })
  else
    local sample_props = xLib.get_object_properties(sample)
    --print("sample_props",rprint(sample_props))
    for k,v in pairs(sample_props) do
      -- only display some types...
      if (type(v) == "boolean") then
        sample_props_elm:add_child(vb:row{
          vb:text{
            text = k,
            width = xBatch.PROPS_COL1_W,
          },
          vb:checkbox{
            value = v,
            --width = xBatch.PROPS_COL2_W,
          }
        })
      elseif (type(v) == "number") then
        sample_props_elm:add_child(vb:row{
          vb:text{
            text = k,
            width = xBatch.PROPS_COL1_W,
          },
          vb:valuebox{
            value = v,
            width = xBatch.PROPS_COL2_W,
            min = -100000,
            max = 100000, -- because math.huge does not work?
          }
        })
      end

    end
    return content
  end

end

--------------------------------------------------------------------------------

function xBatch:show()
  TRACE("xBatch:show()")

  if not self.dialog or not self.dialog.visible then
    if not self.dialog_content then
      self.dialog_content = self:build()
    end
    local function keyhandler(dialog, key)
    end
    self.dialog = renoise.app():show_custom_dialog("xBatch", 
      self.dialog_content, keyhandler)
  else
    self.dialog:show()
  end

end

--------------------------------------------------------------------------------

function xBatch:prepare_task()
  TRACE("xBatch:prepare_task()")

  if self.on_before_task then
    self.on_before_task()
  end

end

--------------------------------------------------------------------------------
-- @param instr (renoise.Instrument)
-- @param t (table>xItemSample)
-- @param compensate (bool) compensate for increased volume
-- @param fn_progress (function)
-- @param fn_done (function)

function xBatch.normalize(instr,t,compensate,fn_progress,fn_done)
  TRACE("xBatch.normalize(instr,t,compensate,fn_progress,fn_done)",instr,t,compensate,fn_progress,fn_done)

  local global_peak = 0
  for k,v in ipairs(t) do
    if v.checked then
      --print("v.peak_level",v.peak_level,type(v),rprint(v))
      global_peak = math.max(global_peak,v.peak_level)
    end
  end
  --print("global_peak",global_peak)

  for k,v in ipairs(t) do

    if v.checked then
      local sample = instr.samples[v.index]
      local channel_action = xLib.SAMPLE_CONVERT.KEEP
      sample = xLib.convert_sample(instr,v.index,v.bit_depth,channel_action,nil,global_peak)
      if compensate then
        local factor = 1/global_peak
        local existing = math.db2lin(sample.volume)
        sample.volume = existing/factor
      end
      --fn_progress()
    end

  end
  --fn_done()

end


