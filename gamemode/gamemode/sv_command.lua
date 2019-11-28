-- Chat Filter
local CancelWords = {} -- These words are completely cancelled
local CancelText = {} -- Anything containing this is completely cancelled
local FilterWords = {} -- The words here will be changed to what it says if it's a SINGLE word
local FilterText = {} -- This is globally filtered over everything

local Styles = Core.Config.Style
local Teams = Core.Config.Team
local DefaultWeapon = Core.Config.Player.DefaultWeapon

local Command = {}
Command.Limit = Core.Config.Var.GetFloat( "CommandLimit" )
Command.Func = {}
Command.Limiter = {}
Command.Pause = {}
Command.Restore = {}

local HelpData, HelpLength
local CommandMisc = Core.ContentText( "MiscCommandLimit" )

--[[
	Description: Replaces occurrences in the text by a pattern
--]]
local function ReplaceByPattern( s, pat, repl, n )
    pat = string.gsub( pat, "(%a)", function( v ) return "[" .. string.upper( v ) .. string.lower( v ) .. "]" end )
    if n then return string.gsub( s, pat, repl, n ) else return string.gsub( s, pat, repl ) end
end

--[[
	Description: Executes multiple chat filters
--]]
local function FilterAnyText( ply, text )
	if Command.Silenced then
		if Core.GetAdminAccess( ply ) == 0 then
			return ""
		end
	elseif string.Trim( text ) == "" then
		return ""
	end

	if not Core.Config.Var.GetBool( "ChatFilter" ) then
		return text
	elseif not Command.FilterLoaded then
		local data = Core.Config.Var.GetChatFilter()
		for i = 1, #data do
			local item = data[ i ]
			if item.Type == "SoloBad" then
				CancelWords[ item.Data ] = true
			elseif item.Type == "Bad" then
				CancelText[ item.Data ] = true
			elseif item.Type == "SoloFilter" then
				FilterWords[ item.Data[ 1 ] ] = item.Data[ 2 ]
			elseif item.Type == "Filter" then
				FilterText[ item.Data[ 1 ] ] = item.Data[ 2 ]
			end
		end

		Command.FilterLoaded = true
	end

	local low = string.lower( text )
	if CancelWords[ low ] then
		Core.Print( ply, "General", Core.Text( "MiscIllegalChat", low ) )

		return ""
	elseif FilterWords[ low ] then
		return FilterWords[ low ]
	else
		local clean = string.gsub( low, " ", "" )
		for input,_ in pairs( CancelText ) do
			if string.find( low, input, 1, true ) then
				Core.Print( ply, "General", Core.Text( "MiscIllegalChat", input ) )

				return ""
			elseif string.find( clean, input, 1, true ) then
				Core.Print( ply, "General", Core.Text( "MiscIllegalChat", input ) )

				return ""
			end
		end

		for input,output in pairs( FilterText ) do
			text = ReplaceByPattern( text, input, output )
		end

		return text
	end
end

--[[
	Description: Resets the command timer
--]]
local function RemoveLimit( ply )
	Command.Limiter[ ply ] = nil
end
Core.RemoveCommandLimit = RemoveLimit

--[[
	Description: Checks if the command is possible
	Notes: This is also called for console commands, which are far more spammable than chat commands (hence the negative time checking)
--]]
local function CommandPossible( ply )
	if not Command.Limiter[ ply ] then
		Command.Limiter[ ply ] = SysTime()
	else
		local dt = SysTime() - Command.Limiter[ ply ]
		if dt < -10 then
			return false
		elseif dt < -5 then
			Core.Print( ply, "General", Core.Text( "CommandBan" ) )
			Command.Limiter[ ply ] = Command.Limiter[ ply ] + 30
			return false
		end

		if dt < Command.Limit then
			Core.Print( ply, "General", Core.Text( "CommandLimiter", CommandMisc[ math.random( 1, #CommandMisc ) ], math.ceil( Command.Limit - (SysTime() - Command.Limiter[ ply ]) ) ) )
			Command.Limiter[ ply ] = Command.Limiter[ ply ] + 0.5
			return false
		end

		Command.Limiter[ ply ] = SysTime()
	end

	return true
end
Core.CanExecuteCommand = CommandPossible

--[[
	Description: Quick function for adding a command (optionally with aliases)
--]]
local function AddCmd( varCommand, varFunc )
	local MainCommand, CommandList = "undefined", { "undefined" }
	if type( varCommand ) == "table" then
		MainCommand = varCommand[ 1 ]
		CommandList = varCommand
	elseif type( varCommand ) == "string" then
		MainCommand = varCommand
		CommandList = { varCommand }
	end

	Command.Func[ MainCommand ] = { CommandList, varFunc }
end
Core.AddCmd = AddCmd

--[[
	Description: Gets a function method by passing the main command name
--]]
local function GetCmd( szMain )
	if Command.Func[ szMain ] then
		return Command.Func[ szMain ][ 2 ]
	else
		return function() end
	end
end
Core.GetCmd = GetCmd

--[[
	Description: Quick function for adding an alias to an existing command
--]]
local function AddAlias( szMain, szAlias )
	if Command.Func[ szMain ] then
		if not table.HasValue( Command.Func[ szMain ][ 1 ], szAlias ) then
			Command.Func[ szMain ][ 1 ][ #Command.Func[ szMain ][ 1 ] + 1 ] = szAlias
			return true
		end
	end
end
Core.AddAlias = AddAlias

--[[
	Description: Counts all active commands and the assigned aliases
--]]
local function CountCommands()
	-- Loop over the command table
	local total, alias = 0, 0
	for cmd,data in pairs( Command.Func ) do
		total = total + 1
		alias = alias + #data[ 1 ] - 1
	end

	-- Return both the values
	return total, alias
end
Core.CountCommands = CountCommands

--[[
	Description: Triggers the callback bundled to a chat command providing the arguments passed
--]]
local function TriggerCmd( ply, szCommand, szText )
	if not CommandPossible( ply ) then return nil end

	local szFunc = nil
	local mainCommand, commandArgs, upperArgs = szCommand, {}, {}

	if string.find( szCommand, " ", 1, true ) then
		local splitData = string.Explode( " ", szCommand )
		local splitDataUpper = string.Explode( " ", szText )
		mainCommand = splitData[ 1 ]

		for i = 2, #splitData do
			commandArgs[ #commandArgs + 1 ] = splitData[ i ]
			upperArgs[ #upperArgs + 1 ] = splitDataUpper[ i ]
		end
	end

	if Command.Func[ mainCommand ] then
		szFunc = mainCommand
	else
		for _,data in pairs( Command.Func ) do
			for __,alias in pairs( data[ 1 ] ) do
				if mainCommand == alias then
					szFunc = data[ 1 ][ 1 ]
					break
				end
			end
		end
	end

	if not szFunc then szFunc = "invalid" end
	commandArgs.Key = mainCommand
	commandArgs.Upper = upperArgs
	commandArgs.FullText = szText
	commandArgs.Params = string.sub( commandArgs.FullText, 3 + string.len( commandArgs.Key ) )

	local varFunc = Command.Func[ szFunc ]
	if varFunc then
		varFunc = varFunc[ 2 ]
		return varFunc( ply, commandArgs )
	end
end


--[[
	Description: Resets the player if they're not spectating
--]]
local function Restart( ply, _, varArgs )
	if varArgs and varArgs != "bypass" then
		if not CommandPossible( ply ) then return end
	end

	if ply.Practice and (not varArgs or varArgs != "bypass") then
		Core.Print( ply, "Timer", Core.Text( "StylePracticeEnabled" ) )
	end

	-- All we have to check is if they're spectating or not
	if ply:Team() != Teams.Spectator then
		if ply.TAS and ply.TAS.IsPaused( ply ) then
			return Core.Print( ply, "Timer", Core.Text( "TASCommandResetPause" ) )
		end

		ply:ResetSpawnPosition()

		local tt = ply.TryTrack
		if tt then
			tt.Amount = tt.Amount - 1

			if tt.Type == "count" then
				Core.Print( ply, "General", Core.Text( "CommandTriesLeft", tt.Amount, tt.Amount == 1 and "try" or "tries" ) )

				if tt.Amount == 0 then
					ply.TryTrack = nil
					Core.Print( ply, "General", Core.Text( "CommandTriesStopped" ) )
				end
			elseif tt.Type == "kick" then
				if tt.Amount <= 0 then
					ply:Kick( "You exceeded the amount of tries!" )
				elseif tt.Amount == 1 then
					Core.Print( ply, "General", Core.Text( "CommandTriesLeft", tt.Amount, "try" ) )
				end
			end
		end
	else
		Core.Print( ply, "Timer", Core.Text( "SpectateRestart" ) )
	end
end
concommand.Add( "reset", Restart )

--[[
	Description: Changes the style
--]]
local function SetStyle( ply, _, varArgs )
	-- When we have a normal table (call from SetStyle function and concommand style)
	if varArgs and type( varArgs ) != "string" then
		if not CommandPossible( ply ) then return end

	-- Forced concommand.Run call
	elseif type( varArgs ) == "string" then
		varArgs = { tonumber( varArgs ) }
	end

	-- Check if they put a valid style that's not already set
	local val = tonumber( varArgs[ 1 ] )
	if not val or (val < Styles.Normal and not Core.Config.Modes[ val ]) or val > Core.Config.MaxStyle then return end

	-- Parse the provided ID
	local nStyle = tonumber( varArgs[ 1 ] ) or Styles.Normal

	-- If we're in a race, de-queue them
	if ply.Race and not ply.Race.Prestyle then
		ply.Race:Abandon( ply )
	end

	-- If we're rocking TAS, make sure they don't do cheeky stuff
	if ply.TAS then
		if nStyle == Core.Config.PracticeStyle then
			return Core.Print( ply, "Timer", Core.Text( "TASChangeStylePractice" ) )
		end

		if not ply:InSpawn() then
			return Core.Print( ply, "Timer", Core.Text( "TASChangeStyleSpawn" ) )
		else
			ply.TAS.ResetTimer( ply, true )
		end
	end

	-- Check the practice style
	if nStyle == Core.Config.PracticeStyle then
		ply.TimerNormal = nil
		ply.TimerBonus = nil
		ply:Spectator( "PlayerRestart" )

		local ar = Core.Prepare( "Timer/Start" )
		ar:UInt( 0, 2 )
		ar:Send( ply )
	end

	-- Finally load in their data for the style
	ply:LoadStyle( nStyle )
end
concommand.Add( "style", SetStyle )

--[[
	Description: Spectate console command
	Notes: Takes arguments to spectate by ID (for the scoreboard)
--]]
local function DoSpectate( ply, _, varArgs )
	if varArgs and varArgs != "bypass" then
		if not CommandPossible( ply ) then return end
	end

	if ply.Spectating and varArgs and type( varArgs ) == "table" and varArgs[ 1 ] then
		return ply:Spectator( "NewById", { varArgs[ 1 ], true, varArgs[ 2 ] } )
	elseif ply.Spectating then
		local target = ply:GetObserverTarget()
		ply:SetTeam( Teams.Players )
		ply:KillSilent()
		ply:Spawn()
		ply:ResetTimer()
		ply.Spectating = false
		ply:VarNet( "Set", "Spectating", false, true )

		-- Change sync state
		Core.Ext( "SMgr", "ToggleSyncState" )( ply, nil, true )

		-- Clear their list
		Core.Send( ply, "Spectate/Clear" )

		-- Clear out sync
		local ar = Core.Prepare( "Timer/SetSync" )
		ar:String( "" )
		ar:Bit( false )
		ar:Send( ply )

		ply:Spectator( "End", { target } )
	else
		-- Check if they're in TAS mode
		if ply.TAS then
			return Core.Print( ply, "Timer", Core.Text( "TASChangeSpectateExit" ) )
		end

		-- Set a published variable
		ply:VarNet( "Set", "Spectating", true, true )
		Core.Send( ply, "Spectate/Clear", true )

		-- Kill them and stop the timer
		ply.Spectating = true
		ply:KillSilent()
		ply:StopAnyTimer()

		-- Set the player to be spectator
		GAMEMODE:PlayerSpawnAsSpectator( ply )
		ply:SetTeam( TEAM_SPECTATOR )

		-- If we're in a race, de-queue them
		if ply.Race then
			ply.Race:Abandon( ply )
		end

		-- Also enable key tracker if they have it enabled
		if ply.ShowKeys then
			Core.EnableKeyTrack()
		end

		if varArgs and type( varArgs ) == "table" and varArgs[ 1 ] then
			return ply:Spectator( "NewById", { varArgs[ 1 ], nil, varArgs[ 2 ] } )
		end

		ply:Spectator( "New" )
	end
end
concommand.Add( "spectate", DoSpectate )

--[[
	Description: Nominates a map IF everything is valid and okay
--]]
local function Nominate( ply, _, varArgs )
	if not CommandPossible( ply ) then return end
	if not varArgs[ 1 ] then return end
	if varArgs[ 1 ] == "none" or varArgs[ 1 ] == "blank" or varArgs[ 1 ] == "wipe" then return ply:RTV( "Denominate" ) end
	if varArgs[ 1 ] == game.GetMap() then return Core.Print( ply, "Notification", Core.Text( "NominateOnMap" ) ) end
	if not Core.MapCheck( varArgs[ 1 ] ) then return Core.Print( ply, "Notification", Core.Text( "MapInavailable", varArgs[ 1 ] ) ) end
	if not Core.MapCheck( varArgs[ 1 ], true ) then return Core.Print( ply, "Notification", Core.Text( "MapMissing" ) ) end

	ply:RTV( "Nominate", varArgs[ 1 ] )
end
concommand.Add( "nominate", Nominate )

--[[
	Description: Noclip by command
	Notes: Strips weapons so people are less likely to start shooting
--]]
local function DoNoclip( ply, _, varArgs )
	if not CommandPossible( ply ) then return end
	if ply.Practice then
		if ply:GetMoveType() != MOVETYPE_NOCLIP then
			ply:SetMoveType( MOVETYPE_NOCLIP )
			ply:StripWeapons()
		else
			ply:SetMoveType( MOVETYPE_WALK )
		end
	else
		Core.Print( ply, "General", Core.Text( "StyleNoclip" ) )
	end
end
concommand.Add( "pnoclip", DoNoclip )

--[[
	Description: An alias/bindable console command for the checkpoint commands
--]]
local function Checkpoint( ply, szCmd, varArgs )
	if not CommandPossible( ply ) then return end
	if ply.Practice then
		local func = GetCmd( "cp" )
		func( ply, { Key = szCmd } )
	else
		Core.Print( ply, "General", Core.Text( "StyleTeleport" ) )
	end
end
concommand.Add( "cpload", Checkpoint )
concommand.Add( "cpsave", Checkpoint )

-- Table containing server commands and their functionality
local ServerCommands = {
	["gg"] = function( args )
		local map = #args > 0 and args[ 1 ] or game.GetMap()
		local change = map == game.GetMap()
		Core.Print( nil, "General", "Console forced a map " .. (change and "reload" or "change to '" .. map .. "'") )
		GAMEMODE:UnloadGamemode( "Command " .. (change and "Reload" or "Change"), function()
			RunConsoleCommand( "changelevel", map )
		end )
	end,
	["savebot"] = function()
		GAMEMODE:UnloadGamemode( "Bot Save" )
	end,
	["control"] = function( args )
		if #args > 0 then
			if string.find( string.Implode( "", args ), ":", 1, true ) then
				local szJoined = string.Implode( " :", args )
				szJoined = string.gsub( szJoined, " :: ", "" )
				szJoined = string.gsub( szJoined, " :", " " )
				args = string.Explode( " ", szJoined )
			end

			local szCmd = args[ 1 ]
			if szCmd == "mem" then
				Core.PrintC( "[Control] Used memory: " .. collectgarbage( "count" ) )
			elseif szCmd == "admin" then
				if #args != 3 then return print( "Invalid parameters supplied!" ) end
				Core.Trigger( "Global/Admin", { -1, 7, args[ 3 ] }, { ConsoleOperator = true, AdminTarget = args[ 2 ], SteamID = function() return "CONSOLE" end, Name = function() return "CONSOLE" end } )
				Core.PrintC( "[Control] Admin authority change submitted" )
			elseif szCmd == "lockdown" then
				if Core.Lockdown then
					Core.Lockdown = nil
					file.Delete( "lockdown.txt" )
					return print( "Lockdown has been ended" )
				end

				local szName, plyNoKick = "Operator"
				if #args >= 2 then
					table.remove( args, 1 )

					local szName = string.Implode( " ", args )

					for _,p in pairs( player.GetHumans() ) do
						if string.find( p:Name(), szName, 1, true ) then
							szName = p:Name()
							plyNoKick = p

							break
						end
					end
				end

				Core.Lockdown = "A lockdown has been issued by " .. szName .. ", you can rejoin later"
				Core.LockExclude = plyNoKick and plyNoKick.UID or ""

				file.Write( "lockdown.txt", Core.Lockdown .. ";" .. Core.LockExclude )

				for _,p in pairs( player.GetHumans() ) do
					if p != plyNoKick then
						p:Kick( Core.Lockdown )
					end
				end

				Core.PrintC( "[Control] Lockdown is now active!" )
			elseif szCmd == "rtv" then
				Core.ClearWaitPeriod()
				Core.PrintC( "[Control] RTV wait period has been cleared!" )
			elseif szCmd == "openrtv" then
				Core.ForceStartRTV()
				Core.PrintC( "[Control] RTV has been forced!" )
			elseif szCmd == "mbot" then
				Core.Ext( "Bot", "SetFrame" )( nil, -1, "Multi" )
			elseif szCmd == "dumpcmds" then
				local missing = {}
				local commands = Core.ContentText( "Commands" )

				for _,set in pairs( Command.Func ) do
					if not commands[ set[ 1 ][ 1 ] ] then
						missing[ #missing + 1 ] = set[ 1 ][ 1 ]
					end

					print( unpack( set[ 1 ] ) )
				end

				Core.PrintC( "[Control] Commands that do not have documentation:" )

				for _,cmd in pairs( missing ) do
					print( "- " .. cmd )
				end
			elseif szCmd == "pos" then
				local szPath = Core.Config.BaseType .. "/gamepostransfer.txt"

				if args[ 2 ] == "save" then
					local data = {}
					for _,p in pairs( player.GetHumans() ) do
						if p:InSpawn() or p.Practice or p.TAS or not p.TimerNormal or p.TimerNormalFinish then continue end

						data[ p:SteamID() ] = { p.Style, p:GetPos(), SysTime() - p.TimerNormal, p:GetJumps(), Core.Ext( "SMgr", "GetStrafes" )( p ), { Core.Ext( "SMgr", "GetPlayerSync" )( p, true ) }, p:EyeAngles() }
					end

					file.Write( szPath, util.TableToJSON( { game.GetMap(), data } ) )
					Core.PrintC( "[Control] Progress has been saved" )
				elseif args[ 2 ] == "load" or args[ 2 ] == "dump" then
					if not file.Exists( szPath, "DATA" ) then
						return Core.PrintC( "[Control] No progress to restore" )
					end

					local content = file.Read( szPath, "DATA" )
					if not content or content == "" then return end

					local json = util.JSONToTable( content )
					if not json or #json != 2 or json[ 1 ] != game.GetMap() then
						return Core.PrintC( "[Control] Invalid progress file" )
					end

					if args[ 2 ] == "dump" then
						return print( "Position file for map: " .. json[ 1 ] .. "\nAmount of players saved: " .. table.Count( json[ 2 ] ) .. "\nRaw data:\n\n" .. content )
					end

					json.Count = 0

					local data = json[ 2 ]
					for _,p in pairs( player.GetHumans() ) do
						if p.TAS then continue end

						local tab = data[ p:SteamID() ]
						if tab then
							if p.Practice then
								RemoveLimit( p )
								SetStyle( p, nil, { Core.Config.PracticeStyle } )
							end

							RemoveLimit( p )
							SetStyle( p, nil, { tab[ 1 ] } )

							RemoveLimit( p )
							Restart( p )

							Core.Ext( "Bot", "CleanPlayer" )( p )
							Core.Ext( "Bot", "SetPlayerActive" )( p )

							p.SkipValidation = true
							p:SetJumps( tab[ 4 ] )

							Core.Ext( "SMgr", "SetStrafes" )( p, tab[ 5 ] )
							Core.Ext( "SMgr", "SetPlayerSync" )( p, tab[ 6 ][ 1 ] or 0, tab[ 6 ][ 2 ] or 0, tab[ 6 ][ 3 ] or 0 )

							p:SetPos( tab[ 2 ] )
							p:SetEyeAngles( tab[ 7 ] )
							p:SetLocalVelocity( Vector( 0, 0, 0 ) )

							p.TimerNormal = SysTime() - tab[ 3 ]
							p.TimerNormalFinish = nil

							local ar = Core.Prepare( "Timer/Start" )
							ar:UInt( 2, 2 )
							ar:Double( tab[ 3 ] or 0 )
							ar:Send( p )

							Core.Print( p, "Timer", Core.Text( "TimerRestoreServer" ) )

							json.Count = json.Count + 1
						end
					end

					file.Delete( szPath )
					Core.PrintC( "[Control] Restored locations of " .. json.Count .. " players" )
				else
					Core.PrintC( "[Control] Available sub-commands of 'pos': save/load/dump\nStorage point: ", szPath )
				end
			elseif szCmd == "collision" then
				for _,p in pairs( player.GetHumans() ) do
					if string.find( string.lower( p:Name() ), string.lower( args[ 2 ] or "" ), 1, true ) then
						if p:GetCollisionGroup() == COLLISION_GROUP_PLAYER then
							p:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
							Core.PrintC( "[Control] Collision disabled on", p:Name() )
						else
							p:SetCollisionGroup( COLLISION_GROUP_PLAYER )
							Core.PrintC( "[Control] Collision re-enabled on", p:Name() )
						end
					end
				end
			elseif szCmd == "resync" then
				Core.LoadRecords()
				Core.AddMaplistVersion()
				Core.PrintC( "[Control] Map version incrmeented!" )
			elseif szCmd == "socket" then
				local pin, pout, pkey = Core.GetPacketsReceived()
				Core.PrintC( "[Control] Socket usage", "Requests: " .. pin, "Total out: " .. math.Round( pout / 1024, 2 ) .. " kB" )
				Core.PrintC( "[Control] Socket secret key: " .. pkey )
			elseif szCmd == "silence" then
				Command.Silenced = not Command.Silenced
				Core.ChatSilence = Command.Silenced

				Core.PrintC( "[Control] Chat silencing", Command.Silenced )
			elseif szCmd == "sqltables" then
				Core.CreateSQLTables()
				Core.PrintC( "[Control] Attempted to create all SQL tables!" )
			else
				Core.PrintC( "[Control] Unknown command! Type control to see a list of all subcommands" )
			end
		else
			Core.PrintC( "[Control] Valid control functions: mem, admin [steam] [level], lockdown, rtv, openrtv, mbot, dumpcmds, pos [save/load/dump], collision [player], resync, socket, silence, sqltables" )
		end
	end
}

--[[
	Description: The console command for
	Notes: Kind of a hacky method of finding a console player
--]]
local function ServerCommand( ply, szCmd, varArgs )
	if not ply or ply:IsValid() or ply:IsPlayer() or ply.Name or ply.Team then return end

	local fExec = ServerCommands[ string.lower( szCmd ) ]
	if fExec then
		fExec( varArgs )
	else
		print( "Server command", "Invalid command entered:", szCmd )
	end
end

-- Add all server commands
for command,_ in pairs( ServerCommands ) do
	concommand.Add( command, ServerCommand )
end


-- Command helpers

--[[
	Description: Loads all commands into a table together with their description
	Notes: Compressed since it's only sent once and quite large
--]]
local function LoadHelp( bForce )
	if not HelpData or not HelpLength or bForce then
		local tab = { HelpText = Core.ContentText( "HelpText" ) }
		local commands = Core.ContentText( "Commands" )
		local content = Core.ContentText( "StyleLookup" )

		for command,data in pairs( Command.Func ) do
			if not commands[ command ] then continue end
			tab[ #tab + 1 ] = { commands[ command ], data[ 1 ] }
		end

		HelpData = util.Compress( util.TableToJSON( tab ) )
		HelpLength = #HelpData
	end
end

--[[
	Description: Loads all bonus related data and enables the commands for it
--]]
local function LoadBonusAdditions()
	-- Also add commands for bonus
	for _,id in pairs( Core.GetBonusIDs() ) do
		local real = id + 1
		AddAlias( "b", "b" .. real )

		local cmds = Core.ContentText( "Commands" )
		cmds[ "wrb" .. real ] = "Open Bonus " .. real .. " record list"

		AddCmd( { "wrb" .. real, "wrbonus" .. real, "b" .. real .. "wr", "bwr" .. real }, function( ply, args )
			local nStyle = (tonumber( string.match( args.Key, "%d+" ) ) or 0) + Core.Config.Style.Bonus - 1
			if #args > 0 then
				Core.DoRemoteWR( ply, args[ 1 ], nStyle )
			else
				GAMEMODE:ShowSpare2( ply, { Core.GetRecordList( nStyle, 1, Core.Config.PageSize ), Core.GetRecordCount( nStyle ), nStyle } )
			end
		end )

		for _,nStyle in pairs( Core.Config.Style ) do
			Core.EnsureStyleRecords( Core.MakeBonusStyle( nStyle, id ) )
		end
	end

	-- Update command count
	Core.UpdateCommandCount()

	-- Load the help properly now
	if not Command.Helped then
		LoadHelp( true )
		Command.Helped = true
	end
end
Core.BonusEntitySetup = LoadBonusAdditions


-- Start of multi-usage commands

--[[
	Description: Sets the style so that it always works (no command limit check)
--]]
local function CommandStyleSet( ply, style )
	RemoveLimit( ply )
	SetStyle( ply, nil, { style } )
end

--[[
	Description: Changes the style of the user to bonus X depending on the entered command
--]]
local function CommandStyleBonus( ply, args )
	local IsHigher = tonumber( string.sub( args.Key, 2, 2 ) )
	if #args > 0 or IsHigher then
		local id = IsHigher or tonumber( args[ 1 ] )
		local keys = {}

		for _,val in pairs( Core.GetBonusIDs() ) do
			keys[ val ] = true
		end

		if id and keys[ id - 1 ] then
			ply:LoadBonus( id - 1 )
		else
			Core.Print( ply, "Timer", Core.Text( "CommandBonusID" ) )
		end
	else
		ply:LoadBonus( 0 )
	end
end

--[[
	Description: Shows the WR window by the provided data
--]]
local function CommandShowWR( ply, args, style )
	if #args > 0 then
		Core.DoRemoteWR( ply, args[ 1 ], style )
	else
		GAMEMODE:ShowSpare2( ply, { Core.GetRecordList( style, 1, Core.Config.PageSize ), Core.GetRecordCount( style ), style } )
	end
end


--[[
	Description: Loads all base commands and sets the function for it
--]]
function Core.LoadCommands()
	-- General timer commands
	AddCmd( { "r", "restart", "respawn", "kill" }, function( ply )
		RemoveLimit( ply )
		Restart( ply )
	end )

	AddCmd( { "spec", "spectate", "watch", "view" }, function( ply, args )
		RemoveLimit( ply )
		if #args > 0 then
			if type( args[ 1 ] ) == "string" then
				local ar, target, tname = ply:Spectator( "GetAlive" ), nil, nil
				for id,p in pairs( ar ) do
					if string.find( string.lower( p:Name() ), string.lower( args[ 1 ] ), 1, true ) then
						target = p.UID
						tname = p:Name()
						break
					end
				end
				if target then
					if ply.Spectating then
						return ply:Spectator( "NewById", { target, true, tname } )
					else
						args[ 1 ] = target
					end
				end
			end

			DoSpectate( ply, nil, args )
		else
			DoSpectate( ply )
		end
	end )

	AddCmd( { "noclip", "freeroam", "clip", "wallhack" }, function( ply )
		RemoveLimit( ply )
		DoNoclip( ply )
	end )

	AddCmd( { "stats", "rts", "realtime", "realtimestats", "js", "jumpstats" }, function( ply, args )
		Core.Send( ply, "GUI/Create", { ID = "Realtime", Dimension = { x = 200, y = 170, px = 20 }, Args = { Title = "Real-Time Stats", Custom = string.sub( args.Key, 1, 1 ) == "j" } } )
	end )

	AddCmd( { "tp", "tpto", "goto", "teleport", "tele" }, function( ply, args )
		if not ply.Practice then
			return Core.Print( ply, "General", Core.Text( "CommandPractice" ) )
		end

		if #args > 0 then
			local target
			for _,p in pairs( player.GetAll() ) do
				if string.find( string.lower( p:Name() ), string.lower( args[ 1 ] ), 1, true ) then
					target = p
					break
				end
			end
			if IsValid( target ) then
				if target.Spectating then
					return Core.Print( ply, "General", Core.Text( "CommandTeleportInvalid" ) )
				end

				ply:SetPos( target:GetPos() )
				ply:SetEyeAngles( target:EyeAngles() )
				ply:SetLocalVelocity( Vector( 0, 0, 0 ) )
				Core.Print( ply, "General", Core.Text( "CommandTeleportGo", target:Name() ) )
			else
				return Core.Print( ply, "General", Core.Text( "CommandTeleportNoTarget", args[ 1 ] ) )
			end
		else
			Core.Print( ply, "General", Core.Text( "CommandTeleportBlank" ) )
		end
	end )

	AddCmd( { "timescale", "ts", "slowmotion", "slowmo", "slomo" }, function( ply, args )
		if not ply.Practice then
			return Core.Print( ply, "General", Core.Text( "CommandPractice" ) )
		end

		local num = tonumber( args[ 1 ] )
		if #args == 0 or not num or num < 0.2 or num > 1.0 then
			return Core.Print( ply, "General", Core.Text( "CommandArgumentNum", args.Key, "Number 0.2 - 1.0" ) )
		end

		if ply:GetLaggedMovementValue() != num then
			ply:SetLaggedMovementValue( num )

			Core.Print( ply, "General", Core.Text( "CommandArgumentChange", "timescale", num ) )
		end
	end )

	AddCmd( { "gravity", "setgravity" }, function( ply, args )
		if not ply.Practice then
			return Core.Print( ply, "General", Core.Text( "CommandPractice" ) )
		end

		local num = tonumber( args[ 1 ] )
		if #args == 0 or not num or num < 0.1 or num > 5.0 then
			return Core.Print( ply, "General", Core.Text( "CommandArgumentNum", args.Key, "Number 0.1 - 5.0" ) )
		end

		Core.Print( ply, "General", Core.Text( "CommandArgumentChange", "gravity", num ) )

		ply:SetGravity( num )
	end )

	AddCmd( { "kz", "friction", "highfriction" }, function( ply )
		if not ToggleStamina then
			return Core.Print( ply, "General", Core.Text( "CommandFrictionNotAvailable" ) )
		end

		Core.Print( ply, "General", Core.Text( ToggleStamina( ply ) ) )
	end )

	AddCmd( { "auto", "autohop", "toggleauto", "toggleautohop", "noauto", "disableauto", "enableauto" }, function( ply, args )
		local to
		if args.Key == "noauto" or args.Key == "disableauto" then
			to = false
		elseif args.Key == "enableauto" then
			to = true
		end

		local change = ply:EnableAutoHop( to, true )
		if change == nil then
			Core.Print( ply, "General", Core.Text( "CommandAutoScroll" ) )
		else
			ply.LastAutoChange = change
			Core.Print( ply, "General", Core.Text( "CommandAutoToggle", change and "enabled" or "disabled" ) )
		end
	end )

	AddCmd( { "listspecs", "listspec", "listspectators", "speclist", "specs", "myspec", "amifamous" }, function( ply )
		local w = {}
		for _,p in pairs( player.GetHumans() ) do
			if p:GetObserverTarget() == ply and not p.Incognito then
				w[ #w + 1 ] = p:Name()
			end
		end

		if #w > 0 then
			Core.Print( ply, "General", Core.Text( "CommandSpectatorList", #w, string.Implode( ", ", w ) ) )
		else
			Core.Print( ply, "General", Core.Text( "CommandSpectatorNone" ) )
		end
	end )

	AddCmd( { "end", "goend", "gotoend", "tpend" }, function( ply )
		if ply.Practice then
			local vPoint = Core.GetZoneCenter()
			if vPoint then
				ply:SetPos( vPoint )
				Core.Print( ply, "Timer", Core.Text( "PlayerTeleport", "the normal end zone!" ) )
			else
				Core.Print( ply, "Timer", Core.Text( "MiscZoneNotFound", "normal end" ) )
			end
		else
			Core.Print( ply, "Timer", Core.Text( "StyleTeleport" ) )
		end
	end )

	AddCmd( { "endbonus", "endb", "bend", "gotobonus", "tpbonus" }, function( ply, args )
		if ply.Practice then
			local vPoint = Core.GetZoneCenter( true, nil, #args > 0 and tonumber( args[ 1 ] ) )
			if vPoint then
				ply:SetPos( vPoint )
				Core.Print( ply, "Timer", Core.Text( "PlayerTeleport", "the bonus end zone!" ) )
			else
				Core.Print( ply, "Timer", Core.Text( "MiscZoneNotFound", "bonus end" ) )
			end
		else
			Core.Print( ply, "Timer", Core.Text( "StyleTeleport" ) )
		end
	end )

	AddCmd( { "pause", "break", "pausetimer", "save", "savetimer" }, function( ply )
		if not ply.IsPauseWarned then
			ply.IsPauseWarned = true

			Core.Print( ply, "Timer", Core.Text( "TimerPauseHelp" ) )
		else
			if not ply.TimerNormal or ply.TimerNormalFinish or ply.Practice or ply.TAS or ply:InSpawn() then
				return Core.Print( ply, "Timer", Core.Text( "TimerInvalidPause" ) )
			end

			local tn = SysTime() - ply.TimerNormal
			if not Command.Pause[ ply.UID ] then
				Core.Print( ply, "Timer", Core.Text( "TimerPause", Core.ConvertTime( tn ) ) )
			else
				Core.Print( ply, "Timer", Core.Text( "TimerPauseOverwrite", Core.ConvertTime( tn ) ) )
			end

			Command.Pause[ ply.UID ] = { ply.Style, ply:GetPos(), tn, ply:GetJumps(), Core.Ext( "SMgr", "GetStrafes" )( ply ), { Core.Ext( "SMgr", "GetPlayerSync" )( ply, true ) }, ply:EyeAngles(), { ply:SpeedValues() } }
		end
	end )

	AddCmd( { "restore", "continue", "lunchtimeisover", "unpause", "resume" }, function( ply )
		if not Command.Pause[ ply.UID ] then
			Core.Print( ply, "Timer", Core.Text( "TimerRestoreNone" ) )
		else
			local data = Command.Pause[ ply.UID ]
			if not ply.TimerNormal or ply.Practice or ply.Style != data[ 1 ] or ply:InSpawn() or ply.TAS then
				return Core.Print( ply, "Timer", Core.Text( "TimerInvalidRestore", Core.StyleName( data[ 1 ] ) ) )
			end

			if not Command.Restore[ ply.UID ] then
				Command.Restore[ ply.UID ] = 1
			else
				Command.Restore[ ply.UID ] = Command.Restore[ ply.UID ]

				if Command.Restore[ ply.UID ] > 3 then
					return Core.Print( ply, "Timer", Core.Text( "TimerRestoreLimit" ) )
				end
			end

			Core.Ext( "Bot", "CleanPlayer" )( ply )
			Core.Ext( "Bot", "SetPlayerActive" )( ply )

			ply:SetJumps( data[ 4 ] )
			ply:SpeedValues( false, data[ 8 ][ 1 ], data[ 8 ][ 3 ], data[ 8 ][ 4 ] )

			Core.Ext( "SMgr", "SetStrafes" )( ply, data[ 5 ] )
			Core.Ext( "SMgr", "SetPlayerSync" )( ply, data[ 6 ][ 1 ] or 0, data[ 6 ][ 2 ] or 0, data[ 6 ][ 3 ] or 0 )

			ply:SetPos( data[ 2 ] )
			ply:SetEyeAngles( data[ 7 ] )
			ply:SetLocalVelocity( Vector( 0, 0, 0 ) )

			ply.TimerNormal = SysTime() - data[ 3 ] - 5 * 60
			ply.TimerNormalFinish = nil

			local ar = Core.Prepare( "Timer/Start" )
			ar:UInt( 2, 2 )
			ar:Double( data[ 3 ] + 5 * 60 )
			ar:Send( ply )

			Core.Print( ply, "Timer", Core.Text( "TimerRestore" ) )

			Command.Pause[ ply.UID ] = nil
		end
	end )

	AddCmd( { "undo", "undor", "ru", "restartundo", "undorestart", "ifuckedup" }, function( ply )
		local data = ply.LastResetData
		if data then
			if SysTime() - data[ 1 ] > 60 then
				return Core.Print( ply, "Timer", Core.Text( "CommandUndoTime" ) )
			elseif ply.Practice or ply.TAS or ply.Style != data[ 2 ] or data[ 3 ] or not data[ 4 ] then
				return Core.Print( ply, "Timer", Core.Text( "CommandUndoFail" ) )
			elseif ply:InSpawn() then
				return Core.Print( ply, "Timer", Core.Text( "CommandUndoSpawn" ) )
			end

			Core.Ext( "Bot", "CleanPlayer" )( ply )
			Core.Ext( "Bot", "SetPlayerActive" )( ply )

			ply:SetJumps( data[ 7 ] or 0 )
			ply:SpeedValues( false, data[ 10 ][ 1 ], data[ 10 ][ 3 ], data[ 10 ][ 4 ] )

			Core.Ext( "SMgr", "SetStrafes" )( ply, data[ 8 ] )
			Core.Ext( "SMgr", "SetPlayerSync" )( ply, data[ 9 ][ 1 ] or 0, data[ 9 ][ 2 ] or 0, data[ 9 ][ 3 ] or 0 )

			ply:SetPos( data[ 5 ] )
			ply:SetEyeAngles( data[ 6 ] )
			ply:SetLocalVelocity( Vector( 0, 0, 0 ) )

			ply.TimerNormal = data[ 4 ]
			ply.TimerNormalFinish = nil
			ply.LastResetData = nil

			local ar = Core.Prepare( "Timer/Start" )
			ar:UInt( 2, 2 )
			ar:Double( SysTime() - data[ 4 ] )
			ar:Send( ply )

			Core.Print( ply, "Timer", Core.Text( "CommandUndoSucceed" ) )
		else
			Core.Print( ply, "Timer", Core.Text( "CommandUndoEmpty" ) )
		end
	end )

	-- RTV commands
	AddCmd( { "rtv", "vote", "votemap", "revote" }, function( ply, args )
		if #args > 0 then
			if args[ 1 ] == "revoke" then
				ply:RTV( "Revoke" )
			elseif args[ 1 ] == "check" or args[ 1 ] == "left" then
				ply:RTV( "Check" )
			elseif args[ 1 ] == "who" or args[ 1 ] == "list" then
				ply:RTV( "Who" )
			elseif args[ 1 ] == "time" then
				ply:RTV( "Left" )
			elseif args[ 1 ] == "revote" or args[ 1 ] == "again" or args[ 1 ] == "vote" then
				ply:RTV( "Revote" )
			elseif args[ 1 ] == "which" then
				ply:RTV( "Which" )
			elseif args[ 1 ] == "nominations" then
				ply:RTV( "Nominations" )
			elseif args[ 1 ] == "unnominate" or args[ 1 ] == "denominate" then
				ply:RTV( "Denominate" )
			elseif args[ 1 ] == "extend" then
				ply:RTV( "Extend" )
			else
				Core.Print( ply, "General", Core.Text( "CommandSubList", args.Key, "revoke, check/left, who/list, time, revote/again/vote, which, nominations, unnominate/denominate, extend" ) )
			end
		else
			if ply:RTV( "Revote", true ) then
				ply:RTV( "Revote" )
			else
				ply:RTV( "Vote" )
			end
		end
	end )

	AddCmd( { "revoke", "retreat", "revokertv" }, function( ply )
		ply:RTV( "Revoke" )
	end )

	AddCmd( { "checkvotes", "votecount" }, function( ply )
		ply:RTV( "Check" )
	end )

	AddCmd( { "votelist", "listrtv" }, function( ply )
		ply:RTV( "Who" )
	end )

	AddCmd( { "timeleft", "time", "remaining", "tl" }, function( ply )
		ply:RTV( "Left" )
	end )

	AddCmd( { "extend", "autoextend", "voteextend" }, function( ply )
		ply:RTV( "Extend" )
	end )

	-- GUI Functionality
	AddCmd( { "showgui", "showhud", "hidegui", "hidehud", "togglegui", "togglehud", "hud", "hudhide", "hudshow", "gui", "guihide", "guishow" }, function( ply, args )
		local interchange = {
			["hud"] = "togglehud",
			["hudhide"] = "hidehud",
			["hudshow"] = "showhud",
			["gui"] = "togglegui",
			["guihide"] = "hidegui",
			["guishow"] = "showgui"
		}

		if interchange[ args.Key ] then
			args.Key = interchange[ args.Key ]
		end

		if string.sub( args.Key, 1, 4 ) == "show" or string.sub( args.Key, 1, 4 ) == "hide" then
			Core.Send( ply, "Client/GUIVisibility", string.sub( args.Key, 1, 4 ) == "hide" and 0 or 1 )
		else
			Core.Send( ply, "Client/GUIVisibility", -1 )
		end
	end )

	AddCmd( { "sync", "showsync", "sink", "strafe", "monitor" }, function( ply )
		Core.Ext( "SMgr", "ToggleSyncState" )( ply )
	end )

	-- Windows
	AddCmd( { "settings", "setting", "options", "config", "bhop", "surf", "menu", "mainmenu" }, function( ply )
		GAMEMODE:ShowHelp( ply )
	end )

	AddCmd( { "style", "mode", "styles", "modes" }, function( ply )
		RemoveLimit( ply )
		Core.Send( ply, "GUI/Create", { ID = "Style", Dimension = { x = 215, y = 360 }, Args = { Title = "Choose Style", Mouse = true, Blur = true, Custom = Core.GetStyleRecords( ply ) } } )
	end )

	AddCmd( { "nominate", "rtvmap", "playmap", "addmap", "maps" }, function( ply, args )
		if #args > 0 then
			if args[ 1 ] == "extend" then
				ply:RTV( "Extend" )
			else
				RemoveLimit( ply )
				Nominate( ply, nil, args )
			end
		else
			Core.Send( ply, "GUI/Create", { ID = "Nominate", Dimension = { x = 300, y = 400 }, Args = { Title = "Nominate a map", Mouse = true, Blur = true, Custom = Core.GetMaplistVersion(), Server = Core.GetMapVariable( "Plays" ), Previous = ply.NominatedMap } } )
		end
	end )

	AddCmd( { "wr", "wrlist", "records" }, function( ply, args )
		if #args > 0 then
			Core.DoRemoteWR( ply, args[ 1 ], ply.Style or Styles.Normal )
		else
			GAMEMODE:ShowSpare2( ply )
		end
	end )

	AddCmd( { "rank", "ranks", "ranklist" }, function( ply )
		Core.Send( ply, "GUI/Create", { ID = "Ranks", Dimension = { x = 195, y = 270 }, Args = { Title = "Rank List", Mouse = true, Blur = true, Custom = { ply.Rank or 1, ply.CurrentPointSum, ply.Style, ply.Bonus } } } )
	end )

	AddCmd( { "mapsbeat", "beatlist", "listbeat", "mapsdone", "mapscompleted", "beat", "done", "completed", "howgoodami" }, function( ply, args )
		Core.HandlePlayerMaps( "Beat", ply, args )
	end )

	AddCmd( { "mapsleft", "left", "leftlist", "listleft", "notbeat", "howbadami" }, function( ply, args )
		Core.HandlePlayerMaps( "Left", ply, args )
	end )

	AddCmd( { "mywr", "mywrs", "wr1", "wr#1", "wrcount", "wrcounter", "countwr", "wramount", "wrsby" }, function( ply, args )
		Core.HandlePlayerMaps( "Mine", ply, args )
	end )

	AddCmd( { "mapsnowr", "nowr", "nowrs", "mapswithoutwr", "withoutwr" }, function( ply, args )
		Core.HandlePlayerMaps( "NoWR", ply, args )
	end )

	AddCmd( { "allwrs", "stylewrs", "mapwrs" }, function( ply )
		local tab = Core.GetTopTimes()
		if table.Count( tab ) > 0 then
			local send = {}
			for style,data in pairs( tab ) do
				send[ #send + 1 ] = { szUID = data.szUID, szPrepend = "[" .. Core.StyleName( style ) .. "] ", nTime = data.nTime }
			end

			Core.Prepare( "GUI/Build", {
				ID = "Top",
				Title = "Number 1 times on all styles",
				X = 400,
				Y = 370,
				Mouse = true,
				Blur = true,
				Data = { send, ViewType = 6 }
			} ):Send( ply )
		else
			Core.Print( ply, "Timer", Core.Text( "CommandWRAllNone" ) )
		end
	end )

	AddCmd( { "profile", "player", "playerprofile", "pp" }, function( ply, args )
		if #args > 0 then
			if string.find( string.lower( args[ 1 ] ), "steam" ) and util.SteamIDTo64( args.Upper[ 1 ] ) != "0" then
				local get = player.GetBySteamID( args.Upper[ 1 ] )
				if IsValid( get ) then
					local ipport = get:IPAddress()
					local ip = string.sub( ipport, 1, string.find( ipport, ":" ) - 1 )
					args.IP = ip
				end

				Core.ShowProfile( ply, args.Upper[ 1 ], args.IP )
			elseif string.find( args[ 1 ], "@", 1, true ) then
				local at = tonumber( string.match( args[ 1 ], "%d+" ) ) or 0
				local found = Core.GetSteamAtID( ply, at )

				if found then
					args[ 1 ] = found
					args.Upper[ 1 ] = found

					local cmd = GetCmd( "profile" )
					cmd( ply, args )
				else
					Core.Print( ply, "General", Core.Text( "CommandProfileNoneAt", at, Core.StyleName( ply.Style ) ) )
				end
			elseif string.find( args[ 1 ], "#", 1, true ) then
				local found
				for _,p in pairs( player.GetHumans() ) do
					if string.find( string.lower( p:Name() ), string.sub( args[ 1 ], 2 ), 1, true ) then
						found = p
						break
					end
				end

				if IsValid( found ) then
					args[ 1 ] = found:SteamID()
					args.Upper[ 1 ] = args[ 1 ]

					local cmd = GetCmd( "profile" )
					cmd( ply, args )
				else
					Core.Print( ply, "General", Core.Text( "CommandProfileNoneName", args[ 1 ] ) )
				end
			else
				Core.Print( ply, "General", Core.Text( "CommandProfileIdentifier" ) )
			end
		else
			local ipport = ply:IPAddress()
			local ip = string.sub( ipport, 1, string.find( ipport, ":" ) - 1 )
			Core.ShowProfile( ply, ply:SteamID(), ip )
		end
	end )

	AddCmd( { "showkeys", "sk", "keys", "displaykeys" }, function( ply, args )
		ply.ShowKeys = true

		if ply.Spectating then
			Core.EnableKeyTrack()
		end

		Core.Send( ply, "GUI/Create", { ID = "Keys", Dimension = { x = 200, y = 130, px = 20 }, Args = { Title = "Keys" } } )
	end )

	AddCmd( { "close", "closewindow", "hidewindow", "destroy" }, function( ply, args )
		Core.Send( ply, "GUI/Close" )
	end )

	AddCmd( { "togglewnd", "hidewnd", "hidew", "hidewindow", "showwnd", "showw", "showwindow", "windowvis", "windowvisibility", "togglew" }, function( ply, args )
		if string.sub( args.Key, 1, 1 ) == "h" or string.sub( args.Key, 1, 1 ) == "s" then
			Core.Send( ply, "GUI/Visibility", string.sub( args.Key, 1, 1 ) == "h" )
		else
			Core.Send( ply, "GUI/Visibility" )
		end
	end )

	-- Weapon functionality
	AddCmd( { "crosshair", "cross", "togglecrosshair", "togglecross", "setcross" }, function( ply, args )
		if #args > 0 then
			local szType = args[ 1 ]
			if szType == "length" then
				if not #args == 2 or not tonumber( args[ 2 ] ) then
					return Core.Print( ply, "General", Core.Text( "CommandParameterMissing", "crosshair length", "[number]" ) )
				end

				Core.Send( ply, "Client/Crosshair", { ["crossstring.length"] = args[ 2 ] } )
			elseif szType == "gap" then
				if not #args == 2 or not tonumber( args[ 2 ] ) then
					return Core.Print( ply, "General", Core.Text( "CommandParameterMissing", "crosshair gap", "[number]" ) )
				end

				Core.Send( ply, "Client/Crosshair", { ["cross_gap"] = args[ 2 ] } )
			elseif szType == "thick" then
				if not #args == 2 or not tonumber( args[ 2 ] ) then
					return Core.Print( ply, "General", Core.Text( "CommandParameterMissing", "crosshair thick", "[number]" ) )
				end

				Core.Send( ply, "Client/Crosshair", { ["cross_thick"] = args[ 2 ] } )
			elseif szType == "opacity" then
				if not #args == 2 or not tonumber( args[ 2 ] ) then
					return Core.Print( ply, "General", Core.Text( "CommandParameterMissing", "crosshair opacity", "[number: between 0 and 255]" ) )
				end

				Core.Send( ply, "Client/Crosshair", { ["cross_opacity"] = args[ 2 ] } )
			elseif szType == "color" then
				if not #args == 4 or not tonumber( args[ 2 ] ) or not tonumber( args[ 3 ] ) or not tonumber( args[ 4 ] ) then
					return Core.Print( ply, "General", Core.Text( "CommandParameterMissing", "crosshair color", "[3x number: between 0 and 255]" ) )
				end

				Core.Send( ply, "Client/Crosshair", { ["cross_colr"] = args[ 2 ], ["cross_colg"] = args[ 3 ], ["cross_colb"] = args[ 4 ] } )
			elseif szType == "default" then
				Core.Send( ply, "Client/Crosshair", { ["crossstring.length"] = 1, ["cross_gap"] = 1, ["cross_thick"] = 0, ["cross_opacity"] = 255, ["cross_colr"] = 0, ["cross_colg"] = 255, ["cross_colb"] = 0 } )
			elseif szType == "random" then
				Core.Send( ply, "Client/Crosshair", { ["crossstring.length"] = math.random( 1, 50 ), ["cross_gap"] = math.random( 1, 35 ), ["cross_thick"] = math.random( 0, 10 ), ["cross_opacity"] = math.random( 70, 255 ), ["cross_colr"] = math.random( 0, 255 ), ["cross_colg"] = math.random( 0, 255 ), ["cross_colb"] = math.random( 0, 255 ) } )
			elseif szType == "disable" then
				Core.Send( ply, "Client/Crosshair", false )
			elseif szType == "enable" then
				Core.Send( ply, "Client/Crosshair", true )
			else
				Core.Print( ply, "General", Core.Text( "CommandSubList", args.Key, "color [red green blue], length [scalar], gap [scalar], thick [scalar], opacity [alpha], default, random, disable, enable" ) )
			end
		else
			Core.Send( ply, "Client/Crosshair" )
		end
	end )

	AddCmd( { "glock", "usp", "knife", "p90", "mp5", "crowbar", "deagle", "fiveseven", "m4a1", "ump45", "scout", "weapon", "weapons" }, function( ply, args )
		if ply.Spectating or ply:Team() == TEAM_SPECTATOR then
			return Core.Print( ply, "General", Core.Text( "SpectateWeapon" ) )
		else
			if args.Key == "weapon" or args.Key == "weapons" then
				local func = Command.Func["glock"]
				local list = table.Copy( func[ 1 ] )

				table.remove( list )
				table.remove( list )

				if #args == 0 or not table.HasValue( list, args[ 1 ] ) then
					return Core.Print( ply, "General", Core.Text( "CommandWeaponList", string.Implode( ", ", list ) ) )
				else
					args.Key = args[ 1 ]
				end
			end

			if Core.Config.IsSurf then
				local valids = Core.Config.Player.SurfWeapons or {}
				if not valids[ "weapon_" .. args.Key ] then
					return Core.Print( ply, "General", Core.Text( "CommandWeaponLimited" ) )
				end
			end

			local bFound = false
			for _,ent in pairs( ply:GetWeapons() ) do
				if ent:GetClass() == "weapon_" .. args.Key then
					bFound = true
					break
				end
			end

			if not bFound then
				local set = ply.WeaponPickupProhibit
				ply.WeaponPickupProhibit = nil
				ply:Give( "weapon_" .. args.Key )
				ply:SelectWeapon( "weapon_" .. args.Key )

				Core.Print( ply, "General", Core.Text( "PlayerGunObtain", args.Key ) )

				if set then
					ply.WeaponPickupProhibit = set
				end
			else
				Core.Print( ply, "General", Core.Text( "PlayerGunFound", args.Key ) )
			end
		end
	end )

	AddCmd( { "remove", "strip", "stripweapons" }, function( ply )
		if not ply.Spectating then
			ply:StripWeapons()
		else
			return Core.Print( ply, "General", Core.Text( "SpectateWeapon" ) )
		end
	end )

	AddCmd( { "flip", "leftweapon", "leftwep", "lefty", "flipwep", "flipweapon" }, function( ply )
		Core.Send( ply, "Client/WeaponFlip" )
	end )

	AddCmd( { "noguns", "nogun", "nogunpickup", "noweaponpickup", "noweps", "noweaps", "noweapons", "nopickup" }, function( ply )
		ply.WeaponPickupProhibit = not ply.WeaponPickupProhibit
		Core.Print( ply, "General", Core.Text( "CommandWeaponPickup", ply.WeaponPickupProhibit and "disabled" or "enabled" ) )
	end )

	-- Client functionality
	AddCmd( { "hide", "show", "showplayers", "hideplayers", "toggleplayers", "seeplayers", "noplayers" }, function( ply, args )
		if string.sub( args.Key, 1, 4 ) == "show" or string.sub( args.Key, 1, 4 ) == "hide" then
			Core.Send( ply, "Client/PlayerVisibility", string.sub( args.Key, 1, 4 ) == "hide" and 0 or 1 )
		else
			Core.Send( ply, "Client/PlayerVisibility", -1 )
		end
	end )

	AddCmd( { "hidespec", "showspec", "togglespec" }, function( ply, args )
		local key = string.sub( args.Key, 1, 1 )
		if key == "s" then
			Core.Send( ply, "Client/SpecVisibility", 1 )
		elseif key == "h" then
			Core.Send( ply, "Client/SpecVisibility", 0 )
		elseif key == "t" then
			Core.Send( ply, "Client/SpecVisibility" )
		end
	end )

	AddCmd( { "zones", "showzones", "showzone", "hidezones", "hidezone", "togglezones" }, function( ply, args )
		local key = string.sub( args.Key, 1, 1 )
		if key == "s" then
			Core.Send( ply, "Client/ZoneVisibility", 1 )
		elseif key == "h" then
			Core.Send( ply, "Client/ZoneVisibility", 0 )
		elseif key == "t" or key == "z" then
			Core.Send( ply, "Client/ZoneVisibility" )
		end
	end )

	AddCmd( { "chat", "togglechat", "hidechat", "showchat" }, function( ply )
		Core.Send( ply, "Client/Chat" )
	end )

	AddCmd( { "muteall", "muteplayers", "unmuteall", "unmuteplayers" }, function( ply, args )
		Core.Send( ply, "Client/MuteAll", { string.sub( args.Key, 1, 1 ) == "m" and true or nil, false } )
	end )

	AddCmd( { "chatmuteall", "chatmuteplayers", "unchatmuteall", "unchatmuteplayers" }, function( ply, args )
		Core.Send( ply, "Client/MuteAll", { string.sub( args.Key, 1, 1 ) == "c" and true or nil, true } )
	end )

	AddCmd( { "voicemute", "voicegag", "chatmute", "chatgag", "unvoicemute", "unvoicegag", "unchatmute", "unchatgag" }, function( ply, args )
		if #args != 1 then
			return Core.Print( ply, "General", Core.Text( "CommandMuteArguments", args.Key ) )
		end

		local key, force = string.sub( args.Key, 1, 1 )
		if key == "u" then
			force = false
		end

		Core.Send( ply, "Client/MuteSingle", { Type = string.find( args.Key, "voice" ) and "Voice" or "Chat", Find = args[ 1 ], Force = force } )
	end )

	AddCmd( { "playernames", "playername", "playertag", "playerids", "targetids", "targetid", "labels" }, function( ply )
		Core.Send( ply, "Client/TargetIDs" )
	end )

	AddCmd( { "water", "fixwater", "reflection", "refraction", "fuckicantsee", "myeyes!" }, function( ply )
		Core.Send( ply, "Client/Water" )
	end )

	AddCmd( { "decals", "blood", "shots", "removedecals", "imonmyperiod" }, function( ply )
		Core.Send( ply, "Client/Decals" )
	end )

	AddCmd( { "sky", "3dsky", "skybox", "fpsboost" }, function( ply )
		Core.Send( ply, "Client/Sky3D" )
	end )

	AddCmd( { "toggle", "toggleopt", "toggleoption", "toggleconf", "toggleconfig" }, function( ply, args )
		Core.Send( ply, "Client/Config", args.Params )
	end )

	AddCmd( { "setopt", "setoption", "setconf", "setconfig", "setitem" }, function( ply, args )
		Core.Send( ply, "Client/Config", args.Params, true )
	end )

	AddCmd( { "space", "spacetoggle", "holdtoggle", "lazymode" }, function( ply )
		ply.SpaceEnabled = not ply.SpaceEnabled
		Core.Send( ply, "Timer/Space" )
	end )

	AddCmd( { "thirdperson", "thirdp", "third", "aerial", "birdseye", "doilookfatinthisdress" }, function( ply )
		GAMEMODE:ShowSpare1( ply )
	end )

	-- Info commands
	AddCmd( { "help", "commands", "command", "alias", "aliases" }, function( ply, args )
		local FromSettings = false
		if #args > 0 then
			if args[ 1 ] == "fs" then
				FromSettings = true
				args = {}
			end
		end

		if #args > 0 then
			local mainArg, th, own = "", table.HasValue, string.lower( args[ 1 ] )
			for main,data in pairs( Command.Func ) do
				if th( data[ 1 ], own ) then
					mainArg = main
					break
				end
			end

			if mainArg != "" then
				local commands = Core.ContentText( "Commands" )
				local data = commands[ mainArg ]
				if data then
					local alias = ""
					local tab = table.Copy( Command.Func[ mainArg ][ 1 ] )
					table.RemoveByValue( tab, own )

					if #tab > 0 then
						alias = "\nAdditional aliases for the command are: " .. string.Implode( ", ", tab )
					end

					Core.Print( ply, "General", Core.Text( "CommandHelpDisplay", own, data:gsub( "%a", string.lower, 1 ) .. alias ) )
				else
					Core.Print( ply, "General", Core.Text( "CommandHelpNone", own ) )
				end
			else
				Core.Print( ply, "General", Core.Text( "CommandHelpInavailable", args[ 1 ] ) )
			end
		else
			net.Start( "BinaryTransfer" )
			net.WriteString( "Help" )
			net.WriteBit( FromSettings )

			if ply.HelpReceived then
				net.WriteUInt( 0, 32 )
			else
				net.WriteUInt( HelpLength, 32 )
				net.WriteData( HelpData, HelpLength )
				ply.HelpReceived = true
			end

			net.Send( ply )
		end
	end )

	AddCmd( { "map", "points", "mapdata", "mapinfo", "difficulty", "tier", "mi" }, function( ply, args )
		if Core.Config.IsSurf then
			Core.AddText( "MapInfo", "The map '1;' has a weight of 2; points 3;4;5;" )
		end

		if #args > 0 then
			if not args[ 1 ] then return end
			if Core.MapCheck( args[ 1 ] ) then
				local data = Core.MapCheck( args[ 1 ], nil, true )
				local last = Core.GetLastPlayed( args[ 1 ] )
				Core.Print( ply, "General", Core.Text( "MapInfo", data[ 1 ], data[ 2 ] or 1, "(Played " .. data[ 3 ] .. " times" .. (last and ", last on " .. last or "") .. ")", "", Core.Config.IsSurf and " (Tier " .. data[ 4 ] .. " - " .. (data[ 5 ] == 1 and "Staged" or "Linear") .. ")" or "" ) )
			else
				Core.Print( ply, "General", Core.Text( "MapInavailable", args[ 1 ] ) )
			end
		else
			local nMult, bMult = Core.GetMapVariable( "Multiplier" ) or 1, Core.GetMapVariable( "Bonus" ) or 1
			local szBonus, szPoints, szAdditional = "", ""

			if not ply.OutputSock then
				if ply.Bonus then
					local nStyle = Core.MakeBonusStyle( ply.Style, ply.Bonus )
					local nPoints = Core.GetPointsForMap( ply, ply.Record, nStyle )
					if ply.Style == Styles.Normal then
						szPoints = "(For the bonuses, you obtained " .. math.Round( nPoints, 2 ) .. " / " .. Core.GetMultiplier( nStyle, true ) .. " pts)"
					else
						szPoints = "(You only get points for bonuses on the Normal style)"
					end
				else
					local nPoints = Core.GetPointsForMap( ply, ply.Record, ply.Style )
					szPoints = "(Obtained " .. math.Round( nPoints, 2 ) .. " / " .. nMult .. " pts)"
				end
			end

			if #Core.GetBonusIDs() > 0 then
				if type( bMult ) == "table" then
					local tab = {}
					for i = 1, #bMult do
						tab[ i ] = "[Bonus " .. i .. "]: " .. bMult[ i ]
					end

					szBonus = " (Bonus points for " .. string.Implode( ", ", tab ) .. ")"
				else
					szBonus = " (Bonus has a multiplier of " .. bMult .. ")"
				end
			end

			if Core.Config.IsSurf then
				local mtier, mtype, stages = Core.GetMapVariable( "Tier" ) or 1, Core.GetMapVariable( "Type" ) or 0, Core.Ext( "Stages", "GetStageCount" )() or 0
				szAdditional = " and is of type Tier " .. mtier .. " - " .. (mtype == 1 and "Staged" .. (stages > 0 and " (Amount: " .. stages .. ")" or "") or "Linear")
			end

			local text = Core.Text( "MapInfo", game.GetMap(), nMult, szPoints, szBonus, szAdditional )
			if ply.OutputSock then
				return text
			else
				Core.Print( ply, "General", text )
			end
		end
	end )

	AddCmd( { "plays", "playcount", "timesplayed", "howoften" }, function( ply, args )
		local thismap = game.GetMap()
		local map = #args > 0 and args[ 1 ] or thismap
		local played, data = Core.GetLastPlayed( map )

		if data then
			local plays = map == thismap and Core.GetMapVariable( "Plays" ) or (data.nPlays or 0)
			Core.Print( ply, "General", Core.Text( "MapPlayed", map == thismap and "This map" or "'" .. map .. "'", plays, played and " It has last been played on " .. played or "" ) )
		else
			Core.Print( ply, "General", Core.Text( "MapInavailable", map ) )
		end
	end )

	AddCmd( { "playinfo", "leastplayed", "mostplayed", "overplayed", "lastplayed", "randommap", "lastmaps" }, function( ply, args )
		ply:RTV( "MapFunc", args.Key )
	end )

	AddCmd( { "wrpos", "mypos", "ladderpos", "leaderboardpos", "mytime", "myrec", "recpos" }, function( ply, args )
		if #args > 0 and args[ 1 ] != game.GetMap() and not tonumber( args[ 1 ] ) then
			ply.OutputFull = function( p, data )
				p.OutputFull = nil

				local found
				if data and table.Count( data ) > 0 then
					for i = 1, #data do
						if data[ i ].szUID == p.UID then
							found = { i, data[ i ].nTime }
						end
					end
				end

				if found then
					Core.Print( p, "General", Core.Text( "CommandWRPosInfo", found[ 1 ], Core.ConvertTime( found[ 2 ] ), " on '" .. args[ 1 ] .. "'" ) )
				elseif data then
					Core.Print( p, "General", Core.Text( "CommandWRPosMissing", "'" .. args[ 1 ] .. "'" ) )
				end
			end

			if not Core.DoRemoteWR( ply, args[ 1 ], ply.Style ) then
				ply.OutputFull = nil
			end
		else
			local t,i = Core.GetPlayerRecord( ply, ply.Style )
			if i > 0 then
				Core.Print( ply, "General", Core.Text( "CommandWRPosInfo", i, Core.ConvertTime( t ), "!" ) )
			else
				Core.Print( ply, "General", Core.Text( "CommandWRPosMissing", "the map" ) )
			end
		end
	end )

	AddCmd( { "getwr", "showwr", "stylewr", "thiswr" }, function( ply, args )
		local tab = Core.GetTopTimes()
		local style = tonumber( args[ 1 ] ) or ply.Style
		local item = tab[ style ]

		if item then
			Core.Send( ply, "Client/SteamText", { "General", Core.Text( "CommandWRInfo", Core.StyleName( style ), Core.ConvertTime( item.nTime or 0 ), item.szUID and "{STEAM}" or "Unknown" ), item.szUID or "Unknown" } )
		else
			Core.Print( ply, "General", Core.Text( "CommandWRNone" ) )
		end
	end )

	AddCmd( { "average", "getaverage", "timeaverage", "averagetime", "avg" }, function( ply, args )
		local style = tonumber( args[ 1 ] ) or ply.Style
		local avg = Core.GetAverage( style )

		if avg > 0 then
			Core.Print( ply, "General", Core.Text( "CommandTimeAvgValue", Core.StyleName( style ), Core.ConvertTime( avg ) ) )
		else
			Core.Print( ply, "General", Core.Text( "CommandTimeAvgNone" ) )
		end
	end )

	AddCmd( { "hop", "swap", "swapserver", "server", "servers" }, function( ply, args )
		local Active = Core.Config.Var.GetSiblings()
		local CustomGo

		local function FindByShort( tab, short )
			for _,data in pairs( tab ) do
				for __,name in pairs( data[ 3 ] ) do
					if name == short then
						return data
					end
				end
			end
		end

		if args.Key == "hop" or args.Key == "swap" or args.Key == "swapserver" then
			if #args > 0 and Active[ args[ 1 ] ] then
				CustomGo = args[ 1 ]
			else
				local tabQuery = {
					Caption = "What server do you want to connect to?",
					Title = "Connect to another server"
				}

				local added = {}
				for _,data in pairs( Active ) do
					if added[ data.IP ] then continue end

					tabQuery[ #tabQuery + 1 ] = { data.Name, { data.IP } }
					added[ data.IP ] = true
				end

				tabQuery[ #tabQuery + 1 ] = { "[[Close", {} }

				Core.Send( ply, "Client/Redirect", { true, tabQuery } )
			end
		end

		if not CustomGo then
			if Active[ string.sub( args.Key, 3 ) ] then
				CustomGo = string.sub( args.Key, 3 )
			end
		end

		if CustomGo then
			local data = Active[ CustomGo ]
			if not data then return end

			Core.Send( ply, "Client/Redirect", { false, data.IP, data.Name } )
		end
	end )

	AddCmd( { "about", "info", "credits", "author", "owner", "whomadethis" }, function( ply )
		Core.Print( ply, "General", Core.Text( "MiscAbout" ) )
	end )

	AddCmd( { "tutorial", "tut", "howto", "helppls", "plshelp", "imhopeless" }, function( ply )
		local link = Core.Config.Var.Get( "URLTutorial" )
		if link == Core.Config.Var.GetDefault( "URLTutorial" ) and Core.Config.IsSurf then
			link = Core.ContentText( "SurfLink" )
		end

		Core.Send( ply, "Client/URL", { link } )
	end )

	AddCmd( { "website", "web" }, function( ply )
		local link = Core.Config.Var.Get( "URLWebsite" )
		if link == "" then
			Core.Print( ply, "General", Core.Text( "CommandLinkNotSet" ) )
		else
			Core.Send( ply, "Client/URL", { link } )
		end
	end )

	AddCmd( { "youtube", "speedruns", "videos", "video", "60fps" }, function( ply )
		Core.Send( ply, "Client/URL", { Core.ContentText( "ChannelLink" ) } )
	end )

	AddCmd( { "forum", "forums", "community" }, function( ply )
		local link = Core.Config.Var.Get( "URLForum" )
		if link == "" then
			Core.Print( ply, "General", Core.Text( "CommandLinkNotSet" ) )
		else
			Core.Send( ply, "Client/URL", { link } )
		end
	end )

	AddCmd( { "thread", "gamemode", "gminfo", "donate", "donation", "sendmoney", "givemoney", "gibepls" }, function( ply )
		Core.Send( ply, "Client/URL", { Core.ContentText( "ThreadLink" ) } )
	end )

	AddCmd( { "version", "ver", "lastchange", "changelog", "changes", "info", "whatdidgravdonow" }, function( ply )
		local link = Core.Config.Var.Get( "URLChangelogs" )
		if link == "" then
			Core.Print( ply, "General", Core.Text( "CommandLinkNotSet" ) )
		else
			Core.Send( ply, "Client/URL", { link } )
		end
	end )

	-- Quick style commands
	AddCmd( { "n", "normal", "default", "standard" }, function( ply ) CommandStyleSet( ply, Styles.Normal ) end )
	AddCmd( { "sw", "sideways" }, function( ply ) CommandStyleSet( ply, Styles.SW ) end )
	AddCmd( { "hsw", "halfsideways", "halfsw", "h" }, function( ply ) CommandStyleSet( ply, Styles.HSW ) end )
	AddCmd( { "w", "wonly" }, function( ply ) CommandStyleSet( ply, Styles["W-Only"] ) end )
	AddCmd( { "a", "aonly" }, function( ply ) CommandStyleSet( ply, Styles["A-Only"] ) end )
	AddCmd( { "d", "donly" }, function( ply ) CommandStyleSet( ply, Styles["D-Only"] ) end )
	AddCmd( { "s", "sonly" }, function( ply, args ) if args.Key == "s" and #args > 0 and tonumber( args[ 1 ] ) then local func = GetCmd( "stage" ) func( ply, args ) else CommandStyleSet( ply, Styles["S-Only"] ) end end )
	AddCmd( { "l", "legit" }, function( ply ) CommandStyleSet( ply, Styles.Legit ) end )
	AddCmd( { "e", "scroll", "easy", "easyscroll", "ez" }, function( ply ) CommandStyleSet( ply, Styles["Easy Scroll"] ) end )
	AddCmd( { "u", "unreal", "weirdshit", "superfast", "speedy" }, function( ply ) CommandStyleSet( ply, Styles.Unreal ) end )
	AddCmd( { "bw", "backwards", "back" }, function( ply ) CommandStyleSet( ply, Styles.Backwards ) end )
	AddCmd( { "lg", "lowgrav", "fly" }, function( ply ) CommandStyleSet( ply, Styles["Low Gravity"] ) end )
	AddCmd( { "p", "practice", "try", "free" }, function( ply, args ) if args.Key == "p" and #args > 0 then local func = GetCmd( "profile" ) args.Key = "profile" func( ply, args ) else CommandStyleSet( ply, Core.Config.PracticeStyle ) end end )
	AddCmd( { "b", "bonus", "extra" }, CommandStyleBonus )

	-- Quick WR list commands
	AddCmd( { "wrn", "wrnormal", "nwr" }, function( ply, args ) CommandShowWR( ply, args, Styles.Normal ) end )
	AddCmd( { "wrsw", "wrsideways", "swwr" }, function( ply, args ) CommandShowWR( ply, args, Styles.SW ) end )
	AddCmd( { "wrhsw", "wrhalf", "wrhalfsw", "wrhalfsideways", "hswwr" }, function( ply, args ) CommandShowWR( ply, args, Styles.HSW ) end )
	AddCmd( { "wrw", "wrwonly", "wwr", "wonlywr" }, function( ply, args ) CommandShowWR( ply, args, Styles["W-Only"] ) end )
	AddCmd( { "wra", "wraonly", "awr", "aonlywr" }, function( ply, args ) CommandShowWR( ply, args, Styles["A-Only"] ) end )
	AddCmd( { "wrd", "wrdonly", "dwr", "donlywr" }, function( ply, args ) CommandShowWR( ply, args, Styles["D-Only"] ) end )
	AddCmd( { "wrs", "wrsonly", "swr", "sonlywr" }, function( ply, args ) CommandShowWR( ply, args, Styles["S-Only"] ) end )
	AddCmd( { "wrl", "wrlegit", "lwr" }, function( ply, args ) CommandShowWR( ply, args, Styles.Legit ) end )
	AddCmd( { "wre", "wrscroll", "scrollwr", "ewr", "ezwr", "wrez" }, function( ply, args ) CommandShowWR( ply, args, Styles["Easy Scroll"] ) end )
	AddCmd( { "wru", "wrunreal", "uwr", "unrealwr" }, function( ply, args ) CommandShowWR( ply, args, Styles.Unreal ) end )
	AddCmd( { "wrbw", "wrbackwards", "bwwr", "backwardswr" }, function( ply, args ) CommandShowWR( ply, args, Styles.Backwards ) end )
	AddCmd( { "wrlg", "wrlowgrav", "wrlowgravity", "lgwr", "lowgravwr", "lowgravitywr" }, function( ply, args ) CommandShowWR( ply, args, Styles["Low Gravity"] ) end )
	AddCmd( { "wrb", "wrbonus", "bwr" }, function( ply, args ) if not args[ 2 ] and tonumber( args[ 1 ] ) then args[ 2 ] = tonumber( args[ 1 ] ) args[ 1 ] = game.GetMap() end CommandShowWR( ply, args, Styles.Bonus + ((tonumber( args[ 2 ] ) and args[ 1 ]) and math.Clamp( tonumber( args[ 2 ] ) - 1, 0, 50 - Styles.Bonus ) or 0) ) end )

	-- Stamina commands
	if Core.Config.IsPack then
		AddCmd( { "j", "jump", "jumppack", "jp", "easymode", "noobmode", "imbad" }, function( ply ) CommandStyleSet( ply, Styles["Jump Pack"] ) end )
		AddCmd( { "wrj", "wrjp", "wrjump", "wrjumppack", "jwr", "jumpwr", "jumppackwr" }, function( ply, args ) CommandShowWR( ply, args, Styles["Jump Pack"] ) end )
	else
		AddCmd( { "stam", "stamina" }, function( ply ) CommandStyleSet( ply, Styles.Stamina ) end )
		AddCmd( { "wrstam", "wrstamina", "stamwr" }, function( ply, args ) CommandShowWR( ply, args, Styles.Stamina ) end )
	end

	-- Main top list command (gets filled with aliases according to lookup table)
	AddCmd( { "normtop", "top", "toplist", "topplayers", "bestplayers", "besties" }, function( ply, args )
		local lookup = Core.ContentText( "StyleLookup" )
		local key = string.gsub( args.Key, "top", "" )
		local style = lookup[ key ] or ply.Style or Styles.Normal
		if args.Key == "top" and #args > 0 then
			if lookup[ args[ 1 ] ] then
				style = lookup[ args[ 1 ] ]
			end
		end

		-- To-Do: Yeaaaaaaaaaaaaa
		if Core.IsValidBonus( style ) then
			style = Styles.Bonus
		end

		local data = Core.GetPlayerTop( style )
		if #data == 0 then
			return Core.Print( ply, "Timer", Core.Text( "CommandTopListBlank", Core.StyleName( style ) ) )
		else
			Core.Prepare( "GUI/Build", {
				ID = "Top",
				Title = Core.StyleName( style ) .. " Top List (Best " .. #data .. " out of " .. Core.GetPlayerCount( style ) .. ")",
				X = 400,
				Y = 370,
				Mouse = true,
				Blur = true,
				Data = { data, ViewType = 0 }
			} ):Send( ply )
		end
	end )

	-- Main WR top list command (gets filled with aliases according to lookup table)
	AddCmd( { "wrtop", "topwr", "topwrs", "normwrtop" }, function( ply, args )
		local lookup = Core.ContentText( "StyleLookup" )
		local key = string.gsub( args.Key, "wrtop", "" )
		local style = lookup[ key ] or ply.Style or Styles.Normal

		-- To-Do: No worrkyyyy
		if Core.IsValidBonus( style ) then
			style = Styles.Bonus
		end

		local data = Core.GetPlayerWRTop( style )
		local count = table.Count( data )

		if count == 0 then
			return Core.Print( ply, "Timer", Core.Text( "CommandWRTopBlank", Core.StyleName( style ) ) )
		else
			Core.Prepare( "GUI/Build", {
				ID = "Top",
				Title = Core.StyleName( style ) .. " WR Top List (" .. count .. " holders)",
				X = 400,
				Y = 370,
				Mouse = true,
				Blur = true,
				Data = { data, ViewType = 7, Count = count }
			} ):Send( ply )
		end
	end )

	-- Miscellaneous
	AddCmd( { "jiggy", "george", "insane", "randomsound", "randomwrsound" }, function( ply, args )
		local name, poss = "wr_jiggy", {}
		local all = Core.GetMapVariable( "WRSounds" )

		if args.Key == "george" then
			for i = 1, #all do
				if string.find( all[ i ], args.Key, 1, true ) then
					poss[ #poss + 1 ] = all[ i ]
				end
			end
		elseif args.Key == "randomsound" or args.Key == "randomwrsound" then
			poss = all
		elseif args.Key == "insane" then
			name = "insane"
		end

		if #poss > 0 then
			name = poss[ math.random( 1, #poss ) ]
		end

		local path = GetConVar( "sv_downloadurl" ):GetString() .. "/sound/" .. Core.Config.MaterialID .. "/" .. name .. ".mp3"
		ply:SendLua( "sound.PlayURL(\"" .. path .. "\",\"\",function(o) if not IsValid(o) then return end if IsValid(JSC) then JSC:SetVolume(0) JSC:Stop() JSC = nil end JSC = o JSC:Play() end)" )
	end )

	AddCmd( { "model", "setmodel", "looks", "changemylooks", "iwanttobesexy" }, function( ply, args )
		if not Core.Config.Var.GetBool( "ModelAllowed" ) then
			return Core.Print( ply, "General", Core.Text( "CommandModelDisabled" ) )
		end

		if args.Key == "iwanttobesexy" then
			args[ 1 ] = "alyx"
		end

		if #args > 0 then
			local models, found = Core.ContentText( "ValidModels" )
			for _,model in pairs( models ) do
				if model == args[ 1 ] then
					found = true
					break
				end
			end

			if not found and args[ 1 ] != "" then
				return Core.Print( ply, "General", Core.Text( "CommandModelInvalid", args[ 1 ] ) )
			end

			local path = "models/player/" .. args[ 1 ] .. ".mdl"
			if args[ 1 ] == "default" or args[ 1 ] == "" then
				args[ 1 ] = "default"
				path = Core.Config.Player.DefaultModel
			end

			ply:SetModel( path )

			if not args.SkipMessage then
				Core.Print( ply, "General", Core.Text( "CommandModelChange", args[ 1 ] ) )
			end
		else
			Core.Print( ply, "General", Core.Text( "CommandModelBlank" ) )
		end
	end )

	AddCmd( { "female", "givemetits", "avaginawilldotoo" }, function( ply )
		ply:SetModel( "models/player/" .. table.Random( Core.ContentText( "FemaleModels" ) ) .. ".mdl" )
		Core.Print( ply, "General", Core.Text( "CommandModelChange", "a random female model" ) )
	end )

	AddCmd( { "remainingtries", "triesleft", "tries", "killmeafter", "icantstop", "pleasehelpmequit", "imaddictedhalp" }, function( ply, args )
		if #args > 0 then
			if #args > 1 and (((args[ 1 ] == "kick" or args[ 1 ] == "count") and tonumber( args[ 2 ] )) or (args[ 1 ] == "time" and string.find( args[ 2 ], ":", 1, true ))) then
				if ply.TryTrack and ply.TryTrack.Type == "time" then
					Core.Send( ply, "Timer/Kicker" )
				end

				local add = "."
				ply.TryTrack = { Type = args[ 1 ], Amount = math.abs( tonumber( args[ 2 ] ) or 1 ) }

				if ply.TryTrack.Type == "time" then
					ply.TryTrack.Time = args[ 2 ]
					add = ". You will be kicked at " .. args[ 2 ] .. ". To cancel this, type !" .. args.Key .. " stop"
					Core.Send( ply, "Timer/Kicker", args[ 2 ] )
				end

				Core.Print( ply, "General", Core.Text( "CommandTriesActivated", args[ 1 ], add ) )
			elseif args[ 1 ] == "stop" then
				Core.Send( ply, "Timer/Kicker" )

				ply.TryTrack = nil
				Core.Print( ply, "General", Core.Text( "CommandTriesStopped" ) )
			elseif args[ 1 ] == "finalize" and ply.TryTrack and ply.TryTrack.Type == "time" and ply.TryTrack.Time == args[ 2 ] then
				ply:Kick( "Playtime is over!" )
			else
				Core.Print( ply, "General", Core.Text( "CommandTriesSubTypes", args.Key ) )
			end
		else
			Core.Print( ply, "General", Core.Text( "CommandTriesInfo", args.Key, args.Key ) )
		end
	end )

	-- Default functions
	AddCmd( "invalid", function( ply, args )
		if args.Key == "invalid" then
			Core.Print( ply, "General", Core.Text( "InvalidCommandLoophole" ) )
		else
			Core.Print( ply, "General", Core.Text( "InvalidCommand", args.Key ) )
		end
	end )

	-- And finalize some command aliases
	local lookup = Core.ContentText( "StyleLookup" )
	for key,_ in pairs( lookup ) do
		AddAlias( "normtop", key .. "top" )
		AddAlias( "normtop", "top" .. key )
		AddAlias( "wrtop", key .. "wrtop" )
		AddAlias( "wrtop", key .. "wrtoplist" )
		AddAlias( "wrtop", "wrtop" .. key )
	end

	-- After all commands have been loaded in, we can setup the help cache
	LoadHelp()

	-- Check for control lockdown
	if file.Exists( "lockdown.txt", "DATA" ) then
		local lock = file.Read( "lockdown.txt", "DATA" )
		local split = string.Explode( ";", lock )
		Core.Lockdown = split[ 1 ]
		Core.LockExclude = split[ 2 ]

		print( "A lockdown has been restored from file!" )
	end

	-- Print result
	Core.PrintC( "[Load] Enabled " .. CountCommands() .. " commands!" )
end


--[[
	Description: Checks if we're entering a command or not
	Notes: Overrides the base gamemode hook so we can easily cancel out the message
--]]
function GM:PlayerSay( ply, text )
	local szPrefix = string.sub( text, 1, 1 )
	local szCommand = "invalid"

	if szPrefix != "!" and szPrefix != "/" then
		return FilterAnyText( ply, text )
	else
		szCommand = string.lower( string.sub( text, 2 ) )
		if szCommand == "" then return "" end
	end

	local szReply = TriggerCmd( ply, szCommand, text )
	if not szReply or not type( szReply ) == "string" then
		return ""
	else
		return szReply
	end
end

-- F1 Key
function GM:ShowHelp( ply )
	Core.Send( ply, "GUI/Create", { ID = "Settings", Dimension = { x = 400, y = 300 }, Args = { Title = "Main Menu", Mouse = true, Blur = true, Custom = Core.GetBaseStatistics() } } )
end

-- F2 Key
function GM:ShowTeam( ply )
	Core.Send( ply, "GUI/Create", { ID = "Spectate", Dimension = { x = 180, y = 128 }, Args = { Mouse = true, Blur = true, HideClose = true } } )
end

-- F3 Key
function GM:ShowSpare1( ply, val )
	if ply.Spectating then return Core.Print( ply, "General", Core.Text( "SpectateThirdperson" ) ) end

	ply.Thirdperson = val != nil and val or not ply.Thirdperson

	Core.Send( ply, "Client/Thirdperson", ply.Thirdperson )
end

-- F4 Key
function GM:ShowSpare2( ply, args, style )
	if not args then
		local nStyle = style or ply.Style or Styles.Normal
		args = { Core.GetRecordList( nStyle, 1, Core.Config.PageSize ), Core.GetRecordCount( nStyle ), nStyle }
	end

	if args[ 2 ] == 0 then
		return Core.Print( ply, "Timer", Core.Text( "CommandWRListBlank", Core.StyleName( args[ 3 ] ) ) )
	end

	if not args[ 4 ] then
		local t,i = Core.GetPlayerRecord( ply, args[ 3 ] )
		if i > 0 then
			args[ 4 ] = i
		end
	end

	args.IsEdit = ply.RemovingTimes

	Core.Prepare( "GUI/Build", {
		ID = "Records",
		Title = "Server records",
		X = 500,
		Y = 400,
		Mouse = true,
		Blur = true,
		Data = args
	} ):Send( ply )
end
