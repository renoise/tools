
This is the trunk of the XRNX tools. Developers are working here; here are
finalized tools, the official Renoise Lua API documentation and tools in 
progress.

--

To work with the trunk in your Renoise user script folder, you can checkout the
trunk directly to the Renoise prefs folder:

$ cd RENOISE_PREFERENCES/Scripts
$ svn co https://xrnx.googlecode.com/svn/trunk/ . --username GOOGLE_USERNAME

Important:
The SVN Password is not your Google Accounts password, login and look here
instead: https://code.google.com/hosting/settings

--

Folder/File Structure:

"Tools"

  Here are XRNX tools that are already distributed, and tools which are still
  in progress. Even though the trunk is a "working version", all scripts and 
  tools in here should at least parse and load in Renoise, without spitting out 
  errors. If you are working on something that is not yet ready for other 
  developers, create a branch for this and do your changes temporarily there 
  please...


"Libraries"

  Here are Lua files you want to share with other tools and developers, aka 
  Lua code that was made to be reused in multiple tools.
  !! Note: Distributed XRNX files should never rely on ANY external Libraries!!
  If your tools depends on a library, copy and paste this library locally into 
  your tool before distributing it: make sure your distributed tools are always 
  self-contained! The "Libraries" folder should only used temporarily for 
  developers who are working with the trunk.


"Snippets"

  Some useful (or not) Renoise related Lua code that does not make up a "tool",
  but still might be interesting to share.


"Documentation"

  "Official" Renoise Scripting API documentation can be found here.
