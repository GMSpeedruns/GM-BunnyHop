-- Catalyst Hullsize Zones

local min1 = Vector( -9968, 5196, -377 )
local max1 = Vector( -9789, 5652, -256 )

--[[
For the hard crouch part near the end, didn't work that much better -> glitchy behavior (can get stuck easier)

local min2 = Vector( -2810, 3056, -11350 )
local max2 = Vector( -2128, 3494, -11177 )
--]]

__HOOK[ "InitPostEntity" ] = function()
	local hullsize = ents.Create( "HullSizeZone" )
	hullsize:SetPos( (min1 + max1) / 2 )
	hullsize.min = min1
	hullsize.max = max1
	hullsize.height = 28
	hullsize:Spawn()
end