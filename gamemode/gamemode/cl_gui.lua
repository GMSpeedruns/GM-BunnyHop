local Window = { Cache = {}, C = {} }
local ActiveWindow
local KeyCheck, MouseCheck = input.IsKeyDown, input.IsMouseDown
local tal, tar, tac, tat = TEXT_ALIGN_LEFT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM
local Iv, st, lp, DrawText, DrawBox, DrawBoxEx, DrawColor, DrawRect = IsValid, SysTime, LocalPlayer, draw.SimpleText, draw.RoundedBox, draw.RoundedBoxEx, surface.SetDrawColor, surface.DrawRect

function Core.CreateFonts()
	surface.CreateFont( "FullscreenHeader", { size = 26, font = "Lato" } )
	surface.CreateFont( "FullscreenSubtitle", { size = 21, font = "Lato" } )
	
	surface.CreateFont( "BottomHUDTiny", { size = 16, font = "Lato" } )
	surface.CreateFont( "BottomHUDStress", { size = 16, weight = 800, font = "Lato" } )
	surface.CreateFont( "BottomHUDSemi", { size = 18, font = "Lato" } )
	surface.CreateFont( "BottomHUDStressL", { size = 18, weight = 800, font = "Lato" } )
	surface.CreateFont( "BottomHUDTime", { size = 20, font = "Lato" } )
	surface.CreateFont( "BottomHUDSpec", { size = 32, font = "Lato" } )
	surface.CreateFont( "BottomHUDVelocity", { size = 34, font = "Lato" } )

	surface.CreateFont( "ScoreboardMassive", { size = 144, weight = 800, font = "Coolvetica" } )
	surface.CreateFont( "ScoreboardTitle", { size = 52, font = "Coolvetica" } )
	surface.CreateFont( "ScoreboardPlayer", { size = 24, font = "Coolvetica" } )
	surface.CreateFont( "ScoreboardAuthor", { size = 14, weight = 800, font = "Tahoma" } )

	surface.CreateFont( "GUICloseButton", { size = 13, weight = 800, font = "Coolvetica" } )
	surface.CreateFont( "GUIWindowTitle", { size = 19, font = "Trebuchet24" } )
	surface.CreateFont( "GUIWindowSubTitle", { size = 11, font = "Trebuchet24" } )
	surface.CreateFont( "GUIButtonFont", { size = 15, font = "Trebuchet24" } )
	surface.CreateFont( "GUIButtonFontIt", { size = 15, font = "Trebuchet24", italic = true } )
	surface.CreateFont( "GUIGrayButton", { size = 19, weight = 1000, font = "Tahoma" } )
	surface.CreateFont( "GUIGrayButtonLight", { size = 19, font = "Tahoma" } )
	
	surface.CreateFont( "HUDHeaderBig", { size = 44, font = "Coolvetica" } )
	surface.CreateFont( "HUDHeader", { size = 30, font = "Coolvetica" } )
	surface.CreateFont( "HUDLabelSmall", { size = 12, weight = 800, font = "Tahoma" } )
	surface.CreateFont( "HUDTimer", { size = 17, weight = 800, font = "Trebuchet24" } )
	surface.CreateFont( "HUDSpeed", { size = 16, weight = 800, font = "Tahoma" } )
	surface.CreateFont( "HUDSpeedBase", { size = 22, weight = 800, font = "Tahoma" } )
	surface.CreateFont( "HUDSpeedSmall", { size = 13, weight = 800, font = "Tahoma" } )
	
	Window.C.GText = Color( 130, 130, 130 )
	Window.C.Text = Color( 85, 85, 85 )
	Window.C.LText = Color( 68, 68, 68 )
	Window.C.DText = Color( 35, 35, 35 )
	Window.C.Opaque = Color( 0, 0, 0, 150 )
	Window.C.BLight = Color( 212, 212, 212 )
	Window.C.BDark = Color( 228, 228, 228 )
	
	Window.Cache.Toggles = {}
end

function Core.GetWindow()
	return Window
end

function Core.ChangeContext( bool )
	if not Iv( ActiveWindow ) then return false end
	
	if bool then
		if not ActiveWindow.IsMouseEnabled then
			ActiveWindow.IsMouseEnabled = true
			ActiveWindow:MakePopup()
		end
	elseif ActiveWindow.IsMouseEnabled then
		ActiveWindow.IsMouseEnabled = false
		ActiveWindow:SetMouseInputEnabled( false )
		ActiveWindow:SetKeyboardInputEnabled( false )
	end
	
	return true
end

function Core.ChangeVisibility( varArgs )
	if not Iv( ActiveWindow ) then return false end
	ActiveWindow.Hidden = type( varArgs[ 1 ] ) == "boolean" and varArgs[ 1 ] or not ActiveWindow.Hidden
	
	for _,v in pairs( ActiveWindow.Items or {} ) do
		if v.SetVisible then
			v:SetVisible( not ActiveWindow.Hidden )
		end
	end
	
	ActiveWindow.MainClose:SetVisible( not ActiveWindow.Hidden )
	ActiveWindow.IsMouseEnabled = true
	
	if ActiveWindow.Hidden then
		Core.ChangeContext( false )
	end
end
Core.Register( "GUI/Visibility", Core.ChangeVisibility )

function Core.RequestClose( varArgs, bZero )
	if bZero and ActiveWindow and Iv( ActiveWindow.TextInput ) and ActiveWindow.TextInput.Focus then return end
	if not Window.Close() and varArgs then
		Core.Print( "General", "All windows are already closed" )
	end
end
Core.Register( "GUI/Close", Core.RequestClose )


function Window.Create( szIdentifier, tabData, varArgs, bForce )
	if Iv( ActiveWindow ) and not bForce and varArgs.Locked then return false end
	
	Window.Close()
	
	ActiveWindow = Window.Panel( tabData.x, tabData.y, tabData.px, tabData.py )
	ActiveWindow.Identifier = szIdentifier
	ActiveWindow.Title = varArgs.Title or szIdentifier
	ActiveWindow.StartTime = st()
	ActiveWindow.Paint = Window.Draw
	ActiveWindow.Think = Window.Process
	
	Window.GenerateContent( ActiveWindow, szIdentifier, varArgs )
end

function Window.GetCurrentID()
	if Iv( ActiveWindow ) then
		return ActiveWindow.Identifier
	end
	
	return ""
end

function Window.Close( bForce )
	if not Iv( ActiveWindow ) then return end
	
	if not bForce and ActiveWindow.CloseFunc then
		if ActiveWindow:CloseFunc() then
			return false
		end
	end
	
	ActiveWindow.IsMouseEnabled = false
	ActiveWindow:SetMouseInputEnabled( false )
	ActiveWindow:SetKeyboardInputEnabled( false )
	
	for _,p in pairs( ActiveWindow.Items ) do
		if p.Items then
			for _,s in pairs( p.Items ) do
				s:Remove()
			end
		end
		
		p:Remove()
	end
	
	ActiveWindow:Remove()
	ActiveWindow = nil
	
	return true
end

function Window.Receive( varArgs )
	if varArgs.Overwrite then
		if Window.GetCurrentID() != varArgs.ID then return end
		
		return Window.Close()
	end

	if not varArgs.Args then varArgs.Args = {} end
	
	Window.Create( varArgs.ID, varArgs.Dimension, varArgs.Args, varArgs.Force )
	
	if Iv( ActiveWindow ) then
		if varArgs.Args.Mouse then ActiveWindow:MakePopup() end
		if varArgs.Args.Blur then ActiveWindow.Blur = varArgs.Args.Blur end
	end
	
	return ActiveWindow
end
Core.Register( "GUI/Create", Window.Receive )
Core.SpawnWindow = Window.Receive

function Window.IsActive( szIdentifier )
	if not Iv( ActiveWindow ) then return false end
	if szIdentifier then return ActiveWindow.Identifier == szIdentifier and ActiveWindow else return true end
end
Core.IsWndActive = Window.IsActive

function Window.Process( s )
	if not s.CanThink then return end
	if s.ThinkHook then s:ThinkHook( Iv( lp() ) and lp():IsTyping() ) end
	if KeyCheck( 92 ) then Window.Receive( { ID = "Settings", Overwrite = true } )
	elseif KeyCheck( 93 ) then Window.Receive( { ID = "Spectate", Overwrite = true } )
	elseif KeyCheck( 95 ) then Window.Receive( { ID = "Records", Overwrite = true } ) end
	
	if MouseCheck( MOUSE_LEFT ) then
		if s.IsMiss then return end
		
		local mx, my = gui.MousePos()
		if s.Dragging then
			s:SetPos( mx - s.Dragging[ 1 ], my - s.Dragging[ 2 ] )
		else
			local x, y = s:ScreenToLocal( mx, my )
			local inside = x >= 8 and y >= 8 and x <= s:GetSize() - 8 and y <= 52
			
			if inside then
				s.Dragging = { x, y }
			else
				s.IsMiss = true
			end
		end
	else
		if s.Dragging then
			s.Dragging = nil
		end
		
		s.IsMiss = nil
	end
end

function Window.Draw( s, w, h )
	if s.Hidden then return end
	if s.Blur then
		Derma_DrawBackgroundBlur( s, s.StartTime )
	end
	
	DrawBox( 8, 0, 0, w, h, Color( 0, 0, 0, 76 ) )
	DrawBox( 8, 8, 44, w - 16, h - 52, Color( 252, 252, 252 ) )
	DrawBox( 8, 8, 8, w - 16, 44, Color( 236, 236, 236 ) )
	
	DrawColor( Color( 236, 236, 236 ) )
	DrawRect( 8, 52 - 16, w - 16, 16 )
	
	if s.Separator then
		DrawColor( Color( 150, 150, 150 ) )
		DrawRect( 8, 51, w - 16, s.Separator + 2 )
	end
	
	DrawColor( Color( 196, 196, 196 ) )
	DrawRect( 8, 52, w - 16, s.Separator or 1 )
	
	DrawText( s.Title, "GUIWindowTitle", w / 2, 8 + 44 / 2 + 1, Color( 255, 255, 255, 204 ), tac, tac )
	local w2,h2 = DrawText( s.Title, "GUIWindowTitle", w / 2, 8 + 44 / 2, Window.C.LText, tac, tac )
	
	if s.Subtitle then
		DrawText( s.Subtitle, "GUIWindowSubTitle", w / 2, 8 + 44 / 2 + h2, Window.C.GText, tac, tat )
	end
end

function Window.Wrap( f, t, w )
	local words = string.Explode( " ", t )
	local tab = {}
	
	surface.SetFont( f )
	
	local word, i = "", 1
	while i <= #words do
		local temp = word .. words[ i ]
		local tw = surface.GetTextSize( temp )
		if tw > w then
			tab[ #tab + 1 ] = word
			word = ""
			i = i - 1
		else
			word = word .. words[ i ]
			if i == #words then
				tab[ #tab + 1 ] = word
			else
				word = word .. " "
			end
		end
		
		i = i + 1
	end
	
	return tab
end

local ocf = SetClipboardText
function Window.Clipboard( t )
	Window.ClipText = t
	ocf( t )
end
SetClipboardText = Window.Clipboard

local specials = { [KEY_COMMA] = ",", [KEY_SPACE] = " ", [KEY_PERIOD] = ".", [KEY_SLASH] = "/", [KEY_MINUS] = "-", [KEY_APOSTROPHE] = "'", [KEY_BACKSPACE] = "" }
local additionals = { ")", "!", "@", "#", "$", "%", "^", "&", "*", "(" }
function Window.TextHandler( s )
	if MouseCheck( MOUSE_LEFT ) or MouseCheck( MOUSE_RIGHT ) then
		local b = s.Bounds
		local p = s:GetParent()
		local x, y = p:ScreenToLocal( gui.MousePos() )
		local inside = x >= b[ 1 ] and x <= b[ 2 ] and y >= b[ 3 ] and y <= b[ 4 ]
		
		if MouseCheck( MOUSE_RIGHT ) then
			if s.NoCopy then return SetClipboardText( s:GetValue() ) end
			return inside and s:SetText( Window.ClipText or (not s.IsPrompt and "" or s.Default) or "" )
		elseif s.IsMiss then
			return
		elseif s.IsPrompt then
			if inside and not IsValid( s.Request ) then
				s:SetText( s.Default )
				s:IsPrompt()
			end
			
			return
		end
		
		if s.Focus and not inside then
			s:SetText( s.Default )
		elseif not s.Focus and inside then
			s:SetText( "" )
		end
		
		if not inside then
			s.IsMiss = true
		end
		
		s.Focus = inside
		p.TextInput = s
	end
	
	if not MouseCheck( MOUSE_LEFT ) then
		s.IsMiss = nil
	end
	
	if s.Focus then
		local text = s:GetText()
		if not s.Blink or s.Blink + 0.5 < SysTime() then
			if text == "" then
				text = "|"
			elseif text == "|" then
				text = ""
			end
			
			s:SetText( text )
			s.Blink = SysTime()
		end
		
		local shifd
		if KeyCheck( KEY_ENTER ) then
			s.Focus = nil
			return s:OnEnter( s:GetText() )
		elseif KeyCheck( KEY_LSHIFT ) or KeyCheck( KEY_RSHIFT ) then
			shifd = true
		end
		
		if s.LastKey and not KeyCheck( s.LastKey ) then
			s.LastKey = nil
			s.RepeatKey = nil
		end
		
		local isKey, printValue
		for i = KEY_A, KEY_Z do
			if KeyCheck( i ) then
				isKey = i
				printValue = string.format( "%c", (shifd and 54 or 86) + isKey )
			end
		end
		
		for i = KEY_0, KEY_9 do
			if KeyCheck( i ) then
				isKey = i
				printValue = shifd and additionals[ i ] or tostring( i - 1 )
			end
		end
		
		for key,data in pairs( specials ) do
			if KeyCheck( key ) then
				isKey = key
				
				if data != "" then
					if key == KEY_MINUS and KeyCheck( KEY_LSHIFT ) then
						printValue = "_"
					else
						printValue = data
					end
				end
			end
		end
		
		if isKey then
			local threshold = 0.05
			if isKey == s.LastKey then
				if not s.RepeatKey then
					threshold = 0.5
				end
			elseif specials[ s.LastKey ] then
				threshold = 0.25
			end
			
			if s.RepeatKey != isKey then s.RepeatKey = nil end
			if s.LastWrite and s.LastWrite + threshold > SysTime() then return end
			if threshold == 0.5 then s.RepeatKey = isKey end
			
			s.LastWrite = SysTime()
			s.LastKey = isKey
			
			if string.find( text, "|" ) then
				text = string.gsub( text, "|", "" )
			end
			
			if printValue then
				text = text .. printValue
			else
				text = string.sub( text, 1, #text - 1 )
			end
			
			s:SetText( text )
		end
	end
end

function Window.Modal( varArgs, szText )
	if szText then varArgs = { Title = varArgs, Text = szText } end
	local f = "BottomHUDTiny"
	surface.SetFont( f )
	
	local w, h = surface.GetTextSize( varArgs.Text )
	w, h = w + 36, h + 110
	
	local p = Window.Panel( w, h )
	p.Blur = true
	p.Title = varArgs.Title
	p.StartTime = st()
	p.Paint = Window.Draw
	p.Think = Window.Process
	
	Window.Label( p, 16, 60, f, varArgs.Text, Window.C.Text )
	Window.GrayButton( p, "OK", w / 2 - 20, h - 42, 40, 26, true, function() p:Remove() end )
	
	p.MainClose = Window.CloseButton( p, p:GetWide() - 16 - 8, 8, 16, 16, function() p:Remove() end )
	p:MakePopup()
	
	timer.Simple( 0.5, function() if Iv( p ) then p.CanThink = true end end )
end
Core.Modal = Window.Modal
Core.Register( "GUI/Modal", Window.Modal )



local function DrawCloseButton( s, w, h )
	DrawText( "X", "GUICloseButton", w - 4, h / 2, Window.C.LText, tar, tac )
end

local function DrawGrayButton( s, w, h )
	local color, y = Color( 221, 221, 221 ), 0
	if s.IsActive then
		color, y = Color( 206, 206, 206 ), 1
	elseif s:IsHovered() then
		color = Color( 238, 238, 238 )
	end
	
	DrawBox( 4, 0, y, w, h - 1, Color( 0, 0, 0, 240 ) )
	DrawBox( 4, 0, y, w, h - 2, Color( 119, 119, 119 ) )
	DrawBox( 4, 1, y + 1, w - 2, h - 4, color )
	
	DrawText( s.Title, s.Font, w / 2, h / 2 - 1 + y, Color( 255, 255, 255, 204 ), tac, tac )
	DrawText( s.Title, s.Font, w / 2, h / 2 - 2 + y, Color( 51, 51, 51 ), tac, tac )
end

local function DrawPlainButton( s, w, h )
	local hover = s:IsHovered()
	local col = s.Data[ 1 ]
	
	if hover or s.Data.Active then
		col = Color( col.r, col.g, col.b, s.Data.over and s.Data.over.a or s.Data.a or 80 )
		
		if s.Data.a then
			s.Data[ 2 ] = s.Data.b
		end
	elseif s.Data.a then
		s.Data[ 2 ] = s.Data.c
	end
	
	DrawBox( 0, 0, 0, w, h, col )
	
	if s.Data.Fixed or s.DrawAt then
		if not s.DrawAt then s.DrawAt = h / 2 end
		DrawText( s.Title, s.Font, 10, s.DrawAt, s.Data[ 2 ], tal, tac )
	else
		DrawText( s.Title, s.Font, 10, h / 2, s.Data[ 2 ], tal, tac )
	end
	
	if s.Extra then
		DrawText( s.Extra, s.Font, w - 24, s.DrawAt, s.Data[ 2 ], tar, tac )
	end
	
	if s.Subtitle then
		DrawText( s.Subtitle, "GUIWindowSubTitle", 10, s.DrawAt + 12, Window.C.GText, tal, tac )
	end
	
	if s.Subtitle1 then
		DrawText( s.Subtitle1, s.Font, 10, s.DrawAt + 16, s.Data[ 2 ], tal, tac )
		if s.Subtitle2 then DrawText( s.Subtitle2, s.Font, 10, s.DrawAt + 32, s.Data[ 2 ], tal, tac ) end
		if s.Subtitle3 then DrawText( s.Subtitle3, s.Font, 10, s.DrawAt + 48, s.Data[ 2 ], tal, tac ) end
	end
	
	if hover and s.Data.List then
		DrawBox( 0, 0, 0, 4, h, s.Data.over or Window.C.Opaque )
	end
end

local function DrawCheckbox( s, w, h )
	DrawBox( 0, 0, h / 2 - 10, 20, 20, Color( 170, 170, 170 ) )
	DrawBox( 0, 2, h / 2 - 8, 16, 16, Color( 255, 255, 255 ) )
	DrawBox( 0, 3, h / 2 - 7, 14, 14, s.Checked and Color( 170, 170, 170 ) or Color( 255, 255, 255 ) )
	DrawText( s.Title, "BottomHUDTiny", 25, h / 2, Window.C.Text, tal, tac )
end

local function DrawImageButton( s, w, h )
	surface.SetMaterial( s.Texture )
	surface.SetDrawColor( Color( 255, 255, 255 ) )
	surface.DrawTexturedRect( 1, 1, 16, 16 )
	DrawText( s.Title, "BottomHUDTiny", 25, h / 2, Window.C.Text, tal, tac )
end

function Window.Panel( w, h, x, y )
	local p = VGUIRect( x and x or ScrW() / 2 - w / 2, y and ScrH() * y or ScrH() / 2 - h / 2, w, h )
	
	p.Items = {}
	p.Data = {}
	
	return p
end

function Window.Picker( d, f )
	local wnd = vgui.Create( "DFrame" )
	wnd:SetTitle( "Pick your preferred color!" )
	wnd:SetSize( 267, 210 )
	wnd:SetBackgroundBlur( true )
	wnd:SetDrawOnTop( true )
	wnd:Center()
	wnd:MakePopup()
	
	local pnl = vgui.Create( "DPanel", wnd )
	pnl:SetPos( 5, 30 )
	pnl:SetSize( 257, 148 )
	pnl:SetDrawBackground( false )
	
	local mix = vgui.Create( "DColorMixer", pnl )
	mix:Dock( FILL )
	mix:SetColor( d )
	
	local lab = vgui.Create( "DLabel", wnd )
	lab:SetPos( 5, 186 )
	lab:SetTextColor( Color( 255, 255, 255 ) )
	lab:SetText( "Use 255, 255, 255, 0 for the default color" )
	lab:SizeToContents()
	
	local btn = vgui.Create( "DButton", wnd )
	btn:SetText( "OK" )
	btn:SizeToContents()
	btn:SetTall( 20 )
	btn:SetWide( btn:GetWide() + 20 )
	btn:SetPos( wnd:GetWide() - btn:GetWide() - 5, 183 )
	btn.DoClick = function() local c = mix:GetColor() f( Color( c.r, c.g, c.b, c.a ) ) wnd:Close() end
end

function Window.Label( p, x, y, f, t, c )
	local i = #p.Items + 1
	p.Items[i] = vgui.Create( "DLabel", p )
	
	local it = p.Items[i]
	it:SetPos( x, y )
	it:SetFont( f )
	it:SetTextColor( c )
	
	it.OldSetText = p.Items[i].SetText
	it.SetText = function( s, t )
		s:OldSetText( t )
		s:SizeToContents()
	end
	
	it:SetText( t )
	return it
end

function Window.CloseButton( p, x, y, w, h, c )
	p.CloseAdded = true
	
	local i = #p.Items + 1
	p.Items[i] = vgui.Create( "DButton", p )
	
	local it = p.Items[i]
	it:SetPos( x, y )
	it:SetSize( w, h )
	it:SetText( "" )
	it:SetDrawBackground( false )
	it.Paint = DrawCloseButton
	it.DoClick = c or Window.Close
	return it
end

function Window.GrayButton( p, t, x, y, w, h, b, c )
	local i = #p.Items + 1
	p.Items[i] = vgui.Create( "DButton", p )
	
	local it = p.Items[i]
	it.Title = t
	it.Font = b and "GUIGrayButton" or "GUIGrayButtonLight"
	
	if not w then
		surface.SetFont( it.Font )
		w = surface.GetTextSize( it.Title ) + 20
	end

	it:SetPos( x, y )
	it:SetSize( w, h )
	it:SetText( "" )
	it:SetDrawBackground( false )
	
	it.MouseCallback = function() end
	it.OldMousePressed = it.OnMousePressed
	it.OldMouseReleased = it.OnMouseReleased
	it.OnMousePressed = function( s, c ) s.IsActive = true s:MouseCallback( true ) s:OldMousePressed( c ) end
	it.OnMouseReleased = function( s, c ) s.IsActive = nil s:MouseCallback() s:OldMouseReleased( c ) end
	
	it.Paint = DrawGrayButton
	it.DoClick = c or function() end
	return it
end

function Window.PlainButton( p, t, x, y, w, h, m, c )
	local i = #p.Items + 1
	p.Items[i] = vgui.Create( "DButton", p )
	
	local it = p.Items[i]
	it:SetPos( x, y )
	it:SetSize( w, h )
	it:SetText( "" )
	it:SetDrawBackground( false )
	it.Font = "GUIButtonFont"
	it.Title = t
	it.Data = m
	it.Paint = DrawPlainButton
	it.DoClick = c or function() end
	return it
end

function Window.Check( p, t, x, y, w, h, m, c )
	if not w then
		surface.SetFont( "BottomHUDTiny" )
		w = surface.GetTextSize( t ) + 24
	end
	
	local i = #p.Items + 1
	p.Items[i] = vgui.Create( "DButton", p )
	
	local it = p.Items[i]
	it:SetPos( x, y )
	it:SetText( "" )
	it:SetDrawBackground( false )
	it.BaseTitle = t
	it.High = h
	it.DoClick = c or function() end
	
	it.Check = function( s, v )
		if v != nil then s.Checked = v else s.Checked = not s.Checked end
		s.Title = s.BaseTitle .. " (" .. (s.Checked and "ON" or "OFF") .. ")"
		
		surface.SetFont( "BottomHUDTiny" )
		w = surface.GetTextSize( s.Title ) + 24
		s:SetSize( w, s.High )
		
		return s.Checked, s.Toggle
	end
	
	it.Toggle = m
	it:Check( m.Default() )
	it.Paint = DrawCheckbox
	
	return it
end

function Window.Combo( p, x, y, w, h, t, o, c )
	local i = #p.Items + 1
	p.Items[i] = vgui.Create( "DComboBox", p )
	
	local it = p.Items[i]
	it:SetPos( x, y )
	it:SetSize( w, h )
	
	local default = t.Default()
	it.Toggle = t
	
	if not table.HasValue( o, default ) then
		default = o[ 1 ]
	end

	it:SetValue( default )
	for j = 1, #o do
		it:AddChoice( o[ j ] )
	end
	
	it.OnSelect = c or function() end
	return it
end

function Window.Text( p, x, y, w, h, t, c )
	local i = #p.Items + 1
	p.Items[i] = vgui.Create( "DTextEntry", p )
	
	local it = p.Items[i]
	it:SetPos( x, y )
	it:SetSize( w, h )
	it.Bounds = { x, x + w, y, y + h }

	local default = t.Default()
	it.Default = default
	it.Toggle = t

	it:SetText( default )
	it.OnEnter = c or function() end
	it.Think = Window.TextHandler
	
	return it
end

function Window.ImageButton( p, t, m, x, y, w, h, c )
	if not w then
		surface.SetFont( "BottomHUDTiny" )
		w = surface.GetTextSize( t ) + 24
	end
	
	local i = #p.Items + 1
	p.Items[i] = vgui.Create( "DButton", p )
	
	local it = p.Items[i]
	it:SetPos( x, y )
	it:SetSize( w, h )
	it:SetText( "" )
	it:SetDrawBackground( false )
	it.DoClick = c or function() end
	it.Title = t
	it.Texture = Material( m )
	it.Paint = DrawImageButton
	
	return it
end

function Window.ListView( p, x, y, w, h, f )
	local i = #p.Items + 1
	p.Items[i] = vgui.Create( "DListView", p )
	
	local it = p.Items[i]
	it:SetPos( x, y )
	it:SetSize( w, h )
	it.OnRowSelected = f
	return it
end

function Window.ScrollPanel( p, x, y, w, h )
	local i = #p.Items + 1
	p.Items[i] = vgui.Create( "DScrollPanel", p )
	
	local it = p.Items[i]
	it:SetPos( x, y )
	it:SetSize( w, h )
	it.VBar.OldMousePressed = it.VBar.OnMousePressed
	it.VBar.Paint = function() end
	it.VBar.btnUp.Paint = function( s, w, h ) DrawBox( 8, 3, 4, w - 8, h - 8, Color( 0, 0, 0, 40 ) ) end
	it.VBar.btnDown.Paint = function( s, w, h ) DrawBox( 8, 3, 4, w - 8, h - 8, Color( 0, 0, 0, 40 ) ) end
	it.VBar.btnGrip.Paint = function( s, w, h ) DrawBox( 0, 4, 0, 4, h + 22, Color( 0, 0, 0, 70 ) ) end
	it.VBar.OnMousePressed = function( s, c ) s:Grip() s:OldMousePressed( c ) end
	return it
end

function Window.GenerateContent( s, szIdentifier, args )
	local w, h = s:GetSize()
	if szIdentifier == "Spectate" then
		s.Title = lp():Team() == TEAM_SPECTATOR and "Stop spectating?" or "Join spectators?"
		
		local bw, bh, by = 48, 32, 70
		Window.GrayButton( s, "Yes", w / 2 - 10 - bw, by, bw, bh, true, function() Window.Close() RunConsoleCommand( "spectate" ) end )
		Window.GrayButton( s, "No", w / 2 + 10, by, bw, bh, true, Window.Close )
	elseif szIdentifier == "Style" then
		local data = args.Custom or {}
		local list = Window.ScrollPanel( s, 8, 54, w - 14, h - 54 - 16 )
		list.Items = {}
		
		local function OnClick( s )
			RunConsoleCommand( "style", tostring( s.Data[ 3 ] ) )
			Window.Close()
		end
		
		local c = 0
		local conv = Core.GetTimeConvert()
		
		for i = Core.Config.Style.Normal, Core.Config.MaxStyle do
			local col = c % 2 == 0 and Window.C.BLight or Window.C.BDark
			local add = data[ i ] and " - " .. conv( data[ i ][ 1 ] ) .. " [#" .. data[ i ][ 2 ] .. "]" or ""
			local b = Window.PlainButton( list, Core.StyleName( i ) .. add, 0, c * 30, w - 10, 30, { col, i == lp().Style and Core.Config.Prefixes.Notification or Window.C.Text, i, List = true }, OnClick )
			
			c = c + 1
			list:AddItem( b )
		end
	elseif szIdentifier == "Nominate" then
		local settings = Core.GetSettings()
		local nVersion, nLocal, nCount = args.Custom, settings:Misc( "MapVersion", 0 ), settings:Misc( "MapCount", 0 )
		
		if nLocal != nVersion then
			Core.Send( "MapList", { nLocal } )
			return Window.Close()
		end
		
		s.Sorter = 1
		s.Sorters = { "Name", "Points", "Plays", "Last Played" }
		s.Ascending = true
		
		if Core.Config.IsSurf then
			table.insert( s.Sorters, 3, "Tier" )
		end
		
		local blank = {}
		local thismap = game.GetMap()
		local map = args.Previous or thismap
		local maps = settings:Get( "Maps", blank )
		
		if nCount == 0 or maps == blank then return Core.Print( "General", "The server doesn't seem to have any maps available." ) end
		if args.Server and maps[ map ] and maps[ map ].nPlays != args.Server then
			maps[ map ].nPlays = args.Server
			settings:Save()
		end
		
		local y, hy = 54, h - 54 - 16 - 64
		local list = Window.ScrollPanel( s, 8, y, w - 14, hy )
		local function OnNominate()
			if list.SelectMap then
				RunConsoleCommand( "nominate", list.SelectMap )
			else
				Core.Print( "General", "Please select a map to nominate." )
			end
			
			Window.Close()
		end
		
		local function OnSort( se )
			s.Ascending = not s.Ascending
			
			if s.Ascending then
				s.Sorter = s.Sorter + 1
				
				if s.Sorter > #s.Sorters then
					s.Sorter = 1
				end
			end
			
			local data, items = {}, list:GetCanvas():GetChildren()
			for i = 1, #items do
				local map = maps[ items[ i ].Data[ 3 ] ]
				data[ #data + 1 ] = { Button = items[ i ], Name = items[ i ].Data[ 3 ], Points = map.nMultiplier or 0, Plays = map.nPlays or 0, ["Last Played"] = map.szDate or "9", Tier = map.nTier or 1 }
			end
			
			table.SortByMember( data, s.Sorters[ s.Sorter ], s.Ascending )
			
			local c = 0
			for i = 1, #data do
				data[ i ].Button:SetPos( 0, c * 30 )
				data[ i ].Button.Data[ 1 ] = c % 2 == 0 and Window.C.BLight or Window.C.BDark
				c = c + 1
			end
			
			se.Title = s.Sorters[ s.Sorter ] .. (s.Ascending and ", Asc" or ", Desc")
			Core.Print( "General", "List is now sorted by " .. s.Sorters[ s.Sorter ] .. (s.Ascending and " (Ascending)" or " (Descending)") )
		end
		
		list.Items = {}
		list.Items.Header = Window.Label( s, 16, y + hy + 8, "BottomHUDSemi", "No map selected", Window.C.DText )
		list.Items.Data = Window.Label( s, 16, y + hy + 32, "BottomHUDTiny", "Select a map to see more details", Window.C.Text )
		
		local function OnClick( s )
			local sel = s.Data[ 3 ]
			if Iv( list ) then
				if Iv( list.Last ) and list.Last == s then return end
				
				list.SelectMap = sel
				
				local items = list:GetCanvas():GetChildren()
				for i = 1, #items do
					items[ i ].Data[ 2 ] = items[ i ].Data[ 3 ] == list.SelectMap and Core.Config.Prefixes.Notification or Window.C.Text
				end

				local lab, cont = list.Items.Header, list.Items.Data
				if Iv( lab ) then
					local data = maps[ sel ]
					lab:SetText( sel )
					
					local text = ""
					if Core.Config.IsSurf then
						text = string.format( "Points: %d%s, Plays: %d, Tier %d %s\nLast played: %s", data.nMultiplier, (data.nBonusMultiplier and data.nBonusMultiplier != 0) and ", Bonus: " .. data.nBonusMultiplier or "", data.nPlays, data.nTier, data.nType == 1 and "Staged" or "Linear", data.szDate )
					else
						text = string.format( "Points: %d%s, Plays: %d\nLast played: %s", data.nMultiplier, (data.nBonusMultiplier and data.nBonusMultiplier != 0) and ", Bonus: " .. data.nBonusMultiplier or "", data.nPlays, data.szDate )
					end
					
					cont:SetText( text )
					
					list.Last = s
				end
			end
		end
		
		local function LoopThrough( t, f )
			local keys = {}
			for k,_ in pairs( t ) do
				keys[ #keys + 1 ] = k
			end
			
			table.sort( keys )
			
			for _,k in ipairs( keys ) do
				f( k, t[ k ] )
			end
		end
		
		local c = 0
		LoopThrough( maps, function( k, v )
			local col = c % 2 == 0 and Window.C.BLight or Window.C.BDark
			local isself = map != thismap and k == map
			local name = k .. (k == thismap and " (Current map)" or "")
			local b = Window.PlainButton( list, name, 0, c * 30, w - 10, 30, { col, k == map and Core.Config.Prefixes.Notification or Window.C.Text, k, List = true, Fixed = true }, OnClick )
			b.Extra = Core.Config.IsSurf and (maps[ k ] and "Tier " .. maps[ k ].nTier .. " " .. (maps[ k ].nType == 1 and "Staged" or "Linear")) or (maps[ k ] and maps[ k ].nMultiplier .. " Points")
			
			c = c + 1
			list:AddItem( b )
			
			if isself then
				OnClick( b )
			end
		end )
		
		s:SetTall( s:GetTall() + 30 )
		
		list.Items.Apply = Window.GrayButton( s, "Nominate", 16, y + hy + 70, 90, 24, false, OnNominate )
		list.Items.Sort = Window.GrayButton( s, "Toggle sorting mode", 16 + 90 + 10, y + hy + 70, 168, 24, false, OnSort )
	elseif szIdentifier == "Vote" then
		s.Data = args.List or {}
		s.Votes = {}
		s.DefaultPadding = 40
		s.CloseFunc = function()
			Core.Print( "General", "The vote window was closed. If you want to re-open it, type !revote" )
		end
		
		local text = {}
		for i = 1, 5 do
			if Core.Config.IsSurf then
				if s.Data[ i ][ 5 ] then
					s.Data[ i ][ 5 ] = s.Data[ i ][ 5 ] == 1 and "Staged" or "Linear"
				end
				
				text[ i ] = string.format( "%d. %s (%d points, %d plays) (Tier %d %s)", i, unpack( s.Data[ i ] ) )
			else
				text[ i ] = string.format( "%d. %s (%d points, %d plays)", i, unpack( s.Data[ i ] ) )
			end
		end
		
		text[ #text + 1 ] = #text + 1 .. ". Extend the current map"
		text[ #text + 1 ] = #text + 1 .. ". Change to one of the least played maps"
		
		local txt = "Press and hold " .. Core.GetSettings():ToggleValue( "HUD_CONTEXT" ) .. " to make a selection"
		surface.SetFont( "BottomHUDTiny" )
		
		local wt = surface.GetTextSize( txt )
		s.LabelWidth = wt
		
		local lab = Window.Label( s, w / 2 - wt / 2, h - 30, "BottomHUDTiny", txt, Window.C.Text )
		local list = Window.ScrollPanel( s, 8, 54, w - 16, h - 54 - 16 )
		list.Items = {}
		list.LastVoted = 0

		function s:UpdateByWidest()
			surface.SetFont( "GUIButtonFont" )
			
			local items = list:GetCanvas():GetChildren()
			local nw = 0
			
			for i = 1, #items do
				local wt = surface.GetTextSize( items[ i ].Title )
				if wt > nw then
					nw = wt
				end
			end
			
			self:ScaleWideTo( nw + self.DefaultPadding )
		end
		
		function s:ScaleWideTo( x )
			local w, h = self:GetSize() w = x
			self:SetSize( w, h )
			list:SetWide( w - 16 )
			
			local lx, ly = lab:GetPos()
			lab:SetPos( w / 2 - self.LabelWidth / 2, ly )
			
			local items = list:GetCanvas():GetChildren()
			if self.MainClose then
				self.MainClose:SetPos( w - 16 - 8, 8 )
			end
			
			for i = 1, 7 do
				if not Iv( items[ i ] ) then continue end
				items[ i ]:SetSize( w - 10, 30 )
			end
		end
		
		local function OnClick( s, auto )
			if st() - list.LastVoted < 1 then
				if not auto then
					Core.Print( "General", "Please wait before voting again." )
				end
				
				return false
			end
			
			list.LastVoted = st()
			s.Active = true
			
			local items = list:GetCanvas():GetChildren()
			for i = 1, #items do
				items[ i ].Data[ 2 ] = items[ i ].Active and Core.Config.Prefixes.Notification or Window.C.Text
			end
			
			s.Active = nil

			Core.Send( "Vote", { s.Data.ID, list.VotedID } )
			list.VotedID = s.Data.ID
		end
		
		local function OnKey( id )
			if id < 1 then return end
			local item = list.Items[ id - 1 ]
			if Iv( item ) then OnClick( item, true ) end
		end
		
		function s:Update( ar )
			local tot = 0
			for i = 1, 7 do
				local v = ar:UInt( 8 )
				self.Votes[ i ] = v > 0 and v
				tot = tot + v
			end
			
			local items = list:GetCanvas():GetChildren()
			for i = 1, 7 do
				if not Iv( items[ i ] ) then continue end
				items[ i ].Title = items[ i ].Data.Base .. ((self.Votes[ i ] and self.Votes[ i ] > 0) and string.format( " (%d %s)", self.Votes[ i ], self.Votes[ i ] != 1 and "votes" or "vote" ) or "")
				
				self:UpdateByWidest()
			end
			
			local nt = string.format( "%d / %d players voted", tot, #player.GetHumans() )
			surface.SetFont( "BottomHUDTiny" )
			local wtx = surface.GetTextSize( nt )

			local w, h = self:GetSize()
			lab:SetPos( w / 2 - wtx / 2, h - 30 )
			lab:SetText( nt )
		end
		
		function s:SetBeaten( data )
			local items = list:GetCanvas():GetChildren()
			local low, count, id = 200, 0, 0
			for i = 1, 5 do
				if data[ i ] then
					local points = data[ i ] * 100
					items[ i ].DrawAt = items[ i ]:GetTall() / 2 - 4
					items[ i ].Subtitle = "Points: " .. math.Round( points, 1 ) .. "%"
					items[ i ].Font = "GUIButtonFontIt"
					
					if points < low then
						low = points
						id = i
					end
					
					count = count + 1
				end
			end
			
			if id > 0 and count == 5 then
				items[ id ].Subtitle = items[ id ].Subtitle .. " (Recommended)"
			end
		end
		
		function s:InstantVote( data )
			OnKey( data[ 1 ] + 1 or -1 )
		end
		
		function s:ThinkHook( bType )
			if bType then return end
			for i = 2, 8 do
				if KeyCheck( i ) then
					OnKey( i )
					break
				end
			end
		end
		
		local c = 0
		for i = 1, 7 do
			local col = c % 2 == 0 and Window.C.BLight or Window.C.BDark
			list.Items[ i ] = Window.PlainButton( list, text[ i ], 0, c * 30, w - 10, 30, { col, Window.C.Text, ID = i, List = true, Base = text[ i ] }, OnClick )
			
			c = c + (i == 5 and 2 or 1)
			list:AddItem( list.Items[ i ] )
		end
		
		Window.Cache.EndTime = st() + s.Data.Countdown or 30
		s:UpdateByWidest()
		
		timer.Create( "TitleRefresh", 0.1, 0, function()
			if not Iv( ActiveWindow ) or not Window.Cache.EndTime or not ActiveWindow.Title then return end
			if ActiveWindow.Identifier != "Vote" then return end
			local t = math.ceil( math.Clamp( Window.Cache.EndTime - st(), 0, 1e10 ) )
			local title = "Voting (" .. t .. "s remaining)"
			if ActiveWindow.Title != title then ActiveWindow.Title = title end
			if t == 0 then
				timer.Remove( "TitleRefresh" )
				timer.Simple( 1, function() Window.Close( true ) end )
			end
		end )
	elseif szIdentifier == "Records" then
		local tabRecord, nCount, nStyle, nAt = args.Custom[ 1 ], args.Custom[ 2 ], args.Custom[ 3 ], args.Custom[ 4 ] or 0
		s.Count = nCount
		s.Title = Core.StyleName( nStyle ) .. " Records"
		s.Style = nStyle
		s.Started = args.Custom.Started or 1
		s.Loaded = s.Count <= 25 and s.Count or 25
		s.TargetID = args.Custom.TargetID
		
		if args.Custom.Map then
			s.Title = s.Title .. " for \"" .. args.Custom.Map .. "\""
			s.Map = args.Custom.Map
		end
		
		if nAt > 0 then
			s.Subtitle = "You are at #" .. nAt
		end
		
		local function OnClick( se )
			local high = se.Expanded and -48 or 48
			se.Expanded = not se.Expanded
			se:SetTall( se:GetTall() + high )
			
			local split = string.Explode( " ", se.Content.vData or "" )
			if se.Expanded then
				se.Subtitle1 = "Steam ID: " .. se.Content.szUID .. " - Run obtained on: " .. Core.ToDate( se.Content.nDate )
				se.Subtitle2 = "Obtained points: " .. math.Round( se.Content.nPoints, 2 )
				
				if #split > 1 then
					local hold = {}
					hold[ #hold + 1 ] = split[ 2 ] and "Average speed: " .. split[ 2 ]
					hold[ #hold + 1 ] = split[ 3 ] and "Jumps: " .. split[ 3 ]
					hold[ #hold + 1 ] = split[ 4 ] and "Strafes: " .. split[ 4 ]
					hold[ #hold + 1 ] = split[ 5 ] and "Sync: " .. split[ 5 ] .. "%"
					hold[ #hold + 1 ] = split[ 6 ] and "Perfect: " .. split[ 6 ] .. "%"
					
					if split[ 1 ] then
						se.Subtitle2 = se.Subtitle2 .. " - " .. (Core.Config.IsSurf and "Start speed: " or "Top speed: ") .. split[ 1 ]
					end
					
					se.Subtitle3 = string.Implode( " - ", hold )
				else
					se.Subtitle3 = "No more details available"
				end
				
				se.Subtitle2 = se.Subtitle2 .. " - Exact time: " .. string.format( "%.12f", se.Content.nTime )
			else
				se.Subtitle1 = nil
				se.Subtitle2 = nil
				se.Subtitle3 = nil
			end
			
			for _,item in pairs( se:GetParent():GetParent():GetCanvas():GetChildren() ) do
				if item.AtID > se.AtID then
					local x, y = item:GetPos()
					item:SetPos( x, y + high )
				end
			end
		end
		
		local function OnRightClick( se )
			if s.Removal then
				return s.Removal( se )
			end
			
			gui.OpenURL( "http://steamcommunity.com/profiles/" .. util.SteamIDTo64( se.Content.szUID or "" ) )
		end
		
		local function OnExpand( se )
			if not se.IsRetrieving then
				se.IsRetrieving = true
				se.Title = "Please wait..."
				
				local parent = se:GetParent()
				Core.Send( "RetrieveList", { parent.Style, se.NextLoad, parent.Map } )
			end
		end
		
		function s:Update( varArgs )
			local tab = varArgs[ 1 ]
			self.Count = varArgs[ 2 ]
			self.Started, self.Loaded = nil, nil
			
			for at,__ in pairs( tab ) do
				if not self.Started then self.Started = at end
				if not self.Loaded then self.Loaded = at end
				
				if at < self.Started then self.Started = at end
				if at > self.Loaded then self.Loaded = at end
			end
			
			local btn = self.MainList.Items.More
			btn.IsRetrieving = false
			
			self.DispLabel:SetText( self.Loaded .. " / " .. self.Count )
			
			local remain = self.Count - self.Loaded
			if remain > 0 then
				local count = math.Clamp( remain, 1, 25 )
				btn.Title = "Load " .. count .. " more record" .. (count != 1 and "s" or "")
				btn.NextLoad = { self.Loaded + 1, self.Loaded + count }
			else
				self.DispLabel:Remove()
				self:SetTall( self:GetTall() - 30 )
				btn:Remove()
			end
			
			for _,item in pairs( s.MainList:GetCanvas():GetChildren() ) do
				if item.Expanded then
					item:SetTall( item:GetTall() - 48 )
					item.Expanded = nil
					item.Subtitle1 = nil
					item.Subtitle2 = nil
					item.Subtitle3 = nil
				end
				
				item:SetPos( 0, item.AtID * 30 )
			end
			
			local last, child, own = 0
			for i,data in SortedPairs( tab ) do
				if not tab[ i ] then continue end
				local col = self.atpos % 2 == 0 and Window.C.BLight or Window.C.BDark
				local b = Window.PlainButton( self.MainList, i .. ". Loading...", 0, s.atpos * 30, w - 10, 30, { col, self.localid == data.szUID and Core.Config.Prefixes.Notification or Window.C.Text, List = true, Fixed = true }, OnClick )
				b.Extra = self.convert( data.nTime or 0 )
				b.Content = data
				b.AtID = self.atpos
				b.DoRightClick = OnRightClick
				self.MainList:AddItem( b )
				self.atpos = self.atpos + 1
				last = last + 1
				if not child then child = b end
				if last == 5 then child = b end
				if data.szUID == s.localid then own = b end
				
				Core.GetPlayerName( util.SteamIDTo64( data.szUID or "" ), function( uid, name, arg )
					if IsValid( b ) then
						b.Title = arg .. ". " .. name
					end
				end, i )
			end
			
			if own or child then
				self.MainList:ScrollToChild( own or child )
			end
		end
		
		local y, hy = 54, h - 54 - 16 - 30
		local list = Window.ScrollPanel( s, 8, y, w - 14, hy )
		list.Items = {}
		s.MainList = list
		s.DispLabel = Window.Label( s, 20, y + hy + 14, "GUIWindowSubTitle", (s.Started + s.Loaded - 1) .. " / " .. s.Count, Window.C.GText )
		
		local shortened = false
		local remain = s.Count - (s.Started + s.Loaded - 1)
		if remain > 0 then
			local count = math.Clamp( remain, 1, 25 )
			list.Items.More = Window.GrayButton( s, "Load " .. count .. " more record" .. (count != 1 and "s" or ""), 0, 0, nil, 24, false, OnExpand )
			list.Items.More.NextLoad = { s.Started + s.Loaded, s.Started + s.Loaded + count - 1 }
			
			local mw = list.Items.More:GetWide()
			list.Items.More:SetPos( w / 2 - mw / 2, y + hy + 7 )
		else
			s.DispLabel:Remove()
			s:SetTall( s:GetTall() - 30 )
			shortened = true
		end
		
		if args.Custom.IsEdit then
			s.RemoveItems = {}
			
			function s.Removal( se )
				s.RemoveItems[ se.Content.szUID ] = not s.RemoveItems[ se.Content.szUID ]
				se.Data[ 2 ] = s.RemoveItems[ se.Content.szUID ] and Color( 0, 190, 255 ) or Window.C.Text
			end
			
			local function OnEdit( se )
				local items = {}
				local parent = se:GetParent()
				
				for _,item in pairs( parent.MainList:GetCanvas():GetChildren() ) do
					if parent.RemoveItems[ item.Content.szUID ] then
						items[ #items + 1 ] = item.Content
						item:Remove()
					end
				end
				
				if #items > 0 then
					Core.Send( "RemoveList", { parent.Style, items, parent.Map } )
				else
					Core.Print( "Admin", "No items were selected (they have to be selected)" )
				end
			end
			
			local function OnRequest( se )
				Derma_StringRequest( "Remove times", "Are you sure you want to remove these times?\nType 'Yes' to continue", "No", function( r ) if r == "Yes" then OnEdit( se ) end end, function() end )
			end
		
			list.Items.Edit = Window.GrayButton( s, "Remove selected", 0, 0, nil, 24, false, OnRequest )
			local mw = list.Items.Edit:GetWide()
			list.Items.Edit:SetPos( w - mw - 20, y + hy + 7 )
			
			if shortened then
				s:SetTall( s:GetTall() + 30 )
			end
		end
		
		s.convert = Core.GetTimeConvert()
		s.localid = Iv( lp() ) and lp():SteamID() or ""
		s.atpos = 0

		for i = s.Started, s.Started + s.Loaded - 1 do
			local tab = tabRecord[ i ]
			if not tab then continue end
			local col = s.atpos % 2 == 0 and Window.C.BLight or Window.C.BDark
			local b = Window.PlainButton( list, i .. ". Loading...", 0, s.atpos * 30, w - 10, 30, { col, s.localid == tab.szUID and Core.Config.Prefixes.Notification or Window.C.Text, List = true, Fixed = true }, OnClick )
			b.Extra = s.convert( tab.nTime or 0 )
			b.Content = tab
			b.AtID = s.atpos
			b.DoRightClick = OnRightClick
			list:AddItem( b )
			s.atpos = s.atpos + 1
			if s.TargetID then if i == s.TargetID then s.OwnID = b end
			elseif tab.szUID == s.localid then s.OwnID = b end
			
			Core.GetPlayerName( util.SteamIDTo64( tab.szUID or "" ), function( uid, name, arg )
				if IsValid( b ) then
					b.Title = arg .. ". " .. name
				end
			end, i )
		end
		
		if s.OwnID then
			list:ScrollToChild( s.OwnID )
		end
		
		if s.atpos <= 10 then
			list:SetWide( list:GetWide() - 3 )
		end
	elseif szIdentifier == "Top" then
		s.Count = args.Custom.Count
		s.ViewType = args.Custom.ViewType
		s.Data = args.Custom.Data
		s.Style = args.Custom.Style
		s.Offset = 1
		s.Item = 0
		
		local function OnClick( se )
			if not se.Content.szUID then return end
			gui.OpenURL( "http://steamcommunity.com/profiles/" .. util.SteamIDTo64( se.Content.szUID or "" ) )
		end

		local y, hy, ih = 54, h - 54 - 16, (s.ViewType == 4 or s.ViewType == 8) and 46 or 30
		local list = Window.ScrollPanel( s, 8, y, w - 14, hy )
		list.Items = {}
		s.MainList = list
		
		if s.ViewType == 2 then
			s.Total = args.Custom.Total
			s.Style = args.Custom.Style
			s.StageID = args.Custom.ID
			s.Pos = args.Custom.Pos
			s.LastLoad = s.Count
			s.DispLabel = Window.Label( s, 20, y + hy + 14, "GUIWindowSubTitle", s.Count .. " / " .. s.Total, Window.C.GText )
			
			local function OnExpand( se )
				if not se.IsRetrieving then
					se.IsRetrieving = true
					se.Title = "Please wait..."
					
					local parent = se:GetParent()
					Core.Send( "RetrieveStages", { parent.Style, parent.StageID, parent.LastLoad } )
				end
			end
			
			local remain = s.Total - s.Count
			if remain > 0 then
				local count = math.Clamp( remain, 1, 50 )
				list.Items.More = Window.GrayButton( s, "Load " .. count .. " more record" .. (count != 1 and "s" or ""), 0, 0, nil, 24, false, OnExpand )
				
				local mw = list.Items.More:GetWide()
				list.Items.More:SetPos( w / 2 - mw / 2, y + hy + 7 )
				
				s:SetTall( s:GetTall() + 30 )
			else
				s.DispLabel:Remove()
			end
			
			if s.Pos and s.Pos > 0 then
				s.Subtitle = "You are at #" .. s.Pos
			end
		end
		
		if args.Custom.IsEdit then
			s.RemoveItems = {}
			
			function s.Removal( se )
				if not se.Content.szUID then return end
				s.RemoveItems[ se.Content.szUID ] = not s.RemoveItems[ se.Content.szUID ]
				se.Data[ 2 ] = s.RemoveItems[ se.Content.szUID ] and Color( 0, 190, 255 ) or Window.C.Text
			end
			
			local function OnEdit( se )
				local items = {}
				local parent = se:GetParent()
				
				for _,item in pairs( parent.MainList:GetCanvas():GetChildren() ) do
					if parent.RemoveItems[ item.Content.szUID ] then
						items[ #items + 1 ] = item.Content.szUID
						item:Remove()
					end
				end
				
				if #items > 0 then
					Core.Send( "RemoveList", { parent.Style, parent.StageID, items, parent.ViewType } )
				else
					Core.Print( "Admin", "No items were selected (they have to be blue)" )
				end
			end
			
			local function OnRequest( se )
				Derma_StringRequest( "Remove times", "Are you sure you want to remove these times?\nType 'Yes' to continue", "No", function( r ) if r == "Yes" then OnEdit( se ) end end, function() end )
			end
			
			list.Items.Edit = Window.GrayButton( s, "Remove", 0, 0, nil, 24, false, OnRequest )
			local mw = list.Items.Edit:GetWide()
			list.Items.Edit:SetPos( w - mw - 20, y + hy + 7 )
		end
		
		s.convert = Core.GetTimeConvert()
		s.localid = Iv( lp() ) and lp():SteamID() or ""
		s.UIDData, s.ButtonData = {}, {}
		
		function s.BuildItems()
			for i = s.Offset, s.Count do
				local tab = s.Data[ i ]
				local col = s.Item % 2 == 0 and Window.C.BLight or Window.C.BDark
				local b = Window.PlainButton( list, "", 0, s.Item * ih, w - 10, ih, { col, s.localid == tab.szUID and Core.Config.Prefixes.Notification or Window.C.Text, List = true, Fixed = true }, s.Removal or OnClick )

				if s.localid == tab.szUID then
					s.selfply = b
				end
				
				if tab.szUID and not tab.szText then
					local id64 = util.SteamIDTo64( tab.szUID or "" )
					s.UIDData[ #s.UIDData + 1 ] = id64
					s.ButtonData[ #s.UIDData ] = b
					b.Title = i .. ". Loading..."
					
					if tab.szAppend then
						b.Pre = "Stage "
						b.Post = tab.szAppend
					elseif tab.szPrepend then
						b.Pre = tab.szPrepend
						b.Post = ""
					end
				else
					b.Title = tab.szText
				end
				
				if s.ViewType == 0 then
					b.Extra = math.Round( tab.nSum, 2 ) .. " Points, Maps Left: " .. tab.nLeft
				elseif s.ViewType == 1 then
					b.Extra = tab.nWins .. " wins (Streak: " .. tab.nStreak .. ")"
				elseif s.ViewType == 4 then
					b.DrawAt = 30 / 2
					b.Extra = s.convert( tab.nTime )
					b.Expanded = true
					b.Subtitle1 = "Time taken: " .. s.convert( tab.nReal or 0 ) .. " - Date: " .. Core.ToDate( tab.nDate )
				elseif s.ViewType == 7 then
					b.Extra = tab.nCount .. " WRs"
				elseif s.ViewType == 8 then
					b.DrawAt = 30 / 2
					b.Extra = tab.nValue .. " units"
					b.Expanded = true
					b.Subtitles = {}
					
					local split = string.Explode( " ", tab.vData )
					if split[ 1 ] then b.Subtitles[ #b.Subtitles + 1 ] = "Pre: " .. split[ 1 ] .. " u/s" end
					if split[ 2 ] then b.Subtitles[ #b.Subtitles + 1 ] = "Sync: " .. split[ 2 ] .. "%" end
					if split[ 3 ] then b.Extra = b.Extra .. " (Strafes: " .. split[ 3 ] .. ")" end
					if split[ 4 ] and tonumber( split[ 4 ] ) > 1 then b.Subtitles[ #b.Subtitles + 1 ] = "Style: " .. Core.StyleName( tonumber( split[ 4 ] ) ) end
					if split[ 5 ] then b.Subtitles[ #b.Subtitles + 1 ] = "Edge: " .. split[ 5 ] .. " u" end
					
					b.Subtitles[ #b.Subtitles + 1 ] = "Date: " .. Core.ToDate( tab.nDate, true )
					
					b.Subtitle1 = string.Implode( ", ", b.Subtitles )
				elseif tab.nTime then
					b.Extra = s.convert( tab.nTime )
				end
				
				b.Content = tab
				list:AddItem( b )
				s.Item = s.Item + 1
			end
		end
		
		function s.NameItems()
			for i = 1, #s.UIDData do
				Core.GetPlayerName( s.UIDData[ i ], function( uid, name, arg )
					if IsValid( ActiveWindow ) and ActiveWindow.ButtonData then
						local btn = ActiveWindow.ButtonData[ i ]
						if IsValid( btn ) then
							btn.Title = (btn.Pre or "") .. arg .. ". " .. name .. (btn.Post or "")
						end
					end
				end, i + s.Offset - 1 )
			end
		end
		
		if s.ViewType == 2 then
			function s:Update( varArgs )
				self.Total = varArgs.Count
				self.LastLoad = varArgs.Top
				self.Count = varArgs.Top
				self.Offset = varArgs.Bottom
				
				for i = varArgs.Bottom, varArgs.Top do
					self.Data[ i ] = varArgs[ 1 ][ i ]
				end
				
				self.UIDData, self.ButtonData = {}, {}
				self.BuildItems()
				self.NameItems()
				self.DispLabel:SetText( self.Count .. " / " .. self.Total )
				
				local btn = self.MainList.Items.More
				btn.IsRetrieving = false
				
				local remain = self.Total - self.Count
				if remain > 0 then
					local count = math.Clamp( remain, 1, 50 )
					btn.Title = "Load " .. count .. " more record" .. (count != 1 and "s" or "")
				else
					self.DispLabel:Remove()
					self:SetTall( self:GetTall() - 30 )
					btn:Remove()
				end
				
				local got
				for i = 1, #s.ButtonData do
					btn = s.ButtonData[ i ]
					if btn.Content.szUID == self.localid then
						got = btn
						break
					elseif i <= 5 then
						got = btn
					end
				end
				
				if got then
					self.MainList:ScrollToChild( got )
				end
			end
		end
		
		s.BuildItems()
		s.NameItems()
		
		if s.selfply then
			list:ScrollToChild( s.selfply )
		end
		
		if s.Count <= 10 * (30 / ih) then
			list:SetWide( list:GetWide() - 3 )
		end
	elseif szIdentifier == "Ranks" then
		local nStyle = args.Custom[ 3 ]
		if args.Custom[ 4 ] then
			args.Custom[ 1 ] = nil
			args.Custom[ 2 ] = nil
			
			nStyle = nil
		end
		
		s.Title = s.Title .. (args.Custom[ 2 ] and " (" .. math.floor( args.Custom[ 2 ] ) .. " pts)" or "")
		
		local list = Window.ScrollPanel( s, 8, 54, w - 14, h - 54 - 16 )
		list.Items = {}
		
		local function OnClick( s )
		end
		
		local c, child = 0
		for i = 1, #Core.Config.Ranks do
			local rd = Core.Config.Ranks[ i ]
			local luminance = 0.2126 * rd[ 2 ].r + 0.7152 * rd[ 2 ].g + 0.0722 * rd[ 2 ].b
			local col = luminance > 255 / 2 and (c % 2 == 0 and Color( 43, 43, 43 ) or Color( 27, 27, 27 )) or (c % 2 == 0 and Window.C.BLight or Window.C.BDark)
			local pts = rd[ 3 ][ nStyle ]
			local b = Window.PlainButton( list, (args.Custom[ 1 ] == i and "> " or "") .. rd[ 1 ] .. (pts and " (" .. math.floor( pts ) .. " pts)" or ""), 0, c * 30, w - 10, 30, { col, rd[ 2 ], i, List = true, over = Color( 255 - col.r, 255 - col.g, 255 - col.b, 255 ) }, OnClick )
			
			c = c + 1
			list:AddItem( b )
			
			if args.Custom[ 1 ] == i then
				child = b
			end
		end
		
		if child then
			list:ScrollToChild( child )
		end
	elseif szIdentifier == "Stats" then
		local v = args.Custom
		s.Title = v.Title .. s.Title

		local tabRender = {
			"Distance: " .. v.Distance .. " units",
			"Prestrafe: " .. v.Prestrafe .. " u/s",
			"Average Sync: " .. v.Sync .. "%",
			"Strafes: " .. #v.SyncValues
		}
		
		if v.Edge then
			table.insert( tabRender, 3, "Edge: " .. v.Edge .. " u" )
			s:SetTall( s:GetTall() + 24 )
		end
		
		if v.Specials then
			table.insert( tabRender, v.Specials )
			s:SetTall( s:GetTall() + 24 )
		end
		
		if Core.GetSettings():ToggleValue( "NOTIFY_LJSTATS" ) then
			table.insert( tabRender, table.remove( tabRender, 4 ) )
			
			local nThis = math.Round( v.Prestrafe )
			for i = 1, #v.SyncValues do
				local nGain, nLoss = 0, 0
				local nNext = v.SpeedValues[ i ]
				
				if nNext then
					if nNext > nThis then nGain = nNext - nThis
					elseif nNext < nThis then nLoss = nThis - nNext end
					
					nThis = nNext
				end
				
				table.insert( tabRender, string.format( "- %du %s %d%% %dms", nThis, nLoss > 0 and "-" .. nLoss or (nGain > 0 and "+" .. nGain) or 0, v.SyncValues[ i ], v.TimeValues[ i ] ) )
				s:SetTall( s:GetTall() + 24 )
			end
		end
		
		for i = 1, #tabRender do
			Window.Label( s, 20, 36 + i * 24, "BottomHUDSemi", tabRender[ i ], Window.C.Text )
		end
		
		if timer.Exists( "StatsCloser" ) then
			timer.Remove( "StatsCloser" )
		end
		
		timer.Create( "StatsCloser", 5, 1, function() if Window.IsActive( "Stats" ) then Window.Close() end end )
	elseif szIdentifier == "Maps" then
		local main = args.Custom[ 1 ] or {}
		s.Style = args.Custom.Style
		s.Type = args.Custom.Type
		s.Count = #main
		s.Left = {}
		
		if s.Type then
			if s.Type != "NoWR" then
				s.Title = szIdentifier .. " " .. s.Type .. " on " .. Core.StyleName( s.Style or 1 )
			end
			
			if s.Type == "Left" or s.Type == "NoWR" then
				local settings = Core.GetSettings()
				local nVersion, nLocal = args.Custom.Version, settings:Misc( "MapVersion", 0 )
				
				if nLocal != nVersion then
					Core.Send( "MapList", { nLocal, args.Custom.Command } )
					return Window.Close()
				else
					local maps = table.Copy( settings:Get( "Maps", {} ) )

					for i = 1, s.Count do
						maps[ main[ i ].szMap ] = nil
					end

					local sorted = {}
					for map,data in pairs( maps ) do
						if s.Style < 0 then
							local m = data.nBonusMultiplier
							if m == 0 then continue end
							
							-- To-Do: Bonus fix needed! Won't work anymore
							local bid = s.Style - Core.Config.Style.Bonus + 1
							if type( m ) == "string" and string.find( m, ", ", 1, true ) then
								local spl = string.Explode( ", ", m )
								for i = 1, #spl do
									spl[ i ] = tonumber( spl[ i ] )
								end
								
								if spl[ bid ] then
									data.nMultiplier = spl[ bid ]
								else
									continue
								end
							elseif bid > 1 then
								continue
							else
								data.nMultiplier = data.nBonusMultiplier
							end
						end
						
						data.szMap = map
						sorted[ #sorted + 1 ] = data
					end

					table.SortByMember( sorted, "nMultiplier", true )
					s.Left = sorted
				end
				
				s.Count = #s.Left
			elseif s.Type == "Beat" then
				table.SortByMember( main, "nDate" )
				
				local maps = Core.GetSettings():Get( "Maps", {} )
				for i = 1, s.Count do
					local data = maps[ main[ i ].szMap ]
					if data then
						local isb = s.Style < 0
						local mult = isb and data.nBonusMultiplier or data.nMultiplier
						if not mult then continue end
						
						if isb and type( mult ) == "string" and string.find( mult, ", ", 1, true ) then
							local spl = string.Explode( ", ", mult )
							for i = 1, #spl do
								spl[ i ] = tonumber( spl[ i ] )
							end
							
							-- To-Do: This wouldn't work anymore
							local bid = s.Style - Core.Config.Style.Bonus + 1
							mult = spl[ bid ] or 1
						end
						
						if mult == 0 then mult = 1 end
						local perc = (main[ i ].nPoints / mult) * 100
						main[ i ].Percentage = " - " .. math.Round( perc, 1 ) .. "%"
						
						if perc < 95 then
							main[ i ].Highlight = true
						end
					end
				end
			end
			
			s.Title = s.Title .. " (#" .. s.Count .. ")"
		end
		
		if args.Custom.SteamID then
			Core.GetPlayerName( util.SteamIDTo64( args.Custom.SteamID ), function( uid, name, arg )
				if IsValid( arg ) then
					arg.Title = arg.Title .. " (By " .. name .. ")"
				end
			end, s )
		end
		
		local function OnClick( se )
			local dy = 16
			if not s.Type then
				dy = 32
				
				se.Subtitle1 = "On " .. Core.ToDate( se.Content.nDate ) .. ", Points: " .. math.Round( se.Content.nPoints or 0 )
				
				local split = string.Explode( " ", se.Content.vData or "" )
				if #split > 1 then
					if split[ 1 ] then se.Subtitle1 = se.Subtitle1 .. ", " .. (Core.Config.IsSurf and "Start: " or "Top: ") .. split[ 1 ] end
					if split[ 2 ] then se.Subtitle1 = se.Subtitle1 .. ", Average: " .. split[ 2 ] end
					
					local hold = {}
					hold[ #hold + 1 ] = split[ 3 ] and "Jumps: " .. split[ 3 ]
					hold[ #hold + 1 ] = split[ 4 ] and "Strafes: " .. split[ 4 ]
					hold[ #hold + 1 ] = split[ 5 ] and "Sync: " .. split[ 5 ] .. "%"
					hold[ #hold + 1 ] = split[ 6 ] and "Perfect: " .. split[ 6 ] .. "%"
					
					se.Subtitle2 = string.Implode( ", ", hold )
				else
					se.Subtitle2 = "No more details available"
				end
			elseif s.Type == "Left" or s.Type == "NoWR" then
				if not se.Expanded then
					local itm = s.LastSelected
					if Iv( itm ) and se != itm then
						itm.Data[ 2 ] = Window.C.Text
					end
					
					se.Data[ 2 ] = Core.Config.Prefixes.Notification
					se.Subtitle1 = "Played " .. se.Content.nPlays .. " times, last on " .. se.Content.szDate
					s.LastSelected = se
				end
			elseif s.Type == "Beat" and se.Content.szMap then
				RunConsoleCommand( "nominate", se.Content.szMap )
				return Window.Close()
			end

			local high = se.Expanded and -dy or dy
			se.Expanded = not se.Expanded
			se:SetTall( se:GetTall() + high )
			
			if not se.Expanded then
				se.Subtitle1 = nil
				se.Subtitle2 = nil
				se.Subtitle3 = nil
			end
			
			for _,item in pairs( se:GetParent():GetParent():GetCanvas():GetChildren() ) do
				if item.AtID > se.AtID then
					local x, y = item:GetPos()
					item:SetPos( x, y + high )
				end
			end
		end

		local y, hy = 54, h - 54 - 16
		local list = Window.ScrollPanel( s, 8, y, w - 14, hy )
		list.Items = {}
		
		s.convert = Core.GetTimeConvert()
		local tab = (s.Type == "Left" or s.Type == "NoWR") and s.Left or main
		
		local c = 0
		for i = 1, s.Count do
			if not tab[ i ] then continue end
			
			local col = c % 2 == 0 and Window.C.BLight or Window.C.BDark
			local text, extra = ""
			
			if s.Type then
				text = (s.Type == "Left" or s.Type == "NoWR") and tab[ i ].szMap or tab[ i ].szMap .. " (Points: " .. math.Round( tab[ i ].nPoints, 2 ) .. (tab[ i ].Percentage and tab[ i ].Percentage or "") .. ")"
				
				if Core.Config.IsSurf then
					extra = s.Type == "Beat" and s.convert( tab[ i ].nTime or 0 ) or math.floor( tab[ i ].nMultiplier or 0 ) .. " Points (Tier " .. (tab[ i ].nTier or 1) .. " " .. (tab[ i ].nType == 1 and "Staged" or "Linear") .. ")"
				else
					extra = s.Type == "Beat" and s.convert( tab[ i ].nTime or 0 ) or math.floor( tab[ i ].nMultiplier or 0 ) .. " Points"
				end
			else
				text = tab[ i ].szMap .. " (" .. Core.StyleName( tab[ i ].nStyle or 1 ) .. " style)"
				extra = s.convert( tab[ i ].nTime or 0 )
			end
			
			local b = Window.PlainButton( list, i .. ". " .. text, 0, c * 30, w - 10, 30, { col, tab[ i ].Highlight and Core.Config.Prefixes.Notification or Window.C.Text, List = true, Fixed = true }, OnClick )
			b.Extra = extra
			b.Content = tab[ i ]
			b.AtID = i
			list:AddItem( b )
			c = c + 1
		end

		if s.Count <= 10 then
			list:SetWide( list:GetWide() - 3 )
		end
		
		if s.Type == "Left" or s.Type == "NoWR" then
			s:SetTall( s:GetTall() + 30 )
			
			local function OnNominate()
				local map = Iv( s.LastSelected ) and s.LastSelected.Content.szMap
				
				if not map then
					for _,item in pairs( list:GetCanvas():GetChildren() ) do
						if item.Expanded then
							map = item.Content.szMap
						end
					end
				end
				
				if map then
					RunConsoleCommand( "nominate", map )
				else
					Core.Print( "General", "Please select a map to nominate by clicking on any entry in the list" )
				end
				
				Window.Close()
			end

			list.Items.Nominate = Window.GrayButton( s, "Nominate this map", 0, 0, nil, 24, false, OnNominate )
			
			local mw = list.Items.Nominate:GetWide()
			list.Items.Nominate:SetPos( w / 2 - mw / 2, y + hy + 7 )
		end
	elseif szIdentifier == "Checkpoints" then
		if not Window.Cache.Checkpoints then Window.Cache.Checkpoints = {} end
		local tab = Window.Cache.Checkpoints
		
		local hy = h - 54 - 46
		local list = Window.ScrollPanel( s, 8, 54, w - 16, hy )
		list.Items = {}
		
		s.OnTrigger = function( s, c, d, w )
			if not s.LastSent or st() - s.LastSent > 0.2 then
				Core.Send( "Checkpoints", { c, s.IsDelay, d, w } )
				
				s.LastSent = st()
				
				if d or w then
					if d and c == tab.LastLoaded then tab.LastLoaded = nil end
					if d and c == tab.LastSaved then tab.LastSaved = nil end
					if w then tab.LastLoaded = nil tab.LastSaved = nil end
				elseif c > 2 then
					if not tab[ c ] then tab.LastSaved = c else tab.LastLoaded = c end
				elseif c == 2 and tab.LastSaved then
					tab.LastLoaded = tab.LastSaved
				end
				
				for _,item in pairs( list:GetCanvas():GetChildren() ) do
					if item.Data[ 3 ] == 1 then
						item.Title = "1. Load last loaded" .. (tab.LastLoaded and " (#" .. tab.LastLoaded .. ")" or "")
					elseif item.Data[ 3 ] == 2 then
						item.Title = "2. Load last saved" .. (tab.LastSaved and " (#" .. tab.LastSaved .. ")" or "")
					end
				end
			end
		end
		
		function s:ThinkHook( bType )
			if bType then return end
			for i = 2, 10 do
				if KeyCheck( i ) then
					self:OnTrigger( i - 1 )
					break
				end
			end
		end
		
		s.Update = function( s, varArgs )
			local Type, ID = varArgs.Type, varArgs.ID
			if Type == "Add" then
				for _,item in pairs( list:GetCanvas():GetChildren() ) do
					if item.Data[ 3 ] < 3 then continue end
					if item.Num == ID then
						tab[ ID ] = varArgs.Details
						item.Title = ID .. ". " .. tab[ ID ]
					end
				end
			elseif Type == "Delete" or Type == "Wipe" then
				for _,item in pairs( list:GetCanvas():GetChildren() ) do
					if item.Data[ 3 ] < 3 then continue end
					if not ID or item.Num == ID then
						tab[ item.Num ] = nil
						item.Title = item.Num .. ". Blank checkpoint"
					end
				end
			elseif Type == "Delay" then
				Core.SetCheckpointDelay()
			end
		end
		
		local function OnMousePressed( b, c )
			if c == 107 then
				s:OnTrigger( b.Num )
			elseif c == 108 then
				s:OnTrigger( b.Num, true )
			elseif c == 109 then
				s:OnTrigger( b.Num, nil, true )
			end

			b:OldMousePressed( c )
		end
		
		local function OnToggle( se, v )
			local bool, toggle = se:Check()
			toggle.Setter( bool, toggle )
			s.IsDelay = bool
		end
		
		tab[ 1 ] = "Load last loaded" .. (tab.LastLoaded and " (#" .. tab.LastLoaded .. ")" or "")
		tab[ 2 ] = "Load last saved" .. (tab.LastSaved and " (#" .. tab.LastSaved .. ")" or "")

		local c = 0
		for i = 1, 9 do
			local col = c % 2 == 0 and Window.C.BLight or Window.C.BDark
			local b = Window.PlainButton( list, i .. ". " .. (tab[ i ] and tab[ i ] or "Blank checkpoint"), 0, c * 24, w - 10, 24, { col, Window.C.Text, i, List = true } )
			b.OldMousePressed = b.OnMousePressed
			b.OnMousePressed = OnMousePressed
			b.Num = i
			
			c = c + 1
			list:AddItem( b )
		end
		
		local settings = Core.GetSettings()
		s.IsDelay = Window.Check( s, "Teleport delay", 16, h - 54, nil, 20, settings:GetToggle( "MISC_CP" ), OnToggle ).Checked
		Window.Label( s, 16, h - 30, "BottomHUDTiny", "For more info, type /cphelp", Window.C.Text )
	elseif szIdentifier == "Realtime" then
		s.Labels = {}
		s.Stats = {}
		s.Player = lp()
		s.Convert = Core.GetTimeConvert()
		s.JumpStats = args.Custom
		
		local new = {}
		new.GFrames, new.GTimes = {}, {}
		new.ST, new.SA, new.SB, new.SS, new.SP, new.SBT, new.SG, new.GC, new.GT, new.GFC, new.CJ, new.CJG, new.SAng, new.LG = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, s.Player:EyeAngles().y, true
		new.SFunc, new.BA, new.BN, new.CT = function( i ) if i > 180 then i = i - 360 elseif i < -180 then i = i + 360 end return i end, bit.band, bit.bnot, CurTime
		new.ML, new.MR, new.MW, new.MF = IN_MOVELEFT, IN_MOVERIGHT, MOVETYPE_WALK, FL_ONGROUND + FL_INWATER
		
		new.KS = {}
		for i = 1, 6 do new.KS[ i ] = "" end
		
		s.Ref = new
		s.Player.RTS = s.Ref
		s.Player.RTSF = function( p, js )
			if js and s.JumpStats then
				local vel = p:GetVelocity():Length2D()
				local _,stamp = Core.GetTimeDifference( 0 )
				if js == 0 and (vel == 0 or vel > 300) then return end
				if stamp == 0 and vel == 0 then return end
				
				local im1, im2
				if s.Stats[ js ] then
					if vel > s.Stats[ js ][ 1 ] then im1 = vel - s.Stats[ js ][ 1 ] s.Stats[ js ][ 1 ] = vel end
					if stamp < s.Stats[ js ][ 2 ] then im2 = s.Stats[ js ][ 2 ] - stamp s.Stats[ js ][ 2 ] = stamp end
				else
					s.Stats[ js ] = { vel, stamp }
				end
				
				if js == 0 then
					for i = 1, 4 do print() end
				end
				
				if Core.GetSettings():ToggleValue( "NOTIFY_JUMPSTATS" ) then
					Core.Print( "JS", (js == 0 and "Prestrafe" or "Speed on jump " .. (js + 1)) .. ": " .. math.Round( vel, 2 ) .. " u/s (+" .. math.Round( s.Stats[ js ][ 1 ] - vel, 2 ) .. ")", s.Convert( stamp ) .. " [+" .. s.Convert( stamp - s.Stats[ js ][ 2 ] ) .. "]" )
				else
					print( (js == 0 and "Prestrafe" or "Speed on jump " .. (js + 1)) .. ": " .. math.Round( vel, 2 ) .. " u/s (+" .. math.Round( s.Stats[ js ][ 1 ] - vel, 2 ) .. ")", s.Convert( stamp ) .. " [+" .. s.Convert( stamp - s.Stats[ js ][ 2 ] ) .. "]", im1 and "New velocity best (-" .. math.Round( im1, 2 ) .. " u/s)" or "", im2 and "New time best (-" .. s.Convert( im2 ) .. ")" or "" )
				end
				
				return true
			end
			
			local cm = p.RTS or {}
			cm.GFrames, cm.GTimes = {}, {}
			cm.ST, cm.SA, cm.SB, cm.SS, cm.SP, cm.SBT, cm.SG, cm.CJ, cm.CJG, cm.SAng, cm.LG = 0, 0, 0, 0, 0, 0, 0, 0, 0, lp():EyeAngles().y, true
		end
		
		s.CloseFunc = function( se )
			if se.Player and se.Player.RTSF then
				se.Player.RTSF = nil
			end
		end
		
		function s:ThinkHook( bType )
			if not Iv( self.Player ) then return end
			
			local data = self.Ref
			local vel = self.Player:GetVelocity()
			
			self:SetLabel( "6ListKeys", "Keys: " .. self:TranslateKeys( data.SBT ) )
			self:SetLabel( "ADVel", "Velocity 3D: " .. math.Round( vel:Length() ) .. " u/s" )
			self:SetLabel( "Jumps", "Jumps: " .. data.CJ )
			self:SetLabel( "Strafes", "Strafes: " .. data.SS )
			self:SetLabel( "Keys", "Key switches: " .. data.SP )
			self:SetLabel( "Sync", "Sync: " .. string.format( "%.1f", (data.SA / data.ST) * 100.0 ) .. " / " .. string.format( "%.1f", (data.SB / data.ST) * 100.0 ) )
			self:SetLabel( "Network", "Network: " .. Core.Config.NetRate )
			
			local vel2d = vel:Length2D()
			data.GT = data.GT + (vel2d - data.SG)
			data.GC = data.GC + 1
			data.SG = vel2d
		end
		
		function s:SetLabel( id, text )
			local resize = false
			if text and self.Labels[ id ] then
				self.Labels[ id ]:SetText( text )
			elseif text and not self.Labels[ id ] then
				local names = { id }
				for name,_ in pairs( self.Labels ) do
					names[ #names + 1 ] = name
				end
				
				resize = true
				table.sort( names )
				
				local at = 1
				for i,lb in pairs( names ) do
					if lb == id then
						at = i
					else
						self.Labels[ lb ]:SetPos( 20, 36 + i * 24 )
					end
				end
				
				self.Labels[ id ] = Window.Label( self, 20, 36 + at * 24, "BottomHUDSemi", text, Window.C.Text )
			elseif not text and self.Labels[ id ] then
				self.Labels[ id ]:Remove()
				self.Labels[ id ] = nil
				
				local names = {}
				for name,_ in pairs( self.Labels ) do
					names[ #names + 1 ] = name
				end
				
				resize = true
				table.sort( names )
				
				for i,lb in pairs( names ) do
					self.Labels[ lb ]:SetPos( 20, 36 + i * 24 )
				end
			end
			
			if resize then
				local w, h = self:GetSize()
				local c = 0
				
				surface.SetFont( "BottomHUDSemi" )
				
				for _,lab in pairs( self.Labels ) do
					local wx = surface.GetTextSize( lab:GetText() ) + 40
					if wx > w then
						w = wx
					end
					
					c = c + 1
				end
				
				h = 2 * 36 + c * 24
				self:SetSize( w, h )
				self.MainClose:SetPos( w - 16 - 8, 8 )
			end
		end
		
		function s:TranslateKeys( num )
			local cm = s.Ref
			if not cm or cm.SBT == 0 then return "" end
			
			cm.KS = {}
			cm.KS[ 1 ] = cm.BA( cm.SBT, IN_FORWARD ) > 0 and "W" or nil
			cm.KS[ #cm.KS + 1 ] = cm.BA( cm.SBT, IN_MOVELEFT ) > 0 and "A" or nil
			cm.KS[ #cm.KS + 1 ] = cm.BA( cm.SBT, IN_BACK ) > 0 and "S" or nil
			cm.KS[ #cm.KS + 1 ] = cm.BA( cm.SBT, IN_MOVERIGHT ) > 0 and "D" or nil
			cm.KS[ #cm.KS + 1 ] = cm.BA( cm.SBT, IN_DUCK ) > 0 and "Duck" or nil
			cm.KS[ #cm.KS + 1 ] = cm.BA( cm.SBT, IN_ATTACK ) > 0 and "Fire" or nil
			
			return string.Implode( ", ", cm.KS )
		end
		
		local function OnStatTrack( ply, data )
			if ply != s.Player or not IsFirstTimePredicted( ply ) then return end
			if not Iv( s ) or not s.Ref then return end
			
			local cm = s.Ref
			local ang = data:GetAngles().y
			cm.SBT = cm.BA( data:GetButtons(), cm.BN( 2 ) )
			
			if not ply:IsFlagSet( cm.MF ) and ply:GetMoveType() == cm.MW then
				local difference = cm.SFunc( ang - cm.SAng )
				if difference != 0 then
					local l, r = cm.BA( cm.SBT, cm.ML ) > 0, cm.BA( cm.SBT, cm.MR ) > 0
					if l or r then
						cm.ST = cm.ST + 1
						
						if difference > 0 then
							if l and not r then cm.SA = cm.SA + 1 if cm.SL != cm.ML then cm.SL = cm.ML cm.SS = cm.SS + 1 end end
							if data:GetSideSpeed() < 0 then cm.SB = cm.SB + 1 end
						elseif difference < 0 then
							if r and not l then cm.SA = cm.SA + 1 if cm.SL != cm.MR then cm.SL = cm.MR cm.SS = cm.SS + 1 end end
							if data:GetSideSpeed() > 0 then cm.SB = cm.SB + 1 end
						end
					end
				end
			end
			
			if cm.SBT != 0 and cm.SK != cm.SBT then
				cm.SK = cm.SBT
				cm.SP = cm.SP + 1
			end
			
			cm.SAng = ang
			
			local ground = ply:IsOnGround()
			if not ground then
				cm.GFC = 0
				
				if cm.LG then
					if cm.CT() - cm.CJG > 0.1 then
						if not s.JumpStats then
							cm.CJ = cm.CJ + 1
						else
							cm.CJ = ply:RTSF( cm.CJ ) and cm.CJ + 1 or 0
						end
						
						cm.CJG = cm.CT()
					end
				end
				
				cm.LG = ground
				
				if cm.GF then
					if cm.GF != 1 and (not cm.LGF or (cm.LGF and cm.CT() - cm.LGF > 0.05)) and (not cm.GFT or (cm.GFT and (cm.CT() - cm.GFT > 0 and cm.CT() - cm.GFT < 0.20))) then
						if cm.GFT then
							cm.GFrames[ #cm.GFrames + 1 ] = cm.GF
							cm.GTimes[ #cm.GTimes + 1 ] = cm.GFT and cm.CT() - cm.GFT
						end
						
						cm.LGF = cm.CT()
						cm.GF = nil
					end
				end
			else
				cm.GFC = cm.GFC + 1
				
				if cm.GFC == 1 then
					cm.GFT = cm.CT()
				end
				
				cm.GF = cm.GFC
				cm.LG = ground
			end
		end
		hook.Add( "SetupMove", "StatsTracking", OnStatTrack )
		
		local function OnUpdate()
			local lpc = lp()
			if not Iv( ActiveWindow ) or ActiveWindow.Identifier != "Realtime" then
				if Iv( lpc ) then
					lpc.RTS = nil
				end
				
				hook.Remove( "SetupMove", "StatsTracking" )
				
				return timer.Remove( "RealtimeUpdater" )
			end
			
			local cm = ActiveWindow.Ref
			if lpc.Style == 8 or lpc.Style == 9 then
				local c1, c2 = 0, 0
				for i = 1, #cm.GFrames do c1 = c1 + cm.GFrames[ i ] end
				for i = 1, #cm.GTimes do c2 = c2 + cm.GTimes[ i ] end
				
				ActiveWindow:SetLabel( "GroundFrame", "Avg. ground frames: " .. math.Round( c1 / #cm.GFrames ) )
				ActiveWindow:SetLabel( "GroundTime", "Avg. ground time: " .. math.Round( (c2 / #cm.GTimes) * 1000, 1 ) .. " ms" )
			else
				ActiveWindow:SetLabel( "GroundFrame" )
				ActiveWindow:SetLabel( "GroundTime" )
			end
			
			ActiveWindow:SetLabel( "ZJumpStats", "Change visibility with !togglew" )
			ActiveWindow:SetLabel( "Gain", "Average gain: " .. string.format( "%.3f", (cm.GT / cm.GC) * 10 ) .. " u/s" )
			cm.GT = 0
			cm.GC = 1
		end
		timer.Create( "RealtimeUpdater", 0.1, 0, OnUpdate )
		
		s.CanThink = true
	elseif szIdentifier == "Keys" then
		s.Spec = TEAM_SPECTATOR
		s.Keys = 0
		s.Links = { [IN_JUMP] = 1, [IN_DUCK] = 2, [IN_FORWARD] = 4, [IN_BACK] = 8, [IN_MOVELEFT] = 16, [IN_MOVERIGHT] = 32, [IN_ATTACK] = 64 }
		s.CloseFunc = function()
			RunConsoleCommand( "unshowkeys" )
		end
		
		local function IsDown( sp, b )
			if sp then
				return bit.band( s.Keys or 0, s.Links[ b ] or 0 ) > 0
			else
				return lp():KeyDown( b )
			end
		end
		
		local b = Window.PlainButton( s, "", 8, 54, w - 16, h - 54 - 16, nil, function() Window.Close() end )
		b.Paint = function( x, w, h )
			local sp = lp():Team() == s.Spec
			DrawText( IsDown( sp, IN_MOVELEFT ) and "A" or "_", "GUIWindowTitle", w / 2 - 32, h / 2, Window.C.LText, tac, tac )
			DrawText( IsDown( sp, IN_MOVERIGHT ) and "D" or "_", "GUIWindowTitle", w / 2 + 32, h / 2, Window.C.LText, tac, tac )
			DrawText( IsDown( sp, IN_FORWARD ) and "W" or "_", "GUIWindowTitle", w / 2, h / 2 - h / 3, Window.C.LText, tac, tac )
			DrawText( IsDown( sp, IN_BACK ) and "S" or "_", "GUIWindowTitle", w / 2, h / 2, Window.C.LText, tac, tac )
			
			if IsDown( sp, IN_JUMP ) then DrawText( "Jump", "GUIWindowTitle", w / 2, h / 2 + h / 3, Window.C.LText, tac, tac ) end
			if IsDown( sp, IN_DUCK ) then DrawText( "Duck", "GUIWindowTitle", w / 2 - 48, h / 2 + h / 3, Window.C.LText, tac, tac ) end
			if IsDown( sp, IN_ATTACK ) then DrawText( "Fire", "GUIWindowTitle", w / 2 + 48, h / 2 + h / 3, Window.C.LText, tac, tac ) end
		end
		
		if not Window.Cache.KeyFunc then
			Window.Cache.KeyFunc = true
			net.Receive( "KeyDataTransfer", function()
				if IsValid( ActiveWindow ) and ActiveWindow.Identifier == "Keys" then
					ActiveWindow.Keys = net.ReadInt( 9 )
				end
			end )
		end
	elseif szIdentifier == "TAS" then
		if not Window.Cache.TASData then
			Window.Cache.TASData = { 0, true, true, true, false }
			Window.Cache.TASDefault = table.Copy( Window.Cache.TASData )
		end
		
		s.Submit = Window.Cache.TASData
		s.Content = { s.Submit[ 2 ] and "Pause" or "Resume", (s.Submit[ 3 ] and "+" or "-") .. "Fastreverse", (s.Submit[ 4 ] and "+" or "-") .. "Fastforward", "Strafehack: " .. (s.Submit[ 5 ] and "ON" or "OFF"), "Set restore frame", "Continue at frame", "Exit TAS mode" }
		s.Commands = {}
		s.LastCommand = 0
		s.CloseFunc = function( se )
			if se.IsExit then return end
			Core.Print( "General", "The TAS menu was closed. If you want to re-open it, type !tasmenu" )
		end
		
		for i = 1, #s.Content do
			s.Commands[ i ] = Window.Label( s, 20, 36 + i * 24, "BottomHUDSemi", i .. ". " .. s.Content[ i ], Window.C.Text )
		end
		
		local function OnKey( i )
			if st() - s.LastCommand < 0.5 then return end
			s.LastCommand = st()
			s.Submit[ 1 ] = i
			
			if i == 1 and not s.Submit[ 2 ] then
				s.SetBtns = nil
			elseif i == 7 then
				s.IsExit = true
			end
			
			Core.Send( "TAS", s.Submit )
		end
		
		local bd, bo, br, bl = bit.band, bit.bor, IN_MOVERIGHT, IN_MOVELEFT
		function s.OnCreateMove( cmd )
			local btn = cmd:GetButtons()
			if Iv( s ) and s.SetBtns then
				btn = bit.bor( btn, s.SetBtns )
				cmd:SetButtons( btn )
			end
			
			if not Window.Cache.TASMove then return end
			if bd( btn, 2 ) > 0 then
				if bd( btn, bl ) > 0 or bd( btn, br ) > 0 then return end
				if cmd:GetMouseX() > 0 then
					cmd:SetButtons( bo( btn, br ) )
					cmd:SetSideMove( 5000 )
				elseif cmd:GetMouseX() < 0 then
					cmd:SetButtons( bo( btn, bl ) )
					cmd:SetSideMove( -5000 )
				end
			end
		end
		hook.Add( "CreateMove", "TASCreateMove", s.OnCreateMove )
		
		function s:TranslateKeys( num )
			if not num then return "" end
			
			local dt = {}
			dt[ #dt + 1 ] = bit.band( num, IN_FORWARD ) > 0 and "W" or nil
			dt[ #dt + 1 ] = bit.band( num, IN_MOVELEFT ) > 0 and "A" or nil
			dt[ #dt + 1 ] = bit.band( num, IN_BACK ) > 0 and "S" or nil
			dt[ #dt + 1 ] = bit.band( num, IN_MOVERIGHT ) > 0 and "D" or nil
			dt[ #dt + 1 ] = bit.band( num, IN_DUCK ) > 0 and "Duck" or nil
			
			local str = string.Implode( ", ", dt )
			return str != "" and "(" .. str .. ")" or ""
		end
		
		function s:ThinkHook( bType )
			if bType then return end
			for i = 2, 8 do
				if KeyCheck( i ) then
					OnKey( i - 1 )
					break
				end
			end
		end
		
		function s:Update( args )
			local id = args[ 1 ]
			local at = id + 1
			
			if id == 0 then
				Window.Cache.TASMove = nil
				hook.Remove( "CreateMove", "TASCreateMove" )
				
				if Window.Close() then
					Window.Cache.TASData = table.Copy( Window.Cache.TASDefault )
					Core.Send( "TAS", { id } )
				end
			elseif id == 1 then
				self.Submit[ at ] = args[ 2 ]
				self.Commands[ id ]:SetText( id .. ". " .. (self.Submit[ at ] and "Pause" or "Resume") )
				
				if args[ 3 ] then
					self.SetBtns = args[ 3 ]
					
					local t = self.Commands[ 1 ]
					if string.find( t:GetText(), "Resume" ) then
						t:SetText( "1. Resume " .. self:TranslateKeys( self.SetBtns ) )
					end
				else
					self.SetBtns = nil
				end
			elseif id == 2 then
				self.Submit[ at ] = args[ 2 ]
				self.Commands[ id ]:SetText( id .. ". " .. (self.Submit[ at ] and "+Fastreverse" or "-Fastreverse") )
				if args[ 3 ] then
					self.SetBtns = args[ 4 ]
					
					local t = self.Commands[ 1 ]
					if string.find( t:GetText(), "Resume" ) then
						t:SetText( "1. Resume " .. self:TranslateKeys( self.SetBtns ) )
					end
				else
					self.SetBtns = nil
				end
			elseif id == 3 then
				self.Submit[ at ] = args[ 2 ]
				self.Commands[ id ]:SetText( id .. ". " .. (self.Submit[ at ] and "+Fastforward" or "-Fastforward") )
				if args[ 3 ] then
					self.SetBtns = args[ 4 ]
					
					local t = self.Commands[ 1 ]
					if string.find( t:GetText(), "Resume" ) then
						t:SetText( "1. Resume " .. self:TranslateKeys( self.SetBtns ) )
					end
				else
					self.SetBtns = nil
				end
			elseif id == 4 then
				self.Submit[ at ] = args[ 2 ]
				self.Commands[ id ]:SetText( id .. ". Strafehack: " .. (self.Submit[ at ] and "ON" or "OFF") )
				Window.Cache.TASMove = self.Submit[ at ]
			elseif id == 10 then
				OnKey( 4 )
			end
		end
	elseif szIdentifier == "Profile" then
		local tab = args.Custom
		tab.ID64 = util.SteamIDTo64( tab.Steam or "" )
		
		s.SavedData = tab
		s.Convert = Core.GetTimeConvert()
		s.Content = { "Name: Loading..." }
		s.Labels = {}
		s.Expands = {}
		s.AtWidth = w
		s.Style = tab.Style or 1
		
		if tab.Steam then s.Content[ #s.Content + 1 ] = "Steam: " .. tab.Steam end
		if tab.Location then s.Content[ #s.Content + 1 ] = "Country: " .. tab.Location end
		
		s.Content[ #s.Content + 1 ] = "Details for: " .. Core.StyleName( s.Style )
		s.Content[ #s.Content + 1 ] = ""
		
		if tab.Points and tab.TopPoints and tab.PlayerPos and tab.Players then
			s.Content[ #s.Content + 1 ] = "1. Rank: " .. (tab.PlayerPos[ s.Style ] or 0) .. " / " .. (tab.Players[ s.Style ] or 0)
			
			if table.Count( tab.Points ) >= 1 then
				s.Expands[ 1 ] = {}
				s.Expands[ 1 ].Header = "Rank progression details"
				
				for i,points in pairs( tab.Points ) do
					local pos = tab.PlayerPos[ i ] or 0
					local amount = tab.Players[ i ] or 0
					local perc = points / (tab.TopPoints[ i ] or 1)
					
					table.insert( s.Expands[ 1 ], "- " .. Core.StyleName( i ) .. ": " .. pos .. " / " .. amount .. " (" .. math.Round( perc * 100, 2 ) .. "%)" )
				end
				
				table.insert( s.Expands[ 1 ], "" )
				table.insert( s.Expands[ 1 ], "The % shows amount points compared to #1" )
			end
		end
		
		if tab.WRs then
			s.Content[ #s.Content + 1 ] = "2. Total WRs: " .. tab.WRs
			
			if tab.PrimeWR then
				s.Expands[ 2 ] = {}
				s.Expands[ 2 ].Header = "Distribution over styles"
				
				for i = 1, #tab.PrimeWR do
					s.Expands[ 2 ][ i ] = "- WRs on " .. tab.PrimeWR[ i ][ 1 ] .. ": " .. tab.PrimeWR[ i ][ 2 ]
				end
				
				table.insert( s.Expands[ 2 ], "" )
				table.insert( s.Expands[ 2 ], "8. View all WRs by player" )
			end
		end
		
		if tab.MapsBeat then
			s.Content[ #s.Content + 1 ] = "3. Maps beat: " .. tab.MapsBeat .. " / " .. tab.MapsTotal
			
			s.Expands[ 3 ] = function()
				RunConsoleCommand( "say", "/mapsbeat " .. Core.StyleName( ActiveWindow.Style ) .. " " .. ActiveWindow.SavedData.Steam )
			end
		end
		
		if tab.Recent and #tab.Recent > 0 then
			s.Content[ #s.Content + 1 ] = "4. Most recent record: " .. os.date( "%Y-%m-%d %H:%M:%S", tab.Recent[ 1 ].nDate )
			
			s.Expands[ 4 ] = {}
			s.Expands[ 4 ].Header = "Player's 10 most recent records"
			
			for i = 1, #tab.Recent do
				s.Expands[ 4 ][ i ] = "- [" .. os.date( "%Y-%m-%d %H:%M:%S", tab.Recent[ i ].nDate ) .. "] " .. tab.Recent[ i ].szMap .. " on " .. Core.StyleName( tab.Recent[ i ].nStyle ) .. " in " .. s.Convert( tab.Recent[ i ].nTime )
			end
		else
			s.Content[ #s.Content + 1 ] = "4. No maps beaten recently"
		end
		
		if tab.CPRs then
			s.Content[ #s.Content + 1 ] = "5. Stages completed: " .. tab.CPRs
		end
		
		s.Content[ #s.Content + 1 ] = ""
		s.Content[ #s.Content + 1 ] = "0. Close window"
		
		function s:PutLabel( i, text, cont )
			local lab = Window.Label( self, 20, 36 + i * 24, "BottomHUDSemi", text, Window.C.Text )
			lab.GetItemWidth = function( se )
				surface.SetFont( se:GetFont() )
				return surface.GetTextSize( se:GetText() )
			end
			
			local wi = lab:GetItemWidth() + 40
			if wi > self.AtWidth then
				self.AtWidth = wi
				self:SetWide( self.AtWidth )
				
				if self.MainClose then
					self.MainClose:SetPos( self:GetWide() - 16 - 8, 8 )
				end
			end
			
			local into = cont or self.Labels
			into[ i ] = lab
			
			self:SetTall( 70 + i * 24 )
		end
		
		for i = 1, #s.Content do
			s:PutLabel( i, s.Content[ i ] )
		end
		
		Core.GetPlayerName( tab.ID64, function( uid, name, arg )
			local lab = arg.Labels[ 1 ]
			if IsValid( lab ) then
				lab:SetText( "Name: " .. name )
				
				local wi = lab:GetItemWidth() + 40
				if wi > arg.AtWidth then
					arg:SetWide( wi )
					if arg.MainClose then
						arg.MainClose:SetPos( wi - 16 - 8, 8 )
					end
				end
			end
		end, s )
		
		local function OnKey( key )
			if s.LastCommand and st() - s.LastCommand < 0.5 then return end
			s.LastCommand = st()
			
			if s.Expands[ key ] and not s.ActiveView then
				if isfunction( s.Expands[ key ] ) then
					return s.Expands[ key ]()
				end
				
				for i = 1, #s.Labels do
					s.Labels[ i ]:SetVisible( false )
				end
				
				s.Paged = { X = s:GetWide(), Y = s:GetTall() }
				s.AtWidth = 0
				s:PutLabel( 1, s.Expands[ key ].Header, s.Paged )
				
				for i = 1, #s.Expands[ key ] do
					s:PutLabel( i + 1, s.Expands[ key ][ i ], s.Paged )
				end
				
				s:PutLabel( #s.Expands[ key ] + 2, "9. Go back", s.Paged )
				s.ActiveView = key
			elseif s.Paged then
				if key == 9 then
					for i = 1, #s.Paged do
						s.Paged[ i ]:Remove()
					end
					
					for i = 1, #s.Labels do
						s.Labels[ i ]:SetVisible( true )
					end
					
					s:SetWide( s.Paged.X )
					s:SetTall( s.Paged.Y )
					s.MainClose:SetPos( s:GetWide() - 16 - 8, 8 )
					s.ActiveView = nil
				elseif key == 8 and s.ActiveView == 2 then
					RunConsoleCommand( "say", "/wrsby " .. (ActiveWindow.SavedData.Steam or "") )
				end
			end
		end
		
		function s:ThinkHook( bType )
			if bType then return end
			for i = 2, 10 do
				if KeyCheck( i ) then
					OnKey( i - 1 )
					break
				end
			end
		end
		
		s:SetPos( s:GetPos(), ScrH() / 2 - s:GetTall() / 2 )
	elseif szIdentifier == "Settings" then
		if not Window.Cache.Settings then
			Window.Cache.Settings = args.Custom or {}
		end
		
		local function WindowToggle( s )
			local parent, active = s:GetParent()
			for _,v in pairs( parent.Menu ) do
				if v.Data.Active then
					active = v
				end
			end
			
			if active == s then return end
			for i,v in pairs( parent.Menu ) do
				v.Data.Active = v == s
				
				if v.Data.Active then
					parent.Target = i
				end
			end
			
			for _,v in pairs( parent.Scroller:GetCanvas():GetChildren() ) do
				if Iv( v ) then
					v:Remove()
				end
			end
			
			parent.Scroller:GetVBar():SetScroll( 0 )
			parent.Regenerate = true
			Window.GenerateContent( parent, parent.Identifier )
		end
		s.ToggleFunc = WindowToggle
		
		if not s.Regenerate then
			s.Separator = 20
			s.Scroller = Window.ScrollPanel( s, 0, 54 + 20, w - 8, h - 54 - 20 - 16 )
			s.Scroller.Items = {}
			s.Scroller.ItemDict = {}
			
			local data = { Color( 0, 0, 0, 0 ), Window.C.Text, a = 0, b = Color( 41, 128, 185 ), c = Window.C.Text }
			s.Menu = {}
			s.Menu[ 1 ] = Window.PlainButton( s, "Settings", 20, 52, 64, 20, table.Copy( data ), WindowToggle )
			s.Menu[ 2 ] = Window.PlainButton( s, "Statistics", w / 2 - 32, 52, 64, 20, table.Copy( data ), WindowToggle )
			s.Menu[ 3 ] = Window.PlainButton( s, "Help", w - 20 - 40, 52, 40, 20, table.Copy( data ), WindowToggle )
			s.Menu[ 1 ].Data.Active = true
		end
		
		local function OnCheck( s )
			local bool, toggle = s:Check()
			toggle.Setter( bool, toggle )
		end
		
		local function OnCombo( s, i, v )
			local toggle = s.Toggle
			toggle.Setter( v, toggle )
		end
		
		local function SpawnItems()
			local x, y = 20, 10
			local settings = Core.GetSettings()
			local mainf = "BottomHUDTiny"
			
			if not s.Target or s.Target == 1 then
				s.Scroller:AddItem( Window.Label( s, x, y - 4, "BottomHUDStressL", "Categories", Window.C.Text ) ) y = y + 24
				s.Scroller:AddItem( Window.ImageButton( s, "Notification options", "icon16/folder_go.png", x, y, nil, 20, function() for i = 1, 3 do s.Menu[ i ].Data.Active = nil end s.Target = 5 WindowToggle( { GetParent = function() return s end } ) end ) ) y = y + 30
				
				local categories = {
					{ "GUI and HUD options", { "GUI_VISIBILITY", "HUD_DEFTYPE", "HUD_OLDTYPE", "HUD_PLAINTYPE", "HUD_SPECTATOR", "HUD_SPEEDOMETER", "HUD_PERMSYNC", "HUD_VEL3D", "HUD_DATETIME", "HUD_TIMELEFT", "HUD_NOVEL", "HUD_NOBLUR", "CHAT_TIME", "MISC_SCORESPECS", "MISC_GREENTEXT", "MISC_CMDSUGGEST", "MISC_SHOWSTAMP" } },
					{ "Zone options", { "GAME_NOZONES", "GAME_ZONES", "GAME_FULLZONES", "GAME_SIMPLEZONE" } },
					{ "Player options", { "GAME_PLAYERS", "GAME_PLAYER_IDS", "MISC_THIRDPERSON", "MISC_SAVESTYLE", "MISC_NOGUNS", "MISC_VIEWINTERP", "MISC_VIEWTWITCH", "MISC_STEADYVIEW", "MISC_NOVIEWMODEL" } }
				}
				
				for _,items in pairs( Window.Cache.Toggles ) do
					categories[ #categories + 1 ] = { items[ 1 ], items[ 2 ] }
				end
				
				for _,items in pairs( categories ) do
					s.Scroller:AddItem( Window.ImageButton( s, items[ 1 ], "icon16/folder_go.png", x, y, nil, 20, function() for i = 1, 3 do s.Menu[ i ].Data.Active = nil end s.Target = 4 s.TTitle = items[ 1 ] s.TArray = items[ 2 ] WindowToggle( { GetParent = function() return s end } ) end ) )
					y = y + 30
				end
				
				local bx, by = x + 182, 10
				s.Scroller:AddItem( Window.Label( s, bx, by - 4, "BottomHUDStressL", "Options", Window.C.Text ) ) by = by + 24
				s.Scroller:AddItem( Window.Label( s, bx, by + 2, mainf, "Current style:", Window.C.Text ) )
				s.Scroller:AddItem( Window.Combo( s, bx + 88, by, 80, 20, { Default = function() return Core.StyleName( LocalPlayer().Style or 1 ) end, Setter = function( v ) local sid = Core.GetStyleID( v ) settings:Set( "LastStyle", sid, true ) RunConsoleCommand( "style", tostring( sid ) ) Window.Close() end }, Core.GetStyles(), OnCombo ) )
				
				s.Scroller:AddItem( Window.Label( s, bx, by + 32, mainf, "HUD opacity:", Window.C.Text ) )
				s.Scroller:AddItem( Window.Combo( s, bx + 88, by + 30, 80, 20, settings:GetToggle( "HUD_OPACITY" ), Core.GetHUDOpacities(), OnCombo ) )
				
				s.Scroller:AddItem( Window.Label( s, bx, by + 62, mainf, "HUD font size:", Window.C.Text ) )
				s.Scroller:AddItem( Window.Combo( s, bx + 88, by + 60, 70, 20, settings:GetToggle( "HUD_TYPE_FONT" ), { "Large", "Medium", "Small" }, OnCombo ) )
				
				s.Scroller:AddItem( Window.Label( s, bx, by + 92, mainf, "Context key:", Window.C.Text ) )
				s.Scroller:AddItem( Window.Combo( s, bx + 88, by + 90, 40, 20, settings:GetToggle( "HUD_CONTEXT" ), Core.GetAllowedKeys(), OnCombo ) )
				
				s.Scroller:AddItem( Window.Label( s, bx, by + 122, mainf, "Decimal time:", Window.C.Text ) )
				s.Scroller:AddItem( Window.Combo( s, bx + 88, by + 120, 40, 20, settings:GetToggle( "HUD_DECIMAL" ), { "3", "2", "1", "0" }, OnCombo ) )

				local fovs = { "90", "85", "80", "75" }
				if not table.HasValue( fovs, tostring( GetConVar( "fov_desired" ):GetInt() ) ) then fovs[ 5 ] = tostring( GetConVar( "fov_desired" ):GetInt() ) end
				s.Scroller:AddItem( Window.Label( s, bx, by + 152, mainf, "Local FOV:", Window.C.Text ) )
				s.Scroller:AddItem( Window.Combo( s, bx + 88, by + 150, 40, 20, { Default = function() return tostring( GetConVar( "fov_desired" ):GetInt() ) end, Setter = function( v ) RunConsoleCommand( "fov_desired", tostring( v ) ) Window.Close() end }, fovs, OnCombo ) )
				
				s.Scroller:AddItem( Window.Label( s, bx, by + 182, mainf, "Sound stopper:", Window.C.Text ) )
				s.Scroller:AddItem( Window.Combo( s, bx + 88, by + 180, 60, 20, settings:GetToggle( "MISC_NOSOUND" ), { "OFF", "5s", "1s", "0.5s", "0.1s", "0.01s" }, OnCombo ) )
				
				s.Scroller:AddItem( Window.Label( s, bx, by + 212, mainf, "Play footsteps:", Window.C.Text ) )
				s.Scroller:AddItem( Window.Combo( s, bx + 88, by + 210, 80, 20, settings:GetToggle( "MISC_FOOTSTEPS" ), { "All", "Only local", "Only remote", "None" }, OnCombo ) )
				
				s.Scroller:AddItem( Window.Label( s, bx, by + 242, mainf, "Default model:", Window.C.Text ) )
				s.Scroller:AddItem( Window.Text( s, bx + 88, by + 240, 80, 20, settings:GetToggle( "MISC_MODEL" ), function( se, r ) local toggle = se.Toggle toggle.Setter( r, toggle ) se:SetText( r ) end ) )
			elseif s.Target == 2 then
				s.Scroller:AddItem( Window.GrayButton( s, "Reset", w - 118, y, 85, 24, false, function()
					local tab, func = { "Everything", "Only settings", "Only statistics", "[[Close", Title = "Reset stored data", Caption = "Please select how much you want to erase\nEach process is irreversible, so be 100% sure before you press that button." }, {}
					local exec = { { "Wipe", "All statistics have been cleared and the settings have been reset to default (changes have been printed in console)" }, { "ResetSettings", "All settings have been reset to default (changes have been printed in console)" }, { "ResetStats", "All statistics have been cleared" }, {} }
					
					for i = 1, #tab do
						func[ #func + 1 ] = tab[ i ]
						func[ #func + 1 ] = exec[ i ]
						func[ #func + 1 ] = function( a, b ) if b then settings:Misc( a ) Core.Print( "General", b ) end end
					end
					
					Core.SpawnWindow( { ID = "Query", Dimension = { x = 100, y = 100 }, Args = { Title = tab.Title, Mouse = true, Blur = true, Caption = tab.Caption, Custom = func, Count = #tab, Callback = function( a, b ) b( unpack( a ) ) end } } )
				end ) )
				
				s.Scroller:AddItem( Window.Label( s, x, y, "BottomHUDStressL", "Game statistics", Window.C.Text ) ) y = y + 24
				s.Scroller:AddItem( Window.Label( s, x, y, mainf, "Data last saved on: " .. Core.ToDate( settings:Get( "LastSaved", 0 ) ), Window.C.Text ) ) y = y + 24
				s.Scroller:AddItem( Window.Label( s, x, y, mainf, "Total connection time: " .. math.Round( settings:Get( "ConnectionTime", 0 ), 1 ) .. " hours", Window.C.Text ) ) y = y + 24
				s.Scroller:AddItem( Window.Label( s, x, y, mainf, "Bytes received from main network: " .. math.Round( Core.Config.NetReceive / 1024, 2 ) .. " KB", Window.C.Text ) ) y = y + 24
				s.Scroller:AddItem( Window.Label( s, x, y, mainf, "Bytes of player data received: " .. math.Round( Core.GetSessionBytes() / 1024, 2 ) .. " KB", Window.C.Text ) ) y = y + 24
				s.Scroller:AddItem( Window.Label( s, x, y, mainf, "Total bytes received since last reset: " .. Core.ParseBytes( settings:Get( "TotalTransferred", 0 ) ), Window.C.Text ) ) y = y + 24
				s.Scroller:AddItem( Window.Label( s, x, y, mainf, "Obtained times on this map: " .. (Window.Cache.Settings[ 1 ] and Window.Cache.Settings[ 1 ] or "0"), Window.C.Text ) ) y = y + 24
				s.Scroller:AddItem( Window.Label( s, x, y, mainf, "Total obtained times on server: " .. (Window.Cache.Settings[ 4 ] and Window.Cache.Settings[ 4 ] or "0"), Window.C.Text ) ) y = y + 24
				s.Scroller:AddItem( Window.Label( s, x, y, mainf, "Total active commands: " .. (Window.Cache.Settings[ 5 ] and Window.Cache.Settings[ 6 ] .. " (" .. Window.Cache.Settings[ 5 ] .. " base commands)" or "0"), Window.C.Text ) ) y = y + 24
				s.Scroller:AddItem( Window.Label( s, x, y, mainf, "Most played map on server: " .. (Window.Cache.Settings[ 3 ] and (Window.Cache.Settings[ 3 ] .. " (" .. Window.Cache.Settings[ 2 ] .. " plays)") or "Unknown"), Window.C.Text ) ) y = y + 48

				s.Scroller:AddItem( Window.Label( s, x, y, "BottomHUDStressL", "Player statistics", Window.C.Text ) ) y = y + 24
				s.Scroller:AddItem( Window.Label( s, x, y, mainf, "Amount of times finished: " .. settings:Get( "TotalFinishes", 0 ), Window.C.Text ) ) y = y + 24
				s.Scroller:AddItem( Window.Label( s, x, y, mainf, "Total jumps: " .. settings:Get( "TotalJumps", 0 ), Window.C.Text ) ) y = y + 24
				s.Scroller:AddItem( Window.Label( s, x, y, mainf, "Total strafes: " .. settings:Get( "TotalStrafes", 0 ), Window.C.Text ) ) y = y + 24
				s.Scroller:AddItem( Window.Label( s, x, y, mainf, "Average sync: " .. settings:Get( "AverageSync", 0 ) .. "%", Window.C.Text ) ) y = y + 24
				s.Scroller:AddItem( Window.Label( s, x, y, mainf, "Best Long Jump: " .. settings:Get( "MaximumLJ", 0 ) .. " units", Window.C.Text ) ) y = y + 48
				
				s.Scroller:AddItem( Window.Label( s, x, y, "BottomHUDStressL", "Server settings", Window.C.Text ) ) y = y + 24
				
				local desc = { ["CSSDuck"] = "CS:S 64 unit duck offsets", ["CSSGains"] = "CS:S strafe gains", ["CSSJumps"] = "CS:S jump height", ["Checkpoints"] = "Linear checkpoints", ["GravityMultiplier"] = "Low Gravity multiplier", ["PackMultiplier"] = "Jump Pack multiplier", ["UseJumpPack"] = "Jump Pack", ["StartLimit"] = "Maximum start speed", ["SpeedLimit"] = "Maximum velocity", ["WalkSpeed"] = "No-gun walking speed" }
				for key,txt in pairs( desc ) do
					local val = Core.ServerSettings[ key ]
					local bool = type( val ) == "boolean" or type( val ) == "nil"
					s.Scroller:AddItem( Window.Label( s, x, y, mainf, txt .. ": " .. (bool and (val and "Enabled" or "Disabled") or val), Window.C.Text ) ) y = y + 24
				end
			elseif s.Target == 3 then
				local commands, text = Core.ObtainHelp()
				if not commands or not text then
					local l = Window.Label( s, x, y, mainf, "Loading help...", Window.C.Text )
					s.Scroller:AddItem( l )
					
					RunConsoleCommand( "say", "/help fs" )
				else
					s.Scroller:AddItem( Window.Label( s, x, y, "BottomHUDStressL", "Gamemode help", Window.C.Text ) ) y = y + 24
					for i = 1, #text do if text[ i ] != "" then local bold = string.sub( text[ i ], 1, 4 ) == "BOLD" s.Scroller:AddItem( Window.Label( s, x, y, bold and "BottomHUDStressL" or (string.find( text[ i ], "[", 1, true ) and "BottomHUDStress" or mainf), bold and string.sub( text[ i ], 5 ) or text[ i ], Window.C.Text ) ) end y = y + (bold and 24 or 16) end
					s.Scroller:AddItem( Window.Label( s, x, y + 24, "BottomHUDStressL", "Commands list", Window.C.Text ) ) y = y + 48
					
					for i = 1, #commands do
						local cmd = commands[ i ]
						local desc, alias = cmd[ 1 ], cmd[ 2 ]
						local main = table.remove( alias, 1 )
						
						s.Scroller:AddItem( Window.Label( s, x, y, "BottomHUDStress", Core.TrimText( "BottomHUDStress", main .. " (Aliases: " .. (#alias > 0 and string.Implode( ", ", alias ) or "None") .. ")", w - 70 ), Window.C.Text ) ) y = y + 16
						
						local tab = Window.Wrap( mainf, desc, w - 70 )
						for i = 1, #tab do s.Scroller:AddItem( Window.Label( s, x, y, mainf, tab[ i ], Window.C.Text ) ) y = y + 16 end
						y = y + 8
						
						table.insert( alias, 1, main )
					end
				end
			elseif s.Target == 4 then
				s.Scroller:AddItem( Window.Label( s, x, y - 4, "BottomHUDStressL", s.TTitle or "Unknown Submenu", Window.C.Text ) ) y = y + 24
				s.Scroller:AddItem( Window.ImageButton( s, "Go back", "icon16/arrow_left.png", x, y, nil, 20, function() for i = 1, 3 do s.Menu[ i ].Data.Active = nil end WindowToggle( s.Menu[ 1 ] ) end ) ) y = y + 30
				
				for _,id in pairs( s.TArray or {} ) do
					local tog = settings:GetToggle( id )
					local dependencies = { { "GAME_ZONES", "GAME_NOZONES" }, { "MISC_VIEWINTERP", "MISC_VIEWTWITCH", true } }
					for _,set in pairs( dependencies ) do
						local a,b = set[ 1 ], set[ 2 ]
						if id == a or id == b then
							tog.OldSetter = tog.Setter
							tog.Setter = function( bool, toggle )
								if bool then
									local item
									if toggle.ID == a then
										item = s.Scroller.ItemDict[ b ]
									elseif toggle.ID == b then
										item = s.Scroller.ItemDict[ a ]
									end
									
									if item then
										item:Check( false )
										
										if set[ 3 ] then
											local func = item.Toggle.OldSetter or item.Toggle.Setter
											func( false, item.Toggle )
										end
									end
								end
								
								toggle.OldSetter( bool, toggle )
							end
						end
					end
					
					s.Scroller.ItemDict[ id ] = Window.Check( s, tog.Description, x, y, nil, 20, tog, OnCheck )
					s.Scroller:AddItem( s.Scroller.ItemDict[ id ] )
					
					if x > 100 then
						x = 20 - 172
						y = y + 30
					end
					
					x = x + 172
				end
			elseif s.Target == 5 then
				local by = y - 8
				s.Scroller:AddItem( Window.Label( s, x, y - 4, "BottomHUDStressL", "Timer and notification options", Window.C.Text ) ) y = y + 24
				s.Scroller:AddItem( Window.ImageButton( s, "Go back", "icon16/arrow_left.png", x, y, nil, 20, function() for i = 1, 3 do s.Menu[ i ].Data.Active = nil end WindowToggle( s.Menu[ 1 ] ) end ) ) y = y + 30

				for _,id in pairs( { "NOTIFY_WRSOUND", "NOTIFY_SPECMSG", "NOTIFY_NOTHING", "NOTIFY_LJS", "NOTIFY_TAS", "HUD_STAGE", "NOTIFY_STAGE", "NOTIFY_COLORS", "NOTIFY_LJSTATS", "MISC_SHOWCONDIFF", "NOTIFY_STAGETOP", "NOTIFY_STAGESPEC", "NOTIFY_JUMPSTATS" } ) do
					local tog = settings:GetToggle( id )
					s.Scroller:AddItem( Window.Check( s, tog.Description, x, y, nil, 20, tog, OnCheck ) )
					
					y = y + 30
				end
				
				s.Scroller:AddItem( Window.Label( s, x + 225, by + 8, mainf, "Visible styles:", Window.C.Text ) )
				s.MakeComboStyle = function( s )
					if IsValid( s.ComboStyle ) then
						s.ComboStyle:Remove()
					end
					
					local bits, vals, opts = settings:Get( "NotifyStyles", 0 ), {}, { "Hidden", "Visible" }
					for name,id in pairs( Core.Config.Style ) do
						vals[ #vals + 1 ] = name .. ": " .. (bit.band( bits, math.pow( 2, id ) ) > 0 and "Hidden" or "Visible")
					end
					
					s.ComboStyle = Window.Combo( s, x + 225, by + 30, 100, 20, { Default = function() return "" end, Setter = function( v )
						if IsValid( s.ComboStyle ) then
							local at = string.find( v, ":", 1, true )
							local style = string.sub( v, 1, at - 1 )
							
							for name,id in pairs( Core.Config.Style ) do
								if name == style then
									local bits = settings:Get( "NotifyStyles", 0 )
									local bitx = math.pow( 2, id )
									
									if bit.band( bits, bitx ) > 0 then
										bits = bit.band( bits, bit.bnot( bitx ) )
									else
										bits = bit.bor( bits, bitx )
									end
									
									settings:Set( "NotifyStyles", bits, true )
									
									table.RemoveByValue( opts, string.sub( v, at + 2, #v ) )
									Core.Print( "General", "Timer notifications for the " .. name .. " style will now be " .. string.lower( opts[ 1 ] ) )
									
									s:MakeComboStyle()
									break
								end
							end
						end
					end }, vals, OnCombo )
					
					s.Scroller:AddItem( s.ComboStyle )
				end
				
				s.MakeComboPos = function( s )
					if IsValid( s.ComboPos ) then
						s.ComboPos:Remove()
					end
					
					local id = s.ComboPosID or Core.StyleName( 1 )
					local opts = { "All", "Only #1", "Top 10", "Top 25", "Top 50", "Top 100", "Top 200" }
					local tab = settings:Get( "NotifyPositions", {} )
					local defv = tab[ id ] or (Core.GetStyleID( id ) > 1 and opts[ 2 ] or opts[ 1 ])
					
					s.ComboPos = Window.Combo( s, x + 225 + 65, by + 90, 60, 20, {
						Default = function()
							return defv or "All"
						end,
						Setter = function( v )
							local tab = settings:Get( "NotifyPositions", {} )
							tab[ id ] = v
							settings:Set( "NotifyPositions", tab, true )
						end
					}, opts, OnCombo )
					
					s.Scroller:AddItem( s.ComboPos )
				end
				
				s.Scroller:AddItem( Window.Label( s, x + 225, by + 68, mainf, "Change position limits:", Window.C.Text ) )
				s.Scroller:AddItem( Window.Combo( s, x + 225, by + 90, 60, 20, {
					Default = function() return Core.StyleName( 1 ) end,
					Setter = function( v ) s.ComboPosID = v s:MakeComboPos() end
				}, Core.GetStyles(), OnCombo ) )
				
				s.Scroller:AddItem( Window.Label( s, x + 225, by + 128, mainf, "Pop-up notifications:", Window.C.Text ) )
				s.Scroller:AddItem( Window.Combo( s, x + 225, by + 150, 80, 20, settings:GetToggle( "HUD_NOTIFICATION" ), { "None", "Chat only", "Popups only", "Both" }, OnCombo ) )
				
				s.Scroller:AddItem( Window.Label( s, x + 225, by + 188, mainf, "Minimal LJ for display:", Window.C.Text ) )
				s.Scroller:AddItem( Window.Combo( s, x + 225, by + 210, 80, 20, settings:GetToggle( "NOTIFY_LJMIN" ), { "256", "258", "260", "262", "264", "266", "268", "270", "272", "274" }, OnCombo ) )
				
				local cols, txts = { ["Name and WR difference color"] = 1, ["Time obtained color"] = 2, ["Time improvement color"] = 3, ["Style indicator color"] = 4, ["Timer prefix color"] = 5, ["General prefix color"] = 6, ["Notification prefix color"] = 7, ["Radio prefix color"] = 8, [Core.Config.ServerName .. " prefix color"] = 9 }, {}
				for n,_ in pairs( cols ) do txts[ #txts + 1 ] = n end
				
				s.Scroller:AddItem( Window.Label( s, x + 225, by + 248, mainf, "Change display colors:", Window.C.Text ) )
				s.Scroller:AddItem( Window.Combo( s, x + 225, by + 270, 100, 20, { Default = function() return "" end, Setter = function( v )
					local dat = cols[ v ]
					local val = settings:Get( "CustomColor" .. dat, "" )
					local col = Core.ParseColor( val )
					
					Window.Picker( col, function( c ) settings:Set( "CustomColor" .. dat, tostring( c ), true ) Core.SetCustomColor( dat, tostring( c ) ) end )
				end }, txts, OnCombo ) )
				
				s:MakeComboStyle()
				s:MakeComboPos()
			end
		end
		
		function s:ReloadHelp()
			if not self.Menu[ 3 ] then return end
			for i = 1, 3 do self.Menu[ i ].Data.Active = nil end
			WindowToggle( self.Menu[ 3 ] )
		end
		
		SpawnItems()
	elseif szIdentifier == "Query" then
		local tab, btn = args.Custom, {}
		local function OnSubmit( s )
			s.SendFunc( s.SendID, s.SendValue, true )
			Window.Close()
		end
		
		local x, y, c = 20, 80, 0
		local rows = math.ceil( args.Count / 3 )
		local height = rows * 34 + y + 20
		local width, addw, totalw = 80, 0, 0
		
		surface.SetFont( "BottomHUDTiny" )
		local wt, wh = surface.GetTextSize( args.Caption )
		height = height + wh
		y = y + wh
		
		local nd = {}
		for i = 1, args.Count * 3, 3 do
			nd[ #nd + 1 ] = { Name = tab[ i ], SID = tab[ i + 1 ], SV = tab[ i + 2 ] }
			
			if string.sub( tab[ i ], 1, 2 ) == "[[" then
				nd[ #nd ].Name = string.Replace( tab[ i ], "[[", "ZZ" )
				nd[ #nd ].SortAbuse = true
			end
		end
		
		table.SortByMember( nd, "Name", true )
		
		for i = 1, #nd do
			local st = (i - 1) * 3
			tab[ st + 1 ] = nd[ i ].Name
			tab[ st + 2 ] = nd[ i ].SID
			tab[ st + 3 ] = nd[ i ].SV
			
			if nd[ i ].SortAbuse then
				tab[ st + 1 ] = string.Replace( tab[ st + 1 ], "ZZ", "" )
			end
		end
		
		for i = 1, args.Count * 3, 3 do
			local b = Window.GrayButton( s, tab[ i ], x, y, nil, 24, false, OnSubmit )
			b.SendID = tab[ i + 1 ]
			b.SendValue = tab[ i + 2 ]
			b.SendFunc = args.Callback
			btn[ #btn + 1 ] = b
			
			totalw = totalw + b:GetWide()
			x = x + b:GetWide() + 10
			c = c + 1
			
			if c >= 3 then
				x, y = 20, y + 24 + 10
				c = 0
				
				if totalw > addw then
					addw = totalw
				end
				
				totalw = 0
			end
		end
		
		width = width + addw
		if wt + 60 > width then
			width = wt + 60
		end
		
		local lab = Window.Label( s, width / 2 - wt / 2, 60, "BottomHUDTiny", args.Caption, Window.C.Text )			
		if #btn > 1 then
			local sets = math.ceil( #btn / 3 )
			for j = 1, sets do
				local offset = j * 3 - 3
				local btns = { btn[ offset + 1 ], btn[ offset + 2 ], btn[ offset + 3 ] }
				
				if #btns > 2 then
					local middle = (btns[ 3 ]:GetPos() + btns[ 3 ]:GetWide()) - btns[ 1 ]:GetPos()
					local offset = width / 2 - middle / 2 - 20
					
					for i = 1, #btns do
						local b = btns[ i ]
						local bx, by = b:GetPos()
						b:SetPos( bx + offset, by )
					end
				elseif #btns > 1 then
					local middle = (btns[ 2 ]:GetPos() + btns[ 2 ]:GetWide()) - btns[ 1 ]:GetPos()
					local offset = width / 2 - middle / 2 - 20
					
					for i = 1, #btns do
						local b = btns[ i ]
						local bx, by = b:GetPos()
						b:SetPos( bx + offset, by )
					end
				elseif #btns > 0 then
					local b = btns[ 1 ]
					local bx, by = b:GetPos()
					b:SetPos( width / 2 - b:GetWide() / 2, by )
				end
			end
		elseif #btn == 1 then
			local b = btn[ 1 ]
			local bx, by = b:GetPos()
			b:SetPos( width / 2 - b:GetWide() / 2, by )
		else
			Window.Label( s, width / 2 - 24, 80, "BottomHUDTiny", "No options", Window.C.Text )
		end
		
		s:SetSize( width, height )
		s:Center()
	elseif szIdentifier == "Radio" or szIdentifier == "Admin" or szIdentifier == "Bot" then
		args.Populate( s, args.Custom, Window, w, h )
	end
	
	if args and not args.HideClose and not s.CloseAdded then
		s.MainClose = Window.CloseButton( s, s:GetWide() - 16 - 8, 8, 16, 16 )
	end
	
	timer.Simple( 0.5, function() if Iv( s ) then s.CanThink = true end end )
end


local function ReceiveVoteList( varArgs )
	Core.SpawnWindow( { ID = "Vote", Dimension = { x = Core.Config.IsSurf and 390 or 300, y = 340, px = 20 }, Args = { Title = "Voting (30s remaining)", List = varArgs } } )
end
Core.Register( "RTV/List", ReceiveVoteList )

local function ReceiveVotesList( ar )
	if Window.IsActive( "Vote" ) then
		ActiveWindow:Update( ar )
	elseif not Window.Cache.VoteNotify or st() - Window.Cache.VoteNotify > 5 then
		Window.Cache.VoteNotify = st()
		Core.Print( "Notification", "A map vote is currently active. If you wish to participate in it, type !revote" )
	end
end
Core.Register( "RTV/VoteList", ReceiveVotesList )

local function ReceiveInstantVote( varArgs )
	if Window.IsActive( "Vote" ) then
		ActiveWindow:InstantVote( varArgs )
	end
end
Core.Register( "RTV/InstantVote", ReceiveInstantVote )

local function ReceiveBeatenMaps( varArgs )
	if Window.IsActive( "Vote" ) then
		ActiveWindow:SetBeaten( varArgs )
	end
end
Core.Register( "RTV/SetBeaten", ReceiveBeatenMaps )

local function ReceiveHelpText()
	if Window.IsActive( "Settings" ) then
		ActiveWindow:ReloadHelp()
	end
end
Core.Register( "Inner/SettingsHelp", ReceiveHelpText )

local function ReceiveCPUpdate( varArgs )
	if Window.IsActive( "Checkpoints" ) then
		ActiveWindow:Update( varArgs )
	end
end
Core.Register( "GUI/UpdateCP", ReceiveCPUpdate )

local function ReceiveTASUpdate( varArgs )
	if Window.IsActive( "TAS" ) then
		ActiveWindow:Update( varArgs )
	end
end
Core.Register( "GUI/UpdateTAS", ReceiveTASUpdate )

local function ReceiveWindowBuild( ar )
	local id = ar:String()
	local title = ar:String()
	local wx = ar:UInt( 10 )
	local wy = ar:UInt( 10 )
	local m = ar:Bit()
	local b = ar:Bit()
	local args = {}
	
	if id == "Records" then
		args.IsEdit = ar:Bit()
		args.Map = ar:Bit() and ar:String()
		
		if ar:Bit() then
			args.Started = ar:UInt( 16 )
			args.TargetID = ar:UInt( 16 )
		end
		
		args[ 1 ] = {}
		args[ 2 ] = ar:UInt( 16 )
		args[ 3 ] = ar:Int( 8 )
		args[ 4 ] = ar:UInt( 16 )
		
		while true do
			local i = ar:UInt( 16 )
			if i == 0 then break end
			
			args[ 1 ][ i ] = { szUID = ar:String(), nTime = ar:Double(), nPoints = ar:Double(), nDate = ar:UInt( 32 ), vData = ar:String() }
		end
	elseif id == "Maps" then
		args[ 1 ] = {}
		args.Style = ar:Int( 8 )
		
		local full = ar:Bit()
		if full then
			args.Type = ar:String()
			args.Command = ar:String()
			args.Version = ar:UInt( 20 )
		elseif ar:Bit() then
			args.SteamID = ar:String()
		end
		
		for i = 1, ar:UInt( 16 ) do
			args[ 1 ][ i ] = { szMap = ar:String(), nTime = ar:Double(), nPoints = ar:Double(), nDate = ar:UInt( 32 ) }
			
			if not full then
				args[ 1 ][ i ].nStyle = ar:Int( 8 )
				args[ 1 ][ i ].vData = ar:String()
			end
		end
	elseif id == "Top" then
		args.ViewType = ar:UInt( 4 )
		args.Count = ar:UInt( 16 )
		args.IsEdit = ar:Bit()
		
		if args.ViewType == 2 then
			args.Total = ar:UInt( 16 )
			args.Style = ar:UInt( 8 )
			args.ID = ar:UInt( 8 )
			args.Pos = ar:Bit() and ar:UInt( 16 )
		elseif args.ViewType == 1 or args.ViewType == 4 or args.ViewType == 8 then
			args.Style = ar:UInt( 8 )
		end
		
		local data = {}
		for i = 1, args.Count do
			data[ i ] = {}
			
			if args.ViewType == 0 then
				data[ i ].szUID = ar:String()
				data[ i ].nSum = ar:Double()
				data[ i ].nLeft = ar:UInt( 12 )
			elseif args.ViewType == 1 then
				data[ i ].szUID = ar:String()
				data[ i ].nStyle = ar:UInt( 8 )
				data[ i ].nWins = ar:UInt( 16 )
				data[ i ].nStreak = ar:UInt( 16 )
			elseif args.ViewType == 2 then
				data[ i ].szUID = ar:String()
				data[ i ].nTime = ar:Double()
			elseif args.ViewType == 3 then
				data[ i ].szUID = ar:String()
				data[ i ].szAppend = ar:String()
				data[ i ].nTime = ar:Double()
			elseif args.ViewType == 4 then
				data[ i ].szUID = ar:String()
				data[ i ].nTime = ar:Double()
				data[ i ].nReal = ar:Double()
				data[ i ].nDate = ar:UInt( 32 )
			elseif args.ViewType == 5 then
				data[ i ].szText = ar:String()
				data[ i ].nTime = ar:Double()
			elseif args.ViewType == 6 then
				data[ i ].szUID = ar:String()
				data[ i ].szPrepend = ar:String()
				data[ i ].nTime = ar:Double()
			elseif args.ViewType == 7 then
				data[ i ].szUID = ar:String()
				data[ i ].nCount = ar:UInt( 10 )
			elseif args.ViewType == 8 then
				data[ i ].szUID = ar:String()
				data[ i ].nValue = ar:Double()
				data[ i ].nDate = ar:UInt( 32 )
				data[ i ].vData = ar:String()
			end
		end
		
		if args.ViewType == 7 then
			table.SortByMember( data, "nCount" )
		end
		
		args.Data = data
	end
	
	Window.Receive( { ID = id, Dimension = { x = wx, y = wy }, Args = { Title = title, Mouse = m, Blur = b, Custom = args } } )
end
Core.Register( "GUI/Build", ReceiveWindowBuild )

local function ReceiveWindowUpdate( ar )
	local id = ar:String()
	local args = {}
	
	if id == "Records" then
		args[ 1 ] = {}
		args[ 2 ] = ar:UInt( 16 )
		
		while true do
			local i = ar:UInt( 16 )
			if i == 0 then break end
			
			args[ 1 ][ i ] = { szUID = ar:String(), szPlayer = ar:String(), nTime = ar:Double(), nPoints = ar:Double(), nDate = ar:UInt( 32 ), vData = ar:String() }
		end
	elseif id == "Top" then
		args[ 1 ] = {}
		args.Amount = ar:UInt( 16 )
		args.Count = ar:UInt( 16 )
		args.Bottom = ar:UInt( 16 )
		args.Top = ar:UInt( 16 )
		
		for i = 1, args.Amount do
			args[ 1 ][ args.Bottom + i - 1 ] = { szUID = ar:String(), nTime = ar:Double() }
		end
	end
	
	if Window.IsActive( id ) then
		ActiveWindow:Update( args )
	end
end
Core.Register( "GUI/Update", ReceiveWindowUpdate )

local function ChatOverride()
	if ActiveWindow and Iv( ActiveWindow.TextInput ) and ActiveWindow.TextInput.Focus then return true end
end
hook.Add( "StartChat", "ChatOverridePopup", ChatOverride )