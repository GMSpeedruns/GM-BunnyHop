-- Define config variables
Core.Config.Var.Add( "TASMaxPlayers", "tas_max_players", 5, "The maximum amount of players allowed in TAS mode simultaneously" )

-- And create the TAS table
local TAS = {}
TAS.ReverseTrack = {}
TAS.ForwardTrack = {}
TAS.Limiter = {}
TAS.FinishFrame = {}
TAS.Players = {}
TAS.Times = {}
TAS.TimeInvalidate = {}
TAS.Cooldown = {}
TAS.BaseStyle = 50
TAS.Maximum = Core.Config.Var.GetInt( "TASMaxPlayers" )
TAS.SelectLimit = Core.Config.Var.GetInt( "TopLimit" )

-- Player recording helpers
local Active, Frame, Paused = {}, {}, {}
local ActiveReverse, ActiveForward = {}, {}
local ActiveMove, ActiveTime, ActiveRestore = {}, {}, {}

-- Player recording tables
local OriginX, OriginY, OriginZ = {}, {}, {}
local AngleP, AngleY = {}, {}
local VelocityX, VelocityY, VelocityZ = {}, {}, {}
local Buttons, TimeValue = {}, {}, {}

-- Access functions
local ST, FT = SysTime, FrameTime
local CreateVec, CreateAngle = Vector, Angle
local Prepare = SQLPrepare
local Styles = Core.Config.Style

--[[
	Description: Initializes the TAS system
--]]
function TAS.Init()
	-- Enable the styles
	for name,id in pairs( Styles ) do
		Core.SetStyle( TAS.BaseStyle + id, name .. " TAS" )
	end
	
	-- Show that we loaded
	Core.Config.Var.Activate( "TAS", TAS )
	Core.PrintC( "[Startup] Extension 'tas' activated" )
end
Core.PostInitFunc = TAS.Init


--[[
	Description: Loads the player time
--]]
function TAS.GetPlayerTime( szUID, nStyle, callback )
	Prepare(
		"SELECT nTime FROM game_tas WHERE szMap = {0} AND szUID = {1} AND nStyle = {2}",
		{ game.GetMap(), szUID, nStyle }
	)( function( data, varArg )
		callback( Core.Assert( data, "nTime" ) and data[ 1 ]["nTime"] or 0 )
	end )
end

--[[
	Description: Gets the top time on a style
--]]
function TAS.GetInfoTimes( szUID, nStyle, callback )
	Prepare(
		"SELECT nTime FROM game_tas WHERE szMap = {0} AND szUID = {1} AND nStyle = {2}",
		{ game.GetMap(), szUID, nStyle },
		
		"SELECT nTime FROM game_tas WHERE szMap = {0} AND nStyle = {1} ORDER BY nTime ASC LIMIT 1",
		{ game.GetMap(), nStyle }
	)( function( data, varArg )
		data = data or {}
		
		local q1, q2 = data[ 1 ], data[ 2 ]
		if q1 and q2 then
			callback( Core.Assert( q1, "nTime" ) and q1[ 1 ]["nTime"] or 0, Core.Assert( q2, "nTime" ) and q2[ 1 ]["nTime"] )
		else
			callback( 0 )
		end
	end )
end

--[[
	Description: Sets the time in the database
--]]
function TAS.SetPlayerTime( szUID, szName, nStyle, nTime, nReal, nPB )
	if nPB == 0 then
		Prepare(
			"INSERT INTO game_tas (szUID, szMap, nStyle, nTime, nReal, nDate) VALUES ({0}, {1}, {2}, {3}, {4}, {5})",
			{ szUID, game.GetMap(), nStyle, nTime, nReal, os.time() }
		)( SQLVoid )
	else
		Prepare(
			"UPDATE game_tas SET nTime = {0}, nReal = {1}, nDate = {2} WHERE szMap = {3} AND szUID = {4} AND nStyle = {5}",
			{ nTime, nReal, os.time(), game.GetMap(), szUID, nStyle }
		)( SQLVoid )
	end
end

--[[
	Description: Deletes items from the TAS table
--]]
function TAS.RemoveTimes( ply, nStyle, tab )
	if #tab == 0 then return end
	
	local strs = {}
	for i = 1, #tab do
		strs[ #strs + 1 ] = "szUID = '" .. tab[ i ] .. "'"
	end
	
	Prepare(
		"DELETE FROM game_tas WHERE szMap = {0} AND nStyle = {1} AND (" .. string.Implode( " OR ", strs ) .. ")",
		{ game.GetMap(), nStyle }
	)( SQLVoid )
	
	TAS.TimeInvalidate[ nStyle ] = true
	
	Core.Print( ply, "Admin", Core.Text( "AdminTimeRemoval", #tab ) )
	Core.AddAdminLog( "Removed " .. #tab .. " " .. Core.StyleName( nStyle ) .. " TAS times on " .. game.GetMap(), ply.UID, ply:Name() )
end


--[[
	Description: Loads their previous TAS record
--]]
function TAS.LoadTime( ply, nStyle, nRecord )
	local function ProceedLoading( p, s, r, b )
		-- Set variables
		p.Record = r
		p.Leaderboard = 0
		
		p:VarNet( "Set", "Record", p.Record )
		p:VarNet( "Set", "Position", p.Leaderboard )
		
		-- Send the data for fast GUI drawing
		local ar = Core.Prepare( "Timer/Record" )
		ar:Double( p.Record )
		
		ar:Bit( true )
		ar:UInt( s, 8 )
		ar:UInt( self.Bonus and self.Bonus + 1 or 0, 4 )
		ar:Bit( false )
		
		ar:Send( p )
		
		-- Remove any medals
		local send = { "Record", "Position" }
		if p.SpecialRank and p.SpecialRank != 0 then
			p.SpecialRank = 0
			p:VarNet( "Set", "SpecialRank", p.SpecialRank )
			
			send[ #send + 1 ] = "SpecialRank"
		end
		
		-- Send variables
		if not b then
			p:VarNet( "UpdateKeys", send )
		end
	end
	
	-- Get the player record
	if nRecord then
		ProceedLoading( ply, nStyle, nRecord )
	else
		TAS.GetPlayerTime( ply.UID, nStyle, function( nTime )
			ProceedLoading( ply, nStyle, nTime )
		end )
	end
end

--[[
	Description: Loads the player rank
--]]
function TAS.LoadRank( ply, bNoReload )
	-- Clear out points
	ply.CurrentPointSum = 0
	ply.CurrentMapSum = 0

	-- Set the rank to TAS
	ply.Rank = -20
	ply:VarNet( "Set", "Rank", ply.Rank )
	
	-- Remove any sub-rank
	ply.SubRank = 0
	ply:VarNet( "Set", "SubRank", ply.SubRank )
	
	-- Send the variables
	if not bNoReload then
		ply:VarNet( "UpdateKeys", { "Rank", "SubRank" } )
	else
		return true
	end
end



--[[
	Description: Process a received command
--]]
function TAS.ReceiveCommand( ply, varArgs )
	if not ply.TAS then return end
	
	local id = varArgs[ 1 ]
	local at = id + 1
	
	-- Close request
	if id == 0 then
		-- Check if we're in spawn
		if not ply:InSpawn() then
			return Core.Print( ply, "Timer", Core.Text( "TASDisableMidrun" ) )
		end
		
		-- First reset the basic variables
		ply.Ta = nil
		ply.TaF = nil
		ply.TAS = nil
		
		-- Send the message
		Core.Print( ply, "Timer", Core.Text( "TASDisabled" ) )
		
		-- And reset the player
		ply:ResetSpawnPosition()
		ply:LoadStyle( ply.Style )
		
		-- Disable +binds again
		Core.Send( ply, "Timer/BypassBind" )
		
		TAS.Players[ ply ] = nil
		TAS.SetRecording( ply )
		TAS.EnsureHook()
		
	-- Pause / Resume
	elseif id == 1 then
		if not Frame[ ply ] or Frame[ ply ] <= 1 then
			return Core.Print( ply, "Timer", Core.Text( "TASCommandPause" ) )
		elseif ActiveReverse[ ply ] or ActiveForward[ ply ] then
			return Core.Print( ply, "Timer", Core.Text( "TASCommandPauseMoving" ) )
		end
		
		local add
		if not Paused[ ply ] then
			Paused[ ply ] = true
			ActiveMove[ ply ] = ply:GetMoveType()
			add = Buttons[ ply ][ Frame[ ply ] - 1 ]
			
			ply:SetMoveType( MOVETYPE_NONE )
			ply:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
		else
			TAS.WipeRange( ply, Frame[ ply ], #OriginX[ ply ] )
			
			ply:SetMoveType( ActiveMove[ ply ] or MOVETYPE_WALK )
			ply:SetCollisionGroup( COLLISION_GROUP_PLAYER )
			
			ActiveMove[ ply ] = nil
			Paused[ ply ] = nil
			
			if ply.Style == Styles.Unreal and TAS.Cooldown[ ply ] and ActiveTime[ ply ] then
				if ActiveTime[ ply ] < TAS.Cooldown[ ply ] then
					local ar = Core.Prepare( "Timer/UnrealReset" )
					ar:UInt( TAS.Cooldown[ ply ] - ActiveTime[ ply ], 6 )
					ar:Send( ply )
				end
			end
		end
		
		Core.Send( ply, "GUI/UpdateTAS", { id, not Paused[ ply ], add } )
	
	-- Fast Reverse
	elseif id == 2 then
		local cmd = varArgs[ at ] and "+fastreverse" or "-fastreverse"
		TAS.ReverseConcommand( ply, cmd )
		
	-- Fast Forward
	elseif id == 3 then
		local cmd = varArgs[ at ] and "+fastforward" or "-fastforward"
		TAS.ForwardConcommand( ply, cmd )
		
	-- Strafehacks
	elseif id == 4 then
		Core.Send( ply, "GUI/UpdateTAS", { id, not varArgs[ at ] } )
		
	-- Set restore frame
	elseif id == 5 then
		if not Frame[ ply ] then
			Core.Print( ply, "Timer", Core.Text( "TASRestoreNotStarted" ) )
		else
			ActiveRestore[ ply ] = Frame[ ply ] - 1
			Core.Print( ply, "Timer", Core.Text( "TASRestoreSet" ) )
		end
		
	-- Continue at frame
	elseif id == 6 then
		if not Frame[ ply ] or not ActiveRestore[ ply ] then
			Core.Print( ply, "Timer", Core.Text( "TASContinueNotSet" ) )
		else
			local frame = ActiveRestore[ ply ]
			if frame >= 1 and frame <= #OriginX[ ply ] then
				if Paused[ ply ] then
					if ActiveReverse[ ply ] or ActiveForward[ ply ] then
						return Core.Print( ply, "Timer", Core.Text( "TASContinueMoving" ) )
					end
					
					ActiveTime[ ply ] = TimeValue[ ply ][ frame ]
					Frame[ ply ] = frame + 1
				else
					Core.Print( ply, "Timer", Core.Text( "TASContinuePause" ) )
				end
			else
				Core.Print( ply, "Timer", Core.Text( "TASContinueRange" ) )
			end
		end
		
	-- Exit mode
	elseif id == 7 then
		-- Check if we're in spawn
		if not ply:InSpawn() then
			return Core.Print( ply, "Timer", Core.Text( "TASDisableMidrun" ) )
		end
		
		Core.Send( ply, "GUI/UpdateTAS", { 0 } )
	end
end
Core.Register( "Global/TAS", TAS.ReceiveCommand )

--[[
	Description: A bindable console command for the pausing
--]]
function TAS.ToggleConcommand( ply, szCmd, varArgs, nForce )
	if not ply.TAS then return end
	if TAS.Limiter[ ply ] and ST() - TAS.Limiter[ ply ] < 0.25 then return end
	
	TAS.Limiter[ ply ] = ST()
	TAS.ReceiveCommand( ply, { szCmd == "Override" and nForce or 1 } )
end
concommand.Add( "tastoggle", TAS.ToggleConcommand )

--[[
	Description: A bindable console command for the rewinding
--]]
function TAS.ReverseConcommand( ply, szCmd, varArgs )
	if not ply.TAS then return end
	if string.lower( szCmd ) == "fastreverse" then
		if TAS.Limiter[ ply ] and ST() - TAS.Limiter[ ply ] < 1 then return end
		TAS.Limiter[ ply ] = ST()
		
		return Core.Print( ply, "Timer", Core.Text( "TASConcommandHelp", "fastreverse" ) )
	end
	
	if not Paused[ ply ] then
		if TAS.Limiter[ ply ] and ST() - TAS.Limiter[ ply ] < 0.25 then return end
		TAS.Limiter[ ply ] = ST()
		
		return Core.Print( ply, "Timer", Core.Text( "TASConcommandPause", "fastreverse" ) )
	elseif ActiveForward[ ply ] then
		return Core.Print( ply, "Timer", Core.Text( "TASConcommandNavigate" ) )
	end
	
	if szCmd[ 1 ] == "+" then
		if TAS.Limiter[ ply ] and ST() - TAS.Limiter[ ply ] < 0.25 then return end
		TAS.Limiter[ ply ] = ST()
		TAS.ReverseTrack[ ply ] = true
		ActiveReverse[ ply ] = true
		
		Core.Send( ply, "GUI/UpdateTAS", { 2, false } )
	elseif szCmd[ 1 ] == "-" then
		if not TAS.ReverseTrack[ ply ] then return end
		TAS.ReverseTrack[ ply ] = nil
		ActiveReverse[ ply ] = nil
		
		Core.Send( ply, "GUI/UpdateTAS", { 2, true, true, Buttons[ ply ][ Frame[ ply ] ] } )
	end
	
	return true
end
concommand.Add( "fastreverse", TAS.ReverseConcommand )
concommand.Add( "+fastreverse", TAS.ReverseConcommand )
concommand.Add( "-fastreverse", TAS.ReverseConcommand )

--[[
	Description: A bindable console command for the rewinding
--]]
function TAS.ForwardConcommand( ply, szCmd, varArgs )
	if not ply.TAS then return end
	if string.lower( szCmd ) == "fastforward" then
		if TAS.Limiter[ ply ] and ST() - TAS.Limiter[ ply ] < 1 then return end
		TAS.Limiter[ ply ] = ST()
		
		return Core.Print( ply, "Timer", Core.Text( "TASConcommandHelp", "fastforward" ) )
	end
	
	if not Paused[ ply ] then
		if TAS.Limiter[ ply ] and ST() - TAS.Limiter[ ply ] < 0.25 then return end
		TAS.Limiter[ ply ] = ST()
		
		return Core.Print( ply, "Timer", Core.Text( "TASConcommandPause", "fastforward" ) )
	elseif ActiveReverse[ ply ] then
		return Core.Print( ply, "Timer", Core.Text( "TASConcommandNavigate" ) )
	end
	
	if szCmd[ 1 ] == "+" then
		if TAS.Limiter[ ply ] and ST() - TAS.Limiter[ ply ] < 0.25 then return end
		TAS.Limiter[ ply ] = ST()
		TAS.ForwardTrack[ ply ] = true
		ActiveForward[ ply ] = true
		
		Core.Send( ply, "GUI/UpdateTAS", { 3, false } )
	elseif szCmd[ 1 ] == "-" then
		if not TAS.ForwardTrack[ ply ] then return end
		TAS.ForwardTrack[ ply ] = nil
		ActiveForward[ ply ] = nil
		
		Core.Send( ply, "GUI/UpdateTAS", { 3, true, true, Buttons[ ply ][ Frame[ ply ] ] } )
	end
	
	return true
end
concommand.Add( "fastforward", TAS.ForwardConcommand )
concommand.Add( "+fastforward", TAS.ForwardConcommand )
concommand.Add( "-fastforward", TAS.ForwardConcommand )


--[[
	Description: Validates the timer
--]]
function TAS.ValidTimer( ply, ent, bonus )
	if not IsValid( ply ) or not ply.Style then return false end
	if ply.Practice or not ply.TAS then return false end
	
	local isb = ply.Bonus
	if not bonus and isb then
		return false
	elseif bonus and not isb then
		return false
	end
	
	if type( ent ) == "Entity" and IsValid( ent ) then
		if string.find( "Bonus", Core.GetZoneName( ent.zonetype ), 1, true ) and not isb then
			return false
		elseif string.find( "Normal", Core.GetZoneName( ent.zonetype ), 1, true ) and isb then
			return false
		end
	end
	
	return true
end

--[[
	Description: Attempts to start a TAS run
--]]
function TAS.StartTimer( ply, ent, bonus )
	if not TAS.ValidTimer( ply, ent, bonus ) then return end
	
	-- Make sure that if we already have a timer, we don't reset
	if ply.Ta or Paused[ ply ] then return end
	
	local vel2d = ply:GetVelocity():Length2D()
	if vel2d > Core.Config.Player.StartSpeed then
		ply:ResetSpawnPosition()
		return Core.PlayerNotification( ply, "Popup", { "Timer", Core.Text( "ZoneSpeed", math.ceil( vel2d ) .. " u/s" ), "lightning", 4 } )
	elseif Core.Config.IsBhop and vel2d > 0 and ply:GetVelocity().z < 0 then
		ply:ResetSpawnPosition()
		return Core.PlayerNotification( ply, "Popup", { "Timer", Core.Text( "ZoneJumpExit" ), "error", 4 } )
	end
	
	TAS.SetRecording( ply, true )
	ActiveTime[ ply ] = 0
	
	ply.Ta = ST()
	
	local ar = Core.Prepare( "Timer/Start" )
	ar:UInt( 0, 2 )
	ar:Send( ply )
	
	if ply.Style == Styles.Unreal then
		local boost = Core.GetMapVariable( "UnrealBoost" )
		if boost[ ply ] and ST() < boost[ ply ] then
			boost[ ply ] = nil
			
			local ar = Core.Prepare( "Timer/UnrealReset" )
			ar:UInt( 0, 6 )
			ar:Send( ply )
		end
		
		TAS.Cooldown[ ply ] = nil
	end
end

--[[
	Description: Resets a TAS run
--]]
function TAS.ResetTimer( ply, ent, bonus )
	if not TAS.ValidTimer( ply, ent, bonus ) then return end
	
	TAS.SetRecording( ply, nil )
	ActiveTime[ ply ] = 0
	
	ply.Ta = nil
	ply.TaF = nil

	local ar = Core.Prepare( "Timer/Start" )
	ar:UInt( 0, 2 )
	ar:Send( ply )
end

--[[
	Description: Stops the timer and ends the run
--]]
function TAS.StopTimer( ply, ent, bonus )
	if not TAS.ValidTimer( ply, ent, bonus ) then return end
	if not ply.Ta then return end
	
	ply.TaF = ST()
	
	TAS.EndTimer( ply, ply.TaF - ply.Ta )
end

--[[
	Description: Ends a player run
--]]
function TAS.EndTimer( ply, nReal )
	-- Security checks
	if not IsValid( ply ) then return end
	if not Frame[ ply ] or not OriginX[ ply ] then return end
	if Frame[ ply ] < 2 or #OriginX[ ply ] < 2 then return end
	if not ply.Ta or not ply.TaF or not ActiveTime[ ply ] then return end
	
	-- Set some default variables
	local nTime = ActiveTime[ ply ] or 0
	local nStyle = ply.Style
	
	-- Check for invalid values
	if nTime == 0 then return end
	
	-- Get the important times
	TAS.GetInfoTimes( ply.UID, nStyle, function( nPB, nTop )
		-- If slower, don't do anything
		if nPB != 0 and nTime >= nPB then
			return Core.Print( ply, "Timer", Core.Text( "TASTimerSlow", Core.StyleName( nStyle ), Core.ConvertTime( nTime ), Core.ConvertTime( nPB ), Core.ConvertTime( nTime - nPB ) ) )
		end
		
		-- Update their time
		TAS.LoadTime( ply, nStyle, nTime )
		TAS.SetPlayerTime( ply.UID, ply:Name(), nStyle, nTime, nReal, nPB )
		TAS.TimeInvalidate[ nStyle ] = true
		
		-- Message them
		Core.Print( ply, "Timer", Core.Text( "TASTimerPB", Core.StyleName( nStyle ), Core.ConvertTime( nTime ), nPB != 0 and " (-" .. Core.ConvertTime( nPB - nTime ) .. ")" or "" ) )
		
		-- Compare times
		if nTop and nTime >= nTop then
			return Core.Print( ply, "Timer", Core.Text( "TASTimerSlowTop", Core.ConvertTime( nTime - nTop ) ) )
		end
		
		-- And send a WR message
		Core.PlayerNotification( ply, "TAS", { Time = nTime, Style = nStyle } )
		
		-- Set new data containers
		local ox, oy, oz = {}, {}, {}
		local ap, ay = {}, {}
		local bt = {}
		
		-- Iterate over the table and copy each frame
		local frames = #OriginX[ ply ]
		for i = 1, frames do
			ox[ i ] = OriginX[ ply ][ i ]
			oy[ i ] = OriginY[ ply ][ i ]
			oz[ i ] = OriginZ[ ply ][ i ]
			ap[ i ] = AngleP[ ply ][ i ]
			ay[ i ] = AngleY[ ply ][ i ]
			bt[ i ] = Buttons[ ply ][ i ]
		end
		
		-- Hand it over to the bot module
		Core.Ext( "Bot", "HandleSpecial" )( ply, "TAS", nTime, { ox, oy, oz, ap, ay, bt } )
	end )
end

--[[
	Description: Returns the players time
--]]
function TAS.GetTimer( ply )
	return ActiveTime[ ply ]
end

--[[
	Description: Checks if the player is paused
--]]
function TAS.IsPaused( ply )
	return Paused[ ply ]
end

--[[
	Description: Validates an Unreal boost in TAS
--]]
function TAS.UnrealBoost( ply, nCool )
	if not ActiveTime[ ply ] then return true end
	if Paused[ ply ] then
		if TAS.Cooldown[ ply ] then
			local ar = Core.Prepare( "Timer/UnrealReset" )
			ar:UInt( TAS.Cooldown[ ply ] - ActiveTime[ ply ], 6 )
			ar:Send( ply )
		end
		
		return true
	end
	
	if nCool then
		TAS.Cooldown[ ply ] = ActiveTime[ ply ] + nCool
	elseif TAS.Cooldown[ ply ] then
		if ActiveTime[ ply ] < TAS.Cooldown[ ply ] then
			local ar = Core.Prepare( "Timer/UnrealReset" )
			ar:UInt( TAS.Cooldown[ ply ] - ActiveTime[ ply ], 6 )
			ar:Send( ply )
			
			return true
		end
	end
end

--[[
	Description: Wipes a given range on the player
--]]
function TAS.WipeRange( ply, start, stop )
	for i = start, stop do
		OriginX[ ply ][ i ] = nil
		OriginY[ ply ][ i ] = nil
		OriginZ[ ply ][ i ] = nil
		AngleP[ ply ][ i ] = nil
		AngleY[ ply ][ i ] = nil
		VelocityX[ ply ][ i ] = nil
		VelocityY[ ply ][ i ] = nil
		VelocityZ[ ply ][ i ] = nil
		Buttons[ ply ][ i ] = nil
		TimeValue[ ply ][ i ] = nil
	end
end

--[[
	Description: Sets recording data for the player
--]]
function TAS.SetRecording( ply, bool )
	if bool and not OriginX[ ply ] then
		OriginX[ ply ], OriginY[ ply ], OriginZ[ ply ] = {}, {}, {}
		AngleP[ ply ], AngleY[ ply ] = {}, {}
		VelocityX[ ply ], VelocityY[ ply ], VelocityZ[ ply ] = {}, {}, {}
		Buttons[ ply ], TimeValue[ ply ] = {}, {}
	end
	
	-- Reset cooldowns
	if TAS.Cooldown[ ply ] then
		TAS.Cooldown[ ply ] = nil
		
		local ar = Core.Prepare( "Timer/UnrealReset" )
		ar:UInt( 0, 6 )
		ar:Send( ply )
	end
	
	-- Clear out ALL data
	OriginX[ ply ] = {}
	OriginY[ ply ] = {}
	OriginZ[ ply ] = {}
	AngleP[ ply ] = {}
	AngleY[ ply ] = {}
	VelocityX[ ply ] = {}
	VelocityY[ ply ] = {}
	VelocityZ[ ply ] = {}
	Buttons[ ply ] = {}
	TimeValue[ ply ] = {}
	
	-- And reset to frame one
	Frame[ ply ] = 1
	
	-- And set whether we're active or not
	Active[ ply ] = bool
end


--[[
	Description: Record TAS run
--]]
local function TASRecord( ply, data )
	if Active[ ply ] then
		if Paused[ ply ] then
			local frame = 1
			if ActiveReverse[ ply ] then
				Frame[ ply ] = Frame[ ply ] - 1
				if Frame[ ply ] <= 1 then
					Frame[ ply ] = #OriginX[ ply ]
				end
				
				frame = Frame[ ply ]
				ActiveTime[ ply ] = TimeValue[ ply ][ frame ]
			elseif ActiveForward[ ply ] then
				Frame[ ply ] = Frame[ ply ] + 1
				if Frame[ ply ] >= #OriginX[ ply ] then
					Frame[ ply ] = 1
				end
				
				frame = Frame[ ply ]
				ActiveTime[ ply ] = TimeValue[ ply ][ frame ]
			else
				frame = Frame[ ply ] - 1
			end
			
			ply:SetEyeAngles( CreateAngle( AngleP[ ply ][ frame ], AngleY[ ply ][ frame ], 0 ) )
			data:SetOrigin( CreateVec( OriginX[ ply ][ frame ], OriginY[ ply ][ frame ], OriginZ[ ply ][ frame ] ) )
			data:SetVelocity( CreateVec( VelocityX[ ply ][ frame ], VelocityY[ ply ][ frame ], VelocityZ[ ply ][ frame ] ) )
		else
			local eyes = data:GetAngles()
			local origin = data:GetOrigin()
			local vel = data:GetVelocity()
			
			local frame = Frame[ ply ]
			OriginX[ ply ][ frame ] = origin.x
			OriginY[ ply ][ frame ] = origin.y
			OriginZ[ ply ][ frame ] = origin.z
			AngleP[ ply ][ frame ] = eyes.p
			AngleY[ ply ][ frame ] = eyes.y
			VelocityX[ ply ][ frame ] = vel.x
			VelocityY[ ply ][ frame ] = vel.y
			VelocityZ[ ply ][ frame ] = vel.z
			Buttons[ ply ][ frame ] = data:GetButtons()
			
			ActiveTime[ ply ] = ActiveTime[ ply ] + FT()
			TimeValue[ ply ][ frame ] = ActiveTime[ ply ]
			Frame[ ply ] = frame + 1
		end
	end
end

--[[
	Description: Makes sure the hook is enabled
--]]
function TAS.EnsureHook( bNeed )
	if bNeed then
		if not TAS.Hooked then
			TAS.Hooked = true
			hook.Add( "SetupMove", "TASRecord", TASRecord )
		end
	else
		local bFree = true
		for _,p in pairs( player.GetHumans() ) do
			if p.TAS then
				bFree = false
				break
			end
		end
		
		if TAS.Hooked and bFree then
			TAS.Hooked = nil
			hook.Remove( "SetupMove", "TASRecord" )
		end
	end
end

--[[
	Description: Sends players their timer
--]]
function TAS.Tick()
	for ply,bool in pairs( TAS.Players ) do
		if not IsValid( ply ) or not bool then continue end
		if not ply:Alive() or not ply.TAS then continue end
		
		local t = ActiveTime[ ply ] or 0
		if t != 0 and not Paused[ ply ] then
			if TAS.Times[ ply.Style ] and #TAS.Times[ ply.Style ] > 0 then
				if t > (TAS.Times[ ply.Style ][ 1 ].nTime or 1e10) * 1.25 then
					TAS.SetRecording( ply )
					ActiveTime[ ply ] = 0
					
					return Core.Print( ply, "Timer", Core.Text( "TASTimerSurpass" ) )
				end
			end
			
			t = t + math.random( 100, 500 ) / 1000
		end
		
		local ar = Core.Prepare( "Timer/ForceTime" )
		ar:Bit( false )
		ar:Double( t )
		ar:Send( ply )
		
		local viewers = ply:Spectator( "Get", { true } )
		if #viewers > 0 then
			ar = Core.Prepare( "Timer/ForceTime" )
			ar:Bit( true )
			ar:Double( t )
			ar:Send( viewers )
		end
	end
end
timer.Create( "TASTick", 1, 0, TAS.Tick )


--[[
	Description: Easy access TAS commands
--]]
Core.AddCmd( { "taspause", "tasresume", "tastoggle" }, function( ply ) TAS.ToggleConcommand( ply ) end )
Core.AddCmd( { "tasstrafe", "tassh", "tasstrafehack" }, function( ply ) Core.Send( ply, "GUI/UpdateTAS", { 10 } ) end )
Core.AddCmd( { "tasrestore", "tasfixedframe", "tasfixedrestore", "tasset" }, function( ply ) TAS.ToggleConcommand( ply, "Override", nil, 5 ) end )
Core.AddCmd( { "tascontinue", "tasfixedresume", "tasfixedcontinue", "tasgo" }, function( ply ) TAS.ToggleConcommand( ply, "Override", nil, 6 ) end )
Core.AddCmd( { "tasexit", "tasleave", "tasclose", "tasbye" }, function( ply ) TAS.ToggleConcommand( ply, "Override", nil, 7 ) end )

--[[
	Description: Opens the TAS WRs
--]]
function TAS.RecordsCommand( ply, args )
	local nStyle = Styles.Normal
	if #args > 0 then
		local lookup = Core.ContentText( "StyleLookup" )
		local found = lookup[ args[ 1 ] ]
		
		if not found then
			local szStyle = string.Implode( " ", args.Upper )
			local nFound = Core.GetStyleID( szStyle )
			
			if not Core.IsValidStyle( nFound ) then
				return Core.Print( ply, "General", Core.Text( "MiscInvalidStyle" ) )
			else
				nStyle = nFound
			end
		else
			nStyle = found
		end
	end
	
	if not Core.IsValidStyle( nStyle ) then
		return Core.Print( ply, "General", Core.Text( "MiscInvalidStyle" ) )
	end
	
	local function OpenRecords( p, s )
		if TAS.Times[ s ] and #TAS.Times[ s ] > 0 then
			Core.Prepare( "GUI/Build", {
				ID = "Top",
				Title = "TAS Records (" .. Core.StyleName( s ) .. ")",
				X = 400,
				Y = 370,
				Mouse = true,
				Blur = true,
				Data = { TAS.Times[ s ] or {}, IsEdit = p.RemovingTimes, Style = s, ViewType = 4 }
			} ):Send( p )
		else
			Core.Print( p, "Timer", Core.Text( "TASCommandWRNone", Core.StyleName( s ) ) )
		end
	end
	
	if not TAS.Times[ nStyle ] or TAS.TimeInvalidate[ nStyle ] then
		TAS.TimeInvalidate[ nStyle ] = nil
		TAS.Times[ nStyle ] = {}
		
		Prepare(
			"SELECT * FROM game_tas WHERE szMap = {0} AND nStyle = {1} ORDER BY nTime ASC LIMIT {2}",
			{ game.GetMap(), nStyle, TAS.SelectLimit }
		)( function( data, varArg )
			if Core.Assert( data, "nTime" ) then
				for j = 1, #data do
					data[ j ]["nStyle"] = nil
					data[ j ]["szMap"] = nil
					TAS.Times[ nStyle ][ j ] = data[ j ]
				end
				
				OpenRecords( ply, nStyle )
			end
		end )
	else
		OpenRecords( ply, nStyle )
	end
end
Core.AddCmd( { "taswr", "wrtas" }, TAS.RecordsCommand )

--[[
	Description: Opens the TAS menu
--]]
function TAS.MenuCommand( ply )
	if not ply.TAS then return Core.Print( ply, "General", Core.Text( "TASMenuInvalid" ) ) end
	Core.Send( ply, "GUI/Create", { ID = "TAS", Dimension = { x = 200, y = 240, px = 20 }, Args = { Title = "TAS Menu" } } )
end
Core.AddCmd( { "tasmenu", "tmenu", "tasassist" }, TAS.MenuCommand )

--[[
	Description: Changes to TAS style
--]]
function TAS.StyleCommand( ply )
	if ply.Practice or not ply:Alive() then return Core.Print( ply, "Timer", Core.Text( "TASEnablePractice" ) ) end
	
	if not ply.TAS then
		if not ply:InSpawn() or ply.TimerNormal or ply.TimerNormalFinish then
			return Core.Print( ply, "Timer", Core.Text( "TASEnableMidrun" ) )
		end
		
		local count = 0
		for _,p in pairs( player.GetHumans() ) do
			if p.TAS then
				count = count + 1
			end
		end
		
		if count >= TAS.Maximum then
			return Core.Print( ply, "Timer", Core.Text( "TASEnableCount", TAS.Maximum ) )
		end
		
		-- Set main variables
		ply.WasTAS = true
		ply.TAS = TAS
		Core.Ext( "Bot", "CleanPlayer" )( ply, true )
		
		-- Enable +binds
		Core.Send( ply, "Timer/BypassBind", true )
		
		TAS.EnsureHook( true )
		TAS.MenuCommand( ply )
		TAS.Players[ ply ] = true
		
		TAS.LoadTime( ply, ply.Style )
		TAS.LoadRank( ply )
		
		Core.Print( ply, "Timer", Core.Text( "TASEnabled" ) )
	else
		TAS.MenuCommand( ply )
	end
end
Core.AddCmd( { "tas", "t", "assisted", "hacks", "omgicanhack" }, TAS.StyleCommand )


-- Language
Core.AddText( "TASEnabled", "TAS mode has been enabled. To re-open the menu, type !tasmenu" )
Core.AddText( "TASDisabled", "TAS mode has been disabled." )
Core.AddText( "TASEnablePractice", "You can't be in practice mode or spectator when switching TAS mode" )
Core.AddText( "TASEnableMidrun", "You can only enable TAS mode while in the spawn zone" )
Core.AddText( "TASEnableCount", "There can only be a maximum of 1; players in TAS at the same time." )
Core.AddText( "TASDisableMidrun", "You can only disable TAS mode while in the spawn zone" )
Core.AddText( "TASMenuInvalid", "You can only open this menu while in TAS mode" )
Core.AddText( "TASRestoreNotStarted", "You need to be in a run in order to set a restore frame" )
Core.AddText( "TASRestoreSet", "Your fixed restore frame has been set!" )
Core.AddText( "TASContinueNotSet", "You need to be in a run and have a restore frame set to use this" )
Core.AddText( "TASContinueMoving", "You can't continue at the given frame while fastreversing or fastforwarding" )
Core.AddText( "TASContinuePause", "You have to be paused in order to restore a previously set frame" )
Core.AddText( "TASContinueRange", "The stored frame is outside of the range of your current run, please set the stored frame properly" )
Core.AddText( "TASChangeStyleSpawn", "You can only change style while in the start zone" )
Core.AddText( "TASChangeStylePractice", "You can't enter practice mode while already in TAS mode" )
Core.AddText( "TASChangeStyleExit", " (Type !tasmenu and press 7 to leave TAS mode)" )
Core.AddText( "TASChangeSpectateExit", "Please exit TAS before going into spectator mode" )
Core.AddText( "TASCommandInvalid", "You can only use this command while in TAS mode" )
Core.AddText( "TASCommandPause", "You can only pause/resume while in a run" )
Core.AddText( "TASCommandPauseMoving", "You can't resume while fastreversing or fastforwarding" )
Core.AddText( "TASCommandWRNone", "There are no TAS records on the 1; style" )
Core.AddText( "TASCommandResetPause", "You can't restart while paused" )
Core.AddText( "TASConcommandHelp", "You can only use this command by binding a key like this: bind KEY +1;" )
Core.AddText( "TASConcommandPause", "You can only use 1; when you are paused" )
Core.AddText( "TASConcommandNavigate", "You can only use one navigational movement at a time" )
Core.AddText( "TASTimerSurpass", "You have surpassed the #1 TAS time by 25% extra. Your run has been cancelled." )
Core.AddText( "TASTimerSlow", "[TAS - 1;] You finished with a time of 2;, which is slower than your personal best of 3; (+4;)" )
Core.AddText( "TASTimerSlowTop", "[TAS] Your time was not faster (+1;) than the top time so your run has not been saved." )
Core.AddText( "TASTimerPB", "[TAS - 1;] You have a new personal best of 2;3;" )
Core.AddText( "TASTimerWR", "[TAS] You have obtained the #1 WR on the 1; style. The bot has automatically been set, type !mbot to play it, !bot save to save it." )

-- Help commands
local cmd = Core.ContentText( nil, true ).Commands
cmd["taswr"] = "Shows the records on the TAS mode"
cmd["tasmenu"] = "Opens the TAS menu"
cmd["tas"] = "Enables the TAS mode"
cmd["taspause"] = "Pauses or resumes TAS"
cmd["tasstrafe"] = "Toggles the strafehack"
cmd["tasrestore"] = "Sets a restore frame"
cmd["tascontinue"] = "Continues at set frame"
cmd["tasexit"] = "Exists TAS mode"