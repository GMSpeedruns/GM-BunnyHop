-- Define config variables
Core.Config.Var.Add( "BotCount", "bot_count", 2, "The amount of replay bots in the game\n - Limits: [0, 2]" )
Core.Config.Var.Add( "BotBusyLimit", "bot_busylimit", 24, "The limit of in-game players after which the bot will stop automatically recording newly joined players" )
Core.Config.Var.Add( "BotRecordingLimit", "bot_reclimit", 150, "The percentage of time the player can go over the current bot time before recording stops\n - Set this to 0 in order to not stop people from being recorded, be warned however, this will eat server memory\n - Limits: [0, Inf]" )

-- Make the base table
local Bot = {}
Bot.Count = Core.Config.Var.GetInt( "BotCount" )
Bot.BusyLimit = Core.Config.Var.GetInt( "BotBusyLimit" )
Bot.RecordingMultiplier = math.Clamp( Core.Config.Var.GetInt( "BotRecordingLimit" ), 0, 1e10 )
Bot.RecordingMultiplier = Bot.RecordingMultiplier == 0 and 1e10 or Bot.RecordingMultiplier / 100.0
Bot.AverageStart = 150
Bot.StartFrames = 200
Bot.HistoryID = 1000
Bot.BaseID = { TAS = 50, Stage = 100 }
Bot.PerStyle = {}

-- Bot playback helpers
local BotPlayer = {}
local BotFrame = {}
local BotFrames = {}
local BotInfo = {}
local BotForceRuns = {}

-- Bot playback content tables
local BotOriginX, BotOriginY, BotOriginZ = {}, {}, {}
local BotAngleP, BotAngleY = {}, {}
local BotButtons = {}

-- Player recording helpers
local Frame = {}
local Active = {}

-- Player recording tables
local OriginX, OriginY, OriginZ = {}, {}, {}
local AngleP, AngleY = {}, {}
local Buttons = {}

-- Localized items
local Styles = Core.Config.Style
local st, Prepare, vON = SysTime, SQLPrepare, include( "sv_von.lua" )
local BotType = { Main = 1, Multi = 2 }
local BasePath = Core.Config.BaseType .. "/bots/"
local PLAYER = FindMetaTable( "Player" )


--[[
	Description: Loads all relevant data from the stored text files and initializes the bots
--]]
function Bot.Init()
	-- Checking for a deeper directory still creates all previous folders
	if not file.Exists( BasePath .. "revisions", "DATA" ) then
		file.CreateDir( BasePath .. "revisions" )
	end
	
	-- Get all bots
	local bots = file.Find( BasePath .. game.GetMap() .. "*.txt", "DATA" )
	
	-- Loop over each bot file
	for i = 1, #bots do
		local fh = file.Open( BasePath .. bots[ i ], "r", "DATA" )
		if not fh then continue end
		
		-- Read the first bit (bound to contain the full info)
		local data = fh:Read( 1024 )
		local newline = string.find( data, "\n", 1, true )
		if newline then
			local enc = string.sub( data, 1, newline - 1 )
			local dec = vON.deserialize( enc )
			
			-- If we have valid data, proceed in loading and add to list
			if dec and dec.Style then
				local style = dec.Style
				local remain = fh:Size() - newline
				fh:Seek( newline )
				
				local Merged = vON.deserialize( fh:Read( remain ) )
				BotOriginX[ style ] = Merged[ 1 ]
				BotOriginY[ style ] = Merged[ 2 ]
				BotOriginZ[ style ] = Merged[ 3 ]
				BotAngleP[ style ] = Merged[ 4 ]
				BotAngleY[ style ] = Merged[ 5 ]
				BotButtons[ style ] = Merged[ 6 ]
				BotFrames[ style ] = #BotOriginX[ style ]
				
				BotInfo[ style ] = dec
				BotInfo[ style ].Saved = true
				BotInfo[ style ].CompletedRun = true
				BotInfo[ style ].BotCooldown = nil
			end
		end
		
		fh:Close()
	end
	
	-- Set admin panel items
	Core.SetAdminItem( 18, "Remove bot", "Developer", Bot.OnAdminCommand, Bot.OnAdminButton )
	Core.SetAdminItem( 35, "Change bot", "Developer", Bot.OnAdminCommand, Bot.OnAdminButton )
	Core.SetAdminItem( 19, "Set bot frame", "Super", Bot.OnAdminCommand, Bot.OnAdminButton )
	
	-- Show that we loaded
	Core.Config.Var.Activate( "Bot", Bot )
	Core.PrintC( "[Startup] Extension 'bot' activated" )
end
Core.PostInitFunc = Bot.Init

--[[
	Description: Saves all bots (instant or not)
--]]
function Bot.Save( bInstant, szRequestee, fCallback )
	-- By default we're not going to save
	local count = 0
	
	-- Check if there are normal bots that aren't yet saved
	for _,info in pairs( BotInfo ) do
		if not info.Saved then
			count = count + 1
		end
	end
	
	-- Check if there's any history bots to be saved
	for _,info in pairs( BotForceRuns ) do
		count = count + 1
	end
	
	-- If there's players online, we'll drop them a message
	if count == 0 then return fCallback and fCallback() end
	if not bInstant and #player.GetHumans() > 0 then
		timer.Simple( 1, function() Bot.Save( true, szRequestee, fCallback ) end )
		return Core.Print( nil, "General", Core.Text( "BotSaving", count, count != 1 and "s" or "", szRequestee and "as requested by " .. szRequestee or "prepare for some lag!" ) )
	end
	
	-- Set timing variables
	local Fulltime, Fullcount = st(), 0
	
	-- Start the full save procedure
	for style,info in pairs( BotInfo ) do
		if not info.Saved then
			if not BotOriginX[ style ] or not BotFrames[ style ] or BotFrames[ style ] < 2 then continue end
			if style >= Bot.HistoryID then continue end
			
			local name = BasePath .. game.GetMap()
			if style != Styles.Normal then
				name = name .. "_" .. style
			end
			
			if file.Exists( name .. ".txt", "DATA" ) then
				local id = 1
				local fp = string.gsub( name, "bots/", "bots/revisions/" ) .. "_v"
				
				while file.Exists( fp .. id .. ".txt", "DATA" ) do
					id = id + 1
				end
				
				local existing = file.Read( name .. ".txt", "DATA" )
				file.Write( fp .. id .. ".txt", existing )
			end
			
			-- Get the run info
			local RunInfo = table.Copy( info )
			RunInfo.Saved = true
			RunInfo.CompletedRun = nil
			RunInfo.BotCooldown = nil
			RunInfo = vON.serialize( RunInfo )
			
			-- Create a new table with data
			local Merged = {}
			Merged[ 1 ] = BotOriginX[ style ]
			Merged[ 2 ] = BotOriginY[ style ]
			Merged[ 3 ] = BotOriginZ[ style ]
			Merged[ 4 ] = BotAngleP[ style ]
			Merged[ 5 ] = BotAngleY[ style ]
			Merged[ 6 ] = BotButtons[ style ]
			
			-- Do the REAL intensive work now
			local BinaryData = vON.serialize( Merged )
			
			-- Create new files
			local fn = name .. ".txt"
			if file.Exists( fn, "DATA" ) then
				file.Delete( fn )
			end
			
			-- Write this massive chunk of data
			file.Write( fn, RunInfo .. "\n" )
			file.Append( fn, BinaryData )
			
			-- Make sure it doesn't save twice
			info.Saved = true
			Fullcount = Fullcount + 1
		end
	end
	
	-- Handle all the force saved runs
	for index,info in pairs( BotForceRuns ) do
		local style = info.Style
		local name = BasePath .. game.GetMap()
		
		if style != Styles.Normal then
			name = name .. "_" .. style
		end
		
		local id = 1
		local fp = string.gsub( name, "bots/", "bots/revisions/" ) .. "_v"
		
		while file.Exists( fp .. id .. ".txt", "DATA" ) do
			id = id + 1
		end
		
		-- Copy over the important details
		local Merged = info.Data
		info.Data = nil
		info.Saved = true
		info.CompletedRun = nil
		info.BotCooldown = nil
		
		-- Do the REAL intensive work now
		local RunInfo = vON.serialize( info )
		local BinaryData = vON.serialize( Merged )
		
		-- Create new files
		file.Write( fp .. id .. ".txt", RunInfo .. "\n" )
		file.Append( fp .. id .. ".txt", BinaryData )
		
		-- Remove the entry
		BotForceRuns[ index ] = nil
		Fullcount = Fullcount + 1
	end
	
	-- Print out a message if necessary
	if Fullcount > 0 then
		local szCount = Fullcount > 1 and "All " .. Fullcount or Fullcount
		local szRun = Fullcount > 1 and "runs have" or "run has"
		Core.Print( nil, "General", Core.Text( "BotSaved", szCount, szRun, Core.ConvertTime( st() - Fulltime ) ) )
		Core.PrintC( "[Event] All runs (" .. Fullcount .. "x) have been saved" )
	end
	
	-- Call the callback
	if fCallback then
		fCallback()
	end
end


-- Player part

--[[
	Description: Ends a bot run and saves it if appropriate
--]]
function Bot.PlayerEndRun( ply, nTime, nID )
	if not IsValid( ply ) then return false end
	
	-- Security checks
	if not Frame[ ply ] or not OriginX[ ply ] then return false end
	if Frame[ ply ] < 2 or #OriginX[ ply ] < 2 then return false end
	if (not ply.TimerNormal and not ply.TimerBonus) or (not ply.TimerNormalFinish and not ply.TimerBonusFinish) then return false end
	
	-- Check if we're good with overwriting the existing bot or no
	local style = ply.Style -- To-Do: With bonuses this would go wrong
	if BotInfo[ style ] and BotInfo[ style ].Time and nTime >= BotInfo[ style ].Time then
		-- Only show the message if we're talking about a top 10 finish
		if nID <= 10 then
			Core.Print( ply, "Timer", Core.Text( "BotSlow", Core.ConvertTime( nTime - BotInfo[ style ].Time ) ) )
		end
		
		return false
	end
	
	-- Set the tables directly and give the player new table addresses
	BotOriginX[ style ] = OriginX[ ply ]
	BotOriginY[ style ] = OriginY[ ply ]
	BotOriginZ[ style ] = OriginZ[ ply ]
	BotAngleP[ style ] = AngleP[ ply ]
	BotAngleY[ style ] = AngleY[ ply ]
	BotButtons[ style ] = Buttons[ ply ]

	-- Assign the new tables
	OriginX[ ply ] = {}
	OriginY[ ply ] = {}
	OriginZ[ ply ] = {}
	AngleP[ ply ] = {}
	AngleY[ ply ] = {}
	Buttons[ ply ] = {}
	
	BotFrames[ style ] = #BotOriginX[ style ]
	BotInfo[ style ] = { Name = ply:Name(), Time = nTime, Style = style, SteamID = ply.UID, Date = os.date( "%Y-%m-%d %H:%M:%S", os.time() ), Saved = false, Start = st() }
	
	-- Change the bot display
	Bot.SetMultiBot( style )
	
	-- Pre-expand and clean up
	Bot.CleanPlayer( ply )
	
	return true
end

--[[
	Description: Setup the bot tables
--]]
function Bot.AddPlayer( ply, force )
	-- Since this only gets called once every now and then, check if the bots are present
	Bot.CheckStatus()

	local count = #player.GetHumans()
	if count < Bot.BusyLimit or force then
		-- Initialize the tables once
		OriginX[ ply ] = {}
		OriginY[ ply ] = {}
		OriginZ[ ply ] = {}
		AngleP[ ply ] = {}
		AngleY[ ply ] = {}
		Buttons[ ply ] = {}
	else
		Core.Print( ply, "Notification", Core.Text( "BotQueue" ) )
	end
end

--[[
	Description: Change if recording is active on the player
--]]
function Bot.SetPlayerActive( ply, value )
	if not OriginX[ ply ] then
		Active[ ply ] = nil
		return false
	end
	
	Active[ ply ] = value
end

--[[
	Description: Gets the current frame the player is at
--]]
function Bot.GetPlayerFrame( ply )
	if not Active[ ply ] then return 0 end
	return Frame[ ply ] or 0
end

--[[
	Description: Checks whether or not the player has been dequeued
--]]
function Bot.IsPlayerActive( ply )
	return Active[ ply ]
end

--[[
	Description: Clean all stored frame data on the player
--]]
function Bot.CleanPlayer( ply, bRemove )
	if not OriginX[ ply ] then return end

	-- Clean all tables
	OriginX[ ply ] = {}
	OriginY[ ply ] = {}
	OriginZ[ ply ] = {}
	AngleP[ ply ] = {}
	AngleY[ ply ] = {}
	Buttons[ ply ] = {}

	-- Reset the frame to the beginning
	Frame[ ply ] = 1
	
	-- Remove if we need to
	if bRemove then
		Bot.SetPlayerActive( ply )
	end
end

--[[
	Description: Chop! Chop! This removes the excessive starting bit of the run
	Notes: This is what allows recording in the start zone. It's more intense on the server, but way cooler
--]]
function Bot.ChopFrames( ply )
	if not OriginX[ ply ] then return end
	if not Frame[ ply ] then return end
	
	-- See if chops are appropriate
	local FrameDifference = Frame[ ply ] - Bot.StartFrames
	if FrameDifference >= 0 then
		-- Move the end to the begin of the array
		for i = 1, Bot.StartFrames do
			OriginX[ ply ][ i ] = OriginX[ ply ][ FrameDifference + i ]
			OriginY[ ply ][ i ] = OriginY[ ply ][ FrameDifference + i ]
			OriginZ[ ply ][ i ] = OriginZ[ ply ][ FrameDifference + i ]
			AngleP[ ply ][ i ] = AngleP[ ply ][ FrameDifference + i ]
			AngleY[ ply ][ i ] = AngleY[ ply ][ FrameDifference + i ]
			Buttons[ ply ][ i ] = Buttons[ ply ][ FrameDifference + i ]
		end
		
		-- And wipe the remaining parts of the array
		for i = Bot.StartFrames + 1, #OriginX[ ply ] do
			OriginX[ ply ][ i ] = nil
			OriginY[ ply ][ i ] = nil
			OriginZ[ ply ][ i ] = nil
			AngleP[ ply ][ i ] = nil
			AngleY[ ply ][ i ] = nil
			Buttons[ ply ][ i ] = nil
		end
		
		-- Finally set the frame to where we chopped
		Frame[ ply ] = Bot.StartFrames
	end
end

-- More bot functions

--[[
	Description: Clears out ALL data we have on a bot
--]]
function Bot.Clear( bot, nStyle )
	BotFrame[ nStyle ] = nil
	BotFrames[ nStyle ] = nil
	BotInfo[ nStyle ] = nil
	
	BotOriginX[ nStyle ] = {}
	BotOriginY[ nStyle ] = {}
	BotOriginZ[ nStyle ] = {}
	BotAngleP[ nStyle ] = {}
	BotAngleY[ nStyle ] = {}
	BotButtons[ nStyle ] = {}
	
	-- If we have a bot just turn it into an idle bot
	if IsValid( bot ) then
		if not BotPlayer[ bot ] then return end
		
		BotPlayer[ bot ] = nil
		Bot.SetInfo( bot, nStyle )
		
		bot:ResetSpawnPosition()
	end
end

--[[
	Description: Sets the essential settings for each respawn
--]]
function Bot.HandleSpawn( ply )
	-- Disallow bots to do anything and set their default values accordingly
	ply:SetMoveType( 0 )
	ply:SetFOV( 90, 0 )
	ply:SetGravity( 0 )
	
	ply:DrawShadow( false )
	ply:StripWeapons()
	
	-- Reset the bot to their default position
	ply:ResetSpawnPosition()
end

--[[
	Description: Sets variables on initial joining of bots to identify them
--]]
function Bot.HandleInitialSpawn( ply )
	-- For the system to identify new bots
	ply.Temporary = true
	
	-- Disallow bots to do anything and set their default values accordingly
	ply:SetModel( Core.Config.Player.DefaultBot )
	ply:SetMoveType( 0 )
	ply:SetFOV( 90, 0 )
	ply:SetGravity( 0 )
	
	ply:DrawShadow( false )
	ply:SetPlayerColor( Vector( 1, 0, 0 ) )
	ply:StripWeapons()
end

--[[
	Description: Spawns a bot and sets the details on them
--]]
function Bot.Spawn( tab )
	-- Loop over the bots
	for _,bot in pairs( player.GetBots() ) do
		if bot.Temporary then
			bot:SetMoveType( 0 )
			bot:SetFOV( 90, 0 )
			bot:SetGravity( 0 )
			
			bot.BotType = tab.Type
			bot.Temporary = nil
			bot:StripWeapons()
			
			return Bot.SetInfo( bot, tab.Style )
		end
	end
	
	-- If we don't have enough bots yet, spawn an extra one
	if #player.GetBots() < 2 then
		RunConsoleCommand( "bot" )
		
		timer.Simple( 1, function()
			Bot.Spawn( tab )
		end )
	end
end

--[[
	Description: Checks the status of the bots
--]]
function Bot.CheckStatus()
	-- Test if we even need bots
	if Bot.Count == 0 then return end
	
	-- See if we're already checking
	if Bot.IsStatusCheck then
		return true
	else
		Bot.IsStatusCheck = true
	end
	
	-- Set counting variables
	local nCount = 0
	local bNormal, bMulti
	
	-- Get the count and check which types are alive
	for _,bot in pairs( player.GetBots() ) do
		nCount = nCount + 1
		
		if not bot.BotType then
			continue
		elseif bot.BotType == BotType.Main then
			bNormal = true
		elseif bot.BotType == BotType.Multi then
			bMulti = true
		end
	end
	
	-- Check if there's even a need to spawn another bot
	if nCount < 2 then
		if not bNormal then
			Bot.Spawn( { Type = BotType.Main, Style = Styles.Normal } )
		end
		
		if not bMulti then
			local nStyle = 0
			for style,_ in pairs( BotOriginX ) do
				if style != Styles.Normal then
					nStyle = style
					break
				end
			end
			
			timer.Simple( not bNormal and 2 or 0, function()
				Bot.Spawn( { Type = BotType.Multi, Style = nStyle } )
			end )
		end
	end
	
	-- Clear check after 5 seconds
	timer.Simple( 5, function()
		Bot.IsStatusCheck = nil
	end )
end

--[[
	Description: Gets the Player of a bot
--]]
function Bot.GetPlayer( nStyle, szType )
	for _,ply in pairs( player.GetBots() ) do
		if szType then
			if ply.BotType and ply.BotType == BotType[ szType ] then
				return ply
			end
		else
			if (nStyle == Styles.Normal and ply.BotType == BotType.Main) or (nStyle != Styles.Normal and ply.BotType == BotType.Multi) then
				return ply
			end
		end
	end
end

--[[
	Description: Changes the multi bot to another style
--]]
function Bot.SetMultiBot( nStyle )
	local ply = Bot.GetPlayer( nStyle )
	if not IsValid( ply ) then return end
	
	Bot.SetInfo( ply, nStyle )
end

--[[
	Description: Gets the style of the multi bot
--]]
function Bot.GetMultiBotDetail()
	for _,ply in pairs( player.GetBots() ) do
		if ply.BotType == BotType.Multi then
			local style = ply.Style
			return { style >= Bot.HistoryID and ply.TrueStyle or style, BotInfo[ style ] and BotInfo[ style ].SteamID, BotInfo[ style ] and BotInfo[ style ].Time }
		end
	end
	
	return { 0 }
end

--[[
	Description: Get details about the multi bots
--]]
function Bot.GetMultiBots( bDetail )
	local tab, detail = {}, {}
	local useful = { ["Name"] = true, ["Time"] = true, ["Style"] = true, ["SteamID"] = true, ["Date"] = true }
	
	for style,data in SortedPairs( BotInfo ) do
		if style >= Bot.HistoryID then continue end
		
		local id = #tab + 1
		tab[ id ] = Core.StyleName( style )
		
		if bDetail then
			detail[ id ] = table.Copy( data )
			
			for k,v in pairs( detail[ id ] ) do
				if not useful[ k ] then
					detail[ id ][ k ] = nil
				end
			end
		end
	end
	
	return tab, detail
end

--[[
	Description: Change the multi bot to another style
--]]
function Bot.ChangeMultiBot( nStyle, bSkip )
	local ply = Bot.GetPlayer( nil, "Multi" )
	if not IsValid( ply ) then return "None" end
	if not Core.IsValidStyle( nStyle ) or nStyle >= Bot.HistoryID then return "Invalid" end
	if nStyle == Styles.Normal then return "Exclude" end
	if ply.Style == nStyle then return "Same" end
	
	if BotInfo[ nStyle ] and BotOriginX[ nStyle ] then
		if not BotInfo[ ply.Style ] or BotInfo[ ply.Style ].CompletedRun or (BotInfo[ ply.Style ].Start and st() - BotInfo[ ply.Style ].Start > 60) or bSkip then
			Bot.SetInfo( ply, nStyle )
			
			return Core.Text( "BotChangeMultiDone", BotInfo[ nStyle ].Name, Core.StyleName( BotInfo[ nStyle ].Style ), Core.ConvertTime( BotInfo[ nStyle ].Time ) )
		else
			return "Wait"
		end
	else
		return "Error"
	end
end

--[[
	Description: Try to save the bots if necessary (bots owned by the calling player)
--]]
function Bot.TrySave( ply )
	local bSave, szSteam, szType = false, ply.UID, "BotAllSaved"
	
	-- Loop over normal bots
	for style,data in pairs( BotInfo ) do
		if not data.Saved and data.SteamID == szSteam then
			bSave = true
			break
		end
	end
	
	-- Check additional bots
	for _,data in pairs( BotForceRuns ) do
		if data.SteamID == szSteam then
			szType = "BotSaveForced"
			break
		end
	end
	
	-- Let them know what we did
	if not bSave then
		Core.Print( ply, "General", Core.Text( szType ) )
	else
		Bot.Save( nil, ply:Name() )
	end
end

--[[
	Description: Checks if the player is being force recorded and executes a save if so
--]]
function Bot.PostFinishForce( ply )
	if not ply.BotForce then return end
	
	timer.Simple( 1, function()
		if IsValid( ply ) then
			if Bot.ForceSave( ply ) then
				if IsValid( ply.BotForce ) then
					if ply.BotForce == ply then
						Core.Print( ply, "General", Core.Text( "CommandBotForceSaved" ) )
					else
						Core.Print( ply.BotForce, "General", Core.Text( "CommandBotForceFeedback", ply:Name() ) )
					end
					
					ply.BotForce = nil
				end
			end
		end
	end )
end

--[[
	Description: Tries to save a bot at the given moment
--]]
function Bot.ForceSave( ply, bSelf )
	-- Security checks
	if not Frame[ ply ] or not OriginX[ ply ] or Active[ ply ] or #OriginX[ ply ] < 2 then return Core.Print( ply, "Timer", Core.Text( "BotAdditionalNotEligible", "Please make sure you are recorded properly." ) ) end
	
	-- Check bonus validity
	local style, bonus = ply.Style
	if ply.Bonus then
		if not ply.TimerBonus or not ply.TimerBonusFinish then return Core.Print( ply, "Timer", Core.Text( "BotAdditionalNotEligible", "Make sure you are recorded and at the end of the map with a stopped timer." ) ) end
		
		bonus = true
	else
		if not ply.TimerNormal or not ply.TimerNormalFinish then return Core.Print( ply, "Timer", Core.Text( "BotAdditionalNotEligible", "Make sure you are recorded and at the end of the map with a stopped timer." ) ) end
	end
	
	-- Check saved data
	local tab = ply.LastObtainedFinish
	if not tab then return Core.Print( ply, "Timer", Core.Text( "BotAdditionalNotEligible", "You have to stand in the end zone after improving your time." ) ) end
	
	local nTime = tab[ 1 ]
	local nStyle = tab[ 2 ]
	local nFinish = tab[ 3 ]
	
	-- Check if all is valid
	local t, tf = (bonus and ply.TimerBonus or ply.TimerNormal) or 0, (bonus and ply.TimerBonusFinish or ply.TimerNormalFinish) or 0
	if nTime != ply.Record or nTime != tf - t or nStyle != style or nFinish != tf then
		return Core.Print( ply, "Timer", Core.Text( "BotAdditionalInvalid" ) )
	end
	
	-- Check if we're good with the time
	if not BotInfo[ style ] or not BotInfo[ style ].Time then
		return Core.Print( ply, "Timer", Core.Text( "BotAdditionalNoTimes" ) )
	end
	
	-- Additional check
	if nTime <= BotInfo[ style ].Time or nTime > BotInfo[ style ].Time * Bot.RecordingMultiplier then
		return Core.Print( ply, "Timer", Core.Text( "BotAdditionalTimeLimited", Core.ConvertTime( BotInfo[ style ].Time * Bot.RecordingMultiplier ) ) )
	end
	
	-- Continue with saving
	return Bot.HandleSpecial( ply, "Force", nTime, { Style = style, Self = bSelf } )
end

--[[
	Description: Tests if the times to be deleted contain a current bot
--]]
function Bot.DeleteFromTimes( tab, nStyle, bLocal )
	local info = BotInfo[ nStyle ]
	if not info or not bLocal then return end
	
	local bRemoved = false
	for i = 1, #tab do
		if info.Style == nStyle and info.SteamID == tab[ i ].szUID and info.Time == tab[ i ].nTime then
			local szStyle = nStyle == Styles.Normal and ".txt" or ("_" .. nStyle .. ".txt")
			if file.Exists( BasePath .. szMap .. szStyle, "DATA" ) then
				file.Delete( BasePath .. szMap .. szStyle )
				bRemoved = true
			end
			
			local bot = Bot.GetPlayer( nil, nStyle == Styles.Normal and "Main" or "Multi" )
			if IsValid( bot ) and bot.Style == nStyle then
				Bot.Clear( bot, nStyle )
			end
		end
	end
	
	return bRemoved
end

--[[
	Description: Scans history runs and deletes the appropriate ones, reorders them after
--]]
function Bot.DeleteFromHistory( tab, nStyle, bLocal )
	if not bLocal then return end
	
	-- Get all history runs
	local runs = Bot.LoadHistory( nStyle )
	local bRemoved = false
	
	-- Loop over all times
	for i = 1, #tab do
		for j = 1, #runs do
			if runs[ j ].Style == nStyle and runs[ j ].SteamID == tab[ i ].szUID and runs[ j ].Time == tab[ i ].nTime then
				if file.Exists( runs[ j ].FilePath, "DATA" ) then
					file.Delete( runs[ j ].FilePath )
					bRemoved = true
					
					local str = runs[ j ].FilePath
					local index = str:match( "^.*()_" )
					local id = tonumber( string.match( string.sub( str, index + 1, #str ), "%d+" ) ) + 1
					local base = string.sub( str, 1, index ) .. "v"
					
					-- Find all existing files
					while file.Exists( base .. id .. ".txt", "DATA" ) do
						file.Write( base .. (id - 1) .. ".txt", file.Read( base .. id .. ".txt", "DATA" ) )
						file.Delete( base .. id .. ".txt" )
						id = id + 1
					end
				end
			end
		end
	end
	
	return bRemoved
end

-- Access functions

--[[
	Description: Sets the bot # record
--]]
function Bot.SetRecord( nStyle, nID )
	local p = Bot.PerStyle[ nStyle ] or 0
	if p > 0 and nID <= p then
		Bot.SetWRPosition( nStyle )
	end
end

--[[
	Description: Handles a collision with a bot and a zone
--]]
function Bot.HandleZoneTrigger( ply )
	local style = BotPlayer[ ply ]
	if not style then return end
	
	BotInfo[ style ].Start = st()
	BotInfo[ style ].StartFrame = BotFrame[ style ] or Bot.AverageStart
	
	Bot.NotifyRestart( style )
	
	if ply:GetCollisionGroup() != COLLISION_GROUP_DEBRIS then
		ply:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
	end
end

--[[
	Description: Calls a restart notification on the bot
--]]
function Bot.NotifyRestart( nStyle )
	local ply = Bot.GetPlayer( nStyle )
	local info = BotInfo[ nStyle ]
	local bEmpty = false
	
	if IsValid( ply ) and not info then
		bEmpty = true
	elseif not IsValid( ply ) or not info then
		return false
	end
	
	local tab, watchers = { true, nil, "Idle bot", nil, true }, {}
	for _,p in pairs( player.GetHumans() ) do
		if not p.Spectating then continue end
		local ob = p:GetObserverTarget()
		if IsValid( ob ) and ob:IsBot() and ob == ply then
			watchers[ #watchers + 1 ] = p
		end
	end
	
	if #watchers == 0 then return end
	if not bEmpty then
		tab[ 2 ] = Bot.GetTime( nStyle )
		tab[ 3 ] = info.Name
		tab[ 4 ] = info.Time
	end
	
	Core.Prepare( "Spectate/Timer", tab ):Send( watchers )
end

--[[
	Description: Generates a notification table for the bot
--]]
function Bot.GenerateNotify( ply, nStyle, varList )
	local info = BotInfo[ nStyle ]
	if not info then return end
	return { true, Bot.GetTime( nStyle ), info.Name, info.Time, varList }
end

--[[
	Description: Function used to automatically start demo recording on bots
--]]
function Bot.AutomaticDemoNotify( bot, prechange )
	for _,p in pairs( player.GetHumans() ) do
		if p.DemoTarget == bot and p.DemoStyle == bot.Style then
			if p.DemoStarted then
				p.DemoStarted = nil
				p.DemoTarget = nil
				p.DemoStyle = nil
				Core.Send( p, "Client/AutoDemo" )
				Core.Print( p, "General", Core.Text( "CommandBotDemoEnded" ) )
			elseif not prechange then
				local info = BotInfo[ bot.Style ]
				if not info then return end
				
				local formattime = string.format( "_%.2d_%.2d_%.3d", math.floor( info.Time / 60 % 60 ), math.floor( info.Time % 60 ), math.floor( info.Time * 1000 % 1000 ) )
				local name = info.Name:gsub( "%W", "" ):lower()
				
				p.DemoStarted = true
				Core.Send( p, "Client/AutoDemo", { name .. formattime } )
			end
		end
	end
end

--[[
	Description: Changes the multibot after a single replay has been completed
--]]
function Bot.AlternateMulti( bot, style, frame )
	-- Check if it's a multi-bot
	if bot.BotType == BotType.Multi and not frame then
		-- Sort the list
		local keys = table.GetKeys( BotInfo )
		table.sort( keys )
		
		-- Get the next one in line
		local after
		for i = 1, #keys do
			if keys[ i ] > (BotPlayer[ bot ] or 0) then
				after = keys[ i ]
				break
			end
		end
		
		-- Try to find a new start position
		if not after then
			for i = 1, #keys do
				if keys[ i ] != Styles.Normal and keys[ i ] != BotPlayer[ bot ] then
					after = keys[ i ]
					break
				end
			end
		end
		
		-- Check recording players
		Bot.AutomaticDemoNotify( bot, true )
		
		-- Try changing the multibot
		if after and string.len( tostring( Bot.ChangeMultiBot( after, true ) ) ) > 10 then
			style = after
		end
	end
	
	-- Run automatic bot recording
	if not frame then
		Bot.AutomaticDemoNotify( bot )
	end
	
	-- Reset it to the start
	BotInfo[ style ].CompletedRun = true
	BotInfo[ style ].BotCooldown = nil
	BotFrame[ style ] = frame or 1
	
	-- Get the starting location
	if not bot:InSpawn( Vector( BotOriginX[ style ][ 1 ], BotOriginY[ style ][ 1 ], BotOriginZ[ style ][ 1 ] ) ) then
		BotInfo[ style ].Start = st()
		BotInfo[ style ].StartFrame = BotFrame[ style ] or Bot.AverageStart
		Bot.NotifyRestart( style )
		
		bot:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
	else
		BotInfo[ style ].Start = nil
		BotInfo[ style ].StartFrame = BotFrame[ style ] or 1
		Bot.NotifyRestart( style )
		
		bot:SetCollisionGroup( COLLISION_GROUP_PLAYER )
	end
end

--[[
	Description: Sets the info on a bot and publishes that data
--]]
function Bot.SetInfo( ply, nStyle, nPublish )
	-- Set the style
	ply.TrueStyle = nil
	ply.Style = nStyle
	
	-- If we don't have any data, set the bot to be idle
	local info = BotInfo[ nStyle ]
	if not info or not info.Time then
		ply:VarNet( "Set", "BotName", "" )
		ply:VarNet( "Set", "Style", 0 )
		return ply:VarNet( "UpdateKeys", { "BotName", "Style" } )
	end
	
	-- We have bots!
	Bot.Initialized = true
	
	-- And set the bot details
	BotFrame[ nStyle ] = 1
	BotPlayer[ ply ] = nStyle
	
	-- Set defaults
	BotInfo[ nStyle ].CompletedRun = nil
	BotInfo[ nStyle ].BotCooldown = nil
	BotInfo[ nStyle ].Start = nil
	
	-- If we've got data to set
	ply:VarNet( "Set", "BotName", info.Name )
	ply:VarNet( "Set", "ProfileURI", util.SteamIDTo64( info.SteamID ) )
	ply:VarNet( "Set", "RunDate", string.Explode( " ", info.Date )[ 1 ] )
	ply:VarNet( "Set", "Record", info.Time )
	ply:VarNet( "Set", "Style", info.Style )
	ply:VarNet( "Set", "TrueStyle", nPublish )
	
	-- To-Do: Make sure info.Style here is in bonus format
	local pos = Core.GetRecordID( info.Time, info.Style )
	ply:VarNet( "Set", "WRPos", pos > 0 and pos or 0 )
	ply:VarNet( "UpdateKeys", {} )
	
	-- Update the position variable
	Bot.PerStyle[ info.Style ] = pos
	
	-- Notify a restart on the bot
	if not ply:InSpawn( Vector( BotOriginX[ nStyle ][ 1 ], BotOriginY[ nStyle ][ 1 ], BotOriginZ[ nStyle ][ 1 ] ) ) then
		BotInfo[ nStyle ].Start = st()
		BotInfo[ nStyle ].StartFrame = BotFrame[ nStyle ] or Bot.AverageStart
		Bot.NotifyRestart( nStyle )
		
		ply:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
	else
		BotInfo[ nStyle ].Start = nil
		BotInfo[ nStyle ].StartFrame = BotFrame[ nStyle ] or 1
		Bot.NotifyRestart( nStyle )
		
		ply:SetCollisionGroup( COLLISION_GROUP_PLAYER )
	end
end

--[[
	Description: Sets the WR position of the bot and publishes it
--]]
function Bot.SetWRPosition( nStyle )
	local ply = Bot.GetPlayer( nStyle )
	if not IsValid( ply ) then return end
	
	local info = BotInfo[ nStyle ]
	if not info then
		ply:VarNet( "Set", "BotName", "" )
		ply:VarNet( "Set", "Style", 0 )
		return ply:VarNet( "UpdateKeys", { "BotName", "Style" } )
	end
	
	if info.Time then
		local pos = Core.GetRecordID( info.Time, info.Style ) -- To-Do: Same here, info.Style < 0
		ply:VarNet( "Set", "WRPos", pos > 0 and pos or 0 )
		ply:VarNet( "UpdateKeys", { "WRPos" } )
		
		Bot.PerStyle[ info.Style ] = pos
	end
end

--[[
	Description: Changes playback frame of the bot
--]]
function Bot.SetFrame( nStyle, nFrame, szType )
	local ply = Bot.GetPlayer( not szType and nStyle, szType )
	if IsValid( ply ) then
		local style = nStyle or ply.Style
		if not BotFrame[ style ] then return end
		
		if nFrame < 1 then
			nFrame = BotFrames[ style ] - 100
		end
		
		if nFrame < BotFrames[ style ] then
			BotFrame[ style ] = nFrame
		end
		
		Bot.AlternateMulti( ply, style, nFrame )
	end
end

--[[
	Description: Gets the playback frame and the total frames of a bot
--]]
function Bot.GetFrame( nStyle )
	if IsValid( Bot.GetPlayer( nStyle ) ) and BotFrame[ nStyle ] and BotFrames[ nStyle ] then
		return { BotFrame[ nStyle ], BotFrames[ nStyle ] }
	end
	
	return { 0, 0 }
end

--[[
	Description: Gets the time of the bot using the playback frame and total frames
--]]
function Bot.GetTime( nStyle )
	if IsValid( Bot.GetPlayer( nStyle ) ) and BotFrame[ nStyle ] and BotFrames[ nStyle ] and BotFrames[ nStyle ] > 1 and BotInfo[ nStyle ] and BotInfo[ nStyle ].Time and BotInfo[ nStyle ].Start then
		if BotInfo[ nStyle ].BotCooldown then
			return -10002
		else
			return math.Clamp( st() - BotInfo[ nStyle ].Start, 0, 1e10 )
		end
	end
	
	return -10001
end

--[[
	Description: Checks if the time is a stoppable time, or whether we keep on recording
--]]
function Bot.IsStoppableTime( ply, nLimit )
	local nTime
	
	if ply.Bonus then
		if ply.TimerBonus and not ply.TimerBonusFinish then
			nTime = st() - ply.TimerBonus
		end
	else
		if ply.TimerNormal and not ply.TimerNormalFinish then
			nTime = st() - ply.TimerNormal
		end
	end
	
	if nTime then
		return nTime > nLimit * Bot.RecordingMultiplier
	end
end

--[[
	Description: Gets older bot runs
--]]
function Bot.LoadHistory( nStyle )
	-- Set the base name
	local name = BasePath .. game.GetMap()
	if nStyle != Styles.Normal then
		name = name .. "_" .. nStyle
	end
	
	-- Create the ids
	local id, ids = 1, {}
	local fp = string.gsub( name, "bots/", "bots/revisions/" ) .. "_v"
	
	-- Find all existing files
	while file.Exists( fp .. id .. ".txt", "DATA" ) do
		ids[ id ] = fp .. id .. ".txt"
		id = id + 1
	end
	
	-- Open all files and read data
	local runs, forces = {}, {}
	for i = 1, #ids do
		local fh = file.Open( ids[ i ], "r", "DATA" )
		if not fh then continue end
		
		local data = fh:Read( 1024 )
		local newline = string.find( data, "\n", 1, true )
		if newline then
			local enc = string.sub( data, 1, newline - 1 )
			local dec = vON.deserialize( enc )
			
			if dec and dec.Style == nStyle then
				dec.BinaryOffset = newline
				dec.FilePath = ids[ i ]
				runs[ #runs + 1 ] = dec
			end
		end
		
		fh:Close()
	end
	
	-- Check forced runs
	for id,data in pairs( BotForceRuns ) do
		if data.Style == nStyle then
			forces[ #forces + 1 ] = { id, data }
		end
	end
	
	-- Sort by time
	table.SortByMember( runs, "Time", true )
	
	return runs, forces
end

--[[
	Description: Changes the multi bot to an older run
--]]
function Bot.ChangeHistoryBot( ply, nStyle, data )
	ply.BotHistoryData = nil
	
	-- Get the bot and test if it's valid
	local bot = Bot.GetPlayer( nil, "Multi" )
	if not IsValid( bot ) then return Core.Send( ply, "GUI/UpdateBot", { 3, false, Core.Text( "BotNoValidBots" ) } ) end
	if not Core.IsValidStyle( nStyle ) then return Core.Send( ply, "GUI/UpdateBot", { 3, false, Core.Text( "BotInvalidStyle" ) } ) end
	
	-- Get the style and info
	local current = bot.Style
	local info = BotInfo[ current ]
	
	-- Test if the current multi bot is idle
	if not BotPlayer[ bot ] or not info then
		info = { CompletedRun = true }
	end
	
	-- Check if the info is valid
	if info and (info.CompletedRun or (info.Start and st() - info.Start > 60)) then
		-- Make sure the fictional style is valid
		local style = Bot.HistoryID
		Core.SetStyle( style, "History" )
		
		if not data.ItemID then		
			-- Double check the file
			if not file.Exists( data.FilePath, "DATA" ) then return end

			-- Load data from the file
			local fh = file.Open( data.FilePath, "r", "DATA" )
			if not fh then return end
			
			-- Check if it's a different run
			if info.Style == data.Style and info.SteamID == data.SteamID and info.Time == data.Time then
				return Core.Send( ply, "GUI/UpdateBot", { 3, false, Core.Text( "BotDisplaySameRun" ) } )
			end
			
			-- Set pointer
			local remain = fh:Size() - data.BinaryOffset
			fh:Seek( data.BinaryOffset )
			
			-- Reset certain fields
			data.BinaryOffset = nil
			data.CompletedRun = nil
			data.Saved = true
			
			-- Read data
			local Merged = vON.deserialize( fh:Read( remain ) )
			BotOriginX[ style ] = Merged[ 1 ]
			BotOriginY[ style ] = Merged[ 2 ]
			BotOriginZ[ style ] = Merged[ 3 ]
			BotAngleP[ style ] = Merged[ 4 ]
			BotAngleY[ style ] = Merged[ 5 ]
			BotButtons[ style ] = Merged[ 6 ]
			
			BotFrames[ style ] = #BotOriginX[ style ]
			BotInfo[ style ] = data
			
			-- Set data on the bot itself
			Bot.SetInfo( bot, style, style )
			bot.TrueStyle = nStyle
			
			Core.Send( ply, "GUI/UpdateBot", { 3, true, Core.Text( "BotChangeMultiDone", data.Name, Core.StyleName( data.Style ), Core.ConvertTime( data.Time ) ) } )
			
			-- Close the file handle
			fh:Close()
		else
			-- Switch up the contents
			data = BotForceRuns[ data.ItemID ]
			
			-- Check if it's a different run
			if info.Style == data.Style and info.SteamID == data.SteamID and info.Time == data.Time then
				return Core.Send( ply, "GUI/UpdateBot", { 3, false, Core.Text( "BotDisplaySameRun" ) } )
			end
			
			-- Set certain fields
			data.Saved = true
			
			-- Set the bot data
			local Merged = data.Data
			BotOriginX[ style ] = Merged[ 1 ]
			BotOriginY[ style ] = Merged[ 2 ]
			BotOriginZ[ style ] = Merged[ 3 ]
			BotAngleP[ style ] = Merged[ 4 ]
			BotAngleY[ style ] = Merged[ 5 ]
			BotButtons[ style ] = Merged[ 6 ]
			
			BotFrames[ style ] = #BotOriginX[ style ]
			BotInfo[ style ] = data
			
			-- Set data on the bot itself
			Bot.SetInfo( bot, style )
			bot.TrueStyle = nStyle
			
			Core.Send( ply, "GUI/UpdateBot", { 3, true, Core.Text( "BotChangeMultiDone", data.Name, Core.StyleName( data.Style ), Core.ConvertTime( data.Time ) ) } )
		end
	else
		Core.Send( ply, "GUI/UpdateBot", { 3, false, Core.Text( "BotChangeMultiPlayback" ) } )
	end
end

--[[
	Description: Handles any extension related data
--]]
function Bot.HandleSpecial( ply, szType, nTime, data )
	if szType == "TAS" then
		-- Base style ID
		local style = Bot.BaseID.TAS + ply.Style
		
		-- Cancel out if it's invalid
		if #data[ 1 ] < 2 then return end
		
		-- Set the tables directly
		BotOriginX[ style ] = data[ 1 ]
		BotOriginY[ style ] = data[ 2 ]
		BotOriginZ[ style ] = data[ 3 ]
		BotAngleP[ style ] = data[ 4 ]
		BotAngleY[ style ] = data[ 5 ]
		BotButtons[ style ] = data[ 6 ]
		
		BotFrames[ style ] = #BotOriginX[ style ]
		BotInfo[ style ] = { Name = ply:Name(), Time = nTime, Style = style, SteamID = ply.UID, Date = os.date( "%Y-%m-%d %H:%M:%S", os.time() ), Saved = false, Start = st() }
		
		local bot = Bot.GetPlayer( nil, "Multi" )
		if IsValid( bot ) and bot.Style == style then
			Bot.SetInfo( bot, style )
		end
	elseif szType == "Stage" then
		-- Base style ID
		local style = Bot.BaseID.Stage + data[ 3 ]
		
		-- Set new data containers
		local ox, oy, oz = {}, {}, {}
		local ap, ay = {}, {}
		local bt = {}
		
		-- Read containers
		local rox, roy, roz = OriginX[ ply ], OriginY[ ply ], OriginZ[ ply ]
		local rap, ray = AngleP[ ply ], AngleY[ ply ]
		local rbt = Buttons[ ply ]
		
		-- Validate arrays and indices
		if not rox or #rox == 0 then return end
		if data[ 2 ] - 1 == #rox then data[ 2 ] = #rox end		
		if data[ 1 ] < 1 or data[ 2 ] > #rox then return end
		
		-- Iterate over the table and copy each frame
		local j = 1
		for i = data[ 1 ], data[ 2 ] do
			ox[ j ] = rox[ i ]
			oy[ j ] = roy[ i ]
			oz[ j ] = roz[ i ]
			ap[ j ] = rap[ i ]
			ay[ j ] = ray[ i ]
			bt[ j ] = rbt[ i ]
			
			j = j + 1
		end
		
		-- Cancel out if it's invalid
		if #ox < 2 then return end
		
		-- Set the tables directly
		BotOriginX[ style ] = ox
		BotOriginY[ style ] = oy
		BotOriginZ[ style ] = oz
		BotAngleP[ style ] = ap
		BotAngleY[ style ] = ay
		BotButtons[ style ] = bt
		
		BotFrames[ style ] = #BotOriginX[ style ]
		BotInfo[ style ] = { Name = ply:Name(), Time = nTime, Style = style, SteamID = ply.UID, Date = os.date( "%Y-%m-%d %H:%M:%S", os.time() ), Saved = false, Start = st() }
		
		local bot = Bot.GetPlayer( nil, "Multi" )
		if IsValid( bot ) and bot.Style == style then
			Bot.SetInfo( bot, style )
		end
		
		return true
	elseif szType == "Force" then
		local tab = {}
		tab[ 1 ] = OriginX[ ply ]
		tab[ 2 ] = OriginY[ ply ]
		tab[ 3 ] = OriginZ[ ply ]
		tab[ 4 ] = AngleP[ ply ]
		tab[ 5 ] = AngleY[ ply ]
		tab[ 6 ] = Buttons[ ply ]
		
		OriginX[ ply ] = {}
		OriginY[ ply ] = {}
		OriginZ[ ply ] = {}
		AngleP[ ply ] = {}
		AngleY[ ply ] = {}
		Buttons[ ply ] = {}
		
		BotForceRuns[ #BotForceRuns + 1 ] = { Name = ply:Name(), Time = nTime, Style = data.Style, SteamID = ply.UID, Date = os.date( "%Y-%m-%d %H:%M:%S", os.time() ), Data = tab }
		
		if data.Self then
			Core.Print( ply, "General", Core.Text( "CommandBotForceSaved" ) )
		end
		
		return true
	elseif szType == "Import" then
		local style = nTime
		if BotInfo[ style ] then
			return Core.Print( ply, "General", Core.Text( "BotImportOverride" ) )
		end
		
		-- Double check the file
		local output = BasePath .. game.GetMap() .. (style != Styles.Normal and "_" .. style or "") .. ".txt"
		if not file.Exists( data.FilePath, "DATA" ) then
			return Core.Print( ply, "General", Core.Text( "BotImportFiles" ) )
		end
		
		-- Load data from the file
		local binary = file.Read( data.FilePath, "DATA" )
		if not binary then return end
		
		-- Reset certain fields
		data.BinaryOffset = nil
		data.CompletedRun = nil
		data.Saved = true
		
		-- Write the data and remove old file
		file.Write( output, binary )
		file.Delete( data.FilePath )
		
		-- Perform pattern operations on name
		local str = data.FilePath
		local index = str:match( "^.*()_" )
		local id = tonumber( string.match( string.sub( str, index + 1, #str ), "%d+" ) ) + 1
		local base = string.sub( str, 1, index ) .. "v"
		
		-- Find all existing files
		while file.Exists( base .. id .. ".txt", "DATA" ) do
			file.Write( base .. (id - 1) .. ".txt", file.Read( base .. id .. ".txt", "DATA" ) )
			file.Delete( base .. id .. ".txt" )
			id = id + 1
		end
		
		-- Get the actual bot data
		local newline = string.find( binary, "\n", 1, true )
		if not newline then return end
		
		-- Deserialize
		local Merged = vON.deserialize( string.sub( binary, newline + 1, #binary ) )
		BotOriginX[ style ] = Merged[ 1 ]
		BotOriginY[ style ] = Merged[ 2 ]
		BotOriginZ[ style ] = Merged[ 3 ]
		BotAngleP[ style ] = Merged[ 4 ]
		BotAngleY[ style ] = Merged[ 5 ]
		BotButtons[ style ] = Merged[ 6 ]
		
		BotFrames[ style ] = #BotOriginX[ style ]
		BotInfo[ style ] = data

		-- Set data on the bot itself
		local bot = Bot.GetPlayer( nil, style == Styles.Normal and "Main" or "Multi" )
		if IsValid( bot ) then
			Bot.SetInfo( bot, style )
		end
		
		-- And notify the player
		Core.Print( ply, "General", Core.Text( "BotImportSucceeded" ) )
	elseif szType == "Fetch" then
		return BotOriginX[ data ], BotOriginY[ data ], BotOriginZ[ data ], BotAngleP[ data ], BotAngleY[ data ], BotInfo[ data ]
	end
end


-- Main control

--[[
	Description: Actually records the players and plays back the bot
--]]
local CreateVec, CreateAng = Vector, Angle
local function BotRecord( ply, data )
	if Active[ ply ] then
		local origin = data:GetOrigin()
		local eyes = data:GetAngles()
		local frame = Frame[ ply ]
		
		OriginX[ ply ][ frame ] = origin.x
		OriginY[ ply ][ frame ] = origin.y
		OriginZ[ ply ][ frame ] = origin.z
		AngleP[ ply ][ frame ] = eyes.p
		AngleY[ ply ][ frame ] = eyes.y
		
		Frame[ ply ] = frame + 1
	elseif BotPlayer[ ply ] then
		local style = BotPlayer[ ply ]
		local frame = BotFrame[ style ]
		
		if frame >= BotFrames[ style ] then
			if not BotInfo[ style ].BotCooldown then
				BotInfo[ style ].BotCooldown = st()
				BotInfo[ style ].Start = nil
				
				Bot.NotifyRestart( style )
			end
			
			local nDifference = st() - BotInfo[ style ].BotCooldown
			if nDifference >= 2 then
				Bot.AlternateMulti( ply, style )
			elseif nDifference >= 0 then
				frame = BotFrames[ style ]
			end
			
			data:SetOrigin( CreateVec( BotOriginX[ style ][ frame ], BotOriginY[ style ][ frame ], BotOriginZ[ style ][ frame ] ) )
			ply:SetEyeAngles( CreateAng( BotAngleP[ style ][ frame ], BotAngleY[ style ][ frame ], 0 ) )
		else
			data:SetOrigin( CreateVec( BotOriginX[ style ][ frame ], BotOriginY[ style ][ frame ], BotOriginZ[ style ][ frame ] ) )
			ply:SetEyeAngles( CreateAng( BotAngleP[ style ][ frame ], BotAngleY[ style ][ frame ], 0 ) )
			
			BotFrame[ style ] = frame + 1
		end
	end
end
hook.Add( "SetupMove", "PositionRecord", BotRecord )

--[[
	Description: Records player keys and sets them on the bot
--]]
local function BotButtonRecord( ply, data )
	if Active[ ply ] then
		Buttons[ ply ][ Frame[ ply ] ] = data:GetButtons()
	elseif BotPlayer[ ply ] then
		data:ClearButtons()
		data:ClearMovement()
		
		local style = BotPlayer[ ply ]
		local frame = BotFrame[ style ]
		if BotButtons[ style ][ frame ] then
			data:SetButtons( BotButtons[ style ][ frame ] )
		end
	end
end
hook.Add( "StartCommand", "ButtonRecord", BotButtonRecord )

--[[
	Description: Ticks to check bot details and player progress
--]]
local function ControlBotPlayers()
	for ply,_ in pairs( BotPlayer ) do
		if IsValid( ply ) then
			if ply:GetMoveType() != 0 then ply:SetMoveType( 0 ) end
			if ply:GetFOV() != 90 then ply:SetFOV( 90, 0 ) end
		end
	end
	
	local humans = player.GetHumans()
	if #player.GetBots() != Bot.Count and #humans > 0 then
		Bot.EmptyTick = (Bot.EmptyTick or 0) + 1
		
		if Bot.EmptyTick > 2 then
			Bot.EmptyTick = nil
			Bot.CheckStatus()
		end
	end
	
	for i = 1, #humans do
		local p = humans[ i ]
		if not Active[ p ] then continue end
		
		if p:InSpawn() then
			if Bot.GetPlayerFrame( p ) > 500 then
				Bot.ChopFrames( p )
			end
		else
			if BotInfo[ p.Style ] and BotInfo[ p.Style ].Time and Bot.IsStoppableTime( p, BotInfo[ p.Style ].Time ) and Active[ p ] then
				Bot.CleanPlayer( p )
				Bot.SetPlayerActive( p )
			end
		end
	end
end
timer.Create( "BotController", 5, 0, ControlBotPlayers )

--[[
	Description: Handles the admin panel buttons
--]]
local function OnAdminCommand( ply, ID, Admin )
	-- Remove bot
	if ID == 18 then
		local spec = ply:GetObserverTarget()
		if IsValid( spec ) and spec:IsBot() and spec.BotType then
			ply.AdminBotTarget = spec
			ply.AdminBotInfo = BotInfo[ spec.Style ]
			
			local tabRequest = Admin.GenerateRequest( Core.Text( "AdminBotRemoveCaption" ), "Confirm removal", "No", ID )
			Core.Send( ply, "Global/Admin", { "Request", tabRequest } )
		else
			Core.Print( ply, "Admin", Core.Text( "AdminBotRemoveTarget" ) )
		end
	
	-- Set bot frame
	elseif ID == 19 then
		local ob = ply:GetObserverTarget()
		if not IsValid( ob ) or not ob:IsBot() then
			return Core.Print( ply, "Admin", Core.Text( "AdminBotTargetting" ) )
		end
		
		ply.AdminBotStyle = ob.Style
		
		local tabData = Bot.GetFrame( ply.AdminBotStyle )
		local tabRequest = Admin.GenerateRequest( Core.Text( "AdminBotFrameCaption", tabData[ 1 ], tabData[ 2 ] ), "Change position of playback", tostring( tabData[ 1 ] ), ID )
		Core.Send( ply, "Global/Admin", { "Request", tabRequest } )
	
	-- Change bot
	elseif ID == 35 then
		local tabRequest = Admin.GenerateRequest( Core.Text( "AdminBotChangeCaption" ), "Replace active bot", ply.AdminBotStyle and tostring( ply.AdminBotStyle ) or "", ID )
		Core.Send( ply, "Global/Admin", { "Request", tabRequest } )
	end
end
Bot.OnAdminCommand = OnAdminCommand

--[[
	Description: Handles the admin panel buttons
--]]
local function OnAdminButton( ply, ID, Value, Admin )
	-- Remove bot
	if ID == 18 then
		local bot = ply.AdminBotTarget
		if Value != "Yes" or not IsValid( bot ) then
			return Core.Print( ply, "Admin", Core.Text( "AdminBotRemoveCancelled" ) )
		end
		
		local info, dels = BotInfo[ bot.Style ], {}
		if ply.AdminBotInfo != info then
			return Core.Print( ply, "Admin", Core.Text( "AdminBotRemoveChanged" ) )
		end
		
		if info.Style != bot.Style and bot.Style >= 1000 and bot.TrueStyle and info.FilePath then
			if file.Exists( info.FilePath, "DATA" ) then
				file.Delete( info.FilePath )
				dels[ #dels + 1 ] = "History file deleted"
				
				local str = info.FilePath
				local index = str:match( "^.*()_" )
				local id = tonumber( string.match( string.sub( str, index + 1, #str ), "%d+" ) ) + 1
				local base = string.sub( str, 1, index ) .. "v"
				
				-- Find all existing files
				while file.Exists( base .. id .. ".txt", "DATA" ) do
					file.Write( base .. (id - 1) .. ".txt", file.Read( base .. id .. ".txt", "DATA" ) )
					file.Delete( base .. id .. ".txt" )
					id = id + 1
				end
			end
		else
			local szStyle = info.Style == Core.Config.Style.Normal and ".txt" or ("_" .. info.Style .. ".txt")
			if file.Exists( BasePath .. game.GetMap() .. szStyle, "DATA" ) then
				file.Delete( BasePath .. game.GetMap() .. szStyle )
				dels[ #dels + 1 ] = "File deleted"
			else
				dels[ #dels + 1 ] = "File not found"
			end
		end
		
		ply.AdminBotStyle = bot.Style
		
		Bot.Clear( bot, bot.Style )
		Core.Print( ply, "Admin", Core.Text( "AdminBotRemoveDone", bot.Style, string.Implode( ", ", dels ) ) )
		Admin.AddLog( "Removed the " .. Core.StyleName( bot.Style ) .. " bot on " .. game.GetMap(), ply.UID, ply:Name() )
	
	-- Set bot frame
	elseif ID == 19 then
		local nFrame = tonumber( Value )
		if not nFrame then
			return Core.Print( ply, "Admin", Core.Text( "AdminInvalidFormat", Value, "Number" ) )
		end
		
		local tabData = Bot.GetFrame( ply.AdminBotStyle )
		if nFrame >= tabData[ 2 ] then
			nFrame = tabData[ 2 ] - 2
		end
		
		Bot.SetFrame( ply.AdminBotStyle, nFrame )
	
	-- Fully remove a map
	elseif ID == 22 then
		local files = file.Find( BasePath .. Value .. "*.txt", "DATA" )
		for i = 1, #files do
			file.Delete( BasePath .. files[ i ] )
		end
		
		local history = file.Find( BasePath .. "revisions/" .. Value .. "*.txt", "DATA" )
		for i = 1, #history do
			file.Delete( BasePath .. "revisions/" .. history[ i ] )
		end
	
	-- Change bot on style
	elseif ID == 35 then
		local style = tonumber( Value )
		if not style or not Core.IsValidStyle( style ) then
			return Core.Print( ply, "Admin", Core.Text( "AdminInvalidFormat", Value, "Number" ) )
		end
		
		local root, runs = BasePath .. "revisions/", {}
		local gets = file.Find( root .. game.GetMap() .. "*.txt", "DATA" )
		
		for i = 1, #gets do
			local fh = file.Open( root .. gets[ i ], "r", "DATA" )
			if not fh then continue end
			
			local data = fh:Read( 1024 )
			local newline = string.find( data, "\n", 1, true )
			if newline then
				local enc = string.sub( data, 1, newline - 1 )
				local dec = von.deserialize( enc )
				
				if dec and dec.Style and dec.Style == style then
					dec.BinaryOffset = newline
					dec.FilePath = root .. gets[ i ]
					runs[ #runs + 1 ] = dec
				end
			end
			
			fh:Close()
		end
		
		table.SortByMember( runs, "Time", true )
		
		local styles, details = {}, {}
		for i = 1, #runs do
			styles[ i ] = runs[ i ].Date
			details[ i ] = runs[ i ]
		end
		
		ply.BotChangeData = details
		ply.FinalizeBotChange = function( s, id )
			local data = s.BotChangeData
			local target = data[ id ]
			if not target then return end
			
			Bot.HandleSpecial( s, "Import", target.Style, target )
			Admin.AddLog( "Changed active bot for " .. Core.StyleName( target.Style ) .. " on " .. game.GetMap(), s.UID, s:Name() )
			
			s.BotChangeData = nil
			s.FinalizeBotChange = nil
		end
		
		Core.Send( ply, "GUI/Bot", { ID = "Bot", Dimension = { x = 400, y = 370 }, Args = { Title = "Multi Bots", Mouse = true, Blur = true, Custom = { styles, details, { 0 }, Core.Text( "AdminBotChangeHeader" ) } } } )
	end
end
Bot.OnAdminButton = OnAdminButton

--[[
	Description: Handles the bot command and all subcommands
--]]
local function OnBotCommand( ply, args )
	args.Help = "set/style/play, info/details, save, force, who, add, check, demo"
	
	if args.Key == "mbot" then
		if #args > 0 then
			if args[ 1 ] == "change" and tonumber( args[ 2 ] ) and ply.FinalizeBotChange then
				return ply:FinalizeBotChange( tonumber( args[ 2 ] ) )
			end
			
			local id = tonumber( args[ 1 ] )
			if id and Core.IsValidStyle( id ) then
				local subid = tonumber( args[ 2 ] )
				if subid and ply.BotHistoryData and #ply.BotHistoryData > 0 and ply.BotHistoryData[ subid ] then
					return Bot.ChangeHistoryBot( ply, id, ply.BotHistoryData[ subid ] )
				end
				
				local data, forces = Bot.LoadHistory( id )
				if #data > 0 then
					for _,list in pairs( forces ) do
						local id = list[ 1 ]
						local item = list[ 2 ]
						
						data[ #data + 1 ] = { ItemID = id, Name = item.Name, Time = item.Time, Style = item.Style, SteamID = item.SteamID, Date = item.Date }
					end
					
					ply.BotHistoryData = data
					
					local useful = { ["Name"] = true, ["Time"] = true, ["Style"] = true, ["SteamID"] = true, ["Date"] = true }
					local send = table.Copy( data )
					
					for i = 1, #send do
						for k,v in pairs( send[ i ] ) do
							if not useful[ k ] then
								send[ i ][ k ] = nil
							end
						end
					end
					
					Core.Send( ply, "GUI/UpdateBot", { 0, send, Bot.GetMultiBotDetail(), Core.Text( "CommandBotMultiUpdate" ) } )
				else
					Core.Send( ply, "GUI/UpdateBot", { 1, Core.Text( "CommandBotNoStyle" ) } )
				end
			else
				Core.Send( ply, "GUI/UpdateBot", { 1, Core.Text( "CommandBotValidStyle" ) } )
			end
		else
			local styles, details = Bot.GetMultiBots( true )
			if #styles > 0 then
				Core.Send( ply, "GUI/Bot", { ID = "Bot", Dimension = { x = 400, y = 370 }, Args = { Title = "Multi Bots", Mouse = true, Blur = true, Custom = { styles, details, Bot.GetMultiBotDetail() } } } )
			else
				Core.Print( ply, "General", Core.Text( "CommandBotMultiNone" ) )
			end
		end
		
		return false
	end
	
	if #args == 0 then
		Core.Print( ply, "General", Core.Text( "CommandSubList", args.Key, args.Help ) )
	else
		local szType = tostring( args[ 1 ] )
		if szType == "set" or szType == "style" or szType == "play" then
			if not args[ 2 ] then
				local list = Bot.GetMultiBots()
				if #list > 0 then
					return Core.Print( ply, "General", Core.Text( "CommandBotRecordList", string.Implode( ", ", list ), szType ) )
				else
					return Core.Print( ply, "General", Core.Text( "CommandBotNoPlayback" ) )
				end
			end
			
			local nStyle = tonumber( args[ 2 ] )
			if not nStyle then
				table.remove( args.Upper, 1 )
				local szStyle = string.Implode( " ", args.Upper )
				
				local nGet = Core.GetStyleID( szStyle )
				if not Core.IsValidStyle( nGet ) then
					return Core.Print( ply, "General", Core.Text( "MiscInvalidStyle" ) )
				else
					nStyle = nGet
				end
			end
			
			local change = Bot.ChangeMultiBot( nStyle )
			Core.Send( ply, "GUI/UpdateBot", { 3, string.len( change ) > 10, string.len( change ) > 10 and change or Core.Text( "BotMulti" .. change ) } )
		elseif szType == "info" or szType == "details" then
			local nStyle = nil
			if not args[ 2 ] or not tonumber( args[ 2 ] ) then
				if args[ 2 ] then
					table.remove( args.Upper, 1 )
					local szStyle = string.Implode( " ", args.Upper )
				
					local a = Core.GetStyleID( szStyle )
					if not Core.IsValidStyle( a ) then
						return Core.Print( ply, "General", Core.Text( "MiscInvalidStyle" ) )
					else
						nStyle = a
					end
				else
					local ob = ply:GetObserverTarget()
					if IsValid( ob ) and ob:IsBot() then
						nStyle = ob.Style
					else
						return Core.Print( ply, "General", Core.Text( "CommandBotNoTarget", szType ) )
					end
				end
			else
				nStyle = tonumber( args[ 2 ] )
				if not Core.IsValidStyle( nStyle ) then
					return Core.Print( ply, "General", Core.Text( "CommandStyleInvalid" ) )
				end
			end
			
			if nStyle then
				local info = BotInfo[ nStyle ]
				if info then
					Core.Print( ply, "General", Core.Text( "BotDetails", info.Name, info.SteamID, Core.StyleName( info.Style ), Core.ConvertTime( info.Time ), info.Date ) )
				else
					Core.Print( ply, "General", Core.Text( "BotDetailsNone", Core.StyleName( nStyle ) ) )
				end
			end
		elseif szType == "save" then
			Bot.TrySave( ply )
		elseif szType == "force" then
			if ply.Spectating then
				local ob = ply:GetObserverTarget()
				if IsValid( ob ) then
					ob.BotForce = ply
					Core.Print( ply, "General", Core.Text( "CommandBotForce" ) )
				end
			else
				if Core.IsInsideZone( ply, Core.GetZoneID( "Normal End" ) ) or (ply.Bonus and Core.IsInsideZone( ply, Core.GetZoneID( "Bonus End" ) )) then
					Bot.ForceSave( ply, true )
				else
					if ply.BotForce == ply then
						Core.Print( ply, "General", Core.Text( "CommandBotForceAlready" ) )
					else
						ply.BotForce = ply
						Core.Print( ply, "General", Core.Text( "CommandBotForceSelf" ) )
					end
				end
			end
		elseif szType == "who" then
			local ps = {}
			for _,p in pairs( player.GetHumans() ) do
				if not Bot.IsPlayerActive( p ) then
					ps[ #ps + 1 ] = p:Name()
				end
			end
			
			if #ps > 0 then
				Core.Print( ply, "General", Core.Text( "CommandBotWhoList", #ps, string.Implode( ", ", ps ) ) )
			else
				Core.Print( ply, "General", Core.Text( "CommandBotWhoAll" ) )
			end
		elseif szType == "add" then
			if Bot.IsPlayerActive( ply ) then
				return Core.Print( ply, "General", Core.Text( "CommandBotRecordAlready" ) )
			end
			
			if not ply:InSpawn() then
				Core.Print( ply, "General", Core.Text( "CommandBotRecordSpawn" ) )
			else
				Bot.AddPlayer( ply, true )
				
				Bot.CleanPlayer( ply )
				Bot.SetPlayerActive( ply, true )
				
				Core.Print( ply, "General", Core.Text( "CommandBotRecordSuccess" ) )
			end
		elseif szType == "check" then
			Core.Print( ply, "General", Core.Text( "CommandBotRecordDisplay", Bot.IsPlayerActive( ply ) and "" or "not " ) )
		elseif szType == "demo" then
			if not ply.DemoTarget then
				local ob = ply:GetObserverTarget()
				if IsValid( ob ) and ob:IsBot() then
					ply.DemoStarted = nil
					ply.DemoTarget = ob
					ply.DemoStyle = ob.Style
					Core.Print( ply, "General", Core.Text( "CommandBotDemoStarted" ) )
				else
					Core.Print( ply, "General", Core.Text( "CommandBotDemoNone" ) )
				end
			else
				ply.DemoStarted = nil
				ply.DemoTarget = nil
				ply.DemoStyle = nil
				Core.Print( ply, "General", Core.Text( "CommandBotDemoDisable" ) )
			end
		else
			Core.Print( ply, "General", Core.Text( "CommandSubList", args.Key, args.Help ) )
		end
	end
end
Core.AddCmd( { "bot", "wrbot", "mbot" }, OnBotCommand )
Core.AddCmd( { "botsave", "savebot", "savemybot", "iwantmybotsaved", "keepbots" }, Bot.TrySave )

-- Language
Core.AddText( "CommandBotNoStyle", "There are no older bots for this style" )
Core.AddText( "CommandBotValidStyle", "Please select a valid style to load older bots from" )
Core.AddText( "CommandBotMultiNone", "There are no multi bot runs available" )
Core.AddText( "CommandBotRecordList", "Runs on these styles are recorded and playable: 1; (Use !bot 2; Style to start playback.)" )
Core.AddText( "CommandBotNoPlayback", "There are no other bots available for playback." )
Core.AddText( "CommandBotNoTarget", "You have to either spectate a bot or use !bot 1; [Style ID] to use this command." )
Core.AddText( "CommandBotWhoList", "These players are NOT being recorded by the bot (#1;): 2;" )
Core.AddText( "CommandBotWhoAll", "All players are being recorded by the replay bots." )
Core.AddText( "CommandBotRecordAlready", "You are already being recorded by the bot." )
Core.AddText( "CommandBotRecordSpawn", "You have to be in the spawn to re-add yourself to the recorded players" )
Core.AddText( "CommandBotRecordSuccess", "You are now being recorded by the bot again!" )
Core.AddText( "CommandBotRecordDisplay", "You are 1;being recorded by the bot" )
Core.AddText( "CommandBotForce", "1; is now being force-recorded; if the player finishes with a decent time it will be saved" )
Core.AddText( "CommandBotForceSelf", "You are being force-recorded; if you finish with a decent time it will be saved" )
Core.AddText( "CommandBotForceAlready", "You are already being force-recorded" )
Core.AddText( "CommandBotForceSaved", "Your run has been put in the bot cache. It will be saved when the map changes. You will need to use !bot force again if you want it to stay active." )
Core.AddText( "CommandBotForceFeedback", "1; just finished the map and the bot was added to the history cache. It will be automatically saved on map change.\nTo record this player again, you have to use !bot force again." )
Core.AddText( "CommandBotDemoNone", "You have to spectate the bot that you want to record!" )
Core.AddText( "CommandBotDemoStarted", "Automatic recording activated. You have to keep spectating this bot now." )
Core.AddText( "CommandBotDemoDisable", "Automatic recording has been manually disabled!" )
Core.AddText( "CommandBotDemoEnded", "Automatic recording ended" )
Core.AddText( "CommandBotMultiUpdate", "Left click shows more info. Replay a run with right click!\nUse BACKSPACE to go back to the previous page.\nALL previously saved runs on this style:" )

Core.AddText( "BotSlow", "Your time was not good enough to replace the top WR bot (+1;). If you still want to save your run, typing \"!bot force\" might help" )
Core.AddText( "BotSaving", "The server will now save 1; run2;, 3;" )
Core.AddText( "BotSaved", "1; 2; been saved in 3;" )
Core.AddText( "BotMultiWait", "The bot must have at least finished playback once or have passed the 1 minute mark before it can be changed." )
Core.AddText( "BotMultiInvalid", "The entered style was invalid or there are no bots for this style." )
Core.AddText( "BotMultiError", "An error occurred when trying to retrieve data to display. Please wait and try again." )
Core.AddText( "BotMultiSame", "The bot is already playing this style." )
Core.AddText( "BotMultiExclude", "The bot can not display the Normal style run. Check the main bot for that!" )
Core.AddText( "BotDetails", "The bot run was done by 1; [2;] on the 3; style in a time of 4; at this date: 5;" )
Core.AddText( "BotDetailsNone", "There are no recorded runs on the 1; style." )
Core.AddText( "BotQueue", "You are not instantly recorded because the server is rather full. If you wish to be recorded, type /bot add" )
Core.AddText( "BotAllSaved", "All your bots have already been saved or you have no bots." )
Core.AddText( "BotSaveForced", "Your !bot forced run can't be saved with this command, please wait for the map to change." )
Core.AddText( "BotImportOverride", "You can't override an existing bot. Please remove that bot first before proceeding." )
Core.AddText( "BotImportFiles", "Either one of the files isn't accessible or writable. Please check the files." )
Core.AddText( "BotImportSucceeded", "The bot has been imported to the given bot slot! It has automatically been saved." )
Core.AddText( "BotNoValidBots", "No valid bot to target" )
Core.AddText( "BotInvalidStyle", "Invalid target style" )
Core.AddText( "BotDisplaySameRun", "The bot is already displaying this run!" )
Core.AddText( "BotDisplayPostRecord", " The bot is now displaying this run!" )
Core.AddText( "BotDisplayRecordPossible", "The bot can now display this run!" )
Core.AddText( "BotDisplayRecordFastest", "The bot is now displaying this run since it is the fastest run available!" )
Core.AddText( "BotChangeMultiDone", "The bot is now displaying 1;'s 2; run (Time: 3;)" )
Core.AddText( "BotChangeMultiPlayback", "The current multi bot hasn't finished playback yet. Please wait 1 minute or until it has looped at least once." )
Core.AddText( "BotAdditionalNotEligible", "You are currently not eligible to force-save your bot. 1;" )
Core.AddText( "BotAdditionalInvalid", "You can only use this command straight after finishing the map" )
Core.AddText( "BotAdditionalNoTimes", "There are no bots on your style yet. This means this command will not be of any use for you" )
Core.AddText( "BotAdditionalTimeLimited", "Your time may not be faster than the current bot and not slower than 50% on top of the time of the current bot (1;)" )

Core.AddText( "AdminBotRemoveTarget", "Please spectate the bot you wish to remove!" )
Core.AddText( "AdminBotTargetting", "You have to spectate the target bot to change position of the bot." )
Core.AddText( "AdminBotRemoveCancelled", "Bot removal operation has been cancelled!" )
Core.AddText( "AdminBotRemoveChanged", "Please make sure the bot hasn't been changed in the meantime" )
Core.AddText( "AdminBotRemoveDone", "The target bot (Style ID: 1;) has been cleared out [Details: 2;]" )
Core.AddText( "AdminBotRemoveCaption", "Are you sure you want to remove the currently spectated bot? Type 'Yes' to confirm, anything else will cancel out." )
Core.AddText( "AdminBotFrameCaption", "Change position in run of the bot (Currently at 1; / 2;)" )
Core.AddText( "AdminBotChangeCaption", "Enter the Style ID for which you want to replace the active bot" )
Core.AddText( "AdminBotChangeHeader", "This is the list of all bot revisions recorded on the given style.\nLeft click for more info, right click for selection\nAll applicable runs:" )

-- Help commands
local cmd = Core.ContentText( nil, true ).Commands
cmd["bot"] = "Show your bot status. For the subcommands, type !bot ?"
cmd["botsave"] = "Saves your own bot (Same as !bot save)"