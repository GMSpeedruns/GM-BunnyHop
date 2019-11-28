local SMgr = {}
SMgr.Detections = {}
SMgr.DefaultDetail = 1
SMgr.ViewDetail = 7
SMgr.MaxDetail = 12
SMgr.AcceptableLimit = 5000

-- All data collection tables
local _S = Core.Config.Style
local BaseStyles, ValidStyles = { _S.Normal, _S.HSW, _S.Legit, _S["Easy Scroll"], Core.Config.IsPack and _S["Jump Pack"] or _S["Stamina"], _S.Unreal, _S["Low Gravity"] }, {}
local Monitored, MonitorAngle, MonitorLast, MonitorLastS, MonitorSimple, MonitorSet = {}, {}, {}, {}, {}, {}
local SyncTotal, SyncAlignA, SyncAlignB, SyncStrafes = {}, {}, {}, {}

-- Localized variables and angle function
local function norm( i ) if i > 180 then i = i - 360 elseif i < -180 then i = i + 360 end return i end
local fb, ogiw, wa, ml, mr = bit.band, FL_ONGROUND + FL_INWATER, MOVETYPE_WALK, IN_MOVELEFT, IN_MOVERIGHT

--[[
	Description: Sets the standard validity tables
--]]
function SMgr.Init( IsReload )
	-- Normalize the ValidStyles table
	for _,k in pairs( BaseStyles ) do
		ValidStyles[ k ] = true
	end
	
	-- Show that the SMgr loaded
	if not IsReload then
		Core.Config.Var.Activate( "SMgr", SMgr )
		Core.PrintC( "[Startup] Extension 'smgr' activated" )
	else
		for k,v in pairs( IsReload ) do
			ValidStyles[ k ] = v
		end
	end
end
Core.PostInitFunc = SMgr.Init


--[[
	Description: Enables stats monitoring
--]]
function SMgr.SetStrafeStats( ply )
	Monitored[ ply ] = true
	MonitorAngle[ ply ] = ply:EyeAngles().y
	SyncTotal[ ply ] = 0
	SyncAlignA[ ply ] = 0
	SyncAlignB[ ply ] = 0
	SyncStrafes[ ply ] = 0
end

--[[
	Description: Changes displaying state
--]]
function SMgr.ToggleSyncState( ply, bForce, bUnspec )
	if bUnspec then
		if MonitorSet[ ply ] != not not ply.SyncDisplay then
			ply.SyncDisplay = MonitorSet[ ply ]
		end
		
		return false
	end
	
	if bForce == nil then
		if not ply.SyncDisplay then
			ply.SyncDisplay = ""
		else
			ply.SyncDisplay = nil
		end
		
		MonitorSet[ ply ] = not not ply.SyncDisplay
		
		Core.Print( ply, "General", Core.Text( "PlayerSyncStatus", ply.SyncDisplay and "now" or "no longer" ) )
	else
		if bForce then
			ply.SyncDisplay = ""
		else
			ply.SyncDisplay = nil
		end
		
		MonitorSet[ ply ] = not not ply.SyncDisplay
	end
end

--[[
	Description: Local rounding function to fix the .0 decimal disappearing
--]]
function SMgr.Round( value, deci )
	return string.format( "%." .. deci .. "f", value )
end

--[[
	Description: Internally get the sync with a lot of decimals
--]]
function SMgr.GetSync( ply, nRound )
	if SyncTotal[ ply ] == 0 then
		return 0.0
	end
	
	return SMgr.Round( (SyncAlignA[ ply ] / SyncTotal[ ply ]) * 100.0, nRound or SMgr.DefaultDetail )
end

--[[
	Description: Get the other sync value
--]]
function SMgr.GetSyncEx( ply, nRound )
	if SyncTotal[ ply ] == 0 then
		return 0.0
	end

	return SMgr.Round( (SyncAlignB[ ply ] / SyncTotal[ ply ]) * 100.0, nRound or SMgr.DefaultDetail )
end

--[[
	Description: Get data for the Simple HUD
--]]
function SMgr.GetSimple( ply )
	return SMgr.GetSyncEx( ply, SMgr.DefaultDetail ), SMgr.GetStrafes( ply ), ply:GetJumps()
end

--[[
	Description: Sets the system to use the Simple HUD
--]]
function SMgr.SetSimple( ply, value )
	MonitorSimple[ ply ] = value
end

--[[
	Description: Gets the sync value in readable format
--]]
function SMgr.GetPlayerSync( ply, bFull )
	-- Only send something when we're on a valid style
	if ValidStyles[ ply.Style ] then
		if bFull then
			return SyncAlignA[ ply ], SyncAlignB[ ply ], SyncTotal[ ply ]
		else
			return SMgr.GetSync( ply, SMgr.DefaultDetail )
		end
	else
		return 0.0
	end
end

--[[
	Description: Sets the sync value on a player
--]]
function SMgr.SetPlayerSync( ply, a, b, t )
	SyncAlignA[ ply ], SyncAlignB[ ply ], SyncTotal[ ply ] = a, b, t
end

--[[
	Description: Gets the amount of strafes on a player
--]]
function SMgr.GetStrafes( ply )
	return SyncStrafes[ ply ] or 0
end

--[[
	Description: Sets the amount of strafes on a player
--]]
function SMgr.SetStrafes( ply, n )
	SyncStrafes[ ply ] = n
end


--[[
	Description: Checks if the player is odd
--]]
function SMgr.TestOddities( ply )
	-- Get Sync A and Sync B in maximum detail
	local SyncA = tonumber( SMgr.GetSync( ply, SMgr.MaxDetail ) )
	local SyncB = tonumber( SMgr.GetSyncEx( ply, SMgr.MaxDetail ) )
	
	-- See if the measurement is realistic
	if SyncTotal[ ply ] > SMgr.AcceptableLimit then
		-- See if the difference between the two is crazy high
		if math.abs( SyncA - SyncB ) > 70 then
			return true
		
		-- Also check for extremely low sync
		elseif SyncA < 5 and SyncB < 5 then
			return true
		end
	end
end

--[[
	Description: Send the sync to the player AND the spectators
--]]
function SMgr.SendSyncPlayer( ply, data, sync, strafes, jumps )
	local viewers = ply:Spectator( "Get", { true } )
	viewers[ #viewers + 1 ] = ply
	
	local ar = Core.Prepare( "Timer/SetSync" )
	ar:String( data or "" )
	
	if sync and strafes and jumps then
		ar:Bit( true )
		ar:Double( sync )
		ar:UInt( strafes, 16 )
		ar:UInt( jumps, 16 )
	else
		ar:Bit( false )
	end
	
	ar:Send( viewers )
end


--[[
	Description: Ticking function to distribute statistics to everyone
--]]
local function DistributeStatistics()
	for _,p in pairs( player.GetHumans() ) do
		if not p.Spectating then
			if p.SyncDisplay and ValidStyles[ p.Style ] then
				local szText = "Sync: " .. SMgr.GetSync( p, SMgr.DefaultDetail ) .. "%"
				if szText != p.SyncDisplay or MonitorSimple[ p ] then
					local s1, s2, s3
					if MonitorSimple[ p ] then
						s1, s2, s3 = SMgr.GetSimple( p )
						
						if s3 == MonitorLastS[ p ] then continue end
						MonitorLastS[ p ] = s3
					end
					
					SMgr.SendSyncPlayer( p, szText, s1, s2, s3 )
					p.SyncDisplay = szText
				end
				
				p.SyncVisible = true
			elseif p.SyncVisible then
				SMgr.SendSyncPlayer( p, nil )
				p.SyncVisible = nil
			end
			
			-- Check if the player is fishy
			if ValidStyles[ p.Style ] and not SMgr.Detections[ p ] and SMgr.TestOddities( p ) then
				SMgr.Detections[ p ] = true
				
				Core.ReportPlayer( {
					Submitter = nil,
					Target = p:SteamID(),
					ReporterSteam = "Console",
					Text = "[SMAC] Picked up a player (" .. p:Name() .. ", " .. p:SteamID() .. ") using a form of strafe assistance. If you can, take a look at it in your !admin panel.",
					TypeID = 51,
					Comment = "A " .. SMgr.GetSync( p, SMgr.MaxDetail ) .. " - B " .. SMgr.GetSyncEx( p, SMgr.MaxDetail )
				} )
			end
		else
			local t = p:GetObserverTarget()
			if not IsValid( t ) or not Monitored[ t ] then continue end
			
			if ValidStyles[ t.Style ] then
				local szText = "Sync: " .. SMgr.GetSync( t, SMgr.DefaultDetail ) .. "%"
				if szText != p.SyncDisplay then
					SMgr.SendSyncPlayer( p, szText )
					p.SyncDisplay = szText
				end
				
				p.SyncVisible = true
			elseif p.SyncVisible then
				SMgr.SendSyncPlayer( p, nil )
				p.SyncVisible = nil
			end
		end
	end
end
timer.Create( "SyncDistribute", 2, 0, DistributeStatistics )

--[[
	Description: Monitors the inputs and movement of each player and changes values for them
--]]
local function MonitorInputSync( ply, data )
	if not Monitored[ ply ] then return end

	local buttons = data:GetButtons()
	local ang = data:GetAngles().y

	if not ply:IsFlagSet( ogiw ) and ply:GetMoveType() == wa then
		local difference = norm( ang - MonitorAngle[ ply ] )
		
		if difference != 0 then
			local l, r = fb( buttons, ml ) > 0, fb( buttons, mr ) > 0
			if l or r then
				SyncTotal[ ply ] = SyncTotal[ ply ] + 1
				
				if difference > 0 then
					if l and not r then
						SyncAlignA[ ply ] = SyncAlignA[ ply ] + 1
						
						if MonitorLast[ ply ] != ml then
							MonitorLast[ ply ] = ml
							SyncStrafes[ ply ] = SyncStrafes[ ply ] + 1
						end
					end
					
					if data:GetSideSpeed() < 0 then
						SyncAlignB[ ply ] = SyncAlignB[ ply ] + 1
					end
				elseif difference < 0 then
					if r and not l then
						SyncAlignA[ ply ] = SyncAlignA[ ply ] + 1
						
						if MonitorLast[ ply ] != mr then
							MonitorLast[ ply ] = mr
							SyncStrafes[ ply ] = SyncStrafes[ ply ] + 1
						end
					end
					
					if data:GetSideSpeed() > 0 then
						SyncAlignB[ ply ] = SyncAlignB[ ply ] + 1
					end
				end
			end
		end
	end
	
	MonitorAngle[ ply ] = ang
end
hook.Add( "SetupMove", "MonitorInputSync", MonitorInputSync )