ENT.Type = "anim"
ENT.Base = "base_anim"

if SERVER then
	AddCSLuaFile()
	
	function ENT:Initialize()  
		self:SetSolid(SOLID_BBOX)
		
		local bbox = ( self.max - self.min ) / 2
	
		self:PhysicsInitBox( -bbox, bbox )
		self:SetCollisionBoundsWS( self.min,self.max )
	
		self:SetTrigger( true )
		self:DrawShadow( false )
		self:SetNotSolid( true )
		self:SetNoDraw( false )
	
		self.Phys = self:GetPhysicsObject()
		if IsValid( self.Phys ) then
			self.Phys:Sleep()
			self.Phys:EnableCollisions( false )
		end
	end

	function ENT:StartTouch( ent )  
		if IsValid( ent ) and ent:IsPlayer() then
			ent:SetPos( self.targetpos )
			ent:SetEyeAngles( self.targetang )
		end
	end
else
	function ENT:Initialize() 
	end 

	function ENT:Draw()
	end
end