local DrawArea, ViewZones = {}, Core and Core.CVar( "showzones", "0" )
local PaintPly, PaintColor, PaintDark, PaintPos, Iv, st, PaintNames = LocalPlayer, Color( 255, 255, 255 ), Color( 25, 25, 25 ), TEXT_ALIGN_CENTER, IsValid, SysTime
local Izd, Ism = Core and Core.Config.MaterialID .. "/zone/l", Core and Core.Config.MaterialID .. "/timer.png"

local DrawCol = {
	[0] = Color( 8, 172, 56 ),
	[1] = Color( 168, 8, 8 ),
	[2] = Color( 8, 172, 168 ),
	[3] = Color( 8, 60, 168 ),
	[5] = Color( 219, 198, 8 )
}

for _,z in pairs( { 0, 1, 2, 3, 5 } ) do
	DrawArea[ z ] = z
end

if Core and not Core.ZonePaint then
	Core.ZonePaint = {}
end

local Paintables = Core and Core.ZonePaint
local function PaintZoneDetails()
	local ply = PaintPly()
	if not Iv( ply ) or not ply:Alive() then return end
	if ViewZones:GetInt() == 0 and not ply.Bonus then return end
	if ViewZones:GetInt() == -1 then return end

	if not PaintNames and Core.EntNames then
		PaintNames = {}

		for n,i in pairs( Core.EntNames ) do
			PaintNames[ i ] = n
		end
	end

	local d, fe = {}, PaintNames or {}
	for i,ent in pairs( ents.FindInSphere( ply:GetPos(), 175 ) ) do
		if Iv( ent ) and Paintables[ ent:EntIndex() ] and ent.zonetype then
			if ent.zonetype >= 2 and ent.zonetype <= 3 then
				if Paintables.Active or ply.Bonus then
					d[ #d + 1 ] = { Text = (fe[ ent.zonetype ] or "Unknown") .. " (ID: " .. (ent.embedded or "Main") .. ")", Dist = (ply:GetPos() - ent:GetPos()):Length2D(), Ent = ent }
				end
			elseif Paintables.Active and (ent.Material or ent.BlinkMat) then
				d[ #d + 1 ] = { Text = (fe[ ent.zonetype ] or "Unknown") .. (ent.embedded and " (Data ID: " .. ent.embedded .. ")" or ""), Dist = (ply:GetPos() - ent:GetPos()):Length2D(), Ent = ent }
			end
		end
	end

	table.SortByMember( d, "Dist", true )

	local x, y, c = ScrW() / 2, 20, #d
	if c == 0 then
		local pe = Paintables.High
		if IsValid( pe ) and pe.BlinkMat then
			pe.Material = pe.BlinkMat
			pe.Color = pe.BlinkCol
			pe.BlinkMat = nil
			pe.BlinkCol = nil
			pe.BlinkTime = nil
		end

		Paintables.High = nil
	end

	for i = 1, c do
		if i == 1 then
			local t = "Nearest: " .. d[ i ].Text .. " (" .. d[ i ].Ent:EntIndex() .. ")"
			draw.SimpleText( t, "FullscreenHeader", x, y + 2, PaintDark, PaintPos )
			draw.SimpleText( t, "FullscreenHeader", x, y, PaintColor, PaintPos )
			y = y + 24

			if Paintables.High != d[ i ].Ent then
				local pe = Paintables.High
				if IsValid( pe ) and pe.BlinkMat then
					pe.Material = pe.BlinkMat
					pe.Color = pe.BlinkCol
					pe.BlinkMat = nil
					pe.BlinkCol = nil
					pe.BlinkTime = nil
				end

				d[ i ].Ent.BlinkMat = d[ i ].Ent.Material
				d[ i ].Ent.BlinkCol = d[ i ].Ent.Color
				d[ i ].Ent.BlinkTime = SysTime() + 1

				Paintables.High = d[ i ].Ent
			end
		else
			local t = d[ i ].Text .. " (" .. math.floor( d[ i ].Dist ) .. "u)"
			draw.SimpleText( t, "FullscreenSubtitle", x, y + 2, PaintDark, PaintPos )
			draw.SimpleText( t, "FullscreenSubtitle", x, y, PaintColor, PaintPos )
			y = y + 20
		end
	end
end

if Core and not Core.ZonePainting then
	Core.ZonePainting = true
	hook.Add( "HUDPaint", "ZoneTooltipPaint", PaintZoneDetails )
end

function ENT:Initialize()
end

function ENT:Draw()
	if self.Material then
		self:DrawBox( self.Bottom, self.Top, self.DrawWidth, self.Color or PaintColor )
	end
end

function ENT:Think()
	local Min, Max = self:GetCollisionBounds()
	self:SetRenderBounds( Min, Max )

	local data = ((Core and Core.ClientEnts) or {})[ self:EntIndex() ]
	if not self.Created then
		if not data then return end
		if not DrawArea[ data[ 1 ] ] then
			if ViewZones:GetInt() == 1 then
				self.BaseHidden = true
			else
				return
			end
		end

		self.zonetype = data[ 1 ]
		self.embedded = data[ 2 ]
		self.directbound = data[ 3 ]

		if self.directbound then
			Min = self:GetPos() + Min - Vector( 16, 16, 0 )
			Max = self:GetPos() + Max + Vector( 16, 16, 0 )
		else
			Min = self:GetPos() + Min
			Max = self:GetPos() + Max
		end

		self.Created = true
		self.Bottom = { Vector( Min.x, Min.y, Min.z ), Vector( Min.x, Max.y, Min.z ), Vector( Max.x, Max.y, Min.z ), Vector( Max.x, Min.y, Min.z ) }
		self.Top = { Vector( Min.x, Min.y, Max.z ), Vector( Min.x, Max.y, Max.z ), Vector( Max.x, Max.y, Max.z ), Vector( Max.x, Min.y, Max.z ) }
		self.Material = Material( Izd .. (DrawArea[ self.zonetype ] or "w") )
		self.BaseMat = self.Material
		self.DrawBox = Core.DrawCustomZone

		if Core.GetSettings():ToggleValue( "GAME_SIMPLEZONE" ) then
			self.Color = DrawCol[ self.zonetype ] or Color( 255, 255, 255 )
			self.Material = Material( Ism )
			self.BaseMat = self.Material
			self.DrawWidth = 3
		else
			self.DrawWidth = 5
		end

		if self.BaseHidden then
			self.Material = nil
		end

		Paintables[ self:EntIndex() ] = self
	else
		local val = ViewZones:GetInt()
		if val == -1 then
			if self.Material then
				self.Material = nil
			end
		elseif val == 0 then
			if not self.BaseHidden then
				self.Material = self.BaseMat
			elseif self.Material then
				self.Material = nil
			end
		elseif val == 1 then
			if Paintables.Active and Paintables.High == self then
				if self.BlinkTime and st() - self.BlinkTime < 0.5 then return end
				self.BlinkTime = st()

				if not IsValid( PaintPly() ) or PaintPly():VarNet( "Get", "Access", 0 ) < 3 then return end
				if not DrawArea[ self.zonetype ] then
					if self.Color then
						self.BlinkID = not self.BlinkID
						self.Color = self.BlinkID and Color( 255, 0, 255 ) or Color( 255, 255, 255 )
					else
						self.BlinkID = self.BlinkID != 2 and 2
						self.Material = Material( Izd .. (DrawArea[ self.BlinkID ] or "w") )
					end
				elseif not self.Material then
					self.Material = self.BaseMat
				end
			elseif not self.Material then
				self.Material = self.BaseMat
			end
		end
	end
end
