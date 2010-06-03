--[[--------------------------------------------------------------------------
TestDocument.lua
--------------------------------------------------------------------------]]--

do
  
  ----------------------------------------------------------------------------
  -- tools
  
  local function assert_error(statement)
    assert(pcall(statement) == false, "expected function error")
  end
  
  
  ----------------------------------------------------------------------------
  -- manual doc creation
  
  local doc = renoise.Document.create()
  local number = doc:add("number_value", 1)
  local number2 = doc:add("number_value2", 2)
  local string_value = doc:add("string_value", "string_value")
  local boolean_value = doc:add("boolean_value", true)
  
  local number_list = doc:add("number_list", { 11, 12, 13})
  local string_list = doc:add("string_list", { "11", "12", "13"})
  local boolean_list = doc:add("boolean_list", { false, false} )
      
  local nested_doc = renoise.Document.create()
  nested_doc:add("sub_number_value", 2)
  nested_doc:add("sub_string_value", "string_value2")
  
  doc:add("sub_node", nested_doc)
  
  
  ----------------------------------------------------------------------------
  -- bogus adds
  
  assert_error(function()
    doc:add("number_value", 1)
  end)
  assert_error(function()
    doc:add("number_list", 1 )
  end)
  assert_error(function()
    doc:add("bogus_list", { false, 1} )
  end)
  assert_error(function()
    doc:add("<bogus_key>", 12)
  end)
  assert_error(function()
    doc:add("bogus key", 12)
  end)
  assert_error(function()
    doc:add("1bogus", 12)
  end)
  
  
  ----------------------------------------------------------------------------
  -- observable value access and serialization
  
  assert(number.value == 1)
  number.value = 123
  assert(number.value == 123)
  assert(tostring(number) == "123")
  
  assert(number:to_string() == "123")
  number:from_string("124")
  assert(number:to_string() == "124")
  
  assert(string_value.value == "string_value")
  string_value.value = "new_string_value"
  assert(string_value.value == "new_string_value")
  assert(tostring(string_value) == "new_string_value")
  
  assert(boolean_value.value == true)
  boolean_value.value = false
  assert(boolean_value.value == false)
  
  
  ----------------------------------------------------------------------------
  -- observable value operators
  
  number.value = 12
  assert(number + 12 == 24)
  assert(number - 12 == 0)
  assert(number * 2 == 24)
  assert(number / 2 == 6)
  assert(number / 2 == 6)
  
  number2.value = 4
  assert(number + number2 == 16)
  
  
  ----------------------------------------------------------------------------
  -- doc member access
  
  local resolved_number = doc.property(doc, "number_value")
  resolved_number.value = 13
  assert(resolved_number.value == 13)
  
  local non_existing_number_value = doc:property("non_existing_number_value")
  assert_error(function()
    non_existing_number_value.value = 21
  end)
  
  doc.number_value.value = 12
  assert(doc.number_value.value == 12)
  
  doc.string_value.value = "foll!"
  assert(doc.string_value.value == "foll!")
  
  assert_error(function()
    resolved_number.unknown_property = 123 
  end)
  
  assert_error(function()
    doc.unknown_property = "something!" 
  end)
   
  assert_error(function() 
    print(doc.unknown_property == "foll!") 
  end)
  
  
  ----------------------------------------------------------------------------
  -- observable list notifiers & list operations
  
  local list_notifications = 0
  local list_notifier = function()
    list_notifications = list_notifications + 1 
  end
  
  number_list:add_notifier(list_notifier)
  
  assert(#number_list == 3)
  while (#number_list ~= 0) do
    number_list:remove()
  end
  
  assert(#number_list == 0)
  assert(list_notifications == 3)
  
  number_list:insert(99)
  assert(number_list:insert(45).value == 45)
  assert(#number_list == 2)
  
  number_list:insert(1, 22)
  assert(number_list[1].value == 22)
  
  number_list:insert(2, 33)
  assert(number_list[2].value == 33)
  
  assert(number_list[3].value == 99)
  assert(number_list[4].value == 45)
  
  number_list[3].value = 999
  
  number_list:remove(1)
  assert(number_list[1].value == 33)
  
  assert(number_list:find(45) == 3)
  assert(not number_list:find(46))
  
  assert(list_notifications == 8)
  
  number_list:remove_notifier(list_notifier)
  
  while (#number_list > 0) do
    number_list:remove()
  end
  
  assert_error(function()
    number_list:remove()
  end)
  number_list:insert(12)
  assert_error(function()
    number_list:remove(2)
  end)
  assert_error(function()
    number_list:remove(0)
  end)
  assert_error(function()
    number_list:insert(0, 66)
  end)
  assert_error(function()
    number_list:insert(3, 66)
  end)
  
  
  while #string_list > 0 do string_list:remove() end
  string_list:insert("olla")
  string_list:insert("wolla")
  assert(string_list[#string_list].value == "wolla")
  
  
  ----------------------------------------------------------------------------
  -- inline doc creation
  
  local doc2 = renoise.Document.create {
    boolean_value = true,
    number = 99,
    string_value = "wer",
    number_list = { 0, 12, 13},
    string_list = { "12", "11"},
    boolean_list = { false },
    sub_node = {
      sub_number = 234,
      sub_string = "weqwer",
      sub_sub_node = {
        boolean_value = false
      }
    },
  }
  
  assert_error(function()
    renoise.Document.create {
      empty_list = {},
    }
  end)
  
  assert_error(function()
    renoise.Document.create {
      ["bogus_key!"] = "value",
    }
  end)
  
  assert(doc2.number.value == 99)
  assert(doc2.string_value.value == "wer")
  assert(doc2.number_list[1].value == 0)
  assert(doc2.number_list[2].value == 12)
  assert(doc2.number_list[3].value == 13)
  assert(#doc2.number_list == 3)
  assert(doc2.string_list[1].value == "12")
  assert(doc2.string_list[2].value == "11")
  assert(#doc2.string_list == 2)
  assert(doc2.boolean_list[1].value == false)
  assert(#doc2.boolean_list == 1)
  assert(doc2.sub_node.sub_number.value == 234)
  assert(doc2.sub_node.sub_string.value == "weqwer")
  assert(doc2.sub_node.sub_sub_node.boolean_value.value == false)
  
  
  ----------------------------------------------------------------------------
  -- XML serialization
  
  local tmp_filename = os.tmpname()
  
  assert(doc2:save_as("TestDocument", tmp_filename))
  assert_error(function()
    assert(doc2:save_as("<TestDocument>", tmp_filename))
  end)
  
  doc2.number.value = 12
  doc2.number_list[3].value = 0
  doc2.sub_node.sub_number.value = 99
  
  assert(doc2:load_from("TestDocument", tmp_filename))
  
  assert_error(function()
    assert(doc2:load_from("Invalid", tmp_filename))
  end)
  
  assert(doc2.number.value == 99)
  assert(doc2.number_list[3].value == 13)
  assert(doc2.sub_node.sub_number.value == 234)
  
  assert(os.remove(tmp_filename))
  
end

------------------------------------------------------------------------------
-- test finalizers

collectgarbage()


--[[--------------------------------------------------------------------------
--------------------------------------------------------------------------]]--

