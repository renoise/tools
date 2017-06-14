--[[===============================================================================================
xStreamStacks
===============================================================================================]]--
--[[

This class handles model stacks for xStream 

]]

--=================================================================================================

class 'xStreamStacks'

xStreamStacks.DEFAULT_NAME = "Untitled stack"
xStreamStacks.FOLDER_NAME = "stacks/"
xStreamStacks.ROOT_PATH = renoise.tool().bundle_path..xStreamStacks.FOLDER_NAME

function xStreamStacks:__init(xstream)
  TRACE("xStreamStacks:__init(xstream)",xstream)

  assert(type(xstream) == "xStream")

  --- xStream - still required by model. Otherwise would use just process..
  self.xstream = xstream

  --- table<string>
  self.available_stacks = {}

  --- int, the stack index, 1-#stacks or 0 when none are available
  self.selected_stack_index = property(self.get_selected_stack_index,self.set_selected_stack_index)
  self.selected_stack_index_observable = renoise.Document.ObservableNumber(0)

  --- xStreamStack, read-only - can be nil
  self.selected_stack = property(self.get_selected_stack)

    --- table<xStreamStack>, registered stacks 
  self.stacks = {}

  --- table<int>, receive notification when stacks are added/removed
  -- the table itself contains just the stack indices
  self.stacks_observable = renoise.Document.ObservableNumberList()

end

---------------------------------------------------------------------------------------------------
-- Get/set
---------------------------------------------------------------------------------------------------

function xStreamStacks:get_selected_stack()
  return self.stacks[selected_stack_index]
end

function xStreamStacks:get_selected_stack_index()
  return self.selected_stack_index_observable.value
end

function xStreamStacks:set_selected_stack_index(idx)
  self.selected_stack_index_observable.value = idx
end


---------------------------------------------------------------------------------------------------
-- Class methods 
---------------------------------------------------------------------------------------------------
-- @param stack_name (string)
-- @return int (index) or nil
-- @return xStreamStack or nil

function xStreamStacks:get_by_name(stack_name)
  TRACE("xStreamStacks:get_by_name(stack_name)",stack_name)

  if not self.stacks then
    return 
  end

  for k,v in ipairs(self.stacks) do
    if (v.name == stack_name) then
      return k,v
    end
  end

end


---------------------------------------------------------------------------------------------------
-- Create new stack from scratch
-- @param str_name (string)
-- @return bool, true when stack got created
-- @return string, error message on failure

function xStreamStacks:create(str_name)
  TRACE("xStreamStacks:create(str_name)",str_name)

  assert(type(str_name) == "string")

  local stack = xStreamStack(self.stack)
  stack.name = str_name

  local str_name_validate = xStreamStack.get_suggested_name(str_name)
  --print(">>> str_name,str_name_validate",str_name,str_name_validate)
  if (str_name ~= str_name_validate) then
    return false,"*** Error: a stack already exists with this name."
  end

  stack.modified = true
  stack.name = str_name
  stack.file_path = ("%s%s.lua"):format(xStreamStacks.ROOT_PATH,str_name)

  self:add(stack)
  
  local got_saved,err = stack:save()
  if not got_saved and err then
    return false,err
  end

  return true

end

---------------------------------------------------------------------------------------------------
-- Register a stack 
-- @param stack, xStreamStack

function xStreamStacks:add(stack)
  TRACE("xStreamStacks:add(stack)")

  table.insert(self.stacks,stack)
  self.stacks_observable:insert(#self.stacks)

end

---------------------------------------------------------------------------------------------------
-- Remove all stacks

function xStreamStacks:remove_all()
  TRACE("xStreamStacks:remove_all()")

  for k,_ in ripairs(self.stacks) do
    self:remove_stack(k)
  end 


end

---------------------------------------------------------------------------------------------------
-- Remove specific stack from list
-- @param stack_idx (int)

function xStreamStacks:remove_stack(stack_idx)
  TRACE("xStreamStacks:remove_stack(stack_idx)",stack_idx)

  table.remove(self.stacks,stack_idx)
  self.stacks_observable:remove(stack_idx)

end

---------------------------------------------------------------------------------------------------
-- Delete from disk, then remove from list
-- @param stack_idx (int)
-- @return bool, true when we deleted the file
-- @return string, error message when failed

function xStreamStacks:delete_stack(stack_idx)
  TRACE("xStreamStacks:delete_stack(stack_idx)",stack_idx)

  local stack = self.stacks[stack_idx]
  local success,err = os.remove(stack.file_path)
  if not success then
    return false,err
  end

  self:remove_stack(stack_idx)

  return true

end

---------------------------------------------------------------------------------------------------
-- Index all stacks (files ending with .lua) in a given folder
-- log potential errors during parsing

function xStreamStacks:scan_for_available(str_path)
  TRACE("xStreamStacks:scan_for_available(str_path)",str_path)

  assert(type(str_path)=="string","Expected string as argument")

  if not io.exists(str_path) then
    LOG("*** Could not open stack, folder does not exist:"..str_path)
    return
  end

  local log_msg = ""
  for _, filename in pairs(os.filenames(str_path, "*.lua")) do

    table.insert(self.available_stacks,filename)

  end

  if (log_msg ~= "") then
     LOG(log_msg.."*** WARNING One or more stack failed to load during startup")
  end

end

---------------------------------------------------------------------------------------------------
-- @param no_asterisk (bool), don't add asterisk to modified stacks
-- return table<string>

function xStreamStacks:get_available(no_asterisk)
  TRACE("xStreamStacks:get_available(no_asterisk)",no_asterisk)

  return table.copy(self.available_stacks)

  --[[
  local t = {}
  for _,v in ipairs(self.stacks) do
    if no_asterisk then
      table.insert(t,v.name)
    else
      table.insert(t,v.modified and v.name.."*" or v.name)
    end
  end
  return t
  ]]

end

