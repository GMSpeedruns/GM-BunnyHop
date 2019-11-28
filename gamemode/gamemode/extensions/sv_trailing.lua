local Trailing = {}
Trailing.PointSize = Vector( 1, 1, 1 ) / 2
Trailing.LoadedStyles = {}

--[[
	Description: Initializes the extension
--]]
function Trailing.Init()
	if not Core.Config.Var.Present( "Bot" ) then
		return Core.PrintC( "[Startup] Failed to load extension 'trailing': missing 'bot' dependency" )
	end
	
	-- Add the hook
	hook.Add( "PlayerInitialSpawn", "PreventEntityTransmission", Trailing.HideAllFromPlayer )
	
	-- Add the command
	Core.AddCmd( { "trail", "trailbot", "bottrail", "botroute", "routecopy", "route", "router", "routing", "path", "botpath" }, Trailing.MainCommand )
	
	-- And load the text into _L
	Trailing.InitLang()
	
	-- Activate it
	Core.Config.Var.Activate( "Trailing", Trailing )
	Core.PrintC( "[Startup] Extension 'trailing' activated" )
end
Core.PostInitFunc = Trailing.Init


--[[
	Description: Prevents entity transmission for new players
--]]
function Trailing.HideAllFromPlayer( ply, manual )
	for _,ent in pairs( ents.FindByClass( "game_point" ) ) do
		ent:SetPreventTransmit( ply, true )
	end
	
	if manual then
		local ar = Core.Prepare( "Trailing/Update" )
		ar:UInt( 0, 8 )
		ar:Send( ply )
	end
end


--[[
	Description: Initializes the trailing systems
--]]
function Trailing.CreateOnStyle( ply, nStyle )
	local ox, oy, oz, ap, ay, info = Core.Ext( "Bot", "HandleSpecial" )( nil, "Fetch", nil, nStyle )
	if not ox or not info then return end
	
	-- Check if they're already spawned
	local fr = info and info.Time and #ox / info.Time or 0
	if info.Time and info.Time == Trailing.LoadedStyles[ nStyle ] then
		-- Make sure they can really load
		for _,ent in pairs( ents.FindByClass( "game_point" ) ) do
			if ent.style == nStyle then
				ent:SetPreventTransmit( ply, false )
			end
		end
		
		-- And update the style
		local ar = Core.Prepare( "Trailing/Update" )
		ar:UInt( nStyle, 8 )
		ar:UInt( info.StartFrame or Core.Ext( "Bot", "AverageStart" ), 12 )
		ar:Double( fr )
		ar:Send( ply )
		
		-- Also success! But differently
		return 1
	end
	
	-- Remove existing game_point entities by the same style
	for _,ent in pairs( ents.FindByClass( "game_point" ) ) do
		if ent.style == nStyle then
			ent:Remove()
		end
	end
	
	-- Loop over the table in steps of 100
	for i = 1, #ox, 100 do
		-- Creates the entity
		local ent = ents.Create( "game_point" )
		ent:SetPos( Vector( ox[ i ], oy[ i ], oz[ i ] ) )
		ent.min = ent:GetPos() - Trailing.PointSize
		ent.max = ent:GetPos() + Trailing.PointSize
		ent.style = nStyle
		ent.id = i
		ent.neighbors = {}
		
		-- Set the point velocity
		if info and info.Time and ox[ i + 1 ] then
			ent.vel = (Vector( ox[ i + 1 ], oy[ i + 1 ], oz[ i + 1 ] ) - ent:GetPos()) * fr
		end
		
		-- Get the neighbors
		for j = i + 10, i + 90, 10 do
			if ox[ j ] then
				ent.neighbors[ #ent.neighbors + 1 ] = Vector( ox[ j ], oy[ j ], oz[ j ] )
			end
		end
		
		-- And create it
		ent:Spawn()
	end
	
	-- And hide the newly created entities from everyone
	local list = ents.FindByClass( "game_point" )
	for _,p in pairs( player.GetHumans() ) do
		if p != ply then
			for _,ent in pairs( list ) do
				ent:SetPreventTransmit( p, true )
			end
		end
	end
	
	-- Allow the points to be drawn
	local ar = Core.Prepare( "Trailing/Update" )
	ar:UInt( nStyle, 8 )
	ar:UInt( info.StartFrame or Core.Ext( "Bot", "AverageStart" ), 12 )
	ar:Double( fr )
	ar:Send( ply )
	
	-- Save the loaded values
	Trailing.LoadedStyles[ nStyle ] = info.Time
	
	-- Success!
	return 0
end


--[[
	Description: Handles the bot trail command
--]]
function Trailing.MainCommand( ply, args )
	if #args > 0 then
		local lookup = Core.ContentText( "StyleLookup" )
		local found, nStyle = lookup[ args[ 1 ] ]
		
		if args[ 1 ] == "hide" or args[ 1 ] == "stop" or args[ 1 ] == "end" or args[ 1 ] == "exit" then
			Trailing.HideAllFromPlayer( ply, true )
			return Core.Print( ply, "General", Core.Text( "TrailFullExit" ) )
		elseif args[ 1 ] == "settings" or args[ 1 ] == "config" then
			local func = Core.GetCmd( "settings" )
			return func( ply )
		elseif args[ 2 ] == "tas" then
			found = nil
		end
		
		if not found then
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
		
		if not Core.IsValidStyle( nStyle ) then
			return Core.Print( ply, "General", Core.Text( "MiscInvalidStyle" ) )
		end
		
		local res = Trailing.CreateOnStyle( ply, nStyle )
		if res == 0 then
			Core.Print( ply, "General", Core.Text( "TrailStarted", Core.StyleName( nStyle ), "bot path has been generated and " ) )
		elseif res == 1 then
			Core.Print( ply, "General", Core.Text( "TrailStarted", Core.StyleName( nStyle ), "run " ) )
		else
			Core.Print( ply, "General", Core.Text( "TrailStartError" ) )
		end
	else
		Core.Print( ply, "General", Core.Text( "TrailCommandInfo", args.Key ) )
	end
end


--[[
	Description: Loads all extension related language
--]]
function Trailing.InitLang()
	-- Language
	Core.AddText( "TrailCommandInfo", "This command allows you to view bot routes in real-time and compare your run to it.\nPlease use this command in addition with a style ID. Example: /1; Normal\nIf you wish to exit previewing mode, simply type /1; hide/stop/end/exit" )
	Core.AddText( "TrailStarted", "The 1; 2;is now shown throughout the map!" )
	Core.AddText( "TrailFullExit", "You have left bot trailing mode" )
	Core.AddText( "TrailStartError", "Something went wrong when trying to load the bot route or there might not exist any bots on the given style." )

	-- Help commands
	local cmd = Core.ContentText( nil, true ).Commands
	cmd["trail"] = "Allows you to follow a bot route"
end