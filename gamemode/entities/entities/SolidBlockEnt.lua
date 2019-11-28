ENT.Type = "anim"
ENT.Base = "base_anim"

if SERVER then
	AddCSLuaFile()
	
	function ENT:Initialize()
		self:SetModel( "models/hunter/blocks/cube025x025x025.mdl" )
		
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_VPHYSICS )

		self:PhysicsInitBox( self.min, self.max )
		self:SetCollisionBounds( self.min, self.max )

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
else
	local ViewZones = Core and Core.CVar( "showzones", "0" )
	local DAng, DCol = Angle( 0, 0, 0 ), Color( 255, 0, 255 )
	function ENT:Initialize()
		hook.Add( "PostDrawTranslucentRenderables", "RenderSolid" .. self:EntIndex(), function()
			if IsValid( self ) and self.IsDrawing then
				self:DrawBox( self:GetCollisionBounds() )
			end
		end )
	end
	
	function ENT:Draw() end
	function ENT:DrawBox( Min, Max )
		render.DrawWireframeBox( self:GetPos(), DAng, Min, Max, DCol, true )
	end
	
	function ENT:Think()
		local b = ViewZones:GetInt()
		if b != 1 then
			self.IsDrawing = nil
		elseif not self.IsDrawing then
			self.IsDrawing = true
			
			if Core.ZonePaint and Core.ZonePaint.Active then
				self.zonetype = 12
				Core.ZonePaint[ self:EntIndex() ] = self
			end
		end
	end
end