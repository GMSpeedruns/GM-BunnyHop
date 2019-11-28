-- Highen WJ triggers on Benchmark

local fakes = {
	{ Vector( 2597.83, 3049.45, 2298.33 ), Vector( 3352.07, 3867.13, 2300.33 ) },
	{ Vector( 2274.19, 3245.97, 2298.33 ), Vector( 2593.69, 3663.97, 2300.33 ) }
}

__HOOK[ "InitPostEntity" ] = function()
	GAMEMODE:SetDefaultStyle( Core.Config.Style.Legit, 16 )

	local target
	for _,v in pairs( ents.FindByClass( "trigger_teleport" ) ) do
		if v:GetPos() == Vector( 5592, 11296, 7120 ) or v:GetPos() == Vector( 5536, 11172, 7120 ) or v:GetPos() == Vector( -832.02, 1039.94, 3128 ) then
			v:SetPos( v:GetPos() + Vector( 0, 0, 8 ) )
			v:Spawn()
		elseif v:GetPos() == Vector( 3204, 3416, 2432 ) then
			target = ents.FindByName( v:GetSaveTable().target )[ 1 ]
		end
	end
	
	if not IsValid( target ) then return end
	for _,v in pairs( fakes ) do
		local f = ents.Create( "TeleporterEnt" )
		f:SetPos( (v[ 1 ] + v[ 2 ]) / 2 )
		f.min = v[ 1 ]
		f.max = v[ 2 ]
		f.targetpos = target:GetPos()
		f.targetang = target:GetAngles()
		f:Spawn()
	end
end