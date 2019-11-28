-- Fix jail and weird spawn position

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.FindByClass( "func_rot_button" ) ) do
		v:Remove()
	end
end

local sf, sl, tn = string.find, string.lower, tonumber
__HOOK[ "EntityKeyValue" ] = function( ent, key, value )
	if ent:GetClass() == "trigger_teleport" then
		if sf( sl( key ), "target" ) and value == "tp_nakaz" then
			return "tp"
		end
	end
end