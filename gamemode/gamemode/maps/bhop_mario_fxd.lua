-- Remove stupid things

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if v:GetPos() == Vector( -4460, 4313, 5337 ) then
			v:Remove()
		end
	end

	for k,v in pairs( ents.FindByClass( "func_rotating" ) ) do
		if v:GetPos() == Vector( 9841, 6043, -5289 ) or v:GetPos() == Vector( 9841, 7647, -5289 ) then
			v:Remove()
		end
	end
	
	for k,v in pairs( ents.FindByClass( "func_button" ) ) do
		if v:GetPos() == Vector( 9809, 9058.5, -5279 ) or v:GetPos() == Vector( 10787.5, 9325.5, -5335 ) then
			v:Remove()
		end
	end
	
	for k,v in pairs( ents.FindByClass( "func_door" ) ) do
		if v:GetPos() == Vector( 11269.5, 8894, -5480 ) then
			v:Fire( "Open" )
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
			if tn( value ) == 6 then
				return "-1"
			end
		end
	end
end