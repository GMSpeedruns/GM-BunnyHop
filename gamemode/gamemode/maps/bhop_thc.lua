-- Remove that one stupid level on bhop_thc

local teles = {
	Vector( -6315, 7093, 75.5 ),
	Vector( -7006, 7059, 80 ),
	Vector( -7477, 7067, 80 ),
	Vector( -8199, 7151, 80 )
}

local movers = {
	Vector( -6315, 7093, 75.5 ),
	Vector( -7006, 7059, 80 ),
	Vector( -7477, 7067, 80 ),
	Vector( -8199, 7151, 80 ),
	Vector( -8707, 7090, 18 )
}

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if table.HasValue( teles, v:GetPos() ) then
			v:Remove()
		end
	end
	
	for k,v in pairs( ents.FindByClass( "func_movelinear" ) ) do
		if table.HasValue( movers, v:GetPos() ) then
			v:Remove()
		end
	end
	
	for k,v in pairs( ents.FindByClass( "path_track" ) ) do
		v:Remove()
	end
	
	for k,v in pairs( ents.FindByClass( "env_laser" ) ) do
		v:Remove()
	end
	
	for k,v in pairs( ents.FindByClass( "func_tanktrain" ) ) do
		v:Remove()
	end
end