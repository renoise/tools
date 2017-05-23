# Live coding with xStream

In xStream, you get immediate feedback on the code as it is entered - if something is not working, you'll see a warning - '⚠ syntax error'. This makes it easy to experiment and learn from potential mistakes.  
In addition, the code is also running in a 'sandbox', a protected environment which should prevent it from executing potentially harmful instructions such as accessing the file system.   

> NB: For these exercises, we rely on the [scripting console](...) in Renoise. Not only can you 'print' output here, the console also displays detailed more error messages than what appears in the UI. It's highly recommended to enable this feature in Renoise.

## Creating a new model 

To create a new model, follow these steps:

1. Click the '+' button in the model toolbar to show the 'Create/Import' dialog.
2. Next, select 'Create from scratch (empty)'

You should now see something that looks similar to this:

... IMAGE

> Note: if you don't see the editor as pictured above, press the arrow button on the left-hand side. This will toggle the visibility of the editor. 

## Our first statement

There is not much going on in the code - looks pretty empty, right? But the model is actually already performing an important task - namely, being able to read from the pattern. Let's demonstrate by adding our first statement inside the code editor: 

    -- print the note present in the note column
    print(xline.note_columns[1].note_string)

If you started streaming now (by pressing 'play'), you should see that the model would read from the pattern, and print this information to the console. Obviously, the pattern will need to contain some notes, or the output will just be empty.  


## Producing pattern data

We can write pattern data by defining a method as simple as this one:

	-- produce an endless stream of C-4 notes..
	xline.note_columns[1].note_string = "C-4"

The variable `xline` refers to the current line in the track, and `xline.note_columns[1]` provides access to the first note column in that line.   
The note is defined as a string, exactly as it shows in the pattern editor: `C-4`.
 
## Controlling code behaviour

Everything in lua, or want to map it to a slider?
To make things more interesting, we can define an _argument_. 

 (hit the '+' button in the [arguments panel](#arguments)) and use it like this:

	-- produce notes which match the value of our argument
	xline.note_columns[1].note_value = args.my_value

We switched from `note_string` to `note_value`. Since we are setting the value of a note, `my_value` is expected to be a number between 0-121 (see the [Lua reference](#xstream-lua-reference) for more details)

## Producing automation data

...TODO

