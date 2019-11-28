local st, lp, Iv, ey, ler, con, gt, near, col, cw, cd, rat, fr, lst = SysTime, LocalPlayer, IsValid, EyeAngles, Lerp, Core.GetTimeConvert(), Core.GetTimeDifference, { pos = Vector() }, { r = 255, g = 0, b = 0, a = 80 }, Color( 255, 255, 255 ), Color( 40, 40, 40 ), 100, 150
local tac, tal = TEXT_ALIGN_CENTER, TEXT_ALIGN_LEFT
local DrawMat, DrawBeam, DrawText = render.SetMaterial, render.DrawBeam, draw.DrawText
local CamStart, CamEnd = cam.Start3D2D, cam.End3D2D

local function OnPaint()
	if Iv( near.ent ) and near.ent.vis and not near.ent.nohud then
		local e, dh, h = near.ent, ScrH() / 2, 18
		local d1 = "Bot " .. e.drawvel .. " (Delta: " .. math.Round( lp():GetVelocity():Length2D() - e:GetPosVel() ) .. " u/s)"
		DrawText( e.drawid, "HUDTimer", 33, dh + 1, cd, tal, tac )
		DrawText( e.drawid, "HUDTimer", 32, dh, cw, tal, tac )
		DrawText( d1, "HUDTimer", 33, dh + h * 1 + 1, cd, tal, tac )
		DrawText( d1, "HUDTimer", 32, dh + h * 1, cw, tal, tac )
		
		local d2, d3 = "Bot Time: " .. con( e.time ) .. gt( e.time ), "Your times:"
		DrawText( d2, "HUDTimer", 33, dh + h * 2 + 1, cd, tal, tac )
		DrawText( d2, "HUDTimer", 32, dh + h * 2, cw, tal, tac )
		
		local tc = #e.times
		if tc > 0 then
			DrawText( d3, "HUDTimer", 33, dh + h * 4 + 1, cd, tal, tac )
			DrawText( d3, "HUDTimer", 32, dh + h * 4, cw, tal, tac )
			
			for i = 1, tc do
				local ti = e.times[ i ].Text
				DrawText( ti, "HUDTimer", 33, dh + h * (4 + i) + 1, cd, tal, tac )
				DrawText( ti, "HUDTimer", 32, dh + h * (4 + i), cw, tal, tac )
			end
		end
	end
end
hook.Add( "HUDPaint", "PaintBotRoute", OnPaint )

local function OnUpdate( ar )
	lst = ar:UInt( 8 )
	
	if lst != 0 then
		fr = ar:UInt( 12 )
		
		local ratio = ar:Double()
		rat = math.Clamp( ratio, 80, ratio )
	end
end
Core.Register( "Trailing/Update", OnUpdate )

local function DrawCol( e, c, n )
	if e.blue and n > 1 then
		c.r = 0
		c.g = ler( n - 1, 0, 255 )
		c.b = 255
	else
		c.r = ler( 2 * n - 1, 255, 0 )
		c.g = ler( n * 2, 0, 255 )
		c.b = 0
	end
	
	c.a = e.alpha and 5 or 80
end

function ENT:LoadConfig()
	local settings = Core.GetSettings()
	self.blue = settings:ToggleValue( "TRAIL_BLUE" )
	self.range = settings:ToggleValue( "TRAIL_RANGE" )
	self.ground = settings:ToggleValue( "TRAIL_GROUND" )
	self.alpha = settings:ToggleValue( "TRAIL_VAGUE" )
	self.nolandmark = settings:ToggleValue( "TRAIL_LABEL" )
	self.nohud = settings:ToggleValue( "TRAIL_HUD" )
end

function ENT:GetPosVel()
	return self.estvel or self:GetVel()
end

function ENT:Initialize()
	self.tcol = cw
	self.col = table.Copy( col )
	self.mat = Material( "effects/laser1" )
	self.lastc = 1e10
	self.prev = 0
	
	local id = self:GetID()
	self.queueid = id > 1 and (id - 1) / 100 + 1 or id
	self.drawid = "Landmark " .. self.queueid
	self.drawvel = "Velocity: " .. self:GetVel() .. " u/s"
	self.style = self:GetStyle()
	self.time = math.Clamp( id - fr, 0, id ) / rat
	self.neighbors = {}
	self.times = {}
	self.groundpos = {}
	
	local calc = self:GetPos()
	for i = 1, 9 do
		local func = self[ "GetNeighbor" .. i ]
		self.Neighbor = func
		
		local vec = self:Neighbor()
		if vec != Vector( 0, 0, 0 ) then
			self.neighbors[ #self.neighbors + 1 ] = vec
			
			if not self.estvel then
				self.estvel = math.Round( (vec - calc):Length2D() * 10 )
			end
		end
	end
	
	self.neighborc = #self.neighbors
	
	if self.estvel then self.drawvel = "Velocity: " .. self.estvel .. " u/s" end
	for _,e in pairs( ents.FindByClass( "game_point" ) ) do
		if e.queueid == self.queueid + 1 and e.style == self.style then
			self.nextpoint = e
			break
		end
	end
	
	for i = 0, self.neighborc do
		local vec = self.neighbors[ i ]
		if i == 0 then
			vec = self:GetPos()
		elseif not vec then
			continue
		end
		
		local r = util.QuickTrace( vec, Vector( 0, 0, -16 ), player.GetAll() )
		if r.Hit then
			self.groundpos[ #self.groundpos + 1 ] = vec
		end
	end
end

function ENT:Think()
	if lst != self.style then
		self.vis = nil
		self.draw = nil
		return
	else
		if not self.draw then
			self:LoadConfig()
		end
		
		self.draw = true
	end
	
	local dist, prev = (self:GetPos() - lp():GetPos()):Length(), self.vis
	self.vis = dist < (self.range and 2000 or math.Clamp( lp():GetVelocity():Length() * 2, 1000, 2000 ))
	
	if self.vis and not prev then
		hook.Add( "PostDrawTranslucentRenderables", "RenderRoute" .. self:EntIndex(), function()
			if Iv( self ) then
				self:DrawAll()
			end
		end )
	elseif not self.vis and prev then
		hook.Remove( "PostDrawTranslucentRenderables", "RenderRoute" .. self:EntIndex() )
	end
	
	if not self.nextpoint and self.queueid then
		for _,e in pairs( ents.FindByClass( "game_point" ) ) do
			if e.queueid == self.queueid + 1 and e.style == self.style then
				self.nextpoint = e
				break
			end
		end
	end
	
	if dist < (near.pos - lp():GetPos()):Length() then
		local e = near.ent
		if Iv( e ) and e != self and e.rect then
			local dat = {
				Vel = lp():GetVelocity():Length2D(),
				Time = e.rect
			}
			
			local add = #e.times == 0
			for at,tab in pairs( e.times ) do
				if dat.Time < tab.Time then
					add = at
					break
				end
			end
			
			if add and dat.Vel > 80 then
				if add == true then add = 1 end
				
				dat.DiffVel = e:GetPosVel() - dat.Vel
				dat.DiffTime = dat.Time - e.time
				dat.Text = "- " .. con( dat.Time ) .. " [" .. (dat.DiffTime > 0 and "+" or "-") .. con( math.abs( dat.DiffTime ) ) .. "] (Bot Velocity " .. (dat.DiffVel > 0 and "+" or "") .. math.Round( dat.DiffVel ) .. " u/s)"
				
				table.insert( e.times, add, dat )
				
				if #e.times > 4 then
					table.remove( e.times, #e.times )
				end
			end
		end
		
		near.ent = self
		near.pos = self:GetPos()
	end
	
	if near.ent == self then
		local comp = math.abs( dist - self.prev )
		if comp < self.lastc then
			self.lastc = comp
			
			local _,t = gt( 0 )
			self.rect = t != 0 and t
		end
	else
		self.lastc = 1e10
	end
	
	self.prev = dist
end

function ENT:Draw() end
function ENT:DrawAll()
	if lst == 0 or not self.draw then return end
	
	DrawCol( self, self.col, (lp():GetVelocity():Length2D() - self:GetPosVel() + 500) / 500 )
	DrawMat( self.mat )
	
	if self.ground then
		for i = 1, #self.groundpos do
			DrawBeam( self.groundpos[ i ], self.groundpos[ i ] + Vector( 0, 0, 32 ), 1, 0, 1, self.col )
		end
	else
		if self.neighbors[ 1 ] then
			DrawBeam( self:GetPos(), self.neighbors[ 1 ], 3, 0, 1, self.col )
		end
		
		for i = 1, self.neighborc - 1 do
			DrawBeam( self.neighbors[ i ], self.neighbors[ i + 1 ], 3, 0, 1, self.col )
		end
		
		if Iv( self.nextpoint ) then
			DrawBeam( self.neighbors[ self.neighborc ], self.nextpoint:GetPos(), 3, 0, 1, self.col )
		end
	end
	
	if not self.nolandmark then
		local a = Angle( 0, ey().y - 90, 90 )
		a:RotateAroundAxis( a:Right(), 0 )
		
		CamStart( self:GetPos() + a:Up() * 0, a, 0.2 )
		DrawText( self.drawid, "BottomHUDSemi", 1, -49, cd, tac )
		DrawText( self.drawid, "BottomHUDSemi", 0, -50, self.tcol, tac )
		DrawText( self.drawvel, "BottomHUDSemi", 1, -31, cd, tac )
		DrawText( self.drawvel, "BottomHUDSemi", 0, -32, self.tcol, tac )
		CamEnd()
	end
end