local PlayerCenter = {}
PlayerCenter.Protocol = "PlayerCenter"
PlayerCenter.PlayerBits = Core.GetNetBits( game.MaxPlayers() )
PlayerCenter.Received = 0

local net = net
local VarNetFunc, NetFunc = {}, {}
local Cache = {}

for key,tab in pairs( Core.GetNetTypes() ) do
	NetFunc[ key ] = tab
end


function NetFunc.ReadPlayer()
	local id = net.ReadUInt( 16 )
	if not Cache[ id ] then
		Cache[ id ] = {}
	end
	
	for i = 1, net.ReadUInt( 8 ) do
		local v,k = NetFunc.ReadKey( net.ReadString() )
		Cache[ id ][ k ] = v
	end
end

function NetFunc.ReadKey( key )
	local Type, Bits = unpack( NetFunc[ key ] )
	return net[ "Read" .. Type ]( Bits ), key
end


function VarNetFunc.Get( ent, key, default )
	local id = ent:EntIndex()
	local item = Cache[ id ] and Cache[ id ][ key ]

	if item != nil then
		return item
	end

	return default
end

function VarNetFunc.Set() end
function VarNetFunc.SetPrivate() end
function VarNetFunc.GetPrivate( ... ) return VarNetFunc.Get( ... ) end

local ENTITY = FindMetaTable( "Entity" )
function ENTITY:VarNet( action, ... )
	return VarNetFunc[ action ]( self, ... )
end


local function ReceiveType( l )
	PlayerCenter.Received = PlayerCenter.Received + l

	for i = 1, net.ReadUInt( PlayerCenter.PlayerBits ) do
		NetFunc.ReadPlayer()
	end
end
net.Receive( PlayerCenter.Protocol, ReceiveType )

local function OnEntityRemoved( ent )
	local id = ent:EntIndex()
	if Cache[ id ] and LocalPlayer() != ent then
		Cache[ id ] = nil
	end
end
hook.Add( "EntityRemoved", "OnClearPlayer", OnEntityRemoved )


function Core.GetSessionBytes()
	return PlayerCenter.Received
end

function Core.GetNetVars( set )
	if set and engine.IsPlayingDemo() then
		Cache = set
	else
		return Cache
	end
end