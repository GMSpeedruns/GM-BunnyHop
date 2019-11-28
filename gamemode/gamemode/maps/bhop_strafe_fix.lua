-- Strafe Fix Crouch parts

local rem = {
Vector( -3946.5, -4732.5, 459 ),
Vector( -624.5, 3270, 4428 ),
}

local fake = {
	Vector( 460, 2871, 3837 ),
	Vector( 903, 3405, 3879 )
}

local c3 = {
	Vector( 461.5, 2861, 3936 ),
	Vector( 902.5, 3232, 4049 )
}

local c3target = nil

__HOOK[ "InitPostEntity" ] = function()
	GAMEMODE:SetDefaultStyle( Core.Config.Style["Easy Scroll"], 16 )

	for k,v in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if table.HasValue( rem, v:GetPos() ) then
			v:Remove()
		elseif v:GetPos() == Vector( 681.5, 3138, 3941.5 ) then
			v:Remove()
			c3target = ents.FindByName( v:GetSaveTable().target )[ 1 ]
		end
	end
	
	for k,v in pairs( ents.FindByClass( "trigger_multiple" ) ) do
		if v:GetPos() == Vector( -6883, 9870, -4647 ) then
			v:Remove()
		end
	end
	
	local f = ents.Create( "TeleporterEnt" )
	f:SetPos( (fake[ 1 ] + fake[ 2 ]) / 2 )
	f.min = fake[ 1 ]
	f.max = fake[ 2 ]
	f.targetpos = c3target:GetPos()
	f.targetang = c3target:GetAngles()
	f:Spawn()
end