-- Remove nigger from bonus room

__HOOK[ "InitPostEntity" ] = function()
	for _,v in pairs( ents.FindByClass( "func_illusionary" ) ) do
		if v:GetPos() == Vector( -15368, 14720, 15424 ) then
			v:Remove()
		end
	end
end