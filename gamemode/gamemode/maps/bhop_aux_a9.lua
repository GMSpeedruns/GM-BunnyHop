-- Aux Booster fixes

local boosters = {
	Vector( -13824, 10240, 8192 ),
	Vector( -11264, 10240, 8192 ),
	Vector( -8704, 10240, 8192 ),
	Vector( -6144, 10240, 8192 ),

	Vector( -13824, -8192, 3072 ),
	Vector( -11264, -8192, 3072 ),
	Vector( -8704, -8704, 3072 ),
	Vector( -6144, -7168, 3072 )
}

__HOOK[ "InitPostEntity" ] = function()
	for _,ent in pairs( ents.FindByClass( "trigger_push" ) ) do
		local pos = ent:GetPos()
		if table.HasValue( boosters, pos ) then
			local Min, Max = ent:GetCollisionBounds()
			Min = pos + Min
			Max = pos + Max
			local np = pos + Vector( 0, 0, 1024 )
			
			local boost = ents.Create( "BoosterZone" )
			boost:SetPos( np )
			boost.min = Vector( Min.x, Min.y, np.z - 128 )
			boost.max = Vector( Max.x, Max.y, np.z + 128 )
			boost.speed = Vector( 0, 0, 128 )
			boost:Spawn()
		end
	end
end