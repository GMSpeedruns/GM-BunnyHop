ENT.Type = "anim"
ENT.Base = "base_anim"

if SERVER then
	AddCSLuaFile( "shared.lua" )
	AddCSLuaFile( "client.lua" )
	include( "server.lua" )
elseif CLIENT then
	include( "client.lua" )
end