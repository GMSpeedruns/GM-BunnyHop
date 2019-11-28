-- Fixes for Guly to disable skipping

local rems = {
	Vector( -4848, -1268, -56 ),
	Vector( -1680.5, -2324, -84 ),
	Vector( 5320.5, -2736, 20 ),
	Vector( -4876, 1898, 31 ),
	Vector( -4156, 1896, 98.72 ),
	Vector( -4118, -1924, -44 )
}

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if v:GetPos() == Vector( 543.5, -980, -84 ) then
			v:SetKeyValue( "target", "level18" )
		end
		
		if table.HasValue( rems, v:GetPos() ) then
			v:Remove()
		end
	end
end