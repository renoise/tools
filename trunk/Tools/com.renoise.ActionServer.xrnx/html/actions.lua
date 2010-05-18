~{do L:set_header("Cache-Control", "no-cache, max-age: 3600") end}
~{do
   local depth = 1
   local path = P["path[]"] or {}
   local str = nil
   if P.depth then
      depth = tonumber(P.depth)
   end
   if P.full and P.full ~= "true" then
      local str = unpack(path)
   end
   local tree = ActionTree:get_subtree(str)
   OUT = ActionTree:to_html_list(tree,depth)
 end}