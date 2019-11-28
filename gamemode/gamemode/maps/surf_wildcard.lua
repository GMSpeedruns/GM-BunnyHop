-- Remove all jails

__HOOK[ "InitPostEntity" ] = function()
	for _,ent in pairs( ents.FindByClass( "logic_timer" ) ) do
		ent:Remove()
	end
	
	for _,ent in pairs( ents.FindByClass( "logic_case" ) ) do
		ent:Remove()
	end
	
	for _,ent in pairs( ents.FindByClass( "trigger_once" ) ) do
		ent:Remove()
	end
end