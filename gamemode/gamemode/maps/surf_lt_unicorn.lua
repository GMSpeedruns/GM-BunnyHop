-- Set custom respawning

local PLAYER = FindMetaTable( "Player" )
local StagePosition = Vector( 14688, -13808, 15988 )
local BonusPosition = Vector( 14864, -13808, 15988 )

PLAYER.BaseResetSpawnPosition = PLAYER.ResetSpawnPosition
function PLAYER:ResetSpawnPosition( bReset, bLeave )
	if self:BaseResetSpawnPosition( bReset, bLeave ) then
		if not self.Bonus then
			self:SetPos( StagePosition )
		elseif self.Bonus == 0 then
			self:SetPos( BonusPosition )
		end
	end
end