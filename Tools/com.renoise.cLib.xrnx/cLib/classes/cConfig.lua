--[[============================================================================
-- cConfig
============================================================================]]--

--[[--

Static methods for accessing with the Renoise config file
.
#

]]

--==============================================================================

require (_clibroot.."cFilesystem")
require (_clibroot.."cParseXML")

class 'cConfig'

-- table, Config.xml (parsed)
cConfig.xml = nil


-------------------------------------------------------------------------------

function cConfig.load_config()

  local config_fpath = cFilesystem.get_userdata_folder().."Config.xml"
  print("config_fpath",config_fpath)

  cConfig.xml = cParseXML.load_and_parse(config_fpath)
  print("cConfig.xml",cConfig.xml)

end

-------------------------------------------------------------------------------
-- retrieve a property from the config file
-- @return string or nil
--[[
function cConfig.get_property(xpath)
  TRACE("cConfig.get_property(xpath)",xpath)

  if not cConfig.xml then
    cConfig.load_config()
  end

  local node = cParseXML.get_node_by_path(cConfig.xml,xpath)
  local val = cParseXML.get_node_value(node)
  return val

end
]]
-------------------------------------------------------------------------------
-- retrieve a property value from the config file
-- @return string or nil

function cConfig.get_value(xpath)
  TRACE("cConfig.get_value(xpath)",xpath)

  if not cConfig.xml then
    cConfig.load_config()
  end

  local node = cParseXML.get_node_by_path(cConfig.xml,xpath)
  if node then
    local val = cParseXML.get_node_value(node)
    return val
  end

end


