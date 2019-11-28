AddCSLuaFile( "cl_init.lua" )

ENT.Type             = "anim"
ENT.Base             = "base_anim"

function ENT:Initialize()    
    self:SetModel( "models/hunter/blocks/cube025x025x025.mdl" )

    local mi = self.min or Vector( 0, 0, 0 )
    local ma = self.max or Vector( 200, 200, 200 )

    self:SetMoveType( MOVETYPE_NONE )
    self:SetSolid( SOLID_VPHYSICS )

  	self:PhysicsInitBox( mi, ma )
  	self:SetCollisionBounds( mi, ma )

  	local phys = self:GetPhysicsObject()
	if IsValid( phys ) then
		phys:EnableMotion( false )
	end
end

function ENT:Think()
	local phys = self:GetPhysicsObject()
	if IsValid( phys ) then
		phys:EnableMotion( false )
	end 
end