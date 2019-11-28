-- Stop rotating things from rotating

local sf, sl = string.find, string.lower
__HOOK[ "EntityKeyValue" ] = function( ent, key, value )
	if ent:GetClass() == "func_rotating" then
		if sf( sl( key ), "maxspeed" ) then
			return "0"
		elseif sf( sl( key ), "fanfriction" ) then
			return "0"
		elseif sf( sl( key ), "spawnflags" ) then
			return "1024"
		end
	end
end