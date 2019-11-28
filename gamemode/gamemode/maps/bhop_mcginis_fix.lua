-- Remove trains and keep hiding platforms open

local tmr = {
	Vector( -6080, -1296, -1413.93 ),
	Vector( -6408, -1296, -1413.93 ),
	Vector( -6808, -1296, -1413.93 ),
	Vector( -6896, -1472, -1413.93 ),
	Vector( -6896, -1728, -1413.93 ),
	Vector( -6896, -2048, -1413.93 ),
	Vector( -6896, -2320, -1413.93 ),
}

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if v:GetPos() == Vector( 10240.1, -14144, -4816 ) or v:GetPos() == Vector( 10240.1, -14336, -4816 ) then
			v:Remove()
		end
	end

	for k,v in pairs( ents.FindByClass( "func_tanktrain" ) ) do
		if v:GetPos() == Vector( 10240.1, -14144, -4824 ) or v:GetPos() == Vector( 10240.1, -14336, -4824 ) then
			v:Remove()
		end
	end
	
	for k,v in pairs( ents.FindByClass( "path_track" ) ) do
		if string.find( v:GetName(), "train", 1, true ) then
			v:Remove()
		end
	end
	
	for k,v in pairs( ents.FindByClass( "trigger_multiple" ) ) do
		if table.HasValue( tmr, v:GetPos() ) then
			v:Remove()
		end
	end
	
	for k,v in pairs( ents.FindByClass( "func_door" ) ) do
		v:Fire( "Open" )
	end
end

local sf, sl, tn = string.find, string.lower, tonumber
__HOOK[ "EntityKeyValue" ] = function( ent, key, value )
	if ent:GetClass() == "func_door" then
		if sf( sl( key ), "wait" ) then
			if tn( value ) == 4 then
				return "-1"
			end
		end
	end
end