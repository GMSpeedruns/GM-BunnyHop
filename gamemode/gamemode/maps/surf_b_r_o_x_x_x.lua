-- Broxxx removing rotating stuff

if CLIENT then
	local main = hook.GetTable()["OnEntityCreated"]["SpawnPlayerCheck"]
	hook.Remove( "OnEntityCreated", "SpawnPlayerCheck" )
	hook.Add( "OnEntityCreated", "SpawnPlayerCheck", function( ent )
		if ent:GetClass() != "env_spritetrail" then
			main( ent )
		end
	end )
	
	return
elseif SERVER then
	AddCSLuaFile()
end

__HOOK[ "InitPostEntity" ] = function()
	for _,v in pairs( ents.FindByClass( "func_breakable" ) ) do
		if v:GetPos() == Vector( -3634.52, -1026, -990 ) then
			v:Remove()
		end
	end
	
	for _,v in pairs( ents.FindByClass( "func_rotating" ) ) do
		if v:GetPos() == Vector( -3634.69, -1024, -987.5 ) or v:GetPos() == Vector( -3634.6, -1024, -987.5 ) then
			v:Remove()
		end
	end
	
	for _,v in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if v:GetPos() == Vector( -3641.41, -1026, -990 ) then
			v:Remove()
		end
	end
end

-- And allow trails
__HOOK[ "PlayerInitialSpawn" ] = function( ply )
	ply:SendLua( "include(\"" .. Core.Config.BaseType .. "/gamemode/maps/surf_b_r_o_x_x_x.lua\")" )
end