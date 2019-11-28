local PLAYER = FindMetaTable( "Player" )

-- Initialize the main admin object
local Admin = {}
Admin.OperatorID = Core.Config.Var.Get( "ServerOperator" )
Admin.OperatorID = Admin.OperatorID != "" and Admin.OperatorID or Core.GetRandomString()

-- Set the access levels with binary increment (2^n)
Admin.Level = {
	None = 0,
	Base = 1,
	Elevated = 2,
	Moderator = 4,
	Admin = 8,
	Super = 16,
	Developer = 32,
	Owner = 64
}

-- Give an icon ID for each access level
Admin.Icons = {
	[Admin.Level.Base] = 1,
	[Admin.Level.Elevated] = 2,
	[Admin.Level.Moderator] = 3,
	[Admin.Level.Admin] = 4,
	[Admin.Level.Super] = 5,
	[Admin.Level.Developer] = 6,
	[Admin.Level.Owner] = 7
}

-- For our community ranks also give an icon
Admin.LoadRank = {}
Admin.CommunityRanks, Admin.CommunityNames = {
	["[pG]"] = Admin.Level.Moderator,
	["=[pG]="] = Admin.Level.Admin
}, {
	[Admin.Level.Moderator] = "Junior Admin",
	[Admin.Level.Admin] = "Full Admin"
}

-- For easy access, copy over the names etc.
Admin.LastAccess = {}
Admin.LevelNames = {}
for key,id in pairs( Admin.Level ) do
	Admin.LevelNames[ id ] = key
end

-- Set the report types and IDs with description
Admin.Reports = {
	{ 1, "Incorrect zone placement" },
	{ 2, "Unfair points assessment" },
	{ 3, "Cheated or exploited time" },
	{ 4, "Exploit or large skip in the map" },
	{ 5, "Hacking player" },
	{ 6, "Suggestion for new map" },
	{ 7, "Suggestion to change zone" },
	{ 8, "Gamemode bug" },
	{ 9, "Gamemode suggestion" },
	{ 10, "Bonus (zone) suggestion" },
	
	{ 50, "Possible strafe assistance" },
	{ 51, "Possible strafe hack" },
	{ 52, "Possible auto-hop" }
}

-- Details for each report type
Admin.ReportDetails = {
	[1] = { "Enter the name of the zone and where it should go (coordinates or text)", "Incorrect zone placement", "Enter new location (123, 456, 789)" },
	[2] = { "Enter the suggested amount of points", "Unfair points assessment", "25 (Has to be a number)" },
	[3] = { "Enter the Steam ID and the style of which time is cheated like so:", "Cheated or exploited time", "Steam ID;Normal" },
	[4] = { "Briefly describe the problem and where it's location is", "Exploit or large skip in the map", "You can go straight to the end at boxes (123, 456, 789)" },			
	-- [5] = { "This will be handled on the forums" },
	[6] = { "Enter the exact name of the map below (or gamebanana link)", "Suggestion for new map", game.GetMap() },
	[7] = { "Enter the name of the zone and how it should be changed", "Suggestion to change zone", "Needs more space at the front" },
	-- [8] = { "This will be handled on the forums" },
	-- [9] = { "This will be handled on the forums" },
	[10] = { "Briefly describe the bonus suggestion you have or enter the start and end coordinates", "Bonus suggestion", "Do this to make it cooler OR Bonus from (Pos1) to (Pos2) and anticheat the tree at (Pos3)" }
}

-- All admin language strings
Admin.Text = {
	["AdminInvalidFormat"] = "The supplied value '1;' is not of the requested type (2;)",
	["AdminMisinterpret"] = "The supplied string '1;' could not be interpreted. Make sure the format is correct.",
	["AdminSetValue"] = "The 1; setting has succesfully been changed to 2;",
	["AdminOperationComplete"] = "The operation has completed succesfully.",
	["AdminHierarchy"] = "The target's permission is greater than or equal to your permission level, thus you cannot perform this action.",
	["AdminDataFailure"] = "The server can't load essential data! If you can, contact an admin to make him identify the issue: 1;",
	["AdminMissingArgument"] = "The 1; argument was missing. It must be of type 2; and have a format of 3;",
	["AdminErrorCode"] = "An error occurred while executing statement: 1;",
	["AdminReportMessage"] = "New (player) report received",
	["AdminReportEvidence"] = "Additional evidence regarding case!",
	["AdminJoinHeader"] = "Administrator authority granted",
	["AdminJoinMessage"] = "Welcome back, 1;. Your authority has been set to 2;.",
	["AdminTimeRemoval"] = "All 1; times have been removed succesfully!",
	["AdminTimesRemoved"] = "1; time(s) have been deleted 2;",
	["AdminReportReceived"] = "Your report has been received in good order. Thank you for your report.",
	["AdminFunctionalityAccess"] = "You don't have access to use this functionality",
	["AdminFunctionalitySurf"] = "This functionality is only usable on Surf.",
	["AdminNoValidPlayer"] = "Couldn't find a valid player with Steam ID: 1;",
	["AdminCommandInvalid"] = "This is not a valid subcommand of 1;",
	["AdminCommandArgument"] = "Please enter a valid Steam ID like this: !admin 1; STEAM_0:ID",
	["AdminSpectatorMove"] = "You have moved 1; to spectator.",
	["AdminSpectatorAlready"] = "This player is already spectating.",
	["AdminForceRock"] = "You have made 1; Rock the Vote.",
	["AdminForceRockAlready"] = "This player has already voted to Rock the Vote.",
	["AdminTimeEditStart"] = "You are now editing times. Type !wr and select an item to remove it. Press this option again to disable it.",
	["AdminTimeEditEnd"] = "You have left time editing mode.",
	["AdminMapVoteCancel"] = "The map vote is now set to 1;be cancelled!",
	["AdminWeaponStrip"] = "You have stripped 1; of their weapons (2;).",
	["AdminPanelReloaded"] = "All admins have been reloaded!",
	["AdminIncognitoWarning"] = "You must be outside of spectator mode in order to change this setting in order to avoid suspicion.",
	["AdminIncognitoToggle"] = "Your incognito mode is now 1;",
	["AdminIncognitoFull"] = "Your admin incognito mode is now 1;",
	["AdminEvidenceNone"] = "No evidence found on this entry",
	["AdminEvidenceStarted"] = "Demo '1;' is now downloading and will be placed in the 'data/2;' folder (Rename .dat to .dem)",
	["AdminEvidenceNoRelated"] = "No related player found on this report",
	["AdminEvidenceNoResults"] = "No results found!",
	["AdminEvidenceMarked"] = "1;arked the report as handled!",
	["AdminEmbeddedReset"] = "Embedded data ID has been reset.",
	["AdminEmbeddedSet"] = "All custom zones set from now on will contain the following embedded data ID: 1;. To revert back to blank data, use the same function but enter nothing.",
	["AdminEmbeddedRange"] = "Please enter a valid ID range. Any positive number above 0 works.",
	["AdminConsoleParse"] = "An error occurred while parsing access level",
	["AdminConsoleAdded"] = "Admin added succesfully!",
	["AdminConsoleError"] = "An error occurred while adding the admin!",
	["AdminZoneFindFailed"] = "Couldn't find selected entity. Please try again.",
	["AdminZoneMoveInfo"] = "You can now start using your keys to move the zone: E (X+), R (X-), Duck (Y+), Jump (Y-), Left Mouse (Z+), Right Mouse (Z-), Scoreboard (End) and Shift (Save)",
	["AdminZoneMoveComplete"] = "Zone position saved!",
	["AdminZoneMoveEnd"] = "Free-move zone hook removed!",
	["AdminMapOptionsNoEntry"] = "You need to have a valid map entry before you can change the options",
	["AdminMapBonusNoEntry"] = "You need to have a valid map entry before you can set the bonus multiplier",
	["AdminMapTierNoEntry"] = "You need to have a valid map entry before you can set the map 1;",
	["AdminBonusPointsInfo"] = "Separate bonus points with spaces. To negate a number add 0: in front of it. Example: 5 1 10 0:100",
	["AdminRemoveUnavailable"] = "The entered map '1;' is not on the nominate list, and thus cannot be deleted as it contains no info.",
	["AdminRemoveComplete"] = "All found data has been deleted!",
	["AdminTeleportZoneWarning"] = "Even for this, you have to be in practice mode. We don't want any accidental 00:00.000 times.",
	["AdminTeleportZoneComplete"] = "You have been teleported to the target zone!",
	["AdminVoteTimeChange"] = "RTV time left has been changed!",
	["AdminTimeDeletionCancel"] = "Time deletion operation has been cancelled!",
	["AdminStyleTimeRemove"] = "All times on 1; have been removed!",
	["AdminChatSilence"] = "The chat is now1; silenced",
	["AdminNotificationEmpty"] = "Aborting notification because text was empty.",
	["AdminTeleportMissingSource"] = "The source entity was lost or disconnected.",
	["AdminTeleportComplete"] = "1; has been teleported to 2;",
	["AdminFullWipeOnline"] = "The target may not be online for this.",
	["AdminFullWipeComplete"] = "Player has been fully wiped!",
	["AdminImportInput"] = "Please enter a correct JSON formatted string containing all essential data",
	["AdminImportComplete"] = "The map '1;' has been imported succesfully (2; zones included)",
	["AdminReportZoneInside"] = "Please stand inside of the related zone!",
	["AdminReportCommunity"] = "Please head to the forums for these issues!",
	["AdminReportInvalid"] = "Invalid report request!",
	["AdminReportLength"] = "The maximum length for a report is 256 characters. Please shorten your message",
	["AdminReportDefault"] = "Please fill in your own custom message.\n'1;' is just an example.",
	["AdminReportMalicious"] = "Sorry, I can't let you do that. Please rephrase your report.",
	["AdminReportNotify"] = "We have received a new player report from 1;. If you can, take a look at it in your admin panel.",
	["AdminReportFrequency"] = "You can only make an admin report every 10 minutes. Please wait."
}

for key,text in pairs( Admin.Text ) do
	Core.AddText( key, text )
	Admin.Text[ key ] = nil
end

-- Set report types
Core.ReportTypes = Admin.Reports

-- Our secure table with all important data
local Secure = {}
Secure.Levels = { [Admin.OperatorID] = Admin.Level.Owner }
Secure.CommunityIDs = {}
Secure.Setup = {
	-- Normal admin management
	{ 12, "Move to spectator", Admin.Level.Moderator, { 1, 1, true }, "Administrative" },
	{ 23, "Strip weapons", Admin.Level.Moderator, { 2, 1, true } },
	{ 27, "Incognito spec.", Admin.Level.Moderator, { 3, 1 } },
	{ 20, "Cancel map vote", Admin.Level.Super, { 4, 1 } },
	{ 26, "Change RTV time", Admin.Level.Developer, { 5, 1 } },
	
	{ 14, "Show logs", Admin.Level.Moderator, { 1, 2 } },
	{ 15, "Show reports", Admin.Level.Moderator, { 2, 2 } },
	{ 16, "Force player RTV", Admin.Level.Super, { 3, 2, true } },
	{ 29, "Send notification", Admin.Level.Developer, { 4, 2 } },
	{ 32, "Incognito admin", Admin.Level.Developer, { 5, 2 } },
	
	-- Map functionality
	{ 5, "Force change map", Admin.Level.Super, { 1, 3 }, "Map editing" },
	{ 3, "Set map multiplier", Admin.Level.Super, { 2, 3 } },
	{ 21, "Set bonus multiplier", Admin.Level.Super, { 3, 3 } },
	{ 11, "Set map options", Admin.Level.Super, { 4, 3 } },
	{ 33, "Set tier or type", Admin.Level.Super, { 5, 3 } },
	
	-- Zone functionality
	{ 1, "Set zone", Admin.Level.Super, { 1, 4 }, "Zone editing" },
	{ 10, "Remove zone", Admin.Level.Super, { 2, 4 } },
	{ 2, "Cancel creation", Admin.Level.Super, { 3, 4 } },
	{ 6, "Reload zones", Admin.Level.Super, { 4, 4 } },
	
	{ 9, "Set zone size", Admin.Level.Super, { 1, 5 } },
	{ 4, "Set zone data", Admin.Level.Super, { 2, 5 } },
	{ 25, "Teleport to zone", Admin.Level.Super, { 3, 5 } },
	{ 31, "Free-move zone", Admin.Level.Super, { 4, 5 } },
	
	-- Operator functionality
	{ 17, "Remove time(s)", Admin.Level.Developer, { 1, 6 }, "Game operations" },
	{ 18, [[]], 128, { 2, 6 } },
	{ 28, "Remove all times", Admin.Level.Developer, { 3, 6 } },
	{ 22, "Remove map", Admin.Level.Developer, { 4, 6 } },
	{ 35, [[]], 128, { 5, 6 } },
	
	{ 7, "Set authority", Admin.Level.Developer, { 1, 7, true } },
	{ 8, "Remove authority", Admin.Level.Developer, { 2, 7, true } },
	{ 24, "Reload admins", Admin.Level.Developer, { 3, 7 } },
	{ 34, "Wipe player", Admin.Level.Developer, { 4, 7 } },
	
	{ 19, [[]], 128, { 1, 8 } },
	{ 30, "Teleport player", Admin.Level.Developer, { 2, 8, true } },
	{ 13, "Import new map", Admin.Level.Developer, { 3, 8 } },
	{ 36, "Silence chat", Admin.Level.Developer, { 4, 8 } },
	
	-- Separate functions
	Evidence = { 50, "Request evidence", Admin.Level.Developer },
	Records = { 51, "Related records", Admin.Level.Developer },
	Handled = { 52, "Mark handled", Admin.Level.Developer },
	Loader = { 54, "Load more", Admin.Level.Developer },
}

-- The notification table for our lovely, non-obnoxious, 'Did you know' notification system
local Notifications = {}
Notifications.Delay = 30
Notifications.Interval = 12 * 60
Notifications.Last = SysTime()
Notifications.Items = {
	{ "Any type of suggestion for maps, times or zones can be made via /admin or the forums", 20 },
	{ "If you're having trouble seeing surfaces through water, you can toggle reflection with /water", 30 },
	{ "Are you experiencing a lot of FPS lag on a map with a complex skybox? Typing /sky might help you with that", 30 },
	{ "We do our best to keep the game up to date for the players. If you have any suggestions, post them on the forums", 20 },
	{ "You can control most client settings via the Main Menu (F1)", 20 },
	{ "All sorts of statistics are tracked locally for your use. View them by going to the Main Menu (F1) and clicking 'Statistics', or view realtime stats with /rts", 20 },
	{ "If you want to know more about the functionality we house, you can see the full list on the Main Menu (F1), subcategory 'Help'", 20 },
	{ "Want to know which maps you haven't yet beaten? Simply type /mapsleft", 30 },
	{ "Have you set a lot of #1 times? If you want to see them in a nice list, type /mywr", 40 },
	{ "Can you just not get the hang of one part? The practice mode in combination with /cp is ideal!", 30 },
	{ "Can't see the map because there's players all over your screen? /hide is the solution!", 20 },
	{ "Are you minimalistic or do you want as little distractions as possible? Try our 'Simple HUD feature' on the Main Menu (F1)!", 30 },
	{ "Do you get distracted by quickly changing milliseconds? You can lower the decimal count on the Main Menu (F1)", 20 },
	{ "Is someone making annoying jokes you don't like with no admin on? You can easily mute them locally via the scoreboard", 30 },
	{ "Can't beat the map? Sit back and relax for a while in spectator mode (accessible via F2 or /spec)", 20 },
	{ "Do you want to know how what time a specific player has at this moment? Left click their name on the scoreboard and find out!", 30 },
	{ "Want to see how amazing you look in your dull default outfit? We have a thirdperson mode for that! (F3 or /thirdperson)", 30 },
	{ "Do you have loose fingers and can't hold your space bar? Need someone to hold it for you? Look no further and type /space", 30 },
	{ "Are you new to " .. (Core.Config.IsSurf and "Skill Surf? You can watch a helpful tutorial" or "Bunny Hop? You can watch 3 in-depth tutorials with varying difficulty") .. " by typing /tutorial", 20 },
	{ "Do you enjoy watching replays of good runs? We upload them in 60 FPS on /youtube", 30 },
	{ "Want to see our latest changes? Type /changes to view the full change log thread", 20 }
}


--[[
	Description: Loads the important administrator data
--]]
local Prepare = SQLPrepare
function Core.LoadAdminPanel()
	Prepare(
		"SELECT szSteam, nLevel FROM game_admins ORDER BY nLevel DESC"
	)( function( data, varArg )
		Secure.Levels = { [Admin.OperatorID] = Admin.Level.Owner }
		
		if Core.Assert( data, "szSteam" ) then
			for _,item in pairs( data ) do
				Secure.Levels[ item["szSteam"] ] = item["nLevel"]
			end
		end
		
		if timer.Exists( "NotificationTick" ) then
			timer.Remove( "NotificationTick" )
		end
		
		timer.Create( "NotificationTick", Notifications.Delay, 0, Admin.NotificationTick )
		
		for _,p in pairs( player.GetHumans() ) do
			p:CheckAdminStatus()
		end
		
		Admin.Loaded = true
		
		Core.PrintC( "[Startup] Module 'admin' initialized" )
	end )
end

--[[
	Description: Gets the access level of a player
--]]
function Admin.GetAccess( ply )
	return Secure.Levels[ ply.UID ] or Admin.Level.None
end
Core.GetAdminAccess = Admin.GetAccess

--[[
	Description: Checks if a player can access a certain level
--]]
function Admin.CanAccess( ply, required, szType )
	return Admin.GetAccess( ply ) >= (szType and Admin.Level[ szType ] or required)
end
Core.HasAdminAccess = Admin.CanAccess

--[[
	Description: Gets info from the stored data and compares access levels
--]]
function Admin.CanAccessID( ply, id, bypass )
	local l
	
	for _,data in pairs( Secure.Setup ) do
		if data[ 1 ] == id then
			l = data[ 3 ]
			break
		end
	end

	if bypass then
		return ply.ConsoleOperator or id > 50
	end
	
	if not l then
		if bypass then
			return true
		end
		
		return false
	end
	
	return Admin.CanAccess( ply, l )
end

--[[
	Description: Checks if the admin in question is superior to admin b
--]]
function Admin.IsHigherThan( a, b, eq, by )
	if not by and (not IsValid( a ) or not IsValid( b )) then return false end
	local ac, bc = Admin.GetAccess( a ), Admin.GetAccess( b )
	return eq and ac >= bc or ac > bc
end

--[[
	Description: Gets the name of the access level
--]]
function Admin.GetAccessName( nID )
	for name,id in pairs( Admin.Level ) do
		if id == nID then
			return name
		end
	end
	
	return "None"
end
Core.GetAccessName = Admin.GetAccessName

--[[
	Description: Sets the networked access level
--]]
function Admin.SetAccessIcon( ply, nLevel )
	if Admin.Icons[ nLevel ] then
		ply:VarNet( "Set", "Access", Admin.Icons[ nLevel ], true )
	elseif ply:VarNet( "Get", "Access" ) then
		ply:VarNet( "Set", "Access", 0, true )
	end
end

--[[
	Description: Checks the admin status of the player and grants some nice goodies if necessary
--]]
function PLAYER:CheckAdminStatus()
	local nAccess = Admin.GetAccess( self )
	if nAccess >= Admin.Level.Base then
		if not Secure.CommunityIDs[ self.UID ] then
			Admin.LoadRank[ #Admin.LoadRank + 1 ] = { Player = self, Access = nAccess }
		elseif self.IsRank then
			Admin.LoadRank[ #Admin.LoadRank + 1 ] = { Player = self, Type = 1, Access = Secure.Levels[ self.UID ] or Admin.Level.Moderator }
		end
	elseif self.IsRank then
		if Admin.CommunityRanks[ self:IsRank() ] then
			Admin.LoadRank[ #Admin.LoadRank + 1 ] = { Player = self, Type = 1, Access = Admin.CommunityRanks[ self:IsRank() ] or Admin.Level.Moderator }
		else
			Admin.LoadRank[ #Admin.LoadRank + 1 ] = { Player = self, Type = 2, Ticks = 0 }
		end
	elseif self:IsSuperAdmin() then
		Admin.LoadRank[ #Admin.LoadRank + 1 ] = { Player = self, Access = Admin.Level.Owner }
	end
	
	if timer.Exists( "NotificationTick" ) then
		timer.Simple( 5, Admin.NotificationTick )
	end
	
	Core.PrintC( "[Load] Checking admin status of " .. self:Name() .. ", base access of " .. nAccess )
end

--[[
	Description: Sends a message to the master server which then saves it in the database
--]]
function Admin.AddLog( szText, szSteam, szAdmin )
	Prepare(
		"INSERT INTO game_logs (szData, szDate, szAdminSteam, szAdminName) VALUES ({0}, {1}, {2}, {3})",
		{ szText, os.date( "%Y-%m-%d %H:%M:%S", os.time() ), szSteam, szAdmin }
	)( SQLVoid )
end
Core.AddAdminLog = Admin.AddLog

--[[
	Description: Creates a pop-up request for usage on the client
--]]
function Admin.GenerateRequest( szCaption, szTitle, szDefault, nReturn )
	return { Caption = szCaption, Title = szTitle, Default = szDefault, Return = nReturn }
end

--[[
	Description: Returns the custom functions on a setup table item
--]]
function Admin.GetSetupTable( id )
	for i = 1, #Secure.Setup do
		if Secure.Setup[ i ][ 1 ] == id then
			return Secure.Setup[ i ][ 4 ][ 4 ], Secure.Setup[ i ][ 4 ][ 5 ]
		end
	end
end

--[[
	Description: Changes the function and description of a setup item
--]]
function Admin.SetSetupTable( id, szTitle, szAuth, fIn, fOut )
	for i = 1, #Secure.Setup do
		if Secure.Setup[ i ][ 1 ] == id then
			Secure.Setup[ i ][ 2 ] = szTitle
			Secure.Setup[ i ][ 3 ] = Admin.Level[ szAuth ]
			Secure.Setup[ i ][ 4 ][ 4 ] = fIn
			Secure.Setup[ i ][ 4 ][ 5 ] = fOut
		end
	end
end
Core.SetAdminItem = Admin.SetSetupTable

--[[
	Description: Attempts to find a player by their Steam ID
--]]
function Admin.FindPlayer( szUID )
	for _,p in pairs( player.GetHumans() ) do
		if tostring( p.UID ) == tostring( szUID ) then
			return p
		end
	end
end

--[[
	Description: The notification ticker to send out new messages every now and then
--]]
function Admin.NotificationTick()
	for pos,data in pairs( Admin.LoadRank ) do
		local ply = data.Player
		if IsValid( ply ) then
			if ply.IsFullyAuthenticated and not ply:IsFullyAuthenticated() then
				continue
			end
			
			if data.Type then
				if data.Type == 2 then
					if Admin.CommunityRanks[ ply:IsRank() ] then
						data.Access = Admin.CommunityRanks[ ply:IsRank() ]
						
						ply:SetPlayerColor( Vector( 0, 0.5, 0 ) )
						
						Secure.CommunityIDs[ ply.UID ] = Admin.CommunityNames[ data.Access ] or "Admin"
						Secure.Levels[ ply.UID ] = data.Access
						
						Admin.SetAccessIcon( ply, data.Access )
						Admin.GetJoinMessage( ply, Secure.CommunityIDs[ ply.UID ] )
					elseif data.Ticks < 4 then
						data.Ticks = data.Ticks + 1
						continue
					end
				elseif data.Type == 1 then
					ply:SetPlayerColor( Vector( 0, 0.5, 0 ) )
					
					Secure.CommunityIDs[ ply.UID ] = Admin.CommunityNames[ data.Access ] or "Admin"
					Secure.Levels[ ply.UID ] = data.Access
					
					Admin.SetAccessIcon( ply, data.Access )
					Admin.GetJoinMessage( ply, Secure.CommunityIDs[ ply.UID ] )
				end
			else
				if ply:GetUserGroup() == "user" then
					ply:SetUserGroup( "admin" )
				end
				
				ply:SetPlayerColor( Vector( 0.5, 0, 0.5 ) )
				
				Admin.SetAccessIcon( ply, data.Access )
				Admin.GetJoinMessage( ply, Admin.LevelNames[ data.Access ] )
			end
		end
		
		table.remove( Admin.LoadRank, pos )
	end
	
	if Notifications.Last and SysTime() - Notifications.Last < Notifications.Interval then return end
	
	local tab = Notifications.Items
	local available = {}
	
	for i = 1, #tab do
		if not tab[ i ].Shown then
			available[ #available + 1 ] = i
		end
	end

	local selected
	local item
	
	if #available == 0 then
		table.SortByMember( tab, "Shown", true )
		
		for i = 1, #tab do
			if math.random( 1, 3 ) == 2 then
				selected = i
				item = tab[ selected ]
				
				break
			end
		end
	else
		selected = math.random( 1, #available )
		item = tab[ available[ selected ] ]
	end
	
	if not item then return end

	Notifications.Last = SysTime()
	item.Shown = SysTime()

	Core.Print( nil, Core.Config.ServerName, item[ 1 ] )
end

--[[
	Description: Fetches all the players and sorts them nicely
--]]
function Admin.GetPlayerList()
	local tab = {}
	
	for _,p in pairs( player.GetHumans() ) do
		local nAccess = Admin.GetAccess( p )
		local szAccess = nAccess > 0 and Admin.LevelNames[ nAccess ] or "Player"
		
		tab[ #tab + 1 ] = { p:Name(), p.UID, szAccess, nAccess }
	end
	
	table.sort( tab, function( a, b )
		if a[ 4 ] > b[ 4 ] then return true end
		if a[ 4 ] < b[ 4 ] then return false end
		
		return a[ 1 ] < b[ 1 ]
	end )
	
	for i = 1, #tab do
		tab[ i ][ 4 ] = nil
	end
	
	return tab
end

--[[
	Description: Gets all the online admins
--]]
function Admin.GetOnlineAdmins()
	local tab = {}
	
	for _,p in pairs( player.GetHumans() ) do
		local nAccess = Admin.GetAccess( p )
		if nAccess >= Admin.Level.Admin then
			tab[ #tab + 1 ] = p
		end
	end
	
	return tab
end

--[[
	Description: Gets the joining message for the player, along with the amount of reports
--]]
function Admin.GetJoinMessage( ply, access )
	Prepare(
		"SELECT COUNT(nID) AS nCount FROM game_reports WHERE szHandled IS NULL"
	)( function( data, varArg )
		local message = Core.Text( "AdminJoinMessage", ply:Name(), access )
		if Core.Assert( data, "nCount" ) then
			local count = tonumber( data[ 1 ]["nCount"] ) or 0
			if count > 0 then
				message = message .. "\nThere " .. (count == 1 and "is " or "are ") .. count .. " unhandled report(s)!"
			end
		end
		
		Core.Prepare( "Global/Notify", { "Admin", Core.Text( "AdminJoinHeader" ), "report_user", 8, message } ):Send( ply )
	end )
end

--[[
	Description: Reports a player and notifies any online admins
--]]
local AdminResponse = {}
function Core.ReportPlayer( args )
	local nTime = os.time()
	
	if args.TypeID >= 50 then
		args.Comment = args.Comment .. " (" .. game.GetMap() .. ")"
	end
	
	Prepare(
		"INSERT INTO game_reports (nType, szTarget, szComment, nDate, szReporter, szHandled, szEvidence) VALUES ({0}, " .. (args.Target and "{1}" or "NULL") .. ", {2}, {3}, {4}, NULL, NULL)",
		{ args.TypeID, args.Target or "", args.Comment, nTime, args.ReporterSteam }
	)( function( data, varArg )
		if IsValid( varArg ) then
			Core.Print( varArg, "Admin", Core.Text( "AdminReportReceived" ) )
		end
		
		Core.Prepare( "Global/Notify", { "Admin", Core.Text( "AdminReportMessage" ), "report_user", 8, args.Text } ):Send( Admin.GetOnlineAdmins() )
	end, args.Submitter )
	
	if args.TypeID >= 50 and args.Target then
		local target = player.GetBySteamID( args.Target )
		if IsValid( target ) then
			Core.Send( target, "Client/AutoDemo", { "info", true } )
			AdminResponse[ target ] = nTime
		end
	end
end

--[[
	Description: Receives the report data from a player
--]]
local AdminCache, TransferChunk, TransferPos, TransferData = {}, 4096
function Admin.ReceiveReportData( l, ply )	
	local id = net.ReadUInt( 2 )
	if id == 0 then
		AdminCache[ ply ] = { net.ReadUInt( 32 ), net.ReadString(), "" }
		
		net.Start( "BinaryTransfer" )
		net.WriteString( "Part" )
		net.WriteUInt( 1, 32 )
		net.Send( ply )
	elseif id == 1 then
		if AdminCache[ ply ] then
			local at = net.ReadUInt( 32 )
			local length = net.ReadUInt( 32 )
			
			AdminCache[ ply ][ 3 ] = AdminCache[ ply ][ 3 ] .. net.ReadData( length )
			
			if at >= AdminCache[ ply ][ 1 ] then
				local str = AdminCache[ ply ][ 2 ]
				local bin = AdminCache[ ply ][ 3 ]
				local json = util.JSONToTable( str or "" )
				
				if json and bin and #bin > 0 then
					if type( json ) == "table" and json.Map then
						local formattime = os.date( "%Y_%m_%d_%H_%M_%S", os.time() )
						local name = "demos/demo_" .. formattime .. "_" .. ply:Name():gsub( "%W", "" ):lower()
						
						file.CreateDir( "demos" )
						file.Write( name .. ".dat", bin )
						file.Write( name .. ".txt", str )
						
						if AdminResponse[ ply ] then
							Prepare(
								"UPDATE game_reports SET szEvidence = {0} WHERE nDate = {1} AND szTarget = {2}",
								{ string.sub( name, 7 ), AdminResponse[ ply ], ply.UID }
							)( function( data, varArg )
								Core.Prepare( "Global/Notify", { "Admin", Core.Text( "AdminReportEvidence" ), "report_user", 8, "An automated demo has been recorded on the player in suspicion (" .. ply:Name() .. ") and has been transferred to the server for reviewing. The name of the demo is supplied in the logs of reports." } ):Send( Admin.GetOnlineAdmins() )
							end )
							
							AdminResponse[ ply ] = nil
						end
					end
				end
				
				AdminCache[ ply ] = nil
			else
				net.Start( "BinaryTransfer" )
				net.WriteString( "Part" )
				net.WriteUInt( at + 1, 32 )
				net.Send( ply )
			end
		end
	elseif id == 2 then
		if TransferData then
			local pos = math.Clamp( TransferPos + TransferChunk, 1, #TransferData )
			local data = string.sub( TransferData, TransferPos, pos )
			local length = #data
			
			if pos - TransferPos < 1 or length < 1 then
				length = 0
			end
			
			TransferPos = pos + 1
			
			net.Start( "BinaryTransfer" )
			net.WriteString( "Demo" )
			net.WriteUInt( length, 32 )
			net.WriteData( data, length )
			net.Send( ply )
		end
	end
end
net.Receive( "BinaryTransfer", Admin.ReceiveReportData )


--[[
	Description: Creates the admin panel window on the player
--]]
function Admin.CreateWindow( ply )
	local access = Admin.GetAccess( ply )
	local tab = {
		Title = ply:Name() .. "'s Admin Panel",
		Width = 825,
		Height = 480,
	}
	
	if access < Admin.Level.Elevated then return end
	if access >= Admin.Level.Super then tab.Width = tab.Width + 105 end
	
	tab[ #tab + 1 ] = { Type = "DListView", Label = "PlayerList", Modifications = { ["SetMultiSelect"] = { false }, ["SetPos"] = { 20, 66 }, ["SetSize"] = { 360, 361 }, ["Sequence"] = { { "AddColumn", { "Player" } }, { "AddColumn", { "Steam ID" }, "SetFixedWidth", 120 }, { "AddColumn", { "Authority" } } } } }
	tab[ #tab + 1 ] = { Type = "DTextEntry", Label = "PlayerSteam", Modifications = { 20, 437, 360, 25, "Steam ID" } }
	
	local y = 87
	for i,item in pairs( Secure.Setup ) do
		if not item[ 3 ] or not item[ 4 ] then continue end
		if access >= item[ 3 ] then
			local data = item[ 4 ]
			local x = 390 + (data[ 1 ] - 1) * 105
			
			if i != 1 and data[ 1 ] == 1 then
				y = y + 35 + (item[ 5 ] and 35 or 0)
			end
			
			local mod = {
				["SetPos"] = { x, y },
				["SetSize"] = { 100, 25 },
				["SetText"] = { item[ 2 ] }
			}
			
			if item[ 5 ] then
				tab[ #tab + 1 ] = { Type = "DLabel", Modifications = { ["SetPos"] = { x, y - 20 }, ["SetFont"] = { "BottomHUDTiny" }, ["SetTextColor"] = { Color( 85, 85, 85 ) }, ["SetText"] = { item[ 5 ] }, ["Sequence"] = { { "SizeToContents", {} } } } }
			end
			
			tab[ #tab + 1 ] = { Type = "DButton", Identifier = item[ 1 ], Require = data[ 3 ], Modifications = mod }
		end
	end
	
	local attach
	if Admin.LastAccess[ ply ] != access then
		Admin.LastAccess[ ply ] = access
		attach = tab
	end
	
	Core.Send( ply, "Global/Admin", { "GUI", "Admin", attach, Admin.GetPlayerList(), { "PlayerSteam", "Steam ID" } } )
end

--[[
	Description: Creates a report panel on the player
--]]
function Admin.CreateReport( ply )
	local tabQuery = {
		Caption = "What kind of issue would you like to report?\n(Note: For anything that is not on this list, please refer to the forums)",
		Title = "Select report type"
	}
	
	for i = 1, #Admin.Reports do
		local item = Admin.Reports[ i ]
		if item[ 1 ] >= 50 then continue end
		tabQuery[ #tabQuery + 1 ] = { item[ 2 ], { 60, item[ 1 ] } }
	end
	
	tabQuery[ #tabQuery + 1 ] = { "[[Close", {} }
	
	Core.Send( ply, "Global/Admin", { "Query", tabQuery } )
end

--[[
	Description: Creates the logs window on the player
--]]
function Admin.CreateLogs( ply, access, update )
	if not access then return end
	
	-- Setup base variables
	local tab = {
		Title = "Server Change Logs",
		Width = 720,
		Height = 475,
	}
	
	-- Create the table
	local list = {}
	tab[ #tab + 1 ] = { Type = "DListView", Label = "PlayerList", Modifications = { ["SetMultiSelect"] = { false }, ["SetPos"] = { 20, 66 }, ["SetSize"] = { 680, 387 }, ["Sequence"] = { { "AddColumn", { "Data" } }, { "AddColumn", { "Admin" }, "SetFixedWidth", 120 }, { "AddColumn", { "Date" }, "SetFixedWidth", 130 } } } }
	
	Prepare(
		"SELECT szData, szDate, szAdminName FROM game_logs ORDER BY nID DESC LIMIT " .. (update or 0) .. ", 50",
		{ UseOptions = true, RawFormat = true }
	)( function( data, varArg )
		if Core.Assert( data, "szData" ) then
			for j = 1, #data do
				list[ j ] = { data[ j ]["szData"], data[ j ]["szAdminName"], data[ j ]["szDate"] }
			end
		end
		
		if not update then
			Core.Send( ply, "Global/Admin", { "GUI", "Admin", tab, list, { "Invalid" } } )
		else
			Core.Send( ply, "Global/Admin", { "Update", list } )
		end
	end )
end

--[[
	Description: Creates the reports window on the player
--]]
function Admin.CreateReports( ply, access, update )
	if not access then return end
	
	-- Setup base variables
	local tab = {
		Title = "Server Reports",
		Width = 960,
		Height = 475,
	}
	
	-- Quick access
	local quick = {}
	for _,v in pairs( Admin.Reports ) do
		quick[ v[ 1 ] ] = v[ 2 ]
	end
	
	-- Create the table
	local list = {}
	tab[ #tab + 1 ] = { Type = "DListView", Label = "PlayerList", Modifications = { ["SetMultiSelect"] = { false }, ["SetPos"] = { 20, 66 }, ["SetSize"] = { 920, 387 }, ["Sequence"] = { { "AddColumn", { "ID" }, "SetFixedWidth", 30 }, { "AddColumn", { "Comment" }, "SetMinWidth", 480 }, { "AddColumn", { "Type" }, "SetWidth", 170 }, { "AddColumn", { "Date" }, "SetWidth", 120 }, { "AddColumn", { "Poster" }, "SetWidth", 130 } } } }
	
	-- Add additional buttons
	if Admin.GetAccess( ply ) >= Admin.Level.Developer then
		tab.Height = tab.Height + 32
		
		local data = Secure.Setup.Evidence
		tab[ #tab + 1 ] = { Type = "DButton", Identifier = data[ 1 ], Modifications = { ["SetPos"] = { 20, 463 }, ["SetSize"] = { 100, 25 }, ["SetText"] = { data[ 2 ] } } }
		
		data = Secure.Setup.Records
		tab[ #tab + 1 ] = { Type = "DButton", Identifier = data[ 1 ], Modifications = { ["SetPos"] = { 130, 463 }, ["SetSize"] = { 100, 25 }, ["SetText"] = { data[ 2 ] } } }
		
		data = Secure.Setup.Handled
		tab[ #tab + 1 ] = { Type = "DButton", Identifier = data[ 1 ], Modifications = { ["SetPos"] = { 240, 463 }, ["SetSize"] = { 100, 25 }, ["SetText"] = { data[ 2 ] } } }
		tab[ #tab + 1 ] = { Type = "DButton", Identifier = data[ 1 ] + 1, Modifications = { ["SetPos"] = { 350, 463 }, ["SetSize"] = { 100, 25 }, ["SetText"] = { "View name" } } }
		tab[ #tab + 1 ] = { Type = "DButton", Identifier = data[ 1 ] + 2, Modifications = { ["SetPos"] = { 460, 463 }, ["SetSize"] = { 100, 25 }, ["SetText"] = { "Load more" } } }
	end
	
	Prepare(
		"SELECT nID, nType, szTarget, szComment, nDate, szReporter, szHandled, szEvidence FROM game_reports ORDER BY szHandled ASC, nID DESC LIMIT " .. (update or 0) .. ", 50",
		{ UseOptions = true, RawFormat = true }
	)( function( data, varArg )
		local makeNum, makeNull = tonumber, Core.Null
		if Core.Assert( data, "nType" ) then
			for j = 1, #data do
				local handle = makeNull( data[ j ]["szHandled"], "" )
				local demo = makeNull( data[ j ]["szEvidence"], "" )
				local target = makeNull( data[ j ]["szTarget"], "" )
				
				if handle != "" then data[ j ]["szComment"] = "[Handled by " .. handle .. "] " .. data[ j ]["szComment"] end
				if target != "" then data[ j ]["szComment"] = data[ j ]["szComment"] .. " (" .. target .. ")" end
				if demo != "" then data[ j ]["szComment"] = data[ j ]["szComment"] .. " (Includes evidence)" end
				
				list[ j ] = { makeNum( data[ j ]["nID"] ), data[ j ]["szComment"], quick[ makeNum( data[ j ]["nType"] ) ] or "Unknown", os.date( "%Y-%m-%d %H:%M:%S", makeNum( data[ j ]["nDate"] ) or 0 ), data[ j ]["szReporter"] }
			end
		end
		
		if not update then
			Core.Send( ply, "Global/Admin", { "GUI", "Admin", tab, list, { "Invalid" } } )
		else
			Core.Send( ply, "Global/Admin", { "Update", list } )
		end
	end )
end


-- Calls when a button is pressed
local function HandleButton( ply, args )
	local ID, Steam = tonumber( args[ 2 ] ), tostring( args[ 3 ] )
	if not Admin.CanAccessID( ply, ID ) then
		return Core.Print( ply, "Admin", Core.Text( "AdminFunctionalityAccess" ) )
	end
	
	-- Set zone
	if ID == 1 then
		local editor = Core.GetZoneEditor()
		if editor:CheckSet( ply, true, ply.ZoneExtra ) then return end
		if Steam == "Extra" then ply.ZoneExtra = true end
		
		local tabQuery = {
			Caption = "What kind of zone do you want to set?\n(Note: When you select one, you will immediately start placing it!)",
			Title = "Select zone type"
		}

		for name,id in pairs( Core.GetZoneID() ) do
			tabQuery[ #tabQuery + 1 ] = { name, { ID, id } }
		end
		
		tabQuery[ #tabQuery + 1 ] = { "[[[[Close", {} }
		
		if not ply.ZoneExtra then
			tabQuery[ #tabQuery + 1 ] = { "[[Add Additional", { ID, -10 } }
		else
			tabQuery[ #tabQuery + 1 ] = { "[[Overwrite existing", { ID, -20 } }
		end
		
		if ply.ZoneNoSnap then
			tabQuery[ #tabQuery + 1 ] = { "[[Enable snapping", { ID, -30 } }
		else
			tabQuery[ #tabQuery + 1 ] = { "[[Disable snapping", { ID, -40 } }
		end
		
		Core.Send( ply, "Global/Admin", { "Query", tabQuery } )
	
	-- Cancel zone creation
	elseif ID == 2 then
		local editor = Core.GetZoneEditor()
		if editor:CheckSet( ply ) then
			editor:CancelSet( ply, true )
		else
			Core.Print( ply, "Admin", Core.Text( "ZoneNoEdit" ) )
		end
	
	-- Change map multiplier
	elseif ID == 3 then
		local tabRequest = Admin.GenerateRequest( "Enter the map multiplier. This is the weight or points value of the map (Default is 1)", "Map multiplier", tostring( Core.GetMapVariable( "Multiplier" ) ), ID )
		Core.Send( ply, "Global/Admin", { "Request", tabRequest } )
	
	-- Set data ID
	elseif ID == 4 then
		local tabRequest = Admin.GenerateRequest( "Enter the embedded data ID. This has to be a positive number value\nIf you want to change the embedded ID, enter [EntIndex]:[ID]", "Zone data ID", ply.AdminZoneID and tostring( ply.AdminZoneID ) or "", ID )
		Core.Send( ply, "Global/Admin", { "Request", tabRequest } )
	
	-- Force change map
	elseif ID == 5 then
		local tabRequest = Admin.GenerateRequest( "Enter the map to change to (Default is the current map - Note: Changing to the same map might cause glitches)", "Change map", game.GetMap(), ID )
		Core.Send( ply, "Global/Admin", { "Request", tabRequest } )
	
	-- Reload zones
	elseif ID == 6 then
		Core.ReloadZones()
		Core.Print( ply, "Admin", Core.Text( "AdminOperationComplete" ) )
	
	-- Set authority
	elseif ID == 7 then
		local target = Admin.FindPlayer( Steam )
		
		if IsValid( target ) then
			ply.AdminTarget = target.UID
			
			local tabQuery = {
				Caption = "What access level do you want to set the player to?\nNote: This is local and only within the gamemode",
				Title = "Select zone type"
			}
			
			for name,id in pairs( Admin.Level ) do
				tabQuery[ #tabQuery + 1 ] = { name, { ID, id } }
			end
			
			tabQuery[ #tabQuery + 1 ] = { "[[Close", {} }

			Core.Send( ply, "Global/Admin", { "Query", tabQuery } )
		else
			Core.Print( ply, "Admin", Core.Text( "AdminNoValidPlayer", Steam ) )
		end
	
	-- Fully removes all admin access from the specified Steam ID
	elseif ID == 8 then
		Prepare(
			"DELETE FROM game_admins WHERE szSteam = {0}",
			{ Steam }
		)( function( data, varArg )
			if data then
				if IsValid( varArg ) then
					Admin.SetAccessIcon( varArg )
					Secure.Levels[ varArg.UID ] = nil
				end
				
				Core.Print( ply, "Admin", Core.Text( "AdminOperationComplete" ) )
				Admin.AddLog( "Removed admin access from " .. Steam, ply.UID, ply:Name() )
			else
				Core.Print( ply, "Admin", Core.Text( "AdminErrorCode", "Unknown" ) )
			end
		end, Admin.FindPlayer( Steam ) )
	
	-- Set zone size
	elseif ID == 9 then
		local tabQuery = {
			Caption = "Which zone do you want to edit?",
			Title = "Select zone"
		}

		local zones = Core.GetZoneEntities()
		for _,zone in pairs( zones ) do
			if IsValid( zone ) then
				tabQuery[ #tabQuery + 1 ] = { Core.GetZoneName( zone.zonetype ) .. " (" .. zone:EntIndex() .. ")" .. Core.GetZoneInfo( zone ), { ID, zone:EntIndex() } }
			end
		end
		
		tabQuery[ #tabQuery + 1 ] = { "[[Close", {} }
		
		Core.Send( ply, "Global/Admin", { "Query", tabQuery } )
	
	-- Remove zone
	elseif ID == 10 then
		local tabQuery = {
			Caption = "Select the zone that you want to remove.\n(Note: The zone will be removed immediately!)\n(Note: The higher the number, the later it was added)",
			Title = "Remove zone"
		}
		
		local zones = Core.GetZoneEntities()
		for _,zone in pairs( zones ) do
			if IsValid( zone ) then				
				tabQuery[ #tabQuery + 1 ] = { Core.GetZoneName( zone.zonetype ) .. " (" .. zone:EntIndex() .. ")" .. Core.GetZoneInfo( zone ), { ID, zone:EntIndex() } }
			end
		end
		
		tabQuery[ #tabQuery + 1 ] = { "[[Close", {} }
		
		Core.Send( ply, "Global/Admin", { "Query", tabQuery } )
	
	-- Set map options
	elseif ID == 11 then
		local tabQuery = {
			Caption = "Please click map required options. Select values that you want to add. Once you're done, press Save (Default is none)",
			Title = "Map options"
		}

		local opt = Core.GetMapVariable( "Options" )
		for name,zone in pairs( Core.GetMapVariable( "OptionList" ) ) do
			local szAdd = bit.band( opt, zone ) > 0 and " (On)" or " (Off)"
			tabQuery[ #tabQuery + 1 ] = { name .. szAdd, { ID, zone } }
		end
		
		tabQuery[ #tabQuery + 1 ] = { "Save", { ID, -1 } }
		tabQuery[ #tabQuery + 1 ] = { "Cancel", {} }
		
		Core.Send( ply, "Global/Admin", { "Query", tabQuery } )
	
	-- Move to spectator
	elseif ID == 12 then
		local target = Admin.FindPlayer( Steam )
		
		if IsValid( target ) then
			if Admin.IsHigherThan( target, ply, true ) then
				return Core.Print( ply, "Admin", Core.Text( "AdminHierarchy" ) )
			end
			
			if not target.Spectating then
				concommand.Run( target, "spectate", "bypass", "" )
				Core.Print( ply, "Admin", Core.Text( "AdminSpectatorMove", target:Name() ) )
				Admin.AddLog( "Moved " .. target:Name() .. " to spectator", ply.UID, ply:Name() )
			else
				Core.Print( ply, "Admin", Core.Text( "AdminSpectatorAlready" ) )
			end
		else
			Core.Print( ply, "Admin", Core.Text( "AdminNoValidPlayer", Steam ) )
		end
	
	-- Import / export a map
	elseif ID == 13 then
		local tabQuery = {
			Caption = "Please select whether you want to import or export a map",
			Title = "Import / Export"
		}

		tabQuery[ #tabQuery + 1 ] = { "Import", { ID, 1 } }
		tabQuery[ #tabQuery + 1 ] = { "Export", { ID, 2 } }
		tabQuery[ #tabQuery + 1 ] = { "Cancel", {} }
		
		Core.Send( ply, "Global/Admin", { "Query", tabQuery } )
	
	-- Logs
	elseif ID == 14 then
		Admin.CreateLogs( ply, Admin.CanAccessID( ply, ID ) )
	
	-- Reports
	elseif ID == 15 then
		Admin.CreateReports( ply, Admin.CanAccessID( ply, ID ) )
	
	-- Force a player to RTV
	elseif ID == 16 then
		local target = Admin.FindPlayer( Steam )
		
		if IsValid( target ) then
			if Admin.IsHigherThan( target, ply, true ) then
				return Core.Print( ply, "Admin", Core.Text( "AdminHierarchy" ) )
			end
			
			if not target.Rocked then
				target:RTV( "Vote" )
				Core.Print( ply, "Admin", Core.Text( "AdminForceRock", target:Name() ) )
			else
				Core.Print( ply, "Admin", Core.Text( "AdminForceRockAlready" ) )
			end
		else
			Core.Print( ply, "Admin", Core.Text( "AdminNoValidPlayer", Steam ) )
		end
	
	-- Remove times toggle
	elseif ID == 17 then
		if not ply.RemovingTimes then
			ply.RemovingTimes = true
			Core.Print( ply, "Admin", Core.Text( "AdminTimeEditStart" ) )
		else
			ply.RemovingTimes = nil
			Core.Print( ply, "Admin", Core.Text( "AdminTimeEditEnd" ) )
		end
	
	-- Cancel map vote
	elseif ID == 20 then
		local to = Core.ChangeVoteCancel()
		Core.Print( ply, "Admin", Core.Text( "AdminMapVoteCancel", not to and "not " or "" ) )
		Admin.AddLog( "Changed map vote to " .. (not to and "not " or "") .. "be cancelled", ply.UID, ply:Name() )
	
	-- Set bonus multiplier
	elseif ID == 21 then
		local cb = Core.GetMapVariable( "Bonus" )
		if type( cb ) == "table" then
			cb = string.Implode( " ", cb )
		end
		
		local tabRequest = Admin.GenerateRequest( "Enter the bonus multiplier. This is the weight or points value of the bonus (Default is 1)\nSpecials: Separate multiple with spaces, negate with '0:' in front. Example: 5 1 10 0:100", "Bonus multiplier", tostring( cb ), ID )
		Core.Send( ply, "Global/Admin", { "Request", tabRequest } )
	
	-- Remove a map
	elseif ID == 22 then
		local tabRequest = Admin.GenerateRequest( "Enter the name of the map to be removed.\nWARNING: This will remove all saved data of the map, including times!", "Completely remove map", "", ID )
		Core.Send( ply, "Global/Admin", { "Request", tabRequest } )
	
	-- Strip weapons
	elseif ID == 23 then
		local target = Admin.FindPlayer( Steam )
		
		if IsValid( target ) then
			if Admin.IsHigherThan( target, ply, true ) then
				return Core.Print( ply, "Admin", Core.Text( "AdminHierarchy" ) )
			end
			
			target.WeaponStripped = not target.WeaponStripped
			target:StripWeapons()
			target:StripAmmo()
	
			local szPickup = target.WeaponStripped and "They can no longer pick anything up" or "They can pick weapons up again"
			Core.Print( ply, "Admin", Core.Text( "AdminWeaponStrip", target:Name(), szPickup ) )
			Admin.AddLog( "Stripped " .. target:Name() .. " of weapons", ply.UID, ply:Name() )
		else
			Core.Print( ply, "Admin", Core.Text( "AdminNoValidPlayer", Steam ) )
		end
	
	-- Reload admins
	elseif ID == 24 then
		Core.LoadAdminPanel()
		Core.Print( ply, "Admin", Core.Text( "AdminPanelReloaded" ) )
		Admin.AddLog( "Reloaded all admins", ply.UID, ply:Name() )
	
	-- Teleport to a zone
	elseif ID == 25 then
		local tabQuery = {
			Caption = "Which zone do you want to teleport to?",
			Title = "Select zone"
		}

		local zones = Core.GetZoneEntities()
		for _,zone in pairs( zones ) do
			if IsValid( zone ) then
				tabQuery[ #tabQuery + 1 ] = { Core.GetZoneName( zone.zonetype ) .. " (" .. zone:EntIndex() .. ")" .. Core.GetZoneInfo( zone ), { ID, zone:EntIndex() } }
			end
		end
		
		tabQuery[ #tabQuery + 1 ] = { "[[Close", {} }
		
		Core.Send( ply, "Global/Admin", { "Query", tabQuery } )
	
	-- Change RTV timer
	elseif ID == 26 then
		local tabRequest = Admin.GenerateRequest( "Enter the amount of minutes you want there to be left on the clock.", "Change RTV timeleft", "", ID )
		Core.Send( ply, "Global/Admin", { "Request", tabRequest } )
	
	-- Spectator incognito mode
	elseif ID == 27 then
		if ply.Spectating then
			return Core.Print( ply, "Admin", Core.Text( "AdminIncognitoWarning" ) )
		end
		
		ply.Incognito = not ply.Incognito
		Core.Print( ply, "Admin", Core.Text( "AdminIncognitoToggle", ply.Incognito and "enabled" or "disabled" ) )
		Admin.AddLog( (ply.Incognito and "Entered" or "Left") .. " incognito mode", ply.UID, ply:Name() )
	
	-- Remove all times on a style
	elseif ID == 28 then
		local tabRequest = Admin.GenerateRequest( "Enter the ID of the style of which all times are to be removed below\nNote: To remove times for ALL styles, use .0. as a style\nWARNING: This will remove all times permanently!", "Remove all times for mode", "No", ID )
		Core.Send( ply, "Global/Admin", { "Request", tabRequest } )
	
	-- Send a notification
	elseif ID == 29 then
		local tabRequest = Admin.GenerateRequest( "Enter the message to print on the screen\nNote: To send to an individual, use [SteamID]-Message", "Show admin notification", "", ID )
		Core.Send( ply, "Global/Admin", { "Request", tabRequest } )
	
	-- Teleport a player
	elseif ID == 30 then
		local target = Admin.FindPlayer( Steam )
		
		if IsValid( target ) then
			ply.AdminTarget = target.UID
			
			local tabRequest = Admin.GenerateRequest( "Enter the Steam ID of the target player (where the selected player will be teleported to).\nYou can also use a coordinate with or without comma's in this field!\nWARNING: This is possible on any style and will not stop their timer!", "Teleport player", "", ID )
			Core.Send( ply, "Global/Admin", { "Request", tabRequest } )
		else
			Core.Print( ply, "Admin", Core.Text( "AdminNoValidPlayer", Steam ) )
		end
	
	-- Free-move a zone
	elseif ID == 31 then
		local tabQuery = {
			Caption = "Which zone do you want to move?",
			Title = "Select zone"
		}

		local zones = Core.GetZoneEntities()
		for _,zone in pairs( zones ) do
			if IsValid( zone ) then
				tabQuery[ #tabQuery + 1 ] = { Core.GetZoneName( zone.zonetype ) .. " (" .. zone:EntIndex() .. ")" .. Core.GetZoneInfo( zone ), { ID, zone:EntIndex() } }
			end
		end
		
		tabQuery[ #tabQuery + 1 ] = { "[[Close", {} }
		
		Core.Send( ply, "Global/Admin", { "Query", tabQuery } )
	
	-- Incognito admin
	elseif ID == 32 then
		local now = ply:VarNet( "Get", "Access", 0 )
		if now > 0 then
			ply:VarNet( "Set", "Access", 0, true )
		else
			local nAccess = Admin.GetAccess( ply )
			if nAccess >= Admin.Level.Base then
				Admin.SetAccessIcon( ply, nAccess )
			end
		end
		
		Core.Print( ply, "Admin", Core.Text( "AdminIncognitoFull", now > 0 and "enabled" or "disabled" ) )
	
	-- Change tier or type (Surf only)
	elseif ID == 33 then
		if not Core.Config.IsSurf then
			return Core.Print( ply, "Admin", Core.Text( "AdminFunctionalitySurf" ) )
		end
		
		local tabQuery = {
			Caption = "Please select the type of setting you wish to change",
			Title = "Map Tier and Type"
		}

		tabQuery[ #tabQuery + 1 ] = { "Tier", { ID, 1 } }
		tabQuery[ #tabQuery + 1 ] = { "Type", { ID, 2 } }
		tabQuery[ #tabQuery + 1 ] = { "Cancel", {} }
		
		Core.Send( ply, "Global/Admin", { "Query", tabQuery } )
	
	-- Fully wipe a player
	elseif ID == 34 then
		local tabRequest = Admin.GenerateRequest( "Enter the Steam ID of the target player.\nWARNING: This is a NON-REVERSABLE process, be 100% sure!", "Wipe player", "", ID )
		Core.Send( ply, "Global/Admin", { "Request", tabRequest } )
	
	-- Silence game chat
	elseif ID == 36 then
		Core.Print( ply, "Admin", Core.Text( "AdminChatSilence", Core.ChatSilence and " no longer" or "" ) )
		RunConsoleCommand( "control", "silence" )
	
	-- Request evidence (via Reports window)
	elseif ID == 50 then
		local nID = tonumber( Steam ) or -1
		if nID < 0 then return end
		
		Prepare(
			"SELECT * FROM game_reports WHERE nID = {0}",
			{ nID }
		)( function( data, varArg )
			if Core.Assert( data, "nType" ) then
				local row = data[ 1 ]
				local evidence = Core.Null( row["szEvidence"], "" )
				
				if evidence != "" then
					local path = "demos/" .. evidence
					local json = file.Read( path .. ".txt", "DATA" )
					local data = file.Read( path .. ".dat", "DATA" )
					
					if not data or not json then
						return Core.Print( ply, "Admin", Core.Text( "AdminEvidenceNone" ) )
					end
					
					TransferData = data
					TransferPos = 1
					
					net.Start( "BinaryTransfer" )
					net.WriteString( "FullDemo" )
					net.WriteString( evidence )
					net.WriteString( json )
					net.WriteUInt( #TransferData, 32 )
					net.Send( ply )
					
					Core.Print( ply, "Admin", Core.Text( "AdminEvidenceStarted", evidence, Core.Config.BasePath .. "demos/" ) )
				else
					Core.Print( ply, "Admin", Core.Text( "AdminEvidenceNone" ) )
				end
			end
		end )
	
	-- Find related records linked to a ban
	elseif ID == 51 then
		local nID = tonumber( Steam ) or -1
		if nID < 0 then return end
		
		Prepare(
			"SELECT * FROM game_reports WHERE nID = {0}",
			{ nID }
		)( function( data, varArg )
			if Core.Assert( data, "nDate" ) then
				local row = data[ 1 ]
				local szTarget = Core.Null( row["szTarget"], "" )
				if szTarget == "" then
					return Core.Print( ply, "Admin", Core.Text( "AdminEvidenceNoRelated" ) )
				end
				
				local nDate = tonumber( row["nDate"] ) or 0
				local nMin, nMax = nDate - 5400, nDate + 5400
				
				Prepare(
					"SELECT * FROM game_times WHERE szUID = {0} AND nDate > {1} AND nDate < {2}",
					{ szTarget, nMin, nMax }
				)( function( data, varArg )
					local makeNum = tonumber
					if Core.Assert( data, "szMap" ) then
						local tab = {}
						for j = 1, #data do
							tab[ #tab + 1 ] = { nTime = makeNum( data[ j ]["nTime"] ), szUID = data[ j ]["szUID"], szPlayer = data[ j ]["szMap"] .. " (" .. Core.StyleName( makeNum( data[ j ]["nStyle"] ) ) .. ")", nPoints = makeNum( data[ j ]["nPoints"] ), nDate = makeNum( data[ j ]["nDate"] ), vData = data[ j ]["vData"] }
						end
						
						Core.Prepare( "GUI/Build", {
							ID = "Records",
							Title = "Related records",
							X = 500,
							Y = 400,
							Mouse = true,
							Blur = true,
							Data = { tab, #tab, -1 }
						} ):Send( ply )
					else
						Core.Print( ply, "Admin", Core.Text( "AdminEvidenceNoResults" ) )
					end
				end )
			end
		end )
	
	-- Mark a report as handled
	elseif ID == 52 then
		local nID = tonumber( Steam ) or -1
		if nID < 0 then return end
		
		Prepare(
			"SELECT * FROM game_reports WHERE nID = {0}",
			{ nID }
		)( function( data, varArg )
			if Core.Assert( data, "nType" ) then
				local row = data[ 1 ]
				local handled = Core.Null( row["szHandled"], "" )
				
				if handled != "" then
					Prepare(
						"UPDATE game_reports SET szHandled = NULL WHERE nID = {0}",
						{ nID }
					)( SQLVoid )
					
					Core.Print( ply, "Admin", Core.Text( "AdminEvidenceMarked", "Un-m" ) )
				else
					Prepare(
						"UPDATE game_reports SET szHandled = {0} WHERE nID = {1}",
						{ ply:Name(), nID }
					)( SQLVoid )
					
					Core.Print( ply, "Admin", Core.Text( "AdminEvidenceMarked", "M" ) )
				end
			end
		end )
	
	-- Load more logs or reports
	elseif ID == 54 then
		if args[ 3 ][ 2 ] then
			Admin.CreateReports( ply, Admin.CanAccessID( ply, ID ), tonumber( args[ 3 ][ 1 ] ) )
		else
			Admin.CreateLogs( ply, Admin.CanAccessID( ply, ID ), tonumber( args[ 3 ][ 1 ] ) )
		end
	
	-- Handled elsewhere
	elseif ID == 18 or ID == 19 or ID == 35 then
		local f = Admin.GetSetupTable( ID )
		f( ply, ID, Admin )
	end
end

-- Responses from Derma requests or Queries
local function HandleRequest( ply, args )
	local ID, Value = tonumber( args[ 2 ] ), args[ 3 ]
	if ID != 17 then
		Value = tostring( Value )
	end
	
	if not Admin.CanAccessID( ply, ID, ID > 50 or ply.ConsoleOperator ) then
		return Core.Print( ply, "Admin", Core.Text( "AdminFunctionalityAccess" ) )
	end
	
	-- Set zone
	if ID == 1 then
		local Type = tonumber( Value )
		if not Type then return end
		
		if Type == -10 then
			return HandleButton( ply, { -2, ID, "Extra" } )
		elseif Type == -20 then
			ply.ZoneExtra = nil
			return HandleButton( ply, { -2, ID } )
		elseif Type == -30 then
			ply.ZoneNoSnap = nil
			return HandleButton( ply, { -2, ID } )
		elseif Type == -40 then
			ply.ZoneNoSnap = true
			return HandleButton( ply, { -2, ID } )
		end
		
		local editor = Core.GetZoneEditor()
		editor:StartSet( ply, Type )
	
	-- Change map multiplier
	elseif ID == 3 then
		local nMultiplier = tonumber( Value )
		if not nMultiplier then
			return Core.Print( ply, "Admin", Core.Text( "AdminInvalidFormat", Value, "Number" ) )
		end
		
		local nOld, szMap = Core.GetMapVariable( "Multiplier" ) or 1, game.GetMap()
		Core.SetMapVariable( "Multiplier", nMultiplier )
		Core.SetMapVariable( "IsNewMap", true )
		
		local function ProceedReload()
			-- Reload all maps and ranks
			Core.LoadRecords( function()
				local update = {}
				for _,p in pairs( player.GetHumans() ) do
					if p:LoadRank( true ) then
						update[ #update + 1 ] = p
					end
				end
				
				ply:VarNet( "UpdateKeysEx", update, { "Rank", "SubRank" } )
			end )
			
			-- Add to the map version
			Core.AddMaplistVersion()
			
			Core.Print( ply, "Admin", Core.Text( "AdminSetValue", "Multiplier", nMultiplier .. " (You should reload the map now to avoid invalid ranks)" ) )
			Admin.AddLog( "Changed map multiplier on " .. szMap .. " from " .. nOld .. " to " .. nMultiplier, ply.UID, ply:Name() )
		end
		
		Prepare(
			"SELECT szMap FROM game_map WHERE szMap = {0}",
			{ szMap }
		)( function( data, varArg )
			if Core.Assert( data, "szMap" ) then
				Prepare(
					"UPDATE game_map SET nMultiplier = {0} WHERE szMap = {1}",
					{ nMultiplier, szMap }
				)( ProceedReload )
			else
				if Core.Config.IsSurf then
					Prepare(
						"INSERT INTO game_map VALUES ({0}, {1}, 1, 0, NULL, 0, NULL, NULL)",
						{ szMap, nMultiplier }
					)( ProceedReload )
				else
					Prepare(
						"INSERT INTO game_map VALUES ({0}, {1}, NULL, 0, NULL, NULL)",
						{ szMap, nMultiplier }
					)( ProceedReload )
				end
			end
		end )
	
	-- Set embedded data ID
	elseif ID == 4 then
		local nID = tonumber( Value )
		if not nID then
			if string.find( Value, ":", 1, true ) then
				local split = string.Explode( ":", Value )
				local zid, emid = tonumber( split[ 1 ] ), tonumber( split[ 2 ] )
				if not zid then
					return Core.Print( ply, "Admin", Core.Text( "AdminInvalidFormat", Value, "Number" ) )
				end
				
				local zt
				for _,zone in pairs( Core.GetZoneEntities() ) do
					if IsValid( zone ) and zone:EntIndex() == zid then
						zt = { zone.zonetype, zone.truetype, zone.basemin or zone.min, zone.basemax or zone.max }
						break
					end
				end
				
				if zt then
					local editor = Core.GetZoneEditor()
					local nid = emid and zt[ 1 ] + editor.EmbeddedOffsets[ zt[ 1 ] ] + emid or zt[ 1 ]
					
					Prepare(
						"UPDATE game_zones SET nType = {0} WHERE szMap = {1} AND nType = {2} AND vPos1 = {3} AND vPos2 = {4}",
						{ nid, game.GetMap(), zt[ 2 ], util.TypeToString( zt[ 3 ] ), util.TypeToString( zt[ 4 ] ) }
					)( function( data, varArg )
						Core.ReloadZones()
						Core.Print( ply, "Admin", Core.Text( "AdminOperationComplete" ) )
						
						Admin.AddLog( "Changed embedded id of " .. editor.Embedded[ zt[ 1 ] ] .. " (" .. zid .. ") to " .. (emid or "blank") .. " on " .. game.GetMap(), ply.UID, ply:Name() )
					end )
				else
					Core.Print( ply, "Admin", Core.Text( "AdminZoneFindFailed" ) )
				end
				
				return
			else
				ply.AdminZoneID = nil
				return Core.Print( ply, "Admin", Core.Text( "AdminEmbeddedReset" ) )
			end
		else
			if nID <= 0 then
				return Core.Print( ply, "Admin", Core.Text( "AdminEmbeddedRange" ) )
			end
			
			ply.AdminZoneID = nID
			Core.Print( ply, "Admin", Core.Text( "AdminEmbeddedSet", nID and nID or "1" ) )
		end
		
	-- Force change map
	elseif ID == 5 then
		GAMEMODE:UnloadGamemode( "Force", function()
			Admin.AddLog( "Changed level to " .. Value, ply.UID, ply:Name() )
			RunConsoleCommand( "changelevel", Value )
		end )
	
	-- Set player authority
	elseif ID == 7 then
		local nValue = tonumber( Value )
		local szSteam = ply.AdminTarget
		local nAccess, szLevel = Admin.Level.None, "Error"
		
		for name,level in pairs( Admin.Level ) do
			if nValue == level then
				szLevel = name
				nAccess = level
				break
			end
		end
		
		if nAccess == Admin.Level.None then
			if ply.ConsoleOperator then
				print( Core.Text( "AdminConsoleParse" ) )
			else
				Core.Print( ply, "Admin", Core.Text( "AdminMisinterpret", szLevel ) )
			end
			
			return false
		end
		
		local function UpdateAdminStatus( bUpdate, sqlArg, adminPly )	
			local function UpdateAdminCallback( data, varArg )
				local targetAdmin, targetData = varArg[ 1 ], varArg[ 2 ]
				
				if data then
					Core.LoadAdminPanel()
					Admin.AddLog( "Updated admin with identifier " .. targetData[ 1 ] .. " to level " .. targetData[ 2 ], targetAdmin.UID, targetAdmin:Name() )
					
					if targetAdmin.ConsoleOperator then
						print( Core.Text( "AdminConsoleAdded" ) )
					else
						Core.Print( targetAdmin, "Admin", Core.Text( "AdminOperationComplete" ) )
					end
				else
					if targetAdmin.ConsoleOperator then
						print( Core.Text( "AdminConsoleError" ) )
					else
						Core.Print( targetAdmin, "Admin", Core.Text( "AdminErrorCode", "Unknown" ) )
					end
				end
			end
			
			-- Adds a new admin whether they exist or not with the specified details
			if bUpdate then
				Prepare(
					"UPDATE game_admins SET nLevel = {0} WHERE nID = {1}",
					{ sqlArg[ 2 ], sqlArg[ 1 ] }
				)( UpdateAdminCallback, { adminPly, sqlArg } )
			else
				Prepare(
					"INSERT INTO game_admins (szSteam, nLevel) VALUES ({0}, {1})",
					{ sqlArg[ 1 ], sqlArg[ 2 ] }
				)( UpdateAdminCallback, { adminPly, sqlArg } )
			end
		end
		
		-- Checks if the entered Steam ID has any existing admin powers, and see whether we promote or demote him
		Prepare(
			"SELECT nID FROM game_admins WHERE szSteam = {0} ORDER BY nLevel DESC LIMIT 1",
			{ szSteam }
		)( function( data, varArg )
			local adminPly, sqlArg = varArg[ 2 ], varArg[ 3 ]
			local bUpdate = false

			if Core.Assert( data, "nID" ) then
				bUpdate = true
				sqlArg[ 1 ] = data[ 1 ]["nID"]
			end

			local updateFunc = varArg[ 1 ]
			updateFunc( bUpdate, sqlArg, adminPly )
		end, { UpdateAdminStatus, ply, { szSteam, nAccess } } )
	
	-- Set zone size
	elseif ID == 9 then
		local nIndex, bFind = tonumber( Value ), false
		
		local zones = Core.GetZoneEntities()
		for _,zone in pairs( zones ) do
			if IsValid( zone ) and zone:EntIndex() == nIndex then
				ply.ZoneData = { zone.truetype, zone.basemin or zone.min, zone.basemax or zone.max, zone:EntIndex(), zone.zonetype }
				bFind = true
				break
			end
		end
		
		if not bFind then
			Core.Print( ply, "Admin", Core.Text( "AdminZoneFindFailed" ) )
		else
			local nHeight = math.Round( ply.ZoneData[ 3 ].z - ply.ZoneData[ 2 ].z )
			local tabRequest = Admin.GenerateRequest( "Enter new desired height (Default is 128)\nNote: To change embedded data, add a : in front\nNote: To force set the min and max, separate space-separated vectors with a semicolon", "Change height", tostring( nHeight ), 90 )
			Core.Send( ply, "Global/Admin", { "Request", tabRequest } )
		end
	
	-- Set zone size follow-up function
	elseif ID == 90 then
		local nValue = tonumber( Value )
		if not nValue then
			if string.find( Value, ";", 1, true ) then
				local vecs = string.Explode( ";", Value )
				local v1 = util.StringToType( vecs[ 1 ], "Vector" )
				local v2 = util.StringToType( vecs[ 2 ], "Vector" )
				
				if v1 != Vector( 0, 0, 0 ) and v2 != Vector( 0, 0, 0 ) then
					nValue = { v1, v2 }
				else
					return Core.Print( ply, "Admin", Core.Text( "AdminInvalidFormat", Value, "Space-separated vectors" ) )
				end
			elseif string.sub( Value, 1, 1 ) == ":" then
				local emid = tonumber( string.sub( Value, 2 ) )
				local editor = Core.GetZoneEditor()
				local nid = emid and ply.ZoneData[ 5 ] + editor.EmbeddedOffsets[ ply.ZoneData[ 5 ] ] + emid or ply.ZoneData[ 5 ]
				
				return Prepare(
					"UPDATE game_zones SET nType = {0} WHERE szMap = {1} AND nType = {2} AND vPos1 = {3} AND vPos2 = {4}",
					{ nid, game.GetMap(), ply.ZoneData[ 1 ], util.TypeToString( ply.ZoneData[ 2 ] ), util.TypeToString( ply.ZoneData[ 3 ] ) }
				)( function( data, varArg )
					Core.ReloadZones()
					Core.Print( ply, "Admin", Core.Text( "AdminOperationComplete" ) )
					
					Admin.AddLog( "Changed embedded id of " .. editor.Embedded[ ply.ZoneData[ 5 ] ] .. " (" .. ply.ZoneData[ 4 ] .. ") to " .. (emid or "blank") .. " on " .. game.GetMap(), ply.UID, ply:Name() )
				end )
			else
				return Core.Print( ply, "Admin", Core.Text( "AdminInvalidFormat", Value, "Number" ) )
			end
		end

		local OldPos1 = util.TypeToString( ply.ZoneData[ 2 ] )
		local OldPos2 = util.TypeToString( ply.ZoneData[ 3 ] )
		
		if tonumber( nValue ) then
			local nMin = ply.ZoneData[ 2 ].z
			ply.ZoneData[ 3 ].z = nMin + nValue
		else
			ply.ZoneData[ 2 ] = nValue[ 1 ]
			ply.ZoneData[ 3 ] = nValue[ 2 ]
			
			nValue = "a new min-max combo"
		end
		
		Prepare(
			"UPDATE game_zones SET vPos1 = {0}, vPos2 = {1} WHERE szMap = {2} AND nType = {3} AND vPos1 = {4} AND vPos2 = {5}",
			{ util.TypeToString( ply.ZoneData[ 2 ] ), util.TypeToString( ply.ZoneData[ 3 ] ), game.GetMap(), ply.ZoneData[ 1 ], OldPos1, OldPos2 }
		)( function( data, varArg )
			Core.ReloadZones()
			Core.Print( ply, "Admin", Core.Text( "AdminOperationComplete" ) )
			
			Admin.AddLog( "Changed zone size of " .. ply.ZoneData[ 1 ] .. " to " .. nValue .. " on " .. game.GetMap(), ply.UID, ply:Name() )
		end )
	
	-- Remove zone
	elseif ID == 10 then
		local nIndex, bFind = tonumber( Value ), false
		
		local zones = Core.GetZoneEntities()
		for _,zone in pairs( zones ) do
			if IsValid( zone ) and zone:EntIndex() == nIndex then
				Prepare(
					"DELETE FROM game_zones WHERE szMap = {0} AND nType = {1} AND vPos1 = {2} AND vPos2 = {3}",
					{ game.GetMap(), zone.truetype, util.TypeToString( zone.basemin or zone.min ), util.TypeToString( zone.basemax or zone.max ) }
				)( function( data, varArg )
					Core.ReloadZones()
					Core.Print( ply, "Admin", Core.Text( "AdminOperationComplete" ) )
					
					Admin.AddLog( "Removed zone of type " .. Core.GetZoneName( zone.zonetype ) .. " on " .. game.GetMap(), ply.UID, ply:Name() )
				end )
				
				bFind = true
				break
			end
		end
		
		if not bFind then
			Core.Print( ply, "Admin", Core.Text( "AdminZoneFindFailed" ) )
		end
	
	-- Set map options
	elseif ID == 11 then
		local nValue = tonumber( Value )
		if not nValue then
			return Core.Print( ply, "Admin", Core.Text( "AdminInvalidFormat", Value, "Number" ) )
		end
		
		local opt = Core.GetMapVariable( "Options" )
		if nValue > 0 then
			local has = bit.band( opt, nValue ) > 0
			Core.SetMapVariable( "Options", has and bit.band( opt, bit.bnot( nValue ) ) or bit.bor( opt, nValue ) )
			Core.ReloadMapOptions()
			HandleButton( ply, { -2, ID } )
		else
			local szValue = opt == 0 and "NULL" or opt
			local szMap = game.GetMap()
			local szPrev = ""
			
			Prepare(
				"SELECT szMap, nOptions FROM game_map WHERE szMap = {0}",
				{ szMap }
			)( function( data, varArg )
				if Core.Assert( data, "szMap" ) then
					local val = tonumber( data[ 1 ]["nOptions"] )
					if val then
						szPrev = tostring( val )
					end
					
					Prepare(
						"UPDATE game_map SET nOptions = " .. (szValue == "NULL" and "NULL" or "{1}") .. " WHERE szMap = {0}",
						{ szMap, szValue }
					)( function( data, varArg )
						Admin.AddLog( "Changed map options of " .. game.GetMap() .. (szPrev != "" and " from " .. szPrev or "") .. " to " .. szValue, ply.UID, ply:Name() )
						Core.Print( ply, "Admin", Core.Text( "AdminSetValue", "Options", szValue ) )
					end )
				else
					Core.Print( ply, "Admin", Core.Text( "AdminMapOptionsNoEntry" ) )
				end
			end )
		end
	
	-- Import / export a map
	elseif ID == 13 then
		local nType = tonumber( Value )
		if nType == 1 then
			local tabRequest = Admin.GenerateRequest( "Enter JSON exported map data in the field below\nNote: Make sure there is NO map data on the given map\nIt is also recommended to currently not be on the target map", "Import map", "Paste here", 91 )
			Core.Send( ply, "Global/Admin", { "Request", tabRequest } )
		elseif nType == 2 then
			Prepare(
				"SELECT nMultiplier, nBonusMultiplier, nPlays, nOptions, szDate FROM game_map WHERE szMap = {0}",
				{ game.GetMap() },
				
				"SELECT nType, vPos1, vPos2 FROM game_zones WHERE szMap = {0}",
				{ game.GetMap() }
			)( function( dataset, varArg )
				local map = dataset[ 1 ]
				local zones = dataset[ 2 ]
				local json = { game.GetMap() }
				
				if map and map[ 1 ] then
					json[ 2 ] = map[ 1 ].nMultiplier
					json[ 3 ] = map[ 1 ].nBonusMultiplier
					json[ 4 ] = map[ 1 ].nPlays
					json[ 5 ] = map[ 1 ].nOptions
					json[ 6 ] = map[ 1 ].szDate
					
					if json[ 3 ] == "NULL" then json[ 3 ] = nil end
					if json[ 5 ] == "NULL" then json[ 5 ] = nil end
				end
				
				if zones then
					for i = 1, #zones do
						json[ #json + 1 ] = zones[ i ].nType .. ";" .. zones[ i ].vPos1 .. ";" .. zones[ i ].vPos2
					end
				end
				
				net.Start( "BinaryTransfer" )
				net.WriteString( "Export" )
				net.WriteString( util.TableToJSON( json ) )
				net.Send( ply )
			end )
		end
	
	-- Remove times
	elseif ID == 17 then
		ply.TimeRemoveData = Value
		local tabRequest = Admin.GenerateRequest( "Are you sure you want to remove " .. Value[ 4 ] .. "'s #" .. Value[ 2 ] .. " time? (Type Yes to confirm)", "Confirm removal", "No", 170 )
		Core.Send( ply, "Global/Admin", { "Request", tabRequest } )
	
	-- Set bonus multiplier
	elseif ID == 21 then
		local nMultiplier = tonumber( Value )
		if not nMultiplier then
			if not string.find( Value, " " ) then
				return Core.Print( ply, "Admin", Core.Text( "AdminInvalidFormat", Value, "Number" ) )
			else
				if string.find( Value, " " ) then
					local szNums = string.Explode( " ", Value )
					for i = 1, #szNums do
						if string.find( szNums[ i ], ":", 1, true ) then
							local szSplit = string.Explode( ":", szNums[ i ] )
							szNums[ i ] = { tonumber( szSplit[ 2 ] ) }
						else
							szNums[ i ] = tonumber( szNums[ i ] ) or 0
						end
					end
					
					nMultiplier = szNums
				else
					return Core.Print( ply, "Admin", Core.Text( "AdminBonusPointsInfo" ) )
				end
			end
		end

		local nOld, szMap = Core.GetMapVariable( "Bonus" ) or 1, game.GetMap()
		if not tonumber( nMultiplier ) then nMultiplier = Value end
		if type( nOld ) == "table" then nOld = string.Implode( " ", nOld ) end
		
		Core.SetMapVariable( "BonusMultiplier", nMultiplier )
		
		Prepare(
			"SELECT szMap FROM game_map WHERE szMap = {0}",
			{ szMap }
		)( function( data, varArg )
			if Core.Assert( data, "szMap" ) then
				Prepare(
					"UPDATE game_map SET nBonusMultiplier = {0} WHERE szMap = {1}",
					{ nMultiplier, szMap }
				)( function( data, varArg )
					-- Reload all maps and ranks
					Core.LoadRecords( function()
						local update = {}
						for _,p in pairs( player.GetHumans() ) do
							if p:LoadRank( true ) then
								update[ #update + 1 ] = p
							end
						end
						
						ply:VarNet( "UpdateKeysEx", update, { "Rank", "SubRank" } )
					end )
					
					-- Add to the map version
					Core.AddMaplistVersion()
					
					Admin.AddLog( "Changed bonus multiplier on " .. szMap .. " from " .. nOld .. " to " .. nMultiplier, ply.UID, ply:Name() )
					Core.Print( ply, "Admin", Core.Text( "AdminSetValue", "Bonus multiplier", nMultiplier ) )
				end )
			else
				Core.Print( ply, "Admin", Core.Text( "AdminMapBonusNoEntry" ) )
			end
		end )
	
	-- Remove a map
	elseif ID == 22 then
		if not Core.MapCheck( Value ) then
			Core.Print( ply, "Admin", Core.Text( "AdminRemoveUnavailable", Value ) )
		else
			Prepare( "DELETE FROM game_map WHERE szMap = {0}", { Value } )( SQLVoid )
			Prepare( "DELETE FROM game_times WHERE szMap = {0}", { Value } )( SQLVoid )
			Prepare( "DELETE FROM game_zones WHERE szMap = {0}", { Value } )( SQLVoid )
			
			Core.Ext( "Bot", "OnAdminButton" )( ply, ID, Value, Admin )
			Core.Print( ply, "Admin", Core.Text( "AdminRemoveComplete" ) )
			Admin.AddLog( "Fully removed map " .. Value, ply.UID, ply:Name() )
		end
	
	-- Teleport to a zone
	elseif ID == 25 then
		local nIndex, bFind = tonumber( Value )
		
		local zones = Core.GetZoneEntities()
		for _,zone in pairs( zones ) do
			if IsValid( zone ) and zone:EntIndex() == nIndex then
				bFind = zone
				break
			end
		end
		
		if not IsValid( bFind ) then
			Core.Print( ply, "Admin", Core.Text( "AdminZoneFindFailed" ) )
		else
			if not ply.Practice then
				return Core.Print( ply, "Admin", Core.Text( "AdminTeleportZoneWarning" ) )
			end
			
			ply:SetPos( bFind:GetPos() )
			Core.Print( ply, "Admin", Core.Text( "AdminTeleportZoneComplete" ) )
			Admin.AddLog( "Teleported to zone (" .. bFind.zonetype .. ") on " .. game.GetMap(), ply.UID, ply:Name() )
		end
	
	-- Change RTV timer
	elseif ID == 26 then
		local nValue = tonumber( Value )
		if not nValue then
			return Core.Print( ply, "Admin", Core.Text( "AdminInvalidFormat", Value, "Number" ) )
		end
		
		Core.RTVChangeTime( nValue )
		Core.Print( ply, "Admin", Core.Text( "AdminVoteTimeChange" ) )
		Admin.AddLog( "Changed the remaining time to " .. nValue .. " on " .. game.GetMap(), ply.UID, ply:Name() )
		
		ply:RTV( "Left" )
	
	-- Remove all times on a style
	elseif ID == 28 then
		local nStyle = tonumber( Value )
		if not nStyle and nStyle != ".0." then
			return Core.Print( ply, "Admin", Core.Text( "AdminTimeDeletionCancel" ) )
		end
		
		if nStyle == ".0." then
			nStyle = 0
		elseif not Core.IsValidStyle( nStyle ) then
			return Core.Print( ply, "Admin", Core.Text( "MiscInvalidStyle" ) )
		end

		Prepare(
			"DELETE FROM game_times WHERE szMap = {0}" .. (nStyle != 0 and " AND nStyle = {1}" or ""),
			{ game.GetMap(), nStyle }
		)( function( data, varArg )
			local style = nStyle != 0 and Core.StyleName( nStyle ) or "all styles"
			Core.LoadRecords( function()
				local update = player.GetHumans()
				for _,p in pairs( update ) do
					p:LoadTime( true )
				end
				
				ply:VarNet( "UpdateKeysEx", update, { "Record", "Position", "SpecialRank" } )
			end )
			
			Core.Print( ply, "Admin", Core.Text( "AdminStyleTimeRemove", style ) )
			
			Admin.AddLog( "Deleted all times on " .. style .. " for " .. game.GetMap(), ply.UID, ply:Name() )
		end )
	
	-- Send notification
	elseif ID == 29 then
		if Value == "" then
			return Core.Print( ply, "Admin", Core.Text( "AdminNotificationEmpty" ) )
		end
		
		ply.AdminTarget = nil
		
		if string.find( Value, "-", 1, true ) then
			local split = string.Explode( "-", Value )
			local target = Admin.FindPlayer( split[ 1 ] )
			if IsValid( target ) then
				ply.AdminTarget = target
				Value = split[ 2 ]
			end
		end
		
		local tab = { "Admin", Value, "shield", 10, (ply.AdminTarget and "Private" or "Global") .. " message from " .. ply:Name() .. " -> " .. Value }
		if IsValid( ply.AdminTarget ) then
			Core.Prepare( "Global/Notify", tab ):Send( ply.AdminTarget )
		else
			Core.Prepare( "Global/Notify", tab ):Broadcast()
		end
		
		Admin.AddLog( "Sent admin message " .. Value, ply.UID, ply:Name() )
		ply.AdminTarget = nil
	
	-- Teleport a player
	elseif ID == 30 then
		local target = Admin.FindPlayer( Value )
		if not IsValid( target ) then
			local str = string.gsub( Value, ",", "" )
			local vec = util.StringToType( str, "Vector" )
			if vec != Vector( 0, 0, 0 ) then
				target = { IsValid = function() return true end, GetPos = function( s ) return s.Pos end, Name = function( s ) return tostring( s.Pos ) end, Pos = vec }
			end
		end
		
		if IsValid( target ) then
			local source = Admin.FindPlayer( ply.AdminTarget )
			if not IsValid( source ) then
				return Core.Print( ply, "Admin", Core.Text( "AdminTeleportMissingSource" ) )
			end
			
			source:SetPos( target:GetPos() )
			Core.Print( ply, "Admin", Core.Text( "AdminTeleportComplete", source:Name(), target:Name() ) )
			Admin.AddLog( "Teleported " .. source:Name() .. " to " .. target:Name(), ply.UID, ply:Name() )
		else
			Core.Print( ply, "Admin", Core.Text( "AdminNoValidPlayer", Value ) )
		end
	
	-- Free-move a zone
	elseif ID == 31 then
		local nIndex, bFind = tonumber( Value )
		
		local zones = Core.GetZoneEntities()
		for _,zone in pairs( zones ) do
			if IsValid( zone ) and zone:EntIndex() == nIndex then
				bFind = zone
				break
			end
		end
		
		if not IsValid( bFind ) then
			Core.Print( ply, "Admin", Core.Text( "AdminZoneFindFailed" ) )
		else
			ply.AdminTargetZone = { bFind.basemin or bFind.min, bFind.basemax or bFind.max, { bFind.basemin or bFind.min, bFind.basemax or bFind.max, bFind.truetype } }
			Core.Print( ply, "Admin", Core.Text( "AdminZoneMoveInfo" ) )
			
			hook.Add( "KeyPress", "AdminMove_KP", function( ply, key )
				local pdata = ply.AdminTargetZone
				if not pdata then return end
				
				local move = Vector( 0, 0, 0 )
				if key == IN_USE then move = Vector( 1, 0, 0 )
				elseif key == IN_RELOAD then move = Vector( -1, 0, 0 )
				elseif key == IN_DUCK then move = Vector( 0, 1, 0 )
				elseif key == IN_JUMP then move = Vector( 0, -1, 0 )
				elseif key == IN_ATTACK then move = Vector( 0, 0, 1 )
				elseif key == IN_ATTACK2 then move = Vector( 0, 0, -1 )
				elseif key == IN_SCORE then
					ply.AdminTargetZone = nil
					hook.Remove( "KeyPress", "AdminMove_KP" )
					
					Core.Print( ply, "Admin", Core.Text( "AdminZoneMoveEnd" ) )
					Core.ReloadZones()
				elseif key == IN_SPEED then
					Prepare(
						"UPDATE game_zones SET vPos1 = {0}, vPos2 = {1} WHERE szMap = {2} AND nType = {3} AND vPos1 = {4} AND vPos2 = {5}",
						{ util.TypeToString( pdata[ 1 ] ), util.TypeToString( pdata[ 2 ] ), game.GetMap(), pdata[ 3 ][ 3 ], util.TypeToString( pdata[ 3 ][ 1 ] ), util.TypeToString( pdata[ 3 ][ 2 ] ) }
					)( function( data, varArg )
						Admin.AddLog( "Completed free-move of zone (" .. pdata[ 3 ][ 3 ] .. ") on " .. game.GetMap(), ply.UID, ply:Name() )
						
						ply.AdminTargetZone = nil
						hook.Remove( "KeyPress", "AdminMove_KP" )
						
						Core.Print( ply, "Admin", Core.Text( "AdminZoneMoveComplete" ) )
						Core.ReloadZones()
					end )
				else return end
				
				local zone = nil
				local zones = Core.GetZoneEntities()
				for _,z in pairs( zones ) do
					if pdata[ 1 ] == (z.basemin or z.min) and pdata[ 2 ] == (z.basemax or z.max) then
						zone = z
						break
					end
				end
				
				if not IsValid( zone ) then return end
				
				local cache = Core.GetZoneEntities( true )
				for _,data in pairs( cache ) do
					if data.vPos1 == (zone.basemin or zone.min) and data.vPos2 == (zone.basemax or zone.max) then
						data.vPos1 = data.vPos1 + move
						data.vPos2 = data.vPos2 + move
						
						ply.AdminTargetZone = { data.vPos1, data.vPos2, pdata[ 3 ] }
						
						break
					end
				end
				
				Core.GetZoneEntities( true, cache )
				Core.ReloadZones( true )
			end )
		end
	
	-- Change tier or type of map
	elseif ID == 33 then
		local tabRequest = Admin.GenerateRequest( "Enter new desired value\n(Linear: 0, Staged: 1 - Tier: Num 1 - 6):", "Change value", "", 70 )
		ply.AdminTarget = tonumber( Value )
		Core.Send( ply, "Global/Admin", { "Request", tabRequest } )
	
	-- Fully wipe a player
	elseif ID == 34 then
		local target = Admin.FindPlayer( Value )
		
		if IsValid( target ) then
			return Core.Print( ply, "Admin", Core.Text( "AdminFullWipeOnline" ) )
		end
		
		Prepare( "DELETE FROM game_notifications WHERE szUID = {0}", { Value } )( SQLVoid )
		Prepare( "DELETE FROM game_racers WHERE szUID = {0}", { Value } )( SQLVoid )
		Prepare( "DELETE FROM game_stagetimes WHERE szUID = {0}", { Value } )( SQLVoid )
		Prepare( "DELETE FROM game_tas WHERE szUID = {0}", { Value } )( SQLVoid )
		Prepare( "DELETE FROM game_times WHERE szUID = {0}", { Value } )( SQLVoid )
		
		Core.Print( ply, "Admin", Core.Text( "AdminFullWipeComplete" ) )
		Admin.AddLog( "Fully wiped " .. Value, ply.UID, ply:Name() )
	
	-- Reporting by players
	elseif ID == 60 then
		local Type = tonumber( Value )	
		local item = Admin.ReportDetails[ Type ]
		
		ply.AdminReport = nil
		ply.ReportEntity = nil
		
		if item then
			local gent
			if Type == 1 or Type == 7 then
				local list = ents.FindInSphere( ply:GetPos(), 10 )
				for _,e in pairs( list ) do
					if e:GetClass() == "game_timer" then
						gent = e
						break
					end
				end
				
				if not gent then
					return Core.Print( ply, "Admin", Core.Text( "AdminReportZoneInside" ) )
				else
					ply.ReportEntity = gent
				end
			end
			
			ply.AdminReport = Type
			
			local tabRequest = Admin.GenerateRequest( item[ 1 ], item[ 2 ], ply.LastAdminMessage or item[ 3 ], 61 )
			tabRequest.Special = true
			ply.LastAdminMessage = nil
			
			Core.Send( ply, "Global/Admin", { "Request", tabRequest } )
		else
			Core.Print( ply, "Admin", Core.Text( "AdminReportCommunity" ) )
		end
	
	-- Report follow-up function
	elseif ID == 61 then
		local Type = ply.AdminReport
		if not Type or not tonumber( Type ) then
			return Core.Print( ply, "Admin", Core.Text( "AdminReportInvalid" ) )
		end
		
		local l = string.len( Value )
		if l > 256 then
			ply.LastAdminMessage = Value
			return Core.Print( ply, "Admin", Core.Text( "AdminReportLength" ) )
		end
		
		if (Admin.ReportDetails[ Type ] and Admin.ReportDetails[ Type ][ 3 ]) == Value then
			return Core.Print( ply, "Admin", Core.Text( "AdminReportDefault", Admin.ReportDetails[ Type ][ 3 ] ) )
		end

		local low = string.lower( Value )
		if string.find( low, "insert into", 1, true ) or string.find( low, "game_", 1, true ) or string.find( low, "drop table", 1, true ) then
			return Core.Print( ply, "Admin", Core.Text( "AdminReportMalicious" ) )
		end
		
		local zone = (IsValid( ply.ReportEntity ) and ply.ReportEntity.truetype) or -1
		if zone >= 0 then
			Value = Value .. " [Zone (" .. zone .. ") " .. tostring( ply.ReportEntity:GetPos() ) .. "]"
		end
		
		if (Type >= 1 and Type <= 4) or Type == 7 or Type == 10 then
			Value = Value .. " (Map " .. game.GetMap() .. ")"
		end
		
		ply.ReportEntity = nil
		ply.LastAdminReport = SysTime()
		
		Core.ReportPlayer( {
			Submitter = ply,
			ReporterSteam = ply.UID,
			Text = Core.Text( "AdminReportNotify", ply:Name() ),
			TypeID = Type,
			Comment = Value
		} )
	
	-- Map tier or type change follow-up function
	elseif ID == 70 then
		local szType = ply.AdminTarget == 1 and "nTier" or "nType"
		local szNormal = string.sub( szType, 2 )
		
		local nValue = tonumber( Value )
		if not nValue then
			return Core.Print( ply, "Admin", Core.Text( "AdminInvalidFormat", Value, "Number" ) )
		end
		
		if szType == "nType" and nValue != 1 and nValue != 0 then
			return Core.Print( ply, "Admin", Core.Text( "AdminInvalidFormat", Value, "Number" ) )
		elseif szType == "nTier" and nValue < 1 or nValue > 7 then
			return Core.Print( ply, "Admin", Core.Text( "AdminInvalidFormat", Value, "Number" ) )
		end

		local nOld, szMap = Core.GetMapVariable( szNormal ) or (szType == "nTier" and 1 or 0), game.GetMap()
		Core.SetMapVariable( szNormal, nValue )

		Prepare(
			"SELECT szMap FROM game_map WHERE szMap = {0}",
			{ szMap }
		)( function( data, varArg )
			if Core.Assert( data, "szMap" ) then
				Prepare(
					"UPDATE game_map SET " .. szType .. " = {0} WHERE szMap = {1}",
					{ nValue, szMap }
				)( function( data, varArg )
					Core.LoadRecords()
					Core.AddMaplistVersion()
					
					Admin.AddLog( "Changed map " .. string.lower( szNormal ) .. " on " .. szMap .. " from " .. nOld .. " to " .. nValue, ply.UID, ply:Name() )
					Core.Print( ply, "Admin", Core.Text( "AdminSetValue", szNormal, nValue ) )
				end )
			else
				Core.Print( ply, "Admin", Core.Text( "AdminMapTierNoEntry", string.lower( szNormal ) ) )
			end
		end )
	
	-- Map import follow-up function
	elseif ID == 91 then
		local tab = util.JSONToTable( Value )
		if tab and #tab >= 6 then
			local queries = {}
			queries[ #queries + 1 ] = "REPLACE INTO game_map (szMap, nMultiplier, nBonusMultiplier, nPlays, nOptions, szDate) VALUES ({0}, {1}, " .. (tab[ 3 ] and "{2}" or "NULL") .. ", {3}, " .. (tab[ 5 ] and "{4}" or "NULL") .. ", {5})"
			queries[ #queries + 1 ] = { tab[ 1 ], tab[ 2 ], tab[ 3 ] or "DUMMY", tab[ 4 ], tab[ 5 ] or "DUMMY", tab[ 6 ] }
			
			-- Be sure to wipe all zones before inserting the new ones
			queries[ #queries + 1 ] = "DELETE FROM game_zones WHERE szMap = {0}"
			queries[ #queries + 1 ] = { tab[ 1 ] }
			
			-- And add all zones
			for i = 7, #tab do
				local data = string.Explode( ";", tab[ i ] )
				queries[ #queries + 1 ] = "INSERT INTO game_zones (szMap, nType, vPos1, vPos2) VALUES ({0}, {1}, {2}, {3})"
				queries[ #queries + 1 ] = { tab[ 1 ], data[ 1 ], data[ 2 ], data[ 3 ] }
			end
			
			local out = Prepare(
				unpack( queries )
			)( function( data, varArg )
				Core.Print( ply, "Admin", Core.Text( "AdminImportComplete", tab[ 1 ], #tab - 6 ) )
			end )
		else
			Core.Print( ply, "Admin", Core.Text( "AdminImportInput" ) )
		end
	
	-- Handled elsewhere
	elseif ID == 18 or ID == 19 or ID == 35 then
		local _,f = Admin.GetSetupTable( ID )
		f( ply, ID, Value, Admin )
	end
end

local function AdminHandleClient( ply, varArgs )
	local nID = tonumber( varArgs[ 1 ] )
	if nID == -1 then
		HandleRequest( ply, varArgs )
	elseif nID == -2 then
		HandleButton( ply, varArgs )
	else
		print( "Invalid admin request by", ply, varArgs[ 1 ] )
	end
end
Core.Register( "Global/Admin", AdminHandleClient )

function Admin.CommandProcess( ply, args )
	if not Admin.CanAccess( ply, Admin.Level.Moderator ) or args.Key == "report" then
		if ply.LastAdminReport and SysTime() - ply.LastAdminReport < 600 then
			return Core.Print( ply, "Admin", Core.Text( "AdminReportFrequency" ) )
		end
		
		Admin.CreateReport( ply )
	else
		if #args == 0 then
			Admin.CreateWindow( ply )
		else
			local szID, nAccess = args[ 1 ], Admin.GetAccess( ply )
			if szID == "spectator" and nAccess >= Admin.Level.Moderator then
				if not args[ 2 ] then return Core.Print( ply, "Admin", Core.Text( "AdminCommandArgument", szID ) ) end
				HandleButton( ply, { -2, 12, args.Upper[ 2 ] } )
			elseif szID == "strip" and nAccess >= Admin.Level.Moderator then
				if not args[ 2 ] then return Core.Print( ply, "Admin", Core.Text( "AdminCommandArgument", szID ) ) end
				HandleButton( ply, { -2, 23, args.Upper[ 2 ] } )
			elseif szID == "zone" and nAccess >= Admin.Level.Super then
				HandleButton( ply, { -2, 1 } )
			else
				Core.Print( ply, "Admin", Core.Text( "AdminCommandInvalid", args.Key ) )
			end
		end
	end
end
Core.AddCmd( { "admin", "report" }, Admin.CommandProcess )