-- Remove some fucky triggers for crouch

local t1 = Vector( 15090, 6272, 744 )
local t2 = Vector( 14034, 6272, 744 )

__HOOK[ "InitPostEntity" ] = function()
	for _,ent in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if ent:GetPos() == t1 or ent:GetPos() == t2 then
			ent:Remove()
		end
	end
end