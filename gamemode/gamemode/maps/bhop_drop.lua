-- Set custom respawning

local PLAYER = FindMetaTable( "Player" )
local StagePosition = Vector( -11328, 13448, -188 )
local StageAngle = Angle( 0, 270, 0 )

PLAYER.BaseResetSpawnPosition = PLAYER.ResetSpawnPosition
function PLAYER:ResetSpawnPosition( bReset, bLeave )
	if self:BaseResetSpawnPosition( bReset, bLeave ) then
		if not self.Bonus then
			self:SetPos( StagePosition )
			self:SetEyeAngles( StageAngle )
		end
	end
end