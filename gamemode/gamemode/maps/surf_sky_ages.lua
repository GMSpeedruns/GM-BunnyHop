-- Fix jail and moving parts

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.FindByClass( "logic_relay" ) ) do
		v:Remove()
	end
	
	for k,v in pairs( ents.FindByClass( "func_door" ) ) do
		if string.find( v:GetName(), "falldoor" ) then
			v:Fire( "Open" )
		end
	end
	
	for k,v in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if string.find( v:GetName(), "timeupteles" ) then
			v:Remove()
		end
	end
end

local sf, sl, tn = string.find, string.lower, tonumber
__HOOK[ "EntityKeyValue" ] = function( ent, key, value )
	if ent:GetClass() == "func_rotating" then
		if sf( sl( key ), "maxspeed" ) then
			return "0"
		elseif sf( sl( key ), "fanfriction" ) then
			return "0"
		elseif sf( sl( key ), "spawnflags" ) then
			return "1024"
		end
	elseif ent:GetClass() == "func_door" then
		if sf( sl( key ), "wait" ) then
			if tn( value ) == 3 then
				return "-1"
			end
		end
	end
end