-- 3D Easy Life

__HOOK[ "InitPostEntity" ] = function()
	for _,ent in pairs( ents.FindByClass( "func_illusionary" ) ) do
		ent:Remove()
	end
end