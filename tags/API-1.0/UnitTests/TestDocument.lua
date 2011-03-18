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
  
  local doc = renoise.Document.create("TestDocument"){}

  local number, string_value, boolean_value
  local number_list, string_list, boolean_list
  
  if ((math.random(4) % 2 == 0)) then
    number = doc:add_property("number_value", 1)
    string_value = doc:add_property("string_value", "string_value")
    boolean_value = doc:add_property("boolean_value", true)
  else
    number = doc:add_property("number_value", 
      renoise.Document.ObservableNumber(1))
    string_value = doc:add_property("string_value", 
      renoise.Document.ObservableString("string_value"))
    boolean_value = doc:add_property("boolean_value",
      renoise.Document.ObservableBoolean(true))
  end
  
  if (not (math.random(4) % 2 == 0)) then
    number_list = doc:add_property("number_list", { 11, 12, 13} )
    string_list = doc:add_property("string_list", { "11", "12", "13"} )
    boolean_list = doc:add_property("boolean_list", { false, false} )
  else      
    number_list = doc:add_property("number_list",
      renoise.Document.ObservableNumberList())
    number_list:insert(11); number_list:insert(12); number_list:insert(13)
    
    string_list = doc:add_property("string_list",
      renoise.Document.ObservableStringList())
    string_list:insert("11"); string_list:insert("12"); string_list:insert("13")
    
    boolean_list = doc:add_property("boolean_list",
      renoise.Document.ObservableBooleanList())
    boolean_list:insert(false); boolean_list:insert(false)
  end
  
  local nested_doc = renoise.Document.create("TestDocumentNode"){ }
  nested_doc:add_property("sub_number_value", 2)
  nested_doc:add_property("sub_string_value", "string_value2")
  
  doc:add_property("sub_node", nested_doc)
  
  
  ----------------------------------------------------------------------------
  -- bogus adds
  
  assert_error(function()
    doc:add_property("number_value", 1)
  end)
  assert_error(function()
    doc:add_property("number_list", 1 )
  end)
  assert_error(function()
    doc:add_property("bogus_list", { false, 1} )
  end)
  assert_error(function()
    doc:add_property("<bogus_key>", 12)
  end)
  assert_error(function()
    doc:add_property("bogus key", 12)
  end)
  assert_error(function()
    doc:add_property("1bogus", 12)
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
  
  assert(doc.unknown_property == nil) 
  
  
  ----------------------------------------------------------------------------
  -- observable list notifiers & list operations
  
  local list_notifications = 0
  local last_list_notification
  
  local list_notifier = function(notification)
    list_notifications = list_notifications + 1 
    last_list_notification = notification
  end
  
  number_list:add_notifier(list_notifier)
  
  assert(#number_list == 3)
  while (#number_list ~= 0) do
    number_list:remove()
    
    assert(last_list_notification.type == "remove" and 
      last_list_notification.index == #number_list + 1)
  end
  
  assert(#number_list == 0)
  assert(list_notifications == 3)
  
  number_list:insert(99)
  assert(number_list:insert(45).value == 45)
  assert(#number_list == 2)
  assert(last_list_notification.type == "insert" and 
    last_list_notification.index == #number_list)
  
  number_list:insert(1, 22)
  assert(number_list[1].value == 22)
  
  number_list:insert(2, 33)
  assert(number_list[2].value == 33)
  
  assert(number_list[3].value == 99)
  assert(number_list[4].value == 45)
  
  number_list:swap(3, 4)
  assert(number_list[3].value == 45)
  assert(number_list[4].value == 99)
  assert(last_list_notification.type == "swap" and 
    last_list_notification.index1 == 3 and
    last_list_notification.index2 == 4)
    
  number_list:swap(3, 4)
  assert(number_list[3].value == 99)
  assert(number_list[4].value == 45)
  
  assert_error(function()
    number_list:swap(1,#number_list + 1)
  end)
  assert_error(function()
    number_list:swap(0, #number_list)
  end)
  
  number_list[3].value = 999
  
  number_list:remove(1)
  assert(number_list[1].value == 33)
  
  assert(number_list:find(45) == 3)
  assert(not number_list:find(46))
  
  assert(list_notifications == 10)
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
  
  while (#string_list > 0) do string_list:remove() end
  string_list:insert("olla")
  string_list:insert("wolla")
  assert(string_list[#string_list].value == "wolla")
  
  assert(string_list[1].value == "olla")
  assert(string_list[2].value == "wolla")
  assert(string_list[3] == nil)
  assert(string_list[-1] == nil)
  
  
  ----------------------------------------------------------------------------
  -- inline doc creation
  
  local doc2 = renoise.Document.create("AnotherDoc") {
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
    renoise.Document.create("BogusDoc") {
      empty_list = {},
    }
  end)
  
  assert_error(function()
    renoise.Document.create("BogusDoc") {
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
  assert(doc2:save_as(tmp_filename))
  
  doc2.number.value = 12
  doc2.number_list[3].value = 0
  doc2.sub_node.sub_number.value = 99
  
  assert(doc2:load_from(tmp_filename))
  
  assert(doc2.number.value == 99)
  assert(doc2.number_list[3].value == 13)
  assert(doc2.sub_node.sub_number.value == 234)
  
  assert(os.remove(tmp_filename))
  
  
  ----------------------------------------------------------------------------
  -- "free" Observable creation
  
  local notifications = 0
  local notifier = function()
    notifications = notifications + 1 
  end
  
  local observable_number = renoise.Document.ObservableNumber()
  observable_number = renoise.Document.ObservableNumber(23)
  observable_number:add_notifier(notifier)
  assert(observable_number.value == 23)
  assert_error(function()
    observable_number = renoise.Document.ObservableNumber("23")
  end)
  
  local observable_boolean = renoise.Document.ObservableBoolean()
  assert(observable_boolean.value == false)
  observable_boolean = renoise.Document.ObservableBoolean(true)
  observable_boolean:add_notifier(notifier)
  assert(observable_boolean.value == true)
  assert_error(function()
    observable_boolean = renoise.Document.ObservableBoolean(12)
  end)
  
  local observable_string = renoise.Document.ObservableString()
  assert(observable_string.value == "")
  observable_string = renoise.Document.ObservableString("Foo!")
  observable_string:add_notifier(notifier)
  assert(observable_string.value == "Foo!")
  assert_error(function()
    observable_string = renoise.Document.ObservableString(12)
  end)
  
  assert(notifications == 0)
  observable_number.value = 99
  observable_boolean.value = false
  observable_string.value = "New"
  assert(notifications == 3)
  
  
  -- Observable list creation
  
  local observable_number_list = renoise.Document.ObservableNumberList()
  local observable_boolean_list = renoise.Document.ObservableBooleanList()
  local observable_string_list = renoise.Document.ObservableStringList()
  

  ----------------------------------------------------------------------------
  -- sliced doc classes
  
  local sliced_constructor_calls = 0
  
  class "SlicedDocClass"(renoise.Document.DocumentNode)
    function SlicedDocClass:__init()
      renoise.Document.DocumentNode.__init(self)
  
      self:add_property("num", 12)
      self:add_property("str", "Oolla (sliced)!")
      
      sliced_constructor_calls = sliced_constructor_calls + 1
    end
      
  local sliced = SlicedDocClass()
  assert(sliced_constructor_calls == 1)
  
  assert(sliced.num.value == 12)
  assert(sliced.str.value == "Oolla (sliced)!")
  
  sliced.num.value = 66
  sliced.str.value = "changed"
  
  local tmp_filename = os.tmpname()
  assert(sliced:save_as(tmp_filename))
  
  sliced = SlicedDocClass() -- create new instance
  assert(sliced_constructor_calls == 2)
  
  assert(sliced:load_from(tmp_filename))
  assert(sliced_constructor_calls == 2)
  
  assert(sliced.num.value == 66)
  assert(sliced.str.value == "changed")
  
  assert(os.remove(tmp_filename))
  
  
  ----------------------------------------------------------------------------
  -- Document models & lists
  
  local modeled_node1 = renoise.Document.create("MyModel1") {
    num = 1,
    str = "Bla!",
  }
  
  local modeled_node2 = renoise.Document.create("MyModel2") {
    boo1 = false,
    str = "Bli!",
  }
  
  assert_error(function()
    renoise.Document.create("2InvalidModelName") {}
  end)
  
  -- create docs from model type identifiers
  local new_modeled_node = renoise.Document.instantiate("MyModel1")
  assert(new_modeled_node.num.value == 1)
  assert(new_modeled_node.str.value == "Bla!")
  
  
  -- register a doc with doc sub nodes and a doc list
  local doc = renoise.Document.create("MyDoc") {
    yanum = 1,
    doc = { nested_str = "nested" },
    doclist = renoise.Document.DocumentList(),
  }

  
  doc.doclist:insert(modeled_node1)
  doc.doclist:insert(modeled_node2)
  doc.doclist:insert(SlicedDocClass())
  doc.doclist:insert(SlicedDocClass())
  
  assert(doc.doclist[1].num.value == modeled_node1.num.value)
  assert(doc.doclist[1].str.value == modeled_node1.str.value)
  
  assert(doc.doclist[2].boo1.value == modeled_node2.boo1.value)
  assert(doc.doclist[2].str.value == modeled_node2.str.value)
  
  local tmp_filename = os.tmpname()
  assert(doc:save_as(tmp_filename))
  
  assert(sliced_constructor_calls == 4)
  doc = renoise.Document.instantiate("MyDoc")
  assert(sliced_constructor_calls == 6)

  assert(doc:load_from(tmp_filename))
  assert(sliced_constructor_calls == 8)
  
  -- unregister class "SlicedDocClass" (must fail cleanly)
  _G["SlicedDocClass"] = nil
  local succeeded, errormsg = doc:load_from(tmp_filename)
  assert(not succeeded and 
    errormsg:find("class 'SlicedDocClass' was not registered")
  )
   

  ----------------------------------------------------------------------------
  -- doc list notifier
  
  class "TestDocClass"(renoise.Document.DocumentNode)
    function TestDocClass:__init()
      renoise.Document.DocumentNode.__init(self)
      self:add_property("number", 15)
    end
    
  local doc_list_notifications = 0
  local last_doc_list_notification
  
  local doc_list_notifier = function(notification)
    doc_list_notifications = doc_list_notifications + 1 
    last_doc_list_notification = notification
  end
  
  local doc_list = renoise.Document.DocumentList()

  assert_error(function() -- no saving/loading or raw lists
    doc_list:save_as(tmp_filename)
  end)
    
  assert(not doc_list:has_notifier(doc_list_notifier))
  doc_list:add_notifier(doc_list_notifier)
  assert(doc_list:has_notifier(doc_list_notifier))
  
  assert(#doc_list == 0)
  doc_list:insert(TestDocClass())
  doc_list:insert(TestDocClass())
  assert(last_doc_list_notification.type == "insert" and 
    last_doc_list_notification.index == 2)
  
  assert(doc_list_notifications == 2)
  
  doc_list:swap(1, 2)
  assert(last_doc_list_notification.type == "swap" and
    last_doc_list_notification.index1 == 1 and
    last_doc_list_notification.index2 == 2)
  

  assert(doc_list_notifications == 3)
  
  doc_list:remove()
  assert(last_doc_list_notification.type == "remove" and
    last_doc_list_notification.index == 2)

  assert(doc_list_notifications == 4)
  assert(#doc_list == 1)  
  
    
  ------------------------------------------------------------------------------
  -- object lifetime (strong & weak_refs)
  

  -- ChildDoc
  
  class "ChildDoc"(renoise.Document.DocumentNode)
    ChildDoc.instances = 0
  
    function ChildDoc:__init()
      renoise.Document.DocumentNode.__init(self)
      ChildDoc.instances = ChildDoc.instances + 1
    end
   
    function ChildDoc:__finalize()
      ChildDoc.instances = ChildDoc.instances - 1
    end
  
  
  -- ParentDoc
  
  class "ParentDoc"(renoise.Document.DocumentNode)
    ParentDoc.instances = 0
  
    function ParentDoc:__init()
      renoise.Document.DocumentNode.__init(self)
      ParentDoc.instances = ParentDoc.instances + 1
  
      self:add_property("node", ChildDoc())
      self:add_property("list", renoise.Document.DocumentList())
      self:add_property("observable", renoise.Document.ObservableString("Oll"))
    end
   
    function ParentDoc:__finalize()
      ParentDoc.instances = ParentDoc.instances - 1
    end
  
  
  -- sliced doc nodes in doc lists
  
  local sliced_doc_list = renoise.Document.DocumentList()
  sliced_doc_list:insert(ChildDoc())
  
  assert(type(sliced_doc_list[1]) ~= "nil")
  assert(ChildDoc.instances == 1)
  collectgarbage()
  assert(ChildDoc.instances == 1)
  assert(type(sliced_doc_list[1]) ~= "nil")
  
  sliced_doc_list:remove()
  collectgarbage()
  assert(ChildDoc.instances == 0)
  
  
  -- sliced doc nodes in doc nodes
  
  local parent = ParentDoc()
  assert(ParentDoc.instances == 1)
  assert(ChildDoc.instances == 1)
  assert(type(parent.node) ~= "nil")
  collectgarbage()
  assert(type(parent.node) ~= "nil")
  assert(ChildDoc.instances == 1)
  assert(ParentDoc.instances == 1)
  
  parent = nil
  collectgarbage(); collectgarbage()
  assert(ParentDoc.instances == 0)
  assert(ChildDoc.instances == 0)
  
  
  -- modeled doc nodes in doc lists
  
  local child_doc = renoise.Document.create("ChildModel") {}
  sliced_doc_list = renoise.Document.DocumentList()
  sliced_doc_list:insert(child_doc)
  
  assert(type(sliced_doc_list[1]) ~= "nil")
  collectgarbage()
  assert(type(sliced_doc_list[1]) ~= "nil")
  collectgarbage()
  
  
  -- modeled doc nodes in doc nodes
  
  local parent_doc = renoise.Document.create("ParentModel") {
    child = renoise.Document.instantiate("ChildModel")
  }
  
  assert(type(parent_doc.child) ~= "nil")
  collectgarbage()
  assert(type(parent_doc.child) ~= "nil")
  
  
  -- observables in oservable lists
  
  local sliced_obs_list = renoise.Document.ObservableNumberList()
  sliced_obs_list:insert(66)
  
  assert(type(sliced_obs_list[1]) ~= "nil")
  collectgarbage()
  assert(type(sliced_obs_list[1]) ~= "nil")
  collectgarbage()
  
  
  -- oservables in doc nodes
  
  parent = ParentDoc()
  assert(type(parent.observable) ~= "nil")
  collectgarbage()
  assert(type(parent.observable) ~= "nil")
  collectgarbage()
  
  parent.observable = renoise.Document.ObservableString()
  assert(type(parent.observable) ~= "nil")
  collectgarbage()
  assert(type(parent.observable) ~= "nil")
  
  
  ------------------------------------------------------------------------------
  -- TODO: ipairs pairs support (or new ?dpairs? iterators)
  
end


------------------------------------------------------------------------------
-- test finalizers

collectgarbage()
-- need two runs to completely collect all parent<->child refs
collectgarbage()


--[[--------------------------------------------------------------------------
--------------------------------------------------------------------------]]--

