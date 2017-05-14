
class 'xLibTool' (vDialog)

TEST_STATUS = {
  RUNNING = "Running...",
  PASSED = "Passed",
  FAILED = "Failed",
}

--------------------------------------------------------------------------------

function xLibTool:__init(...)

  -- when extending a class, it's constructor needs to be called
  -- we also pass the arguments (...) along to the vDialog constructor 
  vDialog.__init(self,...)

  self.vb = renoise.ViewBuilder()

  -- include all lua files in unit test
  local include_path = renoise.tool().bundle_path.."unit_tests" 
  print(">>> include_path",include_path)
  for __, filename in pairs(os.filenames(include_path)) do
    local folder,fname,extension = cFilesystem.get_path_parts(filename)
    if (extension == "lua") then
      local fname = cFilesystem.file_strip_extension(fname,extension)
      require ("unit_tests/"..fname)
    end
  end

  print(">>> included xlib_tests...",rprint(_xlib_tests))

  self:build()

end

-------------------------------------------------------------------------------
-- methods required by vDialog
-------------------------------------------------------------------------------
-- return the UI which was previously created with build()

function xLibTool:create_dialog()
  TRACE("xLibTool:create_dialog()")

  return self.vb:column{
    self.vb_content,
  }

end

--------------------------------------------------------------------------------
-- Test runner 
--------------------------------------------------------------------------------

function xLibTool:execute_test(idx,test)

  local vb = self.vb

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

function xLibTool:build()

  local vb = self.vb
  local view = nil

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
          self:execute_test(k,v)
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
            self:execute_test(k,_xlib_tests[k])
          end
        end
      end
    },
    vb:checkbox{
      bind = renoise.tool().preferences.autostart
    },
    vb:text{
      text = "Autostart tool"
    }
  })

  self.vb_content = view

end

