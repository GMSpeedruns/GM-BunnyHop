-- Fix jail and edit teleporters

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.FindByClass( "logic_relay" ) ) do
		v:Remove()
	end
	
	for k,v in pairs( ents.FindByClass( "trigger_push" ) ) do
		if v:GetPos() == Vector( -14896, 12042, 1864 ) then
			v:Remove()
		end
	end
end

local sf, sl, tr = string.find, string.lower
__HOOK[ "EntityKeyValue" ] = function( ent, key, value )
	if ent:GetClass() == "trigger_teleport" then
		if sf( sl( key ), "origin" ) then
			if value == "3537 951 -8240" then
				tr = ent
			end
		elseif sf( sl( key ), "target" ) then
			if value == "jail_dest_ct2" or value == "jail_dest_t2" then
				return "stage2_start"
			elseif value == "jail_dest_ct3" or value == "jail_dest_t3" then
				return "stage3_start"
			end
		elseif tr == ent then
			if key == "OnStartTouch" then
				return ""
			end
		end
	elseif ent:GetClass() == "filter_activator_team" then
		if sf( sl( key ), "filterteam" ) then
			return "1"
		end
	end
end