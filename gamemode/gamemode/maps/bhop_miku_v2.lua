-- Miku lag fix

__HOOK[ "InitPostEntity" ] = function()
	for _,v in pairs( ents.FindByClass( "prop_dynamic" ) ) do
		v:Remove()
	end
	
	for _,v in pairs( ents.FindByClass( "logic_timer" ) ) do
		v:Remove()
	end
	
	for _,v in pairs( ents.FindByClass( "logic_case" ) ) do
		v:Remove()
	end
end