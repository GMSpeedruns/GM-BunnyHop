__HOOK[ "InitPostEntity" ] = function()
	for k,v in pairs( ents.FindByClass( "func_rotating" ) ) do
		v:SetName( "StoppedNow" )
	end
end
