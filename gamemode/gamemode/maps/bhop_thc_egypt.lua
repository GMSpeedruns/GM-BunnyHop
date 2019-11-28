-- Override this function in the spawning process to set them to the hard style
local PLAYER = FindMetaTable( "Player" )

PLAYER.MainSetJumps = PLAYER.SetJumps
function PLAYER:SetJumps( nValue )
	self:MainSetJumps( nValue )
	self:SetName( "jump2" )
end