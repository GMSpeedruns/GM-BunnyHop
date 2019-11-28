-- Make sure you spawn with a crowbar on PJ

__HOOK[ "InitPostEntity" ] = function()
	ents.FindByName( "knife" )[ 1 ]:Remove()

	local e = ents.Create( "game_player_equip" )
	e:SetName( "knife" )
	e:SetKeyValue( "weapon_crowbar", "1" )
	e:SetKeyValue( "spawnflags", "1" )
	e:Spawn()
end