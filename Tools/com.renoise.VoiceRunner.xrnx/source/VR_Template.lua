--[[============================================================================
VoiceRunner
============================================================================]]--
--[[

Class for working with VoiceRunner templates


The template is a specially formatted table:

  {
    active = bool or nil,         -- when true, skip matching notes
    column_index = int,           -- 
    column_name = string,
    note_value = int,
    instrument_value = int,
    number_of_occurrences = int,  

  }


Could be represented visually like this: 

    On  Name       Note #Occ  Overlaps
        
    [x] Column 01  C-4  8     [Allow v]
    [x] Column 02  C#4  41    [Merge v]
    [x] Column 03  D-4  2     [First v]
 ⚠  [x] Column 04  D#4  0     [Allow v]
 ⚠  [x] Column 05  E-4  0     [Allow v]
    [x] Column 06  F-4  51    [Allow v]
    [x] Column 07  G-4  2     [Allow v]
    [x] Column 08  G#4  5     [Allow v]
 ⚠  [x] Column 09  A-4  0     [Allow v]
    [x] Column 10  A#4  1     [Allow v]
    [x] Column 11  B-4  3     [Allow v]
    [x] Column 12  C-5        [Allow v]
 ⚠  [ ] Column 13  C#5        [Allow v]
 ⚠  [ ] Column 14  D-5        [Allow v]
 ⚠  [ ] Column 15  D#5        [Allow v]


]]


class 'VR_Template'

--------------------------------------------------------------------------------

function VR_Template:__init()

  -- table, list of entries
  self.entries = {}

end

--------------------------------------------------------------------------------

function VR_Template:set(t)

  self.entries = {}
  for k,v in ipairs(t) do
    table.insert(self.entries,v)
  end
  --print("VR_Template:set - self.entries...",rprint(self.entries))

end


--------------------------------------------------------------------------------
-- retrieve matching entries

function VR_Template:get_entries(criteria)
  TRACE("VR_Template:get_entries(criteria)",criteria)

  local rslt,indices = {},{}
  local matched_idx = nil
  local num_criteria = #table.keys(criteria)
  for k,v in ipairs(self.entries) do
    local criteria_count = 0
    for k2,v2 in pairs(criteria) do
      if v[k2] and (v[k2] == v2) then
        matched_idx = k
        criteria_count = criteria_count+1
        --print("matched",v,k,v2,k2)
        if (num_criteria == criteria_count) then
          table.insert(rslt,self.entries[k])
          table.insert(indices,k)
        end
      end
    end
  end
  --print("*** get_entries - rslt...",rprint(rslt))
  --print("*** get_entries - indices...",rprint(indices))

  return rslt,indices

end

--------------------------------------------------------------------------------
-- set entries 

function VR_Template:set_entries(t)
  TRACE("VR_Template:set_entries(t)",t)

end

