-- Remove the weapon spawners at the start

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.FindByClass( "trigger_multiple" ) ) do
		if v:GetPos() == Vector( -64, -147, 61 ) or v:GetPos() == Vector( -64, -288, 61 ) then
			v:Remove()
		end
	end
	
	for k,v in pairs( ents.FindByClass( "env_entity_maker" ) ) do
		v:Remove()
	end
end