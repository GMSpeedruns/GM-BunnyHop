-- Module documentation: https://github.com/Bromvlieg/gm_bromsock
-- Thank you Bromvlieg for making this, my fellow Nederlander

-- Let's first make sure we have a networking module
local Bootable = false
for _,f in pairs( file.Find( "lua/bin/*", "GAME" ) ) do
	if string.find( f, "bromsock", 1, true ) then
		Bootable = true
	end
end

-- Define config variables
Core.Config.Var.Add( "SocketPort", "socket_port", 4318, "The port the socket server will attempt to listen on" )

-- Proceed with loading
local Socket = {}
Socket.Module = Bootable and require( "bromsock" )
Socket.Port = Core.Config.Var.GetInt( "SocketPort" )
Socket.ContentTypes = { ["html"] = "text/html; charset=UTF-8", ["txt"] = "text/plain", ["jpg"] = "image/jpeg", ["css"] = "text/css", ["ico"] = "image/x-icon" }
Socket.SecretKey = Core.GetRandomString()
Socket.HTMLuaFuncs = {}
Socket.Received = 0
Socket.Requests = 0

-- Valid request paths (for security)
Socket.Paths = {
	["/"] = "index.html",
	["control"] = "control.html",
	["home"] = "home.html",
	["map"] = "map.html",
	["records"] = "records.html",
	["top"] = "top.html",
	["players"] = "players.html"
}

-- Validate the paths
for _,path in pairs( Socket.Paths ) do
	if not file.Exists( "web/" .. path, "DATA" ) then
		Core.PrintC( "[Error] Web file " .. path .. " couldn't be opened because it doesn't exist" )
	end
end

-- Get the HTMLua definitions from the file
if file.Exists( "web/definitions.lua", "DATA" ) then
	Socket.HTMLuaFuncs = include( "../data/web/definitions.lua" )
end


--[[
	Description: Initializes the sockets
--]]
function Socket.Init()
	if not Bootable then
		return Core.PrintC( "[Startup] Failed to load extension 'socket': missing gmsv_bromsock_*.dll module" )
	end
	
	local serv, listen = BromSock()
	if serv:Listen( Socket.Port ) then
		listen = true
	end

	serv:SetCallbackAccept( Socket.AcceptClient )
	serv:Accept()
	
	Socket.Bind = serv
	
	Core.Config.Var.Activate( "Socket", Socket )
	Core.PrintC( "[Startup] Extension 'socket' activated", listen and "Listening on " .. tostring( Socket.Bind ) or "Failed to listen on port " .. Socket.Port )
end
Core.PostInitFunc = Socket.Init

--[[
	Description: Accepts the client and assigns handlers
--]]
function Socket.AcceptClient( server, client )
	if not client then return end
	
	client:SetCallbackReceive( Socket.ReceiveClient )
	client:SetCallbackDisconnect( function() end )
	
	client:SetTimeout( 1000 )
	client:ReceiveUntil( "\r\n\r" )
	
	server:Accept()
end

--[[
	Description: Receives data from the given socket
--]]
function Socket.ReceiveClient( sock, packet )
	Socket.Requests = Socket.Requests + 1
	
	local headerdata = packet:ReadStringAll()
	local rawheaders = string.Explode( "\r\n", headerdata )
	
	local headers = {}
	local requestlinedata = nil
	for _,header in pairs( rawheaders ) do
		if not requestlinedata then
			requestlinedata = string.Explode( " ", header )
		end
		
		local split = string.Explode( ":", header )
		headers[ split[ 1 ] ] = #split > 1 and split[ 2 ] or ""
	end
	
	local method = string.lower( requestlinedata[ 1 ] )
	local path = string.Right( requestlinedata[ 2 ], #requestlinedata[ 2 ] - 1 )
	local httpver, args = string.lower( requestlinedata[ 3 ] ), {}
	local statuscode, filedata, contenttype = "200 OK"

	if string.find( path, "!", 1, true ) then
		local split = string.Explode( "!", path )
		if #split > 1 then
			path = table.remove( split, 1 )
			args = split
		end
	end

	if Socket.Paths[ path ] then
		filedata = file.Read( "web/" .. Socket.Paths[ path ], "DATA" )
	end
	
	if not filedata then
		contenttype = Socket.ContentTypes["html"]
		filedata = "<h2>404 - File not found</h2>"
		statuscode = "404 FILE NOT FOUND"
	else
		local exts = string.Explode( ".", Socket.Paths[ path ] )
		contenttype = Socket.ContentTypes[ exts[ #exts ] ]
	end
	
	if string.sub( Socket.Paths[ path ] or "", -4 ) == "html" then
		filedata = Socket.ParseHTMLua( filedata, args, function( newdata )
			Socket.MakeResponse( sock, path, statuscode, Socket.ContentTypes["html"], newdata )
		end )
	else
		Socket.MakeResponse( sock, path, statuscode, contenttype, filedata )
	end
end

--[[
	Description: Receives data from the given socket
--]]
function Socket.MakeResponse( sock, path, statuscode, contenttype, filedata )
	local out = BromPacket()
	out:WriteLine( "HTTP/1.1 " .. statuscode )
	out:WriteLine( "Connection: close" )
	out:WriteLine( "Content-Type: " .. (contenttype or "text/plain") )
	out:WriteLine( "Content-Length: " .. #filedata )
	
	if contenttype == "image/jpeg" then
		local pieces = string.Explode( "/", path )
		out:WriteLine( "Accept-Ranges: bytes" )
		out:WriteLine( "Content-Disposition: filename=" .. pieces[ #pieces ] )
	end
	
	out:WriteLine( "Server: bromsock" )
	out:WriteLine( "" )
	out:WriteStringRaw( filedata )
	
	Socket.Received = Socket.Received + out:OutPos()
	sock:Send( out, true )
end


--[[
	Description: Sequentially replaces all HTMLua functions with their returned data
--]]
function Socket.ParseHTMLua( str, globals, fCallback )
	local callbacks = { Completed = 0, Content = Socket.ParseControlFlow( str, globals ), Iterator = Socket.ParseIterator }
	for func,params in string.gmatch( callbacks.Content, "<%?Lua::(%a+)(%([%w*%p*]*%))%?>" ) do
		local tag = "<?Lua::" .. func .. params .. "?>"
		local args = Socket.ParseArguments( params, globals )
		
		callbacks[ #callbacks + 1 ] = { tag, func, args }
	end
	
	callbacks:Iterator( fCallback )
end

--[[
	Description: Separates the file by control testing
--]]
function Socket.ParseControlFlow( str, globals )
	local firstpoint, anycheck
	for func,params in string.gmatch( str, "<%?Check::(%a+)(%(%w*%))%?>" ) do
		local tag = "<?Check::" .. func .. params .. "?>"
		local func = Socket.HTMLChecks[ func ] or function() print( "Blank control function detected", func ) end
		
		if func( globals, string.sub( params, 2, -2 ) ) then
			anycheck = tag
		elseif not firstpoint then
			firstpoint = string.find( str, tag, 1, true )
		end
	end
	
	if anycheck then
		local start,pos = string.find( str, anycheck, 1, true )
		local breakpos = string.find( string.sub( str, pos ), "\n" )
		local remain = string.sub( str, pos + breakpos )
		local endpos = string.find( remain, "<?EndCheck?>", 1, true )
		
		return string.sub( remain, 1, endpos - 2 )
	elseif firstpoint then
		return string.sub( str, 1, firstpoint - 2 )
	else
		return str
	end
end

--[[
	Description: Parses the passed parameters to valid Lua objects
--]]
function Socket.ParseArguments( params, globals )
	local data = string.Replace( string.sub( params, 2, #params - 1 ), "_", " " )
	local split = string.Explode( ",", data )
	local args = { Globals = globals }
	
	for i = 1, #split do
		if tonumber( split[ i ] ) then
			args[ i ] = tonumber( split[ i ] )
		elseif string.sub( split[ i ], 1, 1 ) == "\"" and string.sub( split[ i ], -1 ) == "\"" then
			args[ i ] = tostring( string.sub( split[ i ], 2, -2 ) )
		end
	end
	
	return args
end

--[[
	Description: Iterates over the internal list and replaces after a callback has been triggered
--]]
function Socket.ParseIterator( list, fCallback )
	if list.Completed < #list then
		local data = list[ list.Completed + 1 ]
		local name = data[ 1 ]
		local func = data[ 2 ]
		local args = data[ 3 ]
		
		local exec = Socket.HTMLuaFuncs[ func ]
		if exec then
			exec( function( output )
				list.Content = string.Replace( list.Content, name, output or "Function Lua::" .. func .. "() did not return any content" )
				list.Completed = list.Completed + 1
				list:Iterator( fCallback )
			end, args or {} )
		else
			list.Content = string.Replace( list.Content, name, "Function Lua::" .. func .. "() is not part of the HTMLua library" )
			list.Completed = list.Completed + 1
			list:Iterator( fCallback )
		end
	else
		fCallback( list.Content )
	end
end


--[[
	Description: Gets the amount of packets received
--]]
function Core.GetPacketsReceived()
	return Socket.Requests, Socket.Received, Socket.SecretKey
end


--[[
	Description: Allows splitting of HTML files by executing checks on them
--]]
local ControlChecks = {}

-- Checks the amount of set global variables
function ControlChecks.GlobalCount( globals, count )
	return #globals == tonumber( count )
end

-- Compares the first global with the given value
function ControlChecks.GlobalCompare( globals, val )
	return globals[ 1 ] and tonumber( globals[ 1 ] ) == tonumber( val )
end

-- Check if the global variable is set to our secret key
function ControlChecks.CompareSecret( globals )
	return globals[ 1 ] == Socket.SecretKey
end

-- Set the variable to be accessible
Socket.HTMLChecks = ControlChecks