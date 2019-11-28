-- Set tables and quick-access functions
local PlayerMeta = FindMetaTable( "Player" )

-- Scroll related storage tables
local FallTime, FallTicks = {}, {}
local LastGround, LastVelocity = {}, {}
local CancelJump, CheckTicks = {}, {}
local RatioHit, RatioMiss = {}, {}

-- Reference variables
local ValidMoves, ScrollStyles = { [-10000] = true, [-5000] = true, [0] = true, [5000] = true, [10000] = true }, { [8] = true, [9] = true }
local Left, Right, Jump, PickupTime, PickupFrame, TestButtons, BlockMove = IN_MOVELEFT, IN_MOVERIGHT, IN_JUMP, SysTime, FrameTime, bit.band, true

-- Main checking hook
local function CommandValidate( ply, cmd )
	-- Make sure to ignore bots and spectators
	if ply:IsBot() or not ply:Alive() then return end
	
	-- First get the SideMove and ONLY act when it's not 0, it's going to be 0 more than not, so this is more efficient
	local sm = cmd:GetSideMove()
	if sm != 0 then
		-- Check if the value is normal for the engine
		if not ValidMoves[ sm ] or not ValidMoves[ cmd:GetForwardMove() ] then
			-- If we're on stamina it's normal that it happens
			if ply.StaminaUse then return end
			
			-- Just fully block the movement
			cmd:ClearButtons()
			cmd:ClearMovement()
		
		-- When neither keys are pressed but we're still gaining speed it's suspicious
		elseif TestButtons( cmd:GetButtons(), Left ) == 0 and TestButtons( cmd:GetButtons(), Right ) == 0 then
			-- See if it's TAS
			if ply.TAS then return end
			
			-- Just fully block the movement
			cmd:ClearButtons()
			cmd:ClearMovement()
		end
	end
	
	-- Scroll times logic
	if not ScrollStyles[ ply.Style ] then return end
	
	-- Count falling time and block jumps when necessary
	local IsGround = ply:IsOnGround()
	if IsGround then
		if CancelJump[ ply ] then
			if cmd:KeyDown( Jump ) then
				cmd:RemoveKey( Jump )
			else
				CancelJump[ ply ] = nil
			end
		end
		
		FallTime[ ply ] = 0
	else
		FallTime[ ply ] = FallTime[ ply ] + 1
	end
	
	-- After we've been falling for a while, start checking jump inputs
	if FallTime[ ply ] > 35 then
		if cmd:KeyDown( Jump ) then
			FallTicks[ ply ] = FallTicks[ ply ] + 1
		end
	end
	
	-- If we've got more than 30 (for scrolling this will typically be ~10) we know something is wrong; block the next jump
	if FallTicks[ ply ] >= 30 then
		FallTicks[ ply ] = 0
		CancelJump[ ply ] = true
	end
	
	-- On to perfect jump checking! This means we just landed
	if IsGround and not LastGround[ ply ] then
		CheckTicks[ ply ] = 3
	end
	
	-- See if we've got ticks left to check
	if CheckTicks[ ply ] > 0 then
		CheckTicks[ ply ] = CheckTicks[ ply ] - 1
		
		-- This is our third tick and here we'll know if we've lost speed or not
		local Vel = ply:GetVelocity():Length2D()
		if CheckTicks[ ply ] == 0 and Vel > 80 then
			if Vel - LastVelocity[ ply ] >= 0 then
				RatioHit[ ply ] = RatioHit[ ply ] + 1
			else
				RatioMiss[ ply ] = RatioMiss[ ply ] + 1
			end
		end
		
		LastVelocity[ ply ] = Vel
	end
	
	-- Save our last state
	LastGround[ ply ] = IsGround
end
hook.Add( "StartCommand", "AntiStrafeHack", CommandValidate )

-- Set base values
local function EnableJumpTracking( ply )
	-- To save extra if-checks on the more intensive hook
	FallTime[ ply ] = 0
	FallTicks[ ply ] = 0
	CheckTicks[ ply ] = 0
	
	-- Set ratio calculation variables
	RatioHit[ ply ] = 0
	RatioMiss[ ply ] = 0
end
hook.Add( "PlayerInitialSpawn", "ScrollJumpTracking", EnableJumpTracking )

-- Allow remote access
function PlayerMeta:RequestJumpRatio( bReset, vData )
	-- Request data when restarting (handled by gamemode)
	if bReset then
		RatioHit[ self ] = 0
		RatioMiss[ self ] = 0
	else
		-- We don't want any NaNs appearing so return 0 if any of them are 0
		if RatioHit[ self ] == 0 and RatioMiss[ self ] == 0 then
			return 0
		else
			-- Get the data
			local nStyle = vData[ 1 ]
			local nJumps = vData[ 2 ]
			local nTime = vData[ 3 ]
			local nRecord = vData[ 4 ]
			
			-- Get the ratio of perfect jumps and compare that to a constant; only auto report if we have enough jumps measured (~15 jumps perfect in a row is near impossible)
			local ratio = math.Round( 100.0 * (RatioHit[ self ] / (RatioHit[ self ] + RatioMiss[ self ])), 1 )
			if ratio > 85 and (nJumps or 0) >= 15 then
				-- Report the player if we can, this will trigger an automatic demo recording
				if not Core.ReportPlayer then return end
				Core.ReportPlayer( {
					Submitter = nil,
					Target = self:SteamID(),
					ReporterSteam = "Console",
					Text = "[SMAC] Picked up a player (" .. self:Name() .. ", " .. self:SteamID() .. ") using a form of jump assistance. If you can, take a look at it in your !admin panel.",
					TypeID = 52,
					Comment = nStyle .. " Ratio " .. ratio .. " - Jumps " .. nJumps .. " - Time (C " .. nTime .. " R " .. nRecord .. ")"
				} )
			end
			
			return ratio
		end
	end
end