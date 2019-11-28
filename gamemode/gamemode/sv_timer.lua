-- Player meta function table
local PLAYER = FindMetaTable( "Player" )

-- Main class objects
local Timer = { Spawns = {}, Teleports = {}, Top = {}, PostInitFunc = {}, TopWRPlayer = {}, TopWRList = {} }
local Zones = { SpecialDoorMaps = {}, MovingDoorMaps = {} }
local Player = {}
local RTV = {}

-- Data containers
local WRSounds, Popups = {}, {}
local ClientEnts, BoostTimer = {}, {}
local Checkpoints, BeatMaps = {}, {}
local WRCache, WRTopCache = {}, {}
local TopListCache, StylePoints = {}, {}
local ZoneCache, ZoneEnts, ZoneWatch = {}, {}, {}

-- Easy access variables
local Lefty, Righty, ST, Bypass, PsuedoOff = IN_LEFT, IN_RIGHT, SysTime
local Config, NetPrepare, Prepare = Core.Config, Core.Prepare, SQLPrepare
local Styles, Ranks, PlayerData = Config.Style, Config.Ranks, Config.Player

-- Value containers
local ScrollStyles = { [Styles["Easy Scroll"]] = true, [Styles["Legit"]] = true }
local BoostCooldown = { 30, 45, 20, 20 }
local BoostMultiplier = { 1.8, 2.4, 3.0, 3.0 }

--[[
	Description: Translates a zone box into usable coordinates and gets a random spawn point
--]]
local function GetSpawnPoint( data )
	if type( data ) != "table" or #data != 3 then
		return Vector( 0, 0, 0 )
	end

	local vx, vy, vz = 8, 8, 0
	local dx, dy = data[ 2 ].x - data[ 1 ].x, data[ 2 ].y - data[ 1 ].y

	if dx > 96 then vx = dx - 32 - dx / 2 end
	if dy > 96 then vy = dy - 32 - dy / 2 end
	if data[ 2 ].z - data[ 1 ].z > 32 then vz = 16 end

	local center = Vector( data[ 3 ].x, data[ 3 ].y, data[ 1 ].z )
	local out = center + Vector( math.random( -vx, vx ), math.random( -vy, vy ), vz )

	return out
end
Core.RandomizeSpawn = GetSpawnPoint

--[[
	Description: Checks if the player has a valid timer
--]]
local function ValidTimer( ply, bBonus )
	if not IsValid( ply ) then return false end
	if ply.Practice or ply.TAS then return false end
	if ply.SkipValidation then ply.SkipValidation = nil return false end

	if bBonus then
		if not ply.Bonus then return false end
	else
		if ply.Bonus then return false end
	end

	return true
end

--[[
	Description: Resets any game-changing attributes on the player
--]]
local function ResetPlayerAttributes( ply, nPrevious, bStart )
	if ply:GetMoveType() != 2 then
		ply:SetMoveType( 2 )
	end

	if ply.LastObtainedFinish then
		ply.LastObtainedFinish = nil
	end

	if ply.TAS or ply.Practice then
		Core.Ext( "SMgr", "SetStrafeStats" )( ply )
	end

	if not bStart then
		Core.Ext( "Stages", "ResetStageID" )( ply )
	end

	if (bStart and ply.Style == Styles.Unreal) or (nPrevious == Styles.Unreal) then
		if BoostTimer[ ply ] and ST() < BoostTimer[ ply ] then
			BoostTimer[ ply ] = nil

			local ar = NetPrepare( "Timer/UnrealReset" )
			ar:UInt( 0, 6 )
			ar:Send( ply )
		end
	end

	if nPrevious then
		Core.Ext( "Stages", "OnStageReset" )( ply )

		if ply.Style == Styles.Legit or ply.Style == Styles.Stamina then
			ply:EnableStamina( true )
		elseif ply.StaminaUse then
			ply:EnableStamina( false )
		end
	end

	if ply.Style == Styles["Low Gravity"] then
		ply:SetGravity( Config.Player.LowGravity )
	elseif ply:GetGravity() != 0 then
		ply:SetGravity( 0 )
	end

	if ScrollStyles[ ply.Style ] then
		ply:EnableAutoHop( false )

		if ply.RequestJumpRatio then
			ply:RequestJumpRatio( true )
		end
	else
		if ply.LastAutoChange == false then
			ply:EnableAutoHop( false, true )
		else
			ply:EnableAutoHop( true )
		end
	end

	if ply.Practice then return end
	if ply:GetLaggedMovementValue() != 1 then
		ply:SetLaggedMovementValue( 1 )
	end
end

--[[
	Description: Cleaning up of variables when the player resets or sets their timer
--]]
local function PostTimerCleanup( ply, szType, varData )
	ply:Spectator( "PlayerRestart", varData )

	if szType != "Stop" then
		Core.Ext( "SMgr", "SetStrafeStats" )( ply )
	end

	if szType == "Start" or szType == "Reset" then
		ResetPlayerAttributes( ply, nil, szType == "Start" )
	end
end


--[[
	Description: Attempts to start the player's timer
--]]
function PLAYER:StartTimer( ent )
	if self.TAS then return self.TAS.StartTimer( self, ent ) end
	if not ValidTimer( self ) then return end

	local vel2d = self:GetVelocity():Length2D()
	if vel2d > PlayerData.StartSpeed and not Zones.IsOption( Zones.Options.NoStartLimit ) then
		self:ResetSpawnPosition()
		return Player.Notification( self, "Popup", { "Timer", Core.Text( "ZoneSpeed", math.ceil( vel2d ) .. " u/s" ), "lightning", 4 } )
	end

	-- Set the start speed value for surfers
	if Config.IsSurf then
		self.Tspeed = self:GetVelocity():Length()
	end

	self.TimerNormal = ST()
	self:SetJumps( 0 )

	local ar = NetPrepare( "Timer/Start" )
	ar:UInt( 1, 2 )
	ar:Send( self )

	-- Make sure we don't have the FULL clip of this guy walking around in the start zone
	Core.Ext( "Bot", "ChopFrames" )( self )

	-- Run stage hooks
	Core.Ext( "Stages", "HitStartZone" )( self )

	-- Check multiple start points
	if #Zones.StartPoints > 1 and IsValid( ent ) then
		local id
		for pos,data in pairs( Zones.StartPoints ) do
			if data[ 1 ] == ent.min then
				id = pos
			end
		end

		self.StartZoneID = id
	end

	PostTimerCleanup( self, "Start" )
end

--[[
	Description: Resets a player's timer
--]]
function PLAYER:ResetTimer( bEntity, ent )
	if self.TAS then return self.TAS.ResetTimer( self, ent ) end
	if not ValidTimer( self ) then return end
	if not self.TimerNormal and not bEntity then return end

	self.TimerNormal = nil
	self.TimerNormalFinish = nil

	Core.Ext( "Bot", "CleanPlayer" )( self )
	Core.Ext( "Bot", "SetPlayerActive" )( self, true )

	PostTimerCleanup( self, "Reset" )

	local ar = NetPrepare( "Timer/Start" )
	ar:UInt( 0, 2 )
	ar:Send( self )
end

--[[
	Description: Stops the timer and ends the run
--]]
function PLAYER:StopTimer( ent )
	if self.TAS then return self.TAS.StopTimer( self, ent ) end
	if not ValidTimer( self ) then return end

	-- Run stage hooks
	Core.Ext( "Stages", "HitEndZone" )( self )

	-- Check if we're missing timers
	if not self.TimerNormal or self.TimerNormalFinish then return end

	-- Set stop timer and deactivate bot
	self.TimerNormalFinish = ST()
	Core.Ext( "Bot", "SetPlayerActive" )( self )

	-- Start making use of this time that the player got
	local nTime = self.TimerNormalFinish - self.TimerNormal
	Timer.ProcessEnd( self, nTime )
	PostTimerCleanup( self, "Stop", { nTime } )
end

--[[
	Description: Attempts to start the player's bonus timer
--]]
function PLAYER:BonusStart( ent )
	if IsValid( ent ) and not Zones.ValidateBonusStyle( self, ent.embedded ) then return end
	if self.TAS then return self.TAS.StartTimer( self, ent, true ) end
	if not ValidTimer( self, true ) then return end

	local vel2d = self:GetVelocity():Length2D()
	if vel2d > PlayerData.StartSpeed then
		self:ResetSpawnPosition()
		return Player.Notification( self, "Popup", { "Timer", Core.Text( "ZoneSpeed", math.ceil( vel2d ) .. " u/s" ), "lightning", 4 } )
	end

	-- Set the start speed value for surfers
	if Config.IsSurf then
		self.Tspeed = self:GetVelocity():Length()
	end

	self.TimerBonus = ST()
	self:SetJumps( 0 )

	local ar = NetPrepare( "Timer/Start" )
	ar:UInt( 1, 2 )
	ar:Send( self )

	-- Make sure we don't have the FULL clip of this guy walking around in the start zone
	Core.Ext( "Bot", "ChopFrames" )( self )

	PostTimerCleanup( self, "Start" )
end

--[[
	Description: Resets a player's bonus timer
--]]
function PLAYER:BonusReset( bEntity, ent )
	if bEntity and IsValid( ent ) and not Zones.ValidateBonusStyle( self, ent.embedded ) then return end
	if self.TAS then return self.TAS.ResetTimer( self, ent, true ) end
	if not ValidTimer( self, true ) then return end
	if not self.TimerBonus and not bEntity then return end

	self.TimerBonus = nil
	self.TimerBonusFinish = nil

	Core.Ext( "Bot", "CleanPlayer" )( self )
	Core.Ext( "Bot", "SetPlayerActive" )( self, true )

	PostTimerCleanup( self, "Reset" )

	local ar = NetPrepare( "Timer/Start" )
	ar:UInt( 0, 2 )
	ar:Send( self )
end

--[[
	Description: Stops the bonus timer and ends the run
--]]
function PLAYER:BonusStop( ent )
	if IsValid( ent ) and not Zones.ValidateBonusStyle( self, ent.embedded ) then return end
	if self.TAS then return self.TAS.StopTimer( self, ent, true ) end
	if not ValidTimer( self, true ) then return end
	if not self.TimerBonus or self.TimerBonusFinish then return end

	self.TimerBonusFinish = ST()
	Core.Ext( "Bot", "SetPlayerActive" )( self )

	-- Start making use of this sexy bonus time
	local nTime = self.TimerBonusFinish - self.TimerBonus
	Timer.ProcessEnd( self, nTime, self.Bonus )
	PostTimerCleanup( self, "Stop", { nTime } )
end

--[[
	Description: Stops any timer (for cheating purposes)
--]]
function PLAYER:StopAnyTimer( ent )
	if self:IsBot() or self.Practice then return false end
	if IsValid( ent ) and ent.embedded and self.Style != ent.embedded then return false end
	if self.TAS then return self.TAS.ResetTimer( self, ent ) end

	self.TimerNormal = nil
	self.TimerNormalFinish = nil
	self.TimerBonus = nil
	self.TimerBonusFinish = nil

	Core.Ext( "Stages", "OnStageReset" )( self )
	Core.Ext( "Bot", "SetPlayerActive" )( self )
	Core.Ext( "Bot", "CleanPlayer" )( self )

	local ar = NetPrepare( "Timer/Start" )
	ar:UInt( 0, 2 )
	ar:Send( self )

	PostTimerCleanup( self, "Anticheat" )

	return true
end

--[[
	Description: Checks if the player can be monitored while in the start zone
--]]
function PLAYER:RequestZonePermission( ent, main, bonus )
	if not IsValid( self ) or not self.Style then return end
	if not main and not bonus then return end
	if self.Practice or self.TAS or Config.IsSurf then return end

	if bonus then
		if not Zones.ValidateBonusStyle( self, ent.embedded ) then return end
	elseif main then
		if self.Bonus then return end
	end

	if self:GetVelocity().z != 0 then
		self:SetLocalVelocity( Vector( 0, 0, -1000 ) )
	end

	return true
end

--[[
	Description: Checks whether the player is in a spawn or not
--]]
function PLAYER:InSpawn( pos )
	-- Get the compare position
	pos = pos or self:GetPos()

	-- Find all matching zone entities and compare
	for _,zone in pairs( ZoneEnts ) do
		if IsValid( zone ) then
			if self.Bonus then
				if zone.zonetype == Zones.Type["Bonus Start"] then

				end
			elseif zone.zonetype != Zones.Type["Normal Start"] then
				continue
			end

			if pos.x >= zone.min.x and pos.y >= zone.min.y and pos.z >= zone.min.z and pos.x <= zone.max.x and pos.y <= zone.max.y and pos.z <= zone.max.z then
				return true
			end
		end
	end
end

--[[
	Description: Resets the player's position
--]]
function PLAYER:ResetSpawnPosition( bReset, bLeave )
	if self:IsBot() then
		self:SetLocalVelocity( Vector( 0, 0, 0 ) )
		return Zones.BotPoints and #Zones.BotPoints > 0 and self:SetPos( Zones.BotPoints[ math.random( 1, #Zones.BotPoints ) ] )
	elseif not self.Style then
		return
	elseif bReset then
		local dz = bReset.embedded
		if dz then
			if bLeave and self:GetVelocity():Length2D() > dz * 100 then
				self:SetLocalVelocity( Vector( 0, 0, 0 ) )
			end

			return
		end
	end

	self.LastResetData = not self:InSpawn() and { ST(), self.Style, self.TimerNormalFinish, self.TimerNormal, self:GetPos(), self:EyeAngles(), self:GetJumps(), Core.Ext( "SMgr", "GetStrafes" )( self ), { Core.Ext( "SMgr", "GetPlayerSync" )( self, true ) }, { self:SpeedValues() } }
	self:SetLocalVelocity( Vector( 0, 0, 0 ) )
	self:SetJumps( 0 )
	self:SetJumpPower( Config.Player.JumpPower )

	ResetPlayerAttributes( self )

	Core.Ext( "Stages", "OnStageReset" )( self )
	Core.Ext( "Stats", "ResetPlayer" )( self )

	if self.SpaceEnabled then
		Core.Send( self, "Timer/Space", true )
	end

	local bonus = self.Bonus
	if bonus and self.TimerBonus then
		self:BonusReset()
	elseif not bonus and self.TimerNormal then
		self:ResetTimer()
	end

	if Timer.BaseAngles then
		if bonus then
			local ang = Timer.BonusAngles[ bonus ]
			if ang then
				self:SetEyeAngles( Angle( self:EyeAngles().p, ang.y, 0 ) )
			end
		else
			self:SetEyeAngles( Angle( self:EyeAngles().p, Timer.BaseAngles.y, 0 ) )
		end
	end

	if not bonus and Zones.StartPoints and #Zones.StartPoints > 0 then
		self:SetPos( GetSpawnPoint( Zones.StartPoints[ self.StartZoneID or math.random( 1, #Zones.StartPoints ) ] ) )
	elseif bonus then
		self:SetPos( GetSpawnPoint( Zones.GetBonusPoint( bonus ) ) )
	else
		Core.Print( self, "Timer", Core.Text( "ZoneSetup" ) )
	end

	return true
end

--[[
	Description: Executes an unreal boost
--]]
function PLAYER:DoUnrealBoost( nForce )
	if not self.Practice and BoostTimer[ self ] and ST() < BoostTimer[ self ] then return end
	if self.TAS and self.TAS.UnrealBoost( self ) then return end

	-- Set the base cooldown to be non-existant
	local nCooldown, nMultiplier, nType = 0, 0, 1
	local vel = self:GetVelocity()

	-- Check which boost type we need
	if self:KeyDown( IN_FORWARD ) and not self:KeyDown( IN_BACK ) and not self:KeyDown( IN_MOVELEFT ) and not self:KeyDown( IN_MOVERIGHT ) then
		nType = 2
	elseif self:KeyDown( IN_JUMP ) and not self:KeyDown( IN_FORWARD ) and not self:KeyDown( IN_BACK ) and not self:KeyDown( IN_MOVELEFT ) and not self:KeyDown( IN_MOVERIGHT ) then
		nType = 3
	elseif self:KeyDown( IN_BACK ) and not self:KeyDown( IN_FORWARD ) and not self:KeyDown( IN_MOVELEFT ) and not self:KeyDown( IN_MOVERIGHT ) then
		nType = 4
	else
		nType = 1
	end

	-- See if we're forcing
	if nForce then
		nType = nForce
	end

	-- By default, for all different key combinations, we will simply amplify velocity
	if nType == 1 then
		nCooldown = BoostCooldown[ 1 ]
		nMultiplier = BoostMultiplier[ 1 ]

		self:SetVelocity( vel * Vector( nMultiplier, nMultiplier, nMultiplier * 1.5 ) - vel )

	-- If we've only got W down, we will boost forward faster than normal omnidirectional boost
	elseif nType == 2 then
		nCooldown = BoostCooldown[ 2 ]
		nMultiplier = BoostMultiplier[ 2 ]

		self:SetVelocity( vel * Vector( nMultiplier, nMultiplier, 1 ) - vel )

	-- If we've only got jump in, we will boost upwards strongly
	elseif nType == 3 then
		nCooldown = BoostCooldown[ 3 ]
		nMultiplier = BoostMultiplier[ 3 ]

		if vel.z < 0 then
			nMultiplier = -0.5 * nMultiplier
		end

		self:SetVelocity( vel * Vector( 1, 1, nMultiplier ) - vel )

	-- If we've got S down and nothing else, we will boost downwards fast
	elseif nType == 4 then
		nCooldown = BoostCooldown[ 4 ]
		nMultiplier = BoostMultiplier[ 4 ]

		if vel.z > 0 then
			nMultiplier = -nMultiplier
		end

		self:SetVelocity( vel * Vector( 1, 1, nMultiplier ) - vel )
	end

	if nCooldown != 0 then
		BoostTimer[ self ] = ST() + nCooldown
		if self.TAS then self.TAS.UnrealBoost( self, nCooldown ) end

		local ar = NetPrepare( "Timer/UnrealReset" )
		ar:UInt( nCooldown, 6 )
		ar:Send( self )
	end
end

--[[
	Description: Enables stamina on the given player
--]]
function PLAYER:EnableStamina( bool )
	Core.EnableStamina( self, bool )
	self.StaminaUse = bool

	local ar = NetPrepare( "Timer/Stamina" )
	ar:Bit( bool )
	ar:Send( self )

	return bool
end

--[[
	Description: Toggles auto hop on the given player
--]]
function PLAYER:EnableAutoHop( bValue, bUpdate )
	if bUpdate and ScrollStyles[ self.Style ] then return end

	local _,au = Core.GetDuckSet()
	if bValue == nil then
		au[ self ] = not au[ self ]
	else
		au[ self ] = not bValue
	end

	if bUpdate then
		local ar = NetPrepare( "Timer/AutoHop" )
		ar:Bit( au[ self ] )
		ar:Send( self )
	end

	return not au[ self ]
end

--[[
	Description: Enables freestyle movement for specific styles
--]]
function PLAYER:StartFreestyle( ent )
	if not ValidTimer( self, self.Bonus ) and not self.TAS then return end
	if IsValid( ent ) and ent.embedded and self.Style != ent.embedded then return false end

	if self.Style >= Styles.SW and self.Style <= Styles["S-Only"] then
		self.Freestyle = true
		Core.Send( self, "Timer/Freestyle", { self.Freestyle } )
		Core.Print( self, "Timer", Core.Text( "StyleFreestyle", "entered a", " All key combinations are now possible." ) )
	elseif self.Style == Styles["Low Gravity"] then
		self.Freestyle = true
		Core.Send( self, "Timer/Freestyle", { self.Freestyle } )
		Core.Print( self, "Timer", Core.Text( "StyleFreestyle", "entered a", " Reverted gravity to normal values." ) )
	end
end

--[[
	Description: Disables freestyle movement for specific styles
--]]
function PLAYER:StopFreestyle( ent )
	if (not ValidTimer( self, self.Bonus ) and not self.TAS) or not self.Freestyle then return end
	if IsValid( ent ) and ent.embedded and self.Style != ent.embedded then return false end

	if self.Style >= Styles.SW and self.Style <= Styles["S-Only"] then
		self.Freestyle = nil
		Core.Send( self, "Timer/Freestyle", { self.Freestyle } )
		Core.Print( self, "Timer", Core.Text( "StyleFreestyle", "left the", "" ) )
	elseif self.Style == Styles["Low Gravity"] then
		self.Freestyle = nil
		Core.Send( self, "Timer/Freestyle", { self.Freestyle } )
		Core.Print( self, "Timer", Core.Text( "StyleFreestyle", "left the", "" ) )
	end
end


-- Records

Timer.Multiplier = 1
Timer.BonusMultiplier = 1
Timer.Options = 0
Timer.Maps = 0
Timer.BonusMaps = 0
Timer.RealBonusMaps = 0
Timer.SamplePercentage = 50

local Maps = {}
local Records = {}
local TopTimes = {}
local Averages = {}
local TimeCache = {}
local InsertAt, RemoveAt = table.insert, table.remove


--[[
	Description: Gets the amount of records in a style
--]]
local function GetRecordCount( nStyle )
	return Records[ nStyle ] and #Records[ nStyle ] or 0
end

--[[
	Description: Gets the saves average for a specific style, returns 0 if none set
--]]
local function GetAverage( nStyle )
	return Averages[ nStyle ] or 0
end

--[[
	Description: Recalculate the average for a specific style
--]]
local function CalcAverage( nStyle )
	local nTotal, nCount, nLimit = 0, 0, 0

	-- Get the sample count
	if Records[ nStyle ] and #Records[ nStyle ] > 0 then
		-- Set it to take over all if we can't find any time larger
		nLimit = #Records[ nStyle ]

		-- Get the maximum included time
		local nMax = Records[ nStyle ][ 1 ]["nTime"] * (1 + Timer.SamplePercentage / 100)
		for i = 1, nLimit do
			if nMax < Records[ nStyle ][ i ]["nTime"] then
				nLimit = i - 1
				break
			end
		end
	end

	-- Iterate over the top nLimit times of this style and add the time values
	for i = 1, nLimit do
		if Records[ nStyle ] and Records[ nStyle ][ i ] then
			nTotal = nTotal + Records[ nStyle ][ i ]["nTime"]
			nCount = nCount + 1
		else
			break
		end
	end

	-- Check the amount of times we have
	if nCount == 0 then
		Averages[ nStyle ] = 0
	else
		-- Save the average for later use
		Averages[ nStyle ] = nTotal / nCount
	end

	-- Return the saved average
	return Averages[ nStyle ]
end

--[[
	Description: Updates a player record accordingly
--]]
local function UpdateRecords( szUID, nStyle, nPos, nNew, nOld, nDate, szData, nInterp )
	local Entry = {}
	Entry.szUID = szUID
	Entry.nTime = nNew
	Entry.nPoints = nInterp
	Entry.nDate = nDate
	Entry.vData = Core.Null( szData )

	-- If there's no previous time, just insert a new entry at the correct position
	if nOld == 0 then
		InsertAt( Records[ nStyle ], nPos, Entry )
	else
		local AtID = 0

		-- Obtain the player's location in the ladder
		for i = 1, #Records[ nStyle ] do
			if Records[ nStyle ][ i ]["szUID"] == Entry["szUID"] then
				AtID = i
				break
			end
		end

		-- Update the record at that position
		if AtID > 0 then
			RemoveAt( Records[ nStyle ], AtID )
			InsertAt( Records[ nStyle ], nPos, Entry )
		else
			Core.PrintC( "[Error] Records", "Unable to replace existing time. Please restart server immediately." )
		end
	end
end

--[[
	Description: Final function in the AddRecord chain; broadcasts messages and recalculates
--]]
local function AddRecord_End( ply, nTime, nOld, nID, nStyle, nOriginal, nPreviousWR, nPrevID, szPreviousWR )
	-- Show a message that a new time has been added
	Core.PrintC( "[Event] Record set from " .. nOld .. " to " .. nTime .. " by ", ply:Name(), " on ", Core.StyleName( nOriginal ) .. " (" .. nStyle .. ")" )

	-- Setup data for notification
	local data = {}

	-- Give them a shiny medal when applicable
	if nID <= 3 then
		Player.SetRankMedal( ply, nID, true )

		if nID == 1 then
			-- Notify the previous WR holder
			if nPreviousWR > 0 and szPreviousWR and szPreviousWR != ply.UID then
				Player.NotifyBeatenWR( szPreviousWR, game.GetMap(), ply:Name(), nStyle, nPreviousWR - nTime )
			end

			-- (Re)load the full list if required
			if nStyle == Styles.Normal or GetRecordCount( nStyle ) >= 10 then
				if not Timer.SoundTracker or #Timer.SoundTracker == 0 then
					Timer.SoundTracker = {}

					for i = 1, #WRSounds do
						Timer.SoundTracker[ i ] = i
					end
				end

				-- WR Sounds, yey (only for the really cool people, though)
				local nSound = table.remove( Timer.SoundTracker, math.random( 1, #Timer.SoundTracker ) )
				if Config.Var.GetBool( "PlaySound" ) then
					data.Sound = "/sound/" .. Config.MaterialID .. "/" .. WRSounds[ nSound ] .. ".mp3"
				end
			end

			-- Set the top time
			Timer.ChangeTopTime( nStyle )
		end
	end

	-- Set the new WR position for the bot
	-- To-Do: The fuck why is this here?
	Core.Ext( "Bot", "SetRecord" )( nStyle, nID )

	-- Send the player his new time
	local ar = NetPrepare( "Timer/Record" )
	ar:Double( nTime )
	ar:Bit( false )
	ar:Send( ply )

	-- End the bot run if there is any
	local bSucceed = Core.Ext( "Bot", "PlayerEndRun" )( ply, nTime, nID )
	if bSucceed then
		data.Bot = true
	else
		ply.LastObtainedFinish = { nTime, nStyle, ply.Bonus and ply.TimerBonusFinish or ply.TimerNormalFinish }
		Core.Ext( "Bot", "PostFinishForce" )( ply )
	end

	-- Setup the variables
	data.Time = nTime
	data.Style = nOriginal
	data.Pos = nID
	data.Bonus = ply.Bonus
	data.DifferenceWR = nID > 1 and "WR +" .. Timer.Convert( nTime - Timer.ChangeTopTime( nStyle, true ) ) or (nPreviousWR > 0 and "WR -" .. Timer.Convert( nPreviousWR - nTime ) or "")
	data.Improvement = nOld == 0 and -1 or Timer.Convert( nOld - nTime )
	data.MapRecord = nID == 1
	data.Rank = nID .. " / " .. GetRecordCount( nStyle )

	-- Send out the notification
	Player.Notification( ply, "ImproveFinish", data )
end

--[[
	Description: First function in the AddRecord chain; Get the player's new rank
--]]
local function AddRecord_Begin( data, varArg )
	-- Get required variables
	local ply, nTime, nOld, nDate, nStyle, nOriginal, szData, nInterp = unpack( varArg )
	local nPrevious, szPrevious = Timer.ChangeTopTime( nStyle, true )
	local nID = Timer.GetRecordID( nTime, nStyle )
	local _,nPrevID = Timer.GetPlayerRecord( ply )
	local nCurrentAverage = CalcAverage( nStyle )

	-- Insert the record into the internal table
	UpdateRecords( ply.UID, nStyle, nID, nTime, nOld, nDate, szData, nInterp )

	-- Obtain the new average
	CalcAverage( nStyle )

	-- Change the ID
	ply.Leaderboard = nID
	ply:VarNet( "Set", "Position", ply.Leaderboard, true )

	-- Reload everything
	ply:LoadRank()
	ply:AddFrags( 1 )
	Player.ReloadRanks( ply, nStyle, nCurrentAverage )

	-- End the AddRecord instance
	AddRecord_End( ply, nTime, nOld, nID, nStyle, nOriginal, nPrevious or 0, nPrevID, szPrevious )
end


--[[
	Description: Begins processing the obtained time and takes the next steps
--]]
function Timer.ProcessEnd( ply, nTime, nBonus )
	-- Get the difference between previous record
	local Difference = ply.Record > 0 and nTime - ply.Record
	local IsImproved = ply.Record == 0 or (ply.Record > 0 and nTime < ply.Record)
	local SelfDifference = Difference and "PB " .. (Difference < 0 and "-" or "+") .. Timer.Convert( math.abs( Difference ) ) or ""

	-- Check run details
	local StyleId, TopSpeed, AverageSpeed = ply.Style, ply:SpeedValues()
	local CurrentSync, Strafes, Jumps, StartSpeed = Core.Ext( "SMgr", "GetPlayerSync" )( ply ), Core.Ext( "SMgr", "GetStrafes" )( ply ), ply:GetJumps()
	local JumpRatio = ScrollStyles[ ply.Style ] and ply.RequestJumpRatio and ply:RequestJumpRatio( nil, { Core.StyleName( StyleId ), Jumps, nTime, ply.Record } )

	-- Set start speed
	if Config.IsSurf then
		StartSpeed = ply.Tspeed
		ply.Tspeed = nil
	end

	-- Check additional possibilities
	if ply.Race then
		ply.Race:Stop( ply )
	end

	-- Get the style id
	if nBonus then
		StyleId = Core.MakeBonusStyle( StyleId, nBonus )
	end

	-- Get the amount of points the user gets for completing the map
	local InterpAverage = Timer.InterpolateAverage( nTime, StyleId )
	local InterpPoints = Timer.GetPointsForMap( ply, nTime, StyleId, InterpAverage, true )
	local InterpRank = Player.GetRankProgress( ply, nil, InterpPoints )

	-- Notify the player
	Player.Notification( ply, "BaseFinish", { Time = nTime, Difference = SelfDifference, Jumps = Jumps, Strafes = Strafes, Sync = CurrentSync, Points = IsImproved and math.Round( InterpPoints, 2 ), Rank = IsImproved and InterpRank } )

	-- Check if they have an old record
	local OldRecord = ply.Record
	if ply.Record != 0 and nTime >= ply.Record then return end

	-- Update variables
	local RunDetails = string.Implode( " ", { math.floor( Config.IsBhop and TopSpeed or StartSpeed or 0 ), math.floor( AverageSpeed or 0 ), Jumps or 0, Strafes or 0, CurrentSync or 0, JumpRatio } )
	ply.Record = nTime
	ply:VarNet( "Set", "Record", ply.Record, true )

	-- If we have something, update, otherwise, insert
	Prepare(
		"SELECT nTime FROM game_times WHERE szMap = {0} AND szUID = {1} AND nStyle = {2}",
		{ game.GetMap(), ply.UID, StyleId }
	)( function( data, varArg )
		local OldTime, QueryTime, QueryObject = OldRecord, Timer.GetCurrentDate()
		if Core.Assert( data, "nTime" ) then
			OldTime = data[ 1 ]["nTime"] or OldTime

			if ply.Record < OldTime then
				QueryObject = Prepare(
					"UPDATE game_times SET nTime = {0}, nDate = {1}, vData = {2} WHERE szMap = {3} AND szUID = {4} AND nStyle = {5}",
					{ ply.Record, QueryTime, RunDetails, game.GetMap(), ply.UID, StyleId }
				)
			end
		else
			QueryObject = Prepare(
				"INSERT INTO game_times VALUES ({0}, {1}, {2}, {3}, 0, {4}, {5})",
				{ ply.UID, game.GetMap(), StyleId, ply.Record, QueryTime, RunDetails }
			)
		end

		-- Continue with execution if we still have a valid object
		if QueryObject then
			QueryObject( AddRecord_Begin, { ply, ply.Record, OldTime, QueryTime, StyleId, ply.Style, RunDetails, InterpPoints } )
		end
	end )
end

--[[
	Description: Sends the top times table
--]]
function Timer.SendTopTimes( ply )
	local ar = NetPrepare( "Timer/Initial" )
	ar:UInt( table.Count( TopTimes ), 8 )

	for s,t in pairs( TopTimes ) do
		ar:Double( s )
		ar:Double( t )
	end

	if ply then
		ar:Send( ply )
	else
		ar:Broadcast()
	end
end
Core.SendTopTimes = Timer.SendTopTimes

--[[
	Description: Updates the top time in the local table
--]]
function Timer.ChangeTopTime( nStyle, bGet, bAvoid )
	-- Check if the time is valid
	if Records[ nStyle ] and Records[ nStyle ][ 1 ] and Records[ nStyle ][ 1 ]["nTime"] then
		-- Insert it into the TopTimes cache
		TopTimes[ nStyle ] = Records[ nStyle ][ 1 ]["nTime"]

		-- Return it if we want to get it
		if bGet then
			return TopTimes[ nStyle ] or 0, Records[ nStyle ][ 1 ]["szUID"]
		end
	end

	-- Otherwise broadcast
	if not bGet and not bAvoid then
		Timer.SendTopTimes()
	end
end

--[[
	Description: Returns the multiplier for a given style
	Notes: All styles that follow the main course are given the base multiplier
--]]
function Timer.GetMultiplier( nStyle, bAll )
	if nStyle < Config.BonusStyle then
		if type( Timer.BonusMultiplier ) == "table" then
			if bAll then
				local total = 0
				for i = 1, #Timer.BonusMultiplier do
					total = total + Timer.BonusMultiplier[ i ]
				end
				return total
			else
				local st,id = Core.GetBonusStyle( nStyle )
				return Timer.BonusMultiplier[ id ] or 0
			end
		else
			return Timer.BonusMultiplier
		end
	else
		return Timer.Multiplier
	end
end

--[[
	Description: Gets the amount of points you would have for a specific time on a style
--]]
function Timer.GetPointsForMap( ply, nTime, nStyle, nAverage, bSingle )
	local total = 0
	if nStyle < Config.BonusStyle then
		local st,id = Core.GetBonusStyle( nStyle )
		if st != Styles.Normal then
			return 0
		end

		if bSingle then
			if nTime == 0 then return 0 end
			if not nAverage then nAverage = GetAverage( nStyle ) end

			local m = Timer.GetMultiplier( nStyle )
			total = math.Clamp( m * (nAverage / nTime), m / 4, m * 2 )
		else
			local ids = Zones.GetBonusIDs()
			for i = 1, #ids do
				local style = Core.MakeBonusStyle( st, ids[ i ] )
				local rec = Timer.GetPlayerRecord( ply, style )
				if rec == 0 then continue end

				local m = Timer.GetMultiplier( style )
				local p = math.Clamp( m * (GetAverage( style ) / rec), m / 4, m * 2 )

				total = total + p
			end
		end
	else
		if nTime == 0 then return 0 end
		if not nAverage then nAverage = GetAverage( nStyle ) end

		local m = Timer.GetMultiplier( nStyle )
		total = math.Clamp( m * (nAverage / nTime), m / 4, m * 2 )
	end

	return total
end
Core.GetPointsForMap = Timer.GetPointsForMap

--[[
	Description: Gets the record ID you would have for a time
--]]
function Timer.GetRecordID( nTime, nStyle )
	-- Check the records table
	if Records[ nStyle ] then
		for i = 1, #Records[ nStyle ] do
			if nTime <= Records[ nStyle ][ i ]["nTime"] then
				return i
			end
		end

		return #Records[ nStyle ] + 1
	else
		return 1
	end
end
Core.GetRecordID = Timer.GetRecordID

--[[
	Description: Gets the steam ID of the player at the given position
--]]
function Timer.GetSteamAtID( ply, nID )
	-- Set base variables
	local nStyle = ply.Style
	if ply.Bonus then
		nStyle = Core.MakeBonusStyle( nStyle, ply.Bonus )
	end

	-- Iterate over the table
	if Records[ nStyle ] then
		for i = 1, #Records[ nStyle ] do
			if i == nID then
				return Records[ nStyle ][ i ]["szUID"]
			end
		end
	end
end
Core.GetSteamAtID = Timer.GetSteamAtID

--[[
	Description: Gets the record entry for a player currently in the table
--]]
function Timer.GetPlayerRecord( ply, nOverride )
	-- Set base variables
	local nStyle, szSteam = nOverride or ply.Style, ply.UID
	if ply.Bonus then
		nStyle = Core.MakeBonusStyle( nStyle, ply.Bonus )
	end

	-- Check if we even have records for that style
	if Records[ nStyle ] then
		for i = 1, #Records[ nStyle ] do
			if Records[ nStyle ][ i ]["szUID"] == szSteam then
				return Records[ nStyle ][ i ]["nTime"], i
			end
		end
	end

	return 0, 0
end
Core.GetPlayerRecord = Timer.GetPlayerRecord

--[[
	Description: Gets the top X steam IDs
--]]
function Timer.GetTopSteam( nStyle, nAmount )
	local list = {}
	if Records[ nStyle ] then
		for i = 1, nAmount do
			if Records[ nStyle ][ i ] then
				list[ i ] = Records[ nStyle ][ i ]["szUID"]
			end
		end
	end

	return list
end

--[[
	Description: Gets the WR count on the player
--]]
function Timer.GetPlayerWRs( uid, style, all )
	local out = { 0, 0, 0 }

	-- To-Do: See how we want to display bonus on here (I think we only want to count Normal bonus WRs)
	--[[if style and Core.IsValidBonus( style ) then
		style = Styles.Bonus
	end]]

	for _,data in pairs( WRTopCache[ uid ] or {} ) do
		local ts = data.nStyle
		if ts then
			out[ 1 ] = out[ 1 ] + 1

			--[[if Core.IsValidBonus( ts ) then
				ts = Styles.Bonus
			end]]

			if ts == style then
				out[ 2 ] = out[ 2 ] + 1
			else
				out[ 3 ] = out[ 3 ] + 1
			end

			if all then
				if not out.Rest then out.Rest = {} end
				out.Rest[ ts ] = (out.Rest[ ts ] or 0) + 1
			end
		end
	end

	return out
end

--[[
	Description: Approximate points gained for map
	Notes: It's called Interpolate because it isn't exact, but very accurate
--]]
function Timer.InterpolateAverage( nTime, nStyle )
	local nTotal, nCount, nLast, nLimit = 0, 0, 0, 0

	-- Get the sample count
	if Records[ nStyle ] and #Records[ nStyle ] > 0 then
		-- Set it to take over all if we can't find any time larger
		nLimit = #Records[ nStyle ]

		-- Get the maximum included time
		local nMax = Records[ nStyle ][ 1 ]["nTime"] * (1 + Timer.SamplePercentage / 100)
		for i = 1, nLimit do
			if nMax < Records[ nStyle ][ i ]["nTime"] then
				nLimit = i - 1
				break
			end
		end
	end

	-- Iterate over the top nLimit times of this style and add the time values
	for i = 1, nLimit do
		if Records[ nStyle ][ i ] then
			nTotal = nTotal + Records[ nStyle ][ i ]["nTime"]
			nCount = nCount + 1
			nLast = i
		else
			break
		end
	end

	-- Remove the lowest time and replace it with our (fictional) time
	if nLast > 0 and Records[ nStyle ] and Records[ nStyle ][ nLast ]["nTime"] > nTime then
		nTotal = nTotal - Records[ nStyle ][ nLast ]["nTime"]
		nTotal = nTotal + nTime
	elseif nLast == 0 and nCount == 0 then
		nTotal = nTime
		nCount = 1
	end

	-- Make sure we don't return a NaN
	if nCount == 0 then
		return 0
	else
		return nTotal / nCount
	end
end

--[[
	Description: Opens the WR list for any other map
	Notes: EVEN for when they entered the current map
--]]
function Timer.DoRemoteWRList( ply, szMap, nStyle, nUpdate )
	if not szMap then return end
	if tonumber( szMap ) then
		local nID = tonumber( szMap )
		local nLim = Core.GetRecordCount( nStyle )

		if nID <= 0 or nID > nLim then
			return Core.Print( ply, "General", Core.Text( "CommandWRListReach", nID, nLim ) )
		end

		local nBottom = math.floor( (nID - 1) / Config.PageSize ) * Config.PageSize + 1
		local nTop = nBottom + Config.PageSize - 1

		if nTop > nLim then
			nTop = nLim
		end

		local args = { Core.GetRecordList( nStyle, nBottom, nTop ), nLim, nStyle }
		args.Started = nBottom
		args.TargetID = nID

		return GAMEMODE:ShowSpare2( ply, args )
	end

	if szMap == game.GetMap() and not ply.OutputSock and not ply.OutputFull then
		return GAMEMODE:ShowSpare2( ply, nil, nStyle )
	end

	local function ProceedSending()
		local SendData = {}
		local SendCount = 0

		-- This means we already fetched the data
		local nStart, nMaximum = 1, Config.PageSize
		if nUpdate then
			nStart, nMaximum = nUpdate[ 1 ], nUpdate[ 2 ]
		end

		for i = nStart, nMaximum do
			if WRCache[ szMap ][ nStyle ][ i ] then
				SendData[ i ] = WRCache[ szMap ][ nStyle ][ i ]
			end
		end

		SendCount = #WRCache[ szMap ][ nStyle ]

		if ply.OutputFull then
			return ply:OutputFull( WRCache[ szMap ][ nStyle ] )
		end

		-- Scan for data
		local bZero = true
		for i,data in pairs( SendData ) do
			if i and data then bZero = false break end
		end

		if ply.OutputSock then
			return ply.OutputSock( SendData, SendCount )
		end

		-- If we don't have anything, show only a print
		if bZero or SendCount == 0 then
			if nUpdate then return end
			Core.Print( ply, "Timer", Core.Text( "CommandRemoteWRListBlank", szMap, Core.StyleName( nStyle ) ) )
		else
			if nUpdate then
				NetPrepare( "GUI/Update", {
					ID = "Records",
					Data = { SendData, SendCount }
				} ):Send( ply )
			else
				NetPrepare( "GUI/Build", {
					ID = "Records",
					Title = "Server records",
					X = 500,
					Y = 400,
					Mouse = true,
					Blur = true,
					Data = { SendData, SendCount, nStyle, IsEdit = ply.RemovingTimes, Map = szMap }
				} ):Send( ply )
			end
		end
	end

	local WRMap = WRCache[ szMap ]
	if not WRMap or (type( WRMap ) == "table" and not WRMap[ nStyle ]) then
		if RTV.MapExists( szMap ) then
			if not WRMap then
				WRCache[ szMap ] = {}
			end

			-- Request the data
			Prepare(
				"SELECT * FROM game_times WHERE szMap = {0} AND nStyle = {1} ORDER BY nTime ASC",
				{ szMap, nStyle },
				{ UseOptions = true, RawFormat = true }
			)( function( data, varArg )
				WRCache[ szMap ][ nStyle ] = {}

				if Core.Assert( data, "szUID" ) then
					local makeNum, makeNull, nCount = tonumber, Core.Null, 1
					for j = 1, #data do
						data[ j ]["szMap"] = nil
						data[ j ]["nStyle"] = nil
						data[ j ]["nTime"] = makeNum( data[ j ]["nTime"] )
						data[ j ]["nPoints"] = makeNum( data[ j ]["nPoints"] )
						data[ j ]["nDate"] = makeNum( data[ j ]["nDate"] ) or 0
						data[ j ]["vData"] = makeNull( data[ j ]["vData"] )

						WRCache[ szMap ][ nStyle ][ nCount ] = data[ j ]
						nCount = nCount + 1
					end
				end

				ProceedSending()
			end )
		else
			return Core.Print( ply, "General", Core.Text( "MapInavailable", szMap ) )
		end
	else
		ProceedSending()
	end

	return true
end
Core.DoRemoteWR = Timer.DoRemoteWRList

--[[
	Description: Responds with an update to the request
	Notes: Much more efficient than what I used to do with paging
--]]
function Timer.WRListRequest( ply, varArgs )
	local nStyle = varArgs[ 1 ]
	local tabOffset = varArgs[ 2 ]
	local szMap = varArgs[ 3 ]

	-- If a map is provided, send a remote WR update
	if szMap then
		Timer.DoRemoteWRList( ply, szMap, nStyle, tabOffset )
	else
		NetPrepare( "GUI/Update", {
			ID = "Records",
			Data = { Core.GetRecordList( nStyle, tabOffset[ 1 ], tabOffset[ 2 ] ), Core.GetRecordCount( nStyle ) }
		} ):Send( ply )
	end
end
Core.Register( "Global/RetrieveList", Timer.WRListRequest )

--[[
	Description: Removes times by request of an admin
	Notes: Migrated from the admin panel to here
--]]
function Timer.RemoveListRequest( ply, varArgs )
	-- Not that people will, but people might
	if not ply.RemovingTimes then
		return Core.Print( ply, "Admin", Core.Text( "MiscIllegalAccess" ) )
	end

	local nStyle = tonumber( varArgs[ 1 ] )
	local tabContent = varArgs[ 2 ]
	local szMap = varArgs[ 3 ]
	local nView = tonumber( varArgs[ 4 ] )

	if nView then
		if nView == 1 then
			Core.Ext( "Race", "RemoveItems" )( ply, nStyle, szMap )
		elseif nView == 2 then
			Core.Ext( "Stages", "RemoveTimes" )( ply, nStyle, tonumber( tabContent ), szMap )
		elseif nView == 4 then
			Core.Ext( "TAS", "RemoveTimes" )( ply, nStyle, szMap )
		elseif nView == 8 then
			Core.Ext( "Stats", "RemoveItems" )( ply, nStyle, szMap )
		end

		return
	end

	if not szMap then
		szMap = game.GetMap()
	end

	-- Delete the times
	local nAmount = #tabContent
	local bLocal = szMap == game.GetMap()
	local bMainBot = Core.Ext( "Bot", "DeleteFromTimes" )( tabContent, nStyle, bLocal )
	local bHistoryBot = Core.Ext( "Bot", "DeleteFromHistory" )( tabContent, nStyle, bLocal )

	-- Create the query
	local szQuery = "DELETE FROM game_times WHERE szMap = {0} AND nStyle = {1} AND ("
	local tabArg = { szMap, nStyle }

	-- Populate the tables
	for i = 1, nAmount do
		szQuery = szQuery .. "szUID = {" .. (i + 1) .. "} OR "
		tabArg[ #tabArg + 1 ] = tabContent[ i ].szUID
	end

	-- Execute it
	Prepare(
		string.sub( szQuery, 1, -4 ) .. ")",
		tabArg
	)( function( data, varArg )
		-- Check if it's the local map and not remote
		if bLocal then
			-- If local, reload everything
			Core.LoadRecords( function()
				local update = {}
				for _,p in pairs( player.GetHumans() ) do
					for i = 1, nAmount do
						-- Only reload their time if they match the style
						if p.UID == tabContent[ i ].szUID and p.Style == nStyle then
							update[ #update + 1 ] = p
							p:LoadTime( true )
						end
					end
				end

				ply:VarNet( "UpdateKeysEx", update, { "Record", "Position", "SpecialRank" } )
			end )
		end

		-- Inform the admin
		local info, str = {}, ""
		if bLocal then info[ #info + 1 ] = "All records have been reloaded" end
		if bMainBot then info[ #info + 1 ] = "Main bot deleted" end
		if bHistoryBot then info[ #info + 1 ] = "History bot deleted" end
		if #info > 0 then str = "[" .. string.Implode( "; ", info ) .. "]" end

		Core.Print( ply, "Admin", Core.Text( "AdminTimesRemoved", nAmount, str ) )
		Core.AddAdminLog( "Removed " .. nAmount .. " times on " .. szMap .. " (" .. Core.StyleName( nStyle ) .. ", " .. str .. ")", ply.UID, ply:Name() )
	end )
end
Core.Register( "Global/RemoveList", Timer.RemoveListRequest )

--[[
	Description: Sends the appropriate list to the player
	Notes: Houses Maps Left, Beat and My WR
--]]
function Core.HandlePlayerMaps( szID, ply, args )
	local nStyle, szUID = ply.Style
	if args and #args > 0 then
		if util.SteamIDTo64( args.Upper[ 1 ] ) != "0" then
			szUID = args.Upper[ 1 ]
		elseif szID == "Beat" or szID == "Left" then
			local szStyle = string.Implode( " ", args.Upper )
			local nGet = Core.GetStyleID( szStyle, true )

			if not Core.IsValidStyle( nGet ) then
				return Core.Print( ply, "General", Core.Text( "MiscInvalidStyle" ) )
			else
				nStyle = nGet
			end

			for i = 1, #args do
				if string.find( args[ i ], "steam", 1, true ) then
					local uid = util.SteamIDTo64( args.Upper[ i ] )
					if uid != "0" then
						szUID = args.Upper[ i ]
					end
				end
			end
		end
	end

	local IsRemote = szUID and szUID != ply.UID
	szUID = szUID or ply.UID

	if not BeatMaps[ szUID ] then
		BeatMaps[ szUID ] = {}
	end

	-- To-Do: This shouldn't happen for when we're viewing other player's stuff
	if ply.Bonus then
		nStyle = Core.MakeBonusStyle( nStyle, ply.Bonus )
	end

	if szID == "Beat" or szID == "Left" or szID == "NoWR" then
		local function ProceedDisplay()
			local count = BeatMaps[ szUID ][ nStyle ] and type( BeatMaps[ szUID ][ nStyle ] ) == "table" and #BeatMaps[ szUID ][ nStyle ] or -1
			if args and args.GetCount then
				if count < 0 then
					count = 0
				end

				return args.GetCount( count )
			end

			if szID == "NoWR" then
				if count <= 0 then
					return Core.Print( ply, "General", Core.Text( "CommandNoWRBeat", IsRemote and "This player hasn't" or "You haven't" ) )
				end

				local data, tab, cache = {}, BeatMaps[ szUID ][ nStyle ], WRTopCache[ szUID ] or {}
				for i = 1, #cache do
					for j = 1, count do
						if cache[ i ].nTime == tab[ j ].nTime then
							data[ #data + 1 ] = cache[ i ]
						end
					end
				end

				if #data == 0 then
					return Core.Print( ply, "General", Core.Text( "CommandNoWRNone", IsRemote and "This player doesn't" or "You don't" ) )
				elseif #data == (nStyle < 0 and Timer.BonusMaps or Timer.Maps) then
					return Core.Print( ply, "General", Core.Text( "CommandNoWRAll" .. (IsRemote and "Remote" or "") ) )
				end

				NetPrepare( "GUI/Build", {
					ID = "Maps",
					Title = "No WR maps on " .. Core.StyleName( nStyle ),
					X = 400,
					Y = 390,
					Mouse = true,
					Blur = true,
					Data = { data, Style = -1, Type = szID, Command = args.FullText, Version = Core.GetMaplistVersion() }
				} ):Send( ply )

				return false
			end

			if count < 0 then
				return Core.Print( ply, "General", szID == "Left" and Core.Text( "CommandWRLeftNone", IsRemote and "This player still needs" or "You still need" ) or Core.Text( "CommandWRBeatNone", IsRemote and "This player hasn't" or "You haven't" ) )
			elseif szID == "Left" and count == (nStyle < 0 and Timer.BonusMaps or Timer.Maps) then
				return Core.Print( ply, "General", Core.Text( "CommandWRLeftAll", IsRemote and "This player has" or "You have" ) )
			elseif szID == "Beat" and count == 0 then
				return Core.Print( ply, "General", Core.Text( "CommandWRLeftNone", IsRemote and "This player still needs" or "You still need" ) )
			end

			if count > 0 and count <= (nStyle < 0 and Timer.BonusMaps or Timer.Maps) then
				NetPrepare( "GUI/Build", {
					ID = "Maps",
					Title = "Maps " .. szID,
					X = 400 + (szID == "Beat" and 100 or 0),
					Y = 390,
					Mouse = true,
					Blur = true,
					Data = { BeatMaps[ szUID ][ nStyle ], Style = nStyle, Type = szID, Command = args.FullText, Version = Core.GetMaplistVersion() }
				} ):Send( ply )
			else
				Core.Print( ply, "General", Core.Text( "CommandWRListUnable", IsRemote and "the player hasn't" or "you haven't" ) )
			end
		end

		if not BeatMaps[ szUID ][ nStyle ] then
			BeatMaps[ szUID ][ nStyle ] = true

			Prepare(
				"SELECT szMap, nTime, nPoints, nDate FROM game_times WHERE szUID = {0} AND nStyle = {1} ORDER BY nPoints ASC",
				{ szUID, nStyle },
				{ UseOptions = true, RawFormat = true }
			)( function( data, varArg )
				if Core.Assert( data, "szMap" ) then
					local makeNum = tonumber
					for j = 1, #data do
						data[ j ]["nTime"] = makeNum( data[ j ]["nTime"] )
						data[ j ]["nPoints"] = makeNum( data[ j ]["nPoints"] )
						data[ j ]["nDate"] = makeNum( data[ j ]["nDate"] )
					end

					BeatMaps[ szUID ][ nStyle ] = data
				end

				ProceedDisplay()
			end )
		else
			ProceedDisplay()
		end
	elseif szID == "Mine" then
		if not BeatMaps[ szUID ][ 0 ] then
			BeatMaps[ szUID ][ 0 ] = true

			if WRTopCache[ szUID ] then
				BeatMaps[ szUID ][ 0 ] = WRTopCache[ szUID ]
			end
		end

		local count = BeatMaps[ szUID ][ 0 ] and type( BeatMaps[ szUID ][ 0 ] ) == "table" and #BeatMaps[ szUID ][ 0 ] or 0
		if count > 0 then
			NetPrepare( "GUI/Build", {
				ID = "Maps",
				Title = "#1 WRs (" .. count .. ")",
				X = 400,
				Y = 390,
				Mouse = true,
				Blur = true,
				Data = { BeatMaps[ szUID ][ 0 ], Style = 0, By = IsRemote and szUID }
			} ):Send( ply )
		else
			Core.Print( ply, "General", (IsRemote and "This player doesn't" or "You don't") .. " seem to have any #1 records" )
		end
	end
end

--[[
	Description: Get the keys pressed at the moment of request
	Notes: Used to see what keys to press when returning to a checkpoint with high velocity
--]]
function Timer.GetCheckpointKeys( ply )
	local szStr = ply:Crouching() and " C" or ""
	if ply:KeyDown( IN_MOVELEFT ) then
		szStr = szStr .. " A"
	elseif ply:KeyDown( IN_MOVERIGHT ) then
		szStr = szStr .. " D"
	end

	return szStr
end

--[[
	Description: The checkpoint request processing
--]]
function Timer.CheckpointRequest( ply, varArgs, IsForce )
	if not ply.Practice then return Core.Print( ply, "General", Core.Text( "TimerCheckpointMenuPractice" ) ) end
	if ply.CheckpointTeleport then return Core.Print( ply, "Timer", Core.Text( "TimerCheckpointWaiting" ) ) end

	local ID = varArgs[ 1 ]
	local IsDelay = varArgs[ 2 ]
	local IsDelete = varArgs[ 3 ]
	local IsWipe = varArgs[ 4 ]
	local IsFixedWrite = varArgs[ 5 ]
	local CanSave = true
	local Send = {}

	if not Checkpoints[ ply ] then
		Checkpoints[ ply ] = {}
	end

	-- This means load last loaded / load last saved
	if ID == 1 then
		ID = ply.LastCP
		CanSave, IsDelete, IsWipe = nil, nil, nil
	elseif ID == 2 then
		ID = ply.LastWriteCP
		CanSave, IsDelete, IsWipe = nil, nil, nil
	end

	-- Check if we're force writing
	if IsForce then
		local WriteAt = 3
		for i = 3, 9 do
			if not Checkpoints[ ply ][ i ] then
				WriteAt = i
				break
			end
		end

		ID = WriteAt
		Checkpoints[ ply ][ ID ] = nil

	-- Else find a valid ID
	elseif not ID then
		local IsAny
		for i = 3, 9 do
			if Checkpoints[ ply ][ i ] then
				IsAny = i
				break
			elseif IsFixedWrite then
				IsAny = i
				break
			end
		end

		if IsAny then
			ID = ply.LastCP or IsAny

			if not IsFixedWrite and (not ID or not Checkpoints[ ply ][ ID ]) then
				return Core.Print( ply, "Timer", Core.Text( "TimerCheckpointMissing" ) )
			end
		else
			return Core.Print( ply, "Timer", Core.Text( "TimerCheckpointLoadBlank" ) )
		end
	end

	if ID and IsFixedWrite then
		CanSave = true
	end

	-- If we have a checkpoint
	if Checkpoints[ ply ][ ID ] and not IsFixedWrite then
		if IsDelete then
			Checkpoints[ ply ][ ID ] = nil
			Send.Type = "Delete"
			Send.ID = ID
		elseif IsWipe then
			-- Iterate over all checkpoints
			for i = 3, 9 do
				Checkpoints[ ply ][ i ] = nil
			end

			-- Reset variables
			ply.LastCP = nil
			ply.LastWriteCP = nil

			Send.Type = "Wipe"
		else
			ply.LastCP = ID

			-- Setup the function
			local function MakeTeleport()
				if not IsValid( ply ) then return end
				if not ply.Practice or ply.Spectating then
					return Core.Print( ply, "General", Core.Text( "TimerCheckpointPractice" ) )
				end

				ply.CheckpointTeleport = nil

				local cp = Checkpoints[ ply ][ ply.LastCP ]
				ply:SetPos( cp[ 1 ] )
				ply:SetEyeAngles( cp[ 2 ] )
				ply:SetLocalVelocity( cp[ 3 ] )
			end

			if IsDelay then
				ply.CheckpointTeleport = true
				Send.Type = "Delay"

				timer.Simple( 1.5, MakeTeleport )
			else
				MakeTeleport()
			end
		end
	elseif CanSave then
		if IsDelete then
			Core.Print( ply, "Timer", Core.Text( "TimerCheckpointBlank" ) )
		elseif IsWipe then
			-- Iterate over all checkpoints
			for i = 3, 9 do
				Checkpoints[ ply ][ i ] = nil
			end

			-- Reset variables
			ply.LastCP = nil
			ply.LastWriteCP = nil

			Send.Type = "Wipe"
		else
			local pos, ang, vel = ply:GetPos(), ply:EyeAngles(), ply:GetVelocity()
			if ply.Spectating and IsValid( ply:GetObserverTarget() ) then
				local target = ply:GetObserverTarget()
				pos = target:GetPos()
				ang = target:EyeAngles()
				vel = target:GetVelocity()
			end

			Checkpoints[ ply ][ ID ] = { pos, ang, vel, ST() }
			Send.Type = "Add"
			Send.ID = ID
			Send.Details = string.format( "%.0f u/s%s", Checkpoints[ ply ][ ID ][ 3 ]:Length2D(), Timer.GetCheckpointKeys( ply ) )

			ply.LastWriteCP = ID
		end
	else
		return Core.Print( ply, "Timer", Core.Text( "TimerCheckpointLoadBlank" ) )
	end

	if Send.Type then
		Core.Send( ply, "GUI/UpdateCP", Send )
	end
end
Core.Register( "Global/Checkpoints", Timer.CheckpointRequest )

--[[
	Description: Handles the checkpoint commands
--]]
function Timer.CheckpointCommand( ply, args )
	-- Check if they're in practice mode or not
	if not ply.Practice and args.Key != "cphelp" then
		return Core.Print( ply, "General", Core.Text( "TimerCheckpointMenuPractice" ) )
	end

	-- Allocate them a spot in the checkpoint table
	if not Checkpoints[ ply ] then
		Checkpoints[ ply ] = {}
	end

	if args.Key == "cp" or args.Key == "cpmenu" then
		Core.Send( ply, "GUI/Create", { ID = "Checkpoints", Dimension = { x = 200, y = 332, px = 20 }, Args = { Title = "Checkpoint Menu" } } )
	elseif args.Key == "cpload" then
		Timer.CheckpointRequest( ply, {} )
	elseif args.Key == "cpsave" then
		Timer.CheckpointRequest( ply, {}, true )
	elseif args.Key == "cpset" then
		local ID = tonumber( args[ 1 ] )
		if not ID or ID < 3 or ID > 9 then
			Core.Print( ply, "Timer", Core.Text( "TimerCheckpointInvalidID" ) )
		else
			ply.LastCP = ID
			Core.Print( ply, "Timer", Core.Text( "TimerCheckpointManualSet", ID ) )
		end
	elseif args.Key == "cpwipe" or args.Key == "cpdelete" then
		local id
		if #args > 0 then
			id = tonumber( args[ 1 ] )
		end

		-- Iterate over all checkpoints
		for i = 3, 9 do
			if id == nil or id == i then
				Checkpoints[ ply ][ i ] = nil
			end
		end

		-- Reset variables
		if not id then
			ply.LastCP = nil
			ply.LastWriteCP = nil
		end

		Core.Send( ply, "GUI/UpdateCP", { Type = "Wipe", ID = id } )
	elseif args.Key == "cphelp" then
		Core.Print( ply, "General", Core.Text( "TimerCheckpointHelp" ) )
	end
end
Core.AddCmd( { "cp", "cpmenu", "cpload", "cpsave", "cpset", "cphelp", "cpwipe", "cpdelete" }, Timer.CheckpointCommand )

--[[
	Description: Loads everything we've got
--]]
function Core.LoadRecords( fPostTimes )
	-- Clean up Maps table for if it's a reload
	Maps = {}

	-- Reset map count
	Timer.Maps = 0
	Timer.BonusMaps = 0
	Timer.RealBonusMaps = 0

	-- Get config variables
	Timer.SamplePercentage = math.Clamp( Config.Var.GetInt( "AveragePercentage" ), 0, 1e10 )

	-- Set the base statistics variable
	Timer.BaseStatistics = { 0, 0 }

	-- Load all maps into the Maps table
	Prepare(
		"SELECT * FROM game_map ORDER BY szMap ASC",
		{ UseOptions = true, RawFormat = true }
	)( function( data, varArg )
		if Core.Assert( data, "szMap" ) then
			local makeNum, makeNull = tonumber, Core.Null
			for j = 1, #data do
				local map = data[ j ]["szMap"]
				data[ j ]["szMap"] = nil
				data[ j ]["nMultiplier"] = makeNum( makeNull( data[ j ]["nMultiplier"], 1 ) )
				data[ j ]["nBonusMultiplier"] = makeNull( data[ j ]["nBonusMultiplier"], 0 )
				data[ j ]["nPlays"] = makeNum( makeNull( data[ j ]["nPlays"], 0 ) )
				data[ j ]["nOptions"] = makeNum( makeNull( data[ j ]["nOptions"], 0 ) )
				data[ j ]["szDate"] = makeNull( data[ j ]["szDate"], "Unknown" )

				-- Check the bonus multiplier
				if data[ j ]["nBonusMultiplier"] != 0 then
					local nNum = makeNum( data[ j ]["nBonusMultiplier"] )
					if not nNum and string.find( data[ j ]["nBonusMultiplier"], " " ) then
						local szNums = string.Explode( " ", data[ j ]["nBonusMultiplier"] )
						for i = 1, #szNums do
							if string.find( szNums[ i ], ":", 1, true ) then
								local szSplit = string.Explode( ":", szNums[ i ] )
								szNums[ i ] = { makeNum( szSplit[ 2 ] ) }
							else
								szNums[ i ] = makeNum( szNums[ i ] ) or 0
								Timer.RealBonusMaps = Timer.RealBonusMaps + (szNums[ i ] > 0 and 1 or 0)
							end
						end

						data[ j ]["nBonusMultiplier"] = szNums
					else
						data[ j ]["nBonusMultiplier"] = nNum or 0
					end
				else
					data[ j ]["nBonusMultiplier"] = makeNum( data[ j ]["nBonusMultiplier"] )
				end

				-- Add the bonus count
				if makeNum( data[ j ]["nBonusMultiplier"] ) and data[ j ]["nBonusMultiplier"] > 0 then
					Timer.BonusMaps = Timer.BonusMaps + 1
					Timer.RealBonusMaps = Timer.RealBonusMaps + 1
				end

				-- Load tier and type for surf
				if Config.IsSurf then
					data[ j ]["nTier"] = makeNum( makeNull( data[ j ]["nTier"], 1 ) )
					data[ j ]["nType"] = makeNum( makeNull( data[ j ]["nType"], 0 ) )
				end

				-- Add the map and increment
				Maps[ map ] = data[ j ]
				Timer.Maps = Timer.Maps + 1

				if data[ j ]["nPlays"] > Timer.BaseStatistics[ 2 ] then
					Timer.BaseStatistics[ 2 ] = data[ j ]["nPlays"]
					Timer.BaseStatistics[ 3 ] = map
				end
			end

			Core.PrintC( "[Load] All " .. Timer.Maps .. " maps have been fetched from the database" )
		end

		-- Get the details for the current map
		local map = game.GetMap()
		if Maps[ map ] then
			Timer.Multiplier = Maps[ map ]["nMultiplier"] or 1
			Timer.BonusMultiplier = Maps[ map ]["nBonusMultiplier"] or 0
			Timer.Options = Maps[ map ]["nOptions"] or 0
			Timer.Plays = (Maps[ map ]["nPlays"] or 0) + 1
			Timer.Date = Maps[ map ]["szDate"] or ""

			-- Surf details
			Timer.Tier = Maps[ map ]["nTier"] or 1
			Timer.Type = Maps[ map ]["nType"] or 0
		else
			Timer.Multiplier = 1
			Timer.BonusMultiplier = 0
			Timer.Options = 0
			Timer.Plays = 0
			Timer.Date = ""

			-- Surf details
			Timer.Tier = 1
			Timer.Type = 0
		end

		-- Directly use the loaded options
		Zones.CheckOptions()

		-- Loads all ranks and the top list
		local parsed = table.Copy( Maps )
		Player.LoadRanks()

		-- Enable all extensions after map data is ready
		if not Timer.ExtensionsLoaded then
			Timer.ExtensionsLoaded = true

			for i = 1, #Timer.PostInitFunc do
				Timer.PostInitFunc[ i ]()
			end
		end

		-- When we're dealing with a new map, update its date
		if Timer.IsNewMap then
			Timer.IsNewMap = nil

			local szDate = Timer.GetCurrentDate( true )
			if Timer.Date == "" or Timer.Date == "Unknown" then
				Prepare(
					"UPDATE game_map SET szDate = {0} WHERE szMap = {1}",
					{ szDate, map }
				)( SQLVoid )

				Timer.Date = szDate

				if Maps[ map ] and Maps[ map ]["szDate"] then
					Maps[ map ]["szDate"] = szDate
				end
			end

			return false
		end

		-- Recalculate points for the most recent map
		Prepare(
			"SELECT szMap FROM game_map ORDER BY szDate DESC LIMIT 1"
		)( function( data, varArg )
			if Core.Assert( data, "szMap" ) then
				local map = data[ 1 ]["szMap"]
				Prepare(
					"SELECT nStyle, nTime FROM game_times WHERE szMap = {0} ORDER BY nTime",
					{ map }
				)( function( items, varArg )
					local sum, count, avg = {}, {}, {}
					local done, first = {}, {}
					if Core.Assert( items, "nStyle" ) then
						for i = 1, #items do
							local style = items[ i ]["nStyle"]
							if done[ style ] then continue end

							if not first[ style ] then
								first[ style ] = items[ i ]["nTime"] * (1 + Timer.SamplePercentage / 100)
								sum[ style ] = items[ i ]["nTime"]
								count[ style ] = 1
							else
								if items[ i ]["nTime"] > first[ style ] then
									avg[ style ] = sum[ style ] / count[ style ]
									done[ style ] = true
								else
									sum[ style ] = sum[ style ] + items[ i ]["nTime"]
									count[ style ] = count[ style ] + 1
									avg[ style ] = sum[ style ] / count[ style ]
								end
							end
						end

						-- Build all queries
						local entry, queries = parsed[ map ], {}
						for nStyle,nAverage in pairs( avg ) do
							local nMultiplier = 0
							if nStyle < Config.BonusStyle then
								local st,id = Core.GetBonusStyle( nStyle )
								if st != Styles.Normal then continue end

								if type( entry.nBonusMultiplier ) == "table" then
									nMultiplier = entry.nBonusMultiplier[ id ] or 0
								else
									nMultiplier = entry.nBonusMultiplier
								end
							else
								nMultiplier = entry.nMultiplier
							end

							-- Add the queries
							queries[ #queries + 1 ] = "UPDATE game_times SET nPoints = " .. nMultiplier .. " * (" .. nAverage .. " / nTime) WHERE szMap = {0} AND nStyle = {1}"
							queries[ #queries + 1 ] = { map, nStyle }

							queries[ #queries + 1 ] = "UPDATE game_times SET nPoints = " .. (nMultiplier / 4) .. " WHERE szMap = {0} AND nStyle = {1} AND nPoints < " .. (nMultiplier / 4)
							queries[ #queries + 1 ] = { map, nStyle }
						end

						-- Execute all queries
						Prepare( unpack( queries ) )( SQLVoid )
					end
				end )
			end

			-- Add a single play to the map
			if not Timer.AddedPlay then
				Timer.AddedPlay = true
				Prepare(
					"UPDATE game_map SET nPlays = nPlays + 1, szDate = {0} WHERE szMap = {1}",
					{ Timer.GetCurrentDate( true ), map }
				)( SQLVoid )
			end
		end )
	end )

	-- When we're dealing with a new map, cancel out loading the rest
	if Timer.IsNewMap then
		return false
	end

	-- If the table was populated, clean out everything
	for n,v in pairs( Records ) do
		if v and type( v ) != "table" then continue end
		Records[ n ] = {}
	end

	-- Pre-prepare all styles
	local StyleCounter = {}
	for _,n in pairs( Styles ) do
		if not Records[ n ] then
			Records[ n ] = {}
			StyleCounter[ n ] = 1
		end
	end

	-- Load all styles
	Prepare(
		"SELECT * FROM game_times WHERE szMap = {0} ORDER BY nTime ASC",
		{ game.GetMap() },
		{ UseOptions = true, RawFormat = true }
	)( function( data, varArg )
		if Core.Assert( data, "szUID" ) then
			local makeNum, makeNull, styleId = tonumber, Core.Null
			for j = 1, #data do
				styleId = makeNum( data[ j ]["nStyle"] )

				data[ j ]["szMap"] = nil
				data[ j ]["nStyle"] = nil
				data[ j ]["nTime"] = makeNum( data[ j ]["nTime"] )
				data[ j ]["nPoints"] = makeNum( data[ j ]["nPoints"] )
				data[ j ]["nDate"] = makeNum( data[ j ]["nDate"] ) or 0
				data[ j ]["vData"] = makeNull( data[ j ]["vData"] )

				if not Records[ styleId ] then Records[ styleId ] = {} end
				if not StyleCounter[ styleId ] then StyleCounter[ styleId ] = 1 end

				Records[ styleId ][ StyleCounter[ styleId ] ] = data[ j ]
				StyleCounter[ styleId ] = StyleCounter[ styleId ] + 1
			end

			Core.PrintC( "[Load] " .. #data .. " times have been cached" )
		end

		-- Load the statistics
		if not Timer.StatisticsSet then
			Timer.StatisticsSet = true

			-- Set the statistics value
			for _,value in pairs( StyleCounter ) do
				Timer.BaseStatistics[ 1 ] = Timer.BaseStatistics[ 1 ] + value - 1
			end

			-- Get the total amount of times on the server
			Prepare(
				"SELECT COUNT(nTime) AS nCount FROM game_times"
			)( function( data, varArg )
				if Core.Assert( data, "nCount" ) then
					Timer.BaseStatistics[ 4 ] = tonumber( data[ 1 ]["nCount"] ) or 0
				end
			end )

			-- Get command stats
			Timer.BaseStatistics[ 5 ], Timer.BaseStatistics[ 6 ] = Core.CountCommands()
		end

		-- Set all the #1 times for sending
		for style,_ in pairs( StyleCounter ) do
			Timer.ChangeTopTime( style, nil, true )
			CalcAverage( style )

			-- Get the current average time for Normal
			if style == Styles.Normal and Config.Var.GetBool( "VoteAdjust" ) then
				local add = GetAverage( style ) / 3 - 10
				local new = math.Clamp( 20 - add, 0, 20 ) * 60
				RTV.ChangeTime( math.ceil( (RTV.Length - new) / 60 ) )
			end
		end

		-- See if there's a callback
		if fPostTimes then
			fPostTimes()
		end
	end )

	-- Do the point sum caching
	if not Timer.PointsCached then
		Timer.PlayerCount = {}
		Timer.PlayerLadderPos = {}

		Prepare(
			"SELECT nStyle, szUID, SUM(nPoints) AS nSum FROM game_times WHERE szMap != {0} GROUP BY nStyle, szUID",
			{ game.GetMap() },
			{ UseOptions = true, RawFormat = true }
		)( function( data, varArg )
			local makeNum, out = tonumber, {}
			if Core.Assert( data, "nSum" ) then
				Timer.PointsCached = true

				for j = 1, #data do
					local nStyle = makeNum( data[ j ]["nStyle"] )
					if nStyle < Config.BonusStyle then
						local st,id = Core.GetBonusStyle( nStyle )
						if st != Styles.Normal then
							continue
						else
							nStyle = Core.MakeBonusStyle( st, 0 )
						end
					end

					if not StylePoints[ nStyle ] then
						StylePoints[ nStyle ] = {}
						out[ nStyle ] = {}
					end

					local pts = makeNum( data[ j ]["nSum"] ) or 0
					StylePoints[ nStyle ][ data[ j ]["szUID"] ] = pts
					out[ nStyle ][ #out[ nStyle ] + 1 ] = { UID = data[ j ]["szUID"], Pts = pts }
				end
			end

			for style,data in pairs( out ) do
				table.SortByMember( data, "Pts" )
				Timer.PlayerLadderPos[ style ] = {}

				for i = 1, #data do
					Timer.PlayerLadderPos[ style ][ data[ i ].UID ] = i
				end
			end

			local total, styles = 0, 0
			for style,data in pairs( StylePoints ) do
				total = total + table.Count( data )
				styles = styles + 1
			end

			Core.PrintC( "[Load] Assigned points per style for a total of " .. total .. " players spread out over " .. styles .. " styles" )
		end )

		Prepare(
			"SELECT nStyle, COUNT(DISTINCT(szUID)) AS nAmount FROM game_times GROUP BY nStyle"
		)( function( data, varArg )
			local makeNum = tonumber
			if Core.Assert( data, "nAmount" ) then
				for j = 1, #data do
					Timer.PlayerCount[ makeNum( data[ j ]["nStyle"] ) ] = makeNum( data[ j ]["nAmount"] ) or 0
				end
			end
		end )
	end

	-- Only do these things on first load
	if not RTV.Started then
		-- Remember a variable
		RTV.Started = true

		-- Starts the RTV instance
		RTV:Start()
	end
end




-- Player class
Player.TopListLimit = Config.Var.GetInt( "TopLimit" )
Player.RankScalars = {}

Player.AveragePoints = 1
Player.AveragePointsCache = {}
Player.NotifyCache = {}


--[[
	Description: Loads all ranks for each type of gameplay
--]]
function Player.LoadRanks()
	-- Get the total sum of points
	local NormalSum = 0
	for map,data in pairs( Maps ) do
		NormalSum = NormalSum + data["nMultiplier"]
	end

	-- If there's no maps, we still need to be able to calculate simple ranks, prints a message as well
	if NormalSum == 0 then
		Core.PrintC( "[Error] Ranking", "Couldn't calculate ranking scalar. Make sure you have at least ONE entry in your game_map!" )
	end

	-- Get the ranking scalars
	local Scalars = string.Explode( ",", Config.Var.Get( "RankScalars" ) )
	if #Scalars != Config.MaxStyle then
		Core.PrintC( "[Error] Ranking", "Missing rank scalar for a style. Make sure there are " .. Config.MaxStyle .. " scalars in the ConVar" )
	end

	-- Set this to one so we still have everyone at a rank
	if NormalSum == 0 then NormalSum = 1 end

	-- Set some local functionality
	local mp, c = math.pow, #Ranks
	local Exponential = function( c, n ) return c * mp( n, 2.9 ) end
	local FindScalar = function( s ) for i = 0, 50, 0.00001 do if Exponential( i, c ) > s then return i end end return 0 end

	-- Set blank scalars
	Player.RankScalars = {}

	-- Loop over each value and use it
	for i = 1, #Scalars do
		local Scalar = tonumber( Scalars[ i ] ) or 0
		Player.RankScalars[ i ] = FindScalar( NormalSum * Scalar )

		-- Generate additional columns for easy calculation on the rank list
		for j = 1, c do
			Ranks[ j ][ 3 ][ i ] = Exponential( Player.RankScalars[ i ], j )
		end
	end

	-- Show a debug message
	Core.PrintC( "[Load] " .. c .. " ranks have been scaled accordingly!" )

	-- Continue with loading the top lists when we're doing the first load
	if not Player.LoadedLists then
		Player.LoadTopLists()
		Player.LoadNotifyCache()
	end
end

--[[
	Description: Loads the full top list of players into a table
--]]
function Player.LoadTopLists()
	-- Get all styles to be ranked
	Prepare(
		"SELECT DISTINCT(nStyle) FROM game_times ORDER BY nStyle ASC"
	)( function( data, varArg )
		if Core.Assert( data, "nStyle" ) then
			Player.LoadedLists = true

			local queries, bonus = {}, {}
			for j = 1, #data do
				local style = tonumber( data[ j ]["nStyle"] )

				-- Check if bonus
				if style < Config.BonusStyle then
					if Core.GetBonusStyle( style ) == Styles.Normal then
						bonus[ #bonus + 1 ] = style

						-- And add a blank table
						if not TopListCache[ style ] then
							TopListCache[ style ] = {}
						end
					end

					continue
				end

				-- Create a blank table for this style
				if not TopListCache[ style ] then
					TopListCache[ style ] = {}
				end

				-- Add the query to the list
				queries[ #queries + 1 ] = "SELECT szUID, SUM(nPoints) AS nSum, COUNT(nTime) AS nBeat FROM game_times WHERE nStyle = {0} GROUP BY szUID ORDER BY nSum DESC LIMIT {1}"
				queries[ #queries + 1 ] = { style, Player.TopListLimit, VarObj = style }
			end

			-- Check the bonus ids
			if #bonus > 0 then
				-- Add the query to the list
				queries[ #queries + 1 ] = "SELECT szUID, SUM(nPoints) AS nSum, COUNT(nTime) AS nBeat FROM game_times WHERE nStyle = " .. string.Implode( " OR nStyle = ", bonus ) .. " GROUP BY szUID ORDER BY nSum DESC LIMIT {0}"
				queries[ #queries + 1 ] = { Player.TopListLimit, VarObj = Core.MakeBonusStyle( Styles.Normal, 0 ) }
			end

			-- Add the options
			queries[ #queries + 1 ] = { UseOptions = true, RawFormat = true }

			-- Get the top players for the selected style
			Prepare(
				unpack( queries )
			)( function( dataset, varArg )
				for i = 1, #dataset do
					local q = dataset[ i ]
					local style = dataset.Objects[ i ]

					if Core.Assert( q, "nSum" ) then
						local makeNum = tonumber
						for j = 1, #q do
							q[ j ]["nSum"] = makeNum( q[ j ]["nSum"] )
							q[ j ]["nLeft"] = (style < Config.BonusStyle and Timer.RealBonusMaps or Timer.Maps) - makeNum( q[ j ]["nBeat"] )

							-- Insert the entry to the total table
							TopListCache[ style ][ j ] = q[ j ]
						end
					end

					-- Check if there is any
					if TopListCache[ style ][ 1 ] and TopListCache[ style ][ 1 ].szUID then
						Timer.Top[ style ] = TopListCache[ style ][ 1 ].szUID
					end
				end
			end )
		end
	end )

	-- Fetch all #1 WRs for each map on each style
	Prepare(
		"SELECT * FROM (SELECT * FROM game_times ORDER BY nTime DESC) AS tSub GROUP BY szMap, nStyle ORDER BY nStyle ASC",
		{ UseOptions = true, RawFormat = true }
	)( function( data, varArg )
		-- Set a variable to track most WRs
		local TopWRTrack = {}
		Timer.TopWRPlayer = {}
		Timer.TopWRList = {}

		if Core.Assert( data, "nTime" ) then
			local makeNum = tonumber
			for j = 1, #data do
				local id = data[ j ]["szUID"]
				local count = 1

				if not WRTopCache[ id ] then
					WRTopCache[ id ] = {}
				else
					count = #WRTopCache[ id ] + 1
				end

				data[ j ]["szUID"] = nil
				data[ j ]["nStyle"] = makeNum( data[ j ]["nStyle"] )
				data[ j ]["nTime"] = makeNum( data[ j ]["nTime"] )
				data[ j ]["nPoints"] = makeNum( data[ j ]["nPoints"] )
				data[ j ]["nDate"] = makeNum( data[ j ]["nDate"] )

				local style = data[ j ]["nStyle"]
				if not TopWRTrack[ style ] then
					TopWRTrack[ style ] = {}
				end

				TopWRTrack[ style ][ id ] = (TopWRTrack[ style ][ id ] or 0) + 1

				-- Insert the entry to the total table
				WRTopCache[ id ][ count ] = data[ j ]
			end
		end

		-- Compute the top WR players
		for style,tab in pairs( TopWRTrack ) do
			local topn, topu = 0

			-- Loop over all data
			for uid,count in pairs( tab ) do
				if count > topn then
					topn = count
					topu = uid
				end
			end

			-- Set the top WR player for the style
			Timer.TopWRPlayer[ style ] = topu
		end

		-- Copy over the tracking list for further usage
		Timer.TopWRList = TopWRTrack
	end )

	-- Compute data for total rank
	Prepare(
		"SELECT AVG(nPoints) AS nPoints FROM game_times"
	)( function( data, varArg )
		if Core.Assert( data, "nPoints" ) then
			Player.AveragePoints = tonumber( data[ 1 ]["nPoints"] ) or 1
		end
	end )
end

--[[
	Description: Loads the WR beaten notifications
--]]
function Player.LoadNotifyCache()
	-- Determine the maximum age
	local nThreshold = os.time() - (3600 * 24 * 14)

	-- Delete all old entries
	Prepare(
		"DELETE FROM game_notifications WHERE nDate < {0}",
		{ nThreshold }
	)( SQLVoid )

	-- Fetch all valid notifications
	Prepare(
		"SELECT * FROM game_notifications"
	)( function( data, varArg )
		local count = 0
		if Core.Assert( data, "szUID" ) then
			count = #data

			for j = 1, #data do
				local id = data[ j ]["szUID"]
				if not Player.NotifyCache[ id ] then
					Player.NotifyCache[ id ] = {}
				end

				table.insert( Player.NotifyCache[ id ], data[ j ] )
			end
		end

		Core.PrintC( "[Load] Loaded all top lists and time notifications (" .. count .. " messages still stored)" )
	end )
end


--[[
	Description: Loads the player's rank according to their points
--]]
function PLAYER:LoadTime( bNoReload, bPractice )
	-- For practice mode we don't really have to load a time
	if self.Practice then
		self.Record = 0
		self.Leaderboard = 0

		self:VarNet( "Set", "Record", self.Record )
		self:VarNet( "Set", "Position", self.Leaderboard )

		-- Only when it's actually changed
		local send = { "Record", "Position" }
		if self.SpecialRank and self.SpecialRank != 0 then
			self.SpecialRank = 0
			self:VarNet( "Set", "SpecialRank", self.SpecialRank )

			send[ #send + 1 ] = "SpecialRank"
		end

		-- Send the record
		local ar = NetPrepare( "Timer/Record" )
		ar:Double( self.Record )

		ar:Bit( true )
		ar:UInt( self.Style, 8 )
		ar:UInt( self.Bonus and self.Bonus + 1 or 0, 4 )
		ar:Bit( not not bPractice )

		ar:Send( self )

		-- Broadcast variables
		if not bNoReload then
			self:VarNet( "UpdateKeys", send )
		else
			return true
		end

		return false
	end

	-- For TAS, we direct it elsewhere
	if self.TAS then return self.TAS.LoadTime( self, self.Style ) end

	-- Obtain their position in the ladder for their style
	local t, r = Timer.GetPlayerRecord( self )
	self.Record = t
	self.Leaderboard = r

	self:VarNet( "Set", "Record", self.Record )
	self:VarNet( "Set", "Position", self.Leaderboard )

	-- Send the data for fast GUI drawing
	local ar = NetPrepare( "Timer/Record" )
	ar:Double( self.Record )

	ar:Bit( true )
	ar:UInt( self.Style, 8 )
	ar:UInt( self.Bonus and self.Bonus + 1 or 0, 4 )
	ar:Bit( false )

	ar:Send( self )

	-- For the top 3, give them a medal
	if r <= 3 then
		Player.SetRankMedal( self, r )
	elseif self.SpecialRank and self.SpecialRank != 0 then
		self.SpecialRank = 0
		self:VarNet( "Set", "SpecialRank", self.SpecialRank )
	end

	-- And broadcast
	if not bNoReload then
		self:VarNet( "UpdateKeys", { "Record", "Position", "SpecialRank" } )
	else
		return true
	end
end

--[[
	Description: Loads the player's rank according to their points
--]]
function PLAYER:LoadRank( bNoReload, bJoin )
	-- On the first join, give them the scalars
	if bJoin then
		local ar = NetPrepare( "Timer/Ranks" )
		ar:UInt( #Player.RankScalars, 5 )

		for i = 1, #Player.RankScalars do
			ar:Double( Player.RankScalars[ i ] )
		end

		ar:Send( self )

		Core.PrintC( "[Load] Player data for " .. self:Name() .. " retrieved from the database" )
	end

	-- When on Practice, we reset all data
	if self.Practice then
		self.Rank = -10
		self.SubRank = 0

		self:VarNet( "Set", "Rank", self.Rank )
		self:VarNet( "Set", "SubRank", self.SubRank )

		self.CurrentPointSum = 0
		self.CurrentMapSum = 0

		if not bNoReload then
			self:VarNet( "UpdateKeys", { "Rank", "SubRank" } )
		else
			return true
		end
	else
		-- For TAS, we direct it elsewhere
		if self.TAS then return self.TAS.LoadRank( self, true ) end

		-- Obtain the data from the cache and database
		return Player.GetPointSum( self, self.Style, bJoin, function( ply, Points, MapPoints, PostFetch )
			-- Only update if the whole rank is actually different
			local Rank = Player.GetRank( Points, ply.Style )
			if Rank != ply.Rank then
				ply.Rank = Rank
				ply:VarNet( "Set", "Rank", ply.Rank )
			end

			-- Set the current values for later usage
			ply.CurrentPointSum = Points
			ply.CurrentMapSum = MapPoints

			-- Set the sub rank
			Player.SetSubRank( ply, Rank, Points )

			-- Broadcast changes
			if PostFetch or not bNoReload then
				ply:VarNet( "UpdateKeys", { "Rank", "SubRank" } )
			else
				return true
			end
		end )
	end
end

--[[
	Description: Loads the player into a new style and sets the appropriate values
--]]
function PLAYER:LoadStyle( nStyle, bReload )
	-- Validate the style again
	if not nStyle or (nStyle < Styles.Normal and not Config.Modes[ nStyle ]) or nStyle > Config.MaxStyle then return end

	-- Check their current style
	if nStyle == self.Style and not bReload then
		local add = ""
		if self.Practice then
			add = " (Type !p again to leave practice mode)"
		elseif self.TAS then
			add = Core.Text( "TASChangeStyleExit" )
		end

		return Core.Print( self, "Timer", Core.Text( "StyleEqual", Core.StyleName( self.Style ), add ) )
	end

	-- Set the style variables
	local OldStyle, PreviousStyle, NextPractice = self.Style, self.Style
	if nStyle == Config.PracticeStyle then
		if not self.Practice then
			-- Clean the bot, of course
			Core.Ext( "Bot", "CleanPlayer" )( self )
			Core.Ext( "Bot", "SetPlayerActive" )( self )

			-- Set the style to the style we were on at first
			self.Style = OldStyle
			self:VarNet( "Set", "Style", self.Style )

			-- Enable practice mode on server and client
			self.Practice = true
			OldStyle = true
		else
			-- Set the style to the style we were on
			self.Style = OldStyle
			self:VarNet( "Set", "Style", self.Style )

			-- Disable the practice mode and update client
			self.Practice = nil
			OldStyle = nil
			NextPractice = true
		end
	else
		if self.Practice then
			-- Send a message about practice mode
			Core.Print( self, "Timer", Core.Text( "StylePracticeEnabled" ) )

			-- Make sure we're good with the styles
			self.Style = nStyle
			self:VarNet( "Set", "Style", self.Style )

			-- Update on the client (just a double measure)
			OldStyle = true
		else
			-- Set the styles
			self.Style = nStyle
			self:VarNet( "Set", "Style", self.Style )

			-- Make sure we change style normally
			OldStyle = nil
		end
	end

	if not OldStyle then
		-- Reset without copying function addresses
		concommand.Run( self, "reset", "bypass", "" )
	end

	-- Reset attributes
	ResetPlayerAttributes( self, PreviousStyle )

	-- Now loads the actual values in
	self:LoadTime( true, OldStyle )
	self:LoadRank( true )

	-- Publish all variable changes
	self:VarNet( "UpdateKeys", { "Style", "Bonus", "Record", "Position", "SpecialRank", "Rank", "SubRank" } )

	-- Let them know what happened
	local PracticeText = ""
	if OldStyle == true then
		PracticeText = " (With practice mode enabled)"
	elseif NextPractice then
		PracticeText = " (Disabled practice mode)"
	end

	Core.Print( self, "Timer", Core.Text( "StyleChange", Core.StyleName( self.Style ), PracticeText ) )
end

--[[
	Description: Loads the player bonuses
--]]
function PLAYER:LoadBonus( id )
	-- Check if we have a valid bonus
	if not Core.GetBonusPoint( id ) then
		return Core.Print( self, "Timer", Core.Text( "BonusNone", id > 0 and " for this ID." or "" ) )
	end

	-- See if we're already in bonus
	if self.Bonus then
		if self.Bonus == id then
			-- Reset variables
			self.Bonus = nil
			self:VarNet( "Set", "Bonus", 0 )

			-- Send a message
			Core.Print( self, "Timer", Core.Text( "BonusToggle", "left", "" ) )

			-- Load their style back
			return self:LoadStyle( self.Style, true )
		else
			-- Set the bonus id
			self.Bonus = id
			self:VarNet( "Set", "Bonus", self.Bonus + 1 )

			-- Send a message
			Core.Print( self, "Timer", Core.Text( "BonusToggle", "changed your", " (ID: " .. (self.Bonus + 1) .. ")" ) )
		end
	else
		-- Set the bonus id
		self.Bonus = id
		self:VarNet( "Set", "Bonus", self.Bonus + 1 )

		-- Send a message
		Core.Print( self, "Timer", Core.Text( "BonusToggle", "entered", " (ID: " .. (self.Bonus + 1) .. ")" ) )
	end

	-- Reset
	concommand.Run( self, "reset", "bypass", "" )

	-- Load rank and time
	self:LoadTime( true )
	self:LoadRank( true )

	-- Publish all variable changes
	self:VarNet( "UpdateKeys", { "Style", "Bonus", "Record", "Position", "SpecialRank", "Rank", "SubRank" } )
end


--[[
	Description: Gets the amount of points you have in a specific style
--]]
function Player.GetPointSum( ply, nStyle, bJoin, fCall )
	-- Check if the player is on bonus
	if ply.Bonus then
		if nStyle != Styles.Normal then
			return fCall( ply, 0, 0 )
		else
			nStyle = Core.MakeBonusStyle( nStyle, 0 )
		end
	end

	-- Fetch the data
	if (not StylePoints[ nStyle ] or not StylePoints[ nStyle ][ ply.UID ]) and not bJoin then
		Prepare(
			"SELECT SUM(nPoints) AS nSum FROM game_times WHERE szUID = {0} AND nStyle = {1} AND szMap != {2}",
			{ ply.UID, nStyle, game.GetMap() }
		)( function( data, varArg )
			local OtherPoints = 0
			if Core.Assert( data, "nSum" ) then
				OtherPoints = tonumber( data[ 1 ]["nSum"] ) or 0

				if StylePoints[ nStyle ] then
					StylePoints[ nStyle ][ ply.UID ] = OtherPoints
				end
			end

			local MapPoints = Timer.GetPointsForMap( ply, ply.Record, nStyle )
			fCall( ply, OtherPoints + MapPoints, MapPoints, true )
		end )
	else
		local MapPoints = Timer.GetPointsForMap( ply, ply.Record, nStyle )
		return fCall( ply, (StylePoints[ nStyle ] and StylePoints[ nStyle ][ ply.UID ] or 0) + MapPoints, MapPoints )
	end
end

--[[
	Description: Gets your rank using a given amount of points against a certain ladder type
--]]
function Player.GetRank( nPoints, nStyle )
	local Rank = 1

	for i = 1, #Ranks do
		if i > Rank and nPoints >= Player.GetPointsAtRank( i, nStyle ) then
			Rank = i
		end
	end

	return Rank
end

--[[
	Description: Gets the amount of points at a rank for a given style
--]]
function Player.GetPointsAtRank( id, nStyle, nVal )
	if nStyle < Config.BonusStyle then return 1e10 end
	return Ranks[ id ][ 3 ][ nStyle ] or nVal or 1e10
end

--[[
	Description: Gets a player's estimated rank progress
--]]
function Player.GetRankProgress( ply, nPoints, nNew )
	-- Get boundaries on rank
	if ply.Bonus then return 0 end
	if ply.Rank >= #Ranks then return 100, ply.Style == Styles.Normal and 11 or 12 end
	local nBottom = Player.GetPointsAtRank( ply.Rank, ply.Style, 0 )
	local nTop = Player.GetPointsAtRank( ply.Rank + 1, ply.Style, 1 )

	-- Get new player points
	nPoints = nPoints or (StylePoints[ ply.Style ] and StylePoints[ ply.Style ][ ply.UID ] or 0)
	nPoints = nPoints + (nNew or 0)

	-- Return the progress
	return math.Clamp( (nPoints - nBottom) / (nTop - nBottom) * 100, 0, 100 )
end

--[[
	Description: Reloads the rank and sub rank on all relevant players
--]]
function Player.SetSubRank( ply, nRank, nPoints )
	-- Check if the player is the one with most WRs
	local nTarget
	if Timer.TopWRPlayer[ ply.Style ] == ply.UID then
		nTarget = ply.Style == Styles.Normal and 3 or 1
	else
		local style = ply.Bonus and Core.MakeBonusStyle( ply.Style, 0 ) or ply.Style
		nTarget = Timer.Top[ style ] == ply.UID and 2
	end

	-- Sets it to the custom rank icons
	if ply.SubGlow != nTarget then
		ply.SubGlow = nTarget
		ply:VarNet( "Set", "SubGlow", ply.SubGlow or 0, true )
	end

	-- Only change sub rank if it's different
	local nProgress, nMax = Player.GetRankProgress( ply, nPoints )
	local nOut = nMax or math.Clamp( math.Round( nProgress / 10 ), 1, 10 )
	if ply.SubRank != nOut then
		ply.SubRank = nOut
		ply:VarNet( "Set", "SubRank", ply.SubRank )
	end
end

--[[
	Description: Reloads the rank and sub rank on all relevant players
--]]
function Player.ReloadRanks( sender, nStyle, nOldAverage )
	-- Get the multiplier for the given style
	local nMultiplier = Timer.GetMultiplier( nStyle )
	if nMultiplier == 0 then return end
	if nStyle < 0 and Core.GetBonusStyle( nStyle ) != Styles.Normal then return end

	-- Create a new table for changed players
	local update = {}

	-- Get the new average
	local nAverage = GetAverage( nStyle )
	for _,p in pairs( player.GetHumans() ) do
		-- Only reload for relevant players
		if p == sender or p.Style != nStyle or p.Record == 0 or (nStyle < 0 and not p.Bonus) or not p.CurrentPointSum then continue end

		local CurrentPoints = Timer.GetPointsForMap( p, p.Record, nStyle, nOldAverage )
		local NewPoints = Timer.GetPointsForMap( p, p.Record, nStyle, nAverage )
		local Points = p.CurrentPointSum - CurrentPoints + NewPoints

		local Rank = Player.GetRank( Points, p.Style )
		if Rank != p.Rank then
			p.Rank = Rank
			p:VarNet( "Set", "Rank", p.Rank )
		end

		-- Set the new sum for future reloads
		p.CurrentPointSum = Points

		-- Also reload their sub rank
		Player.SetSubRank( p, p.Rank, p.CurrentPointSum )

		-- Get their new leaderboard id
		local t, r = Timer.GetPlayerRecord( p )
		if r != p.Leaderboard then
			p.Leaderboard = r
			p:VarNet( "Set", "Position", p.Leaderboard )
		end

		-- Add this player to the broadcast list
		update[ #update + 1 ] = p
	end

	-- Reload call from sender
	sender:VarNet( "UpdateKeysEx", update, { "Rank", "SubRank", "Position" } )
end

--[[
	Description: Sets the player's medal
--]]
function Player.SetRankMedal( ply, nPos, bReload )
	if not bReload then
		ply.SpecialRank = nPos
		ply:VarNet( "Set", "SpecialRank", ply.SpecialRank )
	else
		 -- Gets the top 3 steam ids
		local nStyle, nBonus = ply.Style, ply.Bonus
		if nBonus then
			nStyle = Core.MakeBonusStyle( nStyle, nBonus )
		end

		local list = Timer.GetTopSteam( nStyle, 3 )
		local function HasValue( tab, v )
			for i = 1, #tab do
				if tab[ i ] == v then
					return i
				end
			end
		end

		local update = {}
		for _,p in pairs( player.GetHumans() ) do
			if nBonus and not p.Bonus then continue end
			if p.Style != ply.Style then continue end
			local AtID = HasValue( list, p.UID )
			if AtID then
				p.SpecialRank = AtID
				p:VarNet( "Set", "SpecialRank", p.SpecialRank )

				update[ #update + 1 ] = p
			elseif p.SpecialRank and p.SpecialRank != 0 then
				p.SpecialRank = 0
				p:VarNet( "Set", "SpecialRank", p.SpecialRank )

				update[ #update + 1 ] = p
			end
		end

		ply:VarNet( "UpdateKeysEx", update, { "SpecialRank" } )
	end
end

--[[
	Description: Gets the details of a player and returns it to the requesting player
--]]
function Player.ReceiveScoreboard( ply, varArgs )
	local id, target = varArgs[ 1 ]
	for _,p in pairs( player.GetHumans() ) do
		if p.UID == id then
			target = p
			break
		end
	end

	if IsValid( target ) then
		local tab = { WRs = Timer.GetPlayerWRs( target.UID, target.Style ) }
		tab.Target = target.UID
		tab.Online = target.ConnectedAt and ST() - target.ConnectedAt or 0
		tab.Timer = (target.TimerBonus and not target.TimerBonusFinish) and ST() - target.TimerBonus or ((target.TimerNormal and not target.TimerNormalFinish) and ST() - target.TimerNormal or -1) or -1
		tab.Stage = Core.Ext( "Stages", "GetStageID" )( target )
		tab.TAS = target.TAS and (target.TAS.GetTimer( target ) or 0)

		local function ProceedDisplay()
			local nStyle = target.Bonus and target.Style == Styles.Normal and Core.MakeBonusStyle( target.Style, target.Bonus ) or target.Style
			tab.TotalRank = math.Round( (Player.AveragePointsCache[ target ] / Player.AveragePoints) * 100.0, 1 )
			tab.MapPoints = { math.Round( Timer.GetPointsForMap( target, target.Record, nStyle ), 2 ), Timer.GetMultiplier( nStyle ) }

			Core.HandlePlayerMaps( "Beat", target, { GetCount = function( count )
				tab.MapsBeat = count
				Core.Send( ply, "GUI/Scoreboard", tab )
			end } )
		end

		-- Fetch the average points
		if not Player.AveragePointsCache[ target ] then
			Prepare(
				"SELECT AVG(nPoints) AS nPoints FROM game_times WHERE szUID = {0}",
				{ target:SteamID() }
			)( function( data, varArg )
				if Core.Assert( data, "nPoints" ) then
					Player.AveragePointsCache[ target ] = tonumber( data[ 1 ]["nPoints"] ) or 0
				else
					Player.AveragePointsCache[ target ] = 0
				end

				ProceedDisplay()
			end )
		else
			ProceedDisplay()
		end
	end
end
Core.Register( "Global/Scoreboard", Player.ReceiveScoreboard )

--[[
	Description: Gets geographic location of the IP
--]]
function Player.GetGeoLocation( ply, ip, callback )
	if not ip then
		return callback()
	end

	if not Player.GeoLocations then
		Player.GeoLocations = {}
	end

	if not Player.GeoLocations[ ip ] then
		Core.Print( ply, "General", Core.Text( "CommandProfileFetching" ) )

		http.Fetch(
			"http://www.geoplugin.net/json.gp?ip=" .. ip,
			function( body )
				local json = util.JSONToTable( body ) or {}
				if json.geoplugin_countryCode and json.geoplugin_countryName and json.geoplugin_countryCode != "" then
					Player.GeoLocations[ json.geoplugin_request ] = { Code = json.geoplugin_countryCode, Name = json.geoplugin_countryName }
					return callback( Player.GeoLocations[ json.geoplugin_request ] )
				end

				callback()
			end,
			function()
				callback()
			end
		)
	else
		callback( Player.GeoLocations[ ip ] )
	end
end

--[[
	Description: Shows the target player information on the given player
--]]
function Player.ShowProfile( ply, steam, ip )
	if ply.FetchingProfile then
		return Core.Print( ply, "General", Core.Text( "CommandProfileBusy" ) )
	end

	ply.FetchingProfile = true

	Player.GetGeoLocation( ply, ip, function( loc )
		local tab = {}
		tab.Style = ply.Style
		tab.Steam = steam
		tab.Location = loc and loc.Name

		local wrs = Timer.GetPlayerWRs( steam, nil, true )
		local sortable = {}

		for style,count in pairs( wrs.Rest or {} ) do
			sortable[ #sortable + 1 ] = { Style = style, Count = count }
		end

		tab.WRs = wrs[ 1 ]
		table.SortByMember( sortable, "Count" )

		if #sortable > 0 then
			tab.PrimeWR = {}

			for i = 1, #sortable do
				tab.PrimeWR[ i ] = { Core.StyleName( sortable[ i ].Style ), sortable[ i ].Count }
			end
		end

		tab.Points = {}
		tab.TopPoints = {}
		tab.PlayerPos = {}
		tab.Players = Timer.PlayerCount or {}
		tab.MapsTotal = ply.Bonus and Timer.BonusMaps or Timer.Maps

		for style,data in pairs( Timer.PlayerLadderPos ) do
			tab.PlayerPos[ style ] = data[ steam ] or 0
		end

		for style,data in pairs( TopListCache ) do
			if data[ 1 ] and data[ 1 ]["nSum"] then
				tab.TopPoints[ style ] = data[ 1 ]["nSum"]
			end
		end

		Core.HandlePlayerMaps( "Beat", { UID = steam, Style = tab.Style }, { "Filler", Upper = { steam }, GetCount = function( count )
			tab.MapsBeat = count

			Prepare(
				"SELECT nStyle, SUM(nPoints) AS nSum FROM game_times WHERE szUID = {0} GROUP BY nStyle",
				{ steam },

				"SELECT COUNT(szMap) AS nCount FROM game_stagetimes WHERE szUID = {0} AND nStyle = {1}",
				{ steam, tab.Style },

				"SELECT szMap, nStyle, nTime, nDate FROM game_times WHERE szUID = {0} ORDER BY nDate DESC LIMIT 10",
				{ steam }
			)( function( data, varArg )
				data = data or {}

				local q1, q2, q3 = data[ 1 ], data[ 2 ], data[ 3 ]
				if Core.Assert( q1, "nSum" ) then
					for j = 1, #q1 do
						local style = tonumber( q1[ j ]["nStyle"] )
						local points = tonumber( q1[ j ]["nSum"] ) or 0

						-- To-Do: Figure out how to display Bonus here
						--[[
						if Core.IsValidBonus( style ) then
							tab.Points[ Styles.Bonus ] = (tab.Points[ Styles.Bonus ] or 0) + points
						else
							tab.Points[ style ] = points
						end
						]]

						tab.Points[ style ] = points
					end
				end

				if Core.Assert( q2, "nCount" ) then
					tab.CPRs = tonumber( q2[ 1 ]["nCount"] ) or 0
				end

				if Core.Assert( q3, "nDate" ) then
					tab.Recent = q3
				end

				Core.Send( ply, "GUI/Create", { ID = "Profile", Dimension = { x = 200, y = 100, px = 20 }, Args = { Title = "Player Profile", Custom = tab } } )
				ply.FetchingProfile = nil
			end )
		end } )
	end )
end
Core.ShowProfile = Player.ShowProfile

--[[
	Description: Handles a player's full connection
--]]
function Player.ReceiveEntry( ply, varArgs )
	-- Make sure the player also receives all player data
	ply:VarNet( "Initial" )

	-- Make sure the player knows the time
	RTV.SendTimeLeft( ply )

	-- Sending the platforms
	Zones.SendPlatforms( ply )

	-- Check all boolean settings
	if varArgs.Simple then concommand.Run( ply, Core.CVar( "set_simple" ), "bypass", "" ) end
	if varArgs.Sync then concommand.Run( ply, Core.CVar( "set_sync" ), "bypass", "" ) end
	if varArgs.Third then concommand.Run( ply, Core.CVar( "set_third" ), "bypass", "" ) end
	if varArgs.Twitch then concommand.Run( ply, Core.CVar( "set_twitch" ), "bypass", "" ) end
	if varArgs.Model then concommand.Run( ply, Core.CVar( "set_model" ), { varArgs.Model, true, Player.ChangeModel }, "" ) end

	-- Settings with local handlers
	if varArgs.Kick then Core.GetCmd( "remainingtries" )( ply, { "time", varArgs.Kick, Key = "remainingtries" } ) end

	-- Check if there's a custom style to be applied
	if ply.CustomStyleFunc then
		ply:CustomStyleFunc()
	elseif varArgs.Style then
		if tonumber( varArgs.Style ) and ply.Style != varArgs.Style then
			concommand.Run( ply, "style", tostring( varArgs.Style ), "" )
		end
	end

	-- Check if something went wrong with the RTV system
	if ST() > RTV.End and (timer.TimeLeft( RTV.Identifier ) or 0) > 30 * 60 and not RTV.ResetBreak then
		RTV.ResetBreak = true
		RTV:ResetVote( "Yes", 1, false, "VoteFailure" )
	end
end
Core.Register( "Global/Entry", Player.ReceiveEntry )

--[[
	Description: Sets the sync state of the player
--]]
function Player.ChangePermSync( ply, cmd, args )
	if args == "bypass" then args = { 1 } elseif not Core.CanExecuteCommand( ply ) then return end
	Core.Ext( "SMgr", "ToggleSyncState" )( ply, tonumber( args[ 1 ] ) == 1 )
end
concommand.Add( Core.CVar( "set_sync" ), Player.ChangePermSync )

--[[
	Description: Receives whether or not the user is using the simple HUD
--]]
function Player.ChangeSimple( ply, cmd, args )
	if args == "bypass" then args = { 1 } elseif not Core.CanExecuteCommand( ply ) then return end
	Core.Ext( "SMgr", "SetSimple" )( ply, tonumber( args[ 1 ] ) == 1 )
end
concommand.Add( Core.CVar( "set_simple" ), ReceiveSimple )

--[[
	Description: Changes the third person state on the player
--]]
function Player.ChangeThirdperson( ply, cmd, args )
	if args == "bypass" then args = { 1 } elseif not Core.CanExecuteCommand( ply ) then return end
	GAMEMODE:ShowSpare1( ply, tonumber( args[ 1 ] ) == 1 )
end
concommand.Add( Core.CVar( "set_third" ), Player.ChangeThirdperson )

--[[
	Description: Changes the model of the player according to the input
--]]
function Player.ChangeModel( ply, cmd, args )
	if args[ 3 ] != Player.ChangeModel and not Core.CanExecuteCommand( ply ) then return end
	Core.GetCmd( "model" )( ply, { args[ 1 ], SkipMessage = args[ 2 ] } )
end
concommand.Add( Core.CVar( "set_model" ), Player.ChangeModel )

--[[
	Description: Calls the help command via console command for no delay
--]]
function Player.RequestHelp( ply, cmd, args )
	if ply.HelpReceived then return end
	Core.GetCmd( "help" )( ply, {} )
end
concommand.Add( Core.CVar( "ask_help" ), Player.RequestHelp )

--[[
	Description: Prints any type of message as a replacement to the regular notifications that used to be in place
--]]
function Player.Notification( ply, szType, details )
	local colors = Config.Colors

	if szType == "BaseFinish" then
		local viewers = ply:Spectator( "Get", { true } )
		local szMessage = Core.ColorText()
		local szMessageRemote = Core.ColorText()

		if ply.Bonus then
			szMessage:Add( "You finished bonus [" )
			szMessage:Add( "Bonus " .. (ply.Bonus + 1), colors[ 1 ], true )
			szMessage:Add( "]" )

			if ply.Style > Styles.Normal then
				szMessage:Add( " on " .. Core.StyleName( ply.Style ), colors[ 4 ], true )
			end

			szMessage:Add( " in " )
			szMessage:Add( Timer.Convert( details.Time ), colors[ 2 ], true )

			if details.Difference != "" then
				szMessage:Add( " (" )
				szMessage:Add( details.Difference, colors[ 1 ], true )
				szMessage:Add( ")" )
			end

			if #viewers > 0 then
				szMessageRemote:Copy( szMessage )
				szMessageRemote:Replace( 1, 4, ply:Name(), colors[ 1 ], true )
				szMessageRemote:Add( " (" .. details.Jumps .. " jumps, " .. details.Strafes .. " strafes with " .. details.Sync .. "% sync)" )
			end
		else
			szMessage:Add( "You finished" )

			if ply.Style > Styles.Normal then
				szMessage:Add( " " .. Core.StyleName( ply.Style ), colors[ 4 ], true )
			end

			szMessage:Add( " in " )
			szMessage:Add( Timer.Convert( details.Time ), colors[ 2 ], true )

			if details.Difference != "" then
				szMessage:Add( " (" )
				szMessage:Add( details.Difference, colors[ 1 ], true )
				szMessage:Add( ")" )
			end

			if #viewers > 0 then
				szMessageRemote:Copy( szMessage )
				szMessageRemote:Replace( 1, 4, ply:Name(), colors[ 1 ], true )
				szMessageRemote:Add( " (" .. details.Jumps .. " jumps, " .. details.Strafes .. " strafes with " .. details.Sync .. "% sync)" )
			end
		end

		local ar = NetPrepare( "Timer/Finish" )
		ar:Double( details.Time )
		ar:UInt( details.Jumps, 16 )
		ar:UInt( details.Strafes, 16 )
		ar:Double( details.Sync )

		if details.Points then
			ar:Bit( true )
			ar:Double( details.Points )
			ar:Double( details.Rank )
		else
			ar:Bit( false )
		end

		ar:ColorText( szMessage:Get() )
		ar:Send( ply )

		if #viewers > 0 and szMessageRemote:Count() > 0 then
			ar = NetPrepare( "Global/NotifyMulti" )
			ar:String( szType )
			ar:ColorText( szMessageRemote:Get() )
			ar:Send( viewers )
		end
	elseif szType == "ImproveFinish" then
		local szMessage = Core.ColorText()
		local szMessageTop = Core.ColorText()

		if details.Bonus then
			szMessage:Add( ply:Name(), colors[ 1 ], true )
			szMessage:Add( " finished bonus [" )
			szMessage:Add( "Bonus " .. (details.Bonus + 1), colors[ 1 ], true )
			szMessage:Add( "] on " )
			szMessage:Add( Core.StyleName( details.Style ), colors[ 4 ], true )
			szMessage:Add( " in " )
			szMessage:Add( Timer.Convert( details.Time ), colors[ 2 ], true )

			if details.DifferenceWR != "" then
				szMessage:Add( " (" )
				szMessage:Add( details.DifferenceWR, colors[ 1 ], true )

				if details.Improvement != -1 then
					szMessage:Add( ", " )
					szMessage:Add( "Improved by " .. details.Improvement, colors[ 3 ], true )
				end

				szMessage:Add( ")" )
			end

			szMessage:Add( " [Rank " .. details.Rank .. "]" )

			if details.MapRecord then
				szMessageTop:Add( ply:Name(), colors[ 1 ], true )
				szMessageTop:Add( " took the #1 place in the " )
				szMessageTop:Add( Core.StyleName( details.Style ) .. " Bonus " .. (details.Bonus + 1), colors[ 4 ], true )
				szMessageTop:Add( " leaderboards!" )

				if details.Bot then
					szMessageTop:Add( Core.Text( "BotDisplayPostRecord" ) )
				end
			else
				local space = ""
				if details.Pos <= 10 then
					szMessageTop:Add( ply:Name(), colors[ 1 ], true )
					szMessageTop:Add( " finished in the top 10 of the " )
					szMessageTop:Add( "Bonus " .. (details.Bonus + 1), colors[ 4 ], true )
					szMessageTop:Add( " leaderboards!" )

					space = " "
				end

				if details.Bot then
					szMessageTop:Add( space .. Core.Text( "BotDisplayRecordFastest" ) )
				end
			end
		else
			szMessage:Add( ply:Name(), colors[ 1 ], true )
			szMessage:Add( " finished " )

			if details.Style > Styles.Normal then
				szMessage:Add( Core.StyleName( details.Style ), colors[ 4 ], true )
				szMessage:Add( " in " )
			else
				szMessage:Add( "in " )
			end

			szMessage:Add( Timer.Convert( details.Time ), colors[ 2 ], true )

			if details.DifferenceWR != "" then
				szMessage:Add( " (" )
				szMessage:Add( details.DifferenceWR, colors[ 1 ], true )

				if details.Improvement != -1 then
					szMessage:Add( ", " )
					szMessage:Add( "Improved by " .. details.Improvement, colors[ 3 ], true )
				end

				szMessage:Add( ")" )
			end

			szMessage:Add( " [Rank " .. details.Rank .. "]" )

			if details.MapRecord then
				szMessageTop:Add( ply:Name(), colors[ 1 ], true )

				if details.Style > Styles.Normal then
					szMessageTop:Add( " took the #1 place in the " )
					szMessageTop:Add( Core.StyleName( details.Style ), colors[ 4 ], true )
					szMessageTop:Add( " leaderboards!" )
				else
					szMessageTop:Add( " took the #1 place in the Normal leaderboards!" )
				end

				if details.Bot then
					szMessageTop:Add( Core.Text( "BotDisplayPostRecord" ) )
				end
			else
				local space = ""
				if details.Pos <= 10 then
					szMessageTop:Add( ply:Name(), colors[ 1 ], true )
					szMessageTop:Add( " finished in the top 10 of the " )
					szMessageTop:Add( Core.StyleName( details.Style ), colors[ 4 ], true )
					szMessageTop:Add( " leaderboards!" )

					space = " "
				end

				if details.Bot then
					szMessageTop:Add( space .. Core.Text( "BotDisplayRecordFastest" ) )
				end
			end
		end

		local ar = NetPrepare( "Global/NotifyMulti" )
		ar:String( szType )
		ar:ColorText( szMessage:Get() )
		ar:UInt( details.Pos, 16 )
		ar:UInt( details.Style, 8 )
		ar:UInt( ply:EntIndex(), 16 )

		if details.Sound then
			ar:Bit( true )
			ar:String( details.Sound )
		else
			ar:Bit( false )
		end

		if szMessageTop:Count() > 0 then
			ar:Bit( true )
			ar:ColorText( szMessageTop:Get() )
		else
			ar:Bit( false )
		end

		ar:Broadcast()
	elseif szType == "StageSlow" then
		local viewers = ply:Spectator( "Get", { true } )
		local szText = details.Linear and "Checkpoint " or "Stage "
		local szMessage = Core.ColorText()
		local szMessageRemote = Core.ColorText()

		szMessage:Add( "You finished [" )
		szMessage:Add( szText .. details.ID, colors[ 1 ], true )
		szMessage:Add( "]" )

		if details.Style > Styles.Normal then
			szMessage:Add( " on " )
			szMessage:Add( Core.StyleName( details.Style ), colors[ 4 ], true )
		end

		szMessage:Add( " in " )
		szMessage:Add( Timer.Convert( details.Time ), colors[ 2 ], true )

		if details.DifferencePB != "" then
			szMessage:Add( " (" )
			szMessage:Add( details.DifferencePB, colors[ 3 ], true )

			if details.DifferenceWR != "" then
				szMessage:Add( ", " )
				szMessage:Add( details.DifferenceWR, colors[ 1 ], true )
			end

			szMessage:Add( ")" )
		end

		if #viewers > 0 then
			szMessageRemote:Copy( szMessage )
			szMessageRemote:Replace( 1, 4, ply:Name(), colors[ 1 ], true )
		end

		local ar = NetPrepare( "Global/NotifyMulti" )
		ar:String( szType )
		ar:ColorText( szMessage:Get() )
		ar:Bit( false )
		ar:Send( ply )

		if #viewers > 0 and szMessageRemote:Count() > 0 then
			ar = NetPrepare( "Global/NotifyMulti" )
			ar:String( szType )
			ar:ColorText( szMessageRemote:Get() )
			ar:Bit( true )
			ar:Send( viewers )
		end
	elseif szType == "StageFast" then
		local szText = details.Linear and "Checkpoint " or "Stage "
		local szMessage = Core.ColorText()
		local szMessageTop = Core.ColorText()
		local szMessageRemote = Core.ColorText()

		szMessage:Add( "You finished [" )
		szMessage:Add( szText .. details.ID, colors[ 1 ], true )
		szMessage:Add( "]" )

		if details.Style > Styles.Normal then
			szMessage:Add( " on " )
			szMessage:Add( Core.StyleName( details.Style ), colors[ 4 ], true )
		end

		szMessage:Add( " in " )
		szMessage:Add( Timer.Convert( details.Time ), colors[ 2 ], true )

		if details.DifferenceWR != "" then
			szMessage:Add( " (" )
			szMessage:Add( details.DifferenceWR, colors[ 1 ], true )

			if details.DifferencePB != "" then
				szMessage:Add( ", " )
				szMessage:Add( details.DifferencePB, colors[ 3 ], true )
			end

			szMessage:Add( ")" )
		end

		szMessage:Add( " [Rank " .. details.Rank .. "]" )

		szMessageRemote:Copy( szMessage )
		szMessageRemote:Replace( 1, 4, ply:Name(), colors[ 1 ], true )

		if details.Pos == 1 then
			szMessageTop:Add( ply:Name(), colors[ 1 ], true )

			if details.Style > Styles.Normal then
				szMessageTop:Add( " took the " )
				szMessageTop:Add( Core.StyleName( details.Style ), colors[ 4 ], true )
				szMessageTop:Add( " record for [" )
			else
				szMessageTop:Add( " took the record for [" )
			end

			szMessageTop:Add( szText .. details.ID, colors[ 1 ], true )
			szMessageTop:Add( "]" )

			if details.Bot then
				szMessageTop:Add( "\n" .. Core.Text( "BotDisplayRecordPossible" ) )
			end
		end

		local ar = NetPrepare( "Global/NotifyMulti" )
		ar:String( szType )
		ar:ColorText( szMessage:Get() )
		ar:ColorText( szMessageRemote:Get() )

		if szMessageTop:Count() > 0 then
			ar:Bit( true )
			ar:ColorText( szMessageTop:Get() )
		else
			ar:Bit( false )
		end

		ar:UInt( details.Pos, 16 )
		ar:UInt( details.Style, 8 )
		ar:UInt( ply:EntIndex(), 16 )

		ar:Broadcast()
	elseif szType == "TAS" then
		Core.Print( ply, "Timer", Core.Text( "TASTimerWR", Core.StyleName( details.Style ) ) )

		local szMessageTop = Core.ColorText()
		szMessageTop:Add( "[TAS] " )
		szMessageTop:Add( ply:Name(), colors[ 1 ], true )
		szMessageTop:Add( " made a new " )
		szMessageTop:Add( Core.StyleName( details.Style ), colors[ 4 ], true )
		szMessageTop:Add( " run, with a time of " )
		szMessageTop:Add( Timer.Convert( details.Time ), colors[ 2 ], true )

		local ar = NetPrepare( "Global/NotifyMulti" )
		ar:String( szType )
		ar:ColorText( szMessageTop:Get() )
		ar:Broadcast()
	elseif szType == "Popup" then
		if Popups[ ply ] and ST() - Popups[ ply ] < 1 then return end

		NetPrepare( "Global/Notify", details ):Send( ply )
		Popups[ ply ] = ST()

		local viewers = ply:Spectator( "Get", { true } )
		if #viewers > 0 then
			local ar = NetPrepare( "Global/NotifyMulti" )
			ar:String( szType )
			ar:Pattern( "Global/Notify", details )
			ar:Send( viewers )
		end
	elseif szType == "LJ" then
		local szMessage = Core.ColorText()

		szMessage:Add( details.Player, colors[ 1 ], true )
		szMessage:Add( " got a " )
		szMessage:Add( details.Distance .. " unit", colors[ 2 ], true )
		szMessage:Add( " LJ" )

		if details.Style > Styles.Normal then
			szMessage:Add( " on " )
			szMessage:Add( Core.StyleName( details.Style ), colors[ 4 ], true )
		end

		szMessage:Add( "!" )

		if details.Position then
			szMessage:Add( " A new personal best, bringing them to #" .. details.Position .. " in the LJ top list!" )
		end

		local ar = NetPrepare( "Global/NotifyMulti" )
		ar:String( szType )
		ar:String( details.Player )
		ar:Double( details.Distance )
		ar:Double( details.Prestrafe )
		ar:Double( details.Sync )
		ar:UInt( details.Count, 8 )

		if details.Edge and details.Duck then
			ar:Bit( true )
			ar:Bit( details.Duck )
			ar:Double( details.Edge )
		else
			ar:Bit( false )
		end

		ar:ColorText( szMessage:Get() )
		ar:Broadcast()
	end
end
Core.PlayerNotification = Player.Notification

--[[
	Description: Lets the player know about any possibly beaten times
--]]
function Player.NotifyBeatenWR( szPreviousWR, szMap, szName, nStyle, nDifference )
	-- Check if the previous WR holder is online
	local bOnline = player.GetBySteamID( szPreviousWR )

	-- If this isn't the case, save it to our table
	if not bOnline then
		Prepare(
			"INSERT INTO game_notifications (szUID, szMap, szName, nStyle, nDifference, nDate) VALUES ({0}, {1}, {2}, {3}, {4}, {5})",
			{ szPreviousWR, szMap, szName, nStyle, nDifference, os.time() }
		)( SQLVoid )
	end
end

--[[
	Description: Lets the player know about any possibly beaten times
--]]
function PLAYER:NotifyBeatenTimes()
	local data = Player.NotifyCache[ self.UID ]
	if data then
		-- Build the messages
		local msg = {}
		for j = 1, #data do
			-- To-Do: Style here can be negative / < Config.BonusStyle
			msg[ #msg + 1 ] = "- [" .. os.date( "%Y-%m-%d", data[ j ]["nDate"] ) .. "] " .. data[ j ]["szMap"] .. " on " .. Core.StyleName( data[ j ]["nStyle"] ) .. " by " .. data[ j ]["szName"] .. " (-" .. Timer.Convert( data[ j ]["nDifference"] ) .. ")"
		end

		-- Send it to the player in the proper format
		if #msg > 0 then
			NetPrepare( "Global/Notify", { "General", Core.Text( "PlayerBeatenPopup", #msg ), "time_delete", 8, #msg < 20 and Core.Text( "PlayerBeatenTime", self:Name(), string.Implode( "\n", msg ), data[ 1 ]["szMap"] ) } ):Send( self )
		end

		-- Clear the table to avoid seeing this again after a rejoin
		Player.NotifyCache[ self.UID ] = {}

		-- Get rid of the items in the database
		Prepare(
			"DELETE FROM game_notifications WHERE szUID = {0}",
			{ self.UID }
		)( SQLVoid )
	end
end

--[[
	Description: Player disconnection hook to clean up the trash they made
--]]
local function PlayerDisconnect( ply )
	-- Bots don't need any other logic
	if ply:IsBot() then return end

	-- When we're all empty, unload the gamemode (save bots)
	if #player.GetHumans() - 1 < 1 then
		GAMEMODE:UnloadGamemode( "Disconnect" )
	end

	-- Notify spectated players that their spectator is gone
	if ply.Spectating then
		ply:Spectator( "End", { ply:GetObserverTarget() } )
		ply.Spectating = nil
	end

	-- When they're racing, close the match
	if ply.Race then
		ply.Race:Abandon( ply )
	end

	-- Clean bot data
	Core.Ext( "Bot", "CleanPlayer" )( ply )

	-- Collect garbage if required
	if bit.band( Config.Var.GetInt( "ServerCollect" ), 2 ) > 0 then
		collectgarbage( "collect" )
	end

	-- Check if a vote is going on
	if RTV.VotePossible then return end

	-- If not, remove their vote
	if ply.Rocked then
		RTV.Votes = RTV.Votes - 1
	end

	-- And check if the vote passes now
	local Count = RTV.GetVotable( ply )
	if Count > 0 then
		RTV.Required = math.ceil( Count * RTV.Fraction )

		if RTV.Votes >= RTV.Required then
			RTV.StartVote()
		end
	end
end
hook.Add( "PlayerDisconnected", "PlayerDisconnect", PlayerDisconnect )



-- RTV System
RTV.MapRepeat = Config.Var.GetInt( "MapRepeat" )
RTV.UseLimitations = Config.Var.GetBool( "VoteLimit" )
RTV.MinLimitations = Config.Var.GetInt( "VoteLimitCount" )
RTV.Fraction = Config.Var.GetFloat( "VoteFraction" )
RTV.RandomizeTie = Config.Var.GetBool( "VoteRandomize" )
RTV.VoteTime = Config.Var.GetInt( "VoteDuration" )
RTV.Length = Config.Var.GetInt( "MapLength" ) * 60
RTV.DefaultExtend = Config.Var.GetInt( "MapExtend" ) * 60
RTV.WaitPeriod = Config.Var.GetInt( "VoteWait" ) * 60

RTV.Identifier = "MapCountdown"
RTV.Version = 1
RTV.ListMax = 5
RTV.VoteCount = 7
RTV.Votes = 0
RTV.VotePossible = false
RTV.VoteList = {}
RTV.VoteTimeEnd = 0
RTV.Extends = 0
RTV.CheckInterval = 0.5 * 60
RTV.BroadcastInterval = RTV.VoteTime / 10

if not RTV.Initialized then
	RTV.TimeNotify = {}
	RTV.Initialized = ST()
	RTV.Begin = RTV.Initialized
	RTV.End = RTV.Begin + RTV.Length

	local tab = string.Explode( ",", Config.Var.Get( "MapNotifications" ) )
	for i = 1, #tab do
		RTV.TimeNotify[ #RTV.TimeNotify + 1 ] = { tonumber( tab[ i ] ) }
	end
end

RTV.Func = {}
RTV.AutoExtend = {}
RTV.Nominations = {}
RTV.LatestList = {}

--[[
	Description: Starts the RTV system
--]]
function RTV:Start()
	-- Make sure there's only one RTV timer running
	if timer.Exists( self.Identifier ) then
		timer.Remove( self.Identifier )
	end

	-- Set initialization fields for lifetime calculation
	self.Begin = ST()
	self.End = self.Begin + self.Length

	-- Populate the vote list with 0 votes
	for i = 1, self.VoteCount do
		self.VoteList[ i ] = 0
	end

	-- Load all necessary data
	self:Load()

	-- Crack up the random generator to throw in a little less than pseudo-randoms
	math.random( 1, 5 )

	-- Skip timers if length is 0
	if RTV.Length == 0 then return end

	-- Create a timer
	timer.Create( self.Identifier, self.Length, 1, self.StartVote )
	timer.Create( self.Identifier .. "Hourglass", self.CheckInterval, 0, self.TimeCheck )
end

--[[
	Description: Loads data required for the RTV system
--]]
function RTV:Load()
	file.CreateDir( Config.BaseType .. "/" )

	-- Load in or write the map version
	if not file.Exists( Config.BaseType .. "/maplistversion.txt", "DATA" ) then
		file.Write( Config.BaseType .. "/maplistversion.txt", tostring( self.Version ) )
	else
		self.Version = tonumber( file.Read( Config.BaseType .. "/maplistversion.txt", "DATA" ) )
	end

	-- Create a dummy file if it's blank
	local dummy = {}
	for i = 1, RTV.MapRepeat do dummy[ i ] = "Dummy" end

	if not file.Exists( Config.BaseType .. "/maptracker.txt", "DATA" ) then
		file.Write( Config.BaseType .. "/maptracker.txt", util.TableToJSON( dummy ) )
	end

	-- Check file content
	local content = file.Read( Config.BaseType .. "/maptracker.txt", "DATA" )
	if not content or content == "" then return end

	-- Try to deserialize
	local tab = util.JSONToTable( content )
	if not tab or #tab != RTV.MapRepeat then
		return file.Write( Config.BaseType .. "/maptracker.txt", util.TableToJSON( dummy ) )
	end

	-- If we're going back to the same map, don't keep adding to the list
	if tab[ 1 ] == game.GetMap() then return end

	-- Insert at front and remove at the back
	table.insert( tab, 1, game.GetMap() )
	table.remove( tab, RTV.MapRepeat + 1 )

	-- Update the table
	self.LatestList = tab

	-- Finally write to file
	file.Write( Config.BaseType .. "/maptracker.txt", util.TableToJSON( self.LatestList ) )
end

--[[
	Description: Starts the vote
--]]
function RTV.StartVote()
	if RTV.VotePossible then return end

	-- Let everyone know we just started a vote
	RTV.VotePossible = true
	RTV.Selections = {}
	Core.Print( nil, "Notification", Core.Text( "VoteStart" ) )

	-- Iterate over the nomination table and categorize it by vote count
	local MapList, MaxCount = {}, 1
	for map,voters in pairs( RTV.Nominations ) do
		local amount = 0
		for _,v in pairs( voters ) do
			if IsValid( v ) then
				amount = amount + 1
			end
		end

		-- If we've got an entry already, expand, otherwise create it
		local count = MapList[ amount ] and #MapList[ amount ]
		if not count then
			MapList[ amount ] = { map }
		else
			MapList[ amount ][ count + 1 ] = map
		end

		-- Increase max count if necessary
		if amount > MaxCount then
			MaxCount = amount
		end
	end

	-- Loop over the most important nominations
	for i = MaxCount, 1, -1 do
		if MapList[ i ] then
			for j = 1, #MapList[ i ] do
				if #RTV.Selections >= RTV.ListMax then break end

				-- Add the nomination to the list
				RTV.Selections[ #RTV.Selections + 1 ] = MapList[ i ][ j ]
			end
		end
	end

	-- If we haven't had sufficient nominations, gather some random maps
	if #RTV.Selections < 5 and Timer.Maps > 0 then
		-- Copy the base table and remove already nominated entries
		local copy = table.Copy( Maps )
		for i = 1, #RTV.Selections do
			copy[ RTV.Selections[ i ] ] = nil
		end

		-- Randomize all items but still keep plays into account
		local temp = {}
		for map,data in pairs( copy ) do
			temp[ #temp + 1 ] = { Map = map, Seed = math.random() * (data.nPlays or 0) }
		end

		-- Sort it by the quasi-random seed
		table.sort( temp, function( a, b ) return a.Seed < b.Seed end )

		-- Get the 25% least played maps in a separate table
		local limit = {}
		for i = 1, math.ceil( #temp * 0.25 ) do
			limit[ i ] = temp[ i ]
		end

		-- Finally add random entries
		for _,data in RandomPairs( limit ) do
			local map = data.Map
			if #RTV.Selections >= RTV.ListMax then break end
			if table.HasValue( RTV.Selections, map ) or map == game.GetMap() then continue end
			if table.HasValue( RTV.LatestList, map ) then continue end

			-- Add the random map to the list
			RTV.Selections[ #RTV.Selections + 1 ] = { map, RTV.GetMapData( map ) }
		end
	end

	-- Create a sortable table
	local sorted = {}
	for i = 1, #RTV.Selections do
		local item = RTV.Selections[ i ]
		if type( item ) == "table" then
			sorted[ #sorted + 1 ] = { Map = item[ 1 ], Plays = item[ 2 ][ 3 ], ListID = i }
		end
	end

	-- Check if we have maps to sort
	if #sorted > 0 then
		-- Sort the table with ascending plays
		table.SortByMember( sorted, "Plays", true )

		-- Reset the current table
		local offset
		for i = 1, #RTV.Selections do
			if type( RTV.Selections[ i ] ) == "table" then
				if not offset then offset = i end
				RTV.Selections[ i ] = nil
			end
		end

		-- Overwrite table entries with re-sorted entries
		for i = 1, #sorted do
			if not offset then break end
			RTV.Selections[ offset + i - 1 ] = sorted[ i ].Map
		end
	end

	-- Double check if we have maps at all
	if #RTV.Selections == 0 then
		local add = {}
		local maps = file.Find( "maps/*.bsp", "GAME" )
		for _,m in RandomPairs( maps ) do
			if #add < 5 then
				add[ #add + 1 ] = string.sub( m, 1, #m - 4 )
			end
		end

		-- Add dummy values if we don't have anything
		if #add < 5 then
			for i = 1, 5 do
				add[ i ] = "no_maps_" .. i
			end
		end

		-- Set our fake table to the selections
		for i = 1, #add do
			RTV.Selections[ i ] = add[ i ]
		end
	end

	-- Create a new table with only map data to be sent
	local RTVSend = {}
	for i = 1, #RTV.Selections do
		RTVSend[ #RTVSend + 1 ] = RTV.GetMapData( RTV.Selections[ i ] )
	end

	-- Make the list accessible from the RTV object and set the ending time
	RTV.VoteTimeEnd = ST() + RTV.VoteTime
	RTV.Sent = RTVSend
	RTV.Sent.Countdown = math.Clamp( RTV.VoteTimeEnd - ST(), 0, RTV.VoteTime )

	-- Broadcast the compiled list and start a timer
	timer.Simple( RTV.VoteTime + 1, RTV.EndVote )
	Core.Broadcast( "RTV/List", RTV.Sent )

	-- Distribute the instant votes
	timer.Simple( 0.5, function()
		local extend = {}
		for p,v in pairs( RTV.AutoExtend ) do
			if v then
				extend[ #extend + 1 ] = p
			end
		end

		if #extend > 0 then
			Core.Send( extend, "RTV/InstantVote", 6 )
		end

		for map,voters in pairs( RTV.Nominations ) do
			for id,data in pairs( RTV.Sent ) do
				if id == "Countdown" then continue end
				if data[ 1 ] == map then
					local out = {}
					for _,p in pairs( voters ) do
						if not RTV.AutoExtend[ p ] then
							out[ #out + 1 ] = p
						end
					end

					Core.Send( out, "RTV/InstantVote", id )
				end
			end
		end
	end )

	-- Get all vote participants
	local tabPlayers = player.GetHumans()
	local szUIDs, szMaps, tabPlys, nIDs = {}, {}, {}, {}
	for i = 1, #tabPlayers do szUIDs[ #szUIDs + 1 ] = tabPlayers[ i ].UID tabPlys[ szUIDs[ #szUIDs ] ] = tabPlayers[ i ] end
	for i = 1, #RTVSend do szMaps[ #szMaps + 1 ] = RTVSend[ i ][ 1 ] nIDs[ szMaps[ #szMaps ] ] = i end

	-- Get query pieces
	local queryMap = "szMap = '" .. string.Implode( "' OR szMap = '", szMaps ) .. "'"
	local queryPlayers = "szUID = '" .. string.Implode( "' OR szUID = '", szUIDs ) .. "'"

	-- Get the beaten maps and send them to the players
	Prepare(
		"SELECT szMap, szUID, nPoints FROM `game_times` WHERE nStyle = {0} AND (" .. queryMap .. ") AND (" .. queryPlayers .. ")",
		{ Styles.Normal }
	)( function( data, varArg )
		if Core.Assert( data, "szMap" ) then
			local tabData = {}
			for i = 1, #data do
				local t, m = tabData[ data[ i ].szUID ], { nIDs[ data[ i ].szMap ], data[ i ].nPoints }
				if not t then
					tabData[ data[ i ].szUID ] = { m }
				else
					t[ #t + 1 ] = m
				end
			end

			for steam,list in pairs( tabData ) do
				local out = {}
				for i = 1, #list do
					out[ list[ i ][ 1 ] ] = list[ i ][ 2 ] / RTVSend[ list[ i ][ 1 ] ][ 2 ]
				end

				if IsValid( tabPlys[ steam ] ) then
					Core.Send( tabPlys[ steam ], "RTV/SetBeaten", out )
				end
			end
		end
	end )

	-- Check broadcast timer
	if timer.Exists( RTV.Identifier .. "Broadcast" ) then
		timer.Remove( RTV.Identifier .. "Broadcast" )
	end

	-- Create one with iterations that stop before the timer runs out
	timer.Create( RTV.Identifier .. "Broadcast", RTV.BroadcastInterval, RTV.VoteTime / RTV.BroadcastInterval - 1, function()
		NetPrepare( "RTV/VoteList", RTV.VoteList ):Broadcast()
	end )
end

--[[
	Description: Ends the vote and decides what won (a map or extend or even random)
--]]
function RTV.EndVote()
	if RTV.CancelVote then
		local result = RTV.CompleteVote( true )
		return RTV:ResetVote( "Yes", 2, false, "VoteCancelled", result == "Extend" and "Extend won the vote. " or "" )
	end

	-- Trigger finalization (bots)
	GAMEMODE:UnloadGamemode( "VoteEnd", RTV.CompleteVote )
end

--[[
	Description: Callback for gamemode unloading
--]]
function RTV.CompleteVote( bGet )
	local nMax, nTotal, nWin = 0, 0, -1
	for i = 1, 7 do
		if RTV.VoteList[ i ] and RTV.VoteList[ i ] > nMax then
			nMax = RTV.VoteList[ i ]
			nWin = i
		end

		nTotal = nTotal + RTV.VoteList[ i ]
	end

	-- If enabled, pick a random one if there's duplicates
	if RTV.RandomizeTie then
		local votes = {}
		for i = 1, 7 do
			if RTV.VoteList[ i ] == nMax then
				votes[ #votes + 1 ] = i
			end
		end

		if #votes > 1 then
			nWin = votes[ math.random( 1, #votes ) ]
			Core.Print( nil, "Notification", Core.Text( "VoteSameVotes", "#" .. string.Implode( ", #", votes ), nWin ) )
		end
	end

	-- Execute winner function
	if nWin <= 0 then
		nWin = math.random( 1, 5 )
	elseif nWin == 6 then
		if bGet then return "Extend" end
		Core.Print( nil, "Notification", Core.Text( "VoteExtend", RTV.DefaultExtend / 60 ) )
		return RTV:ResetVote( nil, 1, true, nil )
	elseif nWin == 7 then
		RTV.VotePossible = false

		if Timer.Maps > 0 then
			local ListMap, ListPlays = {}, {}
			for map,data in pairs( Maps ) do
				ListMap[ #ListMap + 1 ] = map
				ListPlays[ #ListPlays + 1 ] = data["nPlays"]
			end

			local minId, minValue, thisMap = ListMap[ 1 ], ListPlays[ 1 ], game.GetMap()
			for i = 2, #ListPlays do
				if ListPlays[ i ] < minValue and ListMap[ i ] != thisMap then
					minId = ListMap[ i ]
					minValue = ListPlays[ i ]
				end
			end

			if minId and minValue and Maps[ minId ] then
				nWin = 1
				RTV.Selections[ nWin ] = minId
			else
				nWin = math.random( 1, 5 )
			end
		else
			nWin = math.random( 1, 5 )
		end
	end

	-- Get the map from the selection table
	local szMap = RTV.Selections[ nWin ]
	if not szMap or not type( szMap ) == "string" then
		return Core.Print( nil, "Notification", Core.Text( "VoteMissing", szMap ) )
	end

	-- Check if the map we're changing to is actually available
	if not RTV.IsAvailable( szMap ) then
		Core.Print( nil, "Notification", Core.Text( "VoteMissing", szMap ) )
	else
		Core.Print( nil, "Notification", Core.Text( "VoteChange", szMap ) )
	end

	-- Check if we just want the result
	if bGet then
		return szMap
	end

	-- Backup reset for if we don't change
	timer.Simple( 10, function()
		RTV:ResetVote( "Yes", 1, false, "VoteFailure" )
	end )

	-- Finally change level
	timer.Simple( 5, function()
		Core.PrintC( "[Event] RTV -> Map changed to: ", szMap )

		GAMEMODE:UnloadGamemode( "Vote Change", function()
			RunConsoleCommand( "changelevel", szMap )
		end )
	end )
end

--[[
	Description: Resets the vote data according to the vote type
--]]
function RTV:ResetVote( szCancel, nMult, bExtend, szMsg, varArg )
	nMult = nMult or 1

	if szCancel and szCancel == "Yes" then
		self.CancelVote = nil
	end

	self.VotePossible = false
	self.Selections = {}

	self.Begin = ST()
	self.End = self.Begin + (nMult * self.DefaultExtend)

	self.Votes = 0
	for i = 1, self.VoteCount do
		self.VoteList[ i ] = 0
	end

	for _,d in pairs( self.TimeNotify ) do
		d[ 2 ] = nil
	end

	if bExtend then
		self.Extends = self.Extends + 1
		RTV.SendTimeLeft()
	end

	for _,p in pairs( player.GetHumans() ) do
		p.Rocked = nil
		p.LastVotedID = nil
		p.ResentVote = nil
	end

	if timer.Exists( self.Identifier ) then
		timer.Remove( self.Identifier )
	end

	timer.Create( self.Identifier, nMult * self.DefaultExtend, 1, self.StartVote )

	if szMsg then
		Core.Print( nil, "Notification", Core.Text( szMsg, varArg ) )
	end
end

--[[
	Description: Changes the time left on the vote
--]]
function RTV.ChangeTime( nMins )
	-- Make sure there's only one RTV timer running
	if timer.Exists( RTV.Identifier ) then
		timer.Remove( RTV.Identifier )
	end

	timer.Create( RTV.Identifier, nMins * 60, 1, RTV.StartVote )

	RTV.End = ST() + nMins * 60
	RTV.SendTimeLeft()

	for _,d in pairs( RTV.TimeNotify ) do
		d[ 2 ] = nil
	end

	for i = 1, #RTV.TimeNotify do
		local item = RTV.TimeNotify[ i ]
		if nMins * 60 < item[ 1 ] * 60 then
			item[ 2 ] = true
		end
	end
end
Core.RTVChangeTime = RTV.ChangeTime

--[[
	Description: Broadcasts a timeleft notification to every connected player
	Notes: Runs on a timer
--]]
function RTV.TimeCheck()
	local remaining = RTV.End - ST()
	for i = 1, #RTV.TimeNotify do
		local item = RTV.TimeNotify[ i ]
		if remaining < item[ 1 ] * 60 and not item[ 2 ] then
			local text = remaining < 60 and "Less than 1 minute remaining" or ((remaining >= 60 and remaining < 120) and "1 minute remaining" or math.floor( remaining / 60 ) .. " minutes remaining")
			NetPrepare( "Global/Notify", { "Notification", text, "hourglass", 10, text } ):Broadcast()

			item[ 2 ] = true
			break
		end
	end
end

--[[
	Description: Get the amount of people that can actually vote in the server
--]]
function RTV.GetVotable( exclude, plys )
	local n, ps = 0, {}

	for _,p in pairs( player.GetHumans() ) do
		if p == exclude then
			continue
		elseif (Core.Ext( "AFK", "GetPoints" )( p ) or 10) < 2 then
			continue
		elseif RTV.UseLimitations and StylePoints[ Styles.Normal ] and (not StylePoints[ Styles.Normal ][ p.UID ] or StylePoints[ Styles.Normal ][ p.UID ] == 0) then
			if p.Style != Styles.Normal then
				continue
			elseif p.Record == 0 and #player.GetHumans() > RTV.MinLimitations then
				continue
			end
		end

		n = n + 1
		ps[ #ps + 1 ] = p
	end

	return plys and ps or n
end


--[[
	Description: Triggers a vote on the player if possible
--]]
function RTV.Func.Vote( ply )
	if ply.RTVLimit and ST() - ply.RTVLimit < 60 then
		return Core.Print( ply, "Notification", Core.Text( "VoteLimit", math.ceil( 60 - (ST() - ply.RTVLimit) ) ) )
	elseif ply.Rocked then
		return Core.Print( ply, "Notification", Core.Text( "VoteAlready" ) )
	elseif RTV.VotePossible then
		return Core.Print( ply, "Notification", Core.Text( "VotePeriod" ) )
	elseif ST() - RTV.Begin < RTV.WaitPeriod then
		return Core.Print( ply, "Notification", Core.Text( "VoteLimited", string.format( "%.1f", (RTV.WaitPeriod - (ST() - RTV.Begin)) / 60 ) ) )
	elseif RTV.UseLimitations and #player.GetHumans() > RTV.MinLimitations then
		if StylePoints[ Styles.Normal ] and (not StylePoints[ Styles.Normal ][ ply.UID ] or StylePoints[ Styles.Normal ][ ply.UID ] == 0) then
			if ply.Style != Styles.Normal then
				return Core.Print( ply, "Notification", Core.Text( "VoteLimitPlay" ) )
			elseif ply.Record == 0 then
				return Core.Print( ply, "Notification", Core.Text( "VoteLimitPlay" ) )
			end
		end
	end

	ply.RTVLimit = ST()
	ply.Rocked = true

	RTV.Votes = RTV.Votes + 1
	RTV.Required = math.ceil( RTV.GetVotable() * RTV.Fraction )

	local nVotes = RTV.Required - RTV.Votes
	Core.Print( nil, "Notification", Core.Text( "VotePlayer", ply:Name(), nVotes, nVotes == 1 and "vote" or "votes", math.ceil( (RTV.Votes / RTV.Required) * 100 ) ) )

	if RTV.Votes >= RTV.Required then
		RTV.StartVote()
	end
end

--[[
	Description: Revokes a vote on the player if there is any
--]]
function RTV.Func.Revoke( ply )
	if RTV.VotePossible then
		return Core.Print( ply, "Notification", Core.Text( "VotePeriod" ) )
	end

	if ply.Rocked then
		ply.Rocked = false

		RTV.Votes = RTV.Votes - 1
		RTV.Required = math.ceil( RTV.GetVotable() * RTV.Fraction )

		local nVotes = RTV.Required - RTV.Votes
		Core.Print( nil, "Notification", Core.Text( "VoteRevoke", ply:Name(), nVotes, nVotes == 1 and "vote" or "votes" ) )
	else
		Core.Print( ply, "Notification", Core.Text( "VoteRevokeFail" ) )
	end
end

--[[
	Description: Nominates a map
	Notes: Whole lot of extra logic for sorting the maps
--]]
function RTV.Func.Nominate( ply, szMap )
	local szIdentifier = "Nomination"
	local varArgs = { ply:Name(), szMap }

	if RTV.UseLimitations and #player.GetHumans() > RTV.MinLimitations and table.HasValue( RTV.LatestList, szMap ) then
		local at = 1
		for id,map in pairs( RTV.LatestList ) do
			if map == szMap then
				at = id
				break
			end
		end

		return Core.Print( ply, "Notification", Core.Text( "NominateRecent", at - 1 ) )
	end

	if ply.NominatedMap and ply.NominatedMap != szMap then
		if RTV.Nominations[ ply.NominatedMap ] then
			for id,p in pairs( RTV.Nominations[ ply.NominatedMap ] ) do
				if p == ply then
					table.remove( RTV.Nominations[ ply.NominatedMap ], id )

					if #RTV.Nominations[ ply.NominatedMap ] == 0 then
						RTV.Nominations[ ply.NominatedMap ] = nil
					end

					szIdentifier = "NominationChange"
					varArgs = { ply:Name(), ply.NominatedMap, szMap }

					break
				end
			end
		end
	elseif ply.NominatedMap and ply.NominatedMap == szMap then
		return Core.Print( ply, "Notification", Core.Text( "NominationAlready" ) )
	end

	if not RTV.Nominations[ szMap ] then
		RTV.Nominations[ szMap ] = { ply }
		ply.NominatedMap = szMap
		Core.Print( nil, "Notification", Core.Text( szIdentifier, varArgs ) )
	elseif type( RTV.Nominations ) == "table" then
		local Included = false
		for _,p in pairs( RTV.Nominations[ szMap ] ) do
			if p == ply then Included = true break end
		end

		if not Included then
			table.insert( RTV.Nominations[ szMap ], ply )
			ply.NominatedMap = szMap
			Core.Print( nil, "Notification", Core.Text( szIdentifier, varArgs ) )
		else
			return Core.Print( ply, "Notification", Core.Text( "NominationAlready" ) )
		end
	end
end

--[[
	Description: Returns a list of who has voted and who hasn't voted
--]]
function RTV.Func.Who( ply )
	local Voted = {}
	local NotVoted = {}

	for _,p in pairs( RTV.GetVotable( nil, true ) ) do
		if p.Rocked then
			Voted[ #Voted + 1 ] = p:Name()
		else
			NotVoted[ #NotVoted + 1 ] = p:Name()
		end
	end

	RTV.Required = math.ceil( RTV.GetVotable() * RTV.Fraction )
	Core.Print( ply, "Notification", Core.Text( "VoteList", RTV.Required, #Voted, string.Implode( ", ", Voted ), #NotVoted, string.Implode( ", ", NotVoted ) ) )
end

--[[
	Description: Checks how many votes are left before the map changes
--]]
function RTV.Func.Check( ply )
	RTV.Required = math.ceil( RTV.GetVotable() * RTV.Fraction )

	local nVotes = RTV.Required - RTV.Votes
	Core.Print( ply, "Notification", Core.Text( "VoteCheck", nVotes, nVotes == 1 and "vote" or "votes" ) )
end

--[[
	Description: Returns the time remaining before a change of maps
--]]
function RTV.Func.Left( ply )
	Core.Print( ply, "Notification", Core.Text( "MapTimeLeft", Timer.Convert( RTV.End - ST() ) ) )
end

--[[
	Description: Resends the voting screen to the player
--]]
function RTV.Func.Revote( ply, bGet )
	if bGet then return RTV.VotePossible end
	if not RTV.VotePossible then return Core.Print( ply, "Notification", Core.Text( "VotePeriodActive" ) ) end
	ply.ResentVote = true

	RTV.Sent.Countdown = math.Clamp( RTV.VoteTimeEnd - ST(), 0, RTV.VoteTime )
	Core.Send( ply, "RTV/List", RTV.Sent )
end

--[[
	Description: Gets a type of map requested by the player
--]]
function RTV.Func.MapFunc( ply, key )
	if Timer.Maps == 0 then return end

	if key == "playinfo" then
		Core.Print( ply, "General", Core.Text( "TimerMapsInfo" ) )
	elseif key == "leastplayed" then
		local temp = {}
		for map,data in pairs( Maps ) do
			temp[ #temp + 1 ] = { Map = map, Plays = data.nPlays or 0 }
		end

		table.SortByMember( temp, "Plays", true )

		local str = {}
		for i = 1, 5 do
			str[ i ] = temp[ i ].Map .. " (" .. temp[ i ].Plays .. " plays)"
		end

		Core.Print( ply, "General", Core.Text( "TimerMapsDisplay", "Least", string.Implode( ", ", str ) ) )
	elseif key == "mostplayed" or key == "overplayed" then
		local temp = {}
		for map,data in pairs( Maps ) do
			temp[ #temp + 1 ] = { Map = map, Plays = data.nPlays or 0 }
		end

		table.SortByMember( temp, "Plays", false )

		local str = {}
		for i = 1, 5 do
			str[ i ] = temp[ i ].Map .. " (" .. temp[ i ].Plays .. " plays)"
		end

		Core.Print( ply, "General", Core.Text( "TimerMapsDisplay", "Most", string.Implode( ", ", str ) ) )
	elseif key == "lastplayed" or key == "lastmaps" then
		local temp = {}
		for map,data in pairs( Maps ) do
			temp[ #temp + 1 ] = { Map = map, Date = data.szDate }
		end

		table.SortByMember( temp, "Date", false )

		local str = {}
		for i = 1, 5 do
			str[ i ] = temp[ i ].Map .. " (" .. temp[ i ].Date .. ")"
		end

		Core.Print( ply, "General", Core.Text( "TimerMapsDisplay", "Last", string.Implode( ", ", str ) ) )
	elseif key == "randommap" then
		for map,data in RandomPairs( Maps ) do
			Core.Print( ply, "General", Core.Text( "TimerMapsRandom", map ) )
			break
		end
	end
end

--[[
	Description: Shows which map you have nominated
--]]
function RTV.Func.Which( ply )
	Core.Print( ply, "Notification", ply.NominatedMap and Core.Text( "MapNominated", "", ply.NominatedMap ) or Core.Text( "MapNominated", "n't", "a map" ) )
end

--[[
	Description: Shows all nominated maps
--]]
function RTV.Func.Nominations( ply )
	local MapList, MaxCount = {}, 1
	for map,voters in pairs( RTV.Nominations ) do
		local plys = { map }
		for _,v in pairs( voters ) do
			if IsValid( v ) then
				plys[ #plys + 1 ] = v:Name()
			end
		end

		-- If we've got an entry already, expand, otherwise create it
		local amount = #plys - 1
		local count = MapList[ amount ] and #MapList[ amount ]
		if not count then
			MapList[ amount ] = { plys }
		else
			MapList[ amount ][ count + 1 ] = plys
		end

		-- Increase max count if necessary
		if amount > MaxCount then
			MaxCount = amount
		end
	end

	-- Loop over the most important nominations
	local str, add = Core.Text( "MapNominations" )
	for i = MaxCount, 1, -1 do
		if MapList[ i ] then
			for j = 1, #MapList[ i ] do
				str = str .. "- " .. table.remove( MapList[ i ][ j ], 1 ) .. " (By " .. i .. " player(s): " .. string.Implode( ", ", MapList[ i ][ j ] ) .. ")\n"
				add = true
			end
		end
	end

	-- Print the message out
	Core.Print( ply, "Notification", add and (str .. Core.Text( "MapNominationChance" )) or Core.Text( "MapNominationsNone" ) )
end

--[[
	Description: Revokes a player map nomination
--]]
function RTV.Func.Denominate( ply )
	if not ply.NominatedMap then
		return Core.Print( ply, "Notification", Core.Text( "MapNominationNone" ) )
	end

	if RTV.Nominations[ ply.NominatedMap ] then
		for id,p in pairs( RTV.Nominations[ ply.NominatedMap ] ) do
			if p == ply then
				table.remove( RTV.Nominations[ ply.NominatedMap ], id )

				if #RTV.Nominations[ ply.NominatedMap ] == 0 then
					RTV.Nominations[ ply.NominatedMap ] = nil
				end

				break
			end
		end
	end

	ply.NominatedMap = nil

	Core.Print( ply, "Notification", Core.Text( "MapNominationRevoke" ) )
end

--[[
	Description: Sets the player to automatically vote extend
--]]
function RTV.Func.Extend( ply )
	RTV.AutoExtend[ ply ] = not RTV.AutoExtend[ ply ]

	Core.Print( ply, "Notification", Core.Text( "MapAutoExtend", not RTV.AutoExtend[ ply ] and "no longer " or "" ) )
end

--[[
	Description: The function that triggers the RTV.Func's
--]]
function PLAYER:RTV( szType, args )
	if RTV.Func[ szType ] then
		return RTV.Func[ szType ]( self, args )
	end
end


--[[
	Description: Process a received vote
--]]
function RTV.ReceiveVote( ply, varArgs )
	local nVote, nOld = varArgs[ 1 ], varArgs[ 2 ]
	if not RTV.VotePossible or not nVote then return end
	if ply.LastVotedID == nVote then return end

	if not nOld and ply.ResentVote and ply.LastVotedID then
		nOld = ply.LastVotedID
		ply.ResentVote = nil
	end

	ply.LastVotedID = nVote

	local nAdd = 1
	if not nOld then
		if nVote < 1 or nVote > 7 then return end
		if not RTV.VoteList[ nVote ] then RTV.VoteList[ nVote ] = 0 end
		RTV.VoteList[ nVote ] = RTV.VoteList[ nVote ] + nAdd
	else
		if nVote < 1 or nVote > 7 or nOld < 1 or nOld > 7 then return end
		if not RTV.VoteList[ nVote ] then RTV.VoteList[ nVote ] = 0 end
		if not RTV.VoteList[ nOld ] then RTV.VoteList[ nOld ] = 0 end
		RTV.VoteList[ nVote ] = RTV.VoteList[ nVote ] + nAdd
		RTV.VoteList[ nOld ] = RTV.VoteList[ nOld ] - nAdd
		if RTV.VoteList[ nOld ] < 0 then RTV.VoteList[ nOld ] = 0 end
	end

	NetPrepare( "RTV/VoteList", RTV.VoteList ):Broadcast()
end
Core.Register( "Global/Vote", RTV.ReceiveVote )

--[[
	Description: Sends the map list to a player
	Notes: Encodes it here since it might take a while before anyone needs a new map list
--]]
local EncodedData, EncodedLength
function RTV.GetMapList( ply, varArgs )
	if varArgs[ 1 ] != RTV.Version then
		if not EncodedData or not EncodedLength then
			EncodedData = util.Compress( util.TableToJSON( { Maps, RTV.Version, Timer.Maps } ) )
			EncodedLength = #EncodedData
		end

		if not EncodedData or not EncodedLength then
			Core.Print( ply, "Notification", Core.Text( "MiscMissingMapList" ) )
		else
			net.Start( "BinaryTransfer" )
			net.WriteString( "List" )
			net.WriteString( varArgs[ 2 ] or "" )
			net.WriteUInt( EncodedLength, 32 )
			net.WriteData( EncodedData, EncodedLength )
			net.Send( ply )
		end
	end
end
Core.Register( "Global/MapList", RTV.GetMapList )

--[[
	Description: Called when the player tries to open another map list and it automatically updates
--]]
function RTV.MapListUpdated( ply, varArgs )
	Core.RemoveCommandLimit( ply )
	GAMEMODE:PlayerSay( ply, varArgs[ 1 ] )
end
Core.Register( "Global/MapUpdateCmd", RTV.MapListUpdated )

--[[
	Description: Informs the client about how much time is left on the map
--]]
function RTV.SendTimeLeft( ply )
	local ar = NetPrepare( "Timer/TimeLeft" )
	ar:Double( RTV.End - ST() )

	if ply then
		ar:Send( ply )
	else
		ar:Broadcast()
	end
end

--[[
	Description: Update the version number and increment it
--]]
function RTV:UpdateVersion( nAmount )
	EncodedData, EncodedLength = nil, nil

	self.Version = self.Version + (nAmount or 1)
	file.Write( Config.BaseType .. "/maplistversion.txt", tostring( self.Version ) )
end

--[[
	Description: Checks if the map exists on the disk
--]]
function RTV.IsAvailable( szMap )
	return file.Exists( "maps/" .. szMap .. ".bsp", "GAME" )
end

--[[
	Description: Checks if the map exists in the loaded database table
--]]
function RTV.MapExists( szMap )
	return not not Maps[ szMap ]
end

--[[
	Description: Returns the loaded data about a map
	Notes: Could add more but this is only necessary to be on the client itself
--]]
function RTV.GetMapData( szMap )
	local tab = Maps[ szMap ]

	if tab then
		if Config.IsSurf then
			return { szMap, tab["nMultiplier"], tab["nPlays"], tab["nTier"] or 1, tab["nType"] or 0 }
		else
			return { szMap, tab["nMultiplier"], tab["nPlays"] }
		end
	else
		if Config.IsSurf then
			return { szMap, 0, 0, 1, 0 }
		else
			return { szMap, 0, 0 }
		end
	end
end


-- Zones
Zones.Type = {
	["Normal Start"] = 0,
	["Normal End"] = 1,
	["Bonus Start"] = 2,
	["Bonus End"] = 3,
	["Anticheat"] = 4,
	["Freestyle"] = 5,
	["Normal AC"] = 6,
	["Bonus AC"] = 7,
	["Stage Start"] = 8,
	["Stage End"] = 9,
	["Restart Zone"] = 10,
	["Velocity Zone"] = 11,
	["Solid AC"] = 12
}

-- Embedded items
Zones.Embedded = {
	["Bonus Start"] = { 100, 199, 2 },
	["Bonus End"] = { 200, 299, 2 },
	["Anticheat"] = { 500, 599, 1 },
	["Freestyle"] = { 800, 899, 1 },
	["Stage Start"] = { 300, 399, 1 },
	["Stage End"] = { 400, 499, 1 },
	["Restart Zone"] = { 600, 699, 1 },
	["Velocity Zone"] = { 700, 799, 1 }
}

-- The options that can be set
Zones.Options = {
	NoStartLimit = 1,
	NoSpeedLimit = 2,
	TelehopMap = 4,
	Checkpoints = 8
}


--[[
	Description: Loads all zones for this map from the database and parses them
--]]
function Zones.Load( callback )
	Prepare(
		"SELECT nType, vPos1, vPos2 FROM game_zones WHERE szMap = {0}",
		{ game.GetMap() },
		{ UseOptions = true, RawFormat = true }
	)( function( data, varArg )
		ZoneCache = {}

		if Core.Assert( data, "nType" ) then
			local makeNum, makeType = tonumber, util.StringToType
			for j = 1, #data do
				data[ j ]["nType"] = makeNum( data[ j ]["nType"] )
				data[ j ]["vPos1"] = makeType( data[ j ]["vPos1"], "Vector" )
				data[ j ]["vPos2"] = makeType( data[ j ]["vPos2"], "Vector" )

				ZoneCache[ #ZoneCache + 1 ] = data[ j ]
			end
		end

		varArg()
	end, callback )

	-- Load editor data
	for key,data in pairs( Zones.Embedded ) do
		local id = Zones.Type[ key ]
		Zones.Editor.Embedded[ id ] = key
		Zones.Editor.EmbeddedOffsets[ id ] = data[ 1 ] - data[ 3 ] - id
	end
end

--[[
	Description: Sets up the zone entities themselves
--]]
function Zones.Setup()
	Zones.BotPoints = {}
	Zones.StartPoints = {}

	for i = 1, #ZoneCache do
		local zone = ZoneCache[ i ]
		local Type = zone["nType"]
		local P1, P2 = zone["vPos1"], zone["vPos2"]
		local M1, D1 = (P1 + P2) / 2, P2 - P1

		-- Check for custom functions
		if Zones.CustomEnts[ Type ] then
			ZoneEnts[ #ZoneEnts + 1 ] = Zones.CustomEnts[ Type ]( zone )

			continue
		end

		-- Sets start points for respawning
		if Type == Zones.Type["Normal Start"] then
			Zones.StartPoints[ #Zones.StartPoints + 1 ] = { P1, P2, M1 }
			Zones.BotPoints[ #Zones.BotPoints + 1 ] = Vector( M1.x, M1.y, P1.z )
		end

		-- Creates the entity
		local ent = ents.Create( "game_timer" )
		ent:SetPos( M1 )
		ent.min = P1
		ent.max = P2
		ent.directbound = D1.x > 32 and D1.y > 32
		ent.zonetype = Type
		ent.truetype = Type

		-- Check the embedded datatype
		for key,data in pairs( Zones.Embedded ) do
			if Type >= data[ 1 ] and Type <= data[ 2 ] then
				ent.zonetype = Zones.Type[ key ]
				ent.embedded = Type - data[ 1 ] + data[ 3 ]
			end
		end

		-- Set actively monitored start zones
		if ent.zonetype == Zones.Type["Normal Start"] or ent.zonetype == Zones.Type["Bonus Start"] then
			if D1.x > 24 and D1.y > 24 and D1.z > 8 then
				ZoneWatch[ ent ] = true
			end
		end

		-- Create the entity
		ent:Spawn()

		ZoneEnts[ #ZoneEnts + 1 ] = ent
		ClientEnts[ ent:EntIndex() ] = { ent.zonetype, ent.embedded, ent.directbound }
	end

	-- And broadcast them
	Zones.BroadcastClientEnts()
end

--[[
	Description: Reloads all zone entities and re-broadcasts them
--]]
function Zones.Reload( nodb )
	for i = 1, #ZoneEnts do
		if IsValid( ZoneEnts[ i ] ) then
			ZoneEnts[ i ]:Remove()
			ZoneEnts[ i ] = nil
		end
	end

	if not nodb then
		ZoneCache = {}
	end

	ZoneEnts = {}
	ZoneWatch = {}

	if nodb then
		Zones.Setup()
	else
		Zones.Load( function()
			Zones.Setup()

			Core.BonusEntitySetup()
		end )
	end
end
Core.ReloadZones = Zones.Reload

--[[
	Description: Translates a zone ID to a zone name
--]]
function Zones.GetName( n )
	for name,id in pairs( Zones.Type ) do
		if id == n then
			return name
		end
	end

	return "Unknown"
end
Core.GetZoneName = Zones.GetName

--[[
	Description: Gets the center point of a given zone with this type
	Notes: This will not work if the zone is double
--]]
function Zones.GetCenterPoint( nType, nEmbed )
	for i = 1, #ZoneEnts do
		local zone = ZoneEnts[ i ]
		if IsValid( zone ) and zone.zonetype == nType then
			if nEmbed and nEmbed != zone.embedded then continue end

			local pos = zone:GetPos()
			local height = zone.max.z - zone.min.z

			pos.z = pos.z - (height / 2)
			return pos
		end
	end
end

--[[
	Description: Checks if the player is inside of the given zone
--]]
function Zones.IsInside( ply, nType, nEmbed )
	for i = 1, #ZoneEnts do
		local zone = ZoneEnts[ i ]
		if IsValid( zone ) and zone.zonetype == nType then
			if nEmbed and nEmbed != zone.embedded then continue end

			if table.HasValue( ents.FindInBox( zone.min, zone.max ), ply ) then
				return true
			end
		end
	end
end
Core.IsInsideZone = Zones.IsInside

--[[
	Description: Gets the center point of a bonus zone if it exists
--]]
function Zones.GetBonusPoint( nID )
	for i = 1, #ZoneEnts do
		local zone = ZoneEnts[ i ]
		if IsValid( zone ) then
			if zone.zonetype != Zones.Type["Bonus Start"] then continue end

			local embed = zone.embedded and zone.embedded - 1 or 0
			if embed == nID then
				return { zone.min, zone.max, zone:GetPos() }
			end
		end
	end
end
Core.GetBonusPoint = Zones.GetBonusPoint

--[[
	Description: Gets all bonus ids
--]]
function Zones.GetBonusIDs()
	local ids = {}

	for i = 1, #ZoneEnts do
		local zone = ZoneEnts[ i ]
		if IsValid( zone ) then
			if zone.zonetype != Zones.Type["Bonus Start"] then continue end

			ids[ #ids + 1 ] = zone.embedded and zone.embedded - 1 or 0
		end
	end

	return ids
end

--[[
	Description: Checks if the bonus is being done on the right style
--]]
function Zones.ValidateBonusStyle( ply, embedded )
	if not ply.Bonus then return false end

	return ply.Bonus == (embedded and embedded - 1 or 0)
end

--[[
	Description: Analyzes a zone and returns more data if available
--]]
function Zones.GetZoneInfo( zone )
	if not IsValid( zone ) then return "" end
	if Zones.Editor.Embedded[ zone.zonetype ] then
		return " (Data: " .. (zone.embedded or "Blank") .. ")"
	else
		return ""
	end
end

--[[
	Description: Checks if an option is applied to a map
--]]
function Zones.IsOption( opt )
	return bit.band( Timer.Options, opt ) > 0
end

--[[
	Description: Applies all options to the map
--]]
function Zones.CheckOptions()
	if Zones.IsOption( Zones.Options.NoSpeedLimit ) then
		RunConsoleCommand( "sv_maxvelocity", "100000" )
	else
		RunConsoleCommand( "sv_maxvelocity", tostring( Config.Var.GetInt( "SpeedLimit" ) ) )
	end

	if Zones.IsOption( Zones.Options.Checkpoints ) then
		Config.Var.SetShared( "Checkpoints", "1" )
	end
end

--[[
	Description: Finds the most appropriate spawn angle
--]]
function Zones.SetSpawnAngles()
	-- Set base value
	local top, selected = 0

	-- Loop over the spawns
	for value,num in pairs( Timer.Spawns ) do
		if num > top then
			top = num
			selected = value
		end
	end

	-- Get the top one
	if selected then
		Timer.BaseAngles = util.StringToType( selected, "Angle" )
	end

	-- Let's convert stored data
	local tps = {}
	for _,item in pairs( Timer.Teleports ) do
		tps[ #tps + 1 ] = { util.StringToType( item[ 1 ], "Vector" ), util.StringToType( item[ 2 ], "Angle" ) }
	end

	-- Create a temporary function
	local function FindNearestSpawn( at, tab )
		local order = {}
		for _,v in pairs( tab ) do
			local distance = (at - v[ 1 ]):Length()
			order[ #order + 1 ] = { Dist = distance, Vec = v[ 1 ], Ang = v[ 2 ] }
		end

		-- Sort by distance
		table.SortByMember( order, "Dist", true )

		-- Get the one that doesn't collide
		for i = 1, #order do
			local tr = util.TraceLine( { start = at, endpos = order[ i ].Vec } )
			if not tr.HitWorld then
				return order[ i ]
			end
		end

		-- Otherwise, return the top entry
		return order[ 1 ]
	end

	-- Now let's find the bonus zones
	Timer.BonusAngles = {}

	-- Get the list
	for _,i in pairs( Zones.GetBonusIDs() ) do
		local data = Zones.GetBonusPoint( i )

		if data then
			local near = FindNearestSpawn( data[ 3 ], tps )

			if near then
				Timer.BonusAngles[ i ] = near.Ang
			end
		end
	end
end

--[[
	Description: Processes a velocity zone touch
--]]
function PLAYER:ProcessVelocityZone( ent, endt )
	-- Validate whether the player is legit and in a bonus
	if not IsValid( self ) or not self.Style or not ent.embedded then return end

	-- Extract all useful data from the embedded data
	local data = tostring( ent.embedded )
	local vel = math.modf( ent.embedded )
	local pos = string.find( data, ".", 1, true )
	local ang = tonumber( string.sub( data, pos + 1, pos + 2 ) ) or 0
	local bits = tonumber( string.sub( data, pos + 3 ) ) or 0
	local vec = Vector( 1, 0, 0 )

	-- See which EntityTouch event we want to handle
	if bit.band( bits, 1 ) > 0 then
		if endt then return end
	else
		if not endt then return end
	end

	-- Check if double-boosting is disabled
	if bit.band( bits, 2 ) > 0 then
		if self:GetVelocity():Length2D() * 2 > vel * 100 then return end
	end

	-- This means bonus only
	if bit.band( bits, 4 ) == 0 then
		if not self.TimerBonus or not self.Bonus then return end
	end

	-- Upwards boost
	if bit.band( bits, 8 ) > 0 then
		vec = Vector( 0, 0, 1 )
	elseif bit.band( bits, 16 ) > 0 then
		vec = Vector( 1, 0, 1 )
	end

	-- Transform the vector
	vec:Mul( vel * 100 )
	vec:Rotate( Angle( 0, ang * 10, 0 ) )

	-- Apply the velocity to the player
	self:SetVelocity( vec )
end

-- Custom entity initialization
Zones.CustomEnts = {}
Zones.CustomEnts[ Zones.Type["Solid AC"] ] = function( zone )
	local Type = zone["nType"]
	local P1, P2 = zone["vPos1"], zone["vPos2"]
	local M1 = (P1 + P2) / 2

	-- Creates the entity
	local ent = ents.Create( "SolidBlockEnt" )
	ent:SetPos( P1 )
	ent.basemin = P1
	ent.basemax = P2
	ent.min = Vector( 0, 0, 0 )
	ent.max = P2 - P1
	ent.zonetype = Type
	ent.truetype = Type
	ent:Spawn()

	return ent
end


-- Zone editor
Zones.Editor = {
	Embedded = {},
	EmbeddedOffsets = {},

	List = {},
	Double = {
		[Zones.Type["Normal Start"]] = false,
		[Zones.Type["Normal End"]] = false,
		[Zones.Type["Bonus Start"]] = false,
		[Zones.Type["Bonus End"]] = false
	}
}


--[[
	Description: Start setting a zone with the given ID
--]]
function Zones.Editor:StartSet( ply, ID )
	-- Set default params
	local params = { "None" }

	-- Avoid problems with people overriding zones they shouldn't be overriding
	if self.Double[ ID ] != false and not ply.ZoneExtra then
		ply.ZoneExtra = true
		params[ #params + 1 ] = "Additional"
	elseif ply.ZoneExtra then
		params[ #params + 1 ] = "Additional"
	end

	-- Check if snapping is disabled
	if ply.ZoneNoSnap then
		params[ #params + 1 ] = "No snapping"
	end

	-- Check if it's embeddable
	if self.Embedded[ ID ] then
		params[ #params + 1 ] = "Embedded (" .. (ply.AdminZoneID and ply.AdminZoneID or "None") .. ")"
	end

	-- Remove blank embed ID
	if #params > 1 then
		table.remove( params, 1 )
	end

	-- Set the active session
	self.List[ ply ] = {
		Active = true,
		Start = ply:GetPos(),
		Type = ID,
		NoSnap = ply.ZoneNoSnap
	}

	-- Let the client know we're setting a zone
	Core.Send( ply, "Global/Admin", { "EditZone", self.List[ ply ] } )
	Core.Print( ply, "Admin", Core.Text( "ZoneStart", Zones.GetName( ID ), string.Implode( ", ", params ) ) )
end

--[[
	Description: Checks if we're setting something and finishes it if we're all good
--]]
function Zones.Editor:CheckSet( ply, finish, extra )
	-- Only finish if we have an active session
	if self.List[ ply ] then
		-- When we're finishing, actually set the zone
		if finish then
			if extra then
				ply.ZoneExtra = nil
			end

			-- Finalize the session
			self:FinishSet( ply, extra )
		end

		return true
	end
end

--[[
	Description: Cancels a zone placement session
--]]
function Zones.Editor:CancelSet( ply, force )
	-- Clear session and let the client know of this as well
	self.List[ ply ] = nil
	Core.Send( ply, "Global/Admin", { "EditZone", self.List[ ply ] } )
	Core.Print( ply, "Admin", Core.Text( force and "ZoneCancel" or "ZoneFinish" ) )
end

--[[
	Description: Finishes the session and inserts the new entry straight into the database
--]]
function Zones.Editor:FinishSet( ply, extra )
	-- Get the active editor
	local editor = self.List[ ply ]
	if not editor then return end

	-- Custom zones
	if ply.AdminZoneID and Zones.Editor.EmbeddedOffsets[ editor.Type ] then
		local embed = editor.Type + Zones.Editor.EmbeddedOffsets[ editor.Type ] + ply.AdminZoneID

		if editor.Type == Zones.Type["Stage End"] then
			ply.AdminZoneID = ply.AdminZoneID + 1
			Core.Print( ply, "Admin", Core.Text( "ZoneIDIncrement", ply.AdminZoneID ) )
		end

		editor.Type = embed
	end

	-- If we haven't got an end set yet, set it to the current position
	if not editor.End then
		editor.End = ply:GetPos()
	end

	-- Obtain the coordinates
	local s, e, t = editor.Start, editor.End, editor.Type
	if not editor.NoSnap then
		local n, z = 32
		if ply:KeyDown( IN_SPEED ) then z = true end
		if ply:KeyDown( IN_DUCK ) then n = 16 end

		s, e = Core.RoundTo( s, n ), Core.RoundTo( e, n, z )
	end

	-- Get the vector strings
	local Min = util.TypeToString( Vector( math.min( s.x, e.x ), math.min( s.y, e.y ), math.min( s.z, e.z ) ) )
	local Max = util.TypeToString( Vector( math.max( s.x, e.x ), math.max( s.y, e.y ), math.max( s.z + 128, e.z + 128 ) ) )

	-- Check if it's a new zone or an existing one and update it
	Prepare(
		"SELECT nType FROM game_zones WHERE szMap = {0} AND nType = {1}",
		{ game.GetMap(), t }
	)( function( data, varArg )
		local function FinishSetZone()
			-- Close the session and reload all zones
			Zones.Editor:CancelSet( ply )
			Zones.Reload()
		end

		if Core.Assert( data, "nType" ) and not varArg then
			Prepare(
				"UPDATE game_zones SET vPos1 = {0}, vPos2 = {1} WHERE szMap = {2} AND nType = {3}",
				{ Min, Max, game.GetMap(), t }
			)( FinishSetZone )
		else
			Prepare(
				"INSERT INTO game_zones VALUES ({0}, {1}, {2}, {3})",
				{ game.GetMap(), t, Min, Max }
			)( FinishSetZone )
		end
	end, extra )
end


--[[
	Description: Setups up all server entities
--]]
local MapPlatforms, PlatformBoosters = {}, {}
function Core.SetupMap()
	-- Check the spawns
	Zones.SetSpawnAngles()

	-- Check if we have some custom PostInit hooks
	if Zones.CustomEntitySetup then
		Zones.CustomEntitySetup( Timer )
	end

	-- Remove extra pointless stuff that lags (only do that here to ensure they have loaded already)
	hook.Remove( "PlayerTick", "TickWidgets" )
	hook.Remove( "PreDrawHalos", "PropertiesHover" )

	-- Surfers hate bullets!
	if Config.IsSurf then
		hook.Remove( "PlayerPostThink", "ProcessFire" )
	end

	-- Pre-cache models
	for _,model in pairs( Core.ContentText( "ValidModels" ) ) do util.PrecacheModel( "models/player/" .. model .. ".mdl" ) end
	for _,model in pairs( Core.ContentText( "FemaleModels" ) ) do util.PrecacheModel( "models/player/" .. model .. ".mdl" ) end

	-- Enable fading platforms
	for _,ent in pairs( ents.FindByClass( "func_lod" ) ) do
		ent:SetRenderMode( RENDERMODE_TRANSALPHA )
	end

	-- Gets rid of the "Couldn't dispatch user message (21)" errors in console
	for _,ent in pairs( ents.FindByClass( "env_hudhint" ) ) do
		ent:Remove()
	end

	-- Enable fading non-platforms
	for _,ent in pairs( ents.GetAll() ) do
		if ent:GetRenderFX() != 0 and ent:GetRenderMode() == 0 then
			ent:SetRenderMode( RENDERMODE_TRANSALPHA )
		end
	end

	-- Clean the table if there is anything in it
	if not MapPlatforms.NoWipe then
		MapPlatforms = {}
		PlatformBoosters = {}
	else
		MapPlatforms.NoWipe = nil
	end

	-- Since this might get called a lot, localize
	local index = IndexPlatform
	local inbox = ents.FindInBox
	local inmap = game.GetMap()

	-- Loop over all door platforms
	for _,ent in pairs( ents.FindByClass( "func_door" ) ) do
		if not ent.IsP then continue end

		local mins = ent:OBBMins()
		local maxs = ent:OBBMaxs()
		local h = maxs.z - mins.z

		if (h > 80 and not Zones.SpecialDoorMaps[ inmap ]) or Zones.MovingDoorMaps[ inmap ] then continue end
		local tab = inbox( ent:LocalToWorld( mins ) - Vector( 0, 0, 10 ), ent:LocalToWorld( maxs ) + Vector( 0, 0, 5 ) )

		if (tab and #tab > 0) or ent.BHSp > 100 then
			local teleport
			for i = 1, #tab do
				if IsValid( tab[ i ] ) and tab[ i ]:GetClass() == "trigger_teleport" then
					teleport = tab[ i ]
				end
			end

			if teleport or ent.BHSp > 100 then
				ent:Fire( "Lock" )
				ent:SetKeyValue( "spawnflags", "1024" )
				ent:SetKeyValue( "speed", "0" )
				ent:SetRenderMode( RENDERMODE_TRANSALPHA )

				if ent.BHS then
					ent:SetKeyValue( "locked_sound", ent.BHS )
				else
					ent:SetKeyValue( "locked_sound", "DoorSound.DefaultMove" )
				end

				local nid = ent:EntIndex()
				index( nid )
				MapPlatforms[ #MapPlatforms + 1 ] = nid

				if ent.BHSp > 100 then
					index( nid, ent.BHSp )
					PlatformBoosters[ nid ] = ent.BHSp
				end
			end
		end
	end

	-- Loop over all button platforms
	for _,ent in pairs( ents.FindByClass( "func_button" ) ) do
		if not ent.IsP then continue end
		if ent.SpawnFlags == "256" then
			local mins = ent:OBBMins()
			local maxs = ent:OBBMaxs()
			local tab = inbox( ent:LocalToWorld( mins ) - Vector( 0, 0, 10 ), ent:LocalToWorld( maxs ) + Vector( 0, 0, 5 ) )

			if tab and #tab > 0 then
				local teleport
				for i = 1, #tab do
					if IsValid( tab[ i ] ) and tab[ i ]:GetClass() == "trigger_teleport" then
						teleport = tab[ i ]
					end
				end

				if teleport then
					ent:Fire( "Lock" )
					ent:SetKeyValue( "spawnflags", "257" )
					ent:SetKeyValue( "speed", "0" )
					ent:SetRenderMode( RENDERMODE_TRANSALPHA )

					if ent.BHS then
						ent:SetKeyValue( "locked_sound", ent.BHS )
					else
						ent:SetKeyValue( "locked_sound", "None (Silent)" )
					end

					local nid = ent:EntIndex()
					index( nid )
					MapPlatforms[ #MapPlatforms + 1 ] = nid
				end
			end
		end
	end

	-- Load the zones from the database
	Zones.Load( function()
		-- Load entities
		Zones.Setup()

		-- Check if we have additional functions to be executed
		Core.BonusEntitySetup()
	end )
end

--[[
	Description: Sends the platform indexes as well as timer indexes to the client
--]]
function Zones.SendPlatforms( ply )
	-- Send entity data
	NetPrepare( "Client/Entities", { ClientEnts, Zones.Type, MapPlatforms, PlatformBoosters, Config.Var.GetShared() } ):Send( ply )
end

--[[
	Description: Broadcast all timer entities
--]]
function Zones.BroadcastClientEnts()
	NetPrepare( "Client/Entities", { ClientEnts } ):Broadcast()
end



--[[
	Description: Gets the current time in date format if required
--]]
function Timer.GetCurrentDate( bFormat )
	if bFormat then
		return os.date( "%Y-%m-%d %H:%M:%S", os.time() )
	else
		return os.time()
	end
end

--[[
	Description: Converts seconds to a readable and detailed time
--]]
function Core.ConvertTime( Seconds )
	if Seconds >= 3600 then
		return string.format( "%d:%.2d:%.2d.%.3d", math.floor( Seconds / 3600 ), math.floor( Seconds / 60 % 60 ), math.floor( Seconds % 60 ), math.floor( Seconds * 1000 % 1000 ) )
	else
		return string.format( "%.2d:%.2d.%.3d", math.floor( Seconds / 60 % 60 ), math.floor( Seconds % 60 ), math.floor( Seconds * 1000 % 1000 ) )
	end
end
Timer.Convert = Core.ConvertTime

--[[
	Description: Returns a variable from the Timer instance
--]]
function Core.GetMapVariable( szType )
	if szType == "Plays" then
		return Timer.Plays
	elseif szType == "Multiplier" then
		return Timer.Multiplier
	elseif szType == "Bonus" then
		return Timer.BonusMultiplier
	elseif szType == "Options" then
		return Timer.Options
	elseif szType == "OptionList" then
		return Zones.Options
	elseif szType == "Tier" then
		return Timer.Tier
	elseif szType == "Type" then
		return Timer.Type
	elseif szType == "IsBindBypass" then
		return Bypass
	elseif szType == "Platforms" then
		return MapPlatforms
	elseif szType == "UnrealBoost" then
		return BoostTimer
	elseif szType == "WRSounds" then
		return WRSounds
	end
end

--[[
	Description: Sets a variable on the timer object
--]]
function Core.SetMapVariable( szType, varObj )
	Timer[ szType ] = varObj
end

--[[
	Description: Allows remote files to disable +left and +right checking
--]]
function Core.BypassStrafeBinds( bValue )
	Bypass = bValue
end

--[[
	Description: Gets all the zone entities from the table
--]]
function Core.GetZoneEntities( data, set )
	if data then
		if set then
			ZoneCache = set
		else
			return ZoneCache
		end
	else
		return ZoneEnts
	end
end

--[[
	Description: Translates a zone name to a zone ID
--]]
function Core.GetZoneID( szType )
	if not szType then return Zones.Type end
	return Zones.Type[ szType ]
end

--[[
	Description: Gets the center point of a zone with the given type
--]]
function Core.GetZoneCenter( bonus, other, embed )
	return Zones.GetCenterPoint( other and Zones.Type[ other ] or (bonus and Zones.Type["Bonus End"] or Zones.Type["Normal End"]), embed )
end

--[[
	Description: Returns more data about a zone
--]]
function Core.GetZoneInfo( zone )
	return Zones.GetZoneInfo( zone )
end

--[[
	Description: Returns the zone editor table for remote usage
--]]
function Core.GetZoneEditor()
	return Zones.Editor
end

--[[
	Description: Reloads options and executes checks
--]]
function Core.ReloadMapOptions()
	Zones.CheckOptions()
end

--[[
	Description: Checks if an option is applied
--]]
function Core.IsMapOption( opt )
	return Zones.IsOption( opt )
end

--[[
	Description: Gets all bonus IDs
--]]
function Core.GetBonusIDs()
	return Zones.GetBonusIDs()
end

--[[
	Description: Gets the multiplier for the given style
--]]
function Core.GetMultiplier( nStyle, bAll )
	return Timer.GetMultiplier( nStyle, bAll )
end

--[[
	Description: Gets the average for the given style
--]]
function Core.GetAverage( nStyle )
	if GetAverage( nStyle ) > 0 then
		CalcAverage( nStyle )
		return GetAverage( nStyle )
	else
		return 0
	end
end

--[[
	Description: Adds a version to the RTV tracker
--]]
function Core.AddMaplistVersion( nAmount )
	RTV:UpdateVersion( nAmount )
end

--[[
	Description: Gets the map list version (duh, that's what the name of the function implies)
--]]
function Core.GetMaplistVersion()
	return RTV.Version
end

--[[
	Description: Executes a type of map check and returns that data
--]]
function Core.MapCheck( szMap, IsBSP, GetData )
	if IsBSP then
		if GetData then
			return Maps
		else
			return RTV.IsAvailable( szMap )
		end
	else
		if GetData then
			return RTV.GetMapData( szMap )
		else
			return RTV.MapExists( szMap )
		end
	end
end

--[[
	Description: Change whetehr or not the map vote is being cancelled
--]]
function Core.ChangeVoteCancel()
	RTV.CancelVote = not RTV.CancelVote

	return RTV.CancelVote
end

--[[
	Description: Force starts a vote
--]]
function Core.ForceStartRTV()
	RTV.StartVote()
end

--[[
	Description: Gets all the records in the top list cache
--]]
function Core.GetPlayerTop( nStyle )
	return TopListCache[ nStyle ] or {}
end

--[[
	Description: Gets all the players holding WRs
--]]
function Core.GetPlayerWRTop( nStyle )
	return Timer.TopWRList[ nStyle ] or {}
end

--[[
	Description: Gets the amount of unique players on a style
--]]
function Core.GetPlayerCount( nStyle )
	return Timer.PlayerCount[ nStyle ] or 0
end

--[[
	Description: Make sure that records can be inserted for this style
--]]
function Core.EnsureStyleRecords( nStyle )
	if not Records[ nStyle ] then
		Records[ nStyle ] = {}
	end
end

--[[
	Description: Gets all records on a player for each style
--]]
function Core.GetStyleRecords( ply )
	local values = {}
	for i = Styles.Normal, Config.MaxStyle do
		local nTime, nID = Timer.GetPlayerRecord( ply, i )
		if nTime > 0 and nID > 0 then
			values[ i ] = { nTime, nID }
		end
	end

	return values
end

--[[
	Description: Gets a part of the record list (from nStart to nMaximum)
--]]
function Core.GetRecordList( nStyle, nStart, nMaximum )
	local tab = {}

	for i = nStart, nMaximum do
		if Records[ nStyle ] and Records[ nStyle ][ i ] then
			tab[ i ] = Records[ nStyle ][ i ]
		end
	end

	return tab
end

--[[
	Description: Gets the top times in a list
--]]
function Core.GetTopTimes()
	local tab = {}

	for style,data in pairs( Records ) do
		if data[ 1 ] and data[ 1 ]["nTime"] then
			tab[ style ] = data[ 1 ]
		end
	end

	return tab
end

--[[
	Description: Gets the amount of records on a style
--]]
function Core.GetRecordCount( nStyle )
	return GetRecordCount( nStyle )
end

--[[
	Description: Gets the base statistics loaded on startup
--]]
function Core.GetBaseStatistics()
	return Timer.BaseStatistics
end

--[[
	Description: Returns when a map was last played
--]]
function Core.GetLastPlayed( szMap )
	if Maps[ szMap ] then
		return Maps[ szMap ].szDate, Maps[ szMap ]
	end
end

--[[
	Description: Clears out the RTV wait period
--]]
function Core.ClearWaitPeriod()
	RTV.WaitPeriod = 0
end

--[[
	Description: Returns the amount of time left before the vote starts
--]]
function Core.GetTimeLeft()
	return RTV.End - ST()
end

--[[
	Description: Updates the command count statistic
--]]
function Core.UpdateCommandCount()
	Timer.BaseStatistics[ 5 ], Timer.BaseStatistics[ 6 ] = Core.CountCommands()
end



-- Fixes short lags upon loadout of several maps
local function KeyValueChecks( ent, key, value )
	if ent:GetClass() == "info_player_counterterrorist" or ent:GetClass() == "info_player_terrorist" then
		if key == "angles" then
			if not Timer.Spawns[ value ] then
				Timer.Spawns[ value ] = 1
			else
				Timer.Spawns[ value ] = Timer.Spawns[ value ] + 1
			end
		end
	elseif ent:GetClass() == "info_teleport_destination" then
		if key == "origin" then
			Timer.Teleports[ #Timer.Teleports + 1 ] = value
		elseif key == "angles" then
			Timer.Teleports[ #Timer.Teleports ] = { Timer.Teleports[ #Timer.Teleports ], value }
		end
	elseif ent:GetClass() == "game_player_equip" then
		if string.sub( key, 1, 4 ) == "ammo" or string.sub( key, 1, 5 ) == "weapon" or string.sub( 1, 5 ) == "item_" then
			return "1"
		end
	end
end
hook.Add( "EntityKeyValue", "KeyValueChecks", KeyValueChecks )

local uk, us, un = IN_ATTACK2, Styles.Unreal, next
local function UnrealBoostKey( ply, key )
	if key == uk and ply.Style == us then
		ply:DoUnrealBoost()
	end
end
hook.Add( "KeyPress", "UnrealKeyPress", UnrealBoostKey )

local function UnrealBoostBind( ply, _, varArgs )
	if ply.Style == us then
		local force
		if varArgs and varArgs[ 1 ] and tonumber( varArgs[ 1 ] ) then
			force = tonumber( varArgs[ 1 ] )

			if force then
				force = math.floor( force )

				if force < 1 or force > 4 then
					force = 1
				end
			end
		end

		ply:DoUnrealBoost( force )
	end
end
concommand.Add( "unrealboost", UnrealBoostBind )

-- Gamemode specific checks
if not Config.IsSurf then
	-- Check for this press every frame, otherwise we'll have to do it on the client and I don't like that
	local function BlockMovementTypes( ply, data, cmd )
		-- Use this hook to also monitor start zones
		local pos, vel = data:GetOrigin(), data:GetVelocity()
		for e in un, ZoneWatch do
			for p in un, e.Players do
				if pos.x >= e.min.x and pos.y >= e.min.y and pos.x <= e.max.x and pos.y <= e.max.y then
					if vel.z < 0 then
						data:SetVelocity( Vector( 0, 0, -1000 ) )
						continue
					elseif vel.z > 0 then
						local mi, ma, pos = e.min + Vector( 12, 12, 0 ), e.max - Vector( 12, 12, 0 ), data:GetOrigin()
						if pos.x > mi.x and pos.y > mi.y and pos.x < ma.x and pos.y < ma.y then
							data:SetVelocity( Vector( 0, 0, -100 ) )
							continue
						end
					end
				end
			end
		end

		-- Block ladder boosting
		if vel.x == 0 and vel.y == 0 and math.Round( vel.z - ply:GetJumpPower(), 3 ) == 258.000 then
			vel.z = ply:GetJumpPower()
			data:SetVelocity( vel )
		end

		-- Make sure to only check it when we set it to block it (so we can still use it on fly maps)
		if Bypass then return end

		-- Whenever we are pressing +left or +right, check if they have any timers, and stop them if they do
		if data:KeyDown( Lefty ) or data:KeyDown( Righty ) then
			if ply.TAS then return end
			if ply.TimerNormal or ply.TimerBonus then
				if ply:StopAnyTimer() then
					Core.Print( ply, "Timer", Core.Text( "StyleLeftRight" ) )
				end
			end
		end
	end
	hook.Add( "SetupMove", "BlockMovementTypes", BlockMovementTypes )
elseif Config.IsSurf then
	-- Check for each jump landing to make sure we're legit
	local LastMessaged, SpawnJumps = {}, {}
	local function PrehopLimitation( ply )
		if ply.Practice or Zones.IsOption( Zones.Options.TelehopMap ) then return end
		if ply:InSpawn() then
			if ply.LastResetData and ST() - (ply.LastResetData[ 1 ] or 0) < 0.1 then return end
			if ply:KeyDown( IN_JUMP ) or ST() - (SpawnJumps[ ply ] or ST() - 2) < 1 then
				ply:ResetSpawnPosition()

				timer.Simple( 0.01, function()
					if IsValid( ply ) then
						ply:SetLocalVelocity( Vector( 0, 0, 0 ) )
					end
				end )

				if not LastMessaged[ ply ] or ST() - LastMessaged[ ply ] > 2 then
					Player.Notification( ply, "Popup", { "Timer", Core.Text( "ZoneJumpInside" ), "information", 4 } )
					LastMessaged[ ply ] = ST()
				end
			end

			SpawnJumps[ ply ] = ST()
		else
			SpawnJumps[ ply ] = 0
		end
	end
	hook.Add( "OnPlayerHitGround", "PrehopLimitation", PrehopLimitation )
end

-- Load all extensions
if file.Exists( Config.BaseType .. "/gamemode/extensions", "LUA" ) then
	-- Scan the directory for extensions
	local files = file.Find( Config.BaseType .. "/gamemode/extensions/*.lua", "LUA" )
	local blacklist = string.Explode( ",", Config.Var.Get( "BlockExtensions" ) )

	-- Translate the blacklist
	local blocked = {}
	for i = 1, #blacklist do
		blocked[ string.Trim( blacklist[ i ] ) ] = true
	end

	-- Create an init function holder
	Timer.PostInitFunc = {}

	-- Loop over the files
	for _,f in pairs( files ) do
		local name = string.sub( f, 4, -5 )
		if blocked[ name ] then
			Core.PrintC( "[Startup] Skipped activation of extension '" .. string.sub( f, 1, -5 ) .. "'" )
			continue
		else
			Config.Var.Present( name, true )
		end

		if string.sub( f, 1, 2 ) == "cl" then
			AddCSLuaFile( Config.BaseType .. "/gamemode/extensions/" .. f )
		elseif string.sub( f, 1, 2 ) == "sv" then
			include( Config.BaseType .. "/gamemode/extensions/" .. f )

			if Core.PostInitFunc then
				Timer.PostInitFunc[ #Timer.PostInitFunc + 1 ] = Core.PostInitFunc
			end

			Core.PostInitFunc = nil
		end
	end
end

-- Check if we have a map lua file, if we do, execute it
local files = file.Find( Config.BaseType .. "/gamemode/maps/*.lua", "LUA" )
for _,f in pairs( files ) do
	-- Replace for global types
	local ef = f:gsub( "wildcard", "*" ):gsub( ".lua", "" )

	-- Check if the map matches
	if (string.find( ef, "*", 1, true ) and string.match( game.GetMap(), ef )) or f:gsub( ".lua", "" ) == game.GetMap() or ef == "*" then
		-- Check overrides
		if Zones[ "NoWildcard" ] and Zones[ "NoWildcard" ][ game.GetMap() ] and string.find( f, "wildcard", 1, true ) then continue end

		-- Create a global table to be populated
		__HOOK = {}
		__MAP = {}

		-- Load the individual map file
		include( Config.BaseType .. "/gamemode/maps/" .. f )

		-- Set the hook counter
		Timer.HookCount = (Timer.HookCount or 0) + 1

		-- Add all the custom hooks
		for identifier,func in pairs( __HOOK ) do
			hook.Add( identifier, identifier .. "_" .. game.GetMap() .. "_" .. Timer.HookCount, func )
		end

		-- Allow custom entities
		for identifier,bool in pairs( __MAP ) do
			if not Zones[ identifier ] then
				Zones[ identifier ] = {}

				if identifier == "CustomEntitySetup" then
					Zones[ identifier ] = bool
					break
				end
			end

			Zones[ identifier ][ game.GetMap() ] = bool
		end

		-- Dispose of that filthy global
		__HOOK = nil
		__MAP = nil
	end
end

-- Load all WR sounds
local sounds = file.Find( Config.BaseType .. "/content/sound/" .. Config.MaterialID .. "/*.mp3", "LUA" )
for _,f in pairs( sounds ) do
	WRSounds[ #WRSounds + 1 ] = string.sub( f, 1, #f - 4 )
end

-- Make sure nothing fucky happens when we don't have a SQL connection
for i = 1, #Ranks do
	Ranks[ i ][ 3 ] = {}
end
