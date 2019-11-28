-- Set custom respawning

local PLAYER = FindMetaTable( "Player" )

PLAYER.BaseResetSpawnPosition = PLAYER.ResetSpawnPosition
function PLAYER:ResetSpawnPosition( bReset, bLeave )
	if self:BaseResetSpawnPosition( bReset, bLeave ) then
		if self.Bonus then
			self:SetName( "tn_rleft" )
		end
	end
end