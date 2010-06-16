-------------------------------------------------------------------------------
--  Requires
-------------------------------------------------------------------------------

require "renoise.http"


-------------------------------------------------------------------------------
--  Menu registration
-------------------------------------------------------------------------------

local entry = {}

entry.name = "Main Menu:Tools:Check Version..."
entry.active = function() return true end
entry.invoke = function() update_start() end
renoise.tool():add_menu_entry(entry)


-------------------------------------------------------------------------------
--  Main functions
-------------------------------------------------------------------------------

function update_start()
  -- Renoise Version Check; using HTTP Header "User-Agent"
  HTTP:post("http://www.renoise.com/download/checkversion.php", {output="raw"},
    function(res, err)
      if (res) then
        local buttons = table.create{"OK", "Go to downloads"}
        local choice = renoise.app():show_prompt(
          "Checking for Renoise updates",
          table.concat(res), buttons)
        if (choice == buttons[2]) then
          renoise.app():open_url("http://www.renoise.com/download/renoise/")
        end
      end
    end)
end
