-- Make the start zone force them back into stage 1
local PLAYER = FindMetaTable( "Player" )

PLAYER.MainSetJumps = PLAYER.SetJumps
function PLAYER:SetJumps( nValue )
	self:MainSetJumps( nValue )
	self:SetName( "test1" )
end