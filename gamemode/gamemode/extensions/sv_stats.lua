-- Welcome to the messiest file of the gamemode. Special thanks to George for making this core of this beautiful monstrosity.

-- Define config variables
Core.Config.Var.Add( "StatsMinLJ", "stats_min_lj", 256, "The minimum LJ distance for broadcasting a message to other players" )

-- Define some constants
local JUMP_LJ, JUMP_DROP, JUMP_UP, JUMP_LADDER, JUMP_WJ = 1, 2, 3, 4, 5
local MAX_STRAFES, EDGE_DIFF, EDGE_MAXIMUM = 50, 2.60, 25
local MIN_SUBMIT, MAX_SELECT = Core.Config.Var.GetInt( "StatsMinLJ" ), Core.Config.Var.GetInt( "TopLimit" )

-- Local functions for improved speed
local ba, uq = bit.band, util.QuickTrace
local enum_ij, enum_il, enum_ir, enum_la = IN_JUMP, IN_MOVELEFT, IN_MOVERIGHT, MOVETYPE_LADDER
local enum_ignores = { [Core.Config.Style["Low Gravity"]] = true, [Core.Config.Style["Unreal"]] = true }
local enum_names = { ["lj"] = JUMP_LJ, ["long"] = JUMP_LJ, ["wj"] = JUMP_WJ, ["weird"] = JUMP_WJ, ["ladder"] = JUMP_LADDER, ["lad"] = JUMP_LADDER, ["la"] = JUMP_LADDER }

-- The types of jumps that are measured
local jumptypes = { [JUMP_LJ] = "Long Jump", [JUMP_DROP] = "Drop Jump", [JUMP_UP] = "Up Jump", [JUMP_LADDER] = "Ladder Jump", [JUMP_WJ] = "Weird Jump" }
local shortnames = { [JUMP_LJ] = "LJ", [JUMP_WJ] = "WJ", [JUMP_LADDER] = "Ladder Jump" }
local jumpdist = { [JUMP_LJ] = 230, [JUMP_DROP] = 240, [JUMP_UP] = 150, [JUMP_LADDER] = 110, [JUMP_WJ] = 255 }
local jumpdistm = { [JUMP_LJ] = 295, [JUMP_DROP] = 0, [JUMP_UP] = 285, [JUMP_LADDER] = 250, [JUMP_WJ] = 335 }

-- ALL THE TABLES!
local islj, wj, inbhop, strafes, ducking, lastducking, didjump, jumptime, strafenum, strafingright, strafingleft, speed, lastspeed, newp, oldp, lastent, lastonground, jumpproblem, jumppos, jumpvel, tproblem, jumptype, ladder, strafe = {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}
local function ResetFields( p, ... ) for _,f in pairs( { ... } ) do f[ p ] = nil end end

-- The stats table
local Stats = {}
local Prepare = SQLPrepare
local Cache = { [JUMP_LJ] = {}, [JUMP_LADDER] = {}, [JUMP_WJ] = {} }

--[[
	Description: Loads the data from the LJ leaderboards
--]]
function Stats.Init( reload )
	for t,_ in pairs( Cache ) do
		Stats.Cleanup( t )
	end
	
	-- Load all stat values
	Prepare(
		"SELECT * FROM game_ljstats ORDER BY nValue DESC"
	)( function( data, varArg )
		if Core.Assert( data, "nType" ) then
			for j = 1, #data do
				Cache[ data[ j ]["nType"] ][ #Cache[ data[ j ]["nType"] ] + 1 ] = data[ j ]
			end
		end
	end )
	
	-- Print result
	Core.Config.Var.Activate( "Stats", Stats )
	Core.PrintC( "[Startup] Extension 'stats' activated" )
end
Core.PostInitFunc = Stats.Init

--[[
	Description: Cleans up remaining and out-of-range jumps
--]]
function Stats.Cleanup( t )
	Prepare(
		"SELECT * FROM game_ljstats WHERE nType = {0} ORDER BY nValue DESC LIMIT {1}",
		{ t, MAX_SELECT }
	)( function( data, varArg )
		if Core.Assert( data, "nValue" ) then
			local worst
			for j = 1, #data do
				worst = data[ j ]["nValue"]
			end
			
			if worst then
				Prepare(
					"DELETE FROM game_ljstats WHERE nType = {0} AND nValue < {1}",
					{ t, worst }
				)( SQLVoid )
			end
		end
	end )
end

--[[
	Description: Deletes items from the stats top table
--]]
function Stats.RemoveItems( ply, nType, tab )
	if #tab == 0 then return end
	
	local strs = {}
	for i = 1, #tab do
		strs[ #strs + 1 ] = "szUID = '" .. tab[ i ] .. "'"
	end
	
	Prepare(
		"DELETE FROM game_ljstats WHERE nType = {0} AND (" .. string.Implode( " OR ", strs ) .. ")",
		{ nType }
	)( SQLVoid )
	
	Cache[ nType ] = {}
	Stats.Init( true )
	
	Core.Print( ply, "Admin", Core.Text( "AdminTimeRemoval", #tab ) )
	Core.AddAdminLog( "Removed " .. #tab .. " " .. jumptypes[ nType ] .. " entries on " .. game.GetMap(), ply.UID, ply:Name() )
end

--[[
	Description: Adds the jump to the local table and changes the database table accordingly
--]]
function Stats.Add( ply, nType, data )
	if not Cache[ nType ] then return end
	if nType == JUMP_WJ and data.Prestrafe > 340 then return end
	
	local own
	for at,item in pairs( Cache[ nType ] ) do
		if item.szUID == ply.UID then
			own = at
			
			if item.nValue > data.Distance then
				return
			end
		end
	end
	
	local add = #Cache[ nType ] + 1
	for i = #Cache[ nType ], 1, -1 do
		if data.Distance > Cache[ nType ][ i ].nValue then
			add = i
		end
	end
	
	if add > MAX_SELECT then return end
	if own then table.remove( Cache[ nType ], own ) end
	
	local new = { nType = nType, nValue = data.Distance, szUID = ply.UID, nDate = os.time(), vData = string.Implode( " ", { data.Prestrafe, data.Sync, #data.SpeedValues, ply.Style, tonumber( data.Edge ) } ) }
	table.insert( Cache[ nType ], add, new )
	
	table.SortByMember( Cache[ nType ], "nValue" )
	
	Prepare(
		"SELECT nValue FROM game_ljstats WHERE nType = {0} AND szUID = {1}",
		{ nType, new.szUID }
	)( function( data, varArg )
		if Core.Assert( data, "nValue" ) then
			Prepare(
				"UPDATE game_ljstats SET nValue = {1}, nDate = {3}, vData = {4} WHERE nType = {0} AND szUID = {2}",
				{ nType, new.nValue, new.szUID, new.nDate, new.vData }
			)( SQLVoid )
		else
			Prepare(
				"INSERT INTO game_ljstats (nType, nValue, szUID, nDate, vData) VALUES ({0}, {1}, {2}, {3}, {4})",
				{ nType, new.nValue, new.szUID, new.nDate, new.vData }
			)( SQLVoid )
		end
	end )
	
	return add
end

--[[
	Description: Gets the top list for the given type
--]]
function Stats.GetTopList( nType )
	return Cache[ nType ] or {}
end

--[[
	Description: Gets the different jump types by name and ID
--]]
function Stats.GetJumpTypes()
	local tab = {}
	
	for k,_ in pairs( Cache ) do
		tab[ k ] = jumptypes[ k ]
	end
	
	return tab
end

--[[
	Description: Allows resetting of stored player data
--]]
function Stats.ResetPlayer( ply )
	if not islj[ ply ] then return end
	
	strafe[ ply ] = {}
	strafenum[ ply ] = 0
	jumptype[ ply ] = JUMP_LJ
	
	ResetFields( ply, inbhop, jumppos, strafingleft, strafingright, speed, lastspeed, jumpproblem, ducking, oldp, newp, tproblem, didjump )
end

--[[
	Description: Gets the direction vector from the difference vector
--]]
function Stats.GetDirectionFromMinimum( vec )
	local vx, vy = math.abs( vec.x ), math.abs( vec.y )
	local vd = math.abs( vx - vy )
	
	if vd < 80 then
		return Vector( 0, 0, 0 )
	elseif vx > vy then
		return Vector( vec.x >= 0 and 1 or -1, 0, 0 )
	elseif vy > vx then
		return Vector( 0, vec.y >= 0 and 1 or -1, 0 )
	else
		return Vector( 0, 0, 0 )
	end
end

--[[
	Description: Returns which vector is furthest from the given origin
--]]
function Stats.GetFurthestVector( pos, vec1, vec2 )
	if (pos - vec1):Length2D() > (pos - vec2):Length2D() then
		return vec1
	else
		return vec2
	end
end

--[[
	Description: Sees which direction the edge is pointed to and returns it
--]]
function Stats.GetLogicalEdgePlacement( edge, start, dir )
	local dup = Vector( edge.x, edge.y, edge.z )
	
	if dir.x != 0 then
		dup.y = start.y
	elseif dir.y != 0 then
		dup.x = start.x
	end
	
	return dup
end

--[[
	Description: Fully calculates the edge using the functions above and traces
--]]
function Stats.CalculateEdgeFromDirection( ply, start, stop )
	local bmin, bmax = ply:GetModelBounds()
	bmin.z, bmax.z = 0, 0
	
	local dir = Stats.GetDirectionFromMinimum( stop - start )
	if dir == Vector( 0, 0, 0 ) then return end
	
	local vmax = Stats.GetFurthestVector( stop, start + bmin, start + bmax )
	vmax = vmax - dir * EDGE_DIFF
	
	local trace = {}
	trace.start = stop + Vector( 0, 0, 32 )
	trace.endpos = vmax - Vector( 0, 0, 8 )
	
	local tr = util.TraceLine( trace )
	if tr.Hit and tr.HitWorld then
		return math.Round( (vmax - tr.HitPos):Length2D(), 2 )
	else
		local vdouble = Stats.GetLogicalEdgePlacement( vmax, start, dir )
		trace.endpos = vdouble - Vector( 0, 0, 8 )
		tr = util.TraceLine( trace )
		
		if tr.Hit and tr.HitWorld then
			return math.Round( (vdouble - tr.HitPos):Length2D(), 2 )
		end
	end
end

--[[
	Description: Called when the player lands, handles all collected data
--]]
function Stats.OnPlayerLand( p, jpos )
	local good, bad, sync, i = 0, 0, 0, 0
	local totalstats = { sync = {}, speed = {}, length = {} }
	
	-- Go over the registered strafes and calculate the sync from it
	local tab = strafe[ p ] or {}
	for a,v in pairs( tab ) do
		if type( v ) == "table" then
			local sync = math.Round( (v[ 1 ] * 100) / (v[ 1 ] + v[ 2 ]) )
			if sync and sync != 0 and sync <= 100 then
				i = i + 1
				
				totalstats.sync[ i ] = sync
				totalstats.speed[ i ] = math.Round( (v[ 3 ] or Vector( 0, 0, 0 )):Length2D() )
				totalstats.length[ i ] = math.Round( (tab[ a + 1 ] and tab[ a + 1 ][ 4 ] - v[ 4 ] or SysTime() - v[ 4 ]) * 1000 )
				
				good = good + v[ 1 ]
				bad = bad + v[ 2 ]
				start = start and v[ 4 ]
			end
		end
	end
	
	-- Get data for current jump
	local straf = strafenum[ p ]
	local jt = jumptype[ p ]
	local jpp = jumppos[ p ]
	local isnoduck = not p:KeyDown( IN_DUCK )
	local validlj = false
	local dist, distu = 0
	
	-- If we've recorded a position, we'll see what type of jump it was
	if jumppos[ p ] then
		local cz = jpos.z
		if cz - jumppos[ p ].z > -1 and cz - jumppos[ p ].z < 1 then
			cz = jumppos[ p ].z
		end
		
		if jt and jt != JUMP_WJ and cz < jumppos[ p ].z then
			if jt != JUMP_LADDER then
				jt = JUMP_DROP
				validlj = true
			else
				validlj = true
				if jumppos[ p ].z - cz > 20 then
					validlj = false
				end
			end
		elseif jt and jt != JUMP_WJ and cz > jumppos[ p ].z then
			if jt != JUMP_LADDER then
				jt = JUMP_UP
				distu = math.Round( cz - jumppos[ p ].z, 1 )
				validlj = true
			else
				validlj = true
				if jumppos[ p ].z - cz < -20 then
					validlj = false
				end
			end
		elseif jt then
			if jt == JUMP_WJ and cz == jumppos[ p ].z then
				validlj = true
			elseif jt != JUMP_WJ then
				validlj = true
			end
		end
		
		-- Calculate the distance between the two locations
		dist = (jpos - jumppos[ p ]):Length2D()
		
		-- Non ladder jumps are off by 30 by default
		if jt != JUMP_LADDER then
			dist = dist + 30
		end
	end
	
	local dj = didjump[ p ]
	if jumpproblem[ p ] or tproblem[ p ] then
		validlj = false
	end
	
	timer.Simple( 0.3, function()
		if IsValid( p ) and p:IsOnGround() and inbhop and jt then
			inbhop[ p ] = false
			
			if (jt == JUMP_WJ or dj) and straf and straf != 0 and dist and jt and dist > jumpdist[ jt ] and dist <= jumpdistm[ jt ] and validlj and good and bad and totalstats then
				sync = good / (good + bad)
				
				if not islj[ p ] or enum_ignores[ p.Style ] or p:GetGravity() != 0 then return end
				if jt == JUMP_LADDER then jumpvel[ p ] = 0 end
				if #totalstats.sync == 0 then return end
				if jt == JUMP_LJ and jumpvel[ p ] > Core.Config.Player.StartSpeed then return end
				
				local edge = (jt == JUMP_LJ and jpp and jpos) and Stats.CalculateEdgeFromDirection( p, jpp, jpos )
				local viewers = p:Spectator( "Get", { true } )
				viewers[ #viewers + 1 ] = p
				
				local send, outpos = {
					Title = jumptypes[ jt ],
					Distance = math.Round( dist, 2 ),
					Prestrafe = math.Round( jumpvel[ p ], 1 ),
					Sync = math.Round( sync * 100 ),
					SpeedValues = totalstats.speed,
					SyncValues = totalstats.sync,
					TimeValues = totalstats.length,
					Edge = (edge and edge < EDGE_MAXIMUM) and edge,
					UpDist = jt == JUMP_UP and distu,
					Duck = isnoduck,
					TAS = not not p.TAS,
					Timescale = p:GetLaggedMovementValue() != 1
				}
				
				send.Specials = send.Duck or send.TAS or send.Timescale
				
				Core.Send( viewers, "Timer/Stats", send )
				
				local legit = not p.Practice and not p.TAS and p:GetLaggedMovementValue() == 1 and p:GetWalkSpeed() == 250
				if legit then
					outpos = Stats.Add( p, jt, send )
				end
				
				if jt == JUMP_LJ and dist >= MIN_SUBMIT and legit then
					send.Style = p.Style
					send.Player = p:Name()
					send.Count = #send.SyncValues
					send.Position = outpos
					
					Core.PlayerNotification( p, "LJ", send )
				elseif jt != JUMP_LJ and Cache[ jt ] and legit and outpos then
					local szMessage = Core.ColorText()
					
					szMessage:Add( p:Name(), Core.Config.Colors[ 1 ], true )
					szMessage:Add( " got a " )
					szMessage:Add( send.Distance .. " unit", Core.Config.Colors[ 2 ], true )
					szMessage:Add( " " .. shortnames[ jt ] )
					
					if p.Style > Core.Config.Style.Normal then
						szMessage:Add( " on " )
						szMessage:Add( Core.StyleName( p.Style ), Core.Config.Colors[ 4 ], true )
					end
					
					szMessage:Add( "!" )
					szMessage:Add( " A new personal best, bringing them to #" .. outpos .. " in the " .. shortnames[ jt ] .. " top list!" )
					
					local ar = Core.Prepare( "Global/NotifyMulti" )
					ar:String( "OJ" )
					ar:ColorText( szMessage:Get() )
					ar:Send( p )
				end
			end
		end
	end )
	
	-- Reset all the variables
	strafe[ p ] = {}
	strafenum[ p ] = 0
	jumptype[ p ] = JUMP_LJ
	inbhop[ p ] = true
	
	ResetFields( p, jumppos, strafingleft, strafingright, speed, lastspeed, jumpproblem, ducking, oldp, newp, tproblem )
	
	if not didjump[ p ] then
		wj[ p ] = true
		inbhop[ p ] = nil
		
		timer.Simple( 0.3, function() 
			if IsValid( p ) then
				wj[ p ] = nil
			end
		end )
	else
		didjump[ p ] = nil
	end
end

--[[
	Description: Shows the top list for jumps for the player
--]]
function Stats.TopListCommand( ply, args )
	local nType = enum_names[ string.sub( args.Key, 1, 2 ) ] or JUMP_LJ
	if #args > 0 then
		if not enum_names[ args[ 1 ] ] then
			return Core.Print( ply, "General", Core.Text( "LJTopNone" ) )
		end
		
		nType = enum_names[ args[ 1 ] ]
	end
	
	local data = Stats.GetTopList( nType )
	if #data == 0 then
		return Core.Print( ply, "General", Core.Text( "LJTopBlank" ) )
	else
		Core.Prepare( "GUI/Build", {
			ID = "Top",
			Title = jumptypes[ nType ] .. " Top",
			X = 400,
			Y = 370,
			Mouse = true,
			Blur = true,
			Data = { data, IsEdit = ply.RemovingTimes, Style = nType, ViewType = 8, Limit = MAX_SELECT }
		} ):Send( ply )
	end
end
Core.AddCmd( { "ljtop", "wjtop", "laddertop" }, Stats.TopListCommand )


--[[
	Description: The main LJ command
--]]
Core.AddCmd( { "lj", "ljstats", "longjump" }, function( ply )
	islj[ ply ] = not islj[ ply ]
	ply:SetCustomCollisionCheck( islj[ ply ] )
	
	Core.Print( ply, "Timer", Core.Text( "CommandLJ", islj[ ply ] and "enabled" or "disabled" ) )
end )



--[[
	Description: Constantly check and collect data if we're LJing
--]]
local function Stats_MoveCheck( p, data )
	if not islj[ p ] then return end
	
	local b = data:GetButtons()
	if not p:IsOnGround() and didjump[ p ] and not inbhop[ p ] then
		if p:Crouching() then
			ducking[ p ] = true
		end
		
		local dontrun = false
		if not strafe[ p ] then
			strafe[ p ] = {}
		end
		
		local c = 0
		if ba( b, enum_il ) > 0 then
			c = c + 1
		end
		
		if ba( b, enum_ir ) > 0 then
			c = c + 1
		end

		if c == 1 and ((strafenum[ p ] and strafenum[ p ] < MAX_STRAFES) or not strafenum[ p ]) then
			if strafenum[ p ] and ba( b, enum_il ) > 0 and (strafingright[ p ] or (not strafingright[ p ] and not strafingleft[ p ])) then
				strafingright[ p ] = nil
				strafingleft[ p ] = true
				strafenum[ p ] = strafenum[ p ] + 1
				
				strafe[ p ][ strafenum[ p ] ] = {}
				strafe[ p ][ strafenum[ p ] ][ 1 ] = 0
				strafe[ p ][ strafenum[ p ] ][ 2 ] = 0
				strafe[ p ][ strafenum[ p ] ][ 4 ] = SysTime()
			elseif strafenum[ p ] and ba( b, enum_ir ) > 0 and (strafingleft[ p ] or (not strafingright[ p ] and not strafingleft[ p ])) then
				strafingright[ p ] = true
				strafingleft[ p ] = nil
				strafenum[ p ] = strafenum[ p ] + 1
				
				strafe[ p ][ strafenum[ p ] ] = {}
				strafe[ p ][ strafenum[ p ] ][ 1 ] = 0
				strafe[ p ][ strafenum[ p ] ][ 2 ] = 0
				strafe[ p ][ strafenum[ p ] ][ 4 ] = SysTime()
			end
		elseif strafenum[ p ] == 0 then
			dontrun = true
		end
		
		if not strafenum[ p ] then
			dontrun = true
		end
		
		if not dontrun then
			speed[ p ] = data:GetVelocity()
			newp[ p ] = data:GetOrigin()
			
			if lastspeed[ p ] then
				local diff = lastspeed[ p ].z - speed[ p ].z
				if diff < 7.9 or diff > 8.1 then
					jumpproblem[ p ] = true
				end
			end
			
			if lastspeed[ p ] then
				local g = (speed[ p ]:Length2D()) - (lastspeed[ p ]:Length2D())
				if g > 0 then
					strafe[ p ][ strafenum[ p ] ][ 1 ] = strafe[ p ][ strafenum[ p ] ][ 1 ] + 1
				else
					strafe[ p ][ strafenum[ p ] ][ 2 ] = strafe[ p ][ strafenum[ p ] ][ 2 ] + 1
				end
				
				strafe[ p ][ strafenum[ p ] ][ 3 ] = speed[ p ]
				
				local cp = newp[ p ]
				local op = oldp[ p ]
				
				if lastducking[ p ] and not p:Crouching() then
					op.z = op.z - 8.5
				elseif not lastducking[ p ] and p:Crouching() then
					cp.z = cp.z - 8.5
				end
				
				if p:Crouching() then
					lastducking[ p ] = true
				else
					lastducking[ p ] = nil
				end
				
				if (cp - op):Length2D() > (lastspeed[ p ]:Length2D() / 100 + 3) then
					tproblem[ p ] = true
				end
			end
			
			oldp[ p ] = newp[ p ]
			lastspeed[ p ] = speed[ p ]
		elseif strafenum[ p ] and strafenum[ p ] != 0 then
			strafe[ p ][ strafenum[ p ] ][ 2 ] = strafe[ p ][ strafenum[ p ] ][ 2 ] + 1
		end
	end
	
	if p:GetMoveType() == enum_la then
		jumptype[ p ] = JUMP_LADDER
		ladder[ p ] = true
	elseif ladder[ p ] then
		didjump[ p ] = true
		ladder[ p ] = nil
		inbhop[ p ] = nil
		jumppos[ p ] = data:GetOrigin()
		
		timer.Simple( 0.2, function()
			jumpproblem[ p ] = nil
			lastent[ p ] = nil
		end )
	end
	
	if p:IsOnGround() and not lastonground[ p ] then
		Stats.OnPlayerLand( p, data:GetOrigin() )
	end
	
	if p:IsOnGround() then
		lastonground[ p ] = true
	else
		lastonground[ p ] = nil
	end
	
	if ba( b, enum_ij ) > 0 and p:IsOnGround() then
		if wj[ p ] then
			jumptype[ p ] = JUMP_WJ
			inbhop[ p ] = nil
		end

		timer.Simple( 0.2, function()
			if not IsValid( p ) or not didjump or not lastent then return end
			
			didjump[ p ] = true
			lastent[ p ] = nil
		end )
		
		jumppos[ p ] = data:GetOrigin()
		jumpvel[ p ] = data:GetVelocity():Length2D()
	end
end
hook.Add( "SetupMove", "LJStats", Stats_MoveCheck )

--[[
	Description: Handles and registers collision
	Notes: This will only work on players with the custom collision check enabled
--]]
local function Stats_CollideCheck( ent1, ent2 )
	if ent1:IsPlayer() and ent2:IsPlayer() then return end
	
	local o, p
	if ent1:IsPlayer() then
		p = ent1
		o = ent2
	else
		p = ent2
		o = ent1
	end
	
	if not islj[ p ] then return end
	
	if didjump[ p ] and o != lastent[ p ] then
		timer.Simple( 1, function()
			if not IsValid( p ) or not inbhop or not didjump or not jumpproblem or not p.GetPos or not uq then return end
			
			if not p:IsOnGround() and not inbhop[ p ] and didjump[ p ] then
				local t = uq( p:GetPos() + Vector( 0, 0, 2 ), Vector( 0, 0, -34 ), { p } )
				if not t.Hit then
					jumpproblem[ p ] = true
				elseif t.HitPos then
					if p:GetPos().z - t.HitPos.z <= 0.2 then
						jumpproblem[ p ] = true
					end
				end
			end
		end )
	end
	
	lastent[ p ] = o
end
hook.Add( "ShouldCollide", "LJWorldCollide", Stats_CollideCheck )


-- Language
Core.AddText( "CommandLJ", "LJ Stats are now 1;" )
Core.AddText( "LJTopNone", "Statistics for this type of jump aren't tracked.\nValid types are: LJ (Long), WJ (Weird), LA (Ladder)" )
Core.AddText( "LJTopBlank", "The leaderboards are currently empty for this type of jump" )

-- Help commands
local cmd = Core.ContentText( nil, true ).Commands
cmd["lj"] = "Toggles status of LJ Statistics"
cmd["ljtop"] = "Shows LJ leaderboards"