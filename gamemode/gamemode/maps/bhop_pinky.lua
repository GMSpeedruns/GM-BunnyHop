__HOOK[ "InitPostEntity" ] = function()
	-- Remove the weapon button
	for _,ent in pairs( ents.FindByClass( "func_button" ) ) do
		-- Find an entity named 'weapon_button'
		if ent:GetPos() == Vector( -189, -262, 68 ) then
			ent:Remove()
		end
	end
end