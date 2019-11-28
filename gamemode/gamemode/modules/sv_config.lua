-- Config file used by early initialization of core.lua
local Var, var, ext, lod, share, sibs, filter = {}, {}, {}, {}, {}, {}, {}
local Prefix = "game"

--[[
	Description: Adds variables or extensions
--]]
function Var.Add( field, name, default, desc, shared ) var[ field ] = CreateConVar( Prefix .. "_" .. name, default, FCVAR_ARCHIVE, desc ) if shared then share[ field ] = var[ field ] end end
function Var.Activate( field, tab ) ext[ field ] = tab end
function Var.SetShared( field, val ) share[ field ] = { Value = val, GetString = function( s ) return s.Value end } end
function Var.Present( field, val ) if val then lod[ field ] = val else return lod[ string.lower( field ) ] end end

--[[
	Description: Easy-access get functions for each field
--]]
function Var.Get( field ) return var[ field ] and var[ field ]:GetString() or "" end
function Var.GetInt( field ) return var[ field ] and var[ field ]:GetInt() or 0 end
function Var.GetFloat( field ) return var[ field ] and var[ field ]:GetFloat() or 0 end
function Var.GetBool( field ) return var[ field ] and var[ field ]:GetBool() end
function Var.GetDefault( field ) return var[ field ] and var[ field ]:GetDefault() end
function Var.GetExtension( field, func ) return ext[ field ] and ext[ field ][ func ] or func != nil and function() end or ext[ field ] end
function Var.GetShared() return share end
function Var.GetSiblings() return sibs end
function Var.GetChatFilter() return filter end


-- Category: Server
Var.Add( "ServerID", "server_id", 0, "Defines the Server ID with which the SQL tables are linked\n - Changing only useful in a multi-server setup\n - Must be a number! Leave it 0 for using the default tables" )
Var.Add( "ServerDL", "server_dl", "", "Backup Server DL value to still resolve the server type in the first startup\n - Be sure to set this in server.vdf for good backup" )
Var.Add( "ServerOperator", "server_op", "", "The Steam ID of the server operator\n - This player will always have Owner rank and can be used to set others to admin in the database" )
Var.Add( "ServerDebug", "server_debug", 0, "Shows prints in console about the state of the server\n - This isn't really useful if the server console isn't used much" )
Var.Add( "ServerCollect", "server_mem_clean", 3, "The type of garbage collection to perform:\n - 0. None\n - 1. On new player connection\n - 2. On player disconnection\n - 3. Both" )
Var.Add( "BlockExtensions", "extension_blacklist", "", "The extensions that shouldn't be loaded\n - Just putting the name of the extension (excluding sv_ or cl_) here will work\n - Separate multiple ones with commas" )

-- Category: Engine
Var.Add( "StartLimit", "start_limit", 290, "The maximum speed you can have leaving the start zone\n - Depending on walk speed 278 or 290 for Bunny Hop and 355 for Surf", true )
Var.Add( "SpeedLimit", "speed_limit", 3500, "The maximum achievable speed in the server\n - If you want to bypass this for a few maps, use the map option instead", true )
Var.Add( "WalkSpeed", "walk_speed", 260, "The walk speed of the player without weapons", true )
Var.Add( "GravityMultiplier", "lowgrav_mult", 0.6, "The fraction of normal gravity the player will get when going into low gravity style", true )
Var.Add( "PackMultiplier", "jumppack_mult", 250, "The multiplier of how the player will be influenced when gliding", true )
Var.Add( "UseJumpPack", "jumppack_enable", 1, "Whether or not the jump pack style is enabled on Surf", true )
Var.Add( "CSSJumps", "css_jumps", 1, "Whether or not to use CS:S-like jump height", true )
Var.Add( "CSSGains", "css_gain", 1, "Whether or not to use CS:S-like gains", true )
Var.Add( "CSSDuck", "css_duck", 1, "Whether or not to use CS:S-like ducking", true )

-- Category: SQL
Var.Add( "SQLType", "sql_type", "sqlite", "The type of SQL server\n - Possible values: sqlite, mysqloo, tmysql4" )
Var.Add( "SQLHost", "sql_host", "127.0.0.1", "The host for the SQL server\n - Has to be an IPv4 address" )
Var.Add( "SQLUser", "sql_user", "root", "The username used for authentication to the SQL server" )
Var.Add( "SQLPass", "sql_pass", "", "The password used for authentication to the SQL server" )
Var.Add( "SQLDatabase", "sql_database", "gmsql", "The database where all tables will be present in" )
Var.Add( "SQLPrefix", "sql_prefix", "game", "The prefix of the used tables\n - This shouldn't be too long or contain non-alphanumeric characters" )
Var.Add( "SQLPort", "sql_port", 3306, "The port the SQL server is listening on" )
Var.Add( "SQLDebug", "sql_debug", 0, "Whether SQL debugging mode is enabled" )

-- Category: Commands
Var.Add( "ModelAllowed", "allow_models", 1, "Whether or not custom models are allowed" )
Var.Add( "ChatFilter", "chat_filter", 1, "Enables or disables the chat filter" )
Var.Add( "CommandLimit", "command_limit", 0.8, "The amount of allowed time between two input messages\n - Limits: [0, ~]" )
Var.Add( "URLWebsite", "url_website", "", "The URL that will open when people use the !website command" )
Var.Add( "URLForum", "url_forum", "", "The URL that will open when people use the !forum command" )
Var.Add( "URLChangelogs", "url_changelog", "", "The URL that will open when people use the !version command" )
Var.Add( "URLTutorial", "url_tutorial", "https://www.youtube.com/watch?v=vmREZAGx_B8", "The URL that will open when people use the !tutorial command" )

-- Category: RTV
Var.Add( "MapLength", "rtv_length", 60, "The duration of the map in minutes\n - Set this to 0 to not have the RTV system be active" )
Var.Add( "MapExtend", "rtv_extend", 15, "The time that will be added when a map is extended in minutes" )
Var.Add( "MapRepeat", "rtv_repeat_cycle", 6, "The amount of maps that have to be in between playing the same map again" )
Var.Add( "MapNotifications", "rtv_notification_list", "15,10,5,2,1", "A comma separated list of times until a vote where the players will be notified of the time left\n - Make sure this is sorted from high to low" )
Var.Add( "VoteWait", "rtv_waitperiod", 5, "The time players will have to wait before they can RTV in minutes\n - Set this to 0 to remove the limit" )
Var.Add( "VoteDuration", "rtv_duration", 30, "The amount of time players will be able to vote" )
Var.Add( "VoteFraction", "rtv_fraction", 2 / 3, "The fraction of players that need to have voted before a vote is started" )
Var.Add( "VoteLimit", "rtv_limit_use", 1, "Whether or not RTV limits should be applied" )
Var.Add( "VoteLimitCount", "rtv_limit_minplayer", 4, "The amount of players above which RTV limits will be applied" )
Var.Add( "VoteRandomize", "rtv_tie_randomize", 1, "Whether or not to randomize the vote when a tie occurs" )
Var.Add( "VoteAdjust", "rtv_adjust_time", 1, "Whether or not to adjust RTV length by average Normal times" )

-- Category: Timer and gameplay
Var.Add( "PlaySound", "play_wrsound", 1, "Whether or not WR sounds sound play when someone gets a #1 time" )

-- Category: Players and ranking
Var.Add( "TopLimit", "top_limit", 50, "The amount of players will be shown in the top lists\n - Recommended limits: [1, 250]" )
Var.Add( "PageSize", "page_size", 25, "The amount of items that will be shown on a single page of entries displayed in GUIs" )
Var.Add( "RankScalars", "ranking_scalars", "1.05,0.75,0.85,0.70,0.60,0.60,0.25,0.40,0.80,0.90,0.95,0.10,1.00,1.00", "The ranking scalar for each style, comma separated\n - The index inside of this array corresponds to the style id\n - Recommended limits per item: [0.50, 1.25]" )
Var.Add( "AveragePercentage", "ranking_average_perc", 50, "Defines which times compared to the #1 time should be included in average calculation\n - The maximum time still included would be (#1) * (Value / 100 + 1)\n - Recommended limits: [0, ~]" )

-- Category: Multi-call console commands
concommand.Add( Prefix .. "_addsibling", function( _, _, args ) for _,n in pairs( string.Explode( ",", args[ 1 ] ) ) do sibs[ n ] = { Name = args[ 2 ], IP = args[ 3 ] } if Core then Core.AddAlias( "hop", "go" .. n ) end end end )
concommand.Add( Prefix .. "_chat_solobadword", function( _, _, args ) for i = 1, #args do filter[ #filter + 1 ] = { Type = "SoloBad", Data = args[ i ] } end end )
concommand.Add( Prefix .. "_chat_badword", function( _, _, args ) for i = 1, #args do filter[ #filter + 1 ] = { Type = "Bad", Data = args[ i ] } end end )
concommand.Add( Prefix .. "_chat_solofilterword", function( _, _, args ) filter[ #filter + 1 ] = { Type = "SoloFilter", Data = { args[ 1 ], args[ 2 ] } } end )
concommand.Add( Prefix .. "_chat_filterword", function( _, _, args ) filter[ #filter + 1 ] = { Type = "Filter", Data = { args[ 1 ], args[ 2 ] } } end )

-- Makes the variable accessible by the includer
return Var
