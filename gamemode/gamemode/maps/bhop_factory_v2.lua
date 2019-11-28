-- Factory elevator fix

__HOOK[ "InitPostEntity" ] = function()
	ents.FindByName( "ascenseur1" )[ 1 ]:Remove()
	
	local tp = ents.FindInSphere( Vector( 496, 1728, -556 ), 1 )[ 1 ]
	tp:SetKeyValue( "target", "tp_destination18" )
	tp:Spawn()
end