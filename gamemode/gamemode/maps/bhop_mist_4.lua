-- Removes crash and ugly shit on mist_4

__HOOK[ "EntityKeyValue" ] = function( ent, key, value )
	if string.sub( key, 1, 2 ) == "On" and string.find( value, "ShowHudHint" ) then
		ent.hudhint = true
	end
	
	if key == "OnMapSpawn" and value == "command,Command,exec bhopmist4.cfg,0,-1" then
		return ""
	end
end

__HOOK[ "InitPostEntity" ] = function()
	ents.FindByName( "timer2" )[ 1 ]:Remove()
	
	for k,v in pairs( ents.FindByName( "d1" ) ) do
		v:Remove()
	end
	
	for k,v in pairs( ents.FindByName( "d2" ) ) do
		v:Remove()
	end
	
	for k,v in pairs( ents.FindByName( "d3" ) ) do
		v:Remove()
	end
	
	for k,v in pairs( ents.FindByClass( "trigger_multiple" ) ) do
		if v.hudhint then
			v:Remove()
		end
	end
	
	for k,v in pairs( ents.FindByClass( "point_servercommand" ) ) do
		v:Remove()
	end
end