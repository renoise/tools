--[[============================================================================
xRuleset
============================================================================]]--

--[[--

This is a supporting class for xRules
.
#

### See also
@{xRules}
@{xRule}

]]

require (_clibroot.."cFilesystem")

class 'xRuleset'

xRuleset.DEFAULT_NAME = "Untitled ruleset"
xRuleset.CURRENT_RULESET = "Current Ruleset"

-------------------------------------------------------------------------------
-- @param xrules (xRules) owner
-- @param ruleset_def (table), optional
--  {
--    name = "Name of Ruleset",
--    active = false,
--    osc_enabled = false,
--    {rule_def},{rule_def},{...} -- see xRule 
--  }

function xRuleset:__init(xrules,ruleset_def)

  if not ruleset_def then
    ruleset_def = {{}} -- add empty rule
  end

  --- xRules
  self.xrules = xrules

  --- string, name of this ruleset (derived from file_path)
  self.name = property(self.get_name,self.set_name)
  self.name_observable = renoise.Document.ObservableString("")

  --- string, description of this ruleset
  self.description = property(self.get_description,self.set_description)
  self.description_observable = renoise.Document.ObservableString("")

  --- boolean, make rules able to specify an osc pattern
  self.osc_enabled = property(self.get_osc_enabled,self.set_osc_enabled)
  self.osc_enabled_observable = renoise.Document.ObservableBoolean(false)

  --- boolean, when true the voice-manager is enabled for this set
  self.manage_voices = property(self.get_manage_voices,self.set_manage_voices)
  self.manage_voices_observable = renoise.Document.ObservableBoolean(false)

  --- array containing xRule instances
  self.rules = {}
  self.rules_observable = renoise.Document.ObservableNumberList()

  --- boolean, suppress while adding/removing/swapping
  self.suppress_notifier = false

  -- runtime properties --

  --- boolean
  self.modified = property(self.get_modified,self.set_modified)
  self.modified_observable = renoise.Document.ObservableBoolean(false)

  --- boolean, when false the ruleset should be ignored
  self.active = property(self.get_active,self.set_active)
  self.active_observable = renoise.Document.ObservableBoolean(true)

  --- int, selected rule 
  self.selected_rule_index = property(self.get_selected_rule_index,self.set_selected_rule_index)
  self.selected_rule_index_observable = renoise.Document.ObservableNumber(1)

  --- string, full path to location on disk
  self.file_path = property(self.get_file_path,self.set_file_path)
  self.file_path_observable = renoise.Document.ObservableString("")

  --- int, last inserted rule (when registering with router/map)
  -- 
  --self.last_inserted = nil

  -- initialize --

  self:parse_definition(ruleset_def)


end

--==============================================================================
-- Getters and setters 
--==============================================================================

function xRuleset:get_name()
  return self.name_observable.value
end

function xRuleset:set_name(val)
  local modified = (val~=self.name_observable.value)
  self.name_observable.value = val
  if modified then
    self.modified = true
  end
end

-------------------------------------------------------------------------------

function xRuleset:get_description()
  --TRACE("xRuleset:get_description",self.description_observable.value)
  return self.description_observable.value
end

function xRuleset:set_description(val)
  --TRACE("xRuleset:set_description",val,self.description_observable.value)
  local modified = (val~=self.description_observable.value)
  self.description_observable.value = val
  if modified then
    self.modified = true
  end
end

-------------------------------------------------------------------------------

function xRuleset:get_osc_enabled()
  return self.osc_enabled_observable.value
end

function xRuleset:set_osc_enabled(val)
  local modified = (val~=self.osc_enabled_observable.value)
  self.osc_enabled_observable.value = val
  if modified then
    self.modified = true
  end
end

-------------------------------------------------------------------------------

function xRuleset:get_manage_voices()
  return self.manage_voices_observable.value
end

function xRuleset:set_manage_voices(val)
  TRACE("xRuleset:set_manage_voices(val)",val)
  local modified = (val~=self.manage_voices_observable.value)
  self.manage_voices_observable.value = val
  if modified then
    self.modified = true
  end
end

-------------------------------------------------------------------------------

function xRuleset:get_modified()
  return self.modified_observable.value
end

function xRuleset:set_modified(val)
  self.modified_observable.value = val
end

--------------------------------------------------------------------------------

function xRuleset:get_active()
  return self.active_observable.value
end

function xRuleset:set_active(val)
  self.active_observable.value = val
end

--------------------------------------------------------------------------------

function xRuleset:get_selected_rule_index()
  return self.selected_rule_index_observable.value
end

function xRuleset:set_selected_rule_index(val)
  --TRACE("xRuleset:set_selected_rule_index(val)",val)
  self.selected_rule_index_observable.value = val
end

--------------------------------------------------------------------------------

function xRuleset:get_file_path()
  return self.file_path_observable.value
end

function xRuleset:set_file_path(val)
  self.file_path_observable.value = val
end

--==============================================================================
-- Class methods
--==============================================================================

function xRuleset:add_rule(rule_def,idx)

  if not idx then
    idx = #self.rules + 1
  end

  --self.suppress_notifier = true

  local xrule = xRule(rule_def)
  table.insert(self.rules,idx,xrule)
  self.rules_observable:insert(idx,1)
  --self.last_inserted = idx
  --self.xrules.osc_router:add_pattern(xrule.osc_pattern)
  self:attach_to_rule(idx)
  self.modified = true

  --self.suppress_notifier = false

end

-------------------------------------------------------------------------------
--- rename a ruleset - will attempt to rename the file itself
-- @param new_name (string) 
-- @return boolean,string 

function xRuleset:rename(new_name)

  if not cFilesystem.validate_filename(new_name) then
    return false, "The name contains illegal characters"
  end

  local old_path = cFilesystem.get_path_parts(self.file_path)
  local new_filepath = cFilesystem.unixslashes(("%s/%s.lua"):format(old_path,new_name))

  if io.exists(new_filepath) then
    return false,"A file already exist with that name"
  end

  local passed,err = cFilesystem.rename(self.file_path,new_filepath)  
  if not passed then
    return false,err
  end

  self.name = new_name
  self.file_path = new_filepath

  return true

end

-------------------------------------------------------------------------------
-- remove a rule from this set

function xRuleset:remove_rule(idx)

  local rule = self.rules[idx]
  if not rule then
    local err = ("Could not remove rule with index #%d- it doesn't exist"):format(idx)
    return false,err
  end

  table.remove(self.rules,idx)
  self.rules_observable:remove(idx)

  self.modified = true

  return true

end

-------------------------------------------------------------------------------
-- @return string, a display name such as "Rule #01"

function xRuleset:get_rule_name(rule_idx)

  assert(type(rule_idx)=="number", "Expected number as argument")

  local xrule = self.rules[rule_idx]
  if (xrule.name == "") then
    return string.format("Rule #%.2d",rule_idx)
  else
    return xrule.name
  end

end

-------------------------------------------------------------------------------
-- get rule by name, including display names
-- @return xRule,int(index) or nil

function xRuleset:get_rule_by_name(str_name)

  for k,v in ipairs(self.rules) do
    local rule_name = self:get_rule_name(k)
    if (rule_name == str_name) then
      return v,k
    end

  end

end

-------------------------------------------------------------------------------
-- pass message into rules, invoke callback when matched
-- @param xmsg (xMidiMessage or xOscMessage)
-- @param ruleset_idx (int), passed back to callback
-- @param rule_idx (int), only check this rule (optional) 
-- @param force_midi (boolean) force match (used by routings)
-- @return 
--  table<xMidiMessage or xOscMessage>
--  xMidiMessage or xOscMessage (original message)

function xRuleset:match_message(xmsg,ruleset_idx,rule_idx,force_midi)

  assert(type(ruleset_idx)=="number","Expected ruleset_idx to be a number")

  local function do_match(rule,rule_idx)
    if not force_midi and (not rule.midi_enabled 
      and (type(xmsg)=="xMidiMessage"))
    then
      return
    end
    local output,evaluated = rule:match(xmsg,self.xrules,ruleset_idx)
    if evaluated then
      for _,v in ipairs(output) do
        self.xrules:transmit(v,xmsg,ruleset_idx,rule_idx)
      end
    end
  end

  if rule_idx then -- single rule 
    do_match(self.rules[rule_idx],rule_idx)
  else 
    for idx,rule in ipairs(self.rules) do
      do_match(rule,idx)
    end
  end

end

-------------------------------------------------------------------------------
-- compile each of the rules within this set

function xRuleset:compile()
  --TRACE("xRuleset:compile()")

  for k,rule in ipairs(self.rules) do
    local passed,err = rule:compile()
    if err then
      LOG(err)
    end 
  end

end

-------------------------------------------------------------------------------
-- @param ruleset_def (table)
-- @return boolean, true when passed
-- @return string, error message when failed

function xRuleset:parse_definition(ruleset_def)

  self.rules = {}
  for k = #self.rules_observable,1,-1 do
    self.rules_observable:remove(k)
  end
  self.suppress_notifier = true
  self.osc_enabled_observable.value = ruleset_def.osc_enabled or false
  self.manage_voices_observable.value = ruleset_def.manage_voices or false
  self.active_observable.value = ruleset_def.active or true
  self.description_observable.value = ruleset_def.description or ""

  for k,v in ipairs(ruleset_def) do
    -- TODO implement a "looks like rule" 
    self:add_rule(v)
  end

  self.suppress_notifier = false
  return true

end

-------------------------------------------------------------------------------
-- @return boolean, true when file was succesfully loaded
-- @return err, string containing error message

function xRuleset:load_definition(file_path)

  assert(type(file_path) == "string","Expected a string as argument")
  assert(file_path ~= "","Expected a non-empty string as argument")

  local str_def,err = cFilesystem.load_string(file_path)
  if not str_def then
    return false,err
  end

  local passed = xRuleset.looks_like_definition(str_def)
  if not passed then
    return false,("The file %s does not look like a ruleset definition"):format(file_path)
  end

  -- check if we are able to load the definition
  local passed,err = pcall(function()
    assert(loadfile(file_path))
  end) 
  if not passed then
    err = "ERROR: Failed to load the definition '"..file_path.."' - "..err
    return false,err
  end

  local def = assert(loadfile(file_path))()
  local passed,err = self:parse_definition(def)
  if not passed then
    err = "ERROR: Failed to load the definition '"..file_path.."' - "..err
    return false,err
  end

  self.name = cFilesystem.get_raw_filename(file_path)
  self.file_path = file_path

  return true

end

-------------------------------------------------------------------------------
-- serialize entire ruleset
-- @return string

function xRuleset:serialize()

  local str = ""
  str = "-----------------------------------------------------------"
      .."\n-- Ruleset definition for xRules"
      .."\n-- More info @ http://www.renoise.com/tools/xrules"
      .."\n-----------------------------------------------------------"
      .."\nreturn {"
      .."\nosc_enabled = "..tostring(self.osc_enabled).. ","
      .."\nmanage_voices = "..tostring(self.manage_voices).. ","
      .."\ndescription = \""..cLib.serialize_object(self.description).. "\","
      .."\n"

  for k,v in ipairs(self.rules) do
    str = str .. v:serialize()
    if (self.rules[k+1]) then
      str = str .. ",\n"
    end
  end

  str = str.."\n}"

  return str

end

-------------------------------------------------------------------------------
-- save the definition to a file 
-- note: saving the definition will NOT update the file_path property,
--  so you can safely use this method to export a ruleset 
-- 
-- @param file_path, path to file (optional)
-- @return boolean, true when succesfully saved
-- @return string, error message when failed

function xRuleset:save_definition(file_path)

  if not file_path then
    file_path = self.file_path
  end

  local str_def = self:serialize()
  local passed,err = cFilesystem.write_string_to_file(file_path,str_def)
  if not passed then
    return false,err
  end

  return true

end

-------------------------------------------------------------------------------

function xRuleset:attach_to_rule(rule_idx)

  local xrule = self.rules[rule_idx]
  xrule.modified_observable:add_notifier(function()
    self.modified = true
  end)

end

-------------------------------------------------------------------------------

function xRuleset:__tostring()

  return type(self)
    .. ", name:"..tostring(self.name)
    .. ", osc_enabled:"..tostring(self.osc_enabled)
    .. ", manage_voices:"..tostring(self.manage_voices)
    .. ", modified:"..tostring(self.modified)
    .. ", active:"..tostring(self.active)
    .. ", file_path:"..tostring(self.file_path)
    .. ", description:"..tostring(self.description)

end


-------------------------------------------------------------------------------
-- Static methods
-------------------------------------------------------------------------------
-- ensure that a definition is "likely" valid before loading 
-- @return boolean

function xRuleset.looks_like_definition(str_def)

  if not string.find(str_def,"return[%s]*{") or
    not string.find(str_def,"\[?\"?actions\]?\"?[%s]*=[%s]*{") or
    not string.find(str_def,"\[?\"?conditions\]?\"?[%s]*=[%s]*{") 
  then
    return false
  else
    return true
  end

end

-------------------------------------------------------------------------------
-- ensure that the name is unique (among the saved files)

function xRuleset.get_suggested_name(str_name)

  if not str_name then
    str_name = xRuleset.DEFAULT_NAME
  end

  local file_path = xRuleset.get_normalized_file_path(str_name)
  local str_path = cFilesystem.ensure_unique_filename(file_path)
  local suggested_name = cFilesystem.get_raw_filename(str_path)
  return suggested_name

end

-------------------------------------------------------------------------------
-- return the path to the internal models 

function xRuleset.get_normalized_file_path(str_name)

  return ("%s%s.lua"):format(xRules.RULESET_FOLDER,str_name)

end


