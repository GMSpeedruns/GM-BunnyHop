-- Define config variables
Core.Config.Var.Add( "StageSaveLimit", "stage_saveloc_limit", 250, "The amount of saved locations that can exist on the server in total" )
Core.Config.Var.Add( "StageItemsPerPage", "stage_page_items", 50, "The amount of items to display per page of records" )

-- The base table
local Stages = {}
Stages.Cache = {}
Stages.Counter = {}
Stages.Loc = {}
Stages.MaxLoc = Core.Config.Var.GetInt( "StageSaveLimit" )
Stages.SelectLimit = Core.Config.Var.GetInt( "StageItemsPerPage" )
Stages.Telehop = Core.GetMapVariable( "OptionList" ).TelehopMap
Stages.Checkpoints = Core.GetMapVariable( "OptionList" ).Checkpoints

local Prepare = SQLPrepare
local Styles = Core.Config.Style


--[[
	Description: Initializes the stage system
--]]
function Stages.Init( reload )
	if reload then
		Stages.Cache = {}
		Stages.Counter = {}
	end
	
	Prepare(
		"SELECT szUID, nID, nStyle, nTime FROM game_stagetimes WHERE szMap = {0} ORDER BY nTime ASC",
		{ game.GetMap() },
		{ UseOptions = true, RawFormat = true }
	)( function( data, varArg )
		if Core.Assert( data, "szUID" ) then
			local makeNum, makeNull, styleId, stageId = tonumber, Core.Null
			for j = 1, #data do
				styleId = makeNum( data[ j ]["nStyle"] )
				stageId = makeNum( data[ j ]["nID"] )
				
				data[ j ]["nStyle"] = nil
				data[ j ]["nID"] = nil
				
				if not Stages.Cache[ styleId ] then
					Stages.Cache[ styleId ] = {}
					Stages.Counter[ styleId ] = {}
				end
				
				Stages.Counter[ styleId ][ stageId ] = (Stages.Counter[ styleId ][ stageId ] or 0) + 1
				
				if not Stages.Cache[ styleId ][ stageId ] then
					Stages.Cache[ styleId ][ stageId ] = {}
				end
				
				Stages.Cache[ styleId ][ stageId ][ Stages.Counter[ styleId ][ stageId ] ] = { makeNum( data[ j ]["nTime"] ), data[ j ]["szUID"] }
				
				data[ j ]["nTime"] = nil
				data[ j ]["szUID"] = nil
			end
		end
	end )
	
	-- Set styles
	for i = 1, 100 do
		Core.SetStyle( 100 + i, (Core.IsMapOption( Stages.Checkpoints ) and "Checkpoint " or "Stage ") .. i )
	end
	
	-- Add handlers
	AddTimerHandler( 8, Stages.OnStageEnter, Stages.OnStageStart )
	AddTimerHandler( 9, Stages.OnStageComplete, Stages.OnStageReset )
	
	-- And activate it
	Core.Config.Var.Activate( "Stages", Stages )
	Core.PrintC( "[Startup] Extension 'stages' activated" )
end
Core.PostInitFunc = Stages.Init


--[[
	Description: Adds a time to the database and local table
--]]
function Stages.AddTime( uid, nStyle, nID, nTime, nPrev )
	if not Stages.Cache[ nStyle ] then
		Stages.Cache[ nStyle ] = {}
	end
	
	if not Stages.Cache[ nStyle ][ nID ] then
		Stages.Cache[ nStyle ][ nID ] = {}
	end
	
	Prepare(
		nPrev and "UPDATE game_stagetimes SET nTime = {4} WHERE szUID = {0} AND szMap = {1} AND nID = {2} AND nStyle = {3}" or "INSERT INTO game_stagetimes (szUID, szMap, nID, nStyle, nTime) VALUES ({0}, {1}, {2}, {3}, {4})",
		{ uid, game.GetMap(), nID, nStyle, nTime }
	)( SQLVoid )

	local from
	if nPrev then
		for i = 1, #Stages.Cache[ nStyle ][ nID ] do
			if Stages.Cache[ nStyle ][ nID ][ i ][ 2 ] == uid then
				from = i
				break
			end
		end
	end

	local to = #Stages.Cache[ nStyle ][ nID ] + 1
	for i = 1, #Stages.Cache[ nStyle ][ nID ] do
		if Stages.Cache[ nStyle ][ nID ][ i ][ 1 ] > nTime then
			to = i
			break
		end
	end
	
	if nPrev and not from then
		return Core.PrintC( "[Error] Stages", "Something went wrong while finding previous entry!" )
	end
	
	if from then
		table.remove( Stages.Cache[ nStyle ][ nID ], from )
	end
	
	table.insert( Stages.Cache[ nStyle ][ nID ], to, { nTime, uid } )
	
	return to
end



--[[
	Description: Checks if a player is able to get a stage time
--]]
function Stages.IsValidTime( ply )
	-- If the player as a whole is invalid, it's a no-no
	if not IsValid( ply ) then return false end
	
	-- Practice mode, hell naw
	if ply.Practice or ply.TAS then return false end
	
	-- Bonus won't do as a normal style
	if ply.Bonus then return false end
	
	-- Without a timer we're not doing it either
	if not ply.TimerNormal then return false end
	
	-- Finaly give the OK word
	return true
end

--[[
	Description: Gets the stage time of a player
--]]
function Stages.GetStageTime( uid, nStyle, id )
	if not Stages.Cache[ nStyle ] then return end
	if Stages.Cache[ nStyle ][ id ] then
		for i = 1, #Stages.Cache[ nStyle ][ id ] do
			if Stages.Cache[ nStyle ][ id ][ i ][ 2 ] == uid then
				return Stages.Cache[ nStyle ][ id ][ i ][ 1 ]
			end
		end
	end
end

--[[
	Description: Gets the top stage time
--]]
function Stages.GetTopTime( nStyle, id )
	if Stages.Cache[ nStyle ] and Stages.Cache[ nStyle ][ id ] and Stages.Cache[ nStyle ][ id ][ 1 ] then
		return Stages.Cache[ nStyle ][ id ][ 1 ][ 1 ]
	end
end

--[[
	Description: Gets the start point of a specific stage
--]]
function Stages.GetStartPoint( id, bData, bEnd )
	local ZoneEnts = Core.GetZoneEntities()
	for i = 1, #ZoneEnts do
		local zone = ZoneEnts[ i ]
		if IsValid( zone ) then
			if zone.zonetype == Core.GetZoneID( bEnd and "Stage End" or "Stage Start" ) and zone.embedded and zone.embedded == id then
				local pos = zone:GetPos()
				
				if bData then
					return { zone.min, zone.max, pos }
				else
					pos.z = zone.min.z
					
					return pos
				end
			end
		end
	end
end

--[[
	Description: Checks if a zone with a specific data type exists
--]]
function Stages.HasZone( name, id )
	local ZoneEnts = Core.GetZoneEntities()
	for i = 1, #ZoneEnts do
		local zone = ZoneEnts[ i ]
		if IsValid( zone ) then
			if zone.zonetype == Core.GetZoneID( name ) and zone.embedded == id then
				return true
			end
		end
	end
end

--[[
	Description: Returns the amount of stages
--]]
function Stages.GetStageCount()
	local stage = {}
	
	local ZoneEnts = Core.GetZoneEntities()
	for i = 1, #ZoneEnts do
		local zone = ZoneEnts[ i ]
		if IsValid( zone ) then
			if zone.zonetype == Core.GetZoneID( "Stage Start" ) and zone.embedded and not table.HasValue( stage, zone.embedded ) then
				stage[ #stage + 1 ] = zone.embedded
			end
		end
	end
	
	return #stage + (Core.IsMapOption( Stages.Checkpoints ) and 0 or 1)
end

--[[
	Description: Processes a stage time
--]]
function Stages.ProcessEnd( ply, nID, nTime, bLinear )
	-- Base variables
	local nStyle = ply.Style
	local nOld = Stages.GetStageTime( ply.UID, nStyle, nID )
	local nPreviousWR = Stages.GetTopTime( nStyle, nID )
	
	-- Notification strings
	local DifferencePB = nOld and nTime - nOld
	local DifferenceWR = nPreviousWR and nTime - nPreviousWR
	local MsgPB = DifferencePB and ((DifferencePB > 0 and "PB +" or "Improved by ") .. Core.ConvertTime( math.abs( DifferencePB ) )) or ""
	local MsgWR = DifferenceWR and "WR " .. (DifferenceWR < 0 and "-" or "+") .. Core.ConvertTime( math.abs( DifferenceWR ) ) or ""
	
	-- Send a message when they're slower
	if nOld and nTime >= nOld then
		return Core.PlayerNotification( ply, "StageSlow", { ID = nID, Time = nTime, Style = nStyle, DifferencePB = MsgPB, DifferenceWR = MsgWR, Linear = bLinear } )
	end
	
	-- Get new data
	local id = Stages.AddTime( ply.UID, nStyle, nID, nTime, nOld )
	local nRec, bBot = Stages.Cache[ nStyle ] and Stages.Cache[ nStyle ][ nID ] and #Stages.Cache[ nStyle ][ nID ] or 0
	
	-- Handle the bot data
	if id == 1 and nStyle == 1 and ply.StageStartFrame then
		local range = { ply.StageStartFrame, Core.Ext( "Bot", "GetPlayerFrame" )( ply ), nID }
		if range[ 1 ] > 0 and range[ 2 ] > 0 then
			bBot = Core.Ext( "Bot", "HandleSpecial" )( ply, "Stage", nTime, range )
		end
	end
	
	-- Send the message out
	Core.PlayerNotification( ply, "StageFast", { ID = nID, Time = nTime, Style = nStyle, DifferencePB = MsgPB, DifferenceWR = MsgWR, Rank = id .. " / " .. nRec, Pos = id, Bot = bBot, Linear = bLinear } )
end


--[[
	Description: Triggers when a player starts the normal map
--]]
function Stages.HitStartZone( ply )
	-- Check what kind of zones we have
	if Core.IsMapOption( Stages.Checkpoints ) then
		-- See if there's a stage 1 start
		if Stages.HasZone( "Stage Start", 1 ) then
			ply.StageStarted = 1
			ply.StageStartFrame = Core.Ext( "Bot", "GetPlayerFrame" )( ply )
			
			local ar = Core.Prepare( "Timer/Stage" )
			ar:UInt( 3, 3 )
			ar:UInt( ply.StageStarted, 8 )
			ar:Send( ply )
		end
	else
		-- See if there's a stage 1 end
		if Stages.HasZone( "Stage End", 1 ) then
			ply.StageID = 1
			ply.StageStarted = ply.StageID
			ply.StageStartFrame = Core.Ext( "Bot", "GetPlayerFrame" )( ply )
			ply.TimerStage = ply.TimerNormal
			
			local ar = Core.Prepare( "Timer/Stage" )
			ar:UInt( 1, 3 )
			ar:UInt( ply.StageStarted, 8 )
			ar:Send( ply )
		end
	end
end

--[[
	Description: Triggers when a player finishes the normal map
--]]
function Stages.HitEndZone( ply )
	if not Stages.IsValidTime( ply ) then return end
	if not Core.IsMapOption( Stages.Checkpoints ) and ply.TimerNormal then
		-- Get amount of stages
		local stages = Stages.GetStageCount()
		
		-- See if the last stage doesn't have an ending
		if Stages.HasZone( "Stage Start", stages ) and not Stages.HasZone( "Stage End", stages ) then
			Stages.OnStageComplete( ply, { embedded = stages } )
		end
	end
end

--[[
	Description: Called when a player enters a stage
--]]
function Stages.OnStageEnter( ply, ent )
	if not Stages.IsValidTime( ply ) or not ent.embedded then return end
	
	-- Check if it's checkpoints or stages
	if Core.IsMapOption( Stages.Checkpoints ) then
		if ply.TimerNormal and not ply.TimerNormalFinish then
			Stages.ProcessEnd( ply, ent.embedded, SysTime() - ply.TimerNormal, true )
			
			if Stages.HasZone( "Stage Start", ent.embedded + 1 ) then
				ply.StageStarted = ent.embedded + 1
				
				local ar = Core.Prepare( "Timer/Stage" )
				ar:UInt( 4, 3 )
				ar:UInt( ply.StageStarted, 8 )
				ar:Send( ply )
			else
				ply.StageStarted = nil
				
				local ar = Core.Prepare( "Timer/Stage" )
				ar:UInt( 0, 3 )
				ar:Send( ply )
			end
		end
	else
		ply.StageID = ent.embedded
		ply.StageStartFrame = nil
		ply.TimerStage = nil
		
		if Stages.IsValidTime( ply ) then
			local ar = Core.Prepare( "Timer/Stage" )
			ar:UInt( 0, 3 )
			ar:Send( ply )
		end
		
		if ply.TimerNormalFinish == 1e10 then
			Core.Ext( "Bot", "CleanPlayer" )( ply )
		end
	end
end

--[[
	Description: Starts a stage timer
--]]
function Stages.OnStageStart( ply, ent )
	if Core.IsMapOption( Stages.Checkpoints ) then return end
	if not Stages.IsValidTime( ply ) or not ent.embedded then return end
	
	local vel2d = ply:GetVelocity():Length2D()
	if vel2d > Core.Config.Player.StartSpeed and not Core.IsMapOption( Stages.Telehop ) then
		ply.StageStarted = nil
		ply.StageStartFrame = nil
		ply.TimerStage = nil
		
		local ar = Core.Prepare( "Timer/Stage" )
		ar:UInt( 0, 3 )
		ar:Send( ply )
	else
		ply.StageStarted = ent.embedded
		ply.StageStartFrame = Core.Ext( "Bot", "GetPlayerFrame" )( ply )
		ply.TimerStage = SysTime()
		
		local ar = Core.Prepare( "Timer/Stage" )
		ar:UInt( 1, 3 )
		ar:UInt( ply.StageStarted, 8 )
		ar:Send( ply )
	end
end

--[[
	Description: Ends a stage timer
--]]
function Stages.OnStageComplete( ply, ent )
	if Core.IsMapOption( Stages.Checkpoints ) then return end
	if not Stages.IsValidTime( ply ) or not ent.embedded then return end
	
	if ply.StageStarted == ent.embedded and ply.TimerStage then
		local nTime = SysTime() - ply.TimerStage
		Stages.ProcessEnd( ply, ent.embedded, nTime )
		
		local ar = Core.Prepare( "Timer/Stage" )
		ar:UInt( 2, 3 )
		ar:UInt( ply.StageStarted, 8 )
		ar:Double( nTime )
		ar:Send( ply )
		
		ply.StageStarted = nil
		ply.StageFinished = ent.embedded
		ply.TimerStage = nil
	end
end

--[[
	Description: Resets a stage timer
--]]
function Stages.OnStageReset( ply, ent )
	if Core.IsMapOption( Stages.Checkpoints ) then
		if not ent then
			local ar = Core.Prepare( "Timer/Stage" )
			ar:UInt( 0, 3 )
			ar:Send( ply )
		end
		
		return
	elseif ent then
		local ar = Core.Prepare( "Timer/Stage" )
		ar:UInt( 0, 3 )
		return ar:Send( ply )
	end
	
	if ply.StageStarted and ply.TimerStage then
		ply.StageStarted = nil
		ply.TimerStage = nil
		
		local ar = Core.Prepare( "Timer/Stage" )
		ar:UInt( 0, 3 )
		ar:Send( ply )
	end
end

function Stages.ResetStageID( ply )
	if Core.IsMapOption( Stages.Checkpoints ) then
		local ar = Core.Prepare( "Timer/Stage" )
		ar:UInt( 0, 3 )
		ar:Send( ply )
	end
	
	ply.StageID = nil
end

function Stages.GetStageID( ply )
	return not ply.Practice and ply.StageID
end


--[[
	Description: Lets the player go back one stage
--]]
function Stages.GoBackCommand( ply, args )
	if #args > 0 then
		Core.Print( ply, "Timer", Core.Text( "GoBackArgument" ) )
	else
		local nID
		if ply.Practice and ply.StageID and ply.StageID - 1 >= 1 then
			nID = ply.StageID - 1
		elseif not Stages.IsValidTime( ply ) then
			return Core.Print( ply, "Timer", Core.Text( "GoBackInvalid" ) )
		end
		
		if nID or (ply.StageFinished and (ply.StageFinished + 1 == ply.StageID or ply.StageFinished == ply.StageID)) then
			local id = nID or ply.StageFinished
			ply.TimerStage = nil
			ply.StageStarted = nil
			ply.StageFinished = nil
			
			local pos = Stages.GetStartPoint( id )
			if pos then
				ply:SetPos( pos )
				ply:SetLocalVelocity( Vector( 0, 0, 0 ) )
				
				if nID then
					ply.StageID = id
				end
				
				Core.Print( ply, "Timer", Core.Text( "GoBackSend", id ) )
			else
				Core.Print( ply, "Timer", Core.Text( "GoBackInvalid" ) )
			end
		else
			Core.Print( ply, "Timer", Core.Text( "GoBackNotComplete" ) )
		end
	end
end
Core.AddCmd( { "goback", "gb" }, Stages.GoBackCommand )

--[[
	Description: Opens the stage record listing
--]]
function Stages.StageWRCommand( ply, args )
	if #args > 0 then
		local nID = tonumber( args[ 1 ] )
		if not nID then
			return Core.Print( ply, "Timer", Core.Text( "StageCmdStageID" ) )
		end
		
		local nStyle = ply.Style
		if #args > 1 then
			local lookup = Core.ContentText( "StyleLookup" )
			local found = lookup[ args[ 2 ] ]
			
			if not found then
				table.remove( args.Upper, 1 )
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
		
		if Stages.Cache[ nStyle ] and Stages.Cache[ nStyle ][ nID ] and #Stages.Cache[ nStyle ][ nID ] > 0 then
			local data, pos = {}
			for i = 1, #Stages.Cache[ nStyle ][ nID ] do
				local item = Stages.Cache[ nStyle ][ nID ][ i ]
				if item then
					if i <= Stages.SelectLimit then
						data[ i ] = { nTime = item[ 1 ], szUID = item[ 2 ] }
					end
					
					if item[ 2 ] == ply.UID then
						pos = i
					end
				end
			end
			
			Core.Prepare( "GUI/Build", {
				ID = "Top",
				Title = "Stage " .. nID .. " Records (" .. Core.StyleName( nStyle ) .. ")",
				X = 400,
				Y = 370,
				Mouse = true,
				Blur = true,
				Data = { data, Total = #Stages.Cache[ nStyle ][ nID ], Style = nStyle, ID = nID, Pos = pos, IsEdit = ply.RemovingTimes, ViewType = 2 }
			} ):Send( ply )
		else
			Core.Print( ply, "Timer", Core.Text( "StageCmdStyle", nID, Core.StyleName( nStyle ) ) )
		end
	else
		if ply.StageID then
			Stages.StageWRCommand( ply, { ply.StageID } )
		else
			Core.Print( ply, "Timer", Core.Text( "StageCmdArgument", args.Key, args.Key ) )
		end
	end
end
Core.AddCmd( { "stagewr", "stagewrs", "cpr", "cpwr", "wrcp" }, Stages.StageWRCommand )

--[[
	Description: Updates the Stage WR list
--]]
function Stages.StageWRUpdate( ply, varArgs )
	local nStyle = varArgs[ 1 ]
	local nID = varArgs[ 2 ]
	local nOffset, nLast = varArgs[ 3 ]

	local data = {}
	if Stages.Cache[ nStyle ] and Stages.Cache[ nStyle ][ nID ] and #Stages.Cache[ nStyle ][ nID ] > 0 then
		for i = nOffset + 1, nOffset + Stages.SelectLimit do
			local item = Stages.Cache[ nStyle ][ nID ][ i ]
			if item then
				data[ #data + 1 ] = { nTime = item[ 1 ], szUID = item[ 2 ] }
				nLast = i
			end
		end
	end
	
	Core.Prepare( "GUI/Update", {
		ID = "Top",
		Data = { data, #Stages.Cache[ nStyle ][ nID ], nOffset + 1, nLast }
	} ):Send( ply )
end
Core.Register( "Global/RetrieveStages", Stages.StageWRUpdate )

--[[
	Description: Deletes items from the stage WRs
--]]
function Stages.RemoveTimes( ply, nStyle, nID, tab )
	if #tab == 0 then return end
	
	local strs = {}
	for i = 1, #tab do
		strs[ #strs + 1 ] = "szUID = '" .. tab[ i ] .. "'"
	end
	
	Prepare(
		"DELETE FROM game_stagetimes WHERE szMap = {0} AND nID = {1} AND nStyle = {2} AND (" .. string.Implode( " OR ", strs ) .. ")",
		{ game.GetMap(), nID, nStyle }
	)( SQLVoid )
	
	Stages.Init( true )
	
	Core.Print( ply, "Admin", Core.Text( "AdminTimeRemoval", #tab ) )
	Core.AddAdminLog( "Removed " .. #tab .. " " .. Core.StyleName( nStyle ) .. " stage " .. nID .. " times on " .. game.GetMap(), ply.UID, ply:Name() )
end

--[[
	Description: Shows personal stage times
--]]
function Stages.StageOwnCommand( ply, args )
	local tab = {}
	local nStyle = ply.Style
	local szUID = ply.UID
	
	if Stages.Cache[ nStyle ] then
		for stage,records in pairs( Stages.Cache[ nStyle ] or {} ) do
			for i = 1, #records do
				local item = records[ i ]
				if item and item[ 2 ] == szUID then
					tab[ #tab + 1 ] = { nTime = item[ 1 ], szText = "Stage " .. stage .. " (#" .. i .. ")" .. (i > 1 and " (WR +" .. Core.ConvertTime( item[ 1 ] - records[ 1 ][ 1 ] ) .. ")" or (records[ 2 ] and " (Next -" .. Core.ConvertTime( records[ 2 ][ 1 ] - item[ 1 ] ) .. ")" or "")) }
				end
			end
		end
	end
	
	if #tab > 0 then
		Core.Prepare( "GUI/Build", {
			ID = "Top",
			Title = "Your stage records on " .. Core.StyleName( nStyle ),
			X = 400,
			Y = 370,
			Mouse = true,
			Blur = true,
			Data = { tab, ViewType = 5 }
		} ):Send( ply )
	else
		Core.Print( ply, "Timer", Core.Text( "StageOwnNone" ) )
	end
end
Core.AddCmd( { "mystages", "stagetimes", "mycpr", "mycprs" }, Stages.StageOwnCommand )

--[[
	Description: Shows top stage times
--]]
function Stages.StageTopCommand( ply, args )
	local tab = {}
	local nStyle = ply.Style
	
	if Stages.Cache[ nStyle ] then
		for stage,records in pairs( Stages.Cache[ nStyle ] or {} ) do
			if records[ 1 ] then
				tab[ #tab + 1 ] = { nTime = records[ 1 ][ 1 ], szUID = records[ 1 ][ 2 ], szAppend = records[ 2 ] and " (Next -" .. Core.ConvertTime( records[ 2 ][ 1 ] - records[ 1 ][ 1 ] ) .. ")" or "" }
			end
		end
	end
	
	if #tab > 0 then
		Core.Prepare( "GUI/Build", {
			ID = "Top",
			Title = "Top stage records on " .. Core.StyleName( nStyle ),
			X = 400,
			Y = 370,
			Mouse = true,
			Blur = true,
			Data = { tab, ViewType = 3 }
		} ):Send( ply )
	else
		Core.Print( ply, "Timer", Core.Text( "StageTopNone" ) )
	end
end
Core.AddCmd( { "cprtop", "stagetop", "stagebest", "beststages", "stagewrs", "topcpr", "cptop", "cprbest" }, Stages.StageTopCommand )

--[[
	Description: Moves the player to the start of the stage
--]]
function Stages.StageMoveCommand( ply, args )
	if #args > 0 and tonumber( args[ 1 ] ) then
		if ply.Practice then
			return Stages.StageCommand( ply, args )
		end
		
		local id = tonumber( args[ 1 ] )
		if not ply.StageID then
			return Core.Print( ply, "Timer", Core.Text( "StageMoveAt" ) )
		elseif not Stages.IsValidTime( ply ) then
			return Core.Print( ply, "Timer", Core.Text( "StageMoveValid" ) )
		elseif not Stages.GetStartPoint( id ) then
			return Core.Print( ply, "Timer", Core.Text( "StageCmdNotFound", id, Stages.GetStageCount() > 0 and Stages.GetStageCount() or "no" ) )
		end
		
		local pos = Stages.GetStartPoint( id, true )
		if pos then
			local new = Core.RandomizeSpawn( pos )
			if new.x != 0 and new.y != 0 and new.z != 0 then
				local add = ""
				if ply.TimerNormalFinish != 1e10 then
					add = " You can no longer finish the map. You can take infinite tries on any stage, though!"
					
					local ar = Core.Prepare( "Timer/Start" )
					ar:UInt( 0, 2 )
					ar:Send( ply )
				end
				
				ply.TimerNormalFinish = 1e10
				ply.TimerBonusFinish = 1e10
				
				ply:SetPos( new )
				ply:SetLocalVelocity( Vector( 0, 0, 0 ) )
				
				if not Core.Ext( "Bot", "IsPlayerActive" )( ply ) then
					Core.Ext( "Bot", "CleanPlayer" )( ply )
					Core.Ext( "Bot", "SetPlayerActive" )( ply, true )
				end
				
				Core.Print( ply, "Timer", Core.Text( "StageMoveGo", id, add ) )
			end
		end
	else
		Core.Print( ply, "Timer", Core.Text( "StageMoveNum", args.Key ) )
	end
end
Core.AddCmd( { "gostage", "gotostage", "gotos", "gs" }, Stages.StageMoveCommand )

--[[
	Description: Resets the player to the start of the stage
--]]
function Stages.StageResetCommand( ply )
	if ply.StageID then
		if ply.Practice then
			Stages.StageCommand( ply, { ply.StageID } )
		elseif not ply.IsStageResettable or ply:IsStageResettable( ply.StageID ) then
			local pos = Stages.GetStartPoint( ply.StageID, true )
			if pos then
				local new = Core.RandomizeSpawn( pos )
				if new.x != 0 and new.y != 0 and new.z != 0 then
					ply:SetPos( new )
					ply:SetLocalVelocity( Vector( 0, 0, 0 ) )
					
					Core.Print( ply, "Timer", Core.Text( "StageResetGo" ) )
				end
			end
		end
	else
		Core.Print( ply, "Timer", Core.Text( "StageResetNoEnter" ) )
	end
end
Core.AddCmd( { "restartstage", "resetstage", "stagereset", "sr", "rs", "stagestart" }, Stages.StageResetCommand )

--[[
	Description: Saves a location
--]]
function Stages.StageLocationSaveBind( ply, _, varArgs )
	if ply.TAS then return Core.Print( ply, "General", Core.Text( "SaveLocTAS" ) ) end
	if not Core.CanExecuteCommand( ply ) then return end
	
	if varArgs and #varArgs > 0 and string.sub( varArgs[ 1 ], 1, 1 ) == "@" then
		local ID = tonumber( string.sub( varArgs[ 1 ], 2 ) ) or 0
		if ID < 1 or ID > 9 then
			return Core.Print( ply, "Timer", Core.Text( "SaveLocInvalidID" ) )
		end
		
		Core.Trigger( "Global/Checkpoints", { ID, nil, nil, nil, true }, ply )
	else
		Stages.Pointer = ((not Stages.Pointer or Stages.Pointer + 1 > Stages.MaxLoc) and 0 or Stages.Pointer) + 1
		Stages.Loc[ Stages.Pointer ] = { Pos = ply:GetPos(), Ang = ply:EyeAngles(), Vel = ply:GetVelocity(), Own = ply:Name() }
		
		ply.LastSaveLoc = Stages.Pointer
		
		Core.Print( ply, "Timer", Core.Text( "SaveLocSet", Stages.Pointer ) )
	end
end
concommand.Add( "sm_saveloc", Stages.StageLocationSaveBind )

--[[
	Description: Teleports to a given location
--]]
function Stages.StageResetBind( ply, _, varArgs )
	if ply.TAS then return Core.Print( ply, "General", Core.Text( "SaveLocTAS" ) ) end
	
	local id
	if varArgs and #varArgs > 0 and string.sub( varArgs[ 1 ], 1, 1 ) == "@" then
		local ID = tonumber( string.sub( varArgs[ 1 ], 2 ) ) or 0
		if ID < 1 or ID > 9 then
			return Core.Print( ply, "Timer", Core.Text( "SaveLocInvalidID" ) )
		end
		
		return Core.Trigger( "Global/Checkpoints", { ID }, ply )
	elseif varArgs and #varArgs > 0 and string.sub( varArgs[ 1 ], 1, 1 ) == "#" then
		id = tonumber( string.sub( varArgs[ 1 ], 2 ) )
	elseif varArgs and #varArgs > 0 and tonumber( varArgs[ 1 ] ) then
		id = tonumber( varArgs[ 1 ] )
	end
	
	if ply.Practice then
		if #Stages.Loc > 0 then
			local to = id or ply.LastSaveLoc
			if not to then
				for i = 1, Stages.Pointer or 0 do
					if Stages.Loc[ i ].Own == ply:Name() then
						to = i
					end
				end
			end
			
			local target = Stages.Loc[ to ]
			if target and target.Pos then
				ply:SetPos( target.Pos )
				ply:SetEyeAngles( target.Ang )
				ply:SetLocalVelocity( target.Vel )
				ply.LastSaveLoc = to
				
				if target.Own != ply:Name() then
					Core.Print( ply, "Timer", Core.Text( "SaveLocTele", to, target.Own ) )
				end
			else
				Core.Print( ply, "Timer", Core.Text( "SaveLocUnset", to ) )
			end
		else
			Core.Print( ply, "Timer", Core.Text( "SaveLocBlank" ) )
		end
	else
		if ply.StageID then
			if not Core.CanExecuteCommand( ply ) then return end
			Stages.StageResetCommand( ply )
		else
			Core.Print( ply, "Timer", Core.Text( "SaveLocNone" ) )
		end
	end
end
concommand.Add( "sm_tele", Stages.StageResetBind )

--[[
	Description: Teleports the player to a stage
--]]
function Stages.StageCommand( ply, args )
	if #args > 0 and tonumber( args[ 1 ] ) then
		if not ply.Practice then
			return Core.Print( ply, "General", Core.Text( "CommandPractice" ) )
		end
		
		local nID = tonumber( args[ 1 ] )
		local pos = Stages.GetStartPoint( nID )
		if pos then
			ply:SetPos( pos )
			ply:SetLocalVelocity( Vector( 0, 0, 0 ) )
			
			Core.Print( ply, "Timer", Core.Text( "StageCmdSend", nID ) )
		else
			Core.Print( ply, "Timer", Core.Text( "StageCmdNotFound", nID, Stages.GetStageCount() > 0 and Stages.GetStageCount() or "no" ) )
		end
	else
		local count = Stages.GetStageCount()
		Core.Print( ply, "Timer", Core.Text( "StageCmdBase", ply.StageID and "on stage " .. ply.StageID or "not on any stage", count > 0 and count .. " stages in total" or "no stages on this map" ) )
	end
end
Core.AddCmd( { "stage", "tpstage", "tps", "gotostage" }, Stages.StageCommand )

--[[
	Description: Teleports the player to the end of a stage
--]]
function Stages.StageEndCommand( ply, args )
	if #args > 0 and tonumber( args[ 1 ] ) then
		if not ply.Practice then
			return Core.Print( ply, "General", Core.Text( "CommandPractice" ) )
		end
		
		local nID = tonumber( args[ 1 ] )
		local pos = Stages.GetStartPoint( nID, nil, true )
		if pos then
			ply:SetPos( pos )
			ply:SetLocalVelocity( Vector( 0, 0, 0 ) )
			
			Core.Print( ply, "Timer", Core.Text( "StageEndCmdSend", nID ) )
		else
			Core.Print( ply, "Timer", Core.Text( "StageCmdNotFound", nID, Stages.GetStageCount() > 0 and Stages.GetStageCount() or "no" ) )
		end
	else
		Core.Print( ply, "Timer", Core.Text( "StageEndCmdBase", args.Key ) )
	end
end
Core.AddCmd( { "stageend", "send", "gosend", "ends", "endstage" }, Stages.StageEndCommand )

--[[
	Description: Shows the amount of stages
--]]
function Stages.CountCommand( ply )
	local count = Stages.GetStageCount()
	if count > 0 then
		Core.Print( ply, "Timer", Core.Text( "StagesCmdFound", game.GetMap(), count, Core.IsMapOption( Stages.Checkpoints ) and "checkpoints" or "stages" ) )
	else
		Core.Print( ply, "Timer", Core.Text( "StagesCmdNone" ) )
	end
end
Core.AddCmd( { "stages", "stagecount" }, Stages.CountCommand )


-- Language
Core.AddText( "GoBackArgument", "You can't go back multiple stages at once." )
Core.AddText( "GoBackInvalid", "You are not eligible to go back a stage at this moment." )
Core.AddText( "GoBackNotComplete", "You can only go back to a previously completed stage." )
Core.AddText( "GoBackSend", "You have been moved one stage back! (To stage 1;)" )
Core.AddText( "SaveLocNone", "You need to have entered a stage in order to use this command. Or be in practice mode to use sm_saveloc'd locations." )
Core.AddText( "SaveLocBlank", "No positions set with sm_saveloc. Please do so before trying to use sm_tele" )
Core.AddText( "SaveLocUnset", "There are no saved locations on ID #1;" )
Core.AddText( "SaveLocSet", "Saved position to ID #1;" )
Core.AddText( "SaveLocTele", "You have been teleported to saved location #1;, set by 2;" )
Core.AddText( "SaveLocInvalidID", "When using an identifier you must use a valid ID as listed on the !cp window." )
Core.AddText( "SaveLocTAS", "You can't use sm_saveloc or sm_tele while in TAS mode." )
Core.AddText( "StageCmdArgument", "Please use the command like so: /1; [ID] (Style, Optional) -> Example: /2; 1 Sideways" )
Core.AddText( "StageCmdStageID", "The stage ID has to be a valid number" )
Core.AddText( "StageCmdStyle", "There are no Stage 1; WRs for this style (2;)." )
Core.AddText( "StageResetNoEnter", "You are currently not on any stage." )
Core.AddText( "StageResetGo", "You have been reset to the start of the stage." )
Core.AddText( "StageMoveNum", "Please enter the stage number you want to be moved to: /1; [ID]" )
Core.AddText( "StageMoveAt", "You have to be at a stage in order to use this command." )
Core.AddText( "StageMoveValid", "You are not eligible to use this command at this moment (You need to have a running timer)." )
Core.AddText( "StageMoveGo", "You have been moved to stage 1;!2;" )
Core.AddText( "StageOwnNone", "You haven't beaten any stages on this style." )
Core.AddText( "StageTopNone", "There are no beaten stages on this style." )
Core.AddText( "StagesCmdFound", "The map '1;' has 2; 3;." )
Core.AddText( "StagesCmdNone", "This map doesn't have any stages set." )
Core.AddText( "StageCmdNotFound", "There is no stage 1;. This map has 2; stages." )
Core.AddText( "StageCmdSend", "You have been teleported to stage 1;" )
Core.AddText( "StageCmdBase", "You are currently 1;. There are 2;. To teleport to a stage, go into !practice mode and type !s [ID]. To view stage WRs, type !cpr [ID]" )
Core.AddText( "StageEndCmdSend", "You have been teleported to the end of stage 1;" )
Core.AddText( "StageEndCmdBase", "To go to the end of a stage, please use this command in combination with the stage ID. Example /1; [ID]" )

-- Help commands
local cmd = Core.ContentText( nil, true ).Commands
cmd["goback"] = "Moves you one stage back"
cmd["stagewr"] = "Shows the WRs for a stage"
cmd["mystages"] = "Shows all your stage times"
cmd["cprtop"] = "Shows all the #1 stage records on the map"
cmd["gostage"] = "Moves you to any stage"
cmd["restartstage"] = "Resets to the start of a stage"
cmd["stage"] = "Teleports you to a given stage"
cmd["stageend"] = "Teleports you to the end of a given stage"
cmd["stages"] = "Shows the amount of stages on a map"