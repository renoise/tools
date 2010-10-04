--[[============================================================================
  ToggleDSPs main.lua
============================================================================]]--

local debug = true
_AUTO_RELOAD_DEBUG = debug

local toggles = {
  Bypass = false,
  Enable = true,
  Toggle = 'toggle'
}

local types = {
  ALL = "All Effects",
  DSP = "Renoise DSP",
  VST = "VSTfx",
  AU = "AU",
  LADSPA = "LADSPA"
}

local ranges = {
  Song = false,
  Track = true
}

-- Helpers for menu splits
local sep = ""
local split = false

-- Remember track states
-- tracks[track_num]['enabled'] = true
-- tracks[track_num][device_id] = true
local tracks = table.create()
local dsps = table.create()

local options = renoise.Document.create("ScriptingToolPreferences") {
  restore = true -- Remember Bypassed DSPs
}

renoise.tool().preferences = options

--------------------------------------------------------------------------------
-- Menu Items and Keybindings
--------------------------------------------------------------------------------

for toggle_id, toggle_value in pairs(toggles) do

  renoise.tool():add_menu_entry{
    name = "Main Menu:Tools:Toggle DSPs:"..toggle_id.." All In Track",
    invoke = function() toggle_dsps(toggle_value,"ALL", "Track") end
  }

  renoise.tool():add_menu_entry{
     name = "Track DSPs Chain:Toggle DSPs:"..toggle_id.." All In Track",
     invoke = function() toggle_dsps(toggle_value,"ALL", "Track") end
  }
  
  renoise.tool():add_menu_entry{
     name = "Mixer:Toggle DSPs:"..toggle_id.." All In Track",
     invoke = function() toggle_dsps(toggle_value,"ALL", "Track") end
  }

  for range_id, range_value in pairs(ranges) do
    
    if (split) then
      sep = "--- "
      split = false
    else
      sep = ""
    end    

    for type_id, type_value in pairs(types) do

      renoise.tool():add_menu_entry{
        name = sep .. "Main Menu:Tools:Toggle DSPs:" .. type_value ..
          ":" .. toggle_id .. " All In " .. range_id,
        invoke = function() toggle_dsps(toggle_value,type_id, range_id) end
      }
      
      renoise.tool():add_menu_entry{
        name = sep .. "Mixer:Toggle DSPs:" .. type_value ..
          ":" .. toggle_id .. " All In " .. range_id,
        invoke = function() toggle_dsps(toggle_value,type_id, range_id) end
      }
      
      renoise.tool():add_keybinding{
        name = "Track DSPs Chain:Toggle DSPs:" ..
          toggle_id .. " In " .. range_id .. " - " .. type_value ,
        invoke = function(repeated)
          if (not repeated) then 
            toggle_dsps(toggle_value,type_id, range_id) 
          end
        end
      }
      
      renoise.tool():add_keybinding{
        name = "Global:Toggle DSPs:" ..
          toggle_id .. " In " .. range_id .. " - " .. type_value ,
        invoke = function(repeated)
          if (not repeated) then 
            toggle_dsps(toggle_value,type_id, range_id)
          end 
        end
      }

    end
  end
  split = true
end

local restore_invoke = function() options.restore.value = not options.restore.value end
local restore_select = function() return options.restore.value end

renoise.tool():add_menu_entry{
  name = "--- Main Menu:Tools:Toggle DSPs:Remember Bypassed DSPs",
  invoke = restore_invoke,
  selected = restore_select
}

renoise.tool():add_menu_entry{
  name = "--- Track DSPs Chain:Toggle DSPs:Remember Bypassed DSPs",
  invoke = restore_invoke,
  selected = restore_select
}

renoise.tool():add_menu_entry{
  name = "--- Mixer:Toggle DSPs:Remember Bypassed DSPs",
  invoke = restore_invoke,
  selected = restore_select
}

renoise.tool():add_keybinding{
  name = "Track DSPs Chain:Toggle DSPs:Remember Bypassed DSPs",
  invoke = restore_invoke,
  selected = restore_select
}

renoise.tool():add_keybinding{
  name = "Global:Toggle DSPs:Remember Bypassed DSPs",
  invoke = restore_invoke,
  selected = restore_select
}

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

local function trace(s)
  if (not debug) then
    return
  end
  if (type(s) == 'table') then
    rprint(s)
  else
    print(s)
  end
end

local function get_track_state(track_num)
  if (not tracks[track_num] or tracks[track_num]['enabled'] == nil) then
    return true
  end
  return tracks[track_num]['enabled']
end

local function set_track_state(track_num, toggle_value)
  if (not tracks[track_num]) then
    tracks[track_num] = table.create()
  end
  tracks[track_num]['enabled'] = toggle_value
end

-- Updates a table
-- @param t  the table
-- @param data  the built-in data sent by the notifier
-- @param value  the built-in data sent by the notifier
local function update_table(t,data,value)
  trace(data)
  if (data.type == "swap") then
    local temp = t[data.index1]
    t[data.index1] = t[data.index2]
    t[data.index2] = temp
  elseif (data.type == "remove") then        
    t[data.index] = nil
    for k,v in pairs(t) do      
      if (type(k)=='number' and k>data.index) then              
        t[k-1] = v
        t[k] = nil
      end      
    end    
  elseif (data.type == "insert") then
      -- 4 = a
      -- 5 = b
      -- insert 5
      -- 4 = a
      -- 5 = c
      -- 6 = b
      -- insert 4
      -- 4 = d
      -- 5 = a
      -- 6 = c
      -- 7 = b
      -- insert 8
      -- 4 = d
      -- 5 = a
      -- 6 = c
      -- 7 = b
      -- 8 = e
    for _,k in ripairs(table.keys(t)) do
      if (type(k)=='number' and k>=data.index) then
        t[k+1] = t[k]
      end
    end
    if (type(value)=='function') then
      t[data.index] = value(data)
    else
      t[data.index] = value or {}
    end
    trace(t)
  end
end

function get_track_num_by_id(dspid)
  trace(tracks)
  for k,track in pairs(tracks) do
    if (track.id and track.id == dspid) then
      return k
    end
  end
  if (debug) then
    renoise.app():show_error("get_track_num_by_id == nil")
  end
end 

-- This is the handler for the devices_observable notifier
-- When moving a device from one track to another, the device bypass state
--  from the source track will not carry over to the target track
-- @param params  the additional parameters table
-- @param data  the built-in data sent by the notifier
local function device_notifier(id,data)
  local track_num = get_track_num_by_id(id)
  local value = function(d)
    local track_num = get_track_num_by_id(id)
    trace("track_num/id:  " .. track_num .. "/" .. id.value)
    return renoise.song().tracks[track_num].devices[d.index].is_active
  end          
  update_table(tracks[track_num],data,value)
end

-- This is the handler for the tracks_observable notifier
-- @param data  the built-in data sent by the notifier
local function track_notifier(data)
  update_table(tracks, data)
  attach_notifiers()
end

local function is_renoise_dsp(name)
  for k,_ in pairs(types) do
     if k ~= "DSP" and string.find(name, k) then
        return false
     end
  end   
  return true
end

local function toggle_dsps_in_track(toggle_value, track_num, type_id)
  if (not tracks[track_num])then
      tracks[track_num] = {}
  end
  
  if (toggle_value == toggles.Toggle) then
    toggle_value = not get_track_state(track_num)
  end
  
  set_track_state(track_num, toggle_value)
  
  local devices = renoise.song().tracks[track_num].devices

  -- Loop (skip the Track/Vol/Pan device at 1)  
  for i = 2, #devices do
    local d = devices[i]
    if ((type_id == "DSP" and is_renoise_dsp(d.name)) or
      string.find(d.name, type_id) or type_id == "ALL") then
      if (options.restore.value and toggle_value) then
        d.is_active = tracks[track_num][i] or (d.is_active == true)
      else
        tracks[track_num][i] = d.is_active
        d.is_active = toggle_value
      end
    end
  end
end

local function toggle_dsps_in_song(toggle_value, type_id)
  -- Loop through all tracks
  for k in ipairs(renoise.song().tracks) do
    toggle_dsps_in_track(toggle_value, k, type_id)
  end
end

local function toggle_dsps_in_current_track(toggle_value, type_id)
  toggle_dsps_in_track(toggle_value, renoise.song().selected_track_index, type_id)
end

function toggle_dsps(toggle_value, type_id, range_id)
  if range_id == "Song" then
    toggle_dsps_in_song(toggle_value, type_id)
  else     
    toggle_dsps_in_current_track(toggle_value, type_id)
  end  
end

function attach_notifiers()
  trace("attach_notifiers")
  if (renoise.song().tracks_observable:has_notifier(track_notifier)) then
    renoise.song().tracks_observable:remove_notifier(track_notifier)
  end
  renoise.song().tracks_observable:add_notifier(track_notifier)

  for k,track in pairs(renoise.song().tracks) do
    if (not tracks[k]) then
      tracks[k] = {}
    end

    if (not tracks[k].id) then
      tracks[k].id = DSPId()
      track.devices_observable:add_notifier(device_notifier, tracks[k].id)
    end
  end
end


class "DSPId"
DSPId.count = 0
function DSPId:__init()  
  DSPId.count = DSPId.count + 1
  self.value = DSPId.count 
end
function DSPId:__eq(other)
  if (type(other) == "number") then
    return self.value == other
  elseif (type(other) == "DSPId") then
    return self.value == other.value
  end
end
function DSPId:__tostring()  
  return tostring(self.value)
end
function DSPId:reset()
  DSPId.count = 0
end

--------------------------------------------------------------------------------
-- Global Notifiers
--------------------------------------------------------------------------------

renoise.tool().app_new_document_observable:add_notifier(function()
  table.clear(tracks)
  DSPId:reset()
  attach_notifiers()
end)
