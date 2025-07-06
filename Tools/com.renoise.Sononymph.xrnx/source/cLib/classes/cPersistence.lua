--[[===============================================================================================
-- cPersistence
===============================================================================================]]--

--[[--

Add the ability to store a class as serialized data 
.

# How to use 

First, extend your class, e.g. 
```
class 'MyClass' (cPersistence)
```

Next, choose how to/which properties to persist 

  Method 1: Automatic (let cPersistence do the work)
  
    With this approach, you need to define a special __PERSISTENCE property. 
    MyClass.__PERSISTENCE = {"foo","bar"}

  Method 2: Define how to obtain and assign properties manually 

    Specify (override) the following methods: 
    cPersistence:obtain_definition()
    cPersistence:assign_definition()

Finally, you can override the serialize method as well, in case you want to 
customize the resulting string. 


--]]

--=================================================================================================

require (_clibroot.."cTable")
require (_clibroot.."cReflection")

class 'cPersistence'

---------------------------------------------------------------------------------------------------
-- load serialized string from disk
-- @return boolean, true when loading succeeded
-- @return string, when an error occurred

function cPersistence:load(file_path)
  TRACE("cPersistence:load(file_path)")

  assert(type(file_path)=="string")
  
  -- confirm that file is valid
  local str_def,err = cFilesystem.load_string(file_path)
  --print(">>> load_definition - load_string - str_def,err",str_def,err)
  local passed = self:looks_like_definition(str_def)
  if not passed then
    return false,("The file '%s' does not look like a definition"):format(file_path)
  end
  
  -- load the definition
  local passed,err = pcall(function()
    assert(loadfile(file_path))
  end) 
  if not passed then
    err = "*** Error: Failed to load the definition '"..file_path.."' - "..err
    return false,err
  end
  
  local def = assert(loadfile(file_path))()
  self:assign_definition(def)
  
end

---------------------------------------------------------------------------------------------------
-- save serialized string to disk 
-- @return boolean, true when loading succeeded
-- @return string, when an error occurred

function cPersistence:save(file_path)
  TRACE("cPersistence:save(file_path)",file_path)

  assert(type(file_path)=="string")
  
  local got_saved,err = cFilesystem.write_string_to_file(file_path,self:serialize())
  if not got_saved then
    return false,err
  end

  return true

end

---------------------------------------------------------------------------------------------------
-- @return string 

function cPersistence:serialize()
  TRACE("cPersistence:serialize()")

  return cLib.serialize_table(self:obtain_definition())

end

---------------------------------------------------------------------------------------------------
-- assign definition to class 
-- @param def (table)
-- @param ref (object), where to assign values - 'self' if undefined
-- @param _prop_names (table), 

function cPersistence:assign_definition(def,_ref,_prop_names)
  TRACE("cPersistence:assign_definition(def,_ref,_prop_names)",def,_ref,_prop_names)

  assert(type(def)=="table")
  
  -- assign to persisted object 
  -- (first check if the type is available in global scope)
  local create_class_instance = function(def,cname)
    --print(">>> create_class_instance",def,cname)
    if not rawget(_G,cname) then 
      renoise.app():show_warning(        
        ("Could not instantiate: unknown class '%s'"):format(cname))
    else
      local ref = _G[cname]()
      ref:assign_definition(def)
      return ref
    end
  end

  -- check if persisted object? note: only possible for nested entries,
  -- we can't change the fundamental type of class from within
  local cname = cPersistence.get_persisted_type(def)
  --print("cname",cname)
  if _ref and cname then 
    return create_class_instance(def,cname)
  end 

  -- defined when recursing
  _ref = _ref and _ref or self 
  _prop_names = _prop_names and _prop_names or self.__PERSISTENCE
  --print("_ref,_prop_names",_ref,rprint(_prop_names))

  for _,prop_name in ipairs(_prop_names) do 
    --print(">>> assign_definition - prop_name",prop_name)
    local prop_def = def[prop_name]
    local cname = cPersistence.get_persisted_type(prop_def)
    if cname then 
      --print(">>> looks like a persisted object",prop_name,cname)
      _ref[prop_name] = create_class_instance(prop_def,cname)
    else
      if (type(prop_def)=="table" and cTable.is_indexed(prop_def)) then 
        --print(">>> table assignment",prop_name,prop_def)
        _ref[prop_name] = {}
        for k,v in ipairs(prop_def) do 
          -- pass an empty table as reference - this indicates that we are recursing
          -- also, when recursing make sure we stay within the cPersistence scope 
          -- (a class that have extended this one might have overridden the method)
          local table_item_def = {}
          table_item_def = cPersistence.assign_definition(self,v,table_item_def,table.keys(v))
          --print("table_item_def",table_item_def)
          table.insert(_ref[prop_name],table_item_def)
        end
      else
        --print(">>> plain assignment",prop_name,prop_def)
        _ref[prop_name] = prop_def
      end
    end
  end

  return _ref

end  

---------------------------------------------------------------------------------------------------
-- look for certain "things" to confirm that this is a valid definition
-- @param str_def (string)
-- @return bool

function cPersistence:looks_like_definition(str_def)
  TRACE("cPersistence:looks_like_definition(str_def)",str_def)

  assert(type(str_def)=="string")
  
  local pre = '\[?\"?'
  local post = '\]?\"?[%s]*=[%s]'

  for _,prop_name in ipairs(self.__PERSISTENCE) do 
    if not string.find(str_def,pre..prop_name..post) then
      return false
    end
  end
  return true

end

---------------------------------------------------------------------------------------------------
-- obtain a (serializable) table representation of the class
-- note: override this method to define your own implementation 
-- @return table 

function cPersistence:obtain_definition()
  TRACE("cPersistence:obtain_definition()")

  -- core properties (always present)
  local def = {
    __type = type(self),
  }

  for _,prop_name in ipairs(self.__PERSISTENCE) do 
    local prop_def = cPersistence.obtain_property_definition(self[prop_name],prop_name)
    if prop_def then 
      def[prop_name] = prop_def
    end
  end
  return def

end

---------------------------------------------------------------------------------------------------

function cPersistence.obtain_property_definition(prop,prop_name)
  TRACE("cPersistence.obtain_property_definition(prop,prop_name)",prop,prop_name)

  local def = {}
  if cReflection.is_serializable_type(prop) then
    if (type(prop)=="table") then 
      -- distinguish between indexed and associative tables 
      if cTable.is_indexed(prop) then 
        -- make sure to take a recursive copy
        --def[prop_name] = table.rcopy(prop)
        --def = table.rcopy(prop)

        for k,v in ipairs(prop) do
          local table_prop_def = cPersistence.obtain_property_definition(v,k)
          if table_prop_def then 
            def[k] = table_prop_def
          end          
        end   

      else
        -- associative array ("object")
        for k,v in pairs(prop) do
          local table_prop_def = cPersistence.obtain_property_definition(v,k)
          if table_prop_def then 
            def[k] = table_prop_def
          end          
        end        
      end
    else
      -- primitive value (bool, string, number)
      def = prop
    end
  else 
    -- check if instance of cPersistence
    if prop.__PERSISTENCE and prop.obtain_definition then 
      def = prop:obtain_definition()
    else 
      LOG("Warning: this property is not serializable:",prop_name)
    end
  end
  return def

end

---------------------------------------------------------------------------------------------------
-- check if the provided definition refers to a persisted object 
-- @param def (table)
-- @return string or nil 

function cPersistence.get_persisted_type(def)
  --TRACE("cPersistence:get_persisted_type(def)",def)

  return type(def)=="table" and def.__type

end

---------------------------------------------------------------------------------------------------
-- attempt to determine type from first occurrence of '__type' in the file 
-- @return string or nil 

function cPersistence.determine_type(fpath)
  TRACE("cPersistence.determine_type(fpath)",fpath)

  assert(type(fpath)=="string")

  local str_def,err = cFilesystem.load_string(fpath)
  if err then 
    return false,err
  end 

  local first = string.find(str_def,"__type")
  local match = string.match(str_def.sub(str_def,first),' = "(%a+)"')
  --print(match)  

  return match

end
