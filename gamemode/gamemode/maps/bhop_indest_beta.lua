-- Fix lag on Indest

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.FindByClass( "env_entity_maker" ) ) do
		v:Remove()
	end
end