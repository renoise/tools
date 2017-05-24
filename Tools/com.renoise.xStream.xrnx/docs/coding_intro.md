# Live coding with xStream

To get comfortable using xStream, it's essential to at least have a good understanding of how notes, columns and pattern commands work in Renoise. 
If you do, it should be simple enough to read the syntax -  because all the variables and properties are modelled after their Renoise counterpart, 
The rest - the programming part - is using pretty basic, lua-based logic. The results , with a small bag of tricks on top. Most are documented through the available   that can be adapted to various purposes. The whole idea was to make the pattern more accessible, after all. 

   is more required than actually understanding 

## Live editing

In xStream, you get immediate feedback on the code as it is entered - if something is not working, you'll see a warning - '⚠ syntax error'. This makes it easy to experiment and learn from potential mistakes.  
In addition, the code is also running in a 'sandbox', a protected environment which should prevent it from executing potentially harmful instructions such as accessing the file system.   

> NB: For these exercises, we rely on the [scripting console](...) in Renoise. Not only can you 'print' output here, the console also displays detailed more error messages than what appears in the UI. It's highly recommended to enable this feature in Renoise.

## A new model 

To create a new model, follow these steps:

1. Click the '+' button in the model toolbar to show the 'Create/Import' dialog.
2. Next, select 'Create from scratch (empty)'

You should now see something that looks similar to this:

... IMAGE

> Note: if you don't see the editor as pictured above, press the arrow button on the left-hand side. This will toggle the visibility of the editor. 

## Reading 

There is not much going on in the code - looks pretty empty, right? But the model is actually already performing an important task - namely, being able to read from the pattern. Let's demonstrate by adding our first statement inside the code editor: 

    -- print the note present in the note column
    print(xline.note_columns[1].note_string)

If you started streaming now (by pressing 'play'), you should see that the model would read from the pattern, and print this information to the console. Obviously, the pattern will need to contain some notes, or the output will just be empty.  


## Writing

We can write pattern data by defining a method as simple as this one:

	-- produce an endless stream of C-4 notes..
	xline.note_columns[1].note_string = "C-4"

The variable `xline` refers to the current line in the track, and `xline.note_columns[1]` provides access to the first note column in that line.   
The note is defined as a string, exactly as it shows in the pattern editor: `C-4`.
 
## Tweaking

Use 'arguments' in the code to have variables (number/boolean/string) that are bound to on-screen controls, automation, MIDI input or states with Renoise itself.


## Automation

...TODO

