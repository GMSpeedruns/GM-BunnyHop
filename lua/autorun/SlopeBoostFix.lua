local maxvelocity = GetConVar("sv_maxvelocity")
local gravity = GetConVar("sv_gravity")

local ground = {}
local velocity = {}
local last_ground = {}
local last_velocity = {}

--[[---------------------------------------------------------
	Desc: Checks for slope landings and corrects physics
-----------------------------------------------------------]]
local function Slopefix(ply, mv, cmd)
  -- Get entity data
  last_ground[ply] = ground[ply]
  last_velocity[ply] = velocity[ply]
  ground[ply] = ply:IsOnGround()
  velocity[ply] = mv:GetVelocity()

  -- Check if we've just landed
  if ground[ply] and not last_ground[ply] then
    local pos = ply:GetPos()
    local result = util.TraceHull({
      start = pos,
      endpos = Vector(pos.x, pos.y, pos.z - maxvelocity:GetFloat()),
      mins = ply:OBBMins(),
      maxs = ply:OBBMaxs(),
      mask = MASK_PLAYERSOLID_BRUSHONLY,
      filter = ply
    })

    -- Check if we've hit something and that it's a slope
    if result.Hit and result.HitNormal.z < 1.0 and result.HitNormal.z >= 0.7 and last_velocity[ply] then
      local last = Vector(last_velocity[ply].x, last_velocity[ply].y, last_velocity[ply].z - gravity:GetFloat() * engine.TickInterval())
      local back = last:Dot(result.HitNormal)
      local vel = Vector(last.x - result.HitNormal.x * back, last.y - result.HitNormal.y * back, 0)
      local adjust = vel:Dot(result.HitNormal)
      if adjust < 0 then
        vel.x = vel.x - result.HitNormal.x * adjust
        vel.y = vel.y - result.HitNormal.y * adjust
      end

      -- If we're meant to gain velocity (down a ramp)
      if vel:Length2D() > last:Length2D() then
        mv:SetVelocity(vel)
      end
    end
  end
end
hook.Add("SetupMove", "Slopefix", Slopefix)
