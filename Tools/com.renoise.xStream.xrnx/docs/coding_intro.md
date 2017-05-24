# Live coding with xStream

The next chapter of this documentation contains a full reference, listing all the  properties and methods of the xStream 'language'. But before you get that far, it's recommended to read this chapter, as it will attempt to explain the basics of creating an xStream model - even for someone not familiar with the lua language.

However, that's not the same as saying that there's not a pretty steep learning curve. Getting comfortable with xStream involves having a good understanding of Renoise itself - how notes, columns and pattern commands are specified. 
If you are familiar with these things, the xStream syntax should make some sense - after all, most of the 'baked-in' variables and properties are based on, or inspired by Renoise.

## A new model, a new `main`

To create a new model, follow these steps:

1. Click the '+' button in the model toolbar to show the 'Create/Import' dialog.
2. Next, select 'Create from scratch (empty)'

You should now see something that looks similar to this:

... IMAGE

> Note: if you don't see the editor as pictured above, press the arrow button on the left-hand side and/or switch to [expanded mode]. This will toggle the visibility of the code editor. 

What you're seeing is the `main` method. This is the basic function that is evaluated once for every line that xStream processes. 

Let's walk through the code as it appears.

    -------------------------------------------------------------------------------
    -- Empty configuration
    -------------------------------------------------------------------------------

    -- Use this as a template for your own creations. 
    --xline.note_columns[1].note_string = "C-4"
        

The variable `xline` refers to the _current line_ in the track, and `xline.note_columns[1]` provides access to the first note column in that line.  

Notice also that all lines are prefixed with two (or more) dashes - this means that it is a comment. Comments are excluded from the processing, and can be used for documentating the code.

## Live syntax checking

In xStream, you get immediate feedback on the code as it is entered - if something is not working, you'll see a warning - '⚠ syntax error'. 

Try it - enter the number "1" on an empty line, and see how the editor displays the warning. Mouse over, and you will be able to read the error message in the tooltip:

    unexpected symbol near '1'

Remove the '1' again to bring the model back to a working state. The error message should immediately disappear.

That the code is evaluated as you type makes it easy to experiment and learn from your mistakes. In addition, the code is also running in a 'sandbox', a protected environment which should prevent it from executing potentially harmful instructions such as accessing the file system.   

> NB: It's highly recommended to enable the [scripting console](...) in Renoise. Not only does the console displays more detailed error messages, it also allows you to 'print'. And very handily, you get the ability to 'reload all tools' from the tools menu - you WILL need this feature, eventually. 

## Reading from the pattern

Now, as the default model is just some text with a comment, there is apparently not much going on. But the model is actually already performing an important task - namely, reading input from the pattern and passing it through the main method. Let's demonstrate by adding our first statement inside the code editor: 

    -- print the note present in the note column
    print(xline.note_columns[1].note_string)

If you started streaming now (by pressing 'play'), you should see that the model would read from the pattern, and print this information to the console. Obviously, the pattern will need to contain some notes, or the output will just be empty.  


## Writing to the pattern

We can write pattern data by defining a method as simple as this one:

	-- produce an endless stream of C-4 notes..
	xline.note_columns[1].note_string = "C-4"

The note is defined as a string, exactly as it shows in the pattern editor: `C-4`.
 
## Changing the behaviour

While it is possible to type text into the code editor, this is hardly an optimal way to e.g. change notes or control the velocity of notes. 

A much better alternative is to use 'arguments' for this purpose. They allow variables (numbers/booleans/strings) to become bound to something else:

* On-screen controls (sliders, checkboxes, etc.)
* Automation or MIDI input
* The Renoise API 

See also [this chapter](model_arguments.md) for more information on arguments - their properties, and how to create them. 

## Automation

...


> < Previous - [Examples](example_models.md) &nbsp; &nbsp; | &nbsp; &nbsp; Next - [xStream Lua Reference](lua_reference.md) >
