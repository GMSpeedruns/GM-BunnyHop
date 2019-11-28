-- Crouch parts removal

__HOOK[ "InitPostEntity" ] = function()
	GAMEMODE:SetDefaultStyle( Core.Config.Style.Legit, 16 )

	for k,v in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if v:GetPos() == Vector( 4312, 3600, -3780 ) then
			v:Remove()
		end
	end
end