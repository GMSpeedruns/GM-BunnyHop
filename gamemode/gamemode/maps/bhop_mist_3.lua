-- Remove stupid unreliable doors on mist_3

local tester = table.HasValue
local doors = {
	Vector( 2736, -2895, 2688 ),
	Vector( 2896, -2895, 2688 ),
	Vector( 2846, -8856.5, 2712 ),
	Vector( 2778, -8856.5, 2712 ),
	Vector( 10350, -9424.5, 10256 ),
	Vector( 10282, -9424.5, 10256 )
}

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.FindByClass( "func_door" ) ) do
		if tester( doors, v:GetPos() ) then
			v:Remove()
		end
	end
	
	for k,v in pairs( ents.FindByClass( "trigger_multiple" ) ) do
		if v:GetPos() == Vector( 2896, -2878.5, 2672 ) or v:GetPos() == Vector( 2736, -2878.5, 2672 ) then
			v:Remove()
		end
	end
end
