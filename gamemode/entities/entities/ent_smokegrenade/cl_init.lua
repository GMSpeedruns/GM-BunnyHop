include( "shared.lua" )
language.Add( "ent_smokegrenade", "Grenade" )

function ENT:Initialize()
end

function ENT:Draw()
	self.Entity:DrawModel()
end

function ENT:Think()
end

function ENT:IsTranslucent()
	return true
end
