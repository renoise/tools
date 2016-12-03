--[[============================================================================
vTable 
============================================================================]]--

--[[

  As the name suggests, this class provides data to widgets. 

  The data is an indexed table containing associative tables - each entry
  contain whatever you specific _plus_ meta-properties (item ID). 


--]]

class 'vDataProvider'

vDataProvider.ID   = "item_id"

function vDataProvider:__init(...)

  local args = cLib.unpack_args(...)

  --- (table) indexed table 
  self.data = property(self.get_data,self.set_data)
  self._data = args.data or {}

  --- (table) access items by ID
  -- Entries look like this: [item_id] = {item = <table>, index = <int>}
  self.map = {}


end

--------------------------------------------------------------------------------
-- retrieve an item by it's ID 
-- @param item_id (int)
-- @return table or nil 
-- @return int, index 

function vDataProvider:get(item_id)
  TRACE("vDataProvider:get(item_id)",item_id)

  if self.map[item_id] then
    return self.map[item_id].item,self.map[item_id].index
  else
    local item,index = vVector.match_by_key_value(self.data,vDataProvider.ID,item_id)
    self.map[item_id] = {
      item = item,
      index = index
    }
    return item,index
  end

end

--------------------------------------------------------------------------------

function vDataProvider:get_data()
  return self._data
end


function vDataProvider:set_data(data)

  if (type(data)~="table") then
    LOG("*** vDataProvider.set_data() - only tables are accepted as data")
    return 
  end

  if not table.is_empty(data) then
    for i=1, #data do
      data[i][vDataProvider.ID] = 1000+i
    end
  end

  self.map = {}
  self._data = data

end

--------------------------------------------------------------------------------


