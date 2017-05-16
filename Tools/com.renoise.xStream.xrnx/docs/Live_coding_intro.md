# Live coding with xStream

In xStream, it's easy to experiment with code, as it is compiled when entered. This means that you'll get isntant feedback on potential errors. 
In addition, the code is also running in a 'sandbox', a protected environment which should prevent it from executing potentially harmful instructions such as accessing the file system.   

So, let's dive straight into the exciting stuff! 
You're encouraged to copy/paste some of this code into xStream, to experience it first-hand.  

### Creating a model from scratch

1. Click the '+' button in the model toolbar to show the 'Create/Import' dialog.
2. Next, select 'Create from scratch (empty)'

That's it - you now have a default, empty model to work with.  

### Producing pattern data

We can write pattern data by defining a method as simple as this one:

	-- produce an endless stream of C-4 notes...
	xline.note_columns[1].note_string = "C-4"

The variable `xline` refers to the current line in the track, and `xline.note_columns[1]` provides access to the first note column in that line.   
The note is defined as a string, exactly as it shows in the pattern editor: `C-4`.
 
### Externalizing variables  

Everything in lua, or want to map it to a slider?
To make things more interesting, we can define an _argument_. 

 (hit the '+' button in the [arguments panel](#arguments)) and use it like this:

	-- produce notes which match the value of our argument
	xline.note_columns[1].note_value = args.my_value

We switched from `note_string` to `note_value`. Since we are setting the value of a note, `my_value` is expected to be a number between 0-121 (see the [Lua reference](#xstream-lua-reference) for more details)

### Producing automation data

TODO

