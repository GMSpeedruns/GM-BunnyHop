-- Remove doors on bonus

local doors = {
	Vector( -15544, -10576, 180 ),
	Vector( -7696, -8208, 172 ),
	Vector( -11840, -3352, 370 ),
	Vector( -11000, -2448, 370 ),
	Vector( -7680, 1384, 114 )
}

local multi = {
	Vector( -15440, -10576, 176 ),
	Vector( -7736, -8208, 168 ),
	Vector( -11840, -3528, 368 ),
	Vector( -11064, -2448, 368 ),
	Vector( -7680, 1288, 112 )
}

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.FindByClass( "func_door" ) ) do
		if table.HasValue( doors, v:GetPos() ) then
			v:Fire( "Open" )
		end
	end
	
	for k,v in pairs( ents.FindByClass( "trigger_multiple" ) ) do
		if table.HasValue( multi, v:GetPos() ) then
			v:Remove()
		end
	end
end