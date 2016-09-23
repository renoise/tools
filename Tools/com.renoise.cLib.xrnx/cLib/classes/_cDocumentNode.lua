--[[============================================================================
cDocumentNode
============================================================================]]--

--[[--

This class represents a single document node
.
#

]]


class 'cDocumentNode' (cValue)


function cDocumentNode:__init(...)

  local args = cLib.unpack_args(...)

  --- string, machine-readable (lowercase, no spaces...)
  self.name = args.name or ""

  --- string, human readable version
  self.title = args.title or ""

  -- initialize --

  cValue.__init(self,...)

end

