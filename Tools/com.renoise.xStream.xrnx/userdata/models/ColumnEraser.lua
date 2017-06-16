--[[===========================================================================
ColumnEraser.lua
===========================================================================]]--

return {
arguments = {
},
presets = {
},
data = {
  ["get_column_states"] = [[-- return a value of some kind
return function()
  local t = {} 
  for k = 1,12 do
    table.insert(t,rns.selected_track:column_is_muted(k))
  end
  return t
end]],
  ["column_states"] = [[-- representation of last known column state
return {}]],
},
events = {
  ["rns.selected_track_index_observable"] = [[------------------------------------------------------------------------------
-- respond to events in renoise 
-- @param arg, depends on the notifier (see Renoise API docs)
------------------------------------------------------------------------------
data.column_states = data.get_column_states()]],
},
options = {
 color = 0x000000,
},
callback = [[
-------------------------------------------------------------------------------
-- Mute note columns to erase content
-------------------------------------------------------------------------------
if table.is_empty(data.column_states) then --
  data.column_states = data.get_column_states()
end
local track = rns.tracks[read_track_index]
local col_count = track.visible_note_columns
for k = 1,col_count do
  local mute_state = track:column_is_muted(k)
  local has_changed = false
  if (data.column_states[k] ~= mute_state) then
    data.column_states[k] = mute_state
    has_changed = true
  end
  if has_changed then
    if mute_state then
      local xnotecol = {note_value = NOTE_OFF_VALUE}
      local pos,scheduled_xinc = xpos:get_scheduled_pos(xStreamPos.SCHEDULE.LINE)
      xbuffer:schedule_note_column(xnotecol,k,scheduled_xinc)
      xbuffer:schedule_note_column(xnotecol,k,scheduled_xinc+1)
    end 
  else
    if mute_state then
      xline.note_columns[k] = {}
    end
  end
end
]],
}