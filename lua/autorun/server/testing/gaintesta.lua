local set = {}
set.gains = {}
set.gain = false
set.measure = false
set.pass = false
set.last = SysTime()

local LastG, LastV = {}, {}
local function MoverTesta( ply, mv, cmd )
	if ply:IsBot() then return end
	
	if not ply:IsFlagSet( FL_ONGROUND ) and LastG[ ply ] and set.gain then
		set.pass = true
	end
	
	if set.pass and bit.band( cmd:GetButtons(), IN_MOVELEFT ) > 0 then
		set.measure = SysTime()
		set.gain = nil
		set.pass = nil
	end
	
	if not ply:IsOnGround() and set.measure then
		local vel = ply:GetVelocity():Length2D()
		
		if SysTime() - set.last > 0.1 then
			set.gains[ SysTime() - set.measure ] = { vel, vel - (LastV[ ply ] or 0) }
		end
		
		LastV[ ply ] = vel
	end
	
	LastG[ ply ] = ply:IsFlagSet( FL_ONGROUND )
end
hook.Add( "SetupMove", "Moverssss", MoverTesta )

set.write = function()
	file.Write( "gains.txt", "" )
	
	for k,v in SortedPairs( set.gains ) do
		file.Append( "gains.txt", math.Round( k, 6 ) .. " [" .. math.Round( v[ 1 ], 6 ) .. " u/s] - " .. math.Round( v[ 2 ], 6 ) .. "\n" )
	end
end

kek = set