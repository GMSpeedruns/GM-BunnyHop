-- Harmony trash fix

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.FindByClass( "logic_*" ) ) do
		v:Remove()
	end
	
	for k,v in pairs( ents.FindByClass( "func_wall_toggle" ) ) do
		v:Remove()
	end
	
	for k,v in pairs( ents.FindByClass( "func_illusionary" ) ) do
		v:Remove()
	end
	
	for k,v in pairs( ents.FindByClass( "point_clientcommand" ) ) do
		v:Remove()
	end
	
	for k,v in pairs( ents.FindByClass( "shadow_control" ) ) do
		v:Remove()
	end
	
	for k,v in pairs( ents.FindByClass( "func_brush" ) ) do
		v:Remove()
	end
	
	for k,v in pairs( ents.FindByClass( "env_smokestack" ) ) do
		v:Remove()
	end
end