-- Fix jail and moving parts

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.FindByClass( "func_button" ) ) do
		v:Remove()
	end
	
	for k,v in pairs( ents.FindByClass( "func_movelinear" ) ) do
		v:Remove()
	end
	
	for k,v in pairs( ents.FindByClass( "func_tracktrain" ) ) do
		v:Remove()
	end
	
	for k,v in pairs( ents.FindByClass( "path_track" ) ) do
		v:Remove()
	end
	
	for k,v in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if string.find( v:GetName(), "failerteleport" ) or string.find( v:GetName(), "winnerteleport" ) then
			v:Remove()
		end
	end
end

-- Get player table
local PLAYER = FindMetaTable( "Player" )
function PLAYER:IsStageResettable( id )
	return id != 6
end