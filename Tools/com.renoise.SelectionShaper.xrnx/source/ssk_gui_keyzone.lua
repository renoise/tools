--[[===============================================================================================
SSK_Gui
===============================================================================================]]--

--[[

Simple multisample layout widget for SSK 
.

]]

--=================================================================================================

class 'SSK_Gui_Keyzone' (vControl)

SSK_Gui_Keyzone.PALETTE = {
  COLOR_BG = {0x00,0x00,0x00},      -- unassigned space 
  COLOR_EMPTY = {0x1b,0x44,0x30},   -- sample without data
  COLOR_CONTENT = {0x25,0x87,0x56}, -- sample with data 
}

---------------------------------------------------------------------------------------------------

function SSK_Gui_Keyzone:__init(...)

  local args = cLib.unpack_args(...)

  self.note_steps = property(self.get_note_steps,self.set_note_steps) 
  self.note_steps_observable = renoise.Document.ObservableNumber(args.note_steps or SSK_Prefs.DEFAULT_NOTE_STEPS)
  -- 
  self.note_min = property(self.get_note_min,self.set_note_min) 
  self.note_min_observable = renoise.Document.ObservableNumber(args.note_min or xSampleMapping.MIN_NOTE)
  --
  self.note_max = property(self.get_note_max,self.set_note_max) 
  self.note_max_observable = renoise.Document.ObservableNumber(args.note_max or xSampleMapping.MAX_NOTE)
  --
  self.extend_notes = property(self.get_extend_notes,self.set_extend_notes)
  self.extend_notes_observable = renoise.Document.ObservableBoolean(cReflection.as_boolean(args.extend_notes) or SSK_Prefs.DEFAULT_EXTEND_NOTES)

  self.vel_steps = property(self.get_vel_steps,self.set_vel_steps) 
  self.vel_steps_observable = renoise.Document.ObservableNumber(args.vel_steps or xKeyZone.DEFAULT_VEL_STEPS)
  --
  self.vel_min = property(self.get_vel_min,self.set_vel_min) 
  self.vel_min_observable = renoise.Document.ObservableNumber(args.vel_min or xSampleMapping.MIN_VELOCITY)
  --
  self.vel_max = property(self.get_vel_max,self.set_vel_max) 
  self.vel_max_observable = renoise.Document.ObservableNumber(args.vel_max or xSampleMapping.MAX_VELOCITY)

  self.color_bg = property(self.get_color_bg,self.set_color_bg) 
  self._color_bg = args.color_bg or SSK_Gui_Keyzone.PALETTE.COLOR_BG

  self.color_empty = property(self.get_color_empty,self.set_color_empty) 
  self._color_empty = args.color_empty or SSK_Gui_Keyzone.PALETTE.COLOR_EMPTY

  self.color_content = property(self.get_color_content,self.set_color_content) 
  self._color_content = args.color_content or SSK_Gui_Keyzone.PALETTE.COLOR_CONTENT

  -- internal --


  -- table<vSampleMapping>
  self._mappings = {}
  -- table<vButtonStrip>
  self._rows = {}
  -- table {...} 
  --  weight
  --  velocity_range
  --  void (boolean), when only there to fill space 
  self._row_data = {}

  --== initialize ==--

  vControl.__init(self,...)
  self:build()

end

---------------------------------------------------------------------------------------------------
-- Getters & Setters 
---------------------------------------------------------------------------------------------------

function SSK_Gui_Keyzone:get_note_steps()
  return self.note_steps_observable.value
end

function SSK_Gui_Keyzone:set_note_steps(val)
  TRACE("SSK_Gui_Keyzone:set_note_steps",val)
  self.note_steps_observable.value = val
  self:request_update()
end

---------------------------------------------------------------------------------------------------

function SSK_Gui_Keyzone:get_note_min()
  return self.note_min_observable.value
end

function SSK_Gui_Keyzone:set_note_min(val)
  TRACE("SSK_Gui_Keyzone:set_note_min",val)
  self.note_min_observable.value = val
  self:request_update()
end

---------------------------------------------------------------------------------------------------

function SSK_Gui_Keyzone:get_note_max()
  return self.note_max_observable.value
end

function SSK_Gui_Keyzone:set_note_max(val)
  self.note_max_observable.value = val
  self:request_update()
end

---------------------------------------------------------------------------------------------------

function SSK_Gui_Keyzone:get_extend_notes()
  return self.extend_notes_observable.value
end

function SSK_Gui_Keyzone:set_extend_notes(val)
  self.extend_notes_observable.value = val
  self:request_update()
end

---------------------------------------------------------------------------------------------------

function SSK_Gui_Keyzone:get_vel_steps()
  return self.vel_steps_observable.value
end

function SSK_Gui_Keyzone:set_vel_steps(val)
  self.vel_steps_observable.value = val
  self:request_update()
end

---------------------------------------------------------------------------------------------------

function SSK_Gui_Keyzone:get_vel_min()
  return self.vel_min_observable.value
end

function SSK_Gui_Keyzone:set_vel_min(val)
  self.vel_min_observable.value = val
  self:request_update()
end

---------------------------------------------------------------------------------------------------

function SSK_Gui_Keyzone:get_vel_max()
  return self.vel_max_observable.value
end

function SSK_Gui_Keyzone:set_vel_max(val)
  self.vel_max_observable.value = val
  self:request_update()
end

---------------------------------------------------------------------------------------------------

function SSK_Gui_Keyzone:get_vel_max()
  return self.vel_max_observable.value
end

function SSK_Gui_Keyzone:set_vel_max(val)
  self.vel_max_observable.value = val
  self:request_update()
end

---------------------------------------------------------------------------------------------------

function SSK_Gui_Keyzone:get_color_bg()
  return self._color_bg
end

function SSK_Gui_Keyzone:set_color_bg(val)
  self._color_bg = val
  self:request_update()
end

---------------------------------------------------------------------------------------------------

function SSK_Gui_Keyzone:get_color_empty()
  return self._color_empty
end

function SSK_Gui_Keyzone:set_color_empty(val)
  self._color_empty = val
  self:request_update()
end

---------------------------------------------------------------------------------------------------

function SSK_Gui_Keyzone:get_color_content()
  return self._color_content
end

function SSK_Gui_Keyzone:set_color_content(val)
  self._color_content = val
  self:request_update()
end

---------------------------------------------------------------------------------------------------
-- Class methods
---------------------------------------------------------------------------------------------------

function SSK_Gui_Keyzone:build()

  local vb = self.vb
  local spacing = vLib.NULL_SPACING-1
  -- first time: create view 
  if not self.view then
    self.view = vb:column{
      spacing = spacing,
      id = self.id,
    }
  end

  self:_clear()

  -- compute layout
  self._mappings = xKeyZone.create_multisample_layout(xKeyZoneLayout{
    note_steps = self.note_steps,
    note_min = self.note_min,
    note_max = self.note_max,
    vel_steps = self.vel_steps,
    vel_min = self.vel_min,
    vel_max = self.vel_max
  })

  -- compute "rows" 
  self:_compute_velocities()
  local heights = {}
  for k,v in ipairs(self._row_data) do 
    table.insert(heights,v.weight)
  end
  heights = vLib.distribute_sizes(heights,self.height,spacing)

  -- create strips 
  for k,v in ipairs(self._row_data) do 
    local vstrip = vButtonStrip{
      vb = vb,
      width = self.width,
      pressed = function(idx,_strip_)
        print(">>> pressed: ",k,idx,rprint(v),rprint(_strip_.items[idx]))
      end,
      items = self:_compute_notes(v.velocity_range,v.void),
    }
    -- apply height afterwards, to retain dimensions
    vstrip.height = heights[k]
    table.insert(self._rows,vstrip)
    self.view:add_child(vstrip.view)
  end 

end

---------------------------------------------------------------------------------------------------
-- remove all previously created views  

function SSK_Gui_Keyzone:_clear()
  for k,v in ipairs(self._rows) do 
    self.view:remove_child(v.view)
  end 
  self._rows = {};

end

---------------------------------------------------------------------------------------------------

function SSK_Gui_Keyzone:update()
  TRACE("SSK_Gui_Keyzone:update()")

  self:build()

end

---------------------------------------------------------------------------------------------------
-- figure out how tall each row is 
-- note: in reverse - items are stored bottom-up, but rendering needs them top-down 

function SSK_Gui_Keyzone:_compute_velocities()

  self._row_data = {}

  -- above
  if (self.vel_max < xSampleMapping.MAX_VELOCITY) then 
    table.insert(self._row_data,{
      void = true,
      weight = xSampleMapping.MAX_VELOCITY-self.vel_max,
      velocity_range = {self.vel_max,xSampleMapping.MAX_VELOCITY},
    })
  end 

  -- steps
  local velocities = xKeyZone.compute_multisample_velocities(
    self.vel_steps,self.vel_min,self.vel_max)
  for k,v in ripairs(velocities) do 
    table.insert(self._row_data,{
      void = false,
      weight = v[2]-v[1],
      velocity_range = v,
    })
  end

  -- below 
  if (self.vel_min > xSampleMapping.MIN_VELOCITY) then 
    table.insert(self._row_data,{
      void = true,
      weight = self.vel_min,
      velocity_range = {self.vel_min,xSampleMapping.MIN_VELOCITY}
    })
  end 

end

---------------------------------------------------------------------------------------------------
-- populate each strip with members 

function SSK_Gui_Keyzone:_compute_notes(velocity_range,void)
  TRACE("SSK_Gui_Keyzone:_compute_notes(velocity_range,void)",velocity_range,void)

  local rslt = {}

  local notes = xKeyZone.compute_multisample_notes(
    self.note_steps,self.note_min,self.note_max,self.extend_notes)
  for k,v in ipairs(notes) do 
    table.insert(rslt,vButtonStripMember{
      weight = v[2]-v[1],
      color = not void and self.color_content or self.color_empty,
    })
  end

  return rslt

end