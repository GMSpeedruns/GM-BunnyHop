-- Eman On Dropdown Part Fixes

__HOOK[ "InitPostEntity" ] = function()
	for _,ent in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		local vPos = ent:GetPos()
		if vPos.x == -1316 and (vPos.y > -10975 and vPos.y < -10841) then
			ent:SetPos( vPos + Vector( 0, 0, 12 ) )
			local Min, Max = ent:GetCollisionBounds()
			Min.y, Max.y = Min.y + 64, Max.y - 64
			ent:SetCollisionBounds( ent:GetPos(), Min, Max )
			ent:Spawn()
		end
	end
end