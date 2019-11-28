-- Remove stupid rotating things

local sf, sl, tn = string.find, string.lower, tonumber
__HOOK[ "EntityKeyValue" ] = function( ent, key, value )
	if ent:GetClass() == "func_rotating" then
		if sf( sl( key ), "maxspeed" ) and tn( value ) == 25 then
			return "0"
		elseif sf( sl( key ), "fanfriction" ) and tn( value ) == 20 then
			return "0"
		elseif sf( sl( key ), "spawnflags" ) then
			return "1024"
		end
	end
end