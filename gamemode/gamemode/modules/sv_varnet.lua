local PlayerCenter = {}
PlayerCenter.Protocol = "PlayerCenter"
PlayerCenter.PlayerBits = Core.GetNetBits( game.MaxPlayers() )

local net = net
local VarNetFunc, NetFunc = {}, {}
local Public, Private = {}, {}

-- Add all types to the NetFunc object
for key,tab in pairs( Core.GetNetTypes() ) do
	NetFunc[ key ] = tab
end


--[[
	Description: Writes all keys on a given player
--]]
function NetFunc.WritePlayer( id )
	local tab = Public[ id ] or {}
	net.WriteUInt( id, 16 )
	net.WriteUInt( table.Count( tab ), 8 )
	
	for key,value in pairs( tab ) do
		NetFunc.WriteKey( key, value )
	end
end

--[[
	Description: Writes a given set of keys from the given player
--]]
function NetFunc.WriteSelective( id, tab, send )
	net.WriteUInt( id, 16 )
	
	local keys = {}
	for key,value in pairs( tab ) do
		if not send or send[ key ] then
			keys[ key ] = value
		end
	end
	
	net.WriteUInt( table.Count( keys ), 8 )
	
	for key,value in pairs( keys ) do
		NetFunc.WriteKey( key, value )
	end
end

--[[
	Description: Writes a single key by using its stored function
--]]
function NetFunc.WriteKey( key, value )
	local Type, Bits = unpack( NetFunc[ key ] )
	net.WriteString( key )
	net[ "Write" .. Type ]( value, Bits )
end


--[[
	Description: Sends the public cache to the player for initial data
--]]
function VarNetFunc.Initial( ply )
	net.Start( PlayerCenter.Protocol )
	
	local players = player.GetAll()
	net.WriteUInt( #players, PlayerCenter.PlayerBits )
	
	for i = 1, #players do
		if players[ i ] != ply then
			NetFunc.WritePlayer( players[ i ]:EntIndex() )
		end
	end
	
	net.Send( ply )
end

--[[
	Description: Updates a given set of keys on a specific player
--]]
function VarNetFunc.UpdateKeys( ent, keys )
	net.Start( PlayerCenter.Protocol )
	net.WriteUInt( 1, PlayerCenter.PlayerBits )
	
	local send = #keys > 0 and {}
	for i = 1, #keys do
		send[ keys[ i ] ] = true
	end
	
	NetFunc.WriteSelective( ent:EntIndex(), Public[ ent:EntIndex() ] or {}, send )
	
	net.Broadcast()
end

--[[
	Description: Updates a given set of keys on multiple players
--]]
function VarNetFunc.UpdateKeysEx( sender, players, keys )
	net.Start( PlayerCenter.Protocol )
	net.WriteUInt( #players, PlayerCenter.PlayerBits )
	
	local send = #keys > 0 and {}
	for i = 1, #keys do
		send[ keys[ i ] ] = true
	end
	
	for i = 1, #players do
		NetFunc.WriteSelective( players[ i ]:EntIndex(), Public[ players[ i ]:EntIndex() ] or {}, send )
	end
	
	net.Broadcast()
end

--[[
	Description: Sets a variable exclusively accessible by the owning player
--]]
function VarNetFunc.SetPrivate( ent, key, value, target )
	-- Determine which is the target
	local send = ent:IsPlayer() and ent or target
	if not IsValid( send ) then return end
	
	-- Allocate table space
	local id = ent:EntIndex()
	if not Private[ id ] then
		Private[ id ] = {}
	end

	-- Update or create the entry
	Private[ id ][ key ] = value
	
	-- Write the data
	net.Start( PlayerCenter.Protocol )
	net.WriteUInt( 1, PlayerCenter.PlayerBits )
	
	NetFunc.WriteSelective( id, Private[ id ], { [key] = true } )
	
	net.Send( send )
end

--[[
	Description: Gets a private variable
--]]
function VarNetFunc.GetPrivate( ent, key, default )	
	-- Get the stored item
	local id = ent:EntIndex()
	local item = Private[ id ] and Private[ id ][ key ]
	
	-- ONLY if the item is a nil, return the default value
	if item != nil then
		return item
	end
	
	return default
end

--[[
	Description: Sets a variable value in the public cache
--]]
function VarNetFunc.Set( ent, key, value, send )
	-- Make sure we have a usable table
	local id = ent:EntIndex()
	if not Public[ id ] then
		Public[ id ] = {}
	end

	-- Update or create the entry
	Public[ id ][ key ] = value
	
	-- Write the data if necessary
	if send then
		net.Start( PlayerCenter.Protocol )
		net.WriteUInt( 1, PlayerCenter.PlayerBits )
		
		NetFunc.WriteSelective( id, Public[ id ], { [key] = true } )
		
		net.Broadcast()
	end
end

--[[
	Description: Retrieves a variable value from the cache
--]]
function VarNetFunc.Get( ent, key, default )
	-- Get the stored item
	local id = ent:EntIndex()
	local item = Public[ id ] and Public[ id ][ key ]
	
	-- ONLY if the item is a nil, return the default value
	if item != nil then
		return item
	end
	
	return default
end

--[[
	Description: Make the VarNetFunc table accessible on every entity
--]]
local ENTITY = FindMetaTable( "Entity" )
function ENTITY:VarNet( action, ... )
	return VarNetFunc[ action ]( self, ... )
end


--[[
	Description: Hook to clear out the data if we have a player that disconnected
--]]
local function OnEntityRemoved( ent )
	local id = ent:EntIndex()
	if Public[ id ] then Public[ id ] = nil end
	if Private[ id ] then Private[ id ] = nil end
end
hook.Add( "EntityRemoved", "OnClearPlayer", OnEntityRemoved )