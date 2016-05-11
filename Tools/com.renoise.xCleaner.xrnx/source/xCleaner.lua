--[[============================================================================
xCleaner
============================================================================]]--
--[[

  Requires xLib

  FIXME
    - antialiasing always enabled on fixed samples (no API access...)
    - detect when instrument is gone (deleted, or on new song...)


  TODO

  - realtime update when checking fxchains on/off

  - Sliced removal process

  - when sample is sliced, 
    scanning: ANY matched sample will keep them all
    removing: just don't - can't "selectively" modify slices

  PLANNED

  Batch Convert Samples
  - simply implemented as "Batch" button, brings up dialog

    Sample Buffer 
    [x] Set bit depth to  [xLib.NUM_BITS]
    [ ] Adjust channels   [xSample.SAMPLE_CONVERT]
    [ ] Swap phase
    [ ] Normalize to      [ percentage% ] 
                          [x] relative to global peak

    Sample Properties
    set any "key" to value...
    - list of keys obtained via xLib.collect_object_properties()

    [x] Interpolation     [Cubic]



]]

class 'xCleaner'

--------------------------------------------------------------------------------
-- Constants

xCleaner.NOT_AVAILABLE = "--"
xCleaner.SLICED_INSTR_MSG = "Can't process a sliced instrument. Please render the instrument to slices and try again"

-- Configuration Settings

-- (bool)
xCleaner.check_unreferenced = true

-- (bool)
xCleaner.find_issues = true

-- (bool)
xCleaner.find_actual_bit_depth = false

-- (bool)
xCleaner.find_channel_issues = false

-- (bool)
xCleaner.find_excess_data = false

-- (bool) 
xCleaner.skip_empty_samples = true



--------------------------------------------------------------------------------

function xCleaner:__init()

  self._ui = xCleanerUI(self) -- (xCleanerUI)
  self.process_slicer = nil -- (ProcessSlicer)

  self.samples = nil    -- (table)
  self.modsets = nil    -- (table)
  self.fxchains = nil   -- (table)
  self.instr = nil      -- (renoise.Instrument) 
  self.instr_idx = nil  -- (int) 
  self.sample_idx = nil -- (int) 
  self.modset_idx = nil -- (int) 
  self.fxchain_idx = nil -- (int) 

  self.notifiers = {
    selected_instrument_observable = function()
      print("selected_instrument_observable fired...")
      self._ui:update_instr_selector()
    end,
    selected_sample_observable = function()
      print("selected_sample_observable fired...")
      local instr_idx = renoise.song().selected_instrument_index
      if (instr_idx == self.instr_idx) then
        self.sample_idx = renoise.song().selected_sample_index
      end
      self._ui:highlight_row(xCleanerUI.TAB.SAMPLES)
      self._ui:update_main_buttons()
    end,
    selected_sample_modulation_set_observable = function()
      print("selected_sample_modulation_set_observable fired...")
      local instr_idx = renoise.song().selected_instrument_index
      if (instr_idx == self.instr_idx) then
        self.modset_idx = renoise.song().selected_sample_modulation_set_index
      end
      self._ui:highlight_row(xCleanerUI.TAB.MODULATION)
      self._ui:update_main_buttons()
    end,
    selected_sample_device_chain_observable = function()
      print("selected_sample_device_chain_observable fired...")
      local instr_idx = renoise.song().selected_instrument_index
      if (instr_idx == self.instr_idx) then
        self.fxchain_idx = renoise.song().selected_sample_device_chain_index
      end
      self._ui:highlight_row(xCleanerUI.TAB.EFFECTS)
      self._ui:update_main_buttons()
    end,

  }

  -- set initial prefs --------------

  self:set_issue_scanning_pref(xCleaner.find_issues)

end


--------------------------------------------------------------------------------
-- remove selected assets

function xCleaner:remove_assets()
  --print("xCleaner:remove_assets()")

  local str_msg = "Beginning removal of assets"
  self._ui:add_to_log(str_msg,true)
  local time_elapsed = os.clock()

  if xInstrument.is_sliced(self.instr) then
    str_msg = ("%s\nWARNING: Cannot remove samples from a sliced instrument"):format(str_msg)
  else
    for k,v in ripairs(self.samples) do
      if v.checked then
        print(("*** about to delete sample at index %X"):format(v.index))
        self.instr:delete_sample_at(v.index)
      end
    end
  end

  for k,v in ripairs(self.modsets) do
    if v.checked then
      print(("*** about to delete mod-set at index %i"):format(v.index)) 
      self.instr:delete_sample_modulation_set_at(v.index)
    end
  end

  for k,v in ripairs(self.fxchains) do
    if v.checked then
      print(("*** about to delete fx-chain at index %i"):format(v.index)) 
      self.instr:delete_sample_device_chain_at(v.index)
    end
  end

  time_elapsed = os.clock()-time_elapsed
  str_msg = ("%s\nCompleted in %.2f seconds"):format(str_msg,time_elapsed)
  self._ui:add_to_log(str_msg,true)

  -- "quick" rebuild of table
  self:gather_samples(false)

end


--------------------------------------------------------------------------------
-- "all in one" enabling of the various issue scanners

function xCleaner:set_issue_scanning_pref(bool)
  --print("xCleaner:set_issue_scanning_pref(bool)",bool)

  xCleaner.find_issues = bool
  xCleaner.find_actual_bit_depth = bool
  xCleaner.find_channel_issues = bool
  xCleaner.find_excess_data = bool
  
end

--------------------------------------------------------------------------------
-- solve the issues that we are able to 

function xCleaner:fix_issues()
  print("xCleaner:fix_issues()")

  if xInstrument.is_sliced(self.instr) then
    renoise.app():show_message(xCleaner.SLICED_INSTR_MSG)
    return false
  end

  local instr = self.instr
  local samples_tab_idx = 1
  local xsamples = self.samples
  local user_invoked = false

  local str = ("Fixing all known issues for '%s'"):format(instr.name)
  self._ui:add_to_log(str,true)

  -- processing function
  local process = function(instr_idx,fn_progress,fn_done)
    for k,xsample in ipairs(self.samples) do
      xCleaner.fix_issue(instr,samples_tab_idx,xsamples,xsample.index,fn_progress)
      coroutine.yield()
      if (instr_idx == renoise.song().selected_instrument_index) then
        renoise.song().selected_sample_index = xsample.index
      end
    end
    fn_done()
  end

  local time_elapsed = os.clock()

  local progress_handler = function(item,tab_idx,issues_fixed)
    if (issues_fixed > 0) then
      local str = ("Fixed %d issues in '%s'"):format(issues_fixed,item.name)
      self._ui:add_to_log(str,true)
    end
  end

  local done_handler = function()
    time_elapsed = os.clock()-time_elapsed
    self._ui:show_results(time_elapsed)
  end

  -- call the processing function...
  self.process_slicer = ProcessSlicer(process,self.instr_idx,progress_handler,done_handler)
  self.process_slicer:start()

end
--------------------------------------------------------------------------------
-- solve issues on the selected item in the active table/tab
-- @param instr (renoise.Instrument)  
-- @param tab_idx (int)
-- @param data (table)
-- @param item_idx (int)

function xCleaner.fix_issue(instr,tab_idx,data,item_idx,update_callback)
  print("xCleaner.fix_issue()",instr,tab_idx,data,item_idx,update_callback)
  
  if not instr then
    print("*** xCleaner:fix_issue() - no instrument selected")
    return false
  end

  if xInstrument.is_sliced(instr) then
    renoise.app():show_message(xCleaner.SLICED_INSTR_MSG)
    return false
  end

  if (tab_idx == 1) then


    --local xsample = xCleaner.get_data_item(data,"index",item_idx-1)
    local xsample = vVector.match_by_key_value(data,"index",item_idx)

    if not xCleaner.has_issues(xsample) then
      return
    end

    local channel_action = nil
    local bit_depth = nil

    -- how to fix panning issue
    if xsample.channel_info then
      if (xsample.channel_info == xSample.SAMPLE_INFO.PAN_LEFT) then
        channel_action = xSample.SAMPLE_CONVERT.MONO_LEFT
      elseif (xsample.channel_info == xSample.SAMPLE_INFO.PAN_RIGHT) then
        channel_action = xSample.SAMPLE_CONVERT.MONO_RIGHT
      elseif (xsample.channel_info == xSample.SAMPLE_INFO.DUPLICATE) then
        channel_action = xSample.SAMPLE_CONVERT.MONO_LEFT
      end
    end

    -- provide actual bit depth
    if (xsample.bit_depth ~= xsample.bit_depth_actual) then
      bit_depth = xsample.bit_depth_actual
    end

    --print("PRE channel_action,bit_depth,xsample.excess_data",channel_action,bit_depth,xsample.excess_data)

    -- do we have something to fix? 
    if channel_action or bit_depth or xsample.excess_data then
      
      local sample = instr.samples[item_idx]
      local buffer = sample.sample_buffer
      if not buffer.has_sample_data then
        return false
      end

      -- provide defaults
      if not channel_action then
        channel_action = (buffer.number_of_channels == 2) and
          xSample.SAMPLE_CONVERT.STEREO or xSample.SAMPLE_CONVERT.MONO_LEFT
      end

      if not bit_depth then
        bit_depth = xsample.bit_depth
      end

      local range = {
        start_frame = 1,
        end_frame = buffer.number_of_frames
      }
      if xsample.excess_data then
        range.end_frame = sample.loop_end
      end

      --print("POST instr,item_idx,bit_depth,channel_action,range",instr,item_idx,bit_depth,channel_action,range)
      sample = xSample.convert_sample(instr,item_idx,bit_depth,channel_action,range)

      -- hard panning: adjust on sample level
      if (xsample.channel_info == xSample.SAMPLE_INFO.PAN_LEFT) then
        sample.panning = 0
      elseif (xsample.channel_info == xSample.SAMPLE_INFO.PAN_RIGHT) then
        sample.panning = 1
      end
      
      local issues_fixed = nil
      xCleaner.collect_sample_info(instr,xsample,item_idx)
      xsample.excess_data = false
      xsample.summary,issues_fixed = vString.strip_line(xsample.summary,"\^ISSUE:")
      if update_callback then
        update_callback(xsample,tab_idx,issues_fixed)
      end

    end

  end

  

end

--------------------------------------------------------------------------------

function xCleaner:gather()
  print("xCleaner:gather()")

  self.instr = renoise.song().selected_instrument
  self.instr_idx = renoise.song().selected_instrument_index

  self._ui:clear_log()
  self._ui:add_to_log(("Starting scan of assets for '%s'"):format(self.instr.name),true)

  self:gather_samples(xCleaner.find_issues)

end


--------------------------------------------------------------------------------
-- scan for samples, using sliced processing 
-- @param find_issues (bool) when true, check for defined types

function xCleaner:gather_samples(find_issues)
  print("xCleaner.gather_samples()",find_issues)

  local instr = self.instr

  self:set_issue_scanning_pref(find_issues)

  -- processing function >>> 
  local gather_process = function(fn_progress,fn_done)

    local t = table.create()

    local sample_refs = {}
    local note_refs = {}

    local add_sample_ref = function(sample_idx,ref)
      if not sample_refs[sample_idx] then
        sample_refs[sample_idx] = table.create()
      end
      sample_refs[sample_idx]:insert(ref)
    end

    -- iterate through phrases, and register which samples are being used
    -- when instr. column is visible: register direct sample references 
    for k,phrase in ipairs(instr.phrases) do
      if (phrase.instrument_column_visible) then
        local phrase_lines = phrase:lines_in_range(1,phrase.number_of_lines)
        for k2, phrase_line in ipairs(phrase_lines) do
          for k3, note_col in ipairs(phrase_line.note_columns) do
            -- skip hidden note columns
            if (k3 <= phrase.visible_note_columns) then
              if (note_col.instrument_value < 255) then
                add_sample_ref(note_col.instrument_value+1,{
                  phrase_idx = k,
                  line_idx = k2,
                  column_idx = k3
                })
              end
            end
          end
        end
      end
    end

    -- step 2: populate the table with data, and optionally
    -- scan for "actual" sample info (bit-depth/channel etc.)
    for k,sample in ipairs(instr.samples) do
      t[k] = {
        -- displayed in table
        name = (sample.name == "") and ("Sample %02X"):format(k-1) or sample.name,
        index = k,
        sample_rate = nil,
        bit_depth_display = nil,
        num_channels_display = nil,
        -- hidden data
        bit_depth = nil,
        bit_depth_actual = nil,
        channel_info = nil,         -- defined when having panning issues
        num_channels = nil,         -- 
        num_channels_actual = nil,  --
        excess_data = false,
        summary = "",
      }
      xCleaner.collect_sample_info(instr,t[k],k)

      -- display progress
      fn_progress(("Processed sample #%02X - %s"):format(k-1,sample.name))
      coroutine.yield()
    end

    -- step 3: cross-reference with samples registered in phrases

    local kz_available = xInstrument.is_keyzone_available(instr)
    --print("kz_available",kz_available)
    for k,sample in ipairs(instr.samples) do
      if not sample_refs[k] then
        if xCleaner.skip_empty_samples and
          not sample.sample_buffer.has_sample_data 
        then 
          t[k].summary = t[k].summary ..
            "KEEP: You have chosen to leave empty samples intact\n"
        else
          -- when using keyzones, any sample can theoritically be reached
          -- so we check if the keyzone is available
          if not kz_available then
            t[k].summary = t[k].summary ..
              "REMOVE: Not referenced in a phrase via sample columns\n"
          end
        end
      else
        t[k].summary = t[k].summary ..
          ("KEEP: Referenced %d times via sample columns\n"):format(#sample_refs[k])
      end

      t[k].checked = (xCleaner.check_unreferenced) and 
        xCleaner.is_unreferenced(t[k]) or false

      if (t[k].summary == "") then
        t[k].summary = ("%sKEEP: This sample can be accessed via the keyzone\n"):format(t[k].summary)
      end

    end

    --print("t",rprint(t))
    fn_done(t)

  end
  -- /processing function

  local time_elapsed = os.clock()

  local progress_handler = function(str)
    self._ui:add_to_log(tostring(str),true)
  end

  local done_handler = function(t)
    print("done_handler(t)",t)

    self.samples = t
    time_elapsed = os.clock()-time_elapsed
    self:gather_modulation()
    self:gather_effects()
    self._ui:show_results(time_elapsed)
    self:set_issue_scanning_pref(xCleaner.find_issues)

  end

  -- call the processing function...
  self.process_slicer = ProcessSlicer(gather_process,progress_handler,done_handler)
  self.process_slicer:start()
  
  --[[ 
  gather_process(progress_handler,done_handler)
  ]]


end

--------------------------------------------------------------------------------
-- (static method) collect sample info, including issues
-- @param item (table)
-- @param sample_idx (int)

function xCleaner.collect_sample_info(instr,item,sample_idx)
  print("xCleaner.collect_sample_info()")

  local sample = instr.samples[sample_idx]
  local buffer = sample.sample_buffer

  -- check sample rate
  item.sample_rate = (buffer.has_sample_data) and 
    buffer.sample_rate or xCleaner.NOT_AVAILABLE

  -- check channels
  local num_channels = 0
  local num_channels_actual = 0
  if buffer.has_sample_data then
    num_channels = buffer.number_of_channels
    num_channels_actual = buffer.number_of_channels
    if xCleaner.find_channel_issues then
      local channel_info = xSample.get_channel_info(sample)
      --print("channel_info",channel_info)
      if (channel_info == xSample.SAMPLE_INFO.DUPLICATE) then
        item.summary = item.summary ..
          "ISSUE: Reported as stereo, but seems to be in mono\n"
        num_channels_actual = 1
      elseif (channel_info == xSample.SAMPLE_INFO.PAN_RIGHT) or 
        (channel_info == xSample.SAMPLE_INFO.PAN_LEFT)
      then
        item.summary = item.summary ..
          "ISSUE: One of the channels are silent ('hard-panned')\n"
        num_channels_actual = 1
      elseif (channel_info == xSample.SAMPLE_INFO.SILENT) then
        item.summary = item.summary ..
          "WARNING: The entire sample is silent \n"
        num_channels_actual = num_channels
      elseif (channel_info == xSample.SAMPLE_INFO.MONO) then
        num_channels_actual = 1
      elseif (channel_info == xSample.SAMPLE_INFO.STEREO) then
        num_channels_actual = 2
      end
      item.channel_info = channel_info
    end
  end
  item.num_channels = num_channels
  item.num_channels_actual = num_channels_actual
  --print("num_channels,num_channels_actual",num_channels,num_channels_actual)
  item.num_channels_display = (num_channels == 0) and 
    xCleaner.NOT_AVAILABLE or num_channels
  if (num_channels ~= num_channels_actual) then
    item.num_channels_display = ("%d⚠"):format(num_channels)
  end

  -- check bit depth
  local bit_depth = 0
  local bit_depth_actual = 0
  if buffer.has_sample_data then
    bit_depth = buffer.bit_depth
    bit_depth_actual = buffer.bit_depth
    if xCleaner.find_actual_bit_depth then
      bit_depth_actual = xSample.get_bit_depth(sample)
    end
  end
  item.bit_depth = bit_depth
  item.bit_depth_actual = bit_depth_actual
  item.bit_depth_display = (bit_depth == 0) and 
    xCleaner.NOT_AVAILABLE or bit_depth
  if (bit_depth ~= bit_depth_actual) then
    if item.channel_info and (item.channel_info == xSample.SAMPLE_INFO.SILENT) then
      -- silent sample, do not complain over bitrate
    else
      item.bit_depth_display = ("%d⚠"):format(bit_depth)
      item.summary = ("%sISSUE: Has a lower actual bitrate than reported (%d)\n"):format(item.summary,bit_depth_actual)
    end
  end

  -- detect excess data
  if buffer.has_sample_data and xCleaner.find_excess_data then
    if (sample.loop_mode ~= renoise.Sample.LOOP_MODE_OFF) then
      if (sample.loop_end < buffer.number_of_frames) then
        item.excess_data = true
        item.summary = ("%sISSUE: Has excess data after the loop point\n"):format(item.summary)
      end
    end
  end

  if not xCleaner.find_issues then
    item.summary = ("%sTIP: Enable issue scanning to learn if we can perform optimizations on this sample\n"):format(item.summary)
  end

end

--------------------------------------------------------------------------------
-- collect unused modulation sets

function xCleaner:gather_modulation()
  print("xCleaner:gather_modulation()")

  local instr = self.instr
  local xsamples = self.samples
  local t = table.create()

  for k,modset in ipairs(instr.sample_modulation_sets) do
    t[k] = {
      name = modset.name,
      index = k,
      -- hidden data
      summary = "",
      sample_links = {}, -- {name=[string], index=[int]}
    }
    for k2,xsample in ipairs(xsamples) do
      if not (xsample.checked) then
        local sample = instr.samples[xsample.index]
        if (sample.modulation_set_index == k) then
          table.insert(t[k].sample_links,{
            name = xsample.name,
            index = xsample.index,
          })
        end
      end
    end
  end

  for k,modset in ipairs(instr.sample_modulation_sets) do

    t[k].checked = (xCleaner.check_unreferenced) and 
      table.is_empty(t[k].sample_links) 

    if table.is_empty(t[k].sample_links) then
      t[k].summary = t[k].summary ..
        "REMOVE: Modulation set not referenced by any samples\n"
    end

  end

  --print("t",rprint(t))
  --return t
  self.modsets = t

end

--------------------------------------------------------------------------------
-- collect unused effect chains
-- this includes checks for linked devices, send devices etc.

function xCleaner:gather_effects()
  print("xCleaner:gather_effects()")

  local instr = self.instr
  local t = table.create()

  -- step 1: check sample references
  for k,fxchain in ipairs(instr.sample_device_chains) do

    t[k] = {
      name = fxchain.name,
      index = k,
      -- hidden data
      summary = "",
      sample_links = {}, -- {name=[string], index=[int]}
      device_links_in = {}, -- {name=[string], index=[int]}
      device_links_out = {}, -- {name=[string], index=[int]}
    }
    for k2,xsample in ipairs(self.samples) do
      if not (xsample.checked) then
        local sample = instr.samples[xsample.index]
        if (sample.device_chain_index == k) then
          table.insert(t[k].sample_links,{
            name = xsample.name,
            index = xsample.index,
          })
        end
      end
    end
  end

  --print("step 1 - t",rprint(t))

  -- step 2: check routing/linking
  local fxchains = instr.sample_device_chains
  for k,fxchain in ipairs(fxchains) do
    for k2,device in ipairs(fxchain.devices) do
      local linked_chains = xAudioDevice.get_device_routings(device)

      for linked_chain_idx,_ in pairs(linked_chains) do
        --print("linked_chain_idx",linked_chain_idx)

        -- skip invalid send devices (routing to self or previous)
        local skip_entry = false
        if xAudioDevice.is_send_device(device) then         
          if (linked_chain_idx <= k) then
            skip_entry = true
            t[k].summary = t[k].summary ..
              ("WARNING: Invalid device routing ("..
              " DSP Device: %s, Source chain: #%s %s, Target chain: #%s %s)\n"
              ):format(device.display_name,k,fxchains[k].name,
                linked_chain_idx,(fxchains[linked_chain_idx]) and fxchains[linked_chain_idx].name or "(N/A)")
          end
        end
        --print("skip_entry",skip_entry)
        
        if not skip_entry and t[linked_chain_idx] then
          table.insert(t[linked_chain_idx].device_links_in,{
            name = fxchain.name,
            index = k,
          })
        end

      end
    end

  end

  --print("step 2 - t",rprint(t))

  local should_check_item = function(item)
    return 
  end

  -- step 3: check if not referenced by samples
  for k,fxchain in ipairs(instr.sample_device_chains) do
    t[k].checked = (xCleaner.check_unreferenced) and 
      table.is_empty(t[k].sample_links) 
  end

  -- step 4: check if not referenced by other devices 
  for k,fxchain in ipairs(instr.sample_device_chains) do

    -- check if device-links are all unreferenced
    local all_devices_unreferenced = true
    for k2,device_link in ipairs(t[k].device_links_in) do
      local xchain = vVector.match_by_key_value(t,"index",device_link.index)
      print("xchain",xchain.name,"xchain.checked",xchain.checked)
      if not xchain.checked then
        all_devices_unreferenced = false
      end
    end
    print("all_devices_unreferenced",all_devices_unreferenced,k,fxchain.name)
    -- check item when unreferenced
    t[k].checked = (xCleaner.check_unreferenced) and 
      t[k].checked and
      (table.is_empty(t[k].device_links_in) or all_devices_unreferenced)

  end


  -- step 5: summarize
  for k,fxchain in ipairs(instr.sample_device_chains) do

    --if (#t[k].device_links_in > 0) or (#t[k].sample_links > 0) then
    if not t[k].checked then
      local str_samples = (#t[k].sample_links > 0) and 
        ("samples: %s"):format(table.concat(
          xLib.match_table_key(t[k].sample_links,"name"),",")) or ""
      local str_devices = (#t[k].device_links_in > 0) and 
        ("fx-chains: %s"):format(table.concat(
          xLib.match_table_key(t[k].device_links_in,"name"),",")) or ""
      t[k].summary = ("%sKEEP: Referenced by %s %s\n"):format(
          t[k].summary,str_samples,str_devices)
    else
      t[k].summary = t[k].summary ..
        "REMOVE: Effect chain not referenced by any samples/devices\n"
    end

  end

  --return t
  self.fxchains = t

end

--------------------------------------------------------------------------------
-- @param item (table)
-- @return bool

function xCleaner.is_unreferenced(item)
    return (item.summary:match("REMOVE")=="REMOVE") 
end

--------------------------------------------------------------------------------
-- @param item (table)
-- @return bool

function xCleaner.has_issues(item)
    return (item.summary:match("ISSUE")=="ISSUE") 
end

--------------------------------------------------------------------------------
-- @param item (table)
-- @return bool

function xCleaner.has_warnings(item)
    return (item.summary:match("WARNING")=="WARNING") 
end

--------------------------------------------------------------------------------
-- count specific text tokens in the .summary data field
-- @param t (table) data item
-- @param token (string), i.e. "ISSUE" or "REMOVE" 
-- @return int

function xCleaner.count_tokens(t,token)

  local count = 0
  local m = t.summary:gmatch(token)
  for k,v in m do
    count = count+1
  end
  return count
  
end


--------------------------------------------------------------------------------

function xCleaner:attach_to_song()
  print("xCleaner:attach_to_song()")

  self.instr = nil
  self.instr_idx = nil

  self.sample_idx = renoise.song().selected_sample_index
  self.modset_idx = renoise.song().selected_sample_modulation_set_index
  self.fxchain_idx = renoise.song().selected_sample_device_chain_index

  if not renoise.song().selected_instrument_observable:has_notifier(
    self.notifiers.selected_instrument_observable)
  then
    renoise.song().selected_instrument_observable:add_notifier(
      self.notifiers.selected_instrument_observable)
  end

  if not renoise.song().selected_sample_observable:has_notifier(
    self.notifiers.selected_sample_observable)
  then
    renoise.song().selected_sample_observable:add_notifier(
      self.notifiers.selected_sample_observable)
  end

  if not renoise.song().selected_sample_modulation_set_observable:has_notifier(
    self.notifiers.selected_sample_modulation_set_observable)
  then
    renoise.song().selected_sample_modulation_set_observable:add_notifier(
      self.notifiers.selected_sample_modulation_set_observable)
  end

  if not renoise.song().selected_sample_device_chain_observable:has_notifier(
    self.notifiers.selected_sample_device_chain_observable)
  then
    renoise.song().selected_sample_device_chain_observable:add_notifier(
      self.notifiers.selected_sample_device_chain_observable)
  end


end


--------------------------------------------------------------------------------
--- handle idle notifications

function xCleaner:on_idle()

end

--------------------------------------------------------------------------------

function xCleaner:show()

  self._ui:show()

end


