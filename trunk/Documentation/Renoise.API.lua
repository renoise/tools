--[[============================================================================
Renoise Application API Reference
============================================================================]]--

--[[

This reference lists the content of the main "renoise" namespace. All renoise
related functions and classes are nested in this namespace.

Please read the INTRODUCTION.txt first to get an overview about the complete
API, and scripting in Renoise in general... 

Do not try to execute this file. It uses a .lua extension for markups only.

]]


--------------------------------------------------------------------------------
-- renoise
--------------------------------------------------------------------------------

-- consts

-- currently 1.0. Any changes in the API which are not backwards compatible,
-- will increase the internal APIs major version number (e.g. from 1.4 -> 2.0). 
-- All other backwards compatible changes, like new functionality, new functions
-- and classes which do not break existing scripts, will increase only the minor
-- version number (e.g. 1.0 -> 1.1).
renoise.API_VERSION -> [number]

-- renoise version "Major.Minor.Revision[ AlphaBetaRcVersion][ Demo]"
renoise.RENOISE_VERSION -> [string]


-- functions

renoise.app() -> [renoise.Application object]
renoise.song() -> [renoise.Song object]
renoise.tool() -> [renoise.ScriptingTool object]

-- not much going on here:
-- for renoise.Application, see Renoise.Application.API.txt
-- for renoise.Song, see Renoise.Song.API.txt
-- for renoise.ScriptingTool, see Renoise.ScriptingTool.API.txt

