-- Make Giga Citadel speedrunnable

local walls = {
	"tog_wall_5_1",
	"tog_wall_6",
	"tog_wall_7",
	"tog_wall_8",
	"tog_wall_9",
	"tog_wall_10",
	"tog_wall_1",
	"tog_wall_2",
	"tog_wall_3",
	"tog_wall_4",
	"tog_wall_11",
	"tog_wall_12"
}

local teles = {
	Vector( -1968, 6432, -352 ),
	Vector( -1696, 6576, -352 ),
	Vector( -2320, 7136, -352 ),
	Vector( -2464, 7408, -752 ),
	Vector( -1872, 6336, -1016 ),
	Vector( -1936, 7508, -340 ),
	Vector( -1888, 7064, -847.5 )
}

local doors = {
	Vector( -600, 1116, 76 ),
	Vector( -696, 1116, 76 ),
	Vector( -3232, -92, 136 ),
	Vector( -3232, -164, 136 ),
	Vector( -1944, 7213, -768 ),
	Vector( -1944, 7151, -768 )
}


__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if table.HasValue( teles, v:GetPos() ) then
			v:Remove()
		end
	end
	
	for k,v in pairs( ents.FindByClass( "func_wall_toggle" ) ) do
		if table.HasValue( walls, v:GetName() ) then
			v:Remove()
		end
	end
	
	for k,v in pairs( ents.FindByClass( "func_door" ) ) do
		if table.HasValue( doors, v:GetPos() ) then
			v:Remove()
		end
		
		if v:GetName() == "door_4" then
			v:Remove()
		end
	end
end
