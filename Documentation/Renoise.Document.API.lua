--[[============================================================================
Renoise Document API Reference
============================================================================]]--

--[[

The renoise.Document namespace covers all document related Renoise API
functions. This is:

* accessing existing Renoise document objects. The whole renoise API uses such
  document structs: all "_observables" in the whole Renoise Lua API are
  renoise.Document.Observable objects

* create new documents (e.g persistent options, presets for your tools),
  which can be loaded and saved as XML files by your scripts, and also bound to
  custom views or "your own" document listeners -> see renoise.Document.create()

Please read the INTRODUCTION.txt first to get an overview about the complete
API, and scripting in Renoise in general...

Do not try to execute this file. It uses a .lua extension for markups only.


-------- Observables

Documents and Views in the Renoise API are modeled after the observer pattern
(have a look at http://en.wikipedia.org/wiki/Observer_pattern if you have not
heard about this before please). This means a document basically just is a
set of some raw data (booleans, numbers, lists, nested nodes), which anything
can attach notifier functions (listeners) to, in order to track changes. A view
in the Renoise API is an Observer, which listens to observable values. 

Attaching and removing notifiers can done with the functions 'add_notifier',
'remove_notifier' of the Observable base class, and support multiple kinds of
callbacks: methods and functions. please see renoise.Document.Observable for
more details. Here is a simple example:

function bpm_changed()
  print(("something changed the BPM to %s"):format(
    renoise.song().transport.bpm))
end

renoise.song().transport.bpm_observable:add_notifier(bpm_changed)
-- later on, maybe:
renoise.song().transport.bpm_observable:remove_notifier(bpm_changed)

[added B4] function tracks_changed(notification)
  if (notification.type == "insert") then
    print(("new track was inserted to index: %d"):format(notification.index))
  
  elseif (notification.type == "remove") then
    print(("track got removed from index: %d"):format(notification.index))
  
  elseif (notification.type == "swap") then
    print(("track at index: %d and %d swapped their positions"):format(
      notification.index1, notification.index2))
  end
end

renoise.song().transport.tracks_observable:add_notifier(tracks_changed)


If you only want to use the existing "_observables" in the Renoise Song/App API,
this is all you need to know. If you want to create your own documents, then
read ahead please:


-------- Document Basetypes, Building Blocks

Types that can be in used in a document, make up a document, are:
- ObservableBoolean/Number/String (wrappers for the "raw" Lua base types)
- ObservableBoolean/String/NumberList (wrappers of lists of the Lua base types)
- other documents (create document trees)

ObservableBoolean/Number/String is a simple wrapper for the raw Lua base types.
Basically it just stores the corresponding value (a boolean, number or string)
and maintains a list of notifiers that are attached to this value. Each 
Observable object is strongly typed, can only hold one Lua base type, which is
defined when constructing the property. Same is true for the list wrappers:
Lists can not contain multiple objects of different types.

Luas other fundamental type, the table, has no direct representation in the
Document API: You can either use the strongly typed lists in order to get Lua
index based table alike behavior, or use nested document nodes (documents in 
documents) to get an associative table alike layout/behavior.

Except of the strong typing, ObservableBoolean/String/NumberList will behave
more or less like Lua tables with number based indices (Arrays), so you can use
the # operator or [] operators just like you do with tables, but can also
query all this info via the list's methods (:size(), :property(name), ...).


-------- Creating Documents

An empty document (node) object can be created with the function 
"renoise.Document.create()".
Such documents objects can be extended with the documents "add" function. 
Existing properties can also be removed again, using the "remove" function:

local my_document = renoise.Document.create() -- creates an empty document
my_document:add("value1", 1) -- adds a number with initial value 1
my_document:add("value2", "bla") -- adds a string

local node = renoise.Document.create() -- creates another document
node:add("another_value", 1)

my_document:add("nested_node", node) -- adds another node
my_document:remove(node) -- removes a previously added node

local value1 = my_document.value1 -- access added properties
value1 = my_document:property("value1")

A more comfortable, and often also more readable way of creating document trees,
is done by passing a table to the create() function:

my_document = renoise.Document.create{
  age = 1,
  name = "bla",
  is_valid = false,
  age_list = {1, 2, 3},
  sub_node = {
    sub_value1 = 2,
    sub_value2 = "bla2"
  }
}

This will create a document node which is !modeled! after the the passed table.
The table is not internally used by the document after construction, and will
thus also not be referenced afterward. Also note that you need to assign values
for all passed table properties, in order to determine its type.


-------- Accessing Documents

Accessing such a renoise.Document can be done more or less just like you do
with tables in Lua, except that if you want to get/set the value of some
property, you have to query the value explicitly. e.g. Using my_document from
the example above:

local age_observable = my_document.age -- this returns the !ObservableNumber 
  -- object, not a number!
my_document.age.value = 2 -- this sets the value of the object
print(my_document.age.value) -- this accesses/prints the value of the object
my_document.age:add_notifier(function() -- adds a notifier
  print("something changed 'age'!")
end)
 
my_document.age_list:insert(22) -- inserts a new entry to the list
print(#my_document.age_list) -- queries the length of the list
local entry = my_document.age_list[1] -- access a list member
my_document.age_list[2].value = 33 -- list members are observables as well

For more details about the document construction and notifiers have a look
at the class docs below please.

]]


--==============================================================================
-- renoise.Document
--==============================================================================

-------- construction

-- create an empty DocumentNode or a DocumentNode that is modeled after the 
-- passed table. See the general description in this file for more info about
-- creating documents.
renoise.Document.create(table or nil)
  -> [renoise.Document.DocumentNode object]


--------------------------------------------------------------------------------
-- renoise.Document.Serializable
--------------------------------------------------------------------------------

-------- functions

-- serialize the object to a string
serializable:to_string()
  -> [string]

-- assign the objects value from a string
serializable:from_string(string)


--------------------------------------------------------------------------------
-- renoise.Document.Observable, inherits Serializable
--------------------------------------------------------------------------------

-------- functions

-- checks if the given function, method was already registered as notifier
observable:has_notifier(function or (object, function) or (function, object))
  -> [boolean]

-- register a function or method as notifier, which will be called as soon as
-- the observables value changed
observable:add_notifier(function or (object, function) or (function, object))

-- unregister a previously registered notifier. when only passing an object to
-- remove_notifier, all notifier functions that match the given object will be
-- removed; aka all methods of the given object are removed. will not fire
-- errors when none are attached in this case.
observable:remove_notifier(function or (object, function) or
 (function, object) or (object))


--------------------------------------------------------------------------------
-- renoise.Document.ObservableBoolean/Number/String, inherits Observable
--------------------------------------------------------------------------------

-------- properties

observable.value
  -> [boolean, number or string]


--------------------------------------------------------------------------------
-- renoise.Document.ObservableBoolean/String/NumberList, inherits Observable
--------------------------------------------------------------------------------

-------- operators

-- query the lists size
#observable_list
  -> [Number]

-- access an observable by its index in the list
observable_list[number]
  -> [renoise.Document.Observable object]


-------- functions

-- returns the number of entries of the list
observable_list:size()
  -> [number]


-- list item access (returns nil for non existing items)
observable_list:property(index)
  -> [nil or an renoise.Document.Observable object]

-- find a value, by comparing the list values with the passed value. first
-- match is returned. when no match is found, nil is returned
observable_list:find([start_pos,] value)
  -> [nil or number (the index)]

-- insert a new item to the end of the list or at the specified position.
-- returns the newly created and inserted Observable
observable_list:insert([pos,] value)
  -> [inserted Observable object]

-- removes an item (or the last one if no index is specified) from the list
observable_list:remove([pos])

-- swaps the positions of two items without addeding/removing the items 
-- with a series of swaps you can move the item from/to any position
[added B4] observable_list:swap(pos1, pos2)


-- notifiers

-- notifiers from renoise.Document.Observable are available for lists as well,
-- but will not broadcast changes made to the items, but only changes to the
-- !list! layout.
-- This means you will get notified as soon as an item was added, removed or
-- changed its position, but not when an items value changed. If you are
-- interested in value changes of a specific item in the list, attach notifiers
-- directly to the item itself and not the list...
--
-- [added B4] List notifiers will also pass a table with information about what
-- happened to the list as first argument to the notifier:
--
-- function my_list_changed_notifier(notification)
--
-- when a new element got added, "notification" is {
--   type = "insert",
--   index = index_where_element_got_added
-- }
-- 
-- when a element got removed, "notification" is {
--   type = "remove",
--   index = index_where_element_got_removed_from
-- }
-- 
-- when two entries swapped their position, "notification" is {
--   type = "swap",
--   index1 = index_swap_pos1
--   index2 = index_swap_pos2
-- }
--
-- Please note that all notifications are fired !after! the list already changed,
-- so the removed object is no longer available at the index you got passed in 
-- the notification. Newly inserted objects will already be present at the 
-- destination index, and so on...

-- see renoise.Document.Observable for has/add/remove_notifier doc
observable_list:has_notifier(function or (object, function) or (function, object))
  -> [boolean]

observable_list:add_notifier(function or (object, function) or (function, object))

observable_list:remove_notifier(function or (object, function) or
 (function, object) or (object))



--------------------------------------------------------------------------------
-- renoise.Document.DocumentNode
--------------------------------------------------------------------------------

-------- functions

doc:has_property(property_name)

-- access a property by name. returns the property, or nil when there is no
-- such property
doc:property(property_name)
  -> [nil or (Observable or DocumentNode object)]

-- add a new property. name must be unique, aka overwriting already existing
-- properties with the same name is not allowed and will fire an error
doc:add(name, boolean_value)
  -> [newly created ObservableBoolean object]
doc:add(name, number_value)
  -> [newly created ObservableNumber object]
doc:add(name, string_value)
  -> [newly created ObservableString object]
doc:add(name, list)
  -> [newly created ObservableList object]
doc:add(name, node)
  -> [newly created DocumentNode object]

-- remove a previously added property
doc:remove(document or observable)


-- save the whole document tree to a XML file. overwrites all contents of the
-- file when it already exists.
doc:save_as(document_type_name, file_name)
  -> [success, error_string or nil on success]

-- load the document tree from a XML file. this will not create new properties
-- except for list items, but will only assign existing properties in the 
-- document node with existing properties from the XML file.
-- this means: nodes that exist in the XML only, will be silently ignored. 
-- nodes that exist in the document only, will not be altered in any way
doc:load_from(document_type_name, file_name)
  -> [success, error_string or nil on success]

