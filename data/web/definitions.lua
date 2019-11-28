-- Object containing all active functions
local HTMLua = {}

--[[
	Basic server request functions
--]]

-- Get the resolved server name
function HTMLua.GetServerName( call )
	call( Core.Config.FullName or "Unknown" )
end

-- Get the current map's name
function HTMLua.GetMapName( call )
	call( game.GetMap() )
end

-- Get the map details as printed in the map command
function HTMLua.GetMapDetails( call )
	call( Core.GetCmd( "map" )( { OutputSock = true }, {} ) )
end

-- Get the time left on a map
function HTMLua.GetMapTime( call )
	call( Core.ConvertTime( Core.GetTimeLeft() ) )
end

-- Returns the string of another pure HTML file
function HTMLua.IncludeFile( call, args )
	call( file.Read( "web/" .. args[ 1 ] .. ".html", "DATA" ) or "File '" .. args[ 1 ] .. "' not found!" )
end

-- Executes a debug print
function HTMLua.Print( call, args )
	call( args[ 1 ] or "nil" )
end

-- Translates RGB to HEX in Lua
function HTMLua.ToHex( c )
	local function f( v, h )
		while v > 0 do
			local i = math.fmod( v, 16 ) + 1
			v = math.floor( v / 16 )
			h = string.sub( "0123456789ABCDEF", i, i ) .. (h or "")
		end
		
		return h
	end
	
	return f( c.r ) .. f( c.g ) .. f( c.b )
end



--[[
	List generation functions
--]]

-- Gets a list of all maps, sorted alphabetically
function HTMLua.GenerateMaps( call )
	local list = Core.MapCheck( nil, true, true )
	local items = {}
	
	for map,data in SortedPairs( list ) do
		items[ #items + 1 ] = "\"" .. map .. "\":" .. (tonumber( data.nMultiplier ) or 0)
	end
	
	call( "{" .. string.Implode( ",", items ) .. "};" )
end

-- Gets a list of all available styles in the current game
function HTMLua.GenerateStyles( call )
	local items = {}
	for id,name in SortedPairs( Core.GetStyles() ) do
		items[ #items + 1 ] = id .. ":\"" .. name .. "\""
	end
	
	call( "{" .. string.Implode( ",", items ) .. "};" )
end

-- Gets a list of all jump types with top lists
function HTMLua.GenerateJumpTypes( call )
	local items = {}
	for id,name in SortedPairs( Core.Ext( "Stats", "GetJumpTypes" )() or {} ) do
		items[ #items + 1 ] = id .. ":\"" .. name .. "\""
	end
	
	call( "{" .. string.Implode( ",", items ) .. "};" )
end



--[[
	Actual data fetching functions
--]]

-- Gets all records in Javascript Object Notation
function HTMLua.GetRecordsObject( call, args )
	local details = args.Globals
	local map, style, mi, ma = details[ 1 ], tonumber( details[ 2 ] ), 1, 25
	if not Core.MapCheck( map ) or not style or not Core.IsValidStyle( style ) then
		if style == 0 then
			return HTMLua.GetTopForStyles( call, nil )
		else
			return call( "{};" )
		end
	end
	
	if tonumber( details[ 3 ] ) and tonumber( details[ 4 ] ) then
		mi = math.Clamp( tonumber( details[ 3 ] ), 1, tonumber( details[ 4 ] ) )
		ma = math.Clamp( tonumber( details[ 4 ] ), 1, tonumber( details[ 4 ] ) )
	end
	
	Core.DoRemoteWR( { OutputSock = function( list, count )
		local items = {}
		if list and count then
			local first, last
			if table.Count( list ) > 0 then
				for pos,_ in SortedPairs( list ) do if not first then first = pos end last = pos end
			else
				first, last = 0, 0
			end
			
			items[ #items + 1 ] = "\"map\":\"" .. map .. "\""
			items[ #items + 1 ] = "\"style\":" .. style
			items[ #items + 1 ] = "\"count\":" .. count
			items[ #items + 1 ] = "\"first\":" .. first
			items[ #items + 1 ] = "\"last\":" .. last
			
			for k,data in SortedPairs( list ) do
				items[ #items + 1 ] = "\"" .. k .. "\":[\"" .. data.szUID .. "\",\"" .. util.SteamIDTo64( data.szUID ) .. "\",\"" .. os.date( "%Y/%m/%d", data.nDate ) .. "\",\"" .. Core.ConvertTime( data.nTime ) .. "\"," .. string.Replace( data.vData, " ", "," ) .. "]"
			end
		end
		
		call( "{" .. string.Implode( ",", items ) .. "};" )
	end }, map, style, { mi, ma } )
end

-- Gets all the #1 times on the map for each style
function HTMLua.GetTopForStyles( call, args )
	local tab = Core.GetTopTimes()
	local items = {}
	
	if table.Count( tab ) > 0 then
		items[ #items + 1 ] = "\"map\":\"" .. game.GetMap() .. "\""
		items[ #items + 1 ] = "\"style\":0"
		items[ #items + 1 ] = "\"count\":" .. table.Count( tab )
		items[ #items + 1 ] = "\"first\":0"
		items[ #items + 1 ] = "\"last\":" .. table.Count( tab )
		
		for k,data in SortedPairs( tab ) do
			items[ #items + 1 ] = "\"" .. Core.StyleName( k ) .. "\":[\"" .. data.szUID .. "\",\"" .. util.SteamIDTo64( data.szUID ) .. "\",\"" .. os.date( "%Y/%m/%d", data.nDate ) .. "\",\"" .. Core.ConvertTime( data.nTime ) .. "\"," .. string.Replace( data.vData, " ", "," ) .. "]"
		end
	end
	
	call( "{" .. string.Implode( ",", items ) .. "};" )
end

-- Gets the data for the given jump type
function HTMLua.GetTopByType( call, args )
	local details, items = args.Globals, {}
	local nType, nStyle = tonumber( details[ 1 ] ), tonumber( details[ 2 ] )
	if not nType or not nStyle or not Core.IsValidStyle( nStyle ) then
		return call( "[];" )
	end
	
	-- Points top
	if nType == 0 then
		local data = Core.GetPlayerTop( nStyle )
		for i = 1, #data do
			items[ #items + 1 ] = "[\"" .. util.SteamIDTo64( data[ i ].szUID ) .. "\"," .. math.Round( data[ i ].nSum or 0, 2 ) .. "]"
		end
		
		call( "[" .. string.Implode( ",", items ) .. "];" )
		
	-- Race top
	elseif nType == 1 then
		if Core.Ext( "Race" ) then
			Core.Ext( "Race", "GetRaceTop" )( nStyle, function( data )
				for i = 1, #data do
					items[ #items + 1 ] = "[\"" .. util.SteamIDTo64( data[ i ].szUID ) .. "\"," .. data[ i ].nWins .. "," .. data[ i ].nStreak .. "]"
				end
				
				call( "[" .. string.Implode( ",", items ) .. "];" )
			end )
		else
			call( "[];" )
		end
		
	-- LJ top
	elseif nType == 2 then
		local data = Core.Ext( "Stats", "GetTopList" )( nStyle ) or {}
		for i = 1, #data do
			items[ #items + 1 ] = "[\"" .. util.SteamIDTo64( data[ i ].szUID ) .. "\"," .. data[ i ].nValue .. ",\"" .. os.date( "%Y/%m/%d", data[ i ].nDate ) .. "\"," .. string.Replace( data[ i ].vData, " ", "," ) .. "]"
		end
		
		call( "[" .. string.Implode( ",", items ) .. "];" )
	else
		call( "[];" )
	end
end

-- Gets details for all connected players
function HTMLua.GetPlayers( call )
	local items = {}
	local plys = player.GetHumans()
	for i = 1, #plys do
		local p = plys[ i ]
		local rt, rc = Core.ObtainRank( p.Rank, p.Style, true )
		local subitem = {}
		
		subitem[ #subitem + 1 ] = "\"" .. p:SteamID64() .. "\""
		subitem[ #subitem + 1 ] = "\"" .. Core.StyleName( p.Style ) .. "\""
		subitem[ #subitem + 1 ] = "\"" .. Core.ConvertTime( p.Record ) .. "\""
		subitem[ #subitem + 1 ] = "\"" .. Core.ConvertTime( (p.Tb and SysTime() - p.Tb) or (p.Tn and SysTime() - p.Tn) or 0 ) .. "\""
		subitem[ #subitem + 1 ] = "\"" .. rt .. "\""
		subitem[ #subitem + 1 ] = "\"" .. HTMLua.ToHex( rc ) .. "\""
		subitem[ #subitem + 1 ] = "\"" .. Core.GetAccessName( Core.GetAdminAccess( p ) ) .. "\""
		subitem[ #subitem + 1 ] = "\"" .. Core.ConvertTime( p.ConnectedAt and SysTime() - p.ConnectedAt or 0 ) .. "\""
		
		items[ #items + 1 ] = "[" .. string.Implode( ",", subitem ) .. "]"
	end
	
	call( "[" .. string.Implode( ",", items ) .. "];" )
end



--[[
	Admin panel control functions
--]]

-- Gets all the latest reports
function HTMLua.ShowLatestReports( call )
	local quick = {}
	for _,v in pairs( Core.ReportTypes ) do
		quick[ v[ 1 ] ] = v[ 2 ]
	end

	SQLPrepare(
		"SELECT nID, nType, szTarget, szComment, nDate, szReporter, szHandled, szEvidence FROM game_reports ORDER BY szHandled ASC, nID DESC LIMIT " .. (update or 0) .. ", 50",
		{ UseOptions = true, RawFormat = true }
	)( function( data, varArg )
		local makeNum, makeNull, out = tonumber, Core.Null, ""
		if Core.Assert( data, "nType" ) then
			local list = {}
			for j = 1, #data do
				local handle = makeNull( data[ j ]["szHandled"], "" )
				local demo = makeNull( data[ j ]["szEvidence"], "" )
				local target = makeNull( data[ j ]["szTarget"], "" )
				
				if handle != "" then data[ j ]["szComment"] = "[Handled by " .. handle .. "] " .. data[ j ]["szComment"] end
				if target != "" then data[ j ]["szComment"] = data[ j ]["szComment"] .. " (" .. target .. ")" end
				if demo != "" then data[ j ]["szComment"] = data[ j ]["szComment"] .. " (Includes evidence)" end
				
				list[ j ] = makeNum( data[ j ]["nID"] ) .. " - " .. data[ j ]["szComment"] .. " - " .. (quick[ makeNum( data[ j ]["nType"] ) ] or "Unknown") .. " - " .. os.date( "%Y-%m-%d %H:%M:%S", makeNum( data[ j ]["nDate"] ) or 0 ) .. " - " .. (data[ j ]["szReporter"] or "Console")
			end
			
			out = string.Implode( "<br />", list )
		end
		
		call( out )
	end )
end

-- Make the object accessible
return HTMLua