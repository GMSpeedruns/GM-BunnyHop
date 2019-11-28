-- This file is server-sided so not every client has to receive this massive amount of text even when they barely ever see it

local _L = {}
_L.Content = {}

--[[
	Description: Formats a text entry from the _L table
--]]
function Core.Text( szIdentifier, ... )
	local varArgs = { ... }
	if not _L[ szIdentifier ] then
		varArgs = { szIdentifier }
		szIdentifier = "Default"
	end
	
	if type( varArgs[ 1 ] ) == "table" then
		varArgs = varArgs[ 1 ]
	end
	
	local szText = _L[ szIdentifier ]
	for nParamID,szArg in pairs( varArgs ) do
		szText = string.gsub( szText, nParamID .. ";", szArg )
	end
	
	return szText
end

--[[
	Description: Allows dynamically adding text
--]]
function Core.AddText( szIdentifier, szText )
	_L[ szIdentifier ] = szText
end

--[[
	Description: Gets larger language objects from our _L table
--]]
function Core.ContentText( szIdentifier, bEntire )
	if bEntire then
		return _L.Content
	else
		return _L.Content[ szIdentifier ]
	end
end

--[[
	Description: Creates a tiny class that allows you to easily add colored text to a table
--]]
function Core.ColorText()
	local data = {}
	
	data.Add = function( s, t, c, w )
		if c != nil then
			local f = true
			for i = #s, 1, -1 do
				if type( s[ i ] ) == "table" then
					if s[ i ] == c then
						f = nil
					end
					
					break
				end
			end
			if f then s[ #s + 1 ] = c end
		end
		
		s[ #s + 1 ] = t
		
		if w then
			s[ #s + 1 ] = color_white
		end
	end
	
	data.Replace = function( s, i, x, t, c, w )
		if c then table.insert( s, i, c ) i = i + 1 end
		local post = string.sub( s[ i ], x )
		s[ i ] = t
		if c and w then table.insert( s, i + 1, color_white ) i = i + 1 end
		table.insert( s, i + 1, post )
	end
	
	data.Copy = function( s, t )
		local d = table.Copy( t )
		for i = 1, #d do
			s[ i ] = d[ i ]
		end
	end
	
	data.Get = function( s )
		local tab = {}
		for i = 1, #s do
			tab[ i ] = s[ i ]
		end
		return tab
	end
	
	data.Count = function( s )
		return #s
	end
	
	return data
end


-- All phrases coming in!
_L.Default = "The message identifier '1;' does not exist! Please report to an admin!"
_L.Generic = "1;"

_L.StyleEqual = "Your style is already set to 1;2;"
_L.StyleChange = "Your style has been changed to 1;!2;"
_L.StyleNoclip = "You can only use noclip in the practice mode. Type !practice or !p to go into practice."
_L.StyleFreestyle = "You have 1; freestyle zone.2;"
_L.StyleLeftRight = "Your timer has been stopped for using +left or +right!"
_L.StyleTeleport = "You can only teleport while in practice mode. Type !practice or !p to go into practice."
_L.StylePracticeEnabled = "Practice mode is still enabled. To turn it off, type !practice or !p again."

_L.BonusNone = "There is no bonus set1;"
_L.BonusToggle = "You have 1; bonus mode2;"

_L.ZoneStart = "You are now placing a '1;'. Move around to see the box in real-time. Press \"Set Zone\" again to save.\nParameters: [2;]"
_L.ZoneFinish = "The zone has been placed."
_L.ZoneCancel = "Zone placement has been cancelled."
_L.ZoneNoEdit = "You are not placing any zones at the moment."
_L.ZoneSetup = "There are no start or end zones available."
_L.ZoneIDIncrement = "The zone ID has been automatically incremented to: 1;"
_L.ZoneSpeed = "You can't leave this zone with that speed. (1;)"
_L.ZoneJumpExit = "You can't leave this zone like that. (No jumping)"
_L.ZoneJumpInside = "You can't jump inside this zone."

_L.VotePlayer = "1; has Rocked the Vote! (2; more 3; required) [4;%]"
_L.VoteRevoke = "1; has revoked their vote (2; 3; are still required)"
_L.VoteStart = "A vote to change map has begun. Make your choice!"
_L.VoteExtend = "The vote has decided that the map is to be extended by 1; minutes!"
_L.VoteChange = "The vote has decided that the map is to be changed to 1;!"
_L.VoteMissing = "The map 1; is not available on the server so it can't be played right now."
_L.VoteLimit = "Please wait for 1; seconds before voting again."
_L.VoteAlready = "You have already Rocked the Vote."
_L.VotePeriod = "A map vote has already started. You cannot vote right now."
_L.VotePeriodActive = "This is only possible during the voting period!"
_L.VoteLimited = "You cannot Rock the Vote right now. Please wait until some time has passed (1;m)"
_L.VoteLimitPlay = "You cannot Rock the Vote until you have beaten at least one map on the Normal style!"
_L.VoteList = "1; vote(s) needed to change maps.\nVoted (2;): 3;\nHaven't voted (4;): 5;"
_L.VoteCheck = "There are 1; 2; needed to change maps."
_L.VoteCancelled = "1;The vote was cancelled by an admin, thus the map will not change."
_L.VoteFailure = "Something went wrong while trying to change maps. Please !rtv again."
_L.VoteRevokeFail = "You can not revoke your vote because you have not Rocked the Vote yet."
_L.VoteSameVotes = "Equal votes on 1;. The server has randomly selected #2; as the winner."

_L.Nomination = "1; has nominated 2; to be played next."
_L.NominationChange = "1; has changed his nomination from 2; to 3;"
_L.NominationAlready = "You have already nominated this map!"
_L.NominateOnMap = "You are currently playing this map so you can't nominate it."
_L.NominateRecent = "This map was last played 1; map(s) ago so it can't be nominated yet."

_L.CommandPractice = "You have to be in practice mode to use this command."
_L.CommandTeleportInvalid = "Your target player is in spectator mode."
_L.CommandTeleportGo = "You have been teleported to 1;"
_L.CommandTeleportNoTarget = "Couldn't find a valid player with search terms: 1;"
_L.CommandTeleportBlank = "No player name entered. Usage: !tp PlayerName"
_L.CommandArgumentNum = "Please enter a valid number as argument, like so: /1; [2;]"
_L.CommandArgumentChange = "Your 1; has been changed to 2;"
_L.CommandAutoScroll = "You can't toggle the state of auto hop on a scroll style!"
_L.CommandAutoToggle = "Auto hop has been 1;"
_L.CommandSpectatorList = "These are the people spectating you (#1;): 2;"
_L.CommandSpectatorNone = "Nobody is spectating you. You really have to step up your game to attract them!"
_L.CommandTopListBlank = "The top list for the 1; style is unavailable."
_L.CommandWRTopBlank = "There are no WR holders on the 1; style."
_L.CommandWRListBlank = "There are no available records on the 1; style."
_L.CommandWRListReach = "The WR ID 1; is not valid. Valid range is [1 - 2;]"
_L.CommandWRListUnable = "Unable to display any data, probably because 1; beaten any maps yet"
_L.CommandNoWRBeat = "1; beaten any maps; every map will still have to be WR'd."
_L.CommandNoWRNone = "1; have any WR time. That means every map can still be conquered!"
_L.CommandNoWRAll = "Damn. A WR on every map? Congratulations! I wish I was that good..."
_L.CommandNoWRAllRemote = "This player holds the WR for every map. Jealous?"
_L.CommandWRBeatNone = "1; beaten any maps on this style yet"
_L.CommandWRLeftNone = "1; to complete every map on this style"
_L.CommandWRLeftAll = "1; beaten every map on this style"
_L.CommandRemoteWRListBlank = "There are no records on 1; for the 2; style"
_L.CommandParameterMissing = "Missing required parameters on /1; -> 2;"
_L.CommandSubList = "Available sub-commands on \"1;\": 2;"
_L.CommandWeaponList = "These weapons are available (spawn with ![name] or !weapon [name]): 1;"
_L.CommandWeaponLimited = "You can't obtain this weapon on Surf. Only the base weapons (glock, usp, knife and the scout) are available"
_L.CommandWeaponPickup = "Picking up weapons is now 1;"
_L.CommandFrictionToggle = "You have 1; increased friction mode"
_L.CommandFrictionStyles = "You can't use this command while on a style that already uses stamina"
_L.CommandFrictionNotAvailable = "You can not enable KZ stamina on this map."
_L.CommandProfileIdentifier = "You need to use this command in combination with an identifier. Either use: /profile [Steam ID] or @(WR Position) or #(Name)"
_L.CommandProfileNoneAt = "Couldn't find a record at number 1; for the 2; style. Please make sure the number is in range."
_L.CommandProfileNoneName = "Couldn't find an online player with a name containing '1;'"
_L.CommandProfileFetching = "We are now loading the player's profile, please sit tight!"
_L.CommandProfileBusy = "You can only load one player profile simultaneously, please wait for the other one to finish loading"
_L.CommandStyleInvalid = "You have entered an invalid style id. Use !styles to see their respective IDs."
_L.CommandHelpDisplay = "The '1;' command 2;"
_L.CommandHelpNone = "The command '1;' has no documentation, sorry!"
_L.CommandHelpInavailable = "The command '1;' isn't available or has no documentation"
_L.CommandBonusID = "Please enter a valid bonus ID."
_L.CommandResetSpawn = "You are already in the start zone"
_L.CommandModelBlank = "Please enter the name of a model like so: !model alyx"
_L.CommandModelInvalid = "The model 1; does not exist or is not supported"
_L.CommandModelChange = "Your model has been changed to 1;. To change back to the default model, type !model default"
_L.CommandModelDisabled = "The server owner has disabled custom models. You will appear as the default model."
_L.CommandUndoEmpty = "You have not restarted yet this run. That means you cannot undo your restart, silly."
_L.CommandUndoTime = "You can only use this command within 60 seconds of the restart"
_L.CommandUndoFail = "Data from before restart and after restart don't match. Don't try to do anything crazy."
_L.CommandUndoSpawn = "You must be outside of the spawn with a started timer to use this"
_L.CommandUndoSucceed = "You have been returned to the position where you used /restart!"
_L.CommandMuteArguments = "You need to provide the target name or Steam ID and then use /1; [Name / Steam ID]"
_L.CommandWRPosMissing = "You haven't completed 1; on this style."
_L.CommandWRPosInfo = "You hold the #1; position with a time of 2;3;"
_L.CommandWRNone = "There is no #1 time for this style"
_L.CommandWRInfo = "The #1 time on 1; is 2;, held by 3;"
_L.CommandWRAllNone = "There are no #1 times on any style!"
_L.CommandTimeAvgNone = "There are no times on this style to determine the average by"
_L.CommandTimeAvgValue = "The average over which points are calculated on 1; is 2;"
_L.CommandTriesInfo = "This command exists to keep track of restarts and does something based on what you want. You can use it in three types: kick, count or time\nTo activate the command, type /1; [kick/count/time] [amount of tries/time]\nTo de-activate: /2; stop"
_L.CommandTriesSubTypes = "Currently the only types are 'kick', 'count', 'time' and 'stop'. Use the subtypes like so: /1; [type] [amount of retries/time]"
_L.CommandTriesActivated = "Restart tracking has been enabled with type '1;'2;"
_L.CommandTriesStopped = "Restart try tracking has been disabled!"
_L.CommandTriesLeft = "You have 1; 2; left!"
_L.CommandLinkNotSet = "No URL has been set for this command"

_L.MapInfo = "The map '1;' has a weight of 2; points 3;4;"
_L.MapInavailable = "The map '1;' is not available on the server."
_L.MapMissing = "Sorry, this map isn't available on the server itself. Please contact an admin!"
_L.MapPlayed = "1; has been played 2; times.3;"
_L.MapTimeLeft = "There is 1; left on this map."
_L.MapAutoExtend = "You will now 1;automatically vote for extend on the map votes."
_L.MapNominated = "You have1; nominated 2;"
_L.MapNominations = "All nominated maps:\n"
_L.MapNominationsNone = "Nobody has nominated a map yet"
_L.MapNominationNone = "You haven't nominated a map yet"
_L.MapNominationRevoke = "Your map nomination has been revoked!"
_L.MapNominationChance = "The maps that have been nominated by most players will have the highest chance of appearing in the map vote"

_L.PlayerGunObtain = "You have obtained a 1;"
_L.PlayerGunFound = "You already have a 1;"
_L.PlayerSyncStatus = "Your sync is 1; being displayed."
_L.PlayerTeleport = "You have been teleported to 1;"
_L.PlayerBeatenTime = "Welcome back, 1;.\nSome of your #1 records have been beaten:\n2;\n\nYou can view records on other maps by typing !wr 3;"
_L.PlayerBeatenPopup = "You have 1; beaten WR(s)!"

_L.TimerPause = "Your timer has been saved. Whenever you want to continue with this session (1;), simply type !restore."
_L.TimerPauseOverwrite = "You have overwritten your previously saved session. To restore this session (1;), type !restore."
_L.TimerRestore = "Your timer has been restored and your saved location has been removed. You can now use !pause again."
_L.TimerRestoreNone = "You don't have any restore points set. You can save your timer and location by typing !pause."
_L.TimerRestoreLimit = "You have already restored your timer 3 times on this map. You cannot use this anymore until the map changes."
_L.TimerRestoreServer = "Your timer has been restored and your location has been changed to where you were at previously before the server reset."
_L.TimerPauseHelp = "By typing this command again your timer will be saved on the server, allowing you to restore to it at a later point by using !restore. Note: By restoring, you will add 5 minutes to your time, removing any advantage."
_L.TimerInvalidPause = "You need to have a running timer on any non-bonus style in order to make use of this feature."
_L.TimerInvalidRestore = "In order to restore your previous time, you need to be outside of the start zone on the same style as you saved on (1;)"

_L.TimerCheckpointWaiting = "Please wait until you have been teleported"
_L.TimerCheckpointMissing = "The designated checkpoint (set with /cpset or by clicking) is no longer available"
_L.TimerCheckpointLoadBlank = "Please set at least one checkpoint before trying to load one"
_L.TimerCheckpointPractice = "You can't use this feature outside of Practice mode or while spawned as a spectator"
_L.TimerCheckpointBlank = "You can't clear out an already empty slot"
_L.TimerCheckpointMenuPractice = "You have to be in practice mode to use the checkpoint menu"
_L.TimerCheckpointInvalidID = "Please enter a VALID and filled in checkpoint with an ID between 3 and 9"
_L.TimerCheckpointManualSet = "Preferred checkpoint manually set to 1;. This will be overridden when you teleport to another checkpoint"
_L.TimerCheckpointHelp = "To save a checkpoint, left click an empty button (left click can also by simulated by your 1-9 number keys. Left click again to teleport to it. To remove a set item, right click it (middle mouse for ALL).\nIf you want to bind these actions, use /cpsave\nFor setting your fixed CP, type /cpset [ID] (or click on it via the GUI), then restore to it by typing /cpload\nTo clear all CPs or a specific one, use /cpwipe [id]"

_L.TimerMapsInfo = "To view more details about specific maps, use the following commands:\n/leastplayed: Shows the 5 least played maps\n/mostplayed: Shows the 5 most played maps\n/lastplayed: Shows the 5 last played maps\n/randommap: Gives you a random map"
_L.TimerMapsDisplay = "1; played maps: 2;"
_L.TimerMapsRandom = "Here's a random map: 1;"

_L.SpectateRestart = "You have to be alive in order to reset yourself to the start."
_L.SpectateTargetInvalid = "You are unable to spectate this player right now."
_L.SpectateWeapon = "You can't obtain a weapon whilst in spectator mode."
_L.SpectateThirdperson = "You can't toggle third person mode while spectating."

_L.MissingArgument = "You have to add 1; argument to the command."
_L.CommandLimiter = "1; Wait a bit before trying again (2;s)."
_L.CommandBan = "We have limited your command usage for an additional 30 seconds."
_L.InvalidCommand = "The command '1;' is not a valid command."
_L.InvalidCommandLoophole = "Oh no, you discovered the top secret invalid command. You now have the power to do nothing at all!"

_L.MiscZoneNotFound = "The 1; zone couldn't be found."
_L.MiscInvalidStyle = "You have entered an invalid style name. Use the exact name shown on !styles or use their respective ID."
_L.MiscMissingMapList = "Couldn't obtain map list, please reconnect!"
_L.MiscIllegalChat = "Please refrain from using '1;' on our servers and remain respectful to all players."
_L.MiscIllegalAccess = "Ha! I'm pretty sure you are NOT allowed to do this ;)"
_L.MiscAbout = "This gamemode, " .. GM.Name .. " v" .. string.format( "%.2f", Core.Config.Version ) .. ", was developed by " .. GM.Author .. " for Prestige Gaming as a follow-up to the old v3.\nI want to give out my special thanks to the people who have helped me a lot over the course of my development adventures: George, Push, Cloud and 1337 Designs.\nI hope everyone will be able to enjoy it!\nFor additional information, hit F1 and go to Help!"

-- The help text we show on F1 -> Help
_L.Content.HelpText = {
	"Welcome to " .. Core.Config.ServerName .. " " .. Core.Config.FullName,
	"",
	"The idea of " .. (Core.Config.IsSurf and "Surfing" or "Bunny Hop") .. " is very simple: to go faster by",
	(Core.Config.IsSurf and "sliding on slanted surfaces" or "continuously jumping") .. ". This idea can be applied in",
	"a lot of different gameplay concepts.",
	"",
	"We provide you with a wide variety of maps that each",
	"house a challenge in the form of an 'obstacle course'.",
	"The difficulty of these maps are indicated by the amount of",
	"points they are worth. You can see this with /map",
	"",
	"By completing any map you gain points based on your time;",
	"The faster the time, the more points you gain.",
	"This amount of calculated by this specific formula:",
	"> Map points * (Style average / Your time)",
	"There are two limits to this formula; you can't get more",
	"than 2x the points and not lower than 0.25x the points.",
	"",
	"Each player has a rank. This rank is calculated from",
	"the total amount of points you have for each map on",
	"a specific style. You can see these ranks with /rank",
	"",
	(Core.Config.IsSurf and "Skill Surf" or "Bunny Hop") .. " has a major competitive aspect to it;",
	"we all compete to get the fastest time, or even",
	"complete the map at all. We compete for the nicest rank.",
	"To see the best players we have, type /top",
	"",
	"BOLDStyle Descriptions",
	"Normal [Default style, Auto Hop: ON, Air Accel: 1k]",
	"You strafe with A and D, hold space to jump",
	"",
	"Sideways [Angled style, Auto Hop: ON, Air Accel: 1k]",
	"You strafe with S and W, turn view by 90 degrees",
	"",
	"Half Sideways [Angled style, Auto Hop: ON, Air Accel: 1k]",
	"You strafe with a combination of W and A or D",
	"For Surf using W+A and S+D is easier",
	"",
	"W-Only [Angled style, Auto Hop: ON, Air Accel: 1k]",
	"You strafe just by using W, hence the name",
	"",
	"A-Only [Angled style, Auto Hop: ON, Air Accel: 1k]",
	"Variant of W-Only, but then you strafe with A",
	"In order to turn, make a 180 degree turn",
	"",
	"D-Only [Angled style, Auto Hop: ON, Air Accel: 1k]",
	"Variant of A-Only, but then you strafe with D",
	"",
	"S-Only [Angled style, Auto Hop: ON, Air Accel: 1k]",
	"Variant of S-Only, but then you strafe with S",
	"You can't see anything on this style. Just for fun",
	"",
	"Legit [Normal style, Auto Hop: OFF, Air Accel: 100]",
	"You strafe with A and D since it's a normal style",
	"Hardest style available, velocity setbacks on",
	"incorrectly timed jumps. Fast strafing required",
	"",
	"Easy Scroll [Normal style, Auto Hop: OFF, Air Accel: 200]",
	"Reduced jump height and scrolling make this harder",
	"Unlike Legit, this does not have velocity setbacks",
	"",
	(Core.Config.IsPack and "Jump Pack" or "Stamina") .. " [Normal style, Auto Hop: ON, Air Accel: 200]",
	(Core.Config.IsPack and "You can hold space mid-air to boost up" or "A full stamina system but with auto"),
	"",
	"Unreal [Normal style, Auto Hop: ON, Air Accel: 10k]",
	"Custom style that is meant to be unrealistic",
	"You can get different boosts by",
	"pressing RIGHT MOUSE at the correct time",
	"under different key combinations (W, S, Space or A/D",
	"or by binding unrealboost [1/2/3/4] to any key",
	"Master this style controlling the speed",
	"",
	"Low Gravity [Normal style, Auto Hop: ON, Air Accel 1k]",
	"Everything is like Normal, but you fly up a LOT higher",
	"",
	"Backwards [Angled style, Auto Hop: ON, Air Accel 1k]",
	"You have to Bunny Hop normally, but instead of using",
	"A to go left you use D, and A to go to the right since",
	"your view is rotated a full 180 degrees",
	"",
	"Bonus [Any style, Auto Hop: Style-based, Air Accel: 1k]",
	"Different course than the normal map",
	"Occasionally offers extra bonuses with !b2",
	"Can be played on each style",
	"",
	"Practice [Normal style, Auto Hop: ON, Air Accel: 1k]",
	"This style is not timed. You can noclip in it",
	"Also have access to !cp for checkpoints"
}

-- Some phrases to throw at the player when they're (possibly) spamming chat commands
_L.Content.MiscCommandLimit = {
	"Please be gentle on the commands.",
	"Commands have feelings, too!",
	"Calm down now.",
	"Stop that, please.",
	"Ouch, my processing power!",
	"Ha, too soon!",
	"You're doing that too fast.",
	"Whoa, that was quick.",
	"Cool-down.",
	"You can relax now."
}

-- A list of all the models the players can use
_L.Content.ValidModels = {
	"default", "alyx", "barney", "breen", "combine_soldier", "combine_soldier_prisonguard", "combine_super_soldier", "eli", "gman_high", "magnusson", "monk", "mossman", "mossman_arctic", "odessa", "p2_chell", "police", "police_fem",
	"riot", "gasmask", "urban", "swat", "phoenix", "arctic", "guerilla", "leet"
}

-- Additional female models
_L.Content.FemaleModels = {
	"group01/female_01", "group01/female_05", "group03/female_01", "group03/female_04", "group03/female_01", "alyx", "mossman", "mossman_arctic", "p2_chell"
}

-- All valid commands and their description
_L.Content.Commands = {
	["r"] = "Resets the player to the start of the map",
	["spec"] = "Brings the player to spectator mode. Also possible via F2",
	["noclip"] = "Toggles noclip on the player. Practice style required. Also possible via noclip bind.",
	["stats"] = "Toggles real-time statistics window",
	["tp"] = "Allows you to teleport to another player",
	["timescale"] = "Sets the timescale of the game",
	["gravity"] = "Changes the gravity on the player",
	["kz"] = "Increases friction to enable easier climbing manouvres",
	["auto"] = "Allows toggling of auto on auto styles",
	["listspecs"] = "Shows who's spectating you",
	["end"] = "Go to the end zone of the normal timer",
	["endbonus"] = "Go to the end zone of the bonus",
	["pause"] = "Saves your time on the server",
	["restore"] = "Allows you to restore a saved session",
	["undo"] = "Undo's an incorrect restart",
	
	["rtv"] = "Calls a Rock the Vote. For the subcommands, type !rtv ?",
	["revoke"] = "Allows the player to revoke their RTV",
	["checkvotes"] = "Prints the requirements for a map vote to happen",
	["votelist"] = "Prints a list of all players and their vote status",
	["timeleft"] = "Displays for how long the map will still be on",
	["extend"] = "Automatically makes the player extend",
	
	["showgui"] = "Allows the user to change the visibility of the GUI",
	["sync"] = "Toggles visibility of sync on their GUI",
	
	["settings"] = "Opens a window where you can change settings",
	["style"] = "Opens a window for the player to select a style",
	["nominate"] = "Opens a window for the player to nominate a map for a vote",
	["wr"] = "Opens the WR list for the style you're currently playing on",
	["rank"] = "Opens a window that shows a list of ranks",
	["top"] = "Opens a window that shows the best players in the server",
	["mapsbeat"] = "Opens a window that shows the maps you have completed and your time on it",
	["mapsleft"] = "Opens a window that shows the maps you haven't completed and their difficulty",
	["mywr"] = "Opens a window that shows all your #1 WRs on your current style",
	["mapsnowr"] = "Opens a window that shows all the maps that you don't have a WR on",
	["allwrs"] = "Opens a window that shows all the #1 WRs on the map",
	["profile"] = "Opens a window that shows details about the given player",
	["showkeys"] = "Opens a window that shows the keys the active player is pressing",
	["close"] = "Closes any window that is open",
	["togglewnd"] = "Changes the visibility of a window",
	
	["crosshair"] = "Toggles the crosshair for the player OR changes settings; type !crosshair help",
	["glock"] = "These commands allow you to spawn in certain weapons",
	["remove"] = "Strip yourself of all weapons",
	["flip"] = "Switches your weapons to the other hand",
	["noguns"] = "Blocks guns from being picked up",
	
	["hide"] = "Sets or toggles the visibililty of the players. Output depends on given command",
	["hidespec"] = "Allows you to change the visibility of the spectator list",
	["zones"] = "Allows you to show hidden zones and toggle them back off",
	["chat"] = "Sets or toggles the visibility of the chat. Output depends on given command",
	["muteall"] = "Sets mute status of players. Output depends on given command",
	["chatmuteall"] = "Sets chat mute status of players. Output depends on given command",
	["voicemute"] = "Mutes a given player by the given command",
	["playernames"] = "Toggles targetted player labels visibility.",
	["water"] = "Toggles the state of water reflection and water refraction.",
	["decals"] = "Clears the map of all bulletholes and blood",
	["sky"] = "Toggles the 3d skybox on a map for optimization of FPS",
	["toggle"] = "Toggles a client setting with the given identifier",
	["setopt"] = "Sets a client setting with the given identifier",
	["space"] = "Allows you to toggle holding space",
	["thirdperson"] = "Toggles thirdperson mode",
	
	["help"] = "Is the command you just entered. Shows a list of commands and their functions",
	["map"] = "Prints the details about the map that is currently on",
	["plays"] = "Shows how often the map has been played",
	["playinfo"] = "Shows details about maps",
	["wrpos"] = "Shows your position on the record list for your current style",
	["getwr"] = "Gets the #1 time for the current or given style",
	["average"] = "Gets the average time for the current or given style",
	["hop"] = "Quickly changes from server",
	["about"] = "Shows information about the gamemode you're playing",
	["tutorial"] = "Opens a YouTube Video Tutorial in the Steam Browser",
	["website"] = "Opens our website in the Steam Browser",
	["youtube"] = "Opens a YouTube Channel where a lot of our runs are uploaded",
	["forum"] = "Opens our forum in the Steam Browser",
	["thread"] = "Opens Facepunch on the thread with more info about this gamemode",
	["version"] = "Opens the latest change log in the Steam Browser",
	
	["n"] = "Change style to Normal",
	["sw"] = "Change style to Sideways",
	["hsw"] = "Change style to Half-Sideways",
	["w"] = "Change style to W-Only",
	["a"] = "Change style to A-Only",
	["d"] = "Change style to D-Only",
	["s"] = "Change style to S-Only",
	["l"] = "Change style to Legit",
	["e"] = "Change style to Easy Scroll",
	[Core.Config.IsPack and "j" or "stam"] = "Change style to " .. (Core.Config.IsPack and "Jump Pack" or "Stamina"),
	["u"] = "Change style to Unreal",
	["bw"] = "Change style to Backwards",
	["lg"] = "Change style to Low Gravity",
	["b"] = "Change style to Bonus",
	["p"] = "Change style to Practice",
	
	["wrn"] = "Open Normal record list",
	["wrsw"] = "Open Sideways record list",
	["wrhsw"] = "Open Half-Sideways record list",
	["wrw"] = "Open W-Only record list",
	["wra"] = "Open A-Only record list",
	["wrd"] = "Open D-Only record list",
	["wrs"] = "Open S-Only record list",
	["wrl"] = "Open Legit record list",
	["wre"] = "Open Easy Scroll record list",
	["wr" .. (Core.Config.IsPack and "j" or "stam")] = "Open " .. (Core.Config.IsPack and "Jump Pack" or "Stamina") .. " record list",
	["wru"] = "Open Unreal record list",
	["wrbw"] = "Open Backwards record list",
	["wrlg"] = "Open Low Gravity record list",
	["wrb"] = "Open Bonus record list",
	
	["cp"] = "Opens the checkpoint menu",
	["normtop"] = "Opens the top list for the given style",
	["wrtop"] = "Opens the top list for WR holders on the given style",
	["jiggy"] = "Drop drop drop in the middle with a jiggy",
	["model"] = "Allows you to change your model",
	["female"] = "Magically changes your body into a female body",
	["remainingtries"] = "Counts the amount of restarts you use",
	["admin"] = "Opens a window where you can report to admins",
	
	["invalid"] = "Returns the invalid command print"
}

-- All style lookup variables
_L.Content.StyleLookup = {
	["n"] = Core.Config.Style.Normal, ["normal"] = Core.Config.Style.Normal, 
	["sw"] = Core.Config.Style.SW, ["sideways"] = Core.Config.Style.SW,
	["hsw"] = Core.Config.Style.HSW, ["halfsideways"] = Core.Config.Style.HSW,
	["w"] = Core.Config.Style["W-Only"], ["wonly"] = Core.Config.Style["W-Only"],
	["a"] = Core.Config.Style["A-Only"], ["aonly"] = Core.Config.Style["A-Only"],
	["d"] = Core.Config.Style["D-Only"], ["donly"] = Core.Config.Style["D-Only"],
	["s"] = Core.Config.Style["S-Only"], ["sonly"] = Core.Config.Style["S-Only"],
	["l"] = Core.Config.Style.Legit, ["legit"] = Core.Config.Style.Legit,
	["e"] = Core.Config.Style["Easy Scroll"], ["ez"] = Core.Config.Style["Easy Scroll"], ["easy"] = Core.Config.Style["Easy Scroll"], ["easyscroll"] = Core.Config.Style["Easy Scroll"],
	["stam"] = Core.Config.Style.Stamina, ["stamina"] = Core.Config.Style.Stamina,
	["j"] = Core.Config.Style["Jump Pack"], ["jp"] = Core.Config.Style["Jump Pack"], ["jump"] = Core.Config.Style["Jump Pack"], ["jumppack"] = Core.Config.Style["Jump Pack"],
	["u"] = Core.Config.Style.Unreal, ["unreal"] = Core.Config.Style.Unreal,
	["bw"] = Core.Config.Style.Backwards, ["back"] = Core.Config.Style.Backwards, ["backwards"] = Core.Config.Style.Backwards,
	["lg"] = Core.Config.Style["Low Gravity"], ["low"] = Core.Config.Style["Low Gravity"], ["lowgrav"] = Core.Config.Style["Low Gravity"], ["lowgravity"] = Core.Config.Style["Low Gravity"]
}

-- Links
_L.Content.ChannelLink = "http://www.youtube.com/user/GMSpeedruns/videos"
_L.Content.ThreadLink = "http://facepunch.com/showthread.php?t=1448806"
_L.Content.SurfLink = "https://www.youtube.com/watch?v=lYc52kwTNb8"

-- Surf additions
if Core.Config.IsSurf then
	Core.Config.Player.SurfWeapons = { ["weapon_glock"] = true, ["weapon_usp"] = true, ["weapon_knife"] = true, ["weapon_scout"] = true }
end