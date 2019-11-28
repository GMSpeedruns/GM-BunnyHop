-- Set custom respawning

local PLAYER = FindMetaTable( "Player" )

PLAYER.BaseResetSpawnPosition = PLAYER.ResetSpawnPosition
function PLAYER:ResetSpawnPosition( bReset, bLeave )
	if self:BaseResetSpawnPosition( bReset, bLeave ) then
		self:SetName( "one" )
		self:SetKeyValue( "classname", "" )
	end
end