-- Define config variables
Core.Config.Var.Add( "AFKMinKick", "afk_minkick", 24, "Allows you to change the minimum amount of players required to be online before starting to kick AFKs" )

-- The extension table
local AFK = {}
AFK.MinimumPlayers = Core.Config.Var.GetInt( "AFKMinKick" )
AFK.StartPoints = 10 -- Amount of tries they get before being marked as AFK
AFK.TickInterval = 10 -- Tick the timer every 10 seconds
AFK.CheckInterval = 30 -- Check each player every 30 seconds

-- Data tables
AFK.Points = {}
AFK.Angles = {}
AFK.LastCheck = {}

--[[
	Description: Initializes the AFK extension
--]]
function AFK.Init()
	-- Start the timer
	timer.Remove( "AFK_Tick" )
	timer.Create( "AFK_Tick", AFK.TickInterval, 0, AFK.Tick )
	
	-- Create all hooks
	hook.Add( "KeyPress", "AFK_OnPlayerKey", AFK.OnPlayerEvent )
	hook.Add( "PlayerSay", "AFK_OnPlayerChat", AFK.OnPlayerEvent )
	hook.Add( "PlayerInitialSpawn", "AFK_OnPlayerCreated", AFK.OnPlayerCreated )
	
	-- And load the language
	Core.AddText( "AFKMinutes", "Hey, wake up! You've been AFK for 1; minutes!" )
	Core.AddText( "AFKKicked", "You've been AFK for 1; minutes and because the player count is too high you have been kicked." )
	Core.AddText( "AFKKickedMessage", "You have been kicked for being AFK too long" )
	
	-- Activate the extension
	Core.Config.Var.Activate( "AFK", AFK )
	Core.PrintC( "[Startup] Extension 'afk' activated" )
end
Core.PostInitFunc = AFK.Init


--[[
	Description: Called by the AFK kicker addon if available on the player
--]]
function AFK.TestPlayer( ply )
	local nPoints = AFK.Points[ ply ]
	if nPoints == 1 then
		Core.Print( ply, "Timer", Core.Text( "AFKMinutes", math.floor( ( (AFK.StartPoints - nPoints) * AFK.CheckInterval) / 60 ) ) )
		
		if not ply.Spectating then
			concommand.Run( ply, "spectate", "bypass", "" )
		end
	elseif nPoints == 0 then
		if #player.GetHumans() >= AFK.MinimumPlayers then
			Core.Print( ply, "Timer", Core.Text( "AFKKicked", math.floor( ( (AFK.StartPoints - nPoints) * AFK.CheckInterval) / 60 ) ) )
		else
			AFK.Points[ ply ] = nPoints + 1
			
			if Core.Ext( "Bot", "IsPlayerActive" )( ply ) then
				Core.Ext( "Bot", "CleanPlayer" )( ply )
				Core.Ext( "Bot", "SetPlayerActive" )( ply )
			end
			
			return true
		end
	end

	return false
end

--[[
	Description: Checks if they moved their mouse
--]]
function AFK.CompareAngles( ply )
	if not AFK.Angles[ ply ] or AFK.Angles[ ply ] != ply:EyeAngles() then
		AFK.Angles[ ply ] = ply:EyeAngles()
		return true
	else
		return false
	end
end

--[[
	Description: Gets the amount of points a player still has
--]]
function AFK.GetPoints( ply )
	return AFK.Points[ ply ] or AFK.StartPoints
end

--[[
	Description: Subtract a point and check if the limit has been reached
--]]
function AFK.SubtractPoints( ply )
	AFK.Points[ ply ] = AFK.Points[ ply ] - 1
	
	-- Run additional checks on the player to see in what state the gamemode is
	if AFK.TestPlayer( ply ) then
		return false
	end
	
	-- This means we're supposed to get kicked
	if AFK.Points[ ply ] <= 0 then
		if #player.GetHumans() >= AFK.MinimumPlayers then
			ply.DCReason = "AFK for too long"
			ply:Kick( Core.Text( "AFKKickedMessage" ) )
			
			return true
		elseif AFK.Points[ ply ] < 0 then
			AFK.Points[ ply ] = 0
		end
	end
end


--[[
	Description: Timer that constantly checks player activity
--]]
function AFK.Tick()
	-- Get a table with all players (excluding bots)
	local plys = player.GetHumans()
	local count = #plys
	
	-- Loop over all players
	for i = 1, count do
		-- Get the player, their points and set a default pass variable
		local ply = plys[ i ]
		local points = AFK.Points[ ply ]
		local pass = false
		
		-- Perform a final check for mouse movement
		if AFK.CompareAngles( ply ) then
			points = AFK.StartPoints
		end
		
		-- Check if we have shown activity in this period
		if points < AFK.StartPoints then
			-- And skip past the check limitation if necessary
			pass = SysTime() - AFK.LastCheck[ ply ] >= AFK.CheckInterval
			
			-- Set when they were last reduced
			AFK.LastCheck[ ply ] = SysTime()
		end
		
		-- If this has been set to true we'll ignore the last check
		if not pass then
			-- Skip over if they've been recently checked
			if SysTime() - AFK.LastCheck[ ply ] < AFK.CheckInterval then continue end
		end
		
		-- If the player wasn't kicked, set when they were last lowered in points
		if not AFK.SubtractPoints( ply ) then
			AFK.LastCheck[ ply ] = SysTime()
		end
	end
end

--[[
	Description: Hook in important player activity
--]]
function AFK.OnPlayerEvent( ply )
	if AFK.Points[ ply ] < AFK.StartPoints then
		AFK.Points[ ply ] = AFK.StartPoints
	end
end

--[[
	Description: Sets some variables on player spawn
--]]
function AFK.OnPlayerCreated( ply )
	AFK.Points[ ply ] = AFK.StartPoints
	AFK.LastCheck[ ply ] = 0
end