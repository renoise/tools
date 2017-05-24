# Known limitations, gotchas

**xStream operation is limited to a single track**. This is an intentional limitation, to make give the tool a certain focus and simplicity. The roadmap however, involves multiple concurrent streaming processes. And [workarounds] exist, too. 

**xStream requires steady updates:** xStream is based on the Renoise API, which is running in the UI thread of the software. This means that you've got an update rate which might vary, according to the CPU load. As a result, gaps might appear in the output - finetune this behaviour in options dialog (writeahead factor).  

**UI Modal Dialogs:** A modal dialog is a specific type of dialogs which prevent you from accessing the program until you have chosen an action, with a common example being the "Are you sure you want to XX" prompt. Triggering this type of dialog should be avoided while streaming, as it will produce a gap in the output while visible.  

**Lua block comments:** The block comment is a special form of comment that allows you to wrap an entire section of text, using square brackets. The xStream editor will **not** allow you to enter this type of comment:

    --[[
      A block comment 
      can span several lines
      ...
    ]]

You should get a warning if you enter such a comment and try to save the model.  
You can only use regular line comments such as this one

    -- this is a comment
    print("And this is code")


