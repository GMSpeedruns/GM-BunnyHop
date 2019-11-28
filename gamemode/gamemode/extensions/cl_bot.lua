local function DoPopulate( s, args, tools, w, h )
	s.DefaultText = args[ 4 ] or "To start playing a run, left click it. Right click a style for older runs.\n\nRecorded runs:"
	s.HeaderLab = tools.Label( s, 14, 54, "BottomHUDTiny", s.DefaultText, tools.C.Text )
	s.OuterView = false
	
	local styles, details = args[ 1 ], args[ 2 ]
	local y, hy = 105, h - 105 - 16
	local list = tools.ScrollPanel( s, 8, y, w - 14, hy )
	list.Items = {}
	
	s.convert = Core.GetTimeConvert()
	
	local function OnClick( se )
		RunConsoleCommand( "say", "!bot play " .. se.SetStyle )
	end
	s.DOnClick = OnClick
	
	local function OnRightClick( se )
		RunConsoleCommand( "say", "!mbot " .. se.SetStyle )
	end
	s.DOnRightClick = OnRightClick
	
	if args[ 4 ] then
		OnClick = function( se )
			local data = details[ se.ItemID ]
			se.Subtitle1 = "Steam ID: " .. (data.SteamID or "") .. ", Exact: " .. (data.Time or "")
			
			local high = se.Expanded and -16 or 16
			se.Expanded = not se.Expanded
			se:SetTall( se:GetTall() + high )
			
			if not se.Expanded then
				se.Subtitle1 = nil
			end
			
			for _,item in pairs( se:GetParent():GetParent():GetCanvas():GetChildren() ) do
				if item.ItemID > se.ItemID then
					local x, y = item:GetPos()
					item:SetPos( x, y + high )
				end
			end
		end
		
		OnRightClick = function( se )
			RunConsoleCommand( "say", "!mbot change " .. se.ItemID )
			tools.Close()
		end
	end
	
	function s.BuildItems()
		local c = 0
		for i = 1, #styles do
			if not styles[ i ] or not details[ i ] then continue end
			local col = c % 2 == 0 and tools.C.BLight or tools.C.BDark
			local highlight = args[ 3 ] and args[ 3 ][ 1 ] == details[ i ].Style and args[ 3 ][ 2 ] == details[ i ].SteamID and args[ 3 ][ 3 ] == details[ i ].Time
			local b = tools.PlainButton( list, i .. ". " .. styles[ i ] .. " (" .. s.convert( details[ i ].Time or 0 ) .. ")", 0, c * 30, w - 10, 30, { col, highlight and Core.Config.Prefixes.Notification or tools.C.Text, List = true, Fixed = true }, OnClick )
			b.Extra = details[ i ].Name or ""
			b.DoRightClick = OnRightClick
			b.SetStyle = details[ i ].Style
			b.ItemID = i
			list:AddItem( b )
			c = c + 1
		end
		
		if c < 9 then
			if not list.Shortened then
				list:SetWide( list:GetWide() - 3 )
				list.Shortened = true
			end
		elseif list.Shortened then
			list:SetWide( list:GetWide() + 3 )
			list.Shortened = nil
		end
	end
	
	function s:ThinkHook( bType )
		if bType then return end
		if input.IsKeyDown( KEY_BACKSPACE ) and self.OuterView then
			self:Update( { 2 } )
		end
	end
	
	function s:Update( varArgs )
		if varArgs[ 1 ] == 0 then
			list.Cache = {}
			self.OuterView = true
			
			for _,item in pairs( list:GetCanvas():GetChildren() ) do
				list.Cache[ #list.Cache + 1 ] = { item.Title, item.Data[ 2 ], item.Extra, item.SetStyle, item.ItemID }
				item:Remove()
			end
			
			list.content = varArgs[ 2 ]
			args[ 3 ] = varArgs[ 3 ]
			
			styles, details = {}, {}

			OnClick = function( se )
				local data = list.content[ se.ItemID ]
				se.Subtitle1 = "Steam ID: " .. (data.SteamID or "") .. ", Date: " .. (data.Date or "")
				
				local high = se.Expanded and -16 or 16
				se.Expanded = not se.Expanded
				se:SetTall( se:GetTall() + high )
				
				if not se.Expanded then
					se.Subtitle1 = nil
				end
				
				for _,item in pairs( se:GetParent():GetParent():GetCanvas():GetChildren() ) do
					if item.ItemID > se.ItemID then
						local x, y = item:GetPos()
						item:SetPos( x, y + high )
					end
				end
			end
			
			OnRightClick = function( se )
				if not se.SetStyle then return end
				RunConsoleCommand( "say", "!mbot " .. se.SetStyle .. " " .. se.ItemID )
			end
			
			for i = 1, #list.content do
				styles[ i ] = Core.StyleName( list.content[ i ].Style )
				details[ i ] = { Time = list.content[ i ].Time, Name = list.content[ i ].Name, SteamID = list.content[ i ].SteamID, Style = list.content[ i ].Style }
			end
			
			self.HeaderText = varArgs[ 4 ]
			self.HeaderLab:SetText( self.HeaderText )
			self.BuildItems()
		elseif varArgs[ 1 ] == 1 then
			local function UpdateText()
				if IsValid( s ) and IsValid( s.HeaderLab ) then
					s.HeaderLab:SetText( s.OuterView and s.HeaderText or s.DefaultText )
					s.HeaderLab:SetTextColor( tools.C.Text )
				end
			end
			
			local text = string.Implode( "\n", tools.Wrap( "BottomHUDTiny", varArgs[ 2 ], w - 50 ) )
			if self.HeaderLab:GetText() == text then
				timer.Remove( "RevertString" )
				timer.Create( "RevertString", 2, 1, UpdateText )
				
				return
			end
			
			self.HeaderLab:SetText( text )
			self.HeaderLab:SetTextColor( Core.Config.Prefixes.Notification )
			
			timer.Remove( "RevertString" )
			timer.Create( "RevertString", 2, 1, UpdateText )
		elseif varArgs[ 1 ] == 2 then
			if list.Cache and #list.Cache > 0 then
				self.HeaderLab:SetText( self.DefaultText )
				self.OuterView = false
				
				for _,item in pairs( list:GetCanvas():GetChildren() ) do
					item:Remove()
				end
				
				local c = 0
				for i = 1, #list.Cache do
					local data = list.Cache[ i ]
					local col = c % 2 == 0 and tools.C.BLight or tools.C.BDark
					local b = tools.PlainButton( list, data[ 1 ], 0, c * 30, w - 10, 30, { col, data[ 2 ], List = true, Fixed = true }, self.DOnClick )
					b.Extra = data[ 3 ]
					b.DoRightClick = self.DOnRightClick
					b.SetStyle = data[ 4 ]
					b.ItemID = data[ 5 ]
					list:AddItem( b )
					c = c + 1
				end

				if c < 9 then
					if not list.Shortened then
						list:SetWide( list:GetWide() - 3 )
						list.Shortened = true
					end
				elseif list.Shortened then
					list:SetWide( list:GetWide() + 3 )
					list.Shortened = nil
				end
			end
		elseif varArgs[ 1 ] == 3 then
			if varArgs[ 2 ] then
				Core.Print( "General", varArgs[ 3 ] )
				tools.Close()
			else
				self:Update( { 1, varArgs[ 3 ] } )
			end
		end
	end
	
	s.BuildItems()
end

local function OnReceive( varArgs )
	varArgs.Args.Populate = DoPopulate
	Core.SpawnWindow( varArgs )
end
Core.Register( "GUI/Bot", OnReceive )

local function OnUpdate( varArgs )
	local wnd = Core.IsWndActive( "Bot" )
	if wnd then
		wnd:Update( varArgs )
	else
		Core.Print( "General", varArgs[ 3 ] )
	end
end
Core.Register( "GUI/UpdateBot", OnUpdate )

local Toggles = Core.GetSettings().Toggles
Toggles["TRAIL_BLUE"] = { "TrailBlueSpeed", false, nil, "Blue when faster" }
Toggles["TRAIL_RANGE"] = { "TrailFullRange", false, nil, "Increased view range" }
Toggles["TRAIL_GROUND"] = { "TrailGroundOnly", false, nil, "Ground hits only" }
Toggles["TRAIL_VAGUE"] = { "TrailVagueAlpha", false, nil, "More transparent" }
Toggles["TRAIL_LABEL"] = { "TrailNoLabels", false, nil, "Hide landmarks" }
Toggles["TRAIL_HUD"] = { "TrailNoHud", false, nil, "Hide trail HUD" }

local Window = Core.GetWindow()
Window.Cache.Toggles[ #Window.Cache.Toggles + 1 ] = { "Bot path options", { "TRAIL_BLUE", "TRAIL_RANGE", "TRAIL_GROUND", "TRAIL_VAGUE", "TRAIL_LABEL", "TRAIL_HUD" } }