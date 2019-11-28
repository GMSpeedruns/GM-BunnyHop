local PLAYER = FindMetaTable( "Player" )

local Spectator = {}
Spectator.PlayMode = Core.Config.Team.Players
Spectator.ViewMode = Core.Config.Team.Spectator

Spectator.Keys = {
	IN_ATTACK,
	IN_ATTACK2,
	IN_RELOAD
}

Spectator.Modes = {
	OBS_MODE_IN_EYE,
	OBS_MODE_CHASE,
	OBS_MODE_ROAMING
}

local KeyTrack = {}
local function GetKeyNumber( data )
	local out = 0
	
	if data[ IN_JUMP ] then out = out + 1 end
	if data[ IN_DUCK ] then out = out + 2 end
	if data[ IN_FORWARD ] then out = out + 4 end
	if data[ IN_BACK ] then out = out + 8 end
	if data[ IN_MOVELEFT ] then out = out + 16 end
	if data[ IN_MOVERIGHT ] then out = out + 32 end
	if data[ IN_ATTACK ] then out = out + 64 end
	
	return out
end

local function PlayerPressKey( ply, key )
	-- Of course only show when we're spectating
	if ply:Team() == Spectator.ViewMode then
		-- Set the default variables if they're not set yet
		if not ply.SpectateID then ply.SpectateID = 1 end
		if not ply.SpectateType then ply.SpectateType = 1 end
		
		-- Check which key we're pressing
		if key == Spectator.Keys[ 1 ] then
			local ar = Spectator.GetAlive()
			ply.SpectateType = 1
			ply.SpectateID = ply.SpectateID + 1
			
			Spectator.Mode( ply, true )
			Spectator.Change( ply, ar, true )
		elseif key == Spectator.Keys[ 2 ] then
			local ar = Spectator.GetAlive()
			ply.SpectateType = 1
			ply.SpectateID = ply.SpectateID - 1
			
			Spectator.Mode( ply, true )
			Spectator.Change( ply, ar, false )
		elseif key == Spectator.Keys[ 3 ] then
			local ar = Spectator.GetAlive()
			if #ar == 0 then
				ply.SpectateType = #Spectator.Modes
				Spectator.Mode( ply, true )
			else
				local bRespec = ply.SpectateType == #Spectator.Modes
				
				ply.SpectateType = ply.SpectateType + 1 > #Spectator.Modes and 1 or ply.SpectateType + 1
				Spectator.Mode( ply, nil, bRespec )
			end
		end
	elseif Spectator.Tracker then
		if not KeyTrack[ ply ] then
			KeyTrack[ ply ] = {}
		end
		
		KeyTrack[ ply ][ key ] = true
		
		local specs = Spectator.Get( ply, true, function( p ) return p.ShowKeys end )
		if #specs > 0 then
			local btn = GetKeyNumber( KeyTrack[ ply ] )
			net.Start( "KeyDataTransfer" )
			net.WriteInt( btn, 9 )
			net.Send( specs )
		end
	end
end
hook.Add( "KeyPress", "SpectatorPressKey", PlayerPressKey )

local function PlayerReleaseKey( ply, key )
	if not Spectator.Tracker then return end
	
	if ply:Team() == Spectator.PlayMode then
		if not KeyTrack[ ply ] then
			KeyTrack[ ply ] = {}
		end
		
		KeyTrack[ ply ][ key ] = nil
		
		local specs = Spectator.Get( ply, true, function( p ) return p.ShowKeys end )
		if #specs > 0 then
			local btn = GetKeyNumber( KeyTrack[ ply ] or {} )
			net.Start( "KeyDataTransfer" )
			net.WriteInt( btn, 9 )
			net.Send( specs )
		end
	end
end
hook.Add( "KeyRelease", "SpectatorReleaseKey", PlayerReleaseKey )

local function UnShowKeys( ply )
	-- Clear out the set variable
	ply.ShowKeys = nil
	
	-- Check if we need it to stay active
	local keep
	for _,p in pairs( player.GetHumans() ) do
		if p.ShowKeys and p:Team() == Spectator.ViewMode then
			keep = true
		end
	end
	
	Spectator.Tracker = keep
end
concommand.Add( "unshowkeys", UnShowKeys )

--[[
	Description: Enables the tracker and refreshes it
--]]
function Core.EnableKeyTrack()
	if not Spectator.Tracker then
		KeyTrack = {}
		Spectator.Tracker = true
	end
end

--[[
	Description: Gets all alive players on the main team
--]]
function Spectator.GetAlive()
	local d = {}
	
	for _,p in pairs( player.GetAll() ) do
		if p:Team() == Spectator.PlayMode and p:Alive() then
			d[ #d + 1 ] = p
		end
	end
	
	return d
end

--[[
	Description: Changes the active spectated entity to the next one
--]]
function Spectator.Change( ply, ar, forward )
	-- Gets the current target
	local previous = ply:GetObserverTarget()
	
	-- If we've only got one player, we're not going anywhere
	if #ar == 1 then
		ply.SpectateID = forward and ply.SpectateID - 1 or ply.SpectateID + 1
		return
	end

	-- If we've got no players at this slot, go back to the start/end
	if not ar[ ply.SpectateID ] then
		ply.SpectateID = forward and 1 or #ar
		
		-- If all spectators have left, un-spectate
		if not ar[ ply.SpectateID ] then
			return concommand.Run( ply, "spectate", "bypass", "" )
		end
	end

	-- Finally spectate the entity and update both players
	ply:SpectateEntity( ar[ ply.SpectateID ] )
	Spectator.Checks( ply, previous )
end

--[[
	Description: Changes the spectator mode of the target player
--]]
function Spectator.Mode( ply, cancel, respec )
	-- When we're going to free roam, remove this player from the previously spectated player
	if ply.SpectateType == #Spectator.Modes and not cancel then
		Spectator.End( ply, ply:GetObserverTarget() )
	end
	
	-- Change type and notify the player (for the top of the HUD)
	ply:Spectate( Spectator.Modes[ ply.SpectateType ] )
	
	-- Send the mode update
	local ar = Core.Prepare( "Spectate/Mode" )
	ar:UInt( ply.SpectateType, 4 )
	ar:Send( ply )
	
	-- Perform checks on the player if we're not in free roam
	if ply.SpectateType != #Spectator.Modes and respec then
		Spectator.Checks( ply )
	end
end

--[[
	Description: End the spectating session
--]]
function Spectator.End( ply, watching )
	-- Re-check all the players that have been spectating ply all along
	for _,p in pairs( player.GetHumans() ) do
		if not p.Spectating then continue end
		
		local ob = p:GetObserverTarget()
		if IsValid( ob ) and ob == ply then
			if not p.Incognito then
				local ar = Core.Prepare( "Spectate/Viewer" )
				ar:Bit( false )
				ar:String( p:Name() )
				ar:String( p.UID )
				ar:Send( ply )
			end
		end
	end
	
	-- Make sure incognitos are ignored
	if not IsValid( watching ) or ply.Incognito then return end
	
	-- Notify everyone that ply is gone
	Spectator.Notify( watching, ply, true )
	Spectator.NotifyWatchers( watching, ply )
end

--[[
	Description: Create a new spectating session on the player
--]]
function Spectator.New( ply )
	local ar = Spectator.GetAlive()
	if #ar == 0 then
		-- If we have no available players, instantly change to free roam
		ply.SpectateType = #Spectator.Modes
		Spectator.Mode( ply, true )
	else
		-- Otherwise, set them to the first person spectating mode
		ply.SpectateType = 1
		if not ar[ ply.SpectateID ] then ply.SpectateID = 1 end
		
		-- Make them spectate
		ply:Spectate( Spectator.Modes[ ply.SpectateType ] )
		ply:SpectateEntity( ar[ ply.SpectateID ] )
		
		-- Update mode
		local ar = Core.Prepare( "Spectate/Mode" )
		ar:UInt( ply.SpectateType, 4 )
		ar:Send( ply )
		
		-- And update the spectated player
		Spectator.Checks( ply )
	end
end

--[[
	Description: Create a new spectating session and force them directly to the specified player
--]]
function Spectator.NewById( ply, szSteam, bSwitch, szName )
	local ar = Spectator.GetAlive()
	local target = { ID = nil, Ent = nil }
	local bBot = szSteam == "NULL"
	
	-- Loop over the players
	for id,p in pairs( ar ) do
		if (bBot and p:IsBot() and szName and p:Name() == szName) or (tostring( p.UID ) == tostring( szSteam )) then
			target.Ent = p
			target.ID = id
			break
		end
	end
	
	-- When we have a valid player, make them spectate it
	if target.Ent then
		local previous = bSwitch and ply:GetObserverTarget() or nil
		
		ply.SpectateType = 1
		ply.SpectateID = target.ID
		
		ply:Spectate( Spectator.Modes[ ply.SpectateType ] )
		ply:SpectateEntity( target.Ent )
		
		local ar = Core.Prepare( "Spectate/Mode" )
		ar:UInt( ply.SpectateType, 4 )
		ar:Send( ply )
		
		Spectator.Checks( ply, previous )
	else
		Core.Print( ply, "General", Core.Text( "SpectateTargetInvalid" ) )
	end
end

--[[
	Description: Performs checks for when a change in spectators happens
--]]
function Spectator.Checks( ply, previous )
	-- If the player that starts spectating is incognito, refresh the list of the target only
	if ply.Incognito then
		local target = ply:GetObserverTarget()
		if IsValid( target ) then
			return Spectator.NotifyWatchers( target )
		else
			return false
		end
	end

	-- See if we have any player as our target
	local current = ply:GetObserverTarget()
	if IsValid( current ) then
		-- Depending on the type, notify
		if current:IsBot() then
			Spectator.NotifyBot( current )
		else
			Spectator.Notify( current, ply )
		end
	end

	-- When we're cycling through players, let the previous one know we're off to the next
	if IsValid( previous ) then
		Spectator.Notify( previous, ply, true )
	end
end

--[[
	Description: Notify the spectated player that they're being spectated, or abandoned
--]]
function Spectator.Notify( target, ply, bLeave )
	-- Notify the target
	if bLeave then
		Spectator.NotifyWatchers( target )
		
		local ar = Core.Prepare( "Spectate/Viewer" )
		ar:Bit( true )
		ar:String( ply:Name() )
		ar:String( ply.UID )
		ar:Send( target )
		
		return false
	else
		local ar = Core.Prepare( "Spectate/Viewer" )
		ar:Bit( false )
		ar:String( ply:Name() )
		ar:String( ply.UID )
		ar:Send( target )
	end
	
	-- Notify all the watchers about the new viewer
	Spectator.NotifyWatchers( target )
end

--[[
	Description: The notify function used for bots
	Notes: The rest of the functionality is in the NotifyWatchers function
--]]
function Spectator.NotifyBot( bot )
	Core.Ext( "Bot", "NotifyRestart" )( bot.Style )
	Spectator.NotifyWatchers( bot )
end

--[[
	Description: Notifies watchers about a restart or timer reset
--]]
function Spectator.PlayerRestart( ply, nFixed )
	local viewers = ply:Spectator( "Get", { true } )
	if #viewers == 0 then return end
	
	if nFixed then
		local ar = Core.Prepare( "Timer/ForceTime" )
		ar:Bit( true )
		ar:Double( nFixed )
		ar:Send( viewers )
	else
		local nTimer = ply.TimerBonus or ply.TimerNormal
		
		if nTimer then
			nTimer = SysTime() - nTimer
		end
		
		Core.Prepare( "Spectate/Timer", { false, nTimer, (ply.Record and ply.Record > 0) and ply.Record or nil, true } ):Send( viewers )
	end
end

--[[
	Description: Notifies watchers about a new member of the gang and sends them an updated timer
--]]
function Spectator.NotifyWatchers( ply, ending )
	local SpectatorList, Watchers, Incognitos = {}, {}, {}
	for _,p in pairs( player.GetHumans() ) do
		if not p.Spectating then continue end
		if IsValid( ending ) and p == ending then continue end
		
		local ob = p:GetObserverTarget()
		if IsValid( ob ) and ob == ply then
			if p.Incognito then
				Incognitos[ #Incognitos + 1 ] = p
			else
				Watchers[ #Watchers + 1 ] = p
				SpectatorList[ #SpectatorList + 1 ] = p:Name()
			end
		end
	end
	
	if #SpectatorList == 0 then
		SpectatorList = nil
	end
	
	if #Watchers + #Incognitos == 0 then
		return
	end

	local nTimer = ply.TimerBonus or ply.TimerNormal
	if nTimer then
		nTimer = SysTime() - nTimer
	end
	
	local data
	if ply:IsBot() then
		data = Core.Ext( "Bot", "GenerateNotify" )( ply, ply.Style, SpectatorList )
		if not data then return end
	else
		data = { false, nTimer, (ply.Record and ply.Record > 0) and ply.Record or nil, SpectatorList }
	end
	
	if #Watchers > 0 then
		Core.Prepare( "Spectate/Timer", data ):Send( Watchers )
	end
	
	if #Incognitos > 0 then
		Core.Prepare( "Spectate/Timer", data ):Send( Incognitos )
	end
end

--[[
	Description: Gets a list of spectators on the player
--]]
function Spectator.Get( ply, all, test )
	local Watchers, Incognitos = {}, {}
	for _,p in pairs( player.GetHumans() ) do
		if not p.Spectating then continue end
		
		local ob = p:GetObserverTarget()
		if IsValid( ob ) and ob == ply then
			if test and not test( p ) then continue end
			if p.SpectateType == #Spectator.Modes then continue end
			
			if p.Incognito then
				if all then
					Watchers[ #Watchers + 1 ] = p
				end
				
				Incognitos[ #Incognitos + 1 ] = p
			else
				Watchers[ #Watchers + 1 ] = p
			end
		end
	end
	
	return Watchers, Incognitos
end

--[[
	Description: Allows the player to access the functions in this module
	Notes: Allows access from each player, elimating useless globals
--]]
function PLAYER:Spectator( szType, args )
	if Spectator[ szType ] then
		args = args or {}
		table.insert( args, 1, self )
		
		return Spectator[ szType ]( unpack( args ) )
	end
end