--[[============================================================================
Renoise ViewBuilder API Reference
============================================================================]]--

--[[

This reference lists all "View" related functions in the API. "View" means
classes and functions that are used to build custom GUIs; GUIs for your
scripts in Renoise.

Please read the INTRODUCTION.txt first to get an overview about the complete
API, and scripting in Renoise in general...

For a small tutorial and more details about how to create and use views, take
a look at the "com.renoise.ExampleToolGUI.xrnx" tool please. This tool 
is included in the scripting dev started pack at http://scripting.renoise.com

Do not try to execute this file. It uses a .lua extension for markups only.

]]


-- Currently there are two ways to to create custom views:

-- Shows a modal dialog with a title, custom content and custom button labels:
app():show_custom_prompt(title, content_view, {button_labels} [,key_handler_func]) 
  -> [pressed button]

and

-- Shows a non modal dialog, a floating tool window, with custom content:
app():show_custom_dialog(title, content_view [, key_handler_func]) 
  -> [dialog object]

-- key_handler_func is optional. When defined, it should point to a function 
-- with the signature noted below. "key" is a table with the fields:
-- key = {
--   name,      -- name of the key, like 'esc' or 'a' - always valid
--   modifiers, -- modifier states. 'shift + control' - always valid
--   character, -- character representation of the key or nil
--   note,      -- virtual keyboard piano key value (starting from 0) or nil
--   repeated,  -- [added B7] true when the key is soft repeated (hold down)
-- }
-- "dialog" is a reference to the dialog the keyhandler is running on.

function my_keyhandler_func(dialog, key) end

-- When no key handler is specified, only the Escape key is used to close the 
-- dialog. For prompts, also the first character of the button labels is used 
-- to invoke the corresponding button.
-- [added B4] When returning the passed key from the key-handler function, the 
-- key will be passed back to Renoises key event chain, in order to allow 
-- processing global Renoise key-bindings from your dialog. This will not work 
-- for modal dialogs. This will also only apply global shortcuts in Renoise, 
-- because your dialog will steal the focus from all other Renoise views like 
-- e.g.: the pattern editor. 


--==============================================================================
-- Views
--==============================================================================

--------------------------------------------------------------------------------
-- renoise.Views.View
--------------------------------------------------------------------------------

-- View is the base class for all following specialized views. All View 
-- properties can be applied to any of the following views.


------ functions

-- Dynamically create view hierarchies.
view:add_child(View child_view)
view:remove_child(View child_view)


----- properties

-- Set visible to false to hide a view (make it invisible without removing 
-- it). Please note that view.visible will also return false when any of its
-- parents are invisible (when its implicitly invisible).
-- By default a view is visible. 
view.visible 
  -> [boolean]

-- Get/set a views size. All views must have a size > 0.
-- By default > 0: how much exactly depends on the specialized view type.
--
-- Note: in nested view_builder notations you can also specify relative
-- sizes, like for example vb:text { width = "80%"}. The percentage values are
-- relative to the views parent size and will automatically update on size 
-- changes...
view.width 
  -> [number]
view.height 
  -> [number]

-- Get/set a tooltip text that should be shown for this view.
-- By default empty (no tip will be shown).
view.tooltip 
  -> [string]



--------------------------------------------------------------------------------
-- renoise.Views.Control (inherits from View)
--------------------------------------------------------------------------------

-- Control is the base class for all views which somehow allow letting the user 
-- change a value or some "state" via the UI.


----- properties

-- Instead of making a control invisible, you can also make it inactive.
-- Deactivated controls will still be shown and will also still show its 
-- currently assigned value, but do not allow changing it. Most controls will 
-- also display "grayed out" to visualize the deactivated state.
[added B6] control.active
  -> [boolean]


-- When set, the control will be highlighted with Renoises MIDI mapping dialog 
-- open. When clicked while the mapping dialog is open, it selects the specified 
-- string as MIDI mapping target action. This target acton can either be one of
-- the globally available mappings in Renoise, or ones that got created by the 
-- tool just for the tool.
-- Target strings are not verified. When they point to nothing, the mapped MIDI
-- message will do nothing but also no error is fired.
[added B7] control.midi_mapping
  -> [boolean]
 
 
--------------------------------------------------------------------------------
-- renoise.Views.Rack (inherits from View, 'column' or 'row' in ViewBuilder)
--------------------------------------------------------------------------------

-- A Rack has no content by its own, but only stacks its child views either
-- vertically (ViewBuilder.column) or horizontally (ViewBuilder.row). It allows 
-- you to create view layouts.

----- functions

-- Adding new child views to a rack automatically enlarges the rack, but
-- removing child views from a rack or making them invisible, will never 
-- automatically shrink it. 
-- "resize" does so, recalculates the racks size to exactly cover all its 
-- child views. When resizing a rack view which is the main content view of 
-- a dialog, "resize" will also resize the dialog.
rack:resize()


----- properties

-- Set the "borders" of the rack (left, right, top and bottom equally)
-- By default 0 (no borders).
rack.margin 
  -> [number]

-- Setup by which amount stacked child views are separated (horizontally in 
-- rows, vertically in columns).
-- By default 0 (no spacing).
rack.spacing 
  -> [number]

-- Setup a background style for the rack. Available styles are:
--   "invisible" -> no background
--   "plain"     -> undecorated, single colored background
--   "border"    -> same as plain, but with a bold nesting border
--   "body"      -> main "background" style, as used in dialogs backgrounds
--   "panel"     -> alternative "background" style, beveled
--   "group"     -> background for "nested" groups within "body"'s
-- By default "invisible".
rack.style 
  -> [string]

-- When set to true, all the child views in the rack will automatically get 
-- resized to the max size of all child views (width in ViewBuilder.column, 
-- height in ViewBuilder.row). This can be useful to automatically align all 
-- sub columns/panels to the same size. Resizing is done automatically, as soon
-- as a child views size changed or new childs got added.
-- By default disabled, false.
rack.uniform 
  -> [boolean]


--------------------------------------------------------------------------------
-- renoise.Views.Aligner (inherits from View, 'horizontal_aligner' or
--   'vertical_aligner' in ViewBuilder)
--------------------------------------------------------------------------------

-- Just like the Rack, the Aligner shows no content by its own, but just aligns 
-- its child views either vertically or horizontally. As soon as childs are 
-- added, the Aligner will expand itself to make sure that all childs are 
-- visible (including spacing & margins). 
-- To make use of modes like "center", you manually have to setup a size that 
-- is bigger than the sum of the child sizes.

----- properties

-- Setup "borders" of the aligner (left, right, top and bottom equally)
-- By default 0 (no borders).
aligner.margin 
  -> [number]

-- Setup by which amount child views are separated (horizontally in rows, 
-- vertically in columns).
-- By default 0 (no spacing).
aligner.spacing 
  -> [number]

-- Setup the alignment mode. Available mode are:
--   "left"       -> align from left to right (for horizontal_aligner only)
--   "right"      -> align from right to left (for horizontal_aligner only)
--   "top"        -> align from top to bottom (for vertical_aligner only)
--   "bottom"     -> align from bottom to top (for vertical_aligner only)
--   "center"     -> center all views
--   "justify"    -> keep outer views at the borders, distribute the rest
--   "distribute" -> equally distributes views over the aligners width/height
-- By default "left" for a horizontal_aligner, "top" for a vertical_aligner.
aligner.mode 
  -> [string]


-----------------------------------------------------------------------------"
-- renoise.Views.Text (inherits from View, 'text' in ViewBuilder)
-----------------------------------------------------------------------------"

-- A view which simply shows a "static" text string. Static just means that
-- its not linked, bound to some value and has no notifiers. And that the 
-- text can not be edited by the user. Nevertheless you can of course change 
-- the text at run-time with its "text" property.

-- See renoise.Views.TextField for texts that can be edited by the user.


--[[
 Text, Bla
--]]


----- properties

-- Get/set the text that should be displayed. Setting a new text will resize
-- the view in order to make the text fully visible (expanding only).
-- By default empty.
text.text 
  -> [string]

-- Get/set the font the text should be displayed with.
-- Available font styles are: 
--   "normal", 
--   "big"
--   "bold
--   "italic"
--   "mono"
-- By default "normal".
text.font 
  -> [string]

-- Setup the text's alignment. Applies only when the view's size is larger than 
-- the size that is needed to draw the text.
-- Available mode are: 
--   "left"
--   "right"
--   "center" 
-- By default "left".
text.align 
  -> [string]


--------------------------------------------------------------------------------
-- renoise.Views.MultiLineText (inherits from View, 'multiline_text' in the builder)
--------------------------------------------------------------------------------

-- A view which shows multiple lines of text, auto-formatting and auto-wrapping 
-- paragraphs into lines.
-- Its size is not automatically set. As soon as the text does not fit into the
-- view, a vertical scroll bar will be shown.

-- See renoise.Views.MultilineTextField for multiline texts that can be edited 
-- by the user.

--[[
 +--------------+-+
 | Text, Bla 1  |+|
 | Text, Bla 2  | |
 | Text, Bla 3  | |
 | Text, Bla 4  |+|
 +--------------+-+
--]]


----- functions

-- When a scroll bar is visible (needed), scroll the text to show the last line.
multiline_text:scroll_to_last_line()

-- When a scroll bar is visible, scroll the text to show the first line.
multiline_text:scroll_to_first_line()

-- Append text to the existing text. Newlines in the text will create new 
-- paragraphs, just like in the "text" property.
multiline_text:add_line(text)

-- clear the whole text, same as multiline_text.text="".
multiline_text:clear()


----- properties

-- Get/set the text that should be displayed in a single line. newlines 
-- (Windows, mac or Unix styled newlines) in the text can be used to create 
-- paragraphs.
-- By default empty.
multiline_text.text 
  -> [string]

-- Get/set an array (table) of text lines, instead of specifying a single text 
-- line with newline characters like "text" does.
-- By default empty.
multiline_text.paragraphs
  -> [string]

-- Get/set the font that the text should be displayed with.
-- Available font styles are: 
--   "normal"
--   "big"
--   "bold
--   "italic"
--   "mono"
-- By default "normal".
multiline_text.font 
  -> [string]

-- Setup the text views background:
--   "body"    -> simple text color with no background
--   "strong"  -> stronger text color with no background
--   "border"  -> text on a bordered background
-- By default "body".
multiline_text.style 
  -> [string]


--------------------------------------------------------------------------------
-- renoise.Views.TextField (inherits from View, 'textfield' in the builder)
--------------------------------------------------------------------------------

-- A view which shows a text string which can be edited by the user when 
-- clicked on.

--[[
 +----------------+
 | Editable Te|xt |
 +----------------+
--]]


----- functions

-- Add/remove value change (text change) notifiers.
textfield:add_notifier(function or {object, function} or {object, function})
textfield:remove_notifier(function or {object, function} or {object, function})

  
----- properties

-- The currently shown value / text. The text will not be updated while editing,
-- but only after editing finished (return was pressed, or focus was lost).
-- By default empty.
textfield.value 
  -> [string]
-- Exactly the same as "value"; provided for consistency.
textfield.text 
  -> [string]

-- Setup the text fields text alignment, when not editing.
-- Valid values are:
--   "left"
--   "right"
--   "center"
-- By default "left".
textfield.align

-- Valid in the construction table only: set up a notifier for text changes. 
-- See add_notifier/remove_notifier below.
textfield.notifier 
  -> [function()]
  
-- Valid in the construction table only: bind the views value to an 
-- renoise.Document.ObservableString object. Will change the Observable
-- value as soon as the views value changed, and change the Views value as 
-- soon as the Observable's value changed - automatically keeps both values 
-- in sync.
-- Notifiers can then be added to either the view or the Observable object.
textfield.bind
  -> [ObservableString Object]

    
--------------------------------------------------------------------------------
-- renoise.Views.MultilineTextField (inherits from View, 
--   'multiline_textfield' in the builder)
--------------------------------------------------------------------------------

-- A view which shows multiple text lines of text, auto-wrapping 
-- paragraphs into lines. The text can be edited by the user.

--[[
 +--------------------------+-+
 | Editable Te|xt.          |+|
 |                          | |
 | With multiple paragraphs | |
 | and auto-wrapping        |+|
 +--------------------------+-+
--]]             


----- functions

-- Add/remove value change (text change) notifiers.
multiline_textfield:add_notifier(function or {object, function} or {object, function})
multiline_textfield:remove_notifier(function or {object, function} or {object, function})

-- When a scroll bar is visible, scroll the text to show the last line.
multiline_textfield:scroll_to_last_line()

-- When a scroll bar is visible, scroll the text to show the first line.
multiline_textfield:scroll_to_first_line()

-- Append a new text to the existing text. Newline characters in the string will
-- Create new paragraphs, else a single new paragraph is appended.
multiline_textfield:add_line(text)

-- Clear the whole text.
multiline_textfield:clear()


----- properties

-- The current text as single line, using using newline characters to specify
-- paragraphs.
-- By default empty.
multiline_textfield.value 
  -> [string]
-- Exactly the same as "value"; provided for consistency.
multiline_textfield.text 
  -> [string]

-- Get/set a list/table of text lines instead of specifying the newlines as 
-- characters.
-- By default empty.
multiline_textfield.paragraphs 
  -> [string]

-- Get/set the font style that the text should be displayed with.
-- Available font styles are: 
--   "normal"
--   "big"
--   "bold
--   "italic"
--   "mono"
-- By default "normal".
multiline_textfield.font 
  -> [string]

-- Setup the text views background style
--   "body"    -> simple body text color with no background
--   "strong"  -> stronger body text color with no background
--   "border"  -> text on a bordered background
-- By default "border".
multiline_textfield.style 
  -> [string]

-- Valid in the construction table only: set up a notifier for text changes. 
-- See add_notifier/remove_notifier above.
multiline_textfield.notifier 
  -> [function()]
  
-- Valid in the construction table only: bind the views value to an 
-- renoise.Document.ObservableStringList object. Will change the Observable
-- value as soon as the views value changed, and change the Views value as 
-- soon as the Observable's value changed - automatically keeps both values 
-- in sync.
-- Notifiers can then be added to either the view or the Observable object.
multiline_textfield.bind
  -> [ObservableStringList Object]


--------------------------------------------------------------------------------
-- renoise.Views.Bitmap (inherits from Control, 'bitmap' in the builder)
--------------------------------------------------------------------------------

--[[    *
       ***
    +   *
   / \
  +---+
  | O |  o
  +---+  |
 ||||||||||||
--]]

-- A view which either simply draws a bitmap, or a draws a bitmap which acts 
-- like a button (as soon as a notifier was specified). The notifier is called 
-- when clicking with the mouse button somewhere on the bitmap. When using a 
-- recolorable style (see 'mode'), the bitmap is automatically recolored to 
-- match the current theme colors. Also mouse hover is enabled when notifies 
-- are present, to show that the bitmap can be clicked.


----- functions

-- Add/remove mouse click notifiers
bitmapview:add_notifier(function or {object, function} or {object, function})
bitmapview:remove_notifier(function or {object, function} or {object, function})


----- properties

-- Setup how the bitmap should be drawn, recolored. Available modes are:
--   "plain"        -> bitmap is drawn just like it is, no recoloring is done
--   "transparent"  -> same as plain, but black pixels will be fully transparent
--   "button_color" -> recolor the bitmap, using the color themes button color
--   "body_color"   -> same as 'button_back' but with body text/back color
--   "main_color"   -> same as 'button_back' but with main text/back colors
-- By default "plain".
bitmapview.mode 
  -> [string]

-- Set the to be drawn bitmap name and path. You should use a relative path
-- that either assumes Renoises default resource folder as base (like
-- "Icons/ArrowRight.bmp"). Or specify a file relative from your XRNX tool 
-- bundle: 
-- Lets say your tool is called "com.foo.MyTool.xrnx" and you pass
-- "MyBitmap.bmp" as name. Then the bitmap is loaded from
-- "PATH_TO/com.foo.MyTool.xrnx/MyBitmap.bmp". 
-- The only supported bitmap format is ".bmp" (Windows bitmap) right now.
bitmapview.bitmap 
  -> [string]

-- Valid in the construction table only: set up a click notifier. See 
-- add_notifier/remove_notifier above.
bitmapview.notifier 
  -> [function()]


--------------------------------------------------------------------------------
-- renoise.Views.Button (inherits from Control, 'button' in the builder)
--------------------------------------------------------------------------------

-- A simple button, which will call a custom notifier function when clicked.
-- Supports text or bitmap labels.

--[[
 +--------+
 | Button |
 +--------+
--]]


----- functions

-- Add/remove button hit/release notifier functions. 
-- When a "pressed" notifier is set, the release notifier is guaranteed to be 
-- called as soon as the mouse was released, either on your button or anywhere
-- else. When only a "release" notifier is set, its only called when the mouse 
-- button was pressed !and! released on your button.
button:add_pressed_notifier(function or {object, function} or {object, function})
button:add_released_notifier(function or {object, function} or {object, function})
button:remove_pressed_notifier(function or {object, function} or {object, function})
button:remove_released_notifier(function or {object, function} or {object, function})


----- properties

-- The text label of the button
-- By default empty.
button.text 
  -> [string]

-- When set, existing text is cleared. You should use a relative path
-- that either assumes Renoises default resource folder as base (like
-- "Icons/ArrowRight.bmp"). Or specify a file relative from your XRNX tool 
-- bundle: 
-- Lets say your tool is called "com.foo.MyTool.xrnx" and you pass
-- "MyBitmap.bmp" as name. Then the bitmap is loaded from
-- "PATH_TO/com.foo.MyTool.xrnx/MyBitmap.bmp". 
-- The only supported bitmap format is ".bmp" (Windows bitmap) right now.
-- Colors will be overridden by the theme colors, using black as transparent 
-- color, white is the full theme color. All colors in between are mapped 
-- according to their gray value.
button.bitmap 
  -> [string]

-- Table of RGB values like {0xff,0xff,0xff} -> white. When set, the
-- unpressed button's background will be drawn in the specified color. 
-- A text color is automatically selected to make sure its always visible. 
-- Set color {0,0,0} to enable the theme colors for the button again.
button.color 
  -> [table with 3 numbers (0-255)]


-- Valid in the construction table only: set up a click notifier.
button.pressed 
  -> [function()]
-- Valid in the construction table only: set up a click release notifier.
button.released 
  -> [function()]

-- synonymous for 'button.released'.
button.notifier 
  -> [function()]


--------------------------------------------------------------------------------
-- renoise.Views.CheckBox (inherits from Control, 'checkbox' in the builder)
--------------------------------------------------------------------------------

-- A single button with a checkbox bitmap, which can be used to toggle 
-- something on/off.

--[[
 +----+
 | _/ |
 +----+
--]]


----- functions

-- Add/remove value notifiers
checkbox:add_notifier(function or {object, function} or {object, function})
checkbox:remove_notifier(function or {object, function} or {object, function})


----- properties

-- The current state of the checkbox, expressed as boolean.
-- By default "false".
checkbox.value 
  -> [boolean]

-- Valid in the construction table only: set up a value notifier.
checkbox.notifier 
  -> [function(boolean_value)]

-- Valid in the construction table only: bind the views value to an 
-- renoise.Document.ObservableBoolean object. Will change the Observable
-- value as soon as the views value changed, and change the Views value as 
-- soon as the Observable's value changed - automatically keeps both values 
-- in sync.
-- Notifiers can then be added to either the view or the Observable object.
checkbox.bind
  -> [ObservableBoolean Object]
  
  
--------------------------------------------------------------------------------
-- renoise.Views.Switch (inherits from Control, 'switch' in the builder)
--------------------------------------------------------------------------------

-- A set of horizontally aligned buttons, where only one button can be enabled
-- at the same time. Select one of multiple choices, indices.

--[[
 +-----------+------------+----------+
 | Button A  | +Button+B+ | Button C |
 +-----------+------------+----------+
--]]


----- functions

-- Add/remove index change notifiers.
switch:add_notifier(function or {object, function} or {object, function})
switch:remove_notifier(function or {object, function} or {object, function})


----- properties

-- Get/set the currently shown button labels. Item list size must be >= 2.
switch.items 
  -> [list of strings]

-- Get/set the currently pressed button index.
switch.value
  -> [number]

-- Valid in the construction table only: set up a value notifier.
switch.notifier 
  -> [function(index)]

-- Valid in the construction table only: bind the views value to an 
-- renoise.Document.ObservableNumber object. Will change the Observable
-- value as soon as the views value changed, and change the Views value as 
-- soon as the Observable's value changed - automatically keeps both values 
-- in sync.
-- Notifiers can then be added to either the view or the Observable object.
switch.bind
  -> [ObservableNumber Object]
  
  
--------------------------------------------------------------------------------
-- renoise.Views.Popup (inherits from Control, 'popup' in the builder)
--------------------------------------------------------------------------------

-- A drop-down menu which shows the currently selected value when closed.
-- When clicked, it pops up a list of all available items.

--[[
 +--------------++---+
 | Current Item || ^ |
 +--------------++---+
--]]


----- functions

-- Add/remove index change notifiers.
popup:add_notifier(function or {object, function} or {object, function})
popup:remove_notifier(function or {object, function} or {object, function})


----- properties

-- Get/set the currently shown items. Item list can be empty, then "None" is
-- displayed and the value won't change.
popup.items 
  -> [list of strings]

-- Get/set the currently selected item index.
popup.value
  -> [number]

-- Valid in the construction table only: set up a value notifier.
popup.notifier 
  -> [function(index)]

-- Valid in the construction table only: bind the views value to an 
-- renoise.Document.ObservableNumber object. Will change the Observable
-- value as soon as the views value changed, and change the Views value as 
-- soon as the Observable's value changed - automatically keeps both values 
-- in sync.
-- Notifiers can then be added to either the view or the Observable object.
popup.bind
  -> [ObservableNumber Object]
  
  
--------------------------------------------------------------------------------
-- renoise.Views.Chooser (inherits from Control, 'chooser' in the builder)
--------------------------------------------------------------------------------

-- A radio button alike set of vertically stacked items. Only one value can be 
-- selected at the same time.

--[[
 . Item A
 o Item B
 . Item C
--]]


----- functions

-- Add/remove index change notifiers.
chooser:add_notifier(function or {object, function} or {object, function})
chooser:remove_notifier(function or {object, function} or {object, function})


----- properties

-- Get/set the currently shown items. Item list size must be >= 2.
chooser.items 
  -> [list of strings]

-- Get/set the currently selected items index.
chooser.value
  -> [number]

-- Valid in the construction table only: set up a value notifier.
chooser.notifier 
  -> [function(index)]

-- Valid in the construction table only: bind the views value to an 
-- renoise.Document.ObservableNumber object. Will change the Observable
-- value as soon as the views value changed, and change the Views value as 
-- soon as the Observable's value changed - automatically keeps both values 
-- in sync.
-- Notifiers can then be added to either the view or the Observable object.
chooser.bind
  -> [ObservableNumber Object]
  
  
--------------------------------------------------------------------------------
-- renoise.Views.ValueBox (inherits from Control, 'valuebox' in the builder)
--------------------------------------------------------------------------------

-- A box with <> buttons and a text field which can be edited by the user. 
-- Allows showing and editing natural numbers in a custom range.

--[[
 +---+-------+
 |<|>|  12   |
 +---+-------+
--]]


----- functions

-- Add/remove value change notifiers.
valuebox:add_notifier(function or {object, function} or {object, function})
valuebox:remove_notifier(function or {object, function} or {object, function})


----- properties

-- Get/set the min/max values that are expected, allowed.
-- By default 0 and 100.
valuebox.min
  -> [number]
valuebox.max 
  -> [number]

-- Get/set the current value
valuebox.value
  -> [number]

-- Valid in the construction table only: setup custom rules on how the number
-- should be displayed. Both, 'tostring' and  'tovalue' must be set, or none
-- of them. If none are set, a default string/number conversion is done, which
-- simply shows the number with 3 digits after the decimal point.
--
-- When defined, 'tostring' must be a function with one parameter, the to be
-- converted number, and must return a string or nil.
-- 'tonumber' must be a function with one parameter and gets the to be
-- converted string passed, returning a a number or nil. when returning nil,
-- no conversion will be done and the value is not changed.
--
-- Note: when any of the callbacks fails with an error, both will be disabled
-- to avoid floods of error messages.
valuebox.tostring 
  -> (function(number) -> [string])
valuebox.tovalue 
  -> (function(string) -> [number])

-- Valid in the construction table only: set up a value notifier.
valuebox.notifier 
  -> [function(number)]

-- Valid in the construction table only: bind the views value to an 
-- renoise.Document.ObservableNumber object. Will change the Observable
-- value as soon as the views value changed, and change the Views value as 
-- soon as the Observable's value changed - automatically keeps both values 
-- in sync.
-- Notifiers can then be added to either the view or the Observable object.
valuebox.bind
  -> [ObservableNumber Object]
  
  
--------------------------------------------------------------------------------
-- renoise.Views.Value (inherits from View, 'value' in the builder)
--------------------------------------------------------------------------------

-- A static text view, which shows a string representation of a number and 
-- allows custom number -> string conversion.
-- See 'Views.ValueField' for a value text field that can be edited by the user.

--[[
 +---+-------+
 | 12.1 dB   |
 +---+-------+
--]]


----- functions

-- Add/remove value change notifiers.
value:add_notifier(function or {object, function} or {object, function})
value:remove_notifier(function or {object, function} or {object, function})


----- properties

-- Get/set the current value.
value.value
  -> [number]

-- Get/set the font that the text should be displayed with.
-- Available font styles are: 
--   "normal"
--   "big"
--   "bold 
--   "italic"
--   "mono"
-- By default "normal".
value.font 
  -> [string]

-- Setup the value text alignment. Valid values are:
--   "left"
--   "right"
--   "center"
-- By default "left".
value.align 
  -> [string]

-- Valid in the construction table only: setup a custom rule on how the
-- number should be displayed. When defined, 'tostring' must be a function
-- with one parameter, the to be converted number, and must return a string
-- or nil.
--
-- Note: when the callback fails with an error, it will be disabled to avoid
-- floods of error messages.
value.tostring 
  -> (function(number) -> [string])

-- Valid in the construction table only: set up a value notifier.
value.notifier 
  -> [function(number)]

-- Valid in the construction table only: bind the views value to an 
-- renoise.Document.ObservableNumber object. Will change the Observable
-- value as soon as the views value changed, and change the Views value as 
-- soon as the Observable's value changed - automatically keeps both values 
-- in sync.
-- Notifiers can then be added to either the view or the Observable object.
value.bind
  -> [ObservableNumber Object]
  
  
--------------------------------------------------------------------------------
-- renoise.Views.ValueField (inherits from Control, 'valuefield' in the builder)
--------------------------------------------------------------------------------

-- A text view, which shows a string representation of a number and allows 
-- custom number <-> string conversion. The value text can be edited by the user.

--[[
 +---+-------+
 | 12.1 dB   |
 +---+-------+
--]]


----- functions

-- Add/remove value change notifiers.
valuefield:add_notifier(function or {object, function} or {object, function})
valuefield:remove_notifier(function or {object, function} or {object, function})


----- properties

-- Get/set the min/max values that are expected, allowed.
-- By default 0.0 and 1.0.
valuefield.min 
  -> [number]
valuefield.max 
  -> [number]

-- Get/set the current value.
valuefield.value
  -> [number]

-- Setup the text alignment. Valid values are:
--   "left"
--   "right"
--   "center"
-- By default "left".
valuefield.align 
  -> [string]

-- Valid in the construction table only: setup custom rules on how the number
-- should be displayed. Both, 'tostring' and  'tovalue' must be set, or none
-- of them. If none are set, a default string/number conversion is done, which
-- simply shows the number with 3 digits after the decimal point.
--
-- When defined, 'tostring' must be a function with one parameter, the to be
-- converted number, and must return a string or nil.
-- 'tonumber' must be a function with one parameter and gets the to be
-- converted string passed, returning a a number or nil. When returning nil,
-- no conversion will be done and the value is not changed.
--
-- Note: when any of the callbacks fail with an error, both will be disabled
-- to avoid floods of error messages.
valuefield.tostring 
  -> (function(number) -> [string])
valuefield.tovalue 
  -> (function(string) -> [number])

-- Valid in the construction table only: set up a value notifier function.
valuefield.notifier 
  -> [function(number)]

-- Valid in the construction table only: bind the views value to an 
-- renoise.Document.ObservableNumber object. Will change the Observable
-- value as soon as the views value changed, and change the Views value as 
-- soon as the Observable's value changed - automatically keeps both values 
-- in sync.
-- Notifiers can then be added to either the view or the Observable object.
valuefield.bind
  -> [ObservableNumber Object]
  
  
--------------------------------------------------------------------------------
-- renoise.Views.Slider (inherits from Control, 'slider' in the builder)
--------------------------------------------------------------------------------

-- A slider with <> buttons, which shows and allows editing values in a custom 
-- range. A slider can be horizontal or vertical; will flip its orientation
-- according to the set width and height. By default horizontal.

--[[
 +---+---------------+
 |<|>| --------[]    |
 +---+---------------+
--]]


----- functions

-- Add/remove value change notifiers.
slider:add_notifier(function or {object, function} or {object, function})
slider:remove_notifier(function or {object, function} or {object, function})


----- properties

-- Get/set the min/max values that are expected, allowed.
-- By default 0.0 and 1.0.
slider.min 
  -> [number]
slider.max 
  -> [number]

-- Get/set the current value.
slider.value
  -> [number]

-- Valid in the construction table only: set up a value notifier function.
slider.notifier 
  -> [function(number)]

-- Valid in the construction table only: bind the views value to an 
-- renoise.Document.ObservableNumber object. Will change the Observable
-- value as soon as the views value changed, and change the Views value as 
-- soon as the Observable's value changed - automatically keeps both values 
-- in sync.
-- Notifiers can then be added to either the view or the Observable object.
slider.bind
  -> [ObservableNumber Object]
  
  
--------------------------------------------------------------------------------
-- renoise.Views.MiniSlider (inherits from Control, 'minislider' in the builder)
--------------------------------------------------------------------------------

-- Same as a slider, but without <> buttons and a really tiny height. Just like
-- the slider, a mini slider can be horizontal or vertical. It will flip its 
-- orientation according to the set width and height. By default horizontal.

--[[
 --------[]
--]]


----- functions

-- Add/remove value change notifiers.
slider:add_notifier(function or {object, function} or {object, function})
slider:remove_notifier(function or {object, function} or {object, function})


----- properties

-- Get/set the min/max values that are expected, allowed.
-- By default 0.0 and 1.0.
slider.min 
  -> [number]
slider.max 
  -> [number]

-- Get/set the current value.
slider.value
  -> [number]

-- Valid in the construction table only: set up a value notifier.
slider.notifier 
  -> [function(number)]

-- Valid in the construction table only: bind the views value to an 
-- renoise.Document.ObservableNumber object. Will change the Observable
-- value as soon as the views value changed, and change the Views value as 
-- soon as the Observable's value changed - automatically keeps both values 
-- in sync.
-- Notifiers can then be added to either the view or the Observable object.
slider.bind
  -> [ObservableNumber Object]

--------------------------------------------------------------------------------
-- renoise.Views.RotaryEncoder (inherits from Control, 'rotary' in the builder)
--------------------------------------------------------------------------------

-- A slider which looks like a potentiometer.
-- Note: when changing the size, the min of the width and height will be used
-- to draw and control the rotary control, so you should always set both 
-- equally.

--[[
   +-+
 / \   \
|   o   |
 \  |  /
   +-+
--]]



----- functions

-- Add/remove value change notifiers.
rotary:add_notifier(function or {object, function} or {object, function})
rotary:remove_notifier(function or {object, function} or {object, function})


----- properties

-- Get/set the min/max values that are expected, allowed.
-- By default 0.0 and 1.0.
rotary.min 
  -> [number]
rotary.max 
  -> [number]

-- Get/set the current value.
rotary.value
  -> [number]

-- Valid in the construction table only: set up a value notifier function.
rotary.notifier 
  -> [function(number)]

-- Valid in the construction table only: bind the views value to an 
-- renoise.Document.ObservableNumber object. Will change the Observable
-- value as soon as the views value changed, and change the Views value as 
-- soon as the Observable's value changed - automatically keeps both values 
-- in sync.
-- Notifiers can then be added to either the view or the Observable object.
rotary.bind
  -> [ObservableNumber Object]
  

--------------------------------------------------------------------------------
-- [added B4] renoise.Views.XYPad (inherits from Control, 'xypad' in the builder)
--------------------------------------------------------------------------------

-- A slider alike pad which allows controlling two values at once. By default
-- it freely moves the XY values, but can also be configured to snap back to a
-- predefined value when releasing the mouse button. 
--
-- All values, notifiers, current value or min/max properties, will act just 
-- like a slider or rotaries properties, but instead of a single number a table
-- with the fields {x = xvalue, y = yvalue} is expected, returned...

--[[
+-------+
|    o  |
|   +   |
|       |
+-------+
--]]


----- functions

-- Add/remove value change notifiers.
xypad:add_notifier(function or {object, function} or {object, function})
xypad:remove_notifier(function or {object, function} or {object, function})


----- properties

-- Get/set a table of min/max values that are allowed.
-- By default 0.0 and 1.0 for both, x and y.
xypad.min 
  -> [{x=Number,y=Number}]
xypad.max 
  -> [{x=Number,y=Number}]

-- Get/set the pads current value in a table
xypad.value
  -> [{x=Number,y=Number}]

-- When snapback is enabled a xy table is returned, else nil. To enable 
-- snapback, pass a xy table with desired values. Pass nil or an empty table 
-- to disable snapback.
-- When snapback is enabled, the pad will revert its values to the specified 
-- snapback values as soon as the mouse button is released in the pad. When 
-- disabled,  releasing the mouse button will not change the value.
xypad.snapback
  -> [{x=Number,y=Number}]

-- Valid in the construction table only: set up a value notifier function.
xypad.notifier 
  -> [function(value={x=Number,y=Number})]

-- Valid in the construction table only: bind the views value to a pair of 
-- renoise.Document.ObservableNumber objects. Will change the Observable
-- values as soon as the views value changed, and change the Views values as 
-- soon as the Observable's value changed - automatically keeps both values 
-- in sync.
-- Notifiers can then be added to either the view or the Observable object.
-- Just like in the other xypad properties, a table with the fields x and y
-- is expected here and not a single value. So you have to bind two 
-- ObservableNumber object to the pad.
xypad.bind
  -> [{x=ObservableNumber Object, y=ObservableNumber Object}]
  
    
--==============================================================================
-- renoise.Dialog
--==============================================================================

-- Dialogs can not created with the viewbuilder, but only by the application. 
-- See "create custom views" on top of this file how to do so.

----- functions

-- Bring an already visible dialog to front and make it the key window.
dialog:show()

-- Close a visible dialog.
dialog:close()


----- properties

-- Check if a dialog is alive and visible.
dialog.visible 
  -> [read-only, boolean]


--==============================================================================
-- renoise.ViewBuilder
--==============================================================================

-- Class which is used to construct new views. All views properties, as listed
-- above, can optionally be in-lined in a passed construction table:
--
-- local vb = renoise.ViewBuilder() -- create a new ViewBuilder
-- vb:button { text = "ButtonText" } -- is the same as
-- my_button = vb:button(); my_button.text = "ButtonText"
--
-- Beside of the listed class properties above, you can also specify the
-- following "extra" properties in the passed table:
--
-- * id = "SomeString": which can be use to resolve the view later on
--   -> vb.views.SomeString or vb.views["SomeString"]
--
-- * notifier = some_function or notifier = {some_obj, some_function} to
--   register value change notifiers in controls (views which represent values)
--
-- * bind = a_document_value (Observable) to bind a view's value directly 
--   to an Observable object. Notifiers can then be added to the Observable or 
--   the view. Then binding a value to a view, the view will automatically 
--   update its value as soon as the Observable's value changed, and the 
--   Observable's value will automatically be updated as soon as the view's 
--   value changed.
--   See "Renoise.Document.API.lua" for more general info about Documents & 
--   Observables please.
--
-- * nested child views: add a child view to the currently specified view. 
--   For example:
--
--   vb:column {
--     margin = 1,
--     vb:text {
--       text = "Text1"
--     },
--     vb:text {
--       text = "Text1"
--     }
--   }
--
--  Creates a column view with margin = 1 and adds two text views to the column.


-- consts (renoise.ViewBuilder.XXX)

-- Default sizes for views and view layouts. Should be used instead of magic 
-- numbers, also to be able to globally change them in the program for all GUIs. 
renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
renoise.ViewBuilder.DEFAULT_MINI_CONTROL_HEIGHT
renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
renoise.ViewBuilder.DEFAULT_DIALOG_SPACING
renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT


----- functions

vb:column { Rack Properties and/or child views }
  -> [Rack object]
vb:row { Rack Properties and/or child views }
  -> [Rack object]

vb:horizontal_aligner { Aligner Properties and/or child views }
  -> [Aligner object]
vb:vertical_aligner { Aligner Properties and/or child views }
  -> [Aligner object]

vb:space { View Properties and/or child views }
  -> [View object]

vb:text { Text Properties }
  -> [Text object]
vb:multiline_text { MultiLineText Properties }
  -> [MultilineText object]

vb:textfield { TextField Properties }
  -> [TextField object]

vb:bitmap { Bitmap Properties }
  -> [Bitmap object]

vb:button { Button Properties }
  -> [Button object]

vb:checkbox  { Rack Properties }
  -> [CheckBox object]
vb:switch { Switch Properties }
  -> [Switch object]
vb:popup { Popup Properties }
  -> [Popup object]
vb:chooser { Chooser Properties }
  -> [Chooser object]

vb:valuebox { ValueBox Properties }
  -> [ValueBox object]

vb:value { Value Properties }
  -> [Value object]
vb:valuefield { ValueField Properties }
  -> [ValueField object]

vb:slider { Slider Properties }
  -> [Slider object]
vb:minislider { MiniSlider Properties }
  -> [MiniSlider object]

vb:rotary { RotaryEncoder Properties }
  -> [RotaryEncoder object]

[added B4] vb:xypad { XYPad Properties } 
  -> [XYPad object]


----- properties

-- View id is the table key, the tables value the view object.
-- e.g.: vb:text{ id="my_view", text="some_text"}
-- vb.views.my_view.visible = false or 
-- vb.views["my_view"].visible = false
vb.views 
  -> [table of views, which got registered via the "id" property]
