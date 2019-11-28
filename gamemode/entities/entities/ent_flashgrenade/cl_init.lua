include( "shared.lua" )

function ENT:Initialize()
end

function ENT:Think()
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:IsTranslucent()
	return true
end