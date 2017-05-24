# Live coding with xStream

This documentation contains a [full reference](lua_reference.md) of the xStream properties and methods. But before you get that far, it's recommended to read this chapter, as it will attempt to explain the basics of xStream programming - even for the non-programmers among us.

However, that's not the same as saying that there's not a pretty steep learning curve. Getting comfortable with xStream also involves having a good understanding of Renoise itself - how notes, columns and pattern commands are specified, and so on. But if you are already familiar with these things, the xStream syntax could make sense right away.

## A new model, a new `main`

As it was mentioned in the [introduction](), streaming works thanks to output being written just ahead of the playback. And the part which is reponsible for writing the output is called the 'main' method. 

So, to create a new main method, we need to create a new model. 
That's not hard, just follow these steps:

1. Click the '+' button in the model toolbar to show the 'Create/Import' dialog.
2. Next, select 'Create from scratch (empty)'

You should now see something similar to this:

... illustration

> Note: if you don't see the editor as pictured above, perhaps that part of the user interface is collapsed or hidden. You can control this from the [main-toolbar ](main_toolbar.md#main-toolbar). 

Ready? ... OK, let's take a look at the code:

    -------------------------------------------------------------------------------
    -- Empty configuration
    -------------------------------------------------------------------------------

    -- Use this as a template for your own creations. 
    --xline.note_columns[1].note_string = "C-4"
        

The variable `xline` refers to the _current line_ in the track, and `xline.note_columns[1]` provides access to the first note column in that line.  

Notice also that all lines are prefixed with two (or more) dashes - in lua, this means that the line is a comment. Comments can be used for documentating the code to yourself and others.

## Live syntax checking

In xStream, you get immediate feedback on the code as it is entered - if something is not working, you'll see a warning - '⚠ syntax error'. 

Try it - enter the number "1" on an empty line, and see how the editor displays the warning. Mouse over, and you will be able to read the error message in the tooltip:

    unexpected symbol near '1'

Remove the '1' again to bring the model back to a working state. The error message should immediately disappear.

That the code is evaluated as you type makes it easy to experiment and learn from your mistakes. In addition, the code is also running in a 'sandbox', a protected environment which should prevent it from executing potentially harmful instructions such as accessing the file system.   

> NB: At this stage, it's highly recommended to enable the [scripting console](...) in Renoise. Not only does the console displays more detailed error messages, it also allows you to 'print'. And very handily, you get the ability to 'reload all tools' from the tools menu - you WILL appriciate this feature. 

## Reading from the pattern

Now, as the default model is just some text with a comment, there is apparently not much going on. But the model is actually already performing an important task - namely, reading input from the pattern and passing it through the main method. Let's demonstrate by adding our first statement inside the code editor: 

    -- print the note present in the note column
    print(xline.note_columns[1].note_string)

If you started streaming now (by pressing 'play'), you should see that the model would read from the pattern, and print this information to the console. Obviously, the pattern will need to contain some notes, or the output will just be empty.  


## Writing to the pattern

Again, `xline` is at the centre of attention. Because, you also create output by working with this object.

	-- produce an endless stream of C-4 notes..
	xline.note_columns[1].note_string = "C-4"

The note is defined as a string, exactly as it shows in the pattern editor: `C-4`.
Alternatively, we could have defined the note using a numeric value: 

	-- produce an endless stream of C-4 notes..
	xline.note_columns[1].note_value = 48

And we could continue like this, creating one note-columns after another, using the column index as the indicator:

	-- a major triad in C...
	xline.note_columns[1].note_string = "C-4"
	xline.note_columns[2].note_string = "E-4"
	xline.note_columns[3].note_string = "G-4"

Effect columns are defined pretty much the same way: 

	-- produce an endless stream of Zxx commands:
	xline.effect_columns[1].number_string = "0Z"
	xline.effect_columns[1].amount_value = 1

## Transforming pattern data

As you might have noticed, the previous examples were sometimes using `note_string`, and at other times, `note_value`. The difference is that one takes a string as argument and the other one is a numeric representation of the same value. 

Having a string representation is good, because it's easier to remember `A-4` than the numeric representation of that pitch. But it would be pretty complex to raise a note by an octave - you would have to pick apart the string, and create a new string each time. 

Here, it's much easier and more convenient to simply raise the value by 12 (12 semitones == one octave): 

	-- raise existing notes by one octave 
	xline.note_columns[1].note_value = xline.note_columns[1].note_value + 12

**NB: The code above is actually a bad example**, as the notes will eventually exceed the valid range. Maybe not the first time you run the code, but eventually. The reason is simple enough: notes can't have a value higher than 120. To fix this problem, use a function such as `math.min(120,my_note_value)` or, to address both upper and lower boundaries at the same, clamp the value using `cLib.clamp_value(val,min,max)`



> Note: if you have the need to convert between string and number values, the classes xNoteColumn and xEffectColumn have a lot of handy methods. See the [lua reference](lua_reference.md#supporting-classes) for more information

## Changing things over time

Since xStream is all about streaming and generating output over time, there are two important properties to learn about. 

The first one is called `xinc`. This is an ever-increasing counter that starts from 0 as you start streaming and counts upwards by one, for each line that got processed. 

To demonstrate, add the following statement to the main method:

    print('xinc',xinc)

Press play and you should see this output in the scripting console:

    xinc  0
    xinc  1
    xinc  2
    etc.

The _other_ important time-keeper is called xpos. This is a regular `renoise.SongPos` that reflect the currently playing/streaming position in the pattern. Technically, a song-pos is a table-alike object containing two properties: `line` and `sequence`.

Try to replace the previous print statement with this one:

    print('xpos',xpos)

When pressing play, this time you should see the following output:

    xpos  1, 1
    xpos  1, 2
    xpos  1, 3
    xpos  1, 4
    etc.

The difference between the two is that `xinc` does not reflect the playback position in the pattern. For example, in case you have looped the pattern it will keep increasing as the streaming reaches the end of the pattern and starts over at the top. And also, `xinc` starts counting from zero while `xpos` counts from 1. 

Rule of thumb: if the output should somehow synchronize with the pattern, use `xpos`. Otherwise, `xinc` is often the better choice.

## Changing things on the fly

While it is possible to type text into the code editor, this is hardly an optimal way to e.g. change notes or control the velocity of notes. A much better alternative is to use _arguments_ for this kind of purpose. 

Essentially, arguments allow you to associate values in the code with something outside the code. This includes things such as an on-screen slider or checkbox, MIDI input or states within Renoise itself.

While that might sound complicated, arguments are actually really simple to work with. Here is an example:

    -- assigns the value of my_arg to a note
    xline.note_columns[1].note_value = args.my_arg 

In the context of the `main` method, arguments are treated just like any other value. There is more to arguments than this, but that is all covered in more detail [here](model_arguments.md) (how to create arguments, what their properties are, etc.)


## Writing automation

...

## Advanced topic: defined vs. undefined

We have already covered how you can access the `xline` and modify notes or write effect commands. But there is an additional feature which might not be immediately obvious. It involves how xStream is dealing with 'undefined' content. 

Take a quick look at this previous example:

	-- Example A: major triad in C...
	xline.note_columns[1].note_string = "C-4"
	xline.note_columns[2].note_string = "E-4"
	xline.note_columns[3].note_string = "G-4"

Now consider the following example, which packs the note columns in curly brackets {} instead of square ones: 

    -- Example B: also a major triad in C...
    xline.note_columns = {
      {note_string = "C-4"},
      {note_string = "E-4"},
      {note_string = "G-4"},
    }

It looks similar and certainly creates similar output. But there is actually an important difference: in the second example, you are _redefining_ the note columns entirely. Any existing information in note-columns - including the fourth, fifth etc. ones - have become 'undefined'. 

Perhaps this doesn't sound like a big deal, but 'undefined' has a special meaning in xStream. Using the global `clear_undefined` flag, you can decide whether undefined content should be erased on output or left as-is. 

One example that clearly demonstrates how much of a difference this makes is the  model called `Random Increase`. Running it with `clear_undefined` disabled will gradually amass a huge amount of notes. When enabled, all you will get is a periodic note, every now and then. 


> < Previous - [Examples](example_models.md) &nbsp; &nbsp; | &nbsp; &nbsp; Next - [xStream Lua Reference](lua_reference.md) >
