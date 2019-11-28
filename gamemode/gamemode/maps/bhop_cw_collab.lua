-- Collab Booster Fix

__HOOK[ "EntityKeyValue" ] = function( ent, key, value )
	if ent:GetClass() == "trigger_multiple" then
		if key == "OnTrigger" then
			if value == "!activator,AddOutput,basevelocity 0 0 350,0,-1" then
				return "!activator,AddOutput,basevelocity 0 0 440,0,-1"
			end
		end
	end
end