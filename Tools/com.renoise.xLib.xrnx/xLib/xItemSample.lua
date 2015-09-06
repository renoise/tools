--[[============================================================================
xItemSample
============================================================================]]--
--[[]]

require (_vlibroot.."vTable")

class 'xItemSample' (xItem)

xItemSample.column_defs = {
  {key = "show",    col_width=25, col_type=vTable.CELLTYPE.BITMAP, tooltip="Bring focus to this item"},
  {key = "checked", col_width=20, col_type=vTable.CELLTYPE.CHECKBOX, tooltip="Select/deselect this item"},
  {key = "summary", col_width=30, col_type=vTable.CELLTYPE.BUTTON}, -- symbolize_summary is added once vTable is instantiated
  {key = "index",   col_width=20, align="center", formatting="%02X", transform=function(val) return val-1 end},
  {key = "name",    col_width="auto"},
  {key = "bit_depth_display",col_width=30, align="center"},
  {key = "num_channels_display",col_width=25, align="center"},
  {key = "sample_rate", col_width=40},
  {key = "interpolation_mode", col_width=35, transform=function(val) return xLib.SAMPLE_INTERPOLATION_LABELS[val] end},
  {key = "oversample_enabled", col_width=20, align="center", transform=function(val) return (val) and "✔" or " " end},
  {key = "peak_level", col_width=30, align="center", formatting="%.2f"},
}

xItemSample.header_defs = {
  bit_depth_display   = {data = "Bits"},
  checked             = {data = false,  col_type=vTable.CELLTYPE.CHECKBOX},
  index               = {data = "#",   align="center"},
  interpolation_mode  = {data = "Interpolation", align="center"},
  name                = {data = "Sample"},
  num_channels_display = {data = "Number of Channels"},
  oversample_enabled  = {data = "Oversample Enabled", align="center"},
  peak_level          = {data = "Peak", align="center"},
  sample_rate         = {data = "Rate"},
  show                = {data = ""},
  summary             = {data = "Info", align="center"},
}

--------------------------------------------------------------------------------

function xItemSample:__init(...)
  --TRACE("xItemSample:__init(...)",...)

  local args = select(1,...)

	--self.bit_depth = nil
	self.bit_depth_actual = nil
	self.bit_depth_display = nil
	self.channel_info = nil
	self.num_channels = nil
	self.num_channels_actual = nil
	self.num_channels_display = nil
	self.sample_rate = nil
	self.interpolation_mode = nil

	self.excess_data = false
	self.peak_level = 0

  xItem.__init(self,...)

end

--------------------------------------------------------------------------------

function xItemSample:__tostring()

  return ("xItemSample"
    .."\n\t name = '%s'"
    .."\n\t index = %d"
    .."\n\t bit_depth_display = %s"
    .."\n\t peak_level = %f"
    ..""):format(
    self.name,
    self.index,
    tostring(self.bit_depth_display),
    self.peak_level)

end


--------------------------------------------------------------------------------

function xItemSample:collect_sample_info(instr,check_for_peak)
  --TRACE("xItemSample:collect_sample_info()",instr,check_for_peak)

  --print("*** xItemSample self",self)
  local sample = instr.samples[self.index]
  if not sample then
    error("Could not collect info, no sample with this index",self.index)
  end

  local buffer = sample.sample_buffer

  -- check sample rate
  self.sample_rate = (buffer.has_sample_data) and 
    buffer.sample_rate or xCleaner.NOT_AVAILABLE

  -- check channels
  local num_channels = 0
  local num_channels_actual = 0
  if buffer.has_sample_data then
    num_channels = buffer.number_of_channels
    num_channels_actual = buffer.number_of_channels
    if x.prefs.find_channel_issues.value then
      local channel_info,peak_level = xLib.get_channel_info(sample,check_for_peak)
      --print("channel_info,peak_level",channel_info,peak_level)
      if (channel_info == xLib.SAMPLE_INFO.DUPLICATE) then
        self.summary = self.summary ..
          "ISSUE: Reported as stereo, but seems to be in mono\n"
        num_channels_actual = 1
      elseif (channel_info == xLib.SAMPLE_INFO.PAN_RIGHT) or 
        (channel_info == xLib.SAMPLE_INFO.PAN_LEFT)
      then
        self.summary = self.summary ..
          "ISSUE: One of the channels are silent ('hard-panned')\n"
        num_channels_actual = 1
      elseif (channel_info == xLib.SAMPLE_INFO.SILENT) then
        self.summary = self.summary ..
          "WARNING: The entire sample is silent \n"
        num_channels_actual = num_channels
      elseif (channel_info == xLib.SAMPLE_INFO.MONO) then
        num_channels_actual = 1
      elseif (channel_info == xLib.SAMPLE_INFO.STEREO) then
        num_channels_actual = 2
      end
      self.channel_info = channel_info
      self.peak_level = peak_level or 0
    end
  end
  self.num_channels = num_channels
  self.num_channels_actual = num_channels_actual
  --print("num_channels,num_channels_actual",num_channels,num_channels_actual)
  self.num_channels_display = (num_channels == 0) and 
    xCleaner.NOT_AVAILABLE or num_channels
  if (num_channels ~= num_channels_actual) then
    self.num_channels_display = ("%d⚠"):format(num_channels)
  end

  -- check bit depth
  local bit_depth = 0
  local bit_depth_actual = 0
  if buffer.has_sample_data then
    bit_depth = buffer.bit_depth
    bit_depth_actual = buffer.bit_depth
    if x.prefs.find_actual_bit_depth.value then
      bit_depth_actual = xLib.get_bit_depth(sample)
    end
  end
  self.bit_depth = bit_depth
  self.bit_depth_actual = bit_depth_actual
  self.bit_depth_display = (bit_depth == 0) and 
    xCleaner.NOT_AVAILABLE or bit_depth
  if (bit_depth ~= bit_depth_actual) then
    if self.channel_info and (self.channel_info == xLib.SAMPLE_INFO.SILENT) then
      -- silent sample, do not complain over bitrate
    else
      self.bit_depth_display = ("%d⚠"):format(bit_depth)
      self.summary = ("%sISSUE: Has a lower actual bitrate than reported (%d)\n"):format(
        self.summary,bit_depth_actual)
    end
  end
  -- max bit depth
  if x.prefs.max_bit_depth.value and (self.bit_depth_actual > x.prefs.max_bit_depth.value) then
    self.bit_depth_display = ("%d⚠"):format(bit_depth)
    self.bit_depth_actual = x.prefs.max_bit_depth.value
    self.summary = ("%sISSUE: This sample exceeds the maximum specified bit-depth (%d)\n"):format(
      self.summary,bit_depth_actual)
  end

  -- detect excess data
  if buffer.has_sample_data and x.prefs.find_excess_data.value then
    if (sample.loop_mode ~= renoise.Sample.LOOP_MODE_OFF) then
      if (sample.loop_end < buffer.number_of_frames) then
        self.excess_data = true
        self.summary = ("%sISSUE: Has excess data after the loop point\n"):format(
          self.summary)
      end
    end
  end

  -- interpolation mode
  self.interpolation_mode = xLib.get_sample_interpolation_mode(sample)
  if buffer.has_sample_data and x.prefs.max_interpolation_mode.value then
    if (self.interpolation_mode > x.prefs.max_interpolation_mode.value) then
      self.summary = ("%sWARNING: This sample exceeds the specified interpolation mode\n"):format(
        self.summary,table.keys(x.prefs.MAX_INTERPOLATE)[x.prefs.max_interpolation_mode.value])
    end
  end

  -- oversampling 
  self.oversample_enabled = xLib.get_sample_oversample_enabled(sample)
  if buffer.has_sample_data and x.prefs.warn_on_oversampling.value then
    if self.oversample_enabled then
      self.summary = ("%sWARNING: xCleaner is configured to warn when samples are using oversampling\n"):format(
        self.summary)
    end
  end

  if not x.prefs.find_issues.value then
    self.summary = ("%sTIP: Enable issue scanning to learn if we can perform optimizations on this sample\n"):format(
      self.summary)
  end

end

--------------------------------------------------------------------------------
-- fix all possible issues and invoke the update_callback function

function xItemSample:fix_issues(instr)

  if not self:has_issues() then
    return
  end

  local channel_action = nil
  local bit_depth = nil

  -- how to fix panning issue
  if self.channel_info then
    if (self.channel_info == xLib.SAMPLE_INFO.PAN_LEFT) then
      channel_action = xLib.SAMPLE_CONVERT.MONO_LEFT
    elseif (self.channel_info == xLib.SAMPLE_INFO.PAN_RIGHT) then
      channel_action = xLib.SAMPLE_CONVERT.MONO_RIGHT
    elseif (self.channel_info == xLib.SAMPLE_INFO.DUPLICATE) then
      channel_action = xLib.SAMPLE_CONVERT.MONO_LEFT
    end
  end

  -- provide actual bit depth
  if (self.bit_depth ~= self.bit_depth_actual) then
    bit_depth = self.bit_depth_actual
  end

  --print("PRE channel_action,bit_depth,self.excess_data",channel_action,bit_depth,self.excess_data)

  -- do we have something to fix? 
  if channel_action or bit_depth or self.excess_data then
    
    local sample = instr.samples[self.index]
    local buffer = sample.sample_buffer
    if not buffer.has_sample_data then
      return false
    end

    -- provide defaults
    if not channel_action then
      channel_action = (buffer.number_of_channels == 2) and
        xLib.SAMPLE_CONVERT.STEREO or xLib.SAMPLE_CONVERT.MONO_LEFT
    end

    if not bit_depth then
      bit_depth = self.bit_depth
    end

    local range = {
      start_frame = 1,
      end_frame = buffer.number_of_frames
    }
    if self.excess_data then
      range.end_frame = sample.loop_end
    end

    --print("POST instr,item_idx,bit_depth,channel_action,range",instr,item_idx,bit_depth,channel_action,range)
    sample = xLib.convert_sample(instr,self.index,bit_depth,channel_action,range)

    -- hard panning: adjust on sample level
    if (self.channel_info == xLib.SAMPLE_INFO.PAN_LEFT) then
      sample.panning = 0
    elseif (self.channel_info == xLib.SAMPLE_INFO.PAN_RIGHT) then
      sample.panning = 1
    end
    
    local issues_fixed = nil
    self:collect_sample_info(instr)
    self.excess_data = false
    --self.summary,issues_fixed = xLib.strip_line(self.summary,"\\^ISSUE:")

    if self.update_callback then
      self.update_callback(issues_fixed)
    end

  end

end


--------------------------------------------------------------------------------
-- export sample: bring focus to item, then execute the API call
-- @param instr_idx (int)
-- @param export_path (string)
-- @param args (table) define @multisample for alternative export method
-- @return bool, false when export failed

function xItemSample:export(instr_idx,export_path,args)
  TRACE("xItemSample:export(instr_idx,args)",instr_idx,export_path,args)

  local rslt = false
  local instr,sample = self:focus(instr_idx)
  if sample then
    if args and args.multisample then
      --local filename = ("%s/%s.sfz"):format(export_path,instr.name)
      local filename = self:prep_export_name(export_path,instr.name,"sfz")
      rslt = renoise.app():save_instrument_multi_sample(filename)
    else
      --local filename = ("%s/%s.flac"):format(export_path,sample.name)
      local filename = self:prep_export_name(export_path,sample.name,"flac")
      rslt = renoise.app():save_instrument_sample(filename)
    end
  else
    error("Failed to bring focus to sample before export")
  end

  return rslt

end

--------------------------------------------------------------------------------
-- "bring focus to this item before export" 
-- @return renoise.Instrument, renoise.Sample or false

function xItemSample:focus(instr_idx)
  TRACE("xItemSample:focus(instr_idx)",instr_idx)

  local instr = self:focus_instr(instr_idx)
  if not instr then
    return false
  end

  local sample = instr.samples[self.index]
  if sample then
    rns.selected_sample_index = self.index
    return instr,sample
  else
    --print("*** no sample found at this index",self.index)
    return false
  end

end
