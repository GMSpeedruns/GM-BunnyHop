-- Base data provider
local SQL = {}
SQL.Debug = Core.Config.Var.GetBool( "SQLDebug" )
SQL.DataType = Core.Config.Var.Get( "SQLType" )
SQL.Credentials = {
	Host = Core.Config.Var.Get( "SQLHost" ),
	User = Core.Config.Var.Get( "SQLUser" ),
	Pass = Core.Config.Var.Get( "SQLPass" ),
	Port = Core.Config.Var.GetInt( "SQLPort" ),
	ID = Core.Config.Var.GetInt( "ServerID" ),
	Prefix = Core.Config.Var.Get( "SQLPrefix" ),
	Database = Core.Config.Var.Get( "SQLDatabase" )
}

-- Networked strings
util.AddNetworkString( "SecureTransfer" )
util.AddNetworkString( "BinaryTransfer" )
util.AddNetworkString( "KeyDataTransfer" )
util.AddNetworkString( "PlayerCenter" )
util.AddNetworkString( "QuickNet" )
util.AddNetworkString( "QuickPrint" )

-- Validation functions

--[[
	Description: Asserts whether or not a result from a data query is valid
--]]
function Core.Assert( varType, szType )
	if varType and type( varType ) == "table" and varType[ 1 ] and type( varType[ 1 ] ) == "table" and varType[ 1 ][ szType ] then
		return true, varType[ 1 ][ szType ]
	end

	return false, nil
end

--[[
	Description: Makes sure an entry for the database isn't NULL
--]]
function Core.Null( varInput, varAlternate )
	if varInput and varInput != "NULL" then
		return varInput
	end

	return varAlternate
end

--[[
	Description: Adds all available resources to the download queue
--]]
function Core.AddResources( id )
	-- Add base images
	resource.AddFile( "materials/" .. id .. "/timer.png" )
	resource.AddFile( "materials/" .. id .. "/hud_layout.png" )
	resource.AddFile( "materials/" .. id .. "/hud_pointer.png" )

	-- Add all rank identifiers
	for i = 1, 7 do
		resource.AddFile( "materials/" .. id .. "/rank" .. i .. ".png" )
	end

	-- And the golden rank ring
	resource.AddFile( "materials/" .. id .. "/rankring.png" )

	-- Special icons
	for i = 1, 3 do
		resource.AddFile( "materials/" .. id .. "/special" .. i .. ".png" )
	end

	-- Base special rank icon
	resource.AddFile( "materials/" .. id .. "/specialbase.png" )

	-- Zones
	for _,i in pairs( { 0, 1, 2, 3, 5, "w" } ) do
		resource.AddFile( "materials/" .. id .. "/zone/l" .. i .. ".vmt" )
		resource.AddFile( "materials/" .. id .. "/zone/l" .. i .. ".vtf" )
		resource.AddFile( "materials/" .. id .. "/zone/l" .. i .. "s.vtf" )
	end

	-- Add the font file for the HUD and GUI
	resource.AddFile( "resource/fonts/latoregular.ttf" )
end

--[[
	Description: Allows writing fancy text with colored prefixes
--]]
function Core.PrintC( pref, ... )
	local rest = { ... }
	if not Core.Config.IsDebug then return end

	-- Check which prefix the message carries
	for p,c in pairs( Core.Config.Prefixes ) do
		if string.find( pref, p, 1, true ) then
			local remain = string.sub( pref, string.find( pref, "] ", 1, true ) + 2, #pref )
			table.insert( rest, 1, remain )
			table.insert( rest, 1, Color( 255, 255, 255 ) )
			table.insert( rest, 1, p )
			table.insert( rest, 1, c )

			break
		end
	end

	-- Add additional tabs
	local i = 1
	while i < #rest do
		if type( rest[ i + 1 ] ) != "table" and type( rest[ i ] ) != "table" and rest[ i ] != "\t" then
			table.insert( rest, i + 1, "\t" )
		end

		i = i + 1
	end

	-- Print with trailing newline
	MsgC( unpack( rest ) )
	MsgC( "\n" )
end

-- Networking code

--[[
	Description: Sends data over the main network connection to the given player or players
--]]
local net, nets = net, {}
function Core.Send( ply, szAction, ... )
	local arg = { ... }
	net.Start( "SecureTransfer" )
	net.WriteString( szAction )

	-- Write the given data correctly
	if arg[ 1 ] and type( arg[ 1 ] ) == "table" then
		net.WriteBit( true )
		net.WriteTable( arg[ 1 ] )
	elseif arg[ 1 ] then
		net.WriteBit( true )
		net.WriteTable( arg )
	elseif not arg[ 1 ] then
		net.WriteBit( false )
	end

	net.Send( ply )
end

--[[
	Description: Broadcasts a network message, optionally excluding varExlude
--]]
function Core.Broadcast( szAction, varArgs, varExclude )
	net.Start( "SecureTransfer" )
	net.WriteString( szAction )

	-- See if we need to write a table
	if varArgs and type( varArgs ) == "table" then
		net.WriteBit( true )
		net.WriteTable( varArgs )
	else
		net.WriteBit( false )
	end

	-- Send to the selected targets
	if varExclude and (type( varExlude ) == "table" or (IsValid( varExclude ) and varExclude:IsPlayer())) then
		net.SendOmit( varExclude )
	else
		net.Broadcast()
	end
end

--[[
	Description: Easy printing for the server side
--]]
function Core.Print( plys, szPrefix, szText )
	net.Start( "QuickPrint" )
	net.WriteString( szPrefix )
	net.WriteString( szText )

	-- Determine the type of sending
	if plys then
		net.Send( plys )
	else
		net.Broadcast()
	end
end

--[[
	Description: Prepares a table with easy-access functions for net sending
--]]
function Core.Prepare( szType, varPattern )
	-- Open and add the type identifier
	nets:Open()
	nets:String( szType )

	-- Check for pattern
	if varPattern then
		nets:Pattern( szType, varPattern )
	end

	-- And return the easy-object
	return nets
end


-- Prepared network statements
nets.Int = function( t, n, b ) net.WriteInt( n, b or 32 ) end
nets.UInt = function( t, n, b ) net.WriteUInt( n, b or 32 ) end
nets.String = function( t, s ) net.WriteString( s ) end
nets.Bit = function( t, b ) net.WriteBit( b ) end
nets.Double = function( t, n ) net.WriteDouble( n ) end
nets.Color = function( t, c ) net.WriteColor( c ) end
nets.ColorText = function( t, d ) t.Cache[ "Internal/ColorText" ]( t, d ) end
nets.Open = function() net.Start( "QuickNet" ) end
nets.Pattern = function( t, s, v ) t.Cache[ s ]( t, v ) end
nets.Send = function( t, p ) net.Send( p ) end
nets.Broadcast = function() net.Broadcast() end

-- Centralized data transmission patterns
nets.Cache = {}
nets.Cache["Client/Entities"] = function( ar, args )
	if #args > 1 then
		ar:Bit( true )
	else
		ar:Bit( false )
	end

	ar:UInt( table.Count( args[ 1 ] ), Core.GetNetBits( Core.Config.MaxZones ) )

	for index,data in pairs( args[ 1 ] ) do
		ar:UInt( index, 16 )

		if data[ 2 ] then
			ar:Bit( true )
			ar:Int( data[ 2 ] or 0, 12 )
			ar:Int( data[ 1 ] or 0, 8 )
			ar:Bit( data[ 3 ] )
		else
			ar:Bit( false )
			ar:Int( data[ 1 ] or 0, 8 )
			ar:Bit( data[ 3 ] )
		end
	end

	if #args > 1 then
		ar:UInt( table.Count( args[ 2 ] ), 8 )

		for name,id in pairs( args[ 2 ] ) do
			ar:String( name )
			ar:UInt( id, 8 )
		end

		ar:UInt( #args[ 3 ], 16 )

		for i = 1, #args[ 3 ] do
			ar:UInt( args[ 3 ][ i ], 16 )
		end

		ar:UInt( table.Count( args[ 4 ] ), 16 )

		for nid,bh in pairs( args[ 4 ] ) do
			ar:UInt( nid, 16 )
			ar:UInt( bh, 20 )
		end

		ar:UInt( table.Count( args[ 5 ] ), 8 )

		for str,cv in pairs( args[ 5 ] ) do
			ar:String( str )
			ar:String( cv:GetString() )
		end
	end
end

nets.Cache["GUI/Build"] = function( ar, args )
	ar:String( args.ID )
	ar:String( args.Title )
	ar:UInt( args.X, 10 )
	ar:UInt( args.Y, 10 )
	ar:Bit( not not args.Mouse )
	ar:Bit( not not args.Blur )

	local data = args.Data
	if args.ID == "Records" then
		ar:Bit( not not data.IsEdit )

		if data.Map then
			ar:Bit( true )
			ar:String( data.Map )
		else
			ar:Bit( false )
		end

		if data.Started and data.TargetID then
			ar:Bit( true )
			ar:UInt( data.Started, 16 )
			ar:UInt( data.TargetID, 16 )
		else
			ar:Bit( false )
		end

		ar:UInt( data[ 2 ], 16 )
		ar:Int( data[ 3 ], 8 )
		ar:UInt( data[ 4 ] or 0, 16 )

		for id,v in pairs( data[ 1 ] ) do
			ar:UInt( id, 16 )
			ar:String( v.szUID or "" )
			ar:Double( v.nTime or 0 )
			ar:Double( v.nPoints or 0 )
			ar:UInt( v.nDate or 0, 32 )
			ar:String( v.vData or "" )
		end

		ar:UInt( 0, 16 )
	elseif args.ID == "Maps" then
		ar:Int( data.Style, 8 )

		if data.Type and data.Version then
			ar:Bit( true )
			ar:String( data.Type )
			ar:String( data.Command )
			ar:UInt( data.Version, 20 )
			ar:UInt( #data[ 1 ], 16 )

			local tab = data[ 1 ]
			for i = 1, #tab do
				ar:String( tab[ i ].szMap or "" )
				ar:Double( tab[ i ].nTime or 0 )
				ar:Double( tab[ i ].nPoints or 0 )
				ar:UInt( tab[ i ].nDate or 0, 32 )
			end
		else
			ar:Bit( false )

			if data.By then
				ar:Bit( true )
				ar:String( data.By )
			else
				ar:Bit( false )
			end

			ar:UInt( #data[ 1 ], 16 )

			local tab = data[ 1 ]
			for i = 1, #tab do
				ar:String( tab[ i ].szMap or "" )
				ar:Double( tab[ i ].nTime or 0 )
				ar:Double( tab[ i ].nPoints or 0 )
				ar:UInt( tab[ i ].nDate or 0, 32 )
				ar:Int( tab[ i ].nStyle or 1, 8 )
				ar:String( tab[ i ].vData or "" )
			end
		end
	elseif args.ID == "Top" then
		local tab = data[ 1 ]
		ar:UInt( data.ViewType, 4 )
		ar:UInt( data.Count or #tab, 16 )
		ar:Bit( not not data.IsEdit )

		if data.ViewType == 0 then
			for i = 1, #tab do
				ar:String( tab[ i ].szUID )
				ar:Double( tab[ i ].nSum )
				ar:UInt( tab[ i ].nLeft, 12 )
			end
		elseif data.ViewType == 1 then
			ar:UInt( data.Style, 8 )

			for i = 1, #tab do
				ar:String( tab[ i ].szUID )
				ar:UInt( tab[ i ].nStyle, 8 )
				ar:UInt( tab[ i ].nWins, 16 )
				ar:UInt( tab[ i ].nStreak, 16 )
			end
		elseif data.ViewType == 2 then
			ar:UInt( data.Total, 16 )
			ar:UInt( data.Style, 8 )
			ar:UInt( data.ID, 8 )

			if data.Pos then
				ar:Bit( true )
				ar:UInt( data.Pos, 16 )
			else
				ar:Bit( false )
			end

			for i = 1, #tab do
				ar:String( tab[ i ].szUID )
				ar:Double( tab[ i ].nTime )
			end
		elseif data.ViewType == 3 then
			for i = 1, #tab do
				ar:String( tab[ i ].szUID )
				ar:String( tab[ i ].szAppend )
				ar:Double( tab[ i ].nTime )
			end
		elseif data.ViewType == 4 then
			ar:UInt( data.Style, 8 )

			for i = 1, #tab do
				ar:String( tab[ i ].szUID )
				ar:Double( tab[ i ].nTime )
				ar:Double( tab[ i ].nReal )
				ar:UInt( tab[ i ].nDate, 32 )
			end
		elseif data.ViewType == 5 then
			for i = 1, #tab do
				ar:String( tab[ i ].szText )
				ar:Double( tab[ i ].nTime )
			end
		elseif data.ViewType == 6 then
			for i = 1, #tab do
				ar:String( tab[ i ].szUID )
				ar:String( tab[ i ].szPrepend )
				ar:Double( tab[ i ].nTime )
			end
		elseif data.ViewType == 7 then
			for steam,count in pairs( tab ) do
				ar:String( steam )
				ar:UInt( count, 10 )
			end
		elseif data.ViewType == 8 then
			ar:UInt( data.Style, 8 )

			for i = 1, math.Clamp( #tab, 0, data.Limit ) do
				ar:String( tab[ i ].szUID )
				ar:Double( tab[ i ].nValue )
				ar:UInt( tab[ i ].nDate, 32 )
				ar:String( tab[ i ].vData )
			end
		end
	end
end

nets.Cache["GUI/Update"] = function( ar, args )
	local data = args.Data
	ar:String( args.ID )

	if args.ID == "Records" then
		ar:UInt( data[ 2 ], 16 )

		for id,v in pairs( data[ 1 ] ) do
			ar:UInt( id, 16 )
			ar:String( v.szUID or "" )
			ar:String( v.szPlayer or "" )
			ar:Double( v.nTime or 0 )
			ar:Double( v.nPoints or 0 )
			ar:UInt( v.nDate or 0, 32 )
			ar:String( v.vData or "" )
		end

		ar:UInt( 0, 16 )
	elseif args.ID == "Top" then
		ar:UInt( #data[ 1 ], 16 )
		ar:UInt( data[ 2 ], 16 )
		ar:UInt( data[ 3 ], 16 )
		ar:UInt( data[ 4 ], 16 )

		for i = 1, #data[ 1 ] do
			ar:String( data[ 1 ][ i ].szUID )
			ar:Double( data[ 1 ][ i ].nTime )
		end
	end
end

nets.Cache["Global/Notify"] = function( ar, args )
	ar:String( args[ 1 ] )
	ar:String( args[ 2 ] )
	ar:String( args[ 3 ] )
	ar:UInt( args[ 4 ], 8 )
	ar:String( args[ 5 ] or "" )
end

nets.Cache["Internal/ColorText"] = function( ar, args )
	ar:UInt( #args, 8 )

	for i = 1, #args do
		if IsColor( args[ i ] ) then
			ar:Bit( true )
			ar:Color( args[ i ] )
		elseif type( args[ i ] ) == "string" then
			ar:Bit( false )
			ar:String( args[ i ] )
		end
	end
end

nets.Cache["RTV/VoteList"] = function( ar, args )
	for i = 1, 7 do
		ar:UInt( args[ i ], 8 )
	end
end

nets.Cache["Spectate/Timer"] = function( ar, args )
	ar:Bit( args[ 1 ] )

	if args[ 2 ] then
		ar:Bit( true )
		ar:Double( args[ 2 ] )
	else
		ar:Bit( false )
	end

	local i = args[ 1 ] and 4 or 3
	if args[ 1 ] then
		ar:String( args[ 3 ] or "" )
	end

	if args[ i ] then
		ar:Bit( true )
		ar:Double( args[ i ] )
	else
		ar:Bit( false )
	end

	local tab = args[ i + 1 ]
	if not tab then
		ar:UInt( 0, 4 )
	else
		if type( tab ) == "table" then
			ar:UInt( 2, 4 )
			ar:UInt( #tab, 8 )

			for i = 1, #tab do
				ar:String( tab[ i ] )
			end
		else
			ar:UInt( 1, 4 )
		end
	end
end


--- SQL ---

-- Local functions because these are used a lot and we need the query to be ready as quick as it can be
local GetTime, GetPairs, GetType, ToNum, ToStr = SysTime, pairs, type, tonumber, tostring
local StrSub, StrLen, StrRep = string.sub, string.len, string.gsub
local SqlStr, SqlQuery, SqlError, SqlOpt, SqlTest, SqlPrint, SqlConn, SqlErr, SqlLastErr, SqlLastFail, SqlReq = sql.SQLStr, sql.Query, sql.LastError, bit.bor, bit.band, Core.PrintC
local SqlNoResult = { ["SELECT"] = true, ["CREATE"] = true }

--[[
	Description: Initiates the (My)SQL startup sequence
--]]
local function SQLStart( fCallback )
	if SQL.DataType == "sqlite" then
		SqlPrint( "[SQL] Successfully connected to the SQLite server using default credentials" )
		SQL.CreateTables()
	elseif SQL.DataType == "tmysql4" then
		if not SqlReq then require( "tmysql4" ) SqlReq = true end
		SqlConn, SqlErr = tmysql.Connect( SQL.Credentials.Host, SQL.Credentials.User, SQL.Credentials.Pass, SQL.Credentials.Database, SQL.Credentials.Port )

		if SqlErr then
			SqlLastFail = true

			SqlPrint( "[SQL] Error", "Couldn't connect to the database", SqlErr )
			Core.Print( nil, "Timer", "SQL Server has gone away!" )
		else
			SqlPrint( "[SQL] Successfully connected to the MySQL server using tmysql4 with " .. SQL.Credentials.User .. "@" .. SQL.Credentials.Host )
			SQL.CreateTables()
		end

		if fCallback then
			fCallback( SqlErr and true )
		end

		SQLErr = nil
	elseif SQL.DataType == "mysqloo" then
		if not SqlReq then require( "mysqloo" ) SqlReq = true end
		SqlConn, SqlErr = mysqloo.connect( SQL.Credentials.Host, SQL.Credentials.User, SQL.Credentials.Pass, SQL.Credentials.Database, SQL.Credentials.Port )

		function SqlConn:onConnected()
			SqlPrint( "[SQL] Successfully connected to the MySQL server using mysqloo with " .. SQL.Credentials.User .. "@" .. SQL.Credentials.Host )
			SQL.CreateTables()

			if fCallback then
				fCallback()
			end
		end

		function SqlConn:onConnectionFailed( err )
			SqlLastFail = true

			SqlPrint( "[SQL] Error", "Couldn't connect to the database", err )
			Core.Print( nil, "Timer", "SQL Server has gone away!" )

			if fCallback then
				fCallback( true )
			end
		end

		SqlConn:connect()
	end
end


--[[
	Description: Replaces the object identifiers with the passed arguments
--]]
local function SQLParseArguments( str, args )
	for i = 1, #args do
		local sort = GetType( args[ i ] )
		local num = ToNum( args[ i ] )
		local arg = ""

		if sort == "string" and not num then
			arg = SqlStr( args[ i ] )
			if args.StripQuotes then
				arg = StrSub( arg, 2, StrLen( arg ) - 1 )
			end
		elseif (sort == "string" and num) or (sort == "number") then
			arg = args[ i ]
		else
			arg = SqlStr( ToStr( args[ i ] ) )
			SqlPrint( "[SQL] Error", "Parameter {" .. (i - 1) .. "} of type " .. sort .. " was parsed to a default value " .. arg .. " on query: " .. str )
		end

		str = StrRep( str, "{" .. i - 1 .. "}", arg )
	end

	return str
end

--[[
	Description: Parses the table name in the query
--]]
local function SQLParseQuery( str )
	-- Check if there's a need to replace things
	if SQL.Credentials.ID > 0 or SQL.Credentials.Prefix != "game" then
		for full,name in string.gmatch( str, "(game_(%a+))" ) do
			str = string.Replace( str, full, SQL.Credentials.Prefix .. (SQL.Credentials.ID > 0 and SQL.Credentials.ID or "") .. "_" .. name )
		end
	end

	return str
end

--[[
	Description: Prepares a query and formats it
--]]
function SQLPrepare( ... )
	local args, options = { ... }, {}
	for i = 1, #args do
		if GetType( args[ i ] ) == "table" and args[ i ].UseOptions then
			options = args[ i ]
			args[ i ] = nil
		end
	end

	local queries, objects = {}, {}
	for i = 1, #args do
		if GetType( args[ i ] ) == "string" then
			args[ i ] = SQLParseQuery( args[ i ] )

			if GetType( args[ i + 1 ] ) == "table" and #args[ i + 1 ] > 0 then
				for k,v in GetPairs( options ) do
					args[ i + 1 ][ k ] = v
				end

				queries[ #queries + 1 ] = SQLParseArguments( args[ i ], args[ i + 1 ] )
				objects[ #queries ] = args[ i + 1 ].VarObj
			else
				queries[ #queries + 1 ] = args[ i ]
			end
		else
			continue
		end
	end

	if options.GetQuery then
		return queries
	elseif #queries == 0 then
		return SQLVoid
	end

	if SQL.DataType == "sqlite" then
		local result = {}
		local sqlTimer = SQL.Debug and GetTime()
		for i = 1, #queries do
			local data = SqlQuery( queries[ i ] )
			if data then
				if not options.RawFormat then
					for id,item in GetPairs( data ) do
						for key,value in GetPairs( item ) do
							if ToNum( value ) then
								data[ id ][ key ] = ToNum( value )
							end
						end
					end
				end

				result[ i ] = data
			else
				if SqlNoResult[ StrSub( queries[ i ], 1, 6 ) ] then
					local szError = SqlError()
					if szError and szError != SqlLastErr then
						SqlLastErr = szError

						SqlPrint( "[SQL] Error", "Error on query", queries[ i ], "->", szError )
					end

					result[ i ] = false
				else
					result[ i ] = true
				end
			end
		end

		local varData = result
		varData.Objects = objects

		if SQL.Debug then
			SqlPrint( "[SQL] " .. #queries .. " " .. (#queries == 1 and "query" or "queries") .. " executed in " .. math.Round( GetTime() - sqlTimer, 2 ) .. "s" )

			for i = 1, #queries do
				print( "- " .. queries[ i ] )
			end
		end

		return function( fCallback, varArg ) fCallback( varData, varArg ) end
	elseif SQL.DataType == "tmysql4" then
		if not SqlConn then SqlPrint( "[SQL] Error", "Connection has not been established" ) return function( fCallback, varArg ) fCallback( false, varArg ) end end
		local function PollQuery( fCallback, varArg, varInner )
			local atid = varInner and varInner.AtID or 1
			local tabQuery = varInner and varInner.Queries or queries
			local sqlTimer = varInner and varInner.SqlTimer or GetTime()

			local function OnResult( data )
				if data[ 1 ].error then
					SqlPrint( "[SQL] Error", "Error on query", queries[ atid ], "->", data[ 1 ].error )

					if string.find( data[ 1 ].error, "gone away" ) then
						SqlLastFail = true
						Core.Print( nil, "Timer", "SQL Server has gone away!" )
					end
				else
					SqlLastFail = nil
				end

				local values = data[ 1 ].data or false
				if atid == #tabQuery then
					if SQL.Debug then
						SqlPrint( "[SQL] " .. #tabQuery .. " " .. (#tabQuery == 1 and "query" or "queries") .. " executed in " .. math.Round( GetTime() - sqlTimer, 2 ) .. "s" )

						for i = 1, #tabQuery do
							print( "- " .. tabQuery[ i ] )
						end
					end

					if varInner then
						varInner.Results[ varInner.AtID ] = values
						varInner.Results.Objects = varInner.Objects
						fCallback( varInner.Results, varArg )
					else
						fCallback( values, varArg )
					end
				else
					local inner = varInner or { AtID = atid, Queries = tabQuery, Results = {}, Objects = objects, SqlTimer = GetTime() }
					inner.Results[ inner.AtID ] = values
					inner.AtID = inner.AtID + 1

					PollQuery( fCallback, varArg, inner )
				end
			end

			SqlConn:Query( tabQuery[ atid ], OnResult )
		end

		return PollQuery
	elseif SQL.DataType == "mysqloo" then
		if not SqlConn then SqlPrint( "[SQL] Error", "Connection has not been established" ) return function( fCallback, varArg ) fCallback( false, varArg ) end end
		local function PollQuery( fCallback, varArg, varInner )
			local atid = varInner and varInner.AtID or 1
			local tabQuery = varInner and varInner.Queries or queries
			local sqlTimer = varInner and varInner.SqlTimer or GetTime()

			local q = SqlConn:query( tabQuery[ atid ] )
			if not q then
				local status = SqlConn:status()
				local function ContinueExecution( bFailed )
					tabQuery[ #tabQuery + 1 ] = options
					SQLPrepare( unpack( tabQuery ) )( fCallback, varArg )
				end

				SqlLastFail = true

				if varArg == SQLForce then
					fCallback( false )
				elseif status == mysqloo.DATABASE_NOT_CONNECTED then
					SQLStart( ContinueExecution )
				elseif status == mysqloo.DATABASE_CONNECTING then
					timer.Simple( 1, ContinueExecution )
				end
			else
				function q:onSuccess( data )
					SqlLastFail = nil

					if atid == #tabQuery then
						if SQL.Debug then
							SqlPrint( "[SQL] " .. #tabQuery .. " " .. (#tabQuery == 1 and "query" or "queries") .. " executed in " .. math.Round( GetTime() - sqlTimer, 2 ) .. "s" )

							for i = 1, #tabQuery do
								print( "- " .. tabQuery[ i ] )
							end
						end

						if varInner then
							varInner.Results[ varInner.AtID ] = data
							varInner.Results.Objects = varInner.Objects
							fCallback( varInner.Results, varArg )
						else
							fCallback( data, varArg )
						end
					else
						local inner = varInner or { AtID = atid, Queries = tabQuery, Results = {}, Objects = objects, SqlTimer = GetTime() }
						inner.Results[ inner.AtID ] = data
						inner.AtID = inner.AtID + 1

						PollQuery( fCallback, varArg, inner )
					end
				end

				function q:onError( error, sql )
					local status = SqlConn:status()
					local function ContinueExecution( bFailed )
						tabQuery[ #tabQuery + 1 ] = options
						SQLPrepare( unpack( tabQuery ) )( fCallback, varArg )
					end

					if varArg == SQLForce then
						fCallback( false )
					elseif status == mysqloo.DATABASE_NOT_CONNECTED then
						SqlLastFail = true
						SQLStart( ContinueExecution )
					elseif status == mysqloo.DATABASE_CONNECTING then
						timer.Simple( 1, ContinueExecution )
					else
						SqlPrint( "[SQL] Error", "Error on query", sql, "->", error )
					end
				end

				q:start()
			end
		end

		return PollQuery
	end
end
SQLVoid, SQLForce = function() end, "SQLForce"


-- SQL Table Mappings
local SqlFields = { INT = 0, DEC = 1, TXT = 2, BIG = 3, DAT = 4 }
local SqlType = { NONE = 0, PRIMARY = 1, INCREMENT = 2, NOTNULL = 4 }
local SqlStructure = {
	["game_admins"] = {
		{ "nID", SqlFields.INT, SqlOpt( SqlType.PRIMARY, SqlType.INCREMENT, SqlType.NOTNULL ) },
		{ "szSteam", SqlFields.TXT, SqlType.NOTNULL },
		{ "nLevel", SqlFields.INT, SqlType.NOTNULL }
	},

	["game_ljstats"] = {
		{ "nType", SqlFields.INT, SqlType.NOTNULL },
		{ "nValue", SqlFields.DEC, SqlType.NOTNULL },
		{ "szUID", SqlFields.TXT, SqlType.NOTNULL },
		{ "nDate", SqlFields.BIG, SqlType.NOTNULL },
		{ "vData", SqlFields.TXT, SqlType.NOTNULL }
	},

	["game_logs"] = {
		{ "nID", SqlFields.INT, SqlOpt( SqlType.PRIMARY, SqlType.INCREMENT, SqlType.NOTNULL ) },
		{ "szData", SqlFields.DAT, SqlType.NONE },
		{ "szDate", SqlFields.TXT, SqlType.NONE },
		{ "szAdminSteam", SqlFields.TXT, SqlType.NOTNULL },
		{ "szAdminName", SqlFields.TXT, SqlType.NONE }
	},

	["game_map"] = {
		{ "szMap", SqlFields.TXT, SqlOpt( SqlType.PRIMARY, SqlType.NOTNULL ) },
		{ "nMultiplier", SqlFields.INT, SqlType.NOTNULL },
		{ "nBonusMultiplier", SqlFields.TXT, SqlType.NONE },
		{ "nPlays", SqlFields.INT, SqlType.NOTNULL },
		{ "nOptions", SqlFields.INT, SqlType.NONE },
		{ "szDate", SqlFields.TXT, SqlType.NONE }
	},

	["game_notifications"] = {
		{ "nID", SqlFields.INT, SqlOpt( SqlType.PRIMARY, SqlType.INCREMENT, SqlType.NOTNULL ) },
		{ "szUID", SqlFields.TXT, SqlType.NOTNULL },
		{ "szMap", SqlFields.TXT, SqlType.NOTNULL },
		{ "szName", SqlFields.TXT, SqlType.NONE },
		{ "nStyle", SqlFields.INT, SqlType.NOTNULL },
		{ "nDifference", SqlFields.DEC, SqlType.NOTNULL },
		{ "nDate", SqlFields.BIG, SqlType.NOTNULL }
	},

	["game_racers"] = {
		{ "szUID", SqlFields.TXT, SqlType.NOTNULL },
		{ "nStyle", SqlFields.INT, SqlType.NOTNULL },
		{ "nWins", SqlFields.INT, SqlType.NOTNULL },
		{ "nStreak", SqlFields.INT, SqlType.NOTNULL }
	},

	["game_radio"] = {
		{ "nID", SqlFields.INT, SqlOpt( SqlType.PRIMARY, SqlType.INCREMENT, SqlType.NOTNULL ) },
		{ "szID", SqlFields.TXT, SqlType.NOTNULL },
		{ "szTitle", SqlFields.TXT, SqlType.NONE },
		{ "szArtist", SqlFields.TXT, SqlType.NONE },
		{ "szAlbum", SqlFields.TXT, SqlType.NONE },
		{ "nDuration", SqlFields.INT, SqlType.NOTNULL },
		{ "nRequests", SqlFields.INT, SqlType.NOTNULL },
		{ "nDate", SqlFields.BIG, SqlType.NOTNULL }
	},

	["game_reports"] = {
		{ "nID", SqlFields.INT, SqlOpt( SqlType.PRIMARY, SqlType.INCREMENT, SqlType.NOTNULL ) },
		{ "nType", SqlFields.INT, SqlType.NOTNULL },
		{ "szTarget", SqlFields.TXT, SqlType.NONE },
		{ "szComment", SqlFields.DAT, SqlType.NONE },
		{ "nDate", SqlFields.BIG, SqlType.NOTNULL },
		{ "szReporter", SqlFields.TXT, SqlType.NOTNULL },
		{ "szHandled", SqlFields.TXT, SqlType.NONE },
		{ "szEvidence", SqlFields.TXT, SqlType.NONE }
	},

	["game_stagetimes"] = {
		{ "szUID", SqlFields.TXT, SqlType.NOTNULL },
		{ "szMap", SqlFields.TXT, SqlType.NOTNULL },
		{ "nID", SqlFields.INT, SqlType.NOTNULL },
		{ "nStyle", SqlFields.INT, SqlType.NOTNULL },
		{ "nTime", SqlFields.DEC, SqlType.NOTNULL }
	},

	["game_tas"] = {
		{ "szUID", SqlFields.TXT, SqlType.NOTNULL },
		{ "szMap", SqlFields.TXT, SqlType.NOTNULL },
		{ "nStyle", SqlFields.INT, SqlType.NOTNULL },
		{ "nTime", SqlFields.DEC, SqlType.NOTNULL },
		{ "nReal", SqlFields.DEC, SqlType.NOTNULL },
		{ "nDate", SqlFields.BIG, SqlType.NOTNULL }
	},

	["game_times"] = {
		{ "szUID", SqlFields.TXT, SqlType.NOTNULL },
		{ "szMap", SqlFields.TXT, SqlType.NOTNULL },
		{ "nStyle", SqlFields.DEC, SqlType.NOTNULL },
		{ "nTime", SqlFields.DEC, SqlType.NOTNULL },
		{ "nPoints", SqlFields.DEC, SqlType.NOTNULL },
		{ "nDate", SqlFields.BIG, SqlType.NOTNULL },
		{ "vData", SqlFields.TXT, SqlType.NONE }
	},

	["game_zones"] = {
		{ "szMap", SqlFields.TXT, SqlType.NOTNULL },
		{ "nType", SqlFields.DEC, SqlType.NOTNULL },
		{ "vPos1", SqlFields.TXT, SqlType.NONE },
		{ "vPos2", SqlFields.TXT, SqlType.NONE }
	}
}

local SqlTranslate = {
	[0] = {
		"INTEGER",
		"int(11)"
	},

	[1] = {
		"INTEGER",
		"double"
	},

	[2] = {
		"TEXT",
		"varchar(255)"
	},

	[3] = {
		"INTEGER",
		"int(11)" -- In order to avoid the Year 2038 Unix bug set this to bigint, but I doubt that'll be a problem now
	},

	[4] = {
		"TEXT",
		"text"
	}
}

--[[
	Description: Creates all the required tables for the given data provider
--]]
function SQL.CreateTables()
	local nProvider = 1
	if SQL.DataType == "sqlite" then
		nProvider = 1
	elseif SQL.DataType == "tmysql4" or SQL.DataType == "mysqloo" then
		nProvider = 2
	end

	local queries = {}
	for szTable,tabFields in GetPairs( SqlStructure ) do
		local strQuery = ""
		if nProvider == 1 then
			strQuery = strQuery .. "CREATE TABLE IF NOT EXISTS " .. szTable .. " ("
		elseif nProvider == 2 then
			strQuery = strQuery .. "CREATE TABLE IF NOT EXISTS `" .. szTable .. "` ("
		end

		local szFields, szPrimary = {}
		for i = 1, #tabFields do
			local szPartial = ""
			local szName = tabFields[ i ][ 1 ]
			local nType = tabFields[ i ][ 2 ]
			local nOpt = tabFields[ i ][ 3 ]

			if nProvider == 1 then
				szPartial = szPartial .. "\"" .. szName .. "\" " .. SqlTranslate[ nType ][ nProvider ]

				if nOpt > 0 then
					local opts = {}
					if SqlTest( nOpt, SqlType.PRIMARY ) > 0 then
						opts[ #opts + 1 ] = "PRIMARY KEY"
					end

					if SqlTest( nOpt, SqlType.INCREMENT ) > 0 then
						opts[ #opts + 1 ] = "AUTOINCREMENT"
					end

					if SqlTest( nOpt, SqlType.NOTNULL ) > 0 then
						opts[ #opts + 1 ] = "NOT NULL"
					end

					szPartial = szPartial .. " " .. string.Implode( " ", opts )
				end

				szFields[ #szFields + 1 ] = szPartial
			elseif nProvider == 2 then
				szPartial = szPartial .. "`" .. szName .. "` " .. SqlTranslate[ nType ][ nProvider ]

				if nOpt > 0 then
					local opts = {}
					if SqlTest( nOpt, SqlType.NOTNULL ) > 0 then
						opts[ #opts + 1 ] = "NOT NULL"
					end

					if SqlTest( nOpt, SqlType.INCREMENT ) > 0 then
						opts[ #opts + 1 ] = "AUTO_INCREMENT"
					end

					if SqlTest( nOpt, SqlType.PRIMARY ) > 0 then
						szPrimary = "PRIMARY KEY (`" .. szName .. "`)"
					end

					szPartial = szPartial .. " " .. string.Implode( " ", opts )
				end

				szFields[ #szFields + 1 ] = szPartial
			end
		end

		if szPrimary then
			szFields[ #szFields + 1 ] = szPrimary
		end

		queries[ #queries + 1 ] = strQuery .. string.Implode( ", ", szFields ) .. ");"
	end

	SQLPrepare( unpack( queries ) )( SQLVoid )
end
Core.CreateSQLTables = SQL.CreateTables

--[[
	Description: Tests the SQL connection
--]]
function SQL.ResumeConnection()
	-- Collect garbage if required
	if bit.band( Core.Config.Var.GetInt( "ServerCollect" ), 1 ) > 0 then
		collectgarbage( "collect" )
	end

	if SQL.DataType == "sqlite" then return end
	local function OnResume( bFailed )
		Core.LoadRecords()
		Core.ReloadZones()
	end

	if not SqlConn then
		SqlPrint( "[SQL] Error", "SQL Connection doesn't seem to be active!" )
		SQLStart( OnResume )
	elseif SqlLastFail then
		SqlPrint( "[SQL] Error", "Last SQL query failed, attempting reconnect" )
		SqlLastFail = nil
		SQLStart( OnResume )
	end
end
Core.TestSQLConnection = SQL.ResumeConnection

-- Finally, try starting the SQL connection
SQLStart()
