ENT.Type = "anim"
ENT.Base = "base_anim"

if SERVER then
	AddCSLuaFile( "shared.lua" )
	AddCSLuaFile( "client.lua" )
	include( "server.lua" )
elseif CLIENT then
	include( "client.lua" )
end

function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "ID" )
	self:NetworkVar( "Int", 1, "Style" )
	self:NetworkVar( "Int", 2, "Vel" )
	
	self:NetworkVar( "Vector", 0, "Neighbor1" )
	self:NetworkVar( "Vector", 1, "Neighbor2" )
	self:NetworkVar( "Vector", 2, "Neighbor3" )
	self:NetworkVar( "Vector", 3, "Neighbor4" )
	self:NetworkVar( "Vector", 4, "Neighbor5" )
	self:NetworkVar( "Vector", 5, "Neighbor6" )
	self:NetworkVar( "Vector", 6, "Neighbor7" )
	self:NetworkVar( "Vector", 7, "Neighbor8" )
	self:NetworkVar( "Vector", 8, "Neighbor9" )
end