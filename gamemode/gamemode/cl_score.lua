local menu, context, contextspec
local ConvertTime, StyleName, Styles = Core.GetTimeConvert(), Core.StyleName, Core.Config.Style
local ScoreData, ScoreDraw, ScoreRequest = {}, { i = 1, x = 8, y = 52, t = {}, tx = {}, ty = {}, d = {} }
local DrawCol, DrawRect, DrawLine, DrawText, DrawMat, DrawTex, Alp = surface.SetDrawColor, surface.DrawRect, surface.DrawLine, draw.SimpleText, surface.SetMaterial, surface.DrawTexturedRect, surface.SetAlphaMultiplier
local CheckMouse, RightMouse, LeftMouse, CWhite, CBlack, CGray, Lerp, OpenMenu, OpenSpecMenu, OpenTooltip = input.IsMouseDown, MOUSE_RIGHT, MOUSE_LEFT, color_white, color_black, Color( 150, 150, 150 ), Lerp
local lp, st, tal, tar, tac, zet = LocalPlayer, SysTime, TEXT_ALIGN_LEFT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER

local admin_names, medal_names, admin_specials = { "Trusted", "Trusted+", "Junior Admin", "Full Admin", "Super Admin", "Gamemode Manager", "Owner" }, { "Gold Medal", "Silver Medal", "Bronze Medal" }, { ["76561198205782696"] = "Fun fact: This guy is the creator of this gamemode" }
local icon_muted, icon_setting, icon_access = Material( "icon32/muted.png" ), Material( "icon16/cog.png" ), { Material( "icon16/heart.png" ), Material( "icon16/heart_add.png" ), Material( "icon16/report_user.png" ), Material( "icon16/shield.png" ), Material( "icon16/shield_add.png" ), Material( "icon16/script_code_red.png" ), Material( "icon16/house.png" ) }
local rank_ring, special_base, icon_rank, icon_special = Material( Core.Config.MaterialID .. "/rankring.png" ), Material( Core.Config.MaterialID .. "/specialbase.png" ), {}, {}
local rank_col, special_col = { Color( 128, 255, 0 ), Color( 0, 230, 255 ), Color( 255, 0, 0 ) }, { Color( 71, 146, 255 ), Color( 172, 116, 255 ), Color( 52, 191, 50 ) }
for i = 1, 7 do icon_rank[ i ] = Material( Core.Config.MaterialID .. "/rank" .. i .. ".png" ) end
for i = 1, 3 do icon_special[ i ] = Material( Core.Config.MaterialID .. "/special" .. i .. ".png" ) end

local function AdminAction( szAction, szSID )
	if not IsValid( lp() ) then return end
	if Core.IsAdminAvailable() or lp():VarNet( "Get", "Access", 0 ) > 2 then
		RunConsoleCommand( "say", "!admin " .. szAction .. " " .. szSID )
	else
		Core.Print( "Admin", "Please open the admin panel before trying to access scoreboard functionality." )
	end	
end

local function IsGlobalAdmin( ply )
	local access = ply:VarNet( "Get", "Access", 0 )
	if access > 2 then
		return access
	end
end

local AdminOptions = {
	{ "Copy name", "page_copy", function( s ) SetClipboardText( s.p:Name() ) end },
	{ "Copy Steam ID", "page_copy", function( s ) SetClipboardText( s.sid ) end, true },
	{ "Move to spectator", "eye", function( s ) AdminAction( "spectator", s.sid ) end },
	{ "Strip weapons", "delete", function( s ) AdminAction( "strip", s.sid ) end },
	{ "Open admin panel", "shield", function( s ) RunConsoleCommand( "sm_admin" ) end },
	{ "Mute player (voice)", "sound_mute", function( s ) RunConsoleCommand( "sm_mute", s.sid ) end },
	{ "Unmute player", "sound_low", function( s ) RunConsoleCommand( "sm_unmute", s.sid ) end },
	{ "Gag player (chat)", "text_strikethrough", function( s ) RunConsoleCommand( "sm_gag", s.sid ) end },
	{ "Unmute player", "text_signature", function( s ) RunConsoleCommand( "sm_ungag", s.sid ) end },
	{ "Kick player", "door_open", function( s ) local pl = s.sid Derma_StringRequest( "Kick Player", "Why do you want to kick " .. s.p:Name() .. "?", "", function( text ) RunConsoleCommand( "sm_kick", pl, text ) end, function() end ) end }
}

local TooltipHelp = {
	["type"] = "The type of bot:\nIdle: Inactive, no run\nNormal: Only shows Normal style\nMulti: Can display any run with !mbot command", ["runner"] = "The name of the runner who did the run the bot is replaying", ["runtime"] = "The time the runner obtained with the shown run", ["date"] = "The date on which the run was obtained",
	["rank"] = "This shows the rank of the player on a certain style.\nTo view all ranks, type !ranks", ["access"] = "The access level of the player.\n\nUser with booklet: Junior Admin\nShield: Full Admin\nShield+: Super Admin\nHeart: Trusted\nHeart+: Trusted+\nRed Code Sheet: Gamemode Manager", ["mute"] = "This indicates the player is muted",
	["subrank"] = "Shows how far the player has progressed into his rank.\nProgress is indicated by the amount of diamonds.\nThe golden ring adds another 5.\nThe closer the total value is to 10, the closer the player is to ranking up.\n\nRed color: Most WRs on Normal\nGreen color: Most WRs obtained on their current style\nLight blue color: Holds the #1 place in !top for their style\n\nThêta symbol: Top rank on Normal\nPhi symbol: Top rank on their current style", ["player"] = "The name of the player", ["timer"] = "This shows the record of the player on the selected style", ["style"] = "This is the style the player is currently playing on\nTo view all styles, type !style",
	["medal"] = "If the record the player has is in the top 3 for that style\na specific medal is awarded", ["position"] = "The position at which the player is placed in the leaderboards", ["ping"] = "The player's latency to the server\n\n0-90: Good connection\n91 - 220: Average connection\n221 - 999: Poor connection", ["remotetimer"] = "The time the player has as of opening this expanded window", ["connected"] = "For how long the player has been connected to the server", ["completed"] = "The amount of times the player has finished a course this session",
	["wrs"] = "The amount of #1 times the player holds.\n\nThe first number ONLY shows the amount on their current style.", ["stage"] = "The stage the player was last seen on\n(and is probably on it right now)", ["tas"] = "The timer people currently have in the TAS mode", ["funcs"] = "There's really a lot of additional player related functions here,\nso you're probably best off just right clicking to figure out more about it", ["avatar"] = "The player's Steam avatar",
	["totalrank"] = "The total rank of the player\nThis percentage shows how much better the player is than average\n\nIt is calculated by taking the average of all players on all styles,\nthen taking the average of this player over the global average\nand finally multiplying that by 100", ["mappoints"] = "The amount of points awarded for the map for their current style\n\nLimits are: [0.25x, 2x Map Points]", ["mapsbeat"] = "The amount of maps the player has beaten on their current style"
}

local TooltipInfo = {
	["rank"] = function( s ) if IsValid( s.player ) and not s.player:Alive() then return "This player is currently spectating" else local r = Core.ObtainRank( s.RankID + 1, s.StyleID, true ) return "Currently at: " .. s.RankText .. " (Rank " .. math.Clamp( s.RankID, 0, #Core.Config.Ranks ) .. " / " .. #Core.Config.Ranks .. ")\nNext rank: " .. (r != "Retrieving..." and r or "None") .. (s.RankID > 1 and " (Progress: " .. math.Clamp( s.SubRank, 0, 10 ) * 10 .. "%)" or "") end end,
	["access"] = function( s ) if s.Access > 0 then return "This player's access: " .. admin_names[ s.Access ] end end,
	["medal"] = function( s ) if s.SpecialRank > 0 then return "This player has a " .. medal_names[ s.SpecialRank ] .. " for their #" .. s.SpecialRank .. " record" end end,
	["player"] = function( s ) if IsValid( s.player ) then return admin_specials[ s.player:SteamID64() ] end end,
	["subrank"] = function( s ) if s.RankID > 1 and s.SubRank > 0 then return "This player is currently at sub rank: " .. math.Clamp( s.SubRank, 0, 10 ) end end
}

local function TrimToSize( font, text, mw )
	surface.SetFont( font )

	local tooLong, isFirst = true, true
	while tooLong do
		local w = surface.GetTextSize( text )
		if w > mw then
			if isFirst then
				text = string.sub( text, 1, #text - 4 )
				isFirst = false
			else
				text = string.sub( text, 1, #text - 1 )
			end
		else
			break
		end
	end
	
	if not isFirst then
		text = text .. "..."
	end
	
	return text
end
Core.TrimText  = TrimToSize

local function PushDrawItem( data, txt, desc, reset )
	if reset then data.i, data.x, data.y = 1, 8, 52 end
	
	if data.y > 112 then
		data.x = data.x + 300
		data.y = 52
	end
	
	local i = data.i
	data.t[ i ] = txt
	data.tx[ i ] = data.x
	data.ty[ i ] = data.y
	data.d[ i ] = desc
	
	data.i = i + 1
	data.y = data.y + 20
end

local function DrawPlayerItem( se, w, h )
	DrawCol( se.Background )
	DrawRect( 0, 0, w, h )
	
	DrawCol( CGray )
	DrawLine( 0, 0, w, 0 )
	DrawLine( 0, 0, 0, h )
	DrawLine( w, 0, w, h )
	DrawLine( w - 1, 0, w - 1, h )
	
	if se.FinalEntry then
		DrawLine( 0, h - 1, w, h - 1 )
	end

	local ply = se.player
	local valid = IsValid( ply )
	local isbot = valid and ply:IsBot()
	local s = 0
	local aw, ah
	
	if valid and isbot then		
		DrawText( se.BotName, "ScoreboardPlayer", s + 11, 9, CBlack, tal )
		aw, ah = DrawText( se.BotName, "ScoreboardPlayer", s + 10, 8, se.BotColor, tal )
		se.boxes.type = { s + 10, 8, aw, ah }
		
		s = s + se.mw + 56

		DrawText( se.PlayerName, "ScoreboardPlayer", s + 11, 9, CBlack, tal )
		aw, ah = DrawText( se.PlayerName, "ScoreboardPlayer", s + 10, 8, se.NameColor, tal )
		se.boxes.runner = { s + 10, 8, aw, ah }
		
		local scrollWide = se.Scroller.Enabled and se.Scroller:GetWide() or 0
		if IsValid( se.Timer ) and IsValid( se.Timer:GetParent() ) then
			local o = w - (se.Timer:GetParent():GetWide() - se.Timer:GetPos()) + scrollWide
			DrawText( se.TimerText, "ScoreboardPlayer", o + 1, 9, CBlack, tal )
			aw, ah = DrawText( se.TimerText, "ScoreboardPlayer", o, 8, CWhite, tal )
			se.boxes.runtime = { o, 8, aw, ah }
		end
		
		DrawText( se.RunDate, "ScoreboardPlayer", w - 9, 9, CBlack, tar )
		aw, ah = DrawText( se.RunDate, "ScoreboardPlayer", w - 10, 8, CWhite, tar )
		se.boxes.date = { w - 10 - aw, 8, aw, ah }
	elseif valid and not isbot and ply:IsPlayer() then
		DrawText( se.RankText, "ScoreboardPlayer", s + 11, 9, CBlack, tal )
		aw, ah = DrawText( se.RankText, "ScoreboardPlayer", s + 10, 8, se.RankColor, tal )
		se.boxes.rank = { s + 10, 8, aw, ah }
		
		s = s + se.mw + 56
		
		if se.Access > 0 then
			DrawMat( icon_access[ se.Access ] )
			DrawCol( CWhite )
			DrawTex( s + 4, 10, 16, 16 )
			se.boxes.access = { s + 4, 8, 16, 16 }
			s = s + 20
		end

		if ply:IsMuted() then
			DrawMat( icon_muted )
			DrawCol( CWhite )
			DrawTex( s + 4, 0, 32, 32 )
			se.boxes.mute = { s + 4, 0, 32, 32 }
			s = s + 32
		end

		if se.RankID > 1 and se.SubRank > 0 then
			local id = se.SubRank
			if id > 5 then
				DrawMat( rank_ring )
				DrawCol( CWhite )
				DrawTex( s + 4, 2, 32, 32 )
			end
			
			DrawMat( icon_rank[ id > 5 and id - 5 or id ] )
			DrawCol( se.SubGlow > 0 and rank_col[ se.SubGlow ] or CWhite )
			
			if id >= 6 and id <= 10 then
				DrawTex( s + 7, 3, 26, 26 )
			else
				DrawTex( s + 4, 2, 32, 32 )
			end
			
			se.boxes.subrank = { s + 4, 2, 32, 32 }
			s = s + 32
		end

		DrawText( se.PlayerName, "ScoreboardPlayer", s + 11, 9, CBlack, tal )
		aw, ah = DrawText( se.PlayerName, "ScoreboardPlayer", s + 10, 8, se.PlayerColor or CWhite, tal )
		se.boxes.player = { s + 10, 8, aw, ah }

		local scrollWide = se.Scroller.Enabled and se.Scroller:GetWide() or 0
		local o = w - se.wt - ((105 - se.wt) * 2) - menu.RecordOffset + scrollWide
		DrawText( se.TimerText, "ScoreboardPlayer", o + 1, 9, CBlack, tar )
		aw, ah = DrawText( se.TimerText, "ScoreboardPlayer", o, 8, CWhite, tar )
		se.boxes.timer = { o - aw, 8, aw, ah }
		
		o = o + 20 + (se.tw - se.wt)
		DrawText( se.StyleText, "ScoreboardPlayer", o + 1, 9, CBlack, tal )
		aw, ah = DrawText( se.StyleText, "ScoreboardPlayer", o, 8, CWhite, tal )
		se.boxes.style = { o, 8, aw, ah }
		
		if se.SpecialRank > 0 then
			DrawMat( special_base )
			DrawCol( CWhite )
			DrawTex( o - se.tw - 56, 2, 32, 32 )
			
			DrawMat( icon_special[ se.SpecialRank > 3 and 2 or se.SpecialRank ] )
			DrawCol( se.SpecialRank > 3 and special_col[ se.SpecialRank - 3 ] or CWhite )
			DrawTex( o - se.tw - 56, 2, 32, 32 )
			se.boxes.medal = { o - se.tw - 56, 0, 32, 32 }
		elseif se.Position > 0 then
			DrawText( "#" .. se.Position, "HUDLabelSmall", o - se.tw - 31, 12, CBlack, tar )
			aw, ah = DrawText( "#" .. se.Position, "HUDLabelSmall", o - se.tw - 32, 11, CGray, tar )
			se.boxes.position = { o - se.tw - 32 - aw, 11, aw, ah }
		end
		
		DrawText( ply:Ping(), "ScoreboardPlayer", w - 9, 9, CBlack, tar )
		aw, ah = DrawText( ply:Ping(), "ScoreboardPlayer", w - 10, 8, CWhite, tar )
		se.boxes.ping = { w - 10 - aw, 8, aw, ah }
		
		if se.Expanded then
			Alp( se.MoveOpacity )
			
			local tab = se.CloseData or ScoreData[ se.PlayerSteam ]
			if not tab then
				DrawText( se.Collapse and "" or "Loading...", "GUIWindowTitle", w / 2, h / 2 + 10, CWhite, tac, tac )
			else
				if not se.OpenedAt then se.OpenedAt = st() end
				if not se.CloseData then se.CloseData = table.Copy( ScoreData[ se.PlayerSteam ] ) end
				
				if tab.TAS then
					PushDrawItem( ScoreDraw, "TAS time: " .. ConvertTime( tab.TAS > 0 and tab.TAS + (st() - se.OpenedAt) or 0 ), "tas", 1 )
				else
					PushDrawItem( ScoreDraw, "Current time: " .. (tab.Timer > -1 and ConvertTime( tab.Timer + (st() - se.OpenedAt) ) or "No timer running"), "remotetimer", 1 )
				end
				
				PushDrawItem( ScoreDraw, "Connected for: " .. ConvertTime( tab.Online + (st() - se.OpenedAt) ), "connected" )
				PushDrawItem( ScoreDraw, "Map completions this session: " .. ply:Frags(), "completed" )
				PushDrawItem( ScoreDraw, tab.WRs[ 1 ] > 0 and "WRs obtained: " .. tab.WRs[ 2 ] .. " (" .. tab.WRs[ 3 ] .. " on other styles)" or "No WRs obtained", "wrs" )
				
				PushDrawItem( ScoreDraw, "Total rank: " .. tab.TotalRank .. "%", "totalrank" )
				PushDrawItem( ScoreDraw, "Map points: " .. tab.MapPoints[ 1 ] .. " / " .. tab.MapPoints[ 2 ], "mappoints" )
				PushDrawItem( ScoreDraw, "Maps beaten: " .. tab.MapsBeat, "mapsbeat" )
				if tab.Stage then PushDrawItem( ScoreDraw, "Last seen on stage: " .. tab.Stage, "stage" ) end
				
				for i = 1, #ScoreDraw.t do
					aw, ah = DrawText( ScoreDraw.t[ i ], "GUIWindowTitle", ScoreDraw.tx[ i ], ScoreDraw.ty[ i ], CWhite, tal, tac )
					se.boxes[ ScoreDraw.d[ i ] ] = { ScoreDraw.tx[ i ], ScoreDraw.ty[ i ] - ah / 2, aw, ah }
				end
				
				if ply != lp() then
					aw, ah = DrawText( "For more functions, right click this box", "GUIWindowTitle", w - 12, h - 16, CWhite, tar, tac )
					se.boxes.funcs = { w - 12 - aw, h - 16 - ah / 2, aw, ah }
				end
			end
			
			Alp( 1 )
		elseif se.Expand then
			Alp( se.MoveOpacity )
			DrawText( "Loading player details...", "GUIWindowTitle", w / 2, h / 2 + 10, CWhite, tac, tac )
			Alp( 1 )
		end
		
		if se.Expand then
			local Fraction = st() - se.StartTime
			local Height = Lerp( Fraction * 2, se.bh, se.mh )
			se.MoveOpacity = Lerp( Fraction * 2, 0, 1 )
			se:SetTall( Height )
			
			if Height == se.mh then
				se.Expand = false
				se.Expanded = true
				
				se.Avatar = vgui.Create( "AvatarImage", se )
				se.Avatar:SetSize( 64, 64 )
				se.Avatar:SetPos( w - 64 - 10, h - 64 - 26 )
				se.Avatar:SetPlayer( ply, 64 )
				
				se.Avatar.Btn = vgui.Create( "DButton", se.Avatar )
				se.Avatar.Btn:SetPos( 0, 0 )
				se.Avatar.Btn:SetSize( 64, 64 )
				se.Avatar.Btn:SetText( "" )
				se.Avatar.Btn:SetDrawBackground( false )
				se.Avatar.Btn.ThePlayer = ply
				se.Avatar.Btn.DoClick = function( se2 )
					if IsValid( se2.ThePlayer ) then
						RunConsoleCommand( "say", "/profile " .. se2.ThePlayer:SteamID() )
					end
				end
				
				se.boxes.avatar = { w - 64 - 10, h - 64 - 26, 64, 64 }
			end
		elseif se.Collapse then
			local Fraction = st() - se.StartTime
			local Height = Lerp( Fraction * 2, se.mh, se.bh )
			se.MoveOpacity = Lerp( Fraction * 4, 1, 0 )
			se:SetTall( Height )
			
			if se.Avatar then
				se.Avatar:SetAlpha( se.MoveOpacity * 255 )
			end
			
			if Height == se.bh then
				se.Collapse = false
				se.Expanded = false
				
				if se.Avatar then
					if se.Avatar.Btn then
						se.Avatar.Btn:Remove()
					end
					
					se.Avatar:Remove()
					se.Avatar = nil
				end
			end
		end
	elseif not valid then
		if not se.ValidCheck then se.ValidText = menu.ActivePlayers > 1 and "Player has disconnected" or "No players to display!" end
		DrawText( se.ValidText, "ScoreboardPlayer", w / 2 + 1, 9, CBlack, tac )
		DrawText( se.ValidText, "ScoreboardPlayer", w / 2, 8, CWhite, tac )
	end
	
	if CheckMouse( RightMouse ) or (isbot and CheckMouse( LeftMouse )) then
		local mx, my = gui.MousePos()
		local sx, sy = se:ScreenToLocal( mx, my )
		local sp = se.Scroller:GetParent()
		local dx, dy = sp:ScreenToLocal( mx, my )
		
		if not IsValid( context ) and sx >= 0 and sx <= w and sy >= 0 and sy <= h and dy >= 0 and dy <= sp:GetTall() then
			context = OpenMenu( ply )
		end
	else
		local rx, ry = se:ScreenToLocal( gui.MousePos() )
		if rx < 0 or rx > w or ry < 0 or ry > h then return end
		
		if ScoreDraw.lx == rx and ScoreDraw.ly == ry and not se.Expand and not se.Collapse then
			ScoreDraw.ch = (ScoreDraw.ch or 0) + 1
			
			if ScoreDraw.ch > 0.30 / FrameTime() then
				ScoreDraw.ch = 0
				OpenTooltip( se, rx, ry )
			end
		else
			ScoreDraw.lx = rx
			ScoreDraw.ly = ry
		end
	end
end

local function PutPlayerItem( self, list, ply, mw, id, total )
	local btn = vgui.Create( "DButton", self )
	btn.player = ply
	btn.ctime = CurTime()
	btn:SetTall( 36 )
	btn:SetText( "" )
	btn.mw = mw
	btn.boxes = {}
	btn.bh = btn:GetTall()
	btn.mh = btn:GetTall() * 4 - 16
	
	btn.Background = id % 2 == 0 and Color( 42, 42, 42, menu.Opacity ) or Color( 64, 64, 64, menu.Opacity )
	btn.FinalEntry = id == total
	btn.Scroller = list:GetVBar()
	
	local parent = list:GetParent()
	if IsValid( parent ) and IsValid( parent.RightMax ) and IsValid( parent.LeftMax ) then
		local cw = parent.RightMax:GetPos() - parent.LeftMax:GetPos()
		parent.TextWidth = cw > 0 and cw
	end
	
	local b = not ply.Blank
	if b then
		btn.PlayerName = ply:Name()
		btn.PlayerSteam = ply:SteamID()
		btn.TimerText = ConvertTime( ply:VarNet( "Get", "Record", 0 ) )
	end
	
	if b and ply:IsBot() then
		local szName = ply:VarNet( "Get", "BotName", "Loading..." )
		if szName == "" then szName = "No run available" end
		if szName != "No run available" and szName != "Loading..." then
			local pos = ply:VarNet( "Get", "WRPos", 0 )
			szName = string.format( "%s %s record by %s", (pos > 0 and "#" .. pos or "A"), StyleName( ply.StyleID ), szName )
		end
		
		btn.PlayerName = szName
		btn.RunDate = ply:VarNet( "Get", "RunDate", "" )
		btn.Timer = list.TimerLabel
		btn.BotColor = Color( 255, 0, 0 )
		btn:SetTall( 32 )
		
		local BotTypes = { [0] = "Idle Bot", [1] = "Multi Bot", [2] = "History Bot", [3] = StyleName( ply.StyleID ) .. " Bot" }
		btn.BotName = BotTypes[ ply.BotType or 0 ]
		
		local nw = parent.TextWidth
		if nw then
			btn.PlayerName = TrimToSize( "ScoreboardPlayer", btn.PlayerName, nw )
		end
	elseif b then
		btn.RankID = ply:VarNet( "Get", "Rank", -1 )
		btn.StyleID = ply:VarNet( "Get", "Style", Styles.Normal )
		btn.RankText, btn.RankColor = Core.ObtainRank( btn.RankID, btn.StyleID, true )
		btn.StyleText = StyleName( btn.StyleID )
		btn.Position = ply:VarNet( "Get", "Position", 0 )
		btn.Access = ply:VarNet( "Get", "Access", 0 )
		btn.SubRank = ply:VarNet( "Get", "SubRank", 1 )
		btn.SubGlow = ply:VarNet( "Get", "SubGlow", 0 )
		btn.SpecialRank = ply:VarNet( "Get", "SpecialRank", 0 )
		
		if not zet then
			local o = Core.SetDecimalCount( nil, true )
			zet = ConvertTime( 0 )
			Core.SetDecimalCount( o )
		end
		
		surface.SetFont( "ScoreboardPlayer" )
		btn.tw = surface.GetTextSize( zet or ConvertTime( 0 ) )
		btn.wt = surface.GetTextSize( btn.TimerText )
		btn.adt = 8
		
		local nw = parent.TextWidth
		if nw then
			if btn.Access > 0 then btn.adt = btn.adt + 20 end
			if btn.SubRank > 0 then btn.adt = btn.adt + 24 end
			if btn.SpecialRank > 0 then btn.adt = btn.adt + 32 end
			nw = nw - btn.adt
			
			btn.PlayerName = TrimToSize( "ScoreboardPlayer", btn.PlayerName, nw )
		end
		
		if not ply:Alive() then
			btn.PlayerColor = Color( 180, 180, 180 )
			btn.RankText, btn.RankColor = "Spectator", btn.PlayerColor
		end
	end
	
	btn.Paint = DrawPlayerItem
	btn.DoClick = function( s )
		local ply = s.player
		if not IsValid( ply ) then return end
		if ply.Blank then return end
		if ply:IsBot() or s.Collapse then return end
		if ScoreRequest then return Core.Print( "General", "We're still fetching data from another player. Please wait until that's finished before requesting another." ) end
		
		local bAny = false
		for _,item in pairs( list:GetCanvas():GetChildren() ) do
			if item.Expand then
				bAny = true
				break
			end
		end
		
		if bAny then return end
		
		for _,item in pairs( list:GetCanvas():GetChildren() ) do
			if item != s and (item.Expanded or item.Expand) then
				item.Collapse = true
				item.Expand = false
				item.MoveOpacity = 1
				item.StartTime = st()
			end
		end
		
		if s:GetTall() == s.bh then
			s.MoveOpacity = 0
			s.Collapse = false
			s.Expand = true
			s.StartTime = st()
			
			ScoreData = {}
			ScoreDraw = { i = 1, x = 8, y = 52, t = {}, tx = {}, ty = {}, d = {} }
			ScoreRequest = ply:SteamID()
			Core.Send( "Scoreboard", { ScoreRequest } )
		elseif s:GetTall() == s.mh then
			s.MoveOpacity = 1
			s.Collapse = true
			s.Expand = false
			s.StartTime = st()
		end
	end
	
	list:AddItem( btn )
end

local function ListPlayers( cont, list, mw, bots )
	local players = {}
	if bots then
		players = player.GetBots()
		
		for _,p in pairs( players ) do
			p.StyleID = p:VarNet( "Get", "Style", 0 )
			
			if p.StyleID == 0 then
				p.BotType = 0
			elseif p.StyleID > Styles.Normal then
				p.BotType = 1
			else
				p.BotType = p:VarNet( "Get", "TrueStyle", -1 ) > -1 and 2 or 3
			end
		end
		
		table.sort( players, function( a, b )
			if not a or not b then return false end
			return a.BotType > b.BotType
		end )
	else
		local specs = {}
		for _,p in pairs( player.GetHumans() ) do
			table.insert( p:Alive() and players or specs, p )
		end
		
		table.sort( players, function( a, b )
			if a:VarNet( "Get", "Style", 1 ) < b:VarNet( "Get", "Style", 1 ) then return true end
			if a:VarNet( "Get", "Style", 1 ) > b:VarNet( "Get", "Style", 1 ) then return false end
			if a:VarNet( "Get", "Rank", 1 ) > b:VarNet( "Get", "Rank", 1 ) then return true end
			if a:VarNet( "Get", "Rank", 1 ) < b:VarNet( "Get", "Rank", 1 ) then return false end
			
			local ra, rb = a:VarNet( "Get", "Record", 0 ), b:VarNet( "Get", "Record", 0 )
			ra = ra == 0 and 1e10 or ra
			rb = rb == 0 and 1e10 or rb
			
			return ra < rb
		end )
		
		if Core.GetSettings():ToggleValue( "MISC_SCORESPECS" ) then
			for _,p in pairs( specs ) do
				table.insert( players, p )
			end
		end
		
		if #players == 0 then
			table.insert( players, { Blank = true } )
		end
		
		local specns = {}
		for _,p in pairs( specs ) do
			specns[ #specns + 1 ] = p:Name()
		end
		
		menu.ActivePlayers = #players
		menu.ActiveSpectators = #specs
		menu.Spectators = "Spectators: " .. (#specs > 0 and string.Implode( ", ", specns ) or "None")
	end

	for _,v in pairs( list:GetCanvas():GetChildren() ) do
		if IsValid( v ) then
			v:Remove()
		end
	end

	for id,ply in pairs( players ) do
		PutPlayerItem( cont, list, ply, mw, id, #players )
	end
	
	if bots and #players == 0 then
		if cont:GetTall() > 0 and IsValid( menu.Players ) then
			cont:SetTall( 0 )
			
			local full = menu:GetTall()
			menu.Players.BaseTall = menu.Players:GetTall()
			menu.Players:SetTall( full * 0.9 + 12 )
		end
	elseif bots and cont:GetTall() == 0 then
		local full = menu:GetTall()
		menu.Players:SetTall( menu.Players.BaseTall )
		cont:SetTall( full - menu.Players.BaseTall - (40 * 2 - 8) )
	end
	
	list:GetCanvas():InvalidateLayout()
end

local function CreateTeamList( parent, mw )
	local main, list = vgui.Create( "DPanel", parent )
	main:DockPadding( 8, 8, 8, 8 )
	
	function main:Paint( w, h )
		DrawCol( Color( 255, 255, 255, 2 ) )
		surface.DrawOutlinedRect( 0, 0, w, h - 2 )
	end
	
	function main:RefreshPlayers()
		ListPlayers( self, list, mw )
	end

	local head = vgui.Create( "DPanel", main )
	head:DockMargin( 0, 0, 0, 4 )
	head:Dock( TOP )
	head.Paint = function() end

	local rank = vgui.Create( "DLabel", head )
	rank:SetText( "Rank" )
	rank:SetFont( "Trebuchet24" )
	rank:SetTextColor( CWhite )
	rank:SetWidth( 50 )
	rank:Dock( LEFT )
	
	local player = vgui.Create( "DLabel", head )
	player:SetText( "Player" )
	player:SetFont( "Trebuchet24" )
	player:SetTextColor( CWhite )
	player:SetWidth( 60 )
	player:DockMargin( mw + 14, 0, 0, 0 )
	player:Dock( LEFT )
	main.LeftMax = player
	
	local ping = vgui.Create( "DLabel", head )
	ping:SetText( "Ping" )
	ping:SetFont( "Trebuchet24" )
	ping:SetTextColor( CWhite )
	ping:SetWidth( 50 )
	ping:DockMargin( 0, 0, 0, 0 )
	ping:Dock( RIGHT )

	local style = vgui.Create( "DLabel", head )
	style:SetText( "Style" )
	style:SetFont( "Trebuchet24" )
	style:SetTextColor( CWhite )
	style:SetWidth( 80 )
	style:DockMargin( 0, 0, menu.RecordOffset - 18, 0 )
	style:Dock( RIGHT )
	
	local timer = vgui.Create( "DLabel", head )
	timer:SetText( "Record" )
	timer:SetFont( "Trebuchet24" )
	timer:SetTextColor( CWhite )
	timer:SetWidth( 80 )
	timer:DockMargin( 0, 0, 18, 0 )
	timer:Dock( RIGHT )
	main.RightMax = timer
	
	list = vgui.Create( "DScrollPanel", main )
	list:Dock( FILL )

	local canvas = list:GetCanvas()
	function canvas:OnChildAdded( child )
		child:Dock( TOP )
	end

	return main
end

local function CreateBotList( parent, mw )
	local main, list = vgui.Create( "DPanel", parent )
	main:DockPadding( 8, 8, 8, 12 )
	
	function main:Paint( w, h )
		DrawCol( Color( 255, 255, 255, 2 ) )
		surface.DrawOutlinedRect( 0, 0, w, h - 4 )
	end
	
	function main:RefreshPlayers()
		ListPlayers( self, list, mw, true )
	end

	local head = vgui.Create( "DPanel", main )
	head:DockMargin( 0, 0, 0, 4 )
	head:Dock( TOP )
	head.Paint = function() end

	local rank = vgui.Create( "DLabel", head )
	rank:SetText( "Type" )
	rank:SetFont( "Trebuchet24" )
	rank:SetTextColor( CWhite )
	rank:SetWidth( 80 )
	rank:Dock( LEFT )
	
	local player = vgui.Create( "DLabel", head )
	player:SetText( "Replay" )
	player:SetFont( "Trebuchet24" )
	player:SetTextColor( CWhite )
	player:SetWidth( 60 )
	player:DockMargin( mw + 14 - 30, 0, 0, 0 )
	player:Dock( LEFT )
	main.LeftMax = player
	
	local ping = vgui.Create( "DLabel", head )
	ping:SetText( "Date" )
	ping:SetFont( "Trebuchet24" )
	ping:SetTextColor( CWhite )
	ping:SetWidth( 50 )
	ping:DockMargin( 0, 0, 0, 0 )
	ping:Dock( RIGHT )

	local timer = vgui.Create( "DLabel", head )
	timer:SetText( "Record" )
	timer:SetFont( "Trebuchet24" )
	timer:SetTextColor( CWhite )
	timer:SetWidth( 80 )
	timer:DockMargin( 0, 0, 80, 0 )
	timer:Dock( RIGHT )
	main.RightMax = timer
	
	list = vgui.Create( "DScrollPanel", main )
	list:Dock( FILL )
	list.TimerLabel = timer
	
	local canvas = list:GetCanvas()
	function canvas:OnChildAdded( child )
		child:Dock( TOP )
	end

	return main
end

function GM:ScoreboardShow()
	if IsValid( menu ) then
		menu.StartTime = st()
		menu:SetVisible( true )
		
		if menu.Players and menu.Players.RefreshPlayers then menu.Players:RefreshPlayers() end
		if menu.Bots and menu.Bots.RefreshPlayers then menu.Bots:RefreshPlayers() end
		if menu.Bottom and menu.Bottom.Specs then menu.Bottom.Specs:SetText( menu.Spectators ) end
	else
		menu = vgui.Create( "DFrame" )
		menu:SetSize( ScrW() * 0.5, ScrH() * 0.8 )
		menu:SetTitle( " ")
		menu:DockPadding( 4, 4, 4, 4 )
		menu.RecordOffset = ((ScrW() - 1280) / 64) * 8
		menu.StartTime = st()
		menu.Opacity = 150
		menu:SetDraggable( false )
		menu:ShowCloseButton( false )
		menu:Center()
		menu:MakePopup()
		menu:SetKeyboardInputEnabled( false )
		menu:SetDeleteOnClose( false )
		
		menu.Spectators = ""
		
		menu.PerformLayout = function( s )
			s.Players:SetWidth( s:GetWide() )
		end

		menu.Paint = function( s, w, h )
			Derma_DrawBackgroundBlur( s, s.StartTime )
			draw.RoundedBox( 8, 0, 0, w, h, Color( 35, 35, 35, s.Opacity ) )
		end

		menu.Credits = vgui.Create( "DPanel", menu )
		menu.Credits:Dock( TOP )
		menu.Credits:DockPadding( 8, 2, 8, 0 )
		menu.Credits.Paint = function() end

		local name = Label( GAMEMODE.DisplayName, menu.Credits )
		name:Dock( LEFT )
		name:SetFont( "ScoreboardTitle" )
		name:SetTextColor( CWhite )
		
		name.PerformLayout = function( s )
			surface.SetFont( s:GetFont() )
			local w, h = surface.GetTextSize( s:GetText() )
			s:SetSize( w, h )
		end

		local credits = vgui.Create( "DButton", menu.Credits )
		credits:Dock( RIGHT )
		credits:SetFont( "ScoreboardAuthor" )
		credits:SetText( string.format( "%s\nBy %s\nVersion %.2f", Core.Config.DisplayName, GAMEMODE.Author, Core.Config.Version ) )
		credits:SetTextColor( CWhite )
		credits:SetDrawBackground( false )
		credits:SetDrawBorder( false )
		credits.PerformLayout = name.PerformLayout
		credits.DoClick = function()
			gui.OpenURL( "http://steamcommunity.com/id/GraviousDev/" )
		end
		
		menu.Credits.PerformLayout = function( s )
			surface.SetFont( name:GetFont() )
			local w, h = surface.GetTextSize( name:GetText() )
			s:SetTall( h )
		end

		surface.SetFont( "ScoreboardPlayer" )
		
		local dist = menu:GetTall()
		local bottom, ratio = 40, 0.7
		local mw, mh = surface.GetTextSize( "Retrieving..." )
		
		menu.Players = CreateTeamList( menu, mw )
		menu.Players:SetTall( dist * ratio )
		menu.Players:Dock( TOP )
		menu.Players:RefreshPlayers()
		
		menu.Bots = CreateBotList( menu, mw )
		menu.Bots:SetTall( dist - (dist * ratio) - (bottom * 2 - 8) )
		menu.Bots:Dock( TOP )
		menu.Bots:RefreshPlayers()
		
		menu.Bottom = vgui.Create( "DPanel", menu )
		menu.Bottom:SetTall( bottom )
		menu.Bottom:Dock( TOP )
		menu.Bottom:DockPadding( 0, 0, 0, 0 )
		menu.Bottom.Paint = function() end
		
		local specs = vgui.Create( "DButton", menu.Bottom )
		specs:SetText( menu.Spectators )
		specs:SetFont( "GUIButtonFont" )
		specs:SetTextColor( Color( 150, 150, 150 ) )
		specs:SetWide( menu:GetWide() - 100 )
		specs:SetDrawBackground( false )
		specs:SetDrawBorder( false )
		specs:Dock( LEFT )
		specs:DockMargin( 4, 0, 0, 24 )
		
		specs.PerformLayout = name.PerformLayout
		specs.DoClick = OpenSpecMenu
		specs.DoRightClick = OpenSpecMenu
		menu.Bottom.Specs = specs

		local settings = vgui.Create( "DButton", menu.Bottom )
		settings:Dock( RIGHT )
		settings:DockMargin( 0, 0, 4, 0 )
		settings:SetText( "" )
		settings:SetWide( 64 )
		settings.Paint = function( s, w, h )
			DrawText( "Settings", "GUIButtonFont", 0, 8, Color( 150, 150, 150 ), tal, tac )
			DrawMat( icon_setting )
			DrawCol( CWhite )
			DrawTex( w - 16, 0, 16, 16 )
		end
		
		settings.DoClick = function()
			Core.SpawnWindow( { ID = "Settings", Dimension = { x = 400, y = 300 }, Args = { Title = "Main Menu", Mouse = true, Blur = true } } )
		end
	end
end

OpenMenu = function( ply )
	if not IsValid( ply ) then return end
	if IsValid( contextspec ) and ply:IsBot() then return end
	local actions, open = DermaMenu(), true

	if ply != lp() then	
		if not ply:IsBot() then
			if IsGlobalAdmin( ply ) then
				local admin = actions:AddOption( "Player is an admin" )
				admin:SetIcon( "icon16/shield.png" )
				actions:AddSpacer()
			end
		
			local mute = actions:AddOption( ply:IsMuted() and "Local unmute" or "Local mute" )
			mute:SetIcon( ply:IsMuted() and "icon16/sound_low.png" or "icon16/sound_mute.png" )
			function mute:DoClick()
				Core.MutePlayer( { Type = "Voice", Player = ply } )
			end
			
			local chatmute = actions:AddOption( ply.ChatMuted and "Local chat unmute" or "Local chat mute" )
			chatmute:SetIcon( "icon16/keyboard_" .. (ply.ChatMuted and "add" or "delete") .. ".png" )
			function chatmute:DoClick()
				Core.MutePlayer( { Type = "Chat", Player = ply } )
			end
			
			local profile = actions:AddOption( "View Profile" )
			profile:SetIcon( "icon16/vcard.png" )
			function profile:DoClick()
				if IsValid( ply ) then
					ply:ShowProfile()
				end
			end
			
			local lprofile = actions:AddOption( "View " .. string.sub( string.upper( Core.Config.BaseType ), 1, 1 ) .. string.sub( Core.Config.BaseType, 2 ) .. " Profile" )
			lprofile:SetIcon( "icon16/report_magnify.png" )
			function lprofile:DoClick()
				if IsValid( ply ) then
					RunConsoleCommand( "say", "/profile " .. ply:SteamID() )
				end
			end
			
			local spec = actions:AddOption( "Spectate " .. (ply:IsBot() and "Bot" or "Player") )
			spec:SetIcon( "icon16/eye.png" )
			function spec:DoClick()
				if IsValid(ply) then
					RunConsoleCommand( "spectate", ply:SteamID(), ply:Name() )
				end
			end
			
			local race = actions:AddOption( "Challenge to race" )
			race:SetIcon( "icon16/clock_play.png" )
			function race:DoClick()
				if IsValid( ply ) then
					RunConsoleCommand( "say", "!race " .. ply:SteamID() )
				end
			end
			
			local raceg = actions:AddOption( "Invite to group race" )
			raceg:SetIcon( "icon16/group_go.png" )
			function raceg:DoClick()
				if IsValid( ply ) then
					RunConsoleCommand( "say", "!racegroup " .. ply:SteamID() )
				end
			end
		else
			local bot = actions:AddOption( "Player is a WR bot" )
			bot:SetIcon( "icon16/control_end.png" )
			actions:AddSpacer()
			
			local szURI = ply:VarNet( "Get", "ProfileURI", "" )
			if szURI != "" then
				local uri = actions:AddOption( "View Runner Profile" )
				uri:SetIcon( "icon16/vcard.png" )
				function uri:DoClick()
					gui.OpenURL( "http://steamcommunity.com/profiles/" .. szURI )
				end
			end
			
			local spec = actions:AddOption( "Spectate " .. (ply:IsBot() and "Bot" or "Player") )
			spec:SetIcon( "icon16/eye.png" )
			function spec:DoClick()
				if IsValid( ply ) then
					RunConsoleCommand( "spectate", ply:SteamID(), ply:Name() )
				end
			end
		end

		if lp().Practice then
			local tpto = actions:AddOption( "Teleport to player" )
			tpto:SetIcon( "icon16/lightning_go.png" )
			function tpto:DoClick()
				if IsValid( ply ) then
					RunConsoleCommand( "say", "!tp " .. ply:Name() )
				end
			end
		end
	else
		open = false
	end
	
	if open and IsValid( lp() ) and IsGlobalAdmin( lp() ) then
		actions:AddSpacer()
		
		for i = 1, #AdminOptions do
			local item = AdminOptions[ i ]			
			local option = actions:AddOption( item[ 1 ] )
			option:SetIcon( "icon16/" .. item[ 2 ] .. ".png" )
			option.p = ply
			option.sid = ply:SteamID()
			option.DoClick = item[ 3 ]
			
			if item[ 4 ] then
				actions:AddSpacer()
			end
		end
	end

	if open then
		actions:Open()
		
		RegisterDermaMenuForClose( actions )
		return actions
	end
end

OpenSpecMenu = function()
	local ply = lp()
	if not IsValid( ply ) then return end	
	
	local valids = 0
	for _,p in pairs( player.GetHumans() ) do
		if IsValid( p ) and not p:Alive() and p != ply then
			valids = valids + 1
		end
	end
	
	if valids == 0 then return end
	local actions, itm, cmd, pnl = DermaMenu(), {}
	cmd, pnl = actions:AddSubMenu( "Local mute" ) pnl:SetIcon( "icon16/sound_mute.png" ) itm[ #itm + 1 ] = cmd cmd.Execution = function( pl ) pl:SetMuted( true ) Core.Print( "General", pl:Name() .. " has been locally muted" ) end
	cmd, pnl = actions:AddSubMenu( "Local unmute" ) pnl:SetIcon( "icon16/sound_low.png" ) itm[ #itm + 1 ] = cmd cmd.Execution = function( pl ) pl:SetMuted( false ) Core.Print( "General", pl:Name() .. " has been locally unmuted" ) end
	cmd, pnl = actions:AddSubMenu( "Local chat mute" ) pnl:SetIcon( "icon16/keyboard_delete.png" ) itm[ #itm + 1 ] = cmd cmd.Execution = function( pl ) pl.ChatMuted = true Core.Print( "General", pl:Name() .. " has been locally chat muted" ) end
	cmd, pnl = actions:AddSubMenu( "Local chat unmute" ) pnl:SetIcon( "icon16/keyboard_add.png" ) itm[ #itm + 1 ] = cmd cmd.Execution = function( pl ) pl.ChatMuted = nil Core.Print( "General", pl:Name() .. " has been locally chat unmuted" ) end
	cmd, pnl = actions:AddSubMenu( "View Ping" ) pnl:SetIcon( "icon16/server_lightning.png" ) itm[ #itm + 1 ] = cmd cmd.Execution = function( pl ) Core.Print( "General", pl:Name() .. " has a ping of " .. pl:Ping() ) end
	cmd, pnl = actions:AddSubMenu( "View Profile" ) pnl:SetIcon( "icon16/vcard.png" ) itm[ #itm + 1 ] = cmd cmd.Execution = function( pl ) pl:ShowProfile() end
	cmd, pnl = actions:AddSubMenu( "View " .. string.sub( string.upper( Core.Config.BaseType ), 1, 1 ) .. string.sub( Core.Config.BaseType, 2 ) .. " Profile" ) pnl:SetIcon( "icon16/report_magnify.png" ) itm[ #itm + 1 ] = cmd cmd.Execution = function( pl ) RunConsoleCommand( "say", "/profile " .. pl:SteamID() ) end
	
	if IsGlobalAdmin( ply ) then
		actions:AddSpacer()
		
		for i = 1, #AdminOptions do
			local item = AdminOptions[ i ]			
			local c, p = actions:AddSubMenu( item[ 1 ] )
			p:SetIcon( "icon16/" .. item[ 2 ] .. ".png" )
			c.Execution = function( pl ) item[ 3 ]( { p = pl, sid = pl:SteamID() } ) end

			itm[ #itm + 1 ] = c
			if item[ 4 ] then actions:AddSpacer() end
		end
	end
	
	for _,p in pairs( player.GetHumans() ) do
		if not p:Alive() and p != ply then
			for i,v in pairs( itm ) do
				local opt = v:AddOption( p:Name() )
				opt.Owner, opt.Holder = p, v

				if IsGlobalAdmin( p ) then
					opt:SetIcon( "icon16/shield.png" )
				end
				
				function opt:DoClick()
					if IsValid( self.Owner ) and IsValid( self.Holder ) and type( self.Holder.Execution ) == "function" then
						self.Holder.Execution( self.Owner )
					end
				end
			end
		end
	end
	
	actions:Open()
	contextspec = actions
	RegisterDermaMenuForClose( actions )
end

OpenTooltip = function( se, bx, by )
	if not menu then return end
	
	local display, bounds = "none"
	for key,rect in pairs( se.boxes ) do
		local ll, lt, lr, lb = rect[ 1 ], rect[ 2 ], rect[ 1 ] + rect[ 3 ], rect[ 2 ] + rect[ 4 ]
		if bx >= ll and by >= lt and bx <= lr and by <= lb then
			display = key
			bounds = { ll, lt, lr, lb }
			
			break
		end
	end
	
	local content = TooltipHelp[ display ]
	if not content then return end
	
	if TooltipInfo[ display ] then
		local append = TooltipInfo[ display ]( se )
		if append then
			content = content .. "\n\n" .. append
		end
	end
	
	if IsValid( menu.tip ) then
		if menu.tip.Title != content then
			menu.tip:Remove()
		else
			return false
		end
	end
	
	menu.tip = vgui.Create( "DTooltip" )
	menu.tip:SetText( content )
	menu.tip:OpenForPanel( se )
	menu.tip:SetVisible( false )
	
	menu.tip.Opened = false
	menu.tip.Title = content
	menu.tip.Bounds = bounds
	menu.tip.OpenX, menu.tip.OpenY = input.GetCursorPos()
	
	menu.tip.PositionTooltip = function( t )
		t:PerformLayout()
		
		local x, y = input.GetCursorPos()
		local w, h = t:GetSize()
		local lx, ly = t.TargetPanel:LocalToScreen( 0, 0 )
		local lw, lh = t.TargetPanel:GetSize()
		
		y = t.OpenY - h - 20
		t:SetPos( math.Clamp( x - w * 0.5, lx, lx + lw - t:GetWide() ), y )
	end
	
	menu.tip.Think = function( t )
		if not IsValid( menu ) or not menu:IsVisible() or not IsValid( t.TargetPanel ) or input.IsMouseDown( MOUSE_LEFT ) or input.IsMouseDown( MOUSE_RIGHT ) then
			return t:Remove()
		end
		
		local rx, ry = t.TargetPanel:ScreenToLocal( gui.MousePos() )
		if rx < t.Bounds[ 1 ] or rx > t.Bounds[ 3 ] or ry < t.Bounds[ 2 ] or ry > t.Bounds[ 4 ] then
			return t:Remove()
		end
		
		if not t.Opened then
			t.Opened = true
			t:SetVisible( true )
		end
	end
end

local function ReceiveScoreboard( varArgs )
	ScoreData[ varArgs.Target ] = varArgs
	ScoreRequest = nil
end
Core.Register( "GUI/Scoreboard", ReceiveScoreboard )

function GM:ScoreboardHide() if IsValid( menu ) then CloseDermaMenus() menu:Close() end end
function GM:HUDDrawScoreBoard() end