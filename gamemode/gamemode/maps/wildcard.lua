-- Set custom map spawning angles

local MapTable = {
	["bhop_aztec_fixed"] = { 90, 180, -90 },
	["bhop_jouluuu"] = 270,
	["bhop_orgrimmar"] = 180,
	["bhop_jierdas"] = 180,
	["bhop_wob_yk"] = 180,
	["bhop_western"] = 180
}

__MAP[ "CustomEntitySetup" ] = function( Timer )
	local map = MapTable[ game.GetMap() ]
	if map then
		local bonuses, base = {}
		if type( map ) == "table" then
			base = table.remove( map, 1 )
			bonuses = map
		else
			base = map
		end
		
		if base then
			Timer.BaseAngles = Angle( 0, base, 0 )
		end
		
		if #bonuses > 0 then
			for _,i in pairs( Core.GetBonusIDs() ) do
				if bonuses[ i + 1 ] then
					Timer.BonusAngles[ i ] = Angle( 0, bonuses[ i + 1 ], 0 )
				end
			end
		end
	end
end