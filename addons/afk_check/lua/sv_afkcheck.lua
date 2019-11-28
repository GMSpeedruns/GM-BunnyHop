-- Table containing all necessary data
local AFK = {}
local st, n = SysTime, next

-- Data tables
AFK.Tracker = {}
AFK.Points = {}
AFK.Connection = {}

-- Changable variables
AFK.MinimumPlayers = 0 -- Set this to 0 if you want to kick AFKs even if the server is almost empty
AFK.StartPoints = 3 -- Means the player can be kicked after being AFK for 15 minutes after at least 10 minutes in-game
AFK.TickInterval = 30 -- How often it ticks
AFK.CheckInterval = 5 * 60 -- Ticks every 5 minutes
AFK.LastCheck = st()


-- Subtract a point and check if the limit has been reached
function AFK.SubtractPoints( ply )
	AFK.Points[ ply ] = AFK.Points[ ply ] - 1
	
	-- Allows us to let the gamemode handle certain things before a player is kicked
	if ply.AFKFunc and ply:AFKFunc( AFK ) then
		-- Cancel out the kick if the gamemode returns true
		return false
	end
	
	if AFK.Points[ ply ] <= 0 then
		ply.DCReason = "AFK for too long"
		ply:Kick( "You have been kicked for being AFK too long" )
	end
end

-- Changes the time required to be kicked on-the-go
function AFK.SetDensity( count )
	if count > 26 then
		AFK.CheckInterval = 2 * 60
	elseif count > 20 then
		AFK.CheckInterval = 3 * 60
	elseif count > 10 then
		AFK.CheckInterval = 4 * 60
	else
		AFK.CheckInterval = 5 * 60
	end
end


-- Main loop
function AFK.Tick()
	-- Get a table with all players (excluding bots)
	local plys = player.GetHumans()
	local count = #plys
	AFK.SetDensity( count )
	
	if st() - AFK.LastCheck < AFK.CheckInterval then return end
	AFK.LastCheck = st()
	
	-- Check if we have enough players to check against
	if count >= AFK.MinimumPlayers then
		for i = 1, count do
			-- Get the player from the array at the specified index
			local ply = plys[ i ]
			
			-- If there's no tracker entry this means the player hasn't interacted for 5 minutes (or was unlucky and got triggered just on the edge)
			if not AFK.Tracker[ ply ] then
				-- Remove points and kick when required
				AFK.SubtractPoints( ply )
				
			-- Reset only if the player has low points
			elseif AFK.Points[ ply ] < AFK.StartPoints then
				-- Restores the points of the player to the starting amount
				AFK.Points[ ply ] = AFK.StartPoints
			end
		end
	end
	
	-- Reset the tracker for every player
	for k in n, AFK.Tracker do
		AFK.Tracker[ k ] = nil
	end
end
timer.Create( "AFK_Tick", AFK.TickInterval, 0, AFK.Tick )

-- Hook that is called on every key press
local function OnPlayerKey( ply, key )
	if ply:IsBot() then return end
	if not AFK.Tracker[ ply ] then AFK.Tracker[ ply ] = true end
end
hook.Add( "KeyPress", "AFK_OnPlayerKey", OnPlayerKey )

-- Some people only chat, so hook that too
local function OnPlayerChat( ply, text )
	if not AFK.Tracker[ ply ] then AFK.Tracker[ ply ] = true end
end
hook.Add( "PlayerSay", "AFK_OnPlayerChat", OnPlayerChat )

-- Whenever a new player joins, we set their points and connection time
local function OnPlayerCreated( ply )
	AFK.Points[ ply ] = AFK.StartPoints
	AFK.Connection[ ply ] = st()
end
hook.Add( "PlayerInitialSpawn", "AFK_OnPlayerCreated", OnPlayerCreated )