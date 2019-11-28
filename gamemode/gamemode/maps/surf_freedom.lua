-- Pause rotating end

if CLIENT then
	local main = hook.GetTable()["OnEntityCreated"]["SpawnPlayerCheck"]
	hook.Remove( "OnEntityCreated", "SpawnPlayerCheck" )
	hook.Add( "OnEntityCreated", "SpawnPlayerCheck", function( ent )
		if ent:GetClass() != "beam" or IsValid( ent:GetParent() ) then
			main( ent )
		end
	end )
	
	return
elseif SERVER then
	AddCSLuaFile()
end

local sf, sl = string.find, string.lower
__HOOK[ "EntityKeyValue" ] = function( ent, key, value )
	if ent:GetClass() == "func_rotating" then
		if sf( sl( key ), "maxspeed" ) then
			return "0"
		elseif sf( sl( key ), "fanfriction" ) then
			return "0"
		elseif sf( sl( key ), "spawnflags" ) then
			return "1024"
		end
	elseif ent:GetClass() == "func_lod" then
		if key == "DisappearDist" then
			return "10000"
		end
	end
end

__HOOK[ "PlayerInitialSpawn" ] = function( ply )
	ply:SendLua( "include(\"" .. Core.Config.BaseType .. "/gamemode/maps/surf_freedom.lua\")" )
end