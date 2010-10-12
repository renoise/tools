--[[============================================================================
Renoise Document API Reference
============================================================================]]--

--[[

The renoise.Document namespace covers all document related Renoise API
functions. This is:

* Accessing existing Renoise document objects. The whole renoise API uses such
  document structs: all "_observables" in the whole Renoise Lua API are
  renoise.Document.Observable objects

* Create new documents (e.g persistent options, presets for your tools)
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
can attach notifier functions (listeners) to, in order to track changes. 
For example a view in the Renoise API is an Observer, which listens to 
observable values in documents.

Attaching and removing notifiers can done with the functions 'add_notifier',
'remove_notifier' of the Observable base class, and supports multiple kinds of
callbacks: plain functions and methods (functions with a context). please 
see renoise.Document.Observable for more details. Here is a simple example:

function bpm_changed()
  print(("something changed the BPM to %s"):format(
    renoise.song().transport.bpm))
end

renoise.song().transport.bpm_observable:add_notifier(bpm_changed)
-- later on, maybe:
renoise.song().transport.bpm_observable:remove_notifier(bpm_changed)

[added B4] When adding notifiers to lists (like the track list in a song)
an additional context parameter is passed to your notifier function. This way
you know what happened to the list:

function tracks_changed(notification)
  if (notification.type == "insert") then
    print(("new track was inserted at index: %d"):format(notification.index))
  
  elseif (notification.type == "remove") then
    print(("track got removed from index: %d"):format(notification.index))
  
  elseif (notification.type == "swap") then
    print(("track at index: %d and %d swapped their positions"):format(
      notification.index1, notification.index2))
  end
end

renoise.song().tracks_observable:add_notifier(tracks_changed)

If you only want to use the existing "_observables" in the Renoise Song/App API,
then this is all you need to know. If you want to create your own documents, 
then read ahead please:


-------- Overall API Design

All renoise.Document classes are wrappers for Renoises internal document
classes. Thus the Lua wrappers are not really a Lua's approach to solve 
and express things. e.g: theres no support for mixed types in lists,
tuples at the moment.
The reason behind this limitation is to allow both worlds (Lua in scripts 
and the internal C++ objects) to fully interact with each others: scripts 
can use existing Renoise objects, Renoise documents can be extended with 
Lua classes and so on.

If all you need is a generic XML im/exporter (or JSON or "fill in the currently
hyped format here") for your Lua tables, data, and you don't need an Observable 
mechanism for your values, then you should prefere using some generic Lua table
serializers. See http://lua-users.org/wiki/TableSerialization for a start.

Related to this, import of renoise.Documents from XML will NOT create new object
models from the source XML files, but will only assign existing values in the 
XML file to existing values in your document object (except for lists which are
instantiated dynamically via predefined types, models). This means: values which
are not present in the original model, will be silently ignored in the import. 
This most of the time is exactly what's needed for example extending an already
existing document format. But thats exactly what's NOTE needed when dealing with
unknown models or formats.


-------- Document Basetypes, Building Blocks

Types that can be in used in renoise.Documents, things that can make up a 
document, are:
- ObservableBoolean/Number/String (wrappers for the "raw" Lua base types)
- ObservableBoolean/String/NumberList (wrappers of lists of the Lua base types)
- other document objects (create document trees)
- lists of document objects (dynamically sized lists of other document nodes)

ObservableBoolean/Number/String is a simple wrapper for the raw Lua base types.
Basically it just stores the corresponding value (a boolean, number or string)
and maintains a list of notifiers that are attached to this value. Each 
Observable object is strongly typed, can only hold a predefined Lua base type, 
defined when constructing the property. Same is true for the basetype list 
wrappers: Lists can not contain multiple objects of different types.

Lua's other fundamental type, the table, has no direct representation in the
Document API: You can either use the strongly typed lists in order to get Lua
index based table alike behavior, or use nested document nodes or lists 
(documents in documents) to get an associative table alike layout/behavior.

Except of the strong typing, ObservableBoolean/String/NumberList and DocumentList
will behave more or less like Lua tables with number based indices (Arrays). 
You can use the # operator or [] operators just like you do with tables, but can
also query all this info via list methods (:size(), :property(name), ...).


-------- Creating Documents via "renoise.Document.create()" (models)

An empty document (node) object can be created with the function 
"renoise.Document.create("MyDoc"){}".
Such documents objects can be extended with the documents "add_property" 
function. Existing properties can also be removed again the "remove_property"
function:

-- creates an empty document, using "MyDoc" as model name (a type name)
local my_document = renoise.Document.create("MyDoc"){ }

-- adds a number to the document with the initial value 1
my_document:add_property("value1", 1) 

-- adds a string
my_document:add_property("value2", "bla") 

-- create another document and add it
local node = renoise.Document.create("MySubDoc"){ } 
node:add_property("another_value", 1)

-- add another already existing node
my_document:add_property("nested_node", node) 

-- removes a previously added node
my_document:remove_property(node) 

-- access properties
local value1 = my_document.value1 
value1 = my_document:property("value1")

A more comfortable, and often also more readable way of creating simple 
document trees, structs, can be done by passing a table to the create() 
function:

my_document = renoise.Document.create("MyDoc") {
  age = 1,
  name = "bla", -- implicitly specify a property type
  is_valid = renoise.Document.ObservableBoolean(false), -- or explicitly
  age_list = {1, 2, 3},
  another_list = renoise.Document.ObservableNumberList(),
  sub_node = {
    sub_value1 = 2,
    sub_value2 = "bla2"
  }
}

This will create a document node which is !modeled! after the the passed table.
The table is not internally used by the document after construction, and will
only be referenced to construct new instances. Also note that you need to assign 
values for all passed table properties in order to automatically determine its 
type, or specify the document types explicitly -> renoise.Document.ObservableXXX().

The passed name ("MyDoc" in the example above) us used to identify the document
when loading/saving it (loading a XML file which was saved with a different 
model will fail) and to generally specify its "type".

Once "create" was called, you can use the specified model name also to create 
new instances. For example:

-- create a new instance of "MyDoc"
my_other_document = renoise.Document.instantiate("MyDoc")


-------- [added B7] Creating Documents via inheritance (custom Doc classes)

Alternatively to "renoise.Document.create", you can also inherit from 
renoise.Document.DocumentNode in order to create your own document classes. 
This is especially recommended when dealing with more complex docs, cause you
also can use additional methods to deal with your properties, the data.

Here is a simple example:

class "MyDocument"(renoise.Document.DocumentNode)

  function MyDocument:__init()
    -- important! call super first
    renoise.Document.DocumentNode.__init(self) 
    
    -- add properties to construct the document model
    self:add_property("age", 1)
    self:add_property("name", renoise.Document.ObservableString("value"))
    
    -- other doc renoise.Document.DocumentNode object
    self:add_property("sub_node", MySubNode()) 
    
    -- list of renoise.Document.DocumentNode objects
    self:add_property("doc_list", renoise.Document.DocumentList())
    
    -- or the create() way:
    self:add_properties {
      something = "else"      
    }
  end

instantiating such document objects can be done as usual, by calling the
constructor:

my_document = MyDocument()
-- do something with my_document, load/save, add/remove more properties


-------- Accessing Document Properties

Accessing "renoise.Document.DocumentNode" can be done more or less just like you
do with tables in Lua, except that if you want to get/set the value of some
property, you have to query the value explicitly. e.g. Using my_document from
the example above:

-- this returns the !ObservableNumber object, not a number!
local age_observable = my_document.age

-- this sets the value of the object
my_document.age.value = 2 

-- this accesses/prints the value of the object
print(my_document.age.value) 

-- add notifiers
my_document.age:add_notifier(function() 
  print("something changed 'age'!")
end)
 
-- inserts a new entry to the list
my_document.age_list:insert(22) 

-- queries the length of the list
print(#my_document.age_list) 

-- access a list member
local entry = my_document.age_list[1] 

-- list members are observables as well
my_document.age_list[2].value = 33 

For more details about the document construction and notifiers have a look
at the class docs below please.

]]


--==============================================================================
-- renoise.Document
--==============================================================================

-------- construction

-- Create an empty DocumentNode or a DocumentNode that is modeled after the 
-- passed table. See the general description in this file for more info about
-- creating documents. "model name" will be used to identify the documents type
-- when loading/saving the doc. Also allows you to instantiate new document
-- objects (see renoise.Document.instantiate).
renoise.Document.create(model_name) {[table]}
  -> [renoise.Document.DocumentNode object]

-- create a new instance of the given document model. model_name must have been
-- registered with renoise.Document.create before.
[added B7] renoise.Document.instantiate(model_name)
  -> [renoise.Document.DocumentNode object]


--------------------------------------------------------------------------------
-- renoise.Document.Serializable
--------------------------------------------------------------------------------

-------- functions

-- Serialize the object to a string.
serializable:to_string()
  -> [string]

-- Assign the objects value from a string - when possible. Errors are 
-- silently ignored.
serializable:from_string(string)


--------------------------------------------------------------------------------
-- renoise.Document.Observable, inherits Serializable
--------------------------------------------------------------------------------

-------- functions

-- Checks if the given function, method was already registered as notifier.
observable:has_notifier(function or (object, function) or (function, object))
  -> [boolean]

-- Register a function or method as notifier, which will be called as soon as
-- the observables value changed.
observable:add_notifier(function or (object, function) or (function, object))

-- Unregister a previously registered notifier. When only passing an object to
-- remove_notifier, all notifier functions that match the given object will be
-- removed; aka all methods of the given object are removed. Will not fire
-- errors when none are attached in this case.
observable:remove_notifier(function or (object, function) or
 (function, object) or (object))


--------------------------------------------------------------------------------
-- renoise.Document.ObservableBoolean/Number/String, inherits Observable
--------------------------------------------------------------------------------

-------- properties

-- Read/write access to the value of an Observable.
observable.value
  -> [boolean, number or string]


--------------------------------------------------------------------------------
-- renoise.Document.ObservableBoolean/String/NumberList, inherits Observable
--------------------------------------------------------------------------------

-------- operators

-- Query a lists size (item count).
#observable_list
  -> [Number]

-- Access an observable item of the list by index (returns nil for non 
-- existing items).
observable_list[number]
  -> [renoise.Document.Observable object]


-------- functions

-- Returns the number of entries of the list.
observable_list:size()
  -> [number]


-- List item access (returns nil for non existing items).
observable_list:property(index)
  -> [nil or an renoise.Document.Observable object]

-- Find a value in the list by comparing the list values with the passed 
-- value. First successful match is returned. When no match is found, nil 
-- is returned.
observable_list:find([start_pos,] value)
  -> [nil or number (the index)]

-- Insert a new item to the end of the list when no position is specified, or 
-- at the specified position. Returns the newly created and inserted Observable.
observable_list:insert([pos,] value)
  -> [inserted Observable object]

-- Removes an item (or the last one if no index is specified) from the list.
observable_list:remove([pos])

-- Swaps the positions of two items without adding/removing the items.
-- With a series of swaps you can move the item from/to any position.
[added B4] observable_list:swap(pos1, pos2)


-- notifiers

-- Notifiers from renoise.Document.Observable are available for lists as well,
-- but will not broadcast changes made to the items, but only changes to the
-- !list! layout.
-- This means you will get notified as soon as an item was added, removed or
-- changed its position, but not when an items value changed. If you are
-- interested in value changes of a specific item in the list, attach notifiers
-- directly to the items itself and not to the list...
--
-- [added B4] List notifiers will also pass a table with information about what
-- happened to the list as first argument to the notifier:
--
-- function my_list_changed_notifier(notification)
--
-- When a new element got added, "notification" is {
--   type = "insert",
--   index = index_where_element_got_added
-- }
-- 
-- When a element got removed, "notification" is {
--   type = "remove",
--   index = index_where_element_got_removed_from
-- }
-- 
-- When two entries swapped their position, "notification" is {
--   type = "swap",
--   index1 = index_swap_pos1,
--   index2 = index_swap_pos2
-- }
--
-- Please note that all notifications are fired !after! the list already changed,
-- so the removed object is no longer available at the index you got passed in 
-- the notification. Newly inserted objects will already be present at the 
-- destination index, and so on...
--
-- See renoise.Document.Observable for more info about has/add/remove_notifier
observable_list:has_notifier(function or (object, function) or 
  (function, object)) -> [boolean]

observable_list:add_notifier(function or (object, function) or 
  (function, object))

observable_list:remove_notifier(function or (object, function) or
 (function, object) or (object))


--------------------------------------------------------------------------------
-- renoise.Document.DocumentList
--------------------------------------------------------------------------------

-------- operators

-- Query a lists size (item count).
[added B7] #doc_list
  -> [Number]

-- Access an document item of the list by index (returns nil for non 
-- existing items).
[added B7] doc_list[number]
  -> [renoise.Document.DocumentNode object]


-------- functions

-- Returns the number of entries of the list.
[added B7] doc_list:size()
  -> [number]


-- List item access by index (returns nil for non existing items).
[added B7] doc_list:property(index)
  -> [nil or renoise.Document.DocumentNode object]

-- Insert a new item to the end of the list when no position is specified, or 
-- at the specified position. Returns the inserted DocumentNode.
[added B7] doc_list:insert([pos,] doc_object)
  -> [inserted renoise.Document.DocumentNode object]

-- Removes an item (or the last one if no index is specified) from the list.
[added B7] doc_list:remove([pos])

-- Swaps the positions of two items without adding/removing the items.
-- With a series of swaps you can move the item from/to any position.
[added B7] doc_list:swap(pos1, pos2)


-- notifiers

-- Notifiers behave exactly like renoise.Document.ObservableXXXLists. Please 
-- have a look at them for more info.

[added B7] doc_list:has_notifier(function or (object, function) or 
  (function, object)) -> [boolean]

[added B7] doc_list:add_notifier(function or (object, function) or 
  (function, object))

[added B7] doc_list:remove_notifier(function or (object, function) or
 (function, object) or (object))

  
  
--------------------------------------------------------------------------------
-- renoise.Document.DocumentNode
--------------------------------------------------------------------------------

-------- operators

[added B7] doc[property_name]
  -> [nil or (Observable, ObservableList or DocumentNode, DocumentList object)]

  
-------- functions

doc:has_property(property_name)
  -> [boolean]

-- Access a property by name. returns the property, or nil when there is no
-- such property.
doc:property(property_name)
  -> [nil or (Observable, ObservableList or DocumentNode, DocumentList object)]

-- [changed B7] "add", "remove" is deprecated and will be removed in the final 
-- version, use the new "add_property", "remove_property" functions instead

-- Add a new property. Name must be unique: overwriting already existing
-- properties with the same name is not allowed and will fire an error.
doc:add_property(name, boolean_value)
  -> [newly created ObservableBoolean object]
doc:add_property(name, number_value)
  -> [newly created ObservableNumber object]
doc:add_property(name, string_value)
  -> [newly created ObservableString object]
doc:add_property(name, list)
  -> [newly created ObservableList object]
doc:add_property(name, node)
  -> [newly created DocumentNode object]
doc:add_property(name, node_list)
  -> [newly created DocumentList object]

-- Remove a previously added property. Property must exist.
doc:remove_property(document or observable object)


-- Save the whole document tree to a XML file. Overwrites all contents of the
-- file when it already exists.
doc:save_as(file_name)
  -> [success, error_string or nil on success]

-- Load the document tree from a XML file. This will !not! create new properties,
-- except for list items, but will only assign existing property values in the 
-- document node with existing property values from the XML.
-- This means: nodes that only exist in the XML only will be silently ignored.
-- Nodes that only exist in the document, will not be altered in any way.
-- The loaded document's type must match the document type that saved the XML data.
-- A documents type is specified in the renoise.Document.create function 
-- as 'model_name'. For classes which inherit from renoise.Document.DocumentNode,
-- its the Lua class name.
doc:load_from(file_name)
  -> [success, error_string or nil on success]
