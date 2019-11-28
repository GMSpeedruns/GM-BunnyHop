-- Force to easy mode

__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.GetAll() ) do
		local name = v:GetName()
		if name == "red" then
			v:Fire( "TurnOff" )
		elseif name == "h" then
			v:Fire( "Disable" )
		elseif name == "right" then
			v:Fire( "Open" )
		elseif name == "left" then
			v:Fire( "Open" )
		elseif name == "movwe" then
			v:Fire( "Close" )
		elseif name == "HARDMODE" then
			v:Fire( "Break" )
		elseif name == "cc" then
			v:Fire( "Disable" )
		elseif name == "spawnlrgreen" then
			v:Fire( "LightOn" )
		end
	end

	for k,v in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if v:GetPos() == Vector( -11612, 2128, 10180 ) or v:GetPos() == Vector( -11612, 1968, 10180 ) then
			v:Remove()
		end
	end
end