-- Allow triggers to teleport any team

local sf, sl = string.find, string.lower
__HOOK[ "EntityKeyValue" ] = function( ent, key, value )
	if ent:GetClass() == "filter_activator_team" then
		if sf( sl( key ), "filterteam" ) then
			return "1"
		end
	end
end