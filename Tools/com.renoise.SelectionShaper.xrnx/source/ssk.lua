--[[===============================================================================================
SSK
===============================================================================================]]--

--[[

Main class for the SSK tool 

]]

--=================================================================================================

class 'SSK'

-- utility table for channel selecting
SSK.CH_UTIL = {
  {0,0,{{1,1},1}}, -- mono,selected_channel is 3
  {{{1,2},1},{{2,1},1},{{1,2},2}}, -- stereo
}

function SSK:__init(prefs)

  assert(type(prefs)=="SSK_Prefs",type(prefs))

  --- number, relates to persistent storage/configs
  self.doc_version = 1

  --- Renoise.Instrument, currently targeted (can be nil)
  self.instrument = nil 
  self.instrument_index = nil 
  self.instrument_name_observable = renoise.Document.ObservableString("")
  --- Renoise.Sample, currently targeted (can be nil)
  self.sample = nil
  --- selected sample index (0 = none)
  self.sample_index = property(self.get_sample_index)
  self.sample_index_observable = renoise.Document.ObservableNumber(0)
  self.sample_name_observable = renoise.Document.ObservableString("")
  self.sample_loop_changed_observable = renoise.Document.ObservableBang()
  self.sample_tuning_changed_observable = renoise.Document.ObservableBang()
  self.samples_changed_observable = renoise.Document.ObservableBang()
  self.buffer_changed_observable = renoise.Document.ObservableBang()

  --- fired when the range has changed
  self.selection_changed_observable = renoise.Document.ObservableBang()
  --- fired when bpm or lpb has changed
  self.tempo_changed_observable = renoise.Document.ObservableBang()

  --- function, expression of the memorized buffer
  self.clip_wv_fn = nil
  self.memorized_changed_observable = renoise.Document.ObservableBang()

  --- SSK_Prefs
  self.prefs = prefs
  --- SSK_Selection
  self.selection = SSK_Selection(self)
  --- SSK_Generator
  self.generator = SSK_Generator(self)
  --- SSK_Modify
  self.modify = SSK_Modify(self)
  --- SSK_Gui
  self.ui = SSK_Gui{
    owner = self,
    waiting_to_show_dialog = true,
  }

  --- SSK_Dialog_Create
  self.create_dialog = SSK_Dialog_Create{
    dialog_title = "Create a new sample",
  }

  -- == Observables ==

  self.prefs.sync_with_renoise:add_notifier(function()
    if self.prefs.sync_with_renoise.value then 
      self:selection_range_notifier()
    end
  end)

  renoise.tool().app_new_document_observable:add_notifier(function()
    self:attach_to_song(true)
  end)

  --self.samples_changed_observable:add_notifier(function()
  --self:attach_to_sample()
  --end)

  -- required for detecting when buffer is created in sample
  self.buffer_changed_observable:add_notifier(function()
    self:attach_to_sample()
  end)


  -- == Initialize ==

  self:attach_to_song()

end

---------------------------------------------------------------------------------------------------
-- Getters & setters
---------------------------------------------------------------------------------------------------

function SSK:get_sample_index()
  return self.sample_index_observable.value
end

---------------------------------------------------------------------------------------------------
-- Class methods 
---------------------------------------------------------------------------------------------------
-- delete selected sample 

function SSK:delete_sample()
  TRACE("SSK:delete_sample()")
  if self.instrument then 
    local sample = self.instrument.samples[self.sample_index]
    if sample then 
      self.instrument:delete_sample_at(self.sample_index)
    end 
  end
end

---------------------------------------------------------------------------------------------------
-- show the 'insert/create' dialog ...

function SSK:insert_sample()
  TRACE("SSK:insert_sample()")
  self.create_dialog:show()
end

---------------------------------------------------------------------------------------------------
-- Generate sample data from a function

function SSK:make_wave(fn,mod_fn)
  TRACE("SSK:make_wave(fn,mod_fn)",fn,mod_fn)

  local buffer = self:get_sample_buffer() 
  if not buffer then 
    return 
  end 

  local bop = xSampleBufferOperation{
    instrument_index = self.instrument_index,
    sample_index = self.sample_index,
    restore_selection = true,
    restore_loop = true,    
    restore_zoom = true,    
    operations = {
      xSampleBuffer.create_wave_fn{
        buffer=buffer,
        fn=fn,
        mod_fn=mod_fn,
      },
    },
    on_complete = function(new_buffer)
      TRACE("[make_wave] process_done - new_buffer",new_buffer)
      -- attempt to load config 
      if self.instrument then 
        SSK_Config.save_to_instrument(self)
      end

    end 
  }
  bop:run()

end

---------------------------------------------------------------------------------------------------
-- Buffer operations
---------------------------------------------------------------------------------------------------
-- Copy to new sample
-- Takes the memorized buffer and applies it to a new sample in the current instrument 

function SSK:copy_to_new()
  TRACE("SSK:copy_to_new()")
  
  local buffer = self:get_sample_buffer() 
  if not buffer then 
    return
  end 

  local init_range = xSampleBuffer.get_selection_range(buffer)
  local init_selected_channel = buffer.selected_channel

  local ch_tbl = SSK.CH_UTIL[buffer.number_of_channels][init_selected_channel]

  local do_process = function(new_buffer)
    local offset = buffer.selection_start-1
    for ch = 1,ch_tbl[2] do
      for fr = 1,init_range do
        new_buffer:set_sample_data(ch,fr,buffer:sample_data(ch_tbl[1][ch], fr + offset))
      end
    end
  end

  local bop = xSampleBufferOperation{
    instrument_index = self.instrument_index,
    sample_index = self.sample_index,
    create_sample = true,
    force_frames = init_range,
    operations = {
      do_process
    },
    on_complete = function(_bop_)
      -- rename and select sample 
      _bop_.sample.name = "#".._bop_.sample.name
      rns.selected_sample_index = _bop_.new_sample_index
    end
  }
  bop:run()

end

---------------------------------------------------------------------------------------------------
-- memorize the buffer (copy)

function SSK:buffer_memorize()
  local buffer = self:get_sample_buffer() 
  if buffer then 
    self.clip_wv_fn = cWaveform.table2fn(xSampleBuffer.wave2tbl{buffer=buffer})
    self.memorized_changed_observable:bang()
  end
end 

---------------------------------------------------------------------------------------------------
-- fit the memorized buffer within the selected region (paste)

function SSK:buffer_redraw()
  TRACE("SSK:buffer_mixdraw()")
  if self.clip_wv_fn then
    self:make_wave(self.clip_wv_fn)
  end
end 

---------------------------------------------------------------------------------------------------
-- mix the memorized buffer with the selected region 

function SSK:buffer_mixdraw()
  TRACE("SSK:buffer_mixdraw()")
  local buffer = self:get_sample_buffer()
  if self.clip_wv_fn and buffer then
    local fn = xSampleBuffer.copy_fn_fn(buffer)
    local mix = cWaveform.mix_fn_fn(fn,self.clip_wv_fn,0.5)
    --print("fn,mix,clip_wv_fn",fn,mix,self.clip_wv_fn)
    self:make_wave(mix)
  end
end 

---------------------------------------------------------------------------------------------------
-- swap the memorized buffer with the selected region 

function SSK:buffer_swap()
  TRACE("SSK:buffer_swap()")
  local buffer = self:get_sample_buffer()
  if self.clip_wv_fn and buffer then
    
    -- TODO 
    -- first step: needs to memorize the clipped range 
    
    -- refuse if clipped range overlaps current selection 

    --[[
    local ch_tbl = SSK.CH_UTIL[buffer.number_of_channels][init_selected_channel]
    local do_process = function(new_buffer)
      local offset = buffer.selection_start-1
      for ch = 1,ch_tbl[2] do
        -- clipped range? insert selected frames... 
        -- selected frames? insert clipped data 
        -- pass through before 
        for fr = 1,init_range do
        end
      end
    end

    local bop = xSampleBufferOperation{
      instrument_index = self.instrument_index,
      sample_index = self.sample_index,
      --force_frames = range,
      restore_selection = true,
      operations = {
        do_process,
      },
      on_complete = function(_bop_)
        -- select the clipped range 
      end
    }
    bop:run()
    ]]
    
  end
end 

---------------------------------------------------------------------------------------------------

function SSK:sweep_ins()
  TRACE("SSK:sweep_ins()")

  local buffer = self:get_sample_buffer()           
  if not buffer then 
    return 
  end

  local bop = xSampleBufferOperation{
    instrument_index = self.instrument_index,
    sample_index = self.sample_index,
    restore_selection = true,
    restore_loop = true,
    restore_zoom = true,
    operations = {
      xSampleBuffer.sweep_ins{
        buffer=buffer
      },
    },
    on_complete = function()
      TRACE("[sweep_ins] process_done")
    end    
  }

  bop:run()

end

---------------------------------------------------------------------------------------------------

function SSK:sync_del()
  TRACE("SSK:sync_del()")

  local buffer = self:get_sample_buffer()           
  if not buffer then 
    return 
  end

  local bop = xSampleBufferOperation{
    instrument_index = self.instrument_index,
    sample_index = self.sample_index,
    restore_selection = true,
    restore_loop = true,        
    restore_zoom = true,        
    operations = {
      xSampleBuffer.sync_del{
        buffer=buffer
      },
    },
    on_complete = function()
      TRACE("[sync_del] process_done")
    end    
  }

  bop:run()

end

---------------------------------------------------------------------------------------------------

function SSK:trim()
  TRACE("SSK:trim(ratio)")

  local buffer = self:get_sample_buffer() 
  if not buffer then 
    return
  end 

  local range = xSampleBuffer.get_selection_range(buffer)

  local bop = xSampleBufferOperation{
    instrument_index = self.instrument_index,
    sample_index = self.sample_index,
    force_frames = range,
    operations = {
      xSampleBuffer.trim{
        buffer=buffer,
      },
    },
    on_complete = function(_bop_)
      -- select/loop everything 
      local sample = _bop_.sample
      xSample.set_loop_all(sample)
      xSampleBuffer.select_all(sample.sample_buffer)
    end
  }
  bop:run()

end

---------------------------------------------------------------------------------------------------
-- @return renoise.SampleBuffer or nil 

function SSK:get_sample_buffer() 
  if self.sample then
    return xSample.get_sample_buffer(self.sample)
  end
end 


---------------------------------------------------------------------------------------------------
-- Observables
---------------------------------------------------------------------------------------------------
-- invoked when instrument name has changed

function SSK:instrument_name_notifier()
  self.instrument_name_observable.value = self.instrument.name
end 

---------------------------------------------------------------------------------------------------
-- invoked as instrument samples are added or removed 

function SSK:instrument_samples_notifier()
  self.samples_changed_observable:bang()
end 

---------------------------------------------------------------------------------------------------
-- invoked when sample range is changed in waveform editor 

function SSK:selection_range_notifier()
  TRACE("SSK:sample_buffer.selection_end fired...")
  if (self.prefs.sync_with_renoise.value) then 
    self.selection:obtain_start_from_editor()
    self.selection:obtain_length_from_editor()
  end 
  self.selection_changed_observable:bang()
end

---------------------------------------------------------------------------------------------------
-- invoked when sample name has changed

function SSK:sample_name_notifier()
  --TRACE("sample.name_observable fired... ")
  self.sample_name_observable.value = self.sample.name
end 

---------------------------------------------------------------------------------------------------
-- invoked when sample loop_mode has changed

function SSK:sample_loop_changed_notifier()
  --TRACE("sample.sample_loop_changed_notifier fired... ")
  self.sample_loop_changed_observable:bang()
end 

---------------------------------------------------------------------------------------------------
-- invoked when sample buffer has changed

function SSK:sample_buffer_notifier()
  --TRACE("sample.name_observable fired... ")
  self.buffer_changed_observable:bang()  
end 

---------------------------------------------------------------------------------------------------
-- invoked when sample tuning has changed

function SSK:sample_tuning_notifier()
  TRACE("SSK:sample_tuning_notifier()")
  self.sample_tuning_changed_observable:bang()  
end 

---------------------------------------------------------------------------------------------------
-- @param new_song (boolean)

function SSK:attach_to_song(new_song)
  TRACE("SSK:attach_to_song(new_song)",new_song)

  local rns = renoise.song()

  if new_song then 
    -- immediately unset sample, instrument 
    self.instrument = nil 
    self.instrument_index = nil 
    self.sample = nil 
    self.sample_index_observable.value = 0
  end 

  rns.transport.bpm_observable:add_notifier(function()
    self.tempo_changed_observable:bang()
    self:selection_range_notifier()
  end)
  rns.transport.lpb_observable:add_notifier(function()
    self.tempo_changed_observable:bang()
    self:selection_range_notifier()
  end)

  rns.selected_instrument_observable:add_notifier(function()
    --TRACE("selected_instrument_observable fired...")
    self:attach_to_instrument()
  end)
  self:attach_to_instrument(new_song)

  rns.selected_sample_observable:add_notifier(function()
    --TRACE("selected_sample_observable fired...")
    self:attach_to_sample()
  end)
  self:attach_to_sample(new_song)

end 

---------------------------------------------------------------------------------------------------
-- @param new_song (boolean)

function SSK:attach_to_instrument(new_song)
  TRACE("SSK:attach_to_instrument(new_song)",new_song)

  local rns = renoise.song()
  if not new_song then 
    self:detach_from_instrument()
  end
  self.instrument = rns.selected_instrument  
  self.instrument_index = rns.selected_instrument_index
  if not self.instrument then 
    self.instrument_name_observable.value = ""
  else 

    local obs = self.instrument.name_observable
    if not obs:has_notifier(self,self.instrument_name_notifier) then     
      obs:add_notifier(self,self.instrument_name_notifier)
    end
    self:instrument_name_notifier()

    local obs = self.instrument.samples_observable
    if not obs:has_notifier(self,self.instrument_samples_notifier) then 
      obs:add_notifier(self,self.instrument_samples_notifier)
    end
    self:instrument_samples_notifier()
  end 

  -- attempt to load config 
  if self.instrument then 
    SSK_Config.load_from_instrument(self)
  end

end 

---------------------------------------------------------------------------------------------------

function SSK:detach_from_instrument()
  TRACE("SSK:detach_from_instrument()")

  if self.instrument then 
    local obs = self.instrument.name_observable
    if obs:has_notifier(self,self.instrument_name_notifier) then 
      obs:remove_notifier(self,self.instrument_name_notifier)
    end
    if obs:has_notifier(self,self.instrument_samples_notifier) then 
      obs:remove_notifier(self,self.instrument_samples_notifier)
    end
    self.instrument = nil
  end 

end 

---------------------------------------------------------------------------------------------------
-- @param new_song (boolean)

function SSK:attach_to_sample(new_song)
  TRACE("SSK:attach_to_sample(new_song)",new_song)

  local rns = renoise.song()
  if not new_song then 
    self:detach_from_sample()
  end
  self.sample = rns.selected_sample 
  if not self.sample then 
    -- not available
    self.sample_index_observable.value = 0
    self.sample_name_observable.value = ""
  else 
    self.sample_index_observable.value = rns.selected_sample_index

    -- sample  
    local obs = self.sample.name_observable
    if not obs:has_notifier(self,self.sample_name_notifier) then
      obs:add_notifier(self,self.sample_name_notifier)
    end
    self:sample_name_notifier()
    local obs = self.sample.loop_mode_observable
    if not obs:has_notifier(self,self.sample_loop_changed_notifier) then 
      obs:add_notifier(self,self.sample_loop_changed_notifier)
    end 
    local obs = self.sample.loop_start_observable
    if not obs:has_notifier(self,self.sample_loop_changed_notifier) then 
      obs:add_notifier(self,self.sample_loop_changed_notifier)
    end 
    local obs = self.sample.loop_end_observable
    if not obs:has_notifier(self,self.sample_loop_changed_notifier) then 
      obs:add_notifier(self,self.sample_loop_changed_notifier)
    end 
    self:sample_loop_changed_notifier()
    local obs = self.sample.sample_buffer_observable
    if not obs:has_notifier(self,self.sample_buffer_notifier) then
      obs:add_notifier(self,self.sample_buffer_notifier)
    end
    local obs = self.sample.fine_tune_observable
    if not obs:has_notifier(self,self.sample_tuning_notifier) then
      obs:add_notifier(self,self.sample_tuning_notifier)
    end
    local obs = self.sample.transpose_observable
    if not obs:has_notifier(self,self.sample_tuning_notifier) then
      obs:add_notifier(self,self.sample_tuning_notifier)
    end
    -- sample-mapping 
    local obs = self.sample.sample_mapping.base_note_observable
    if not obs:has_notifier(self,self.sample_tuning_notifier) then
      obs:add_notifier(self,self.sample_tuning_notifier)
    end

    -- sample-buffer
    if self:get_sample_buffer() then 
      local obs = self.sample.sample_buffer.selection_range_observable   
      if not obs:has_notifier(self,self.selection_range_notifier) then
        obs:add_notifier(self,self.selection_range_notifier)
      end
      self:selection_range_notifier()
    end 

  end 

end 

---------------------------------------------------------------------------------------------------

function SSK:detach_from_sample()
  TRACE("SSK:detach_from_sample()")

  if self.sample then 

    local obs = self.sample.name_observable
    if obs:has_notifier(self,self.sample_name_notifier) then
      obs:remove_notifier(self,self.sample_name_notifier)
    end    
    local obs = self.sample.loop_mode_observable
    if obs:has_notifier(self,self.sample_loop_changed_notifier) then
      obs:remove_notifier(self,self.sample_loop_changed_notifier)
    end    
    local obs = self.sample.loop_start_observable
    if obs:has_notifier(self,self.sample_loop_changed_notifier) then
      obs:remove_notifier(self,self.sample_loop_changed_notifier)
    end    
    local obs = self.sample.loop_end_observable
    if obs:has_notifier(self,self.sample_loop_changed_notifier) then
      obs:remove_notifier(self,self.sample_loop_changed_notifier)
    end    
    local obs = self.sample.sample_buffer_observable
    if not obs:has_notifier(self,self.sample_buffer_notifier) then
      obs:remove_notifier(self,self.sample_buffer_notifier)
    end    
    local obs = self.sample.fine_tune_observable    
    if not obs:has_notifier(self,self.sample_tuning_notifier) then
      obs:remove_notifier(self,self.sample_tuning_notifier)
    end    
    local obs = self.sample.transpose_observable    
    if not obs:has_notifier(self,self.sample_tuning_notifier) then
      obs:remove_notifier(self,self.sample_tuning_notifier)
    end    
    local obs = self.sample.sample_mapping.base_note_observable
    if not obs:has_notifier(self,self.sample_tuning_notifier) then
      obs:remove_notifier(self,self.sample_tuning_notifier)
    end    
    if self:get_sample_buffer() then 
      local obs = self.sample.sample_buffer.selection_range_observable
      if obs:has_notifier(self,self.selection_range_notifier) then 
        obs:remove_notifier(self,self.selection_range_notifier)
      end
    end 
    self.sample = nil
  end 

end 

