--[[============================================================================
Renoise Application API Reference
============================================================================]]--

--[[

This reference lists the content of the main "renoise" namespace. All Renoise
related functions and classes are nested in this namespace.

Please read the INTRODUCTION first to get an overview about the complete
API, and scripting for Renoise in general... 

Do not try to execute this file. It uses a .lua extension for markup only.

]]--


--------------------------------------------------------------------------------
-- renoise
--------------------------------------------------------------------------------

-------- Constants

-- Currently 3.0. Any changes in the API which are not backwards compatible,
-- will increase the internal API's major version number (e.g. from 1.4 -> 2.0). 
-- All other backwards compatible changes, like new functionality, new functions
-- and classes which do not break existing scripts, will increase only the minor
-- version number (e.g. 1.0 -> 1.1).
renoise.API_VERSION -> [number]

-- Renoise Version "Major.Minor.Revision[ AlphaBetaRcVersion][ Demo]"
renoise.RENOISE_VERSION -> [string]


-------- Functions

renoise.app() -> [renoise.Application object]
renoise.song() -> [renoise.Song object]
renoise.tool() -> [renoise.ScriptingTool object]

-- Not much else going on here...
-- for renoise.Application, see Renoise.Application.API,
-- for renoise.Song, see Renoise.Song.API,
-- for renoise.ScriptingTool, see Renoise.ScriptingTool.API,
-- and so on.

