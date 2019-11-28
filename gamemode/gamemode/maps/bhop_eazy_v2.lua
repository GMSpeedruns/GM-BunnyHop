-- Easy V2 removes

__HOOK[ "InitPostEntity" ] = function()
	for _,v in pairs( ents.FindByClass( "func_breakable" ) ) do
		if v:GetPos() == Vector( 4912, 832, 120 ) or v:GetPos() == Vector( 5200, 1312, 120 ) or v:GetPos() == Vector( 4912, 1184, 120 ) then
			v:Remove()
		end
	end
end