--[[============================================================================
main.lua
============================================================================]]--

--[[

Unit-tests for the xLib library
.
#

TODO 
* capture results from asynchroneous test methods

PLANNED 
* turn tool into simple testrunner framework (class)


]]

_xlib_tests = table.create()
_trace_filters = {".*"}

_clibroot = "source/cLib/classes/"
require (_clibroot.."cLib")
require (_clibroot.."cDebug")
require (_clibroot.."cFilesystem")

_xlibroot = "source/xLib/classes/"
require (_xlibroot.."xLib")

--------------------------------------------------------------------------------
-- test runner
--------------------------------------------------------------------------------

rns = nil 
local view = nil
local vb = renoise.ViewBuilder()

TEST_STATUS = {
  RUNNING = "Running...",
  PASSED = "Passed",
  FAILED = "Failed",
}

--------------------------------------------------------------------------------

local execute_test = function(idx,test)

  local status_elm = vb.views["test_status_"..idx]
  local status_elm_err = vb.views["test_status_err_"..idx]

  test.status = TEST_STATUS.RUNNING
  status_elm.text = test.status

  local passed,err = pcall(test.fn) 
  --local passed = true
  --fn()
  if passed then
    test.status = TEST_STATUS.PASSED
    test.error = ""
  else
    test.status = TEST_STATUS.FAILED
    test.error = err
    print("*** "..err)
  end

  status_elm.text = test.status
  status_elm_err.text = test.error


end



--------------------------------------------------------------------------------

local show_dialog = function()
  renoise.app():show_custom_dialog("xLib unit-tests", view)
end

--------------------------------------------------------------------------------

local initialize = function()

  rns = renoise.song()

  if view then
    show_dialog()
    return
  end

  -- include all lua files in unit test
  for __, filename in pairs(os.filenames(_xlibroot.."unit_tests")) do
    local folder,fname,extension = cFilesystem.get_path_parts(filename)
    if (extension == "lua") then
      local fname = cFilesystem.file_strip_extension(fname,extension)
      require (_xlibroot.."unit_tests/"..fname)
    end
  end

  print(">>> _xlib_tests...",rprint(_xlib_tests))

  -- present as list
  local CB_W = 20
  local NAME_W = 100
  local RUN_TEST_BT_W = 80
  local STATUS_W = 100

  view = vb:column{
    margin = 6,
    vb:row{
      vb:checkbox{
        width = CB_W,
        value = true,
        notifier = function(val)
          for k = 1,#_xlib_tests do
            local cb_elm = vb.views["test_cb_"..k]
            cb_elm.value = val
          end
        end
      },
      vb:text{
        text = "Name",
        font = "bold",
        width = NAME_W,
      },
      vb:text{
        text = "Run test",
        font = "bold",
        width = RUN_TEST_BT_W,
      },
      vb:text{
        text = "Status",
        font = "bold",
        width = STATUS_W,
      }
    }
  }
  for k,v in ipairs(_xlib_tests) do
    view:add_child(vb:row{
      vb:checkbox{
        id = "test_cb_"..k,
        value = true,
        width = CB_W
      },
      vb:text{
        text = v.name,
        width = NAME_W,
      },
      vb:button{
        text = "Run tests",
        width = RUN_TEST_BT_W,
        notifier = function()
          execute_test(k,v)
        end
      },
      vb:checkbox{
        visible = false,
        --value = true,
        notifier = function()
          local status_elm_err = vb.views["test_status_err_"..k]
          if (status_elm_err.text ~= "") then
            renoise.app():show_message(status_elm_err.text)
          end
        end
      },
      vb:text{
        id = "test_status_"..k,
        text = "(not set)",
        width = STATUS_W,
      },
      vb:text{
        visible = false,
        id = "test_status_err_"..k,
      }
    })
  end

  view:add_child(vb:space{
    height = 6
  })

  view:add_child(vb:row{
    vb:button{
      id = "test_all_bt",
      text = "Run all selected tests",
      width = 100,
      height = 24,
      notifier = function()
        for k = 1,#_xlib_tests do
          local cb_elm = vb.views["test_cb_"..k]
          if cb_elm.value then
            execute_test(k,_xlib_tests[k])
          end
        end
      end
    }
  })

  show_dialog()

end

--------------------------------------------------------------------------------
-- menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:xLib",
  invoke = function()
    initialize()
  end  
}

--------------------------------------------------------------------------------
-- notifications
--------------------------------------------------------------------------------

renoise.tool().app_new_document_observable:add_notifier(function()
  rns = renoise.song()
end)
