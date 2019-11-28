-- Remove jail teleports teleport

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if v:GetName() == "start_zusammen" then
			v:Remove()
		end
	end
	
	for k,v in pairs( ents.FindByClass( "trigger_multiple" ) ) do
		if v:GetName() == "ban" then
			v:Remove()
		end
	end
	
	for k,v in pairs( ents.FindByClass( "func_button" ) ) do
		v:Remove()
	end
end

local sf, sl = string.find, string.lower
__HOOK[ "EntityKeyValue" ] = function( ent, key, value )
	if ent:GetName() == "tele3" then
		if sf( sl( key ), "startdisabled" ) then
			return "0"
		end
	end
end