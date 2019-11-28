function ENT:Initialize()
	local BBOX = (self.max - self.min) / 2

	self:SetModel( "models/hunter/blocks/cube025x025x025.mdl" )
	self:SetSolid( SOLID_BBOX )
	self:PhysicsInitBox( -BBOX, BBOX )
	self:SetCollisionBoundsWS( self.min, self.max )
	
	self:DrawShadow( false )
	self:SetNotSolid( true )
	self:SetNoDraw( false )
	
	local phys = self:GetPhysicsObject()
	if IsValid( phys ) then
		phys:Sleep()
		phys:EnableCollisions( false )
		phys:EnableMotion( false )
	end
	
	self:SetID( self.id )
	self:SetStyle( self.style )
	self:SetVel( math.Round( (self.vel or Vector( 0, 0, 0 )):Length2D() ) )
	
	for i = 1, #self.neighbors do
		local func = self[ "SetNeighbor" .. i ]
		self.Neighbor = func
		self:Neighbor( self.neighbors[ i ] )
	end
	
	self.Neighbor = nil
end