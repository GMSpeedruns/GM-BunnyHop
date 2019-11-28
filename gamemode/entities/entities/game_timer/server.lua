local EnterFunc = {
	[0] = function( p, e ) e.Players[ p ] = p:RequestZonePermission( e, true ) p:ResetTimer( true, e ) end,
	[1] = function( p, e ) p:StopTimer( e ) end,
	[2] = function( p, e ) e.Players[ p ] = p:RequestZonePermission( e, nil, true ) p:BonusReset( true, e ) end,
	[3] = function( p, e ) p:BonusStop( e ) end,
	[4] = function( p, e ) p:StopAnyTimer( e ) end,
	[5] = function( p, e ) p:StartFreestyle( e ) end,
	[6] = function( p ) p:ResetTimer() end,
	[7] = function( p ) p:BonusReset() end,
	[10] = function( p, e ) p:ResetSpawnPosition( e ) end,
	[11] = function( p, e ) p:ProcessVelocityZone( e ) end
}

local LeaveFunc = {
	[0] = function( p, e ) e.Players[ p ] = nil p:StartTimer( e ) end,
	[2] = function( p, e ) e.Players[ p ] = nil p:BonusStart( e ) end,
	[4] = function( p, e ) p:StopAnyTimer( e ) end,
	[5] = function( p, e ) p:StopFreestyle( e ) end,
	[6] = function( p ) p:ResetTimer() end,
	[7] = function( p ) p:BonusReset() end,
	[10] = function( p, e ) p:ResetSpawnPosition( e, true ) end,
	[11] = function( p, e ) p:ProcessVelocityZone( e, true ) end,
	
	["Bot"] = function( p ) Core.Ext( "Bot", "HandleZoneTrigger" )( p ) end
}

function AddTimerHandler( id, enter, leave )
	EnterFunc[ id ] = enter
	LeaveFunc[ id ] = leave
end

function ENT:Initialize()
	local mi, ma = self.min, self.max
	if self.directbound then
		mi = mi + Vector( 16, 16, 0 )
		ma = ma - Vector( 16, 16, 0 )
	end
	
	local BBOX = (ma - mi) / 2
	self:SetSolid( SOLID_BBOX )
	self:PhysicsInitBox( -BBOX, BBOX )
	self:SetCollisionBoundsWS( mi, ma )
	
	self:SetTrigger( true )
	self:DrawShadow( false )
	self:SetNotSolid( true )
	self:SetNoDraw( false )

	self.Phys = self:GetPhysicsObject()
	
	if IsValid( self.Phys ) then
		self.Phys:Sleep()
		self.Phys:EnableCollisions( false )
	end
	
	self.Players = {}
end

function ENT:StartTouch( ent )
	if not IsValid( self ) or not IsValid( ent ) then return end
	if ent:IsPlayer() and ent:Team() != TEAM_SPECTATOR and not ent:IsBot() then
		local zone = self.zonetype
		if EnterFunc[ zone ] then
			EnterFunc[ zone ]( ent, self )
		end
	end
end

function ENT:EndTouch( ent )
	if not IsValid( self ) or not IsValid( ent ) then return end
	if ent:IsPlayer() and ent:Team() != TEAM_SPECTATOR then
		local zone = self.zonetype
		if ent:IsBot() then
			if zone == 0 or zone == 2 then
				LeaveFunc.Bot( ent )
			end
		elseif LeaveFunc[ zone ] then
			LeaveFunc[ zone ]( ent, self )
		end
	end
end