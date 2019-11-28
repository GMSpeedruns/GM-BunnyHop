-- Booster power increasing

local sf, sl, tn, ts = string.find, string.lower, tonumber, tostring
__HOOK[ "EntityKeyValue" ] = function( ent, key, value )
	if ent:GetClass() == "trigger_push" then
		if sf( sl( key ), "speed" ) then
			return ts( tn( value ) + 80 )
		end
	end
end