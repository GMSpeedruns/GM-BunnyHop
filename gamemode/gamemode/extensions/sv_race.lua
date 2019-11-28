-- Define config variables
Core.Config.Var.Add( "RaceInviteTime", "race_invite_time", 60, "The time for which a race invite will remain valid" )

-- Set the main table
local Race = {}
Race.Challenges = {}
Race.GroupInvite = {}
Race.TopList = {}
Race.Abandons = {}
Race.InviteTime = Core.Config.Var.GetInt( "RaceInviteTime" )
Race.SelectLimit = Core.Config.Var.GetInt( "TopLimit" )


--[[
	Description: Shows initialization of the race extension
--]]
local Prepare = SQLPrepare
function Race.Init()
	Core.Config.Var.Activate( "Race", Race )
	Core.PrintC( "[Startup] Extension 'race' activated" )
end
Core.PostInitFunc = Race.Init

--[[
	Description: Changes the win/streak of the player
--]]
function Race.SetDataEntry( ply, style, win, callback )
	Prepare(
		"SELECT nWins, nStreak FROM game_racers WHERE szUID = {0} AND nStyle = {1}",
		{ ply.UID, style }
	)( function( data, varArg )
		local add = win and 1 or 0
		if Core.Assert( data, "nStreak" ) then
			Prepare(
				"UPDATE game_racers SET nStreak = " .. (win and "nStreak + 1" or "0") .. (win and ", nWins = nWins + 1" or "") .. " WHERE szUID = {0} AND nStyle = {1}",
				{ ply.UID, style }
			)( SQLVoid )
			
			varArg( (tonumber( data[ 1 ]["nStreak"] ) or 0) + add, (tonumber( data[ 1 ]["nWins"] ) or 0) + add )
		else
			Prepare(
				"INSERT INTO game_racers (szUID, nStyle, nWins, nStreak) VALUES ({0}, {1}, {2}, {3})",
				{ ply.UID, style, add, add }
			)( SQLVoid )
			
			varArg( add, add )
		end
		
		Race.Invalidate = true
	end, callback )
end

--[[
	Description: Retrieves the top list from the races per style
--]]
function Race.GetTopList( style, callback )
	if not Race.TopList[ style ] or Race.Invalidate then
		Race.TopList[ style ] = {}
		Race.Invalidate = nil
		
		Prepare(
			"SELECT nStyle, szUID, nWins, nStreak FROM game_racers WHERE nStyle = {0} ORDER BY nWins DESC LIMIT {1}",
			{ style, Race.SelectLimit }
		)( function( data, varArg )
			if Core.Assert( data, "nWins" ) then
				for j = 1, #data do
					Race.TopList[ style ][ j ] = data[ j ]
				end
			end
			
			callback( Race.TopList[ style ] )
		end )
	else
		callback( Race.TopList[ style ] )
	end
end

--[[
	Description: Deletes items from the race top
--]]
function Race.RemoveItems( ply, nStyle, tab )
	if #tab == 0 then return end
	
	local strs = {}
	for i = 1, #tab do
		strs[ #strs + 1 ] = "szUID = '" .. tab[ i ] .. "'"
	end
	
	Prepare(
		"DELETE FROM game_racers WHERE nStyle = {0} AND (" .. string.Implode( " OR ", strs ) .. ")",
		{ nStyle }
	)( SQLVoid )
	
	Race.Invalidate = true
	
	Core.Print( ply, "Admin", Core.Text( "AdminTimeRemoval", #tab ) )
	Core.AddAdminLog( "Removed " .. #tab .. " " .. Core.StyleName( nStyle ) .. " race entries", ply.UID, ply:Name() )
end


--[[
	Description: Checks if a player can race
--]]
function Race.CanPlay( ply )
	return not ply.Spectating and not ply.Practice and not ply.TAS and not ply.Bonus
end

--[[
	Description: Creates a new race object
--]]
function Race.Create( style, plys )
	local tab = { Pass = false }
	
	-- Check if they're ready to race
	for _,ply in pairs( plys ) do
		if not Race.CanPlay( ply ) then
			tab.Message = "RaceInvalidTarget"
		elseif Race.Abandons[ ply ] then
			tab.Message = "RaceInvalidAbandon"
		end
	end

	if not tab.Message then
		-- Set table data
		tab.Players = plys
		tab.Style = style
		tab.Start = Race.Begin
		tab.Stop = Race.End
		tab.Abandon = Race.Abandon
		tab.Finished = {}
		tab.Completed = false
		tab.Pass = true
	end
	
	return tab
end

--[[
	Description: Begins a race given the race object
--]]
function Race.Begin( tab )
	local center = Core.GetZoneCenter( nil, Core.IsValidBonus( tab.Style ) and "Bonus Start" or "Normal Start" )
	if not center then return end
	
	-- Assemble a list
	local ids = {}
	
	-- Set an identifier for style change
	tab.Prestyle = true
	
	-- Set race data on players
	for _,ply in pairs( tab.Players ) do
		if ply.Style != tab.Style then
			concommand.Run( ply, "style", tostring( tab.Style ), "" )
		end
		
		ply.Race = tab
		ids[ #ids + 1 ] = ply:EntIndex()
	end
	
	-- Set the countdown to be active
	tab.Counting = true
	tab.Prestyle = nil
	
	-- Apply reset checks on the players
	for _,ply in pairs( tab.Players ) do
		ply:ResetSpawnPosition()
		ply:SetPos( center )
	end
	
	-- Send the players a delay timer (~0.05s less for net sending time)
	Core.Send( tab.Players, "Timer/RaceDelay", ids )
	
	-- Resetting them constantly
	timer.Create( "MoveChecker", 0.1, 0, function()
		if not tab or not tab.Players then return end
		for _,ply in pairs( tab.Players ) do
			ply:SetPos( center )
		end
	end )
	
	-- Start a timer to begin the race
	timer.Simple( 10, function()
		if not tab then return end
		
		-- Reset countdown
		tab.Counting = nil
		
		-- Check status
		if not tab.Abandoned then
			tab.Started = SysTime()
			
			for _,ply in pairs( tab.Players ) do
				ply:SetPos( center )
			end
		else
			Core.Print( tab.Players, "Timer", Core.Text( "ActivePlayerAbandon", tab.Abandoned ) )
		end
		
		timer.Remove( "MoveChecker" )
	end )
	
	-- Let them know we're good
	return true
end

--[[
	Description: Ends the race for one player
--]]
function Race.End( tab, ply )
	-- If someone abandoned, just destroy right away
	if tab.Abandoned then
		return Race.Destroy( tab, true )
	end
	
	-- Make sure they can only finish once per race
	if tab.Finished[ ply ] then return end
	
	-- Set this player as finished
	tab.Finished[ ply ] = SysTime() - tab.Started
	
	-- Save the details
	Race.Process( tab )
end

--[[
	Description: Removes a player from a race
--]]
function Race.Abandon( tab, ply, command )	
	-- Set the abandoned variable
	if not tab.Abandoned then
		tab.Abandoned = {}
	end
	
	-- Set the player to be abandoned
	tab.Abandoned[ #tab.Abandoned + 1 ] = ply
	Race.Abandons[ ply ] = true
	
	local count = table.Count( tab.Players )
	if count > 2 then				
		-- Loop over it and set them to have high times
		for i = 1, #tab.Abandoned do
			tab.Finished[ tab.Abandoned[ i ] ] = 1000000 + i
		end
	else
		-- Just set the other player's time to 0, giving an instant win
		for _,p in pairs( tab.Players ) do
			if not IsValid( p ) then continue end
			if p != ply then
				tab.Finished[ p ] = 0
			end
		end
	end
	
	-- Get on with processing it
	Race.Process( tab, true )
end

--[[
	Description: Fully destroys the race
--]]
function Race.Destroy( tab, abandon )
	-- Remove the race attributes
	for _,ply in pairs( tab.Players ) do
		if not IsValid( ply ) then continue end
		
		ply.Race = nil
	end
	
	-- Submit a message for destroying
	Core.Print( tab.Players, "Timer", Core.Text( "ActivePlayerCancelled", abandon and " Nobody has been rewarded since one of the players abandoned!" or "" ) )
	
	-- Clean the table
	for k in next,tab do
		tab[ k ] = nil
	end
end

--[[
	Description: Processes the race and checks its status
--]]
function Race.Process( tab, force )
	-- Count tables
	local finish, players = table.Count( tab.Finished ), table.Count( tab.Players )
	
	-- When the match was ended successfully
	if (not tab.Abandoned or force) and (finish >= players or players == 2) then
		local low, top, win, loss  = 1000000, 0
		for p,t in pairs( tab.Finished ) do
			if low > t then
				win = p
				low = t
			end
			
			if top < t then
				loss = p
				top = t
			end
		end
		
		if players == 2 and finish == 1 then
			for _,p in pairs( tab.Players ) do
				if not IsValid( p ) then continue end
				
				if p != win then
					loss = p
				end
			end
		end
		
		-- Quite impossible
		if not IsValid( win ) or not IsValid( loss ) then
			-- Just detroy it here
			Race.Destroy( tab )
			
			return Core.Print( tab.Players, "Timer", Core.Text( "ActivePlayersAbandon" ) )
		end
		
		-- Set the variables
		local winner = tab.Finished[ win ]

		-- Send a message to involved players
		for _,p in pairs( tab.Players ) do
			if not IsValid( p ) then continue end
			
			local text = ""
			if not tab.Finished[ p ] then
				text = "You haven't finished!"
			else
				local t = tab.Finished[ p ] - winner
				text = (t < 0 and "-" or "+") .. Core.ConvertTime( math.abs( t ) ) .. " compared to your timer now"

				if players == 2 and finish == 1 then
					text = "You totally smashed that guy!"
				end
			end

			if p == loss then
				text = "You ended last!"
			elseif p == win then
				text = "Wooohooo!"
			end
			
			Core.Print( p, "Timer", Core.Text( "ActivePlayerFinishIndividual", p == win and "You" or win:Name(), Core.ConvertTime( winner ), text ) )
		end
		
		-- Broadcast a message
		Core.Print( nil, "Timer", Core.Text( "ActivePlayerFinishGlobal", Core.StyleName( tab.Style ), win:Name(), players, tab.Abandoned and "since the competitor(s) abandoned." or "with a time of " .. Core.ConvertTime( winner ) .. "!" ) )
		Core.Send( tab.Players, "Timer/RaceDelay", "Clear" )
		
		-- Finalize
		Race.Finalize( tab, win, loss )
	else
		Core.Print( tab.Players, "Timer", Core.Text( "ActivePlayersFinished", finish, players, force and " (" .. table.Count( tab.Abandoned ) .. " abandoned the race)" or "" ) )
	end
end

--[[
	Description: Finalize the race and distribute the results
--]]
function Race.Finalize( tab, winner, loser )
	-- Get streaks
	Race.SetDataEntry( winner, tab.Style, true, function( sw, ww )
		Race.SetDataEntry( loser, tab.Style, false, function( sl, wl )
			-- Message the winner
			Core.Print( winner, "Timer", Core.Text( "ActivePlayerStreak", ww, sw ) )
			
			-- Message the loser if required
			if sl > 0 then
				Core.Print( loser, "Timer", Core.Text( "ActivePlayerLoss", sl, wl ) )
			end
			
			-- Reset top list
			local top = Race.TopList[ tab.Style ]
			if top then
				for i = 1, #top do
					if top[ i ].szUID == winner.UID then
						top[ i ].nWins = top[ i ].nWins + 1
						break
					end
				end
			end
			
			-- Clean up
			Race.Destroy( tab )
		end )
	end )
end


--[[
	Description: Challenges a player to a race
--]]
function Race.ChallengeCommand( ply, args )
	if #args == 0 then
		Core.Print( ply, "Timer", Core.Text( "RaceBlankCmd", "race" ) )
	else
		if ply.Race then
			return Core.Print( ply, "Timer", Core.Text( "ActiveCommandAttempt" ) )
		end
		
		local target
		for _,p in pairs( player.GetHumans() ) do
			-- Find by SteamID primarily
			if p.UID == args.Upper[ 1 ] then
				target = p
				break
			-- Otherwise find by name
			elseif string.find( string.lower( p:Name() ), string.lower( args[ 1 ] ), 1, true ) then
				if not target then
					target = p
				else
					return Core.Print( ply, "Timer", Core.Text( "RaceDoubleTarget" ) )
				end
			end
		end
		
		if IsValid( target ) and target != ply then
			-- Check if they're valid
			if not Race.CanPlay( target ) or not Race.CanPlay( ply ) then
				return Core.Print( ply, "Timer", Core.Text( "RaceInvalidTarget" ) )
			end
			
			-- Create a list if we don't have anything yet
			if not Race.Challenges[ target ] then
				Race.Challenges[ target ] = {}
			end
			
			-- Check if we have an existing one
			local hasvalid = false
			for _,invite in pairs( Race.Challenges[ target ] ) do
				if not invite.Accepted and invite.Player == ply then
					hasvalid = true
					break
				end
			end
			
			-- Block the invite
			if hasvalid then
				return Core.Print( ply, "Timer", Core.Text( "RaceInviteOngoing" ) )
			end
			
			-- Insert into the list
			local id = table.insert( Race.Challenges[ target ], { Player = ply, Accepted = false, Style = ply.Style, Invited = SysTime() } )
			Core.Print( ply, "Timer", Core.Text( "RaceInviteSent", target:Name() ) )
			Core.Prepare( "Global/Notify", { "Timer", Core.Text( "RaceInvitePopup" ), "email_open_image", 4, Core.Text( "RaceChallenged", ply:Name(), Core.StyleName( ply.Style ), id, id ) } ):Send( target )
		else
			return Core.Print( ply, "Timer", Core.Text( "RaceIncorrectTarget", args.Upper[ 1 ] ) )
		end
	end
end
Core.AddCmd( { "race", "challenge" }, Race.ChallengeCommand )

--[[
	Description: Challenges a group of people to a race
--]]
function Race.ChallengeGroupCommand( ply, args )
	if #args == 0 then
		Core.Print( ply, "Timer", Core.Text( "RaceBlankCmd", "racegroup" ) )
	else
		if ply.Race then
			return Core.Print( ply, "Timer", Core.Text( "ActiveCommandAttempt" ) )
		end
		
		-- Checks if we're a go
		if args[ 1 ] == "start" then
			if not Race.GroupInvite[ ply ] then
				return Core.Print( ply, "Timer", Core.Text( "GroupStartInvalid" ) )
			end
			
			-- See if all players have accepted
			local players = Race.GroupInvite[ ply ].Accepted
			if table.Count( players ) >= 2 then
				-- Actually get a list of players
				local plys = {}
				for p,_ in pairs( players ) do
					plys[ #plys + 1 ] = p
				end
				
				-- Create the race
				local result = Race.Create( Race.GroupInvite[ ply ].Style, plys )
				
				-- When the race was successfully created
				if result.Pass then
					-- Begin the race
					if result:Start() then
						-- Clear the invite
						Race.GroupInvite[ ply ] = nil
						
						-- Notify the players
						Core.Print( plys, "Timer", Core.Text( "GroupRaceBegin" ) )
					else
						Core.Print( plys, "Timer", Core.Text( "AcceptRaceFail" ) )
					end
				else
					Core.Print( plys, "Timer", Core.Text( result.Message ) )
				end
			else
				Core.Print( ply, "Timer", Core.Text( "GroupStartShortage", table.Count( Race.GroupInvite[ ply ].Accepted ), table.Count( Race.GroupInvite[ ply ].Accepted ) ) )
			end
		else
			local target
			for _,p in pairs( player.GetHumans() ) do
				-- Find by SteamID primarily
				if p.UID == args.Upper[ 1 ] then
					target = p
					break
				-- Otherwise find by name
				elseif string.find( string.lower( p:Name() ), string.lower( args[ 1 ] ), 1, true ) then
					if not target then
						target = p
					else
						return Core.Print( ply, "Timer", Core.Text( "RaceDoubleTarget" ) )
					end
				end
			end
			
			if IsValid( target ) and target != ply then
				-- Check if they're valid
				if not Race.CanPlay( target ) or not Race.CanPlay( ply ) then
					return Core.Print( ply, "Timer", Core.Text( "RaceInvalidTarget" ) )
				end
				
				-- Create a list if we don't have anything yet
				if not Race.GroupInvite[ ply ] then
					Race.GroupInvite[ ply ] = { Players = { ply }, Accepted = { [ ply ] = true }, Style = ply.Style }
				end
				
				-- Check if we have an existing one
				local hasvalid = false
				for _,invited in pairs( Race.GroupInvite[ ply ].Players ) do
					if invited == target then
						hasvalid = true
						break
					end
				end
				
				-- Block the invite
				if hasvalid then
					return Core.Print( ply, "Timer", Core.Text( "RaceInviteOngoing" ) )
				end
				
				-- Insert the player into players list
				table.insert( Race.GroupInvite[ ply ].Players, target )
				
				-- Send the message
				Core.Print( ply, "Timer", Core.Text( "RaceInviteSent", target:Name() ) )
				Core.Prepare( "Global/Notify", { "Timer", Core.Text( "RaceInvitePopup" ), "email_open_image", 4, Core.Text( "GroupChallenged", ply:Name(), Core.StyleName( Race.GroupInvite[ ply ].Style ) ) } ):Send( target )
			else
				return Core.Print( ply, "Timer", Core.Text( "RaceIncorrectTarget", args.Upper[ 1 ] ) )
			end
		end
	end
end
Core.AddCmd( { "racegroup", "challengegroup" }, Race.ChallengeGroupCommand )

--[[
	Description: Accepts a race invite
--]]
function Race.AcceptCommand( ply, args )
	if #args == 0 or not tonumber( args[ 1 ] ) then
		Core.Print( ply, "Timer", Core.Text( "AcceptBlankCmd" ) )
	else
		if ply.Race then
			return Core.Print( ply, "Timer", Core.Text( "ActiveCommandAttempt" ) )
		end
		
		-- Check if we have any invitations
		if not Race.Challenges[ ply ] then
			Core.Print( ply, "Timer", Core.Text( "AcceptNoInvitations" ) )
		else
			-- Check if the player is still alive and kickin'
			local opponent = Race.Challenges[ ply ][ tonumber( args[ 1 ] ) ]
			if not opponent or not IsValid( opponent.Player ) or opponent.Accepted or opponent.Player.Race then
				return Core.Print( ply, "Timer", Core.Text( "AcceptNoInvitationsID" ) )
			end
			
			if SysTime() - opponent.Invited > Race.InviteTime then
				if IsValid( opponent.Player ) then
					Core.Print( opponent.Player, "Timer", Core.Text( "RaceInviteSenderTimeout", ply:Name() ) )
				end
				
				Race.Challenges[ ply ][ tonumber( args[ 1 ] ) ] = nil
				return Core.Print( ply, "Timer", Core.Text( "RaceInviteTimeout" ) )
			end
			
			-- Set the invitation state to accepted
			opponent.Accepted = true
			
			-- Create the race
			local result = Race.Create( opponent.Style, { opponent.Player, ply } )
			
			-- When the race was successfully created
			if result.Pass then
				-- Begin the race
				if result:Start() then					
					-- Notify the players
					Core.Print( opponent.Player, "Timer", Core.Text( "AcceptBeginRace", ply:Name() .. " has", "your" ) )
					Core.Print( ply, "Timer", Core.Text( "AcceptBeginRace", "You have", "the" ) )
				else
					Core.Print( { opponent.Player, ply }, "Timer", Core.Text( "AcceptRaceFail" ) )
				end
			else
				Core.Print( { opponent.Player, ply }, "Timer", Core.Text( result.Message ) )
			end
		end
	end
end
Core.AddCmd( { "accept", "duel" }, Race.AcceptCommand )

--[[
	Description: Declines a race invite
--]]
function Race.DeclineCommand( ply, args )
	if #args == 0 or not tonumber( args[ 1 ] ) then
		Core.Print( ply, "Timer", Core.Text( "AcceptBlankCmd" ) )
	else
		if ply.Race then
			return Core.Print( ply, "Timer", Core.Text( "ActiveCommandAttempt" ) )
		end
		
		-- Check if we have any invitations
		if not Race.Challenges[ ply ] then
			Core.Print( ply, "Timer", Core.Text( "DeclineNoInvitations" ) )
		else
			-- Check if we have a valid invitation ID
			local nID = tonumber( args[ 1 ] )
			local opponent = Race.Challenges[ ply ][ nID ]
			if not opponent or opponent.Accepted then
				return Core.Print( ply, "Timer", Core.Text( "AcceptNoInvitationsID" ) )
			end

			-- Set the invitation state to accepted
			opponent.Accepted = nil
			
			-- Send a message
			local name = "the open"
			if IsValid( opponent.Player ) then
				name = opponent.Player:Name()
				Core.Print( opponent.Player, "Timer", Core.Text( "DeclineCmdMessage", ply:Name(), "your" ) )
			end
			
			-- Send message to self
			Core.Print( ply, "Timer", Core.Text( "DeclineCmdMessage", "You", name ) )
			
			-- Nullify the invite
			Race.Challenges[ ply ][ nID ] = nil
		end
	end
end
Core.AddCmd( "decline", Race.DeclineCommand )

--[[
	Description: Accepts a group race invite
--]]
function Race.AcceptGroupCommand( ply, args )
	if ply.Race then
		return Core.Print( ply, "Timer", Core.Text( "ActiveCommandAttempt" ) )
	end
	
	local targets = {}
	for inviter,list in pairs( Race.GroupInvite ) do
		for _,item in pairs( list.Players ) do
			if item == ply then
				targets[ #targets + 1 ] = inviter
			end
		end
	end
	
	local target
	if #targets > 1 then
		if not args[ 1 ] or not tonumber( args[ 1 ] ) or not targets[ tonumber( args[ 1 ] ) ] then
			local data = {}
			for id,v in pairs( targets ) do
				if not IsValid( v ) then continue end
				data[ #data + 1 ] = "[ID " .. id .. "] " .. v:Name()
			end
			
			if #data > 0 then
				return Core.Print( ply, "Timer", Core.Text( "GroupInviteAcceptMulti", string.Implode( ", ", data ) ) )
			else
				return Core.Print( ply, "Timer", Core.Text( "AcceptNoInvitations" ) )
			end
		elseif IsValid( targets[ tonumber( args[ 1 ] ) ] ) then
			target = targets[ tonumber( args[ 1 ] ) ]
		else
			return Core.Print( ply, "Timer", Core.Text( "AcceptNoInvitations" ) )
		end
	elseif #targets == 1 then
		target = targets[ 1 ]
	else
		return Core.Print( ply, "Timer", Core.Text( "AcceptNoInvitations" ) )
	end
	
	-- Check if we have any invitations
	if not IsValid( target ) then
		Core.Print( ply, "Timer", Core.Text( "AcceptNoInvitations" ) )
	else
		-- Check if the player is still alive and kickin'
		if not Race.GroupInvite[ target ] or Race.GroupInvite[ target ].Accepted[ ply ] or target.Race then
			return Core.Print( ply, "Timer", Core.Text( "AcceptNoInvitationsID" ) )
		end
		
		-- Set the invitation state to accepted
		Race.GroupInvite[ target ].Accepted[ ply ] = true
		Core.Print( ply, "Timer", Core.Text( "AcceptBeginRace", "You have", "the group race" ) )
		Core.Print( target, "Timer", Core.Text( "GroupAcceptStart", ply:Name(), table.Count( Race.GroupInvite[ target ].Accepted ), table.Count( Race.GroupInvite[ target ].Players ) ) )
	end
end
Core.AddCmd( { "acceptgroup", "duelgroup" }, Race.AcceptGroupCommand )

--[[
	Description: Abandons a race
--]]
function Race.AbandonCommand( ply, args )
	if not ply.Race then
		Core.Print( ply, "Timer", Core.Text( "ActiveAbandonNone" ) )
	else
		if ply.Race.Counting then
			Core.Print( ply, "Timer", Core.Text( "ActiveAbandonCount" ) )
		else
			Race.Abandon( ply.Race, ply, true )
		end
	end
end
Core.AddCmd( { "abandon", "leave", "stoprace", "giveup" }, Race.AbandonCommand )

--[[
	Description: Shows the race top list for a specific style
--]]
function Race.TopListCommand( ply, args )
	local nStyle = ply.Style or Styles.Normal
	if #args > 0 then
		local st = tonumber( args[ 1 ] )
		if not st then
			local szStyle = string.Implode( " ", args.Upper )
			local a = Core.GetStyleID( szStyle )
			
			if not Core.IsValidStyle( a ) then
				return Core.Print( ply, "General", Core.Text( "MiscInvalidStyle" ) )
			else
				st = a
			end
		end
		
		nStyle = st
	end
	
	if not Core.IsValidStyle( nStyle ) then return Core.Print( ply, "General", Core.Text( "MiscInvalidStyle" ) ) end
	
	Race.GetTopList( nStyle, function( data )
		if #data == 0 then
			return Core.Print( ply, "Timer", Core.Text( "RaceTopStyleNone", Core.StyleName( nStyle ) ) )
		else
			Core.Prepare( "GUI/Build", {
				ID = "Top",
				Title = "Race Top (" .. Core.StyleName( nStyle ) .. ")",
				X = 400,
				Y = 370,
				Mouse = true,
				Blur = true,
				Data = { data, IsEdit = ply.RemovingTimes, Style = nStyle, ViewType = 1 }
			} ):Send( ply )
		end
	end )
end
Core.AddCmd( { "racetop", "toprace" }, Race.TopListCommand )


-- Language
Core.AddText( "RaceBlankCmd", "Please enter a valid oppponent to race like so: !1; [Name]" )
Core.AddText( "RaceDoubleTarget", "Two targets were found with that name. Please narrow the name down or use the scoreboard to directly challenge someone." )
Core.AddText( "RaceInvalidTarget", "You and the target player cannot be spectating nor be in practice mode." )
Core.AddText( "RaceInvalidAbandon", "One of the players has recently abandoned a match and will not be able to race right now." )
Core.AddText( "RaceIncorrectTarget", "There was no valid target found matching '1;'" )
Core.AddText( "RaceInviteSent", "Your invitation has been sent. Please wait for 1; to accept it." )
Core.AddText( "RaceInvitePopup", "You have received a race invite!" )
Core.AddText( "RaceInviteTimeout", "The invitation has timed out. Please request or make another invite." )
Core.AddText( "RaceInviteSenderTimeout", "1; tried accepting your invitation but it timed out. Please send another invitation." )
Core.AddText( "RaceInviteOngoing", "You have already sent this player an invitation." )
Core.AddText( "RaceChallenged", "You have been challenged by 1; to race on the 2; style. Invitation ID is 3;. To accept this challenge simply type !accept 4; or !decline it" )
Core.AddText( "RaceTopStyleNone", "The race top list for the 1; style is unavailable." )
Core.AddText( "GroupChallenged", "You have been challenged by 1; to join a group race on the 2; style. To accept this challenge simply type !acceptgroup or !declinegroup it" )
Core.AddText( "GroupRaceBegin", "Everyone has accepted their invitation. The race will now begin!" )
Core.AddText( "GroupInviteAcceptMulti", "You have multiple invitations, please select one by typing !acceptgroup [Number]\nThis is the list of invitations: 2;" )
Core.AddText( "GroupAcceptStart", "1; accepted your invitation (2; / 3;). To start the race, type !racegroup start" )
Core.AddText( "GroupStartInvalid", "You can't start a group race if you haven't invited anyone" )
Core.AddText( "GroupStartShortage", "Not enough people have accepted the race invite (2; / 3;)" )
Core.AddText( "AcceptBlankCmd", "Please enter a valid invitation ID to accept." )
Core.AddText( "AcceptNoInvitations", "You have no open invitations to accept." )
Core.AddText( "AcceptNoInvitationsID", "You have no open and valid invitations with that ID. The target might also be racing already." )
Core.AddText( "AcceptBeginRace", "1; accepted 2; invitation" )
Core.AddText( "AcceptRaceFail", "Something went wrong while creating the race. Please try again later." )
Core.AddText( "ActivePlayerCancelled", "The race has ended.1;" )
Core.AddText( "ActivePlayerAbandon", "One of the players (1;) has abandoned the race and thus it will not continue." )
Core.AddText( "ActivePlayerFinishGlobal", "[1;] 2; won a 3; player race 4;" )
Core.AddText( "ActivePlayerFinishIndividual", "1; won the race with a time of 2; (3;)" )
Core.AddText( "ActivePlayerStreak", "One win has been added! You have a new total wins of 1;, with a winning streak of 2;!" )
Core.AddText( "ActivePlayerLoss", "Your winning streak has been reset from 1; to 0. Your wins are at 2;." )
Core.AddText( "ActivePlayersFinished", "1; / 2; players have finished the race.3;" )
Core.AddText( "ActiveCommandAttempt", "You cannot use any of these commands while you're in a race. To abandon a race you can type !abandon" )
Core.AddText( "ActiveAbandonNone", "You don't have any active race to abandon." )
Core.AddText( "ActiveAbandonCount", "You can't abandon the race before it has started." )
Core.AddText( "ActivePlayersAbandon", "The important players of the race (winner or loser) have abandoned the race and thus it has been aborted." )
Core.AddText( "DeclineCmdMessage", "1; declined 2; invitation" )
Core.AddText( "DeclineNoInvitations", "You have no open invitations to decline." )

-- Help commands
local cmd = Core.ContentText( nil, true ).Commands
cmd["race"] = "Challenges another player to race you"
cmd["racegroup"] = "Allows you to challenge a whole group to race"
cmd["accept"] = "Accepts an open race invitation"
cmd["decline"] = "Declines an open race invitation"
cmd["acceptgroup"] = "Accepts an open group race invitation"
cmd["abandon"] = "Abandons an active race"
cmd["racetop"] = "Opens the race top list"