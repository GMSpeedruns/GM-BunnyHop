-- Remove annoying parts

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.FindByClass( "func_illusionary" ) ) do
		if v:GetPos() == Vector( 1824, -576, -312 ) then
			v:Remove()
		end
	end
	
	for k,v in pairs( ents.FindByClass( "func_door" ) ) do
		v:Remove()
	end
end