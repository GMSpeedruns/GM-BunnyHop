-- Remove doors on bonus

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.FindByClass( "func_door" ) ) do
		if v:GetPos() == Vector( 2628, -1005, -2309 ) or v:GetPos() == Vector( 2337, -3007, -2309 ) or v:GetPos() == Vector( -1272, -2841, -2309 ) or v:GetPos() == Vector( -610.98, 261.03, -2847 ) then
			v:Remove()
		end
	end
	
	for k,v in pairs( ents.FindByClass( "weapon_scout" ) ) do
		v:Remove()
	end
end