# Live coding with xStream

The next chapter of this documentation contains a full reference, listing all the  properties and methods of the xStream 'language'. But before you get that far, it's recommended to read this chapter, as it will attempt to explain the basics of creating an xStream model - even for someone not familiar with the lua language.

However, that's not the same as saying that there's not a pretty steep learning curve. Getting comfortable with xStream involves having a good understanding of Renoise itself - how notes, columns and pattern commands are specified. 
If you are familiar with these things, the xStream syntax should make some sense.

## A new model, a new `main`

As it was mentioned in the [introduction](), streaming works thanks to output being written just ahead of the playback. And the part which is reponsible for writing the output is called the 'main' method. 

So, to create a new main method, we need to create a new model. 
That's not hard, just follow these steps:

1. Click the '+' button in the model toolbar to show the 'Create/Import' dialog.
2. Next, select 'Create from scratch (empty)'

You should now see something that looks similar to this:

... illustration

What you're seeing is the `main` method. This is the basic function that is evaluated once for every line that xStream processes. 

> Note: if you don't see the editor as pictured above, perhaps that part of the user interface is collapsed or hidden. You can control this from the [main-toolbar ](main_toolbar.md#main-toolbar). 

Ready? ... OK, let's take a look at the code:

    -------------------------------------------------------------------------------
    -- Empty configuration
    -------------------------------------------------------------------------------

    -- Use this as a template for your own creations. 
    --xline.note_columns[1].note_string = "C-4"
        

The variable `xline` refers to the _current line_ in the track, and `xline.note_columns[1]` provides access to the first note column in that line.  

Notice also that all lines are prefixed with two (or more) dashes - in lua, this means that the line is a comment. Comments can be used for documentating the code.

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

And while we could continue like this, creating note-columns using the column index as the indicator:

	-- Example A: major triad in C...
	xline.note_columns[1].note_string = "C-4"
	xline.note_columns[2].note_string = "E-4"
	xline.note_columns[3].note_string = "G-4"

A different syntax is possible too. Consider the following example, which uses curly brackets {} instead of square ones []: 

	-- Example B: also a major triad in C...
	xline.note_columns = {
    {note_string = "C-4"},
    {note_string = "E-4"},
    {note_string = "G-4"},
  }

It looks similar and certainly creates similar output. But there is actually a subtle, but important difference: in the curly bracketed example, you are _redefining_ the note columns entirely. The first example will keep any existing data (i.e. what was read from the pattern and then passed on as `xline`). But in the second example, any existing note-columns - including the fourth, fifth etc. ones - has become 'undefined'. 

## Undefined content

...

## Changing things on the fly

While it is possible to type text into the code editor, this is hardly an optimal way to e.g. change notes or control the velocity of notes. A much better alternative is to use 'arguments' for this purpose. 

Essentially, arguments allow you to associate values in the code with something outside the code. This includes things such as an on-screen slider or checkbox, MIDI input or states within Renoise itself.

See also [this chapter](model_arguments.md) for more information on arguments - their properties, and how to create them. 

## Automation

...


> < Previous - [Examples](example_models.md) &nbsp; &nbsp; | &nbsp; &nbsp; Next - [xStream Lua Reference](lua_reference.md) >
