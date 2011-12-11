--[[============================================================================
Lua Standard Library and Extensions
============================================================================]]--

--[[

This is a reference for standard global Lua functions and tools that were
added/changed by Renoise.

All standard Lua libraries are included in Renoise as well. You can find the
full reference here: <http://www.lua.org/manual/5.1/manual.html#5>

Do not try to execute this file. It uses a .lua extension for markup only.

]]--

-------------------------------------------------------------------------------
-- globals
-------------------------------------------------------------------------------

-------- Added

-- An iterator like ipairs, but in reverse order
-- > examples: t = {"a", "b", "c"}  
-- > for k,v in ripairs(t) do print(k, v) end -> "3 c, 2 b, 1 a"
ripairs(table) -> [iterator function]

-- Return a string which lists properties and methods of class objects
objinfo(class_object) -> [string]

-- Recursively dumps a table and all its members to the std out (console)
rprint(table)

-- Dumps properties and methods of class objects (like renoise.app())
oprint(table)


-------- Changed

-- Also returns a class object's type name. For all other types the standard
-- Lua type function is used
-- > examples: class "MyClass"; function MyClass:__init() end  
-- >          print(type(MyClass)) -> "MyClass class"  
-- >          print(type(MyClass())) -> "MyClass"
type(class_object or class or anything else) -> [string]

-- Also compares object identities of Renoise API class objects: 
-- > examples: 
-- >          print(rawequal(renoise.app(), renoise.app())) --> true  
-- >          print(rawequal(renoise.song().track[1],
-- >            renoise.song().track[1]) --> true  
-- >          print(rawequal(renoise.song().track[1],
-- >            renoise.song().track[2]) --> false
rawequal(obj1, obj2) -> [boolean]


-------------------------------------------------------------------------------
-- debug
-------------------------------------------------------------------------------

------- Added

-- Shortcut to remdebug.session.start(), which starts a debug session:
-- launches the debugger controller and breaks script execution. See
-- "Debugging.txt" in the documentation root folder for more info.
debug.start()

-- Shortcut to remdebug.session.stop: stops a running debug session
debug.stop()


-------------------------------------------------------------------------------
-- table
-------------------------------------------------------------------------------

------- Added

-- Create a new, or convert an exiting table to an object that uses the global
-- 'table.XXX' functions as methods, just like strings in Lua do.
-- > examples: t = table.create(); t:insert("a"); rprint(t) -> [1] = a;  
--           t = table.create{1,2,3}; print(t:concat("|")); -> "1|2|3";
table.create([t]) -> [table]


-- Returns true when the table is empty, else false and will also work
-- for non indexed tables
-- > examples: t = {};          print(table.is_empty(t)); -> true;  
-- >           t = {66};        print(table.is_empty(t)); -> false;  
-- >           t = {["a"] = 1}; print(table.is_empty(t)); -> false;
table.is_empty(t) -> [boolean]

-- Count the number of items of a table, also works for non index
-- based tables (using pairs).
-- > examples:  t = {["a"]=1, ["b"]=1}; print(table.count(t))  -> 2
table.count(t) -> [number]

-- Find first match of 'value' in the given table, starting from element
-- number 'start_index'. Returns the first !key! that matches the value or nil
-- > examples: t = {"a", "b"}; table.find(t, "a") -> 1;  
-- >          t = {a=1, b=2}; table.find(t, 2) -> "b"  
-- >          t = {"a", "b", "a"}; table.find(t, "a", 2) -> "3"  
-- >          t = {"a", "b"}; table.find(t, "c") -> nil
table.find(t, value [,start_index]) -> [key or nil]


-- Return an indexed table of all keys that are used in the table
-- > examples: t = {a="aa", b="bb"}; rprint(table.keys(t)); -> "a", "b"  
-- >           t = {"a", "b"};       rprint(table.keys(t)); -> 1, 2
table.keys(t) -> [table]

-- Return an indexed table of all values that are used in the table
-- > examples: t = {a="aa", b="bb"}; rprint(table.values(t)); -> "aa", "bb"  
-- >           t = {"a", "b"};       rprint(table.values(t)); -> "a", "b"
table.values(t) -> [table]


-- Copy the metatable and all first level elements of the given table into a
-- new table. Use table.rcopy to do a recursive copy of all elements
table.copy(t) -> [table]

-- Deeply copy the metatable and all elements of the given table recursively
-- into a new table - create a clone with unique references.
table.rcopy(t) -> [table]


-- Recursively clears and removes all table elements
table.clear(t)


-------------------------------------------------------------------------------
-- os
-------------------------------------------------------------------------------

------- Added

-- Returns the platform the script is running on:
-- "WINDOWS", "MACINTOSH" or "LINUX"
os.platform() -> [string]

-- Returns the current working dir. Will always be the scripts directory
-- when executing a script from a file
os.currentdir() -> [string]

-- Returns a list of directory names (names, not full paths) for the given
-- parent directory. Passed directory must be valid, or an error will be thrown.
os.dirnames(path) -> [table of strings]

-- Returns a list file names (names, not full paths) for the given
-- parent directory. Second optional argument is a list of file extensions that
-- should be searched for, like {"*.wav", "*.txt"}. By default all files are
-- matched. The passed directory must be valid, or an error will be thrown.
os.filenames(path [, {file_extensions}]) -> [table of strings]

-- Creates a new directory. mkdir can only create one new sub directory at the
-- same time. If you need to create more than one sub dir, call mkdir multiple
-- times. Returns true if the operation was successful; in case of error, it
-- returns nil plus an error string.
os.mkdir(path) -> [boolean, error_string or nil]

-- Moves a file or a directory from path 'src' to 'dest'. Unlike 'os.rename'
-- this also supports moving a file from one file system to another one. Returns
-- true if the operation was successful; in case of error, it returns nil plus 
-- an error string.
os.move(src, dest) -> [boolean, error_string or nil]


------- Changed

-- Replaced with a temp directory and name which renoise will clean up on exit
-- extension will be ".tmp" when not specified
os.tmpname([extension]) -> [string]

-- Replaced with a high precision timer (still expressed in milliseconds)
os.clock() -> [number]

-- Will not exit, but fire an error that os.exit() can not be called
os.exit()


-------------------------------------------------------------------------------
-- io
-------------------------------------------------------------------------------

------- Added

-- Returns true when a file, folder or link at the given path and name exists
io.exists(filename) -> [boolean]

-- Returns a table with status info about the file, folder or link at the given
-- path and name, else nil the error and the error code is returned.
--
-- The returned valid stat table contains the following fields:
--
-- + dev,    (number): device number of filesystem
-- + ino,    (number): inode number
-- + mode,   (number): unix styled file permissions
-- + type,   (string): type ("file", "directory", "link", "socket",
--                   "named pipe", "char device" or "block device")
-- + nlink,  (number): number of (hard) links to the file
-- + uid,    (number): numeric user ID of file's owner
-- + gid,    (number): numeric group ID of file's owner
-- + rdev,   (number): the device identifier (special files only)
-- + size,   (number): total size of file, in bytes
-- + atime,  (number): last access time in seconds since the epoch
-- + mtime,  (number): last modify time in seconds since the epoch
-- + ctime,  (number): inode change time (NOT creation time!) in seconds
io.stat(filename) -> [table or (nil, error, error no)]

-- Change permissions of a file, folder or link. mode is a unix permission
-- styled octal number (like 755 - WITHOUT a leading octal 0). Executable,
-- group and others flags are ignored on windows and won't fire errors
io.chmod(filename, mode) -> [true or (nil, error, error no)]


------- Changed

-- All io functions use UTF8 as encoding for the file names and paths. UTF8
-- is used for LUA in the whole API as default string encoding...


-------------------------------------------------------------------------------
-- math
-------------------------------------------------------------------------------

------- Added

-- Converts a linear value to a db value. db values will be clipped to
-- math.infdb
-- > example: print(math.lin2db(1.0)) -> 0  
-- >          print(math.lin2db(0.0)) -> -200 (math.infdb)
math.lin2db(number) -> [number]

-- Converts a dB value to a linear value
-- > example: print(math.db2lin(math.infdb)) -> 0  
-- >          print(math.db2lin(6.0)) -> 1.9952623149689
math.db2lin(number) -> [number]

-- db values at and below this value will be treated as silent (linearly 0)
math.infdb -> [-200]


-------------------------------------------------------------------------------
-- bit (added)
-------------------------------------------------------------------------------

-- Integer, Bit Operations, provided by <http://bitop.luajit.org/>
-- Take a look at <http://bitop.luajit.org/api.html> for the complete reference
-- and examples please...

-- Normalizes a number to the numeric range for bit operations and returns it.
-- This function is usually not needed since all bit operations already
-- normalize all of their input arguments.
bit.tobit(x) -> [number]

-- Converts its first argument to a hex string. The number of hex digits is
-- given by the absolute value of the optional second argument. Positive
-- numbers between 1 and 8 generate lowercase hex digits. Negative numbers
-- generate uppercase hex digits. Only the least-significant 4*|n| bits are
-- used. The default is to generate 8 lowercase hex digits.
bit.tohex(x [,n]) -> [string]

-- Returns the bitwise not of its argument.
bit.bnot(x) -> [number]

-- Returns either the bitwise or, bitwise and, or bitwise xor of all of its
-- arguments. Note that more than two arguments are allowed.
bit.bor(x1 [,x2...]) -> [number]
bit.band(x1 [,x2...]) -> [number]
bit.bxor(x1 [,x2...]) -> [number]

-- Returns either the bitwise logical left-shift, bitwise logical right-shift,
-- or bitwise arithmetic right-shift of its first argument by the number of
-- bits given by the second argument.
bit.lshift(x, n) -> [number]
bit.rshift(x, n) -> [number]
bit.arshift(x, n) -> [number]

-- Returns either the bitwise left rotation, or bitwise right rotation of its
-- first argument by the number of bits given by the second argument. Bits
-- shifted out on one side are shifted back in on the other side.
bit.rol(x, n) -> [number]
bit.ror(x, n) -> [number]

-- Swaps the bytes of its argument and returns it. This can be used to convert
-- little-endian 32 bit numbers to big-endian 32 bit numbers or vice versa.
bit.bswap(x) -> [number]

