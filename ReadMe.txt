
This is the trunk of the XRNX tools. Developers are working here, here are
finalized tools and tools in progress.

Finalized, released tools and scripts will later on be mirrored to the svn
tags/ folder.

--

To work with the trunk in your user script folder, you can checkout the trunk
directly to the Renoise prefs folder:

$ cd RENOISE_PREFERENCES/Scripts
$ svn co https://xrnx.googlecode.com/svn/trunk/ . --username GOOGLE_USERNAME

Important:
The SVN Password is not your Google Accounts password, login and look here
instead: https://code.google.com/hosting/settings

PRO-TIP: You can also checkout the entire tree and work with symlinks. Example:

$ cd /path/to/xrnx
$ svn co https://xrnx.googlecode.com/svn/ . --username GOOGLE_USERNAME
$ cd RENOISE_PREFERENCES
$ rm -rf Scripts
$ ln -s /path/to/xrnx/trunk Scripts

This method allows you to easily swap out the trunk with experimental branches
and tags when needed.

--

Folder/File Structure:

"Tools"

  Here are regular Renoise tools that are also distributed later on to the
  users. Even though the trunk is a "working version", all scripts and tools
  in here should at least parse and load in Renoise without don't spit out
  errors. If you are working on something that is not yet ready for other
  developers, create a branch for this and do your changes temporarily there
  please...


"Libraries"

  LUA files that you want to share with other tools and developers.
  !! Please note that distributing tools should never rely on ANY Libraries!!
  Aka, if your tools depends on a library, copy and paste if "into" your tool
  before distributing it, make sure your distributed tools are always self
  contained! The "Libraries" folder should only used temporarily for developers.


"Snippets"

  Some useful (or not) Renoise related LUA code that does not make up a "tool",
  but still might be interesting to share with other.


"Documentation"

  "Official" Renoise Scripting Dev docs on can be found here.
