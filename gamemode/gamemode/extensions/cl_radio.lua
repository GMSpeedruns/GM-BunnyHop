local Radio = {}
Radio.Path = Core.GetSettings().Radio
Radio.Channels = {}
Radio.Controls = {}
Radio.Selected = {}
Radio.SearchList = {}
Radio.PlayList = {}
Radio.MainList = {}
Radio.ServerMsg = { "Search", "Search_YT", "Search_SC", "Add_YT", "Add_SC" }

function Radio.Init()
	if not Radio.Initialized then
		Radio.Settings = util.JSONToTable( file.Read( Radio.Path, "DATA" ) or "" ) or {}
		Radio.Volume = Radio.Settings.Volume or 100
		Radio.Put = function( s, k, v )
			s.Settings[ k ] = v
			file.Write( s.Path, util.TableToJSON( s.Settings, true ) )
		end
		
		if Radio.Settings.List then
			for k,v in pairs( Radio.Settings.List ) do
				if tostring( k ) != k then
					Radio.Settings.List[ tostring( k ) ] = v
					Radio.Settings.List[ k ] = nil
				end
			end
		end
	end
	
	Radio.Initialized = true
	Radio.Loaded = nil
	Radio.Player = vgui.Create( "DHTML" )
	
	Radio.Actions = {
		["Actions"] = function() end,
		["Add song from YouTube"] = function( t ) DermaRequest = Derma_StringRequest( t, "Please enter the YouTube URL or the Video ID below", "", function( r ) Radio.Callback( "Add_YT", r ) end, function() end ) end, 
		["Add song from Soundcloud"] = function( t ) DermaRequest = Derma_StringRequest( t, "Please enter the Soundcloud URL or the Track ID below", "", function( r ) Radio.Callback( "Add_SC", r ) end, function() end ) end, 
		["Search YouTube for songs"] = function( t ) DermaRequest = Derma_StringRequest( t, "Please enter the search terms to query against the YouTube API", "", function( r ) Radio.Callback( "Search_YT", r ) end, function() end ) end,
		["Search Soundcloud for songs"] = function( t ) DermaRequest = Derma_StringRequest( t, "Please enter the search terms to query against the Soundcloud API", "", function( r ) Radio.Callback( "Search_SC", r ) end, function() end ) end,
		["Revert search query"] = function() Radio.Callback( "Revert" ) end,
		["Put selected item(s) in playlist"] = function() Radio.Callback( "Playlist", "Add", Radio.Selected ) end, 
		["Remove selected item(s) from playlist"] = function() Radio.Callback( "Playlist", "Remove" ) end, 
		["Open playlist"] = function() Radio.Callback( "Playlist", "Toggle" ) end, 
		["Clear playlist"] = function() Radio.Callback( "Playlist", "Clear" ) end,
		["View preferences"] = function() Radio.Callback( "Preferences" ) end
	}
	
	Radio.DirectAct = {
		["play"] = function( c ) c:Play() Radio.Act( "Btn", Radio.Controls[ 1 ], true ) end,
		["pause"] = function( c ) c:Pause() end,
		["stop"] = function( c ) c:Stop() end,
		["volume"] = function( c, v ) c:SetVolume( v / 100 ) end,
		["seek"] = function( c, v ) Radio.Act( "Seek", v ) end
	}
	
	Radio.ActionNames = {}
	for k,_ in pairs( Radio.Actions ) do
		Radio.ActionNames[ #Radio.ActionNames + 1 ] = k
	end
	
	local yp = Radio.Player
	yp:SetPos( 0, 0 )
	yp:SetSize( 0, 0 )
	yp:SetVisible( false )
	
	yp.OldConsoleMessage = yp.ConsoleMessage
	yp.ConsoleMessage = function( ys, msg )
		if msg then return end
		return ys.OldConsoleMessage( ys, msg )
	end
	
	yp:AddFunction( "medialiblua", "Event", Radio.StateChange )
	
	if IsValid( Radio.BtVolume ) then Radio.BtVolume:UpdatePos( nil, Radio.Volume ) end
	if IsValid( Radio.BtPosition ) then Radio.BtPosition:UpdatePos( nil, 0 ) end
end

function Radio.GenerateGUI( s, data, tools )
	Radio.Window = s
	
	if not Radio.Initialized then
		Radio.Init()
	end
	
	local w, h = s:GetSize()
	local view = tools.ListView( s, 8, 54, w - 16, h - 110, function( se, i ) Radio.Callback( "Select", se, i ) end )
	view.DoDoubleClick = function( _, i ) Radio.Callback( "Double", i ) end
	view:AddColumn( "Title" ):SetWidth( 360 )
	view:AddColumn( "Artist" )
	view:AddColumn( "Album" )
	view:AddColumn( "Duration" ):SetFixedWidth( 50 )
	view:AddColumn( "Requests" ):SetFixedWidth( 50 )
	
	if Core.GetSettings():ToggleValue( "RADIO_DATES" ) then
		view:AddColumn( "Date" ):SetFixedWidth( 70 )
	end
	
	Radio.MainView = view
	Radio.MainView.Bind = "MainList"
	Radio.ActiveView = view
	
	local sk = derma.GetDefaultSkin()
	if not sk.OldListViewPaint then
		sk.OldListViewPaint = sk.PaintListViewLine
		
		function sk:PaintListViewLine( s, w, h )
			local tab = Radio[ s:GetParent():GetParent().Bind ]
			if (tab and Radio.Highlight and tab[ s:GetID() ] == Radio.Highlight) and not s:IsSelected() then
				self.tex.Input.ListBox.Hovered( 0, 0, w, h, Color( 100, 170, 140 ) )
			else
				self:OldListViewPaint( s, w, h )
			end
		end
	end
	
	local own = tools.ListView( s, 8, 54, w - 16, h - 110, function( se, i ) Radio.Callback( "Playlist", "Select", i ) end )
	own.Identifier = "Playlist"
	own.DoDoubleClick = function( se, i ) Radio.Callback( "Playlist", "Double", i ) end
	own:AddColumn( "Title" ):SetWidth( 340 )
	own:AddColumn( "Artist" )
	own:AddColumn( "Album" )
	own:AddColumn( "Duration" ):SetFixedWidth( 50 )
	own:AddColumn( "Added on" ):SetFixedWidth( 70 )
	own:SetVisible( false )
	Radio.OwnView = own
	Radio.OwnView.Bind = "PlayList"
	
	local list = tools.ListView( s, 8, 54, w - 16, h - 110, function() Radio.Callback( "Cancel" ) end )
	list.Identifier = "Search results"
	list.DoDoubleClick = function( _, i ) Radio.Callback( "Request", i ) end
	list:SetMultiSelect( false )
	list:AddColumn( "Title" )
	list:AddColumn( "Uploader" ):SetFixedWidth( 120 )
	list:AddColumn( "Date" ):SetFixedWidth( 70 )
	list:SetVisible( false )
	Radio.ListView = list
	Radio.ListView.Bind = "SearchList"
	Radio.Views = { view, own, list }
	
	local bx = w - 200
	local combo = tools.Combo( s, 20, h - 42, 100, 20, { Default = function() return "Actions" end }, Radio.ActionNames, function( se, _, v ) Radio.Callback( "Combo", v, se ) end )
	local search = tools.Text( s, 20 + 110, h - 42, 200, 20, { Default = function() return "Search..." end }, function( se, r ) Radio.Callback( "Search", r ) end )
	search.IsPrompt = function( se ) DermaRequest = Derma_StringRequest( "Search server radio", "Enter your search query below\nRelevant IDs, titles, artists and albums will be displayed", "", function( r ) Radio.Callback( "Search", r ) end, function() end ) se.Request = DermaRequest end
	
	local play = tools.GrayButton( s, "Play", bx, h - 44, 50, 24, false, function( se ) Radio.Callback( "Play", se ) end ) bx = bx + 60
	local pause = tools.GrayButton( s, "Pause", bx, h - 44, 60, 24, false, function( se ) Radio.Callback( "Pause", se ) end ) bx = bx + 70
	local stop = tools.GrayButton( s, "Stop", bx, h - 44, 50, 24, false, function( se ) Radio.Callback( "Stop", se ) end )
	Radio.Controls = { play, pause, stop }
	
	local labvolt, labpost = "Volume:  ----------------- %d%%", "Position: ----------------- %s"
	local labvol = tools.Label( s, 340, h - 48, "BottomHUDTiny", string.format( labvolt, 100 ), tools.C.Text )
	local labpos = tools.Label( s, 340, h - 32, "BottomHUDTiny", string.format( labpost, Radio.Time( 0 ) ), tools.C.Text )
	local vol = tools.GrayButton( s, "", 390, h - 48, 6, 16, false, function() end )
	local pos = tools.GrayButton( s, "", 390, h - 32, 6, 16, false, function() end )
	
	local function ViewSort( s, c, d )
		s:OldSort( c, d )
		
		local out = {}
		for k,v in pairs( s.Sorted ) do
			local tab = Radio[ s.Bind ] or {}
			if tab[ v:GetID() ] then
				local n = { tab[ v:GetID() ] }
				for i = 1, #v.Columns do
					n[ i + 1 ] = v:GetValue( i )
				end
				
				out[ #out + 1 ] = n
			end
		end
		
		Radio[ "Sorted" .. s.Bind ] = out
	end
	
	local function SliderThink( s )
		if s.IsActive then
			local x, y = s:GetParent():ScreenToLocal( gui.MousePos() )
			local v = math.Clamp( x, s.BaseX, s.TopX )
			s.Slider = (v - s.BaseX) / (s.TopX - s.BaseX)
			s:UpdatePos()
		end
	end
	
	local function SliderEnd( s, b )
		if not b then
			local v = s.Slider * s.Scale
			if v != s.LastSubmitted then
				s.Default = v
				s.LastSubmitted = v
				s.SetFunc( v )
			end
		end
	end
	
	local function SliderUpdate( s, m, p )
		if m then s.Scale = m end
		if p then s.Slider = s.Scale == 0 and 0 or p / s.Scale end
		if s.IsActive and (m or p) then return end
		
		s:SetPos( math.Clamp( s.BaseX + s.Slider * (s.TopX - s.BaseX), s.BaseX, s.TopX ), s.BaseY )
		s.Label.Target:SetText( s.Label.Format( s, s.Slider * s.Scale ) )
	end
	
	vol.Think = SliderThink pos.Think = SliderThink
	vol.MouseCallback = SliderEnd pos.MouseCallback = SliderEnd
	vol.UpdatePos = SliderUpdate pos.UpdatePos = SliderUpdate
	view.OldSort = view.SortByColumn view.SortByColumn = ViewSort
	own.OldSort = own.SortByColumn own.SortByColumn = ViewSort
	
	vol.BaseX, vol.BaseY = vol:GetPos() vol.TopX = vol.BaseX + 80 vol.Slider = 1 vol.Scale = 100 vol.Label = { Target = labvol, Text = labvolt, Format = function( s, c ) return string.format( s.Label.Text, c ) end } vol:UpdatePos( nil, Radio.Volume ) vol.SetFunc = function( v ) Radio.Callback( "Volume", v ) end
	pos.BaseX, pos.BaseY = pos:GetPos() pos.TopX = pos.BaseX + 80 pos.Slider = 0 pos.Scale = 0 pos.Label = { Target = labpos, Text = labpost, Format = function( s, c ) return string.format( s.Label.Text, Radio.Time( c ) ) end } pos.SetFunc = function( t ) Radio.Callback( "Position", t ) end
	
	Radio.BtVolume = vol Radio.BtPosition = pos
	Radio.MainList = {}
	Radio.AddList( view, false )
	
	for i,item in pairs( Radio.SortedMainList and table.Copy( Radio.SortedMainList ) or table.Copy( data ) ) do
		Radio.MainList[ i ] = table.remove( item, 1 )
		Radio.AddList( view, true, item )
	end
	
	if Radio.ShownView and Radio.ShownView != "MainView" then
		Radio.Callback( "Playlist", "Toggle" )
	end
	
	Radio.RecentOpen = SysTime()
end

function Radio.Callback( id, v, arg )
	if id == "Select" then
		Radio.Selected = {}
		
		for _,l in pairs( v:GetSelected() ) do
			Radio.Selected[ l:GetID() ] = true
		end
		
		if Radio.Editor and input.IsMouseDown( MOUSE_RIGHT ) then
			timer.Simple( 0.6, function()
				if input.IsMouseDown( MOUSE_RIGHT ) then
					Radio.Callback( "Edit", Radio.MainView, arg )
				end
			end )
		end
	elseif id == "Edit" then
		if IsValid( v ) and (v == Radio.OwnView and true or Radio.Editor) then
			local h
			for at,c in pairs( v.Columns ) do
				local cx, cw = c:GetPos(), c:GetSize()
				local x, y = v:ScreenToLocal( gui.MousePos() )
				if x >= cx and x <= cx + cw then
					h = at
					break
				end
			end
			
			if h and v.Columns[ h ] and arg and Radio.MainList[ arg ] then
				DermaRequest = Derma_StringRequest( "Edit column " .. v.Columns[ h ].Header:GetText(), "New value:", v:GetLine( arg ):GetColumnText( h ), function( r ) v:GetLine( arg ):SetColumnText( h, r ) if v.SEdit then v.SEdit( arg, h, r ) elseif v == Radio.MainView and Radio.Editor then Core.Send( "Radio", { "Edit", Radio.MainList[ arg ], h, r } ) end end, function() end )
			end
		end
	elseif id == "Double" then
		Radio.NextPlay = nil
		
		local yid = Radio.MainList[ v ]
		if yid then
			Core.Send( "Radio", { "Play", yid, "MainList", Volume = Radio.Volume } )
		end
	elseif id == "Request" then
		local yid = Radio.SearchList[ v ]
		if yid then
			Radio.Act( "View", Radio.MainView )
			Core.Send( "Radio", { "Add_" .. Radio.SearchList.Type, yid } )
		end
	elseif id == "Cancel" then
		if input.IsMouseDown( MOUSE_RIGHT ) then
			Radio.Act( "View", Radio.MainView )
		end
	elseif id == "Playlist" then
		if v == "Select" then
			if input.IsMouseDown( MOUSE_RIGHT ) then
				timer.Simple( 0.6, function()
					if input.IsMouseDown( MOUSE_RIGHT ) then
						Radio.OwnView.SEdit = function( i, c, r )
							local yid = Radio.PlayList[ i ]
							if Radio.Settings.List and Radio.Settings.List[ yid ] then
								Radio.Settings.List[ yid ][ c ] = r
								Radio:Put( "List", Radio.Settings.List )
							end
						end
						
						Radio.Callback( "Edit", Radio.OwnView, arg )
					end
				end )
			end
		elseif v == "Double" then
			Radio.NextPlay = nil
			
			local yid = Radio.PlayList[ arg ]
			if yid then
				Core.Send( "Radio", { "Play", yid, "PlayList", Volume = Radio.Volume } )
			end
		elseif v == "Add" then
			if table.Count( Radio.Selected ) == 0 or Radio.ActiveView != Radio.MainView then
				return Core.Modal( "No entries selected", "Please make sure you select the items you want to add to your list.\nYou can select multiple items by using CTRL or SHIFT." )
			end
			
			local list = Radio.Settings.List or {}
			local add, nadd = 0, 0
			
			for at,_ in pairs( Radio.Selected ) do
				local yid = Radio.MainList[ at ]
				local put = { [5] = Radio.Date( os.time() ) }
				
				for i = 1, 4 do
					local text = Radio.MainView:GetLine( at ):GetColumnText( i )
					put[ i ] = i == 1 and string.sub( text, 1, 2 ) == "> " and string.sub( text, 3 ) or text
				end
				
				if not list[ yid ] then
					list[ yid ] = put
					add = add + 1
				else
					nadd = nadd + 1
				end
			end
			
			if add > 0 then
				Radio:Put( "List", list )
				Core.Modal( "Items added", add .. " new item(s) added to your list!" .. (nadd > 0 and "\n" .. nadd .. " item(s) are already present in your playlist." or "") )
			else
				Core.Modal( "No new items have been added", "The reason for this is probably because the selected items were already in your playlist." )
			end
		elseif v == "Remove" then
			if Radio.ActiveView == Radio.OwnView then
				local del = 0
				for _,l in pairs( Radio.OwnView:GetSelected() ) do
					local yid = Radio.PlayList[ l:GetID() ]
					if Radio.Settings.List and Radio.Settings.List[ yid ] then
						Radio.Settings.List[ yid ] = nil
						del = del + 1
					end
				end
				
				if del > 0 then
					Radio:Put( "List", Radio.Settings.List )
					Radio.ActiveView = nil
					Radio.Callback( "Playlist", "Toggle" )
					
					Core.Modal( "Items removed", del .. " item(s) removed from your list." )
				else
					Core.Modal( "No items removed", "Please select the items you want to remove." )
				end
			else
				Core.Modal( "Wrong active view", "Please make sure you have your playlist opened." )
			end
		elseif v == "Clear" then
			if Radio.ActiveView == Radio.OwnView then
				if not arg then
					DermaRequest = Derma_StringRequest( "Confirm deletion", "Are you sure you want to remove all items in your playlist?\nWrite 'Yes' to continue, anything else will cancel the deletion", "No", function( r ) if r == "Yes" then Radio.Callback( "Playlist", "Clear", true ) end end, function() end )
				else
					local del = table.Count( Radio.Settings.List or {} )
					Radio.Settings.List = {}
					Radio:Put( "List", Radio.Settings.List )
					Radio.ActiveView = nil
					Radio.Callback( "Playlist", "Toggle" )
					
					Core.Modal( "Items deleted", del .. " item(s) deleted from your list." )
				end
			else
				Core.Modal( "Wrong active view", "Please make sure you have your playlist opened." )
			end
		elseif v == "Toggle" then
			local to = Radio.ActiveView == Radio.OwnView and Radio.MainView or Radio.OwnView
			if to == Radio.OwnView then
				Radio.ShownView = "OwnView"
				Radio.SortedPlayList = nil
				Radio.PlayList = {}
				Radio.AddList( Radio.OwnView, false )
				
				for yid,data in pairs( Radio.Settings.List or {} ) do
					Radio.PlayList[ Radio.AddList( Radio.OwnView, true, data ) ] = yid
				end
			else
				Radio.ShownView = "MainView"
			end
			
			Radio.Act( "View", to )
		end
	elseif id == "Revert" then
		Radio.MainList = {}
		Radio.SortedMainList = nil
		Radio.AddList( Radio.MainView, false )
		
		for i,item in pairs( table.Copy( Radio.Custom ) ) do
			Radio.MainList[ i ] = table.remove( item, 1 )
			Radio.AddList( Radio.MainView, true, item )
		end
	elseif id == "Preferences" then
		local wnd = Core.SpawnWindow( { ID = "Settings", Dimension = { x = 400, y = 300 }, Args = { Title = "Main Menu", Mouse = true, Blur = true } } )
		for i = 1, 3 do
			wnd.Menu[ i ].Data.Active = nil
		end
		
		local data = Core.GetWindow().Cache.Toggles[ Radio.SettingID ]
		wnd.Target = 4
		wnd.TTitle = data[ 1 ]
		wnd.TArray = data[ 2 ]
		wnd.ToggleFunc( { GetParent = function() return wnd end } )
	elseif id == "Combo" then
		Radio.Actions[ v ]( v )
		arg:SetValue( arg.Toggle.Default() )
	elseif id == "Volume" then
		Radio.Volume = v
		Radio:Put( "Volume", v )
		Radio.Act( "JS", { "mcontrol.run('volume',{vol:%f})", v } )
	elseif id == "Position" then
		Radio.Act( "JS", { "mcontrol.run('seek',{time:%.1f})", v } )
	elseif id == "Open" then
		Radio.Direct = v
		Radio.Callback( "Stop" )
		Radio.Act( v and "Play" or "URL", arg[ 1 ] )
		Radio.NextPlay = arg[ 2 ] != "" and { arg[ 2 ], arg[ 3 ] }
		Radio.Highlight = arg[ 3 ]
		
		if Core.GetSettings():ToggleValue( "RADIO_MESSAGES" ) and arg[ 4 ] != "" then
			Core.Print( "Radio", "Now playing '" .. arg[ 4 ] .. "' by '" .. arg[ 5 ] .. "'" )
		end
	elseif id == "Play" then
		Radio.Act( "JS", { "mcontrol.run('play')" } )
		
		if Radio.State != "playing" then
			for _,view in pairs( Radio.Views ) do
				if IsValid( view ) and view:IsVisible() then
					view:DoDoubleClick( view:GetSelectedLine() )
				end
			end
		end
	elseif id == "Pause" then
		Radio.State = "paused"
		Radio.Act( "Btn", v, true )
		Radio.Act( "JS", { "mcontrol.run('pause')" } )
	elseif id == "Stop" then
		if IsValid( Radio.Player ) then
			Radio.Player:SetHTML( "" )
		else
			Radio.Init()
		end
		
		for i,c in pairs( Radio.Channels ) do
			if IsValid( c ) then
				c:SetVolume( 0 )
				c:Stop()
				c = nil
				
				table.remove( Radio.Channels, i )
			end
		end
		
		Radio.NextPlay = nil
		Radio.Highlight = nil
		Radio.State = nil
		Radio.Act( "Btn" )
		Radio.Act( "Pos", { 0, 0 } )
	elseif table.HasValue( Radio.ServerMsg, id ) then
		Core.Send( "Radio", { id, v, Volume = Radio.Volume } )
	end
end

function Radio.StateChange( id, jsonstr )
	local event = util.JSONToTable( jsonstr )
	if id == "stateChange" then
		local state = event.state
		Radio.State = state
		Radio.Position = event.time or 0
		
		if state == "playing" then
			Radio.Act( "Btn", Radio.Controls[ 1 ], true )
		elseif state == "ended" then
			Radio.Act( "Btn" )
			
			if Radio.NextPlay then
				local list = Radio.NextPlay[ 1 ]
				local yid, to = Radio.NextPlay[ 2 ]
				local sorted, data = Radio[ "Sorted" .. list ], Radio[ list ] or {}
				
				if sorted then
					for _,t in pairs( sorted ) do
						if to then to = t[ 1 ] break
						elseif t[ 1 ] == yid then to = true end
					end
				else
					for _,i in pairs( data ) do
						if to then to = i break
						elseif i == yid then to = true end
					end
				end
				
				if to and to != true then
					Core.Send( "Radio", { "Play", to, list, Volume = Radio.Volume } )
				end
			end
		end
	elseif id == "playerLoaded" then
		Radio.Loaded = true
		Radio.Duration = event.duration
		Radio.Act( "Pos", { Radio.Duration or 0, Radio.Position or 0 } )
		Radio.Act( "Btn" )
		Radio.Act( "JS", { "mcontrol.run('volume',{vol:%f})", Radio.Volume or 100 } )
	elseif id == "timeChange" then
		Radio.Position = event.time or 0
		Radio.Act( "Pos", { Radio.Duration or 0, Radio.Position or 0 } )
		
		if Radio.RecentOpen and SysTime() - Radio.RecentOpen < 1.5 then
			Radio.Act( "Btn", Radio.Controls[ 1 ], true )
		end
		
		Radio.RecentOpen = nil
	elseif id == "error" then
		print( "[Radio]", "Playback error", event.message )
		
		if Core.GetSettings():ToggleValue( "RADIO_MESSAGES" ) then
			Core.Print( "Radio", "An error occurred while trying to play the song!" )
		elseif IsValid( Radio.Window ) then
			Core.Modal( "Playback error", "Couldn't start playback of the given song.\n\nSee console for details." )
		end
	end
end

function Radio.Act( szType, data, val )
	if szType == "URL" then
		if IsValid( Radio.Player ) then
			Radio.Player:OpenURL( data )
			Radio.Direct = nil
		end
	elseif szType == "JS" then
		if IsValid( Radio.Player ) then
			if Radio.Direct then
				local cmd = string.sub( data[ 1 ], 15, #data[ 1 ] - 1 )
				cmd = string.sub( cmd, 1, string.find( cmd, "'" ) - 1 )
				
				if Radio.DirectAct[ cmd ] and IsValid( Radio.Channel ) then
					Radio.DirectAct[ cmd ]( Radio.Channel, data[ 2 ] )
				end
			elseif Radio.Loaded then
				Radio.Player:QueueJavascript( string.format( unpack( data ) ) )
			end
		end
	elseif szType == "Pos" then
		if IsValid( Radio.Window ) and IsValid( Radio.BtPosition ) then
			Radio.BtPosition:UpdatePos( unpack( data ) )
		end
	elseif szType == "Btn" then
		if not IsValid( Radio.Window ) then return end
		for _,c in pairs( Radio.Controls ) do
			if not IsValid( c ) then return end
			c.Font = "GUIGrayButton" .. (data != c and "Light" or (val and "" or "Light"))
		end
	elseif szType == "Play" then
		Radio.Direct = true
		
		if IsValid( Radio.Channel ) then
			Radio.Channel:SetVolume( 0 )
			Radio.Channel:Stop()
			Radio.Channel = nil
		end
		
		sound.PlayURL( data, Radio.Skippable and "noblock" or "", function( c )
			if IsValid( c ) then
				c:Play()
				c:SetVolume( Radio.Volume / 100 )
				
				Radio.Act( "Btn", Radio.Controls[ 1 ], true )
				Radio.Duration = c:GetLength()
				Radio.Channel = c
				Radio.Channels[ #Radio.Channels + 1 ] = c
				
				timer.Create( "PositionSetter", 0.1, 0, function()
					if IsValid( Radio.Channel ) then
						Radio.Duration = Radio.Channel:GetLength()
						Radio.Position = Radio.Channel:GetTime()
						Radio.State = "playing"
						
						if Radio.SkipTo then
							Radio.Position = Radio.SkipTo
							Radio.Channel:SetTime( Radio.Position )
							
							Radio.SkipTo = nil
						end
						
						Radio.Act( "Pos", { Radio.Duration, Radio.Position } )
						
						if Radio.Position > 0 and Radio.Position < Radio.Duration and Radio.Channel:GetState() == 1 then
							Radio.Act( "Btn", Radio.Controls[ 1 ], true )
						end
						
						if Radio.Channel:GetState() == 0 and Radio.Duration == Radio.Position then
							Radio.StateChange( "stateChange", util.TableToJSON( { state = "ended" } ) )
							timer.Remove( "PositionSetter" )
						end
					else
						timer.Remove( "PositionSetter" )
					end
				end )
			else
				Core.Modal( "Playback error", "Couldn't retrieve stream correctly.\nPlease try again or consult the forums if the issue persists." )
			end
		end )
		
		if Radio.Skippable then
			Radio.Skippable = nil
		end
	elseif szType == "Seek" then
		if IsValid( Radio.Channel ) then
			if Radio.Channel:IsBlockStreamed() then
				local url = Radio.Channel:GetFileName()
				Radio.Channel:Stop()
				Radio.Channel = nil
				
				Radio.Skippable = true
				Radio.SkipTo = data
				Radio.Act( "Play", url )
			else
				Radio.Channel:SetTime( data )
			end
		end
	elseif szType == "View" then
		if not IsValid( Radio.Window ) then return end
		for _,v in pairs( Radio.Views ) do
			if not IsValid( v ) then return end
			v:SetVisible( v == data )
			
			if v == data then
				Radio.ActiveView = v
				
				if IsValid( Radio.Window ) then
					Radio.Window.Title = "Radio" .. (v.Identifier and " (" .. v.Identifier .. ")" or "")
				end
			end
		end
	end
end

function Radio.AddList( view, inst, data )
	if IsValid( Radio.Window ) and IsValid( view ) then
		if not inst then
			view:Clear()
			Radio.Act( "View", view )
		else
			return view:AddLine( unpack( data ) ):GetID()
		end
	end
end

function Radio.Time( n )
	if n < 3600 then
		return string.ToMinutesSeconds( n )
	else
		local h = 0		
		for i = 1, 10 do n = n - 3600 h = h + 1 if n < 3600 then break end end
		return (h < 10 and "0" or "") .. h .. ":" .. string.ToMinutesSeconds( n )
	end
end

function Radio.Date( n )
	return os.date( "%Y-%m-%d", n )
end

function Radio.Receive( ar )
	local id = ar:UInt( 4 )
	if id == 0 then
		if not ar:Bit() then
			Radio.Editor = ar:Bit()
			Radio.Custom = {}
			
			if ar:Bit() then
				for i = 1, ar:UInt( 16 ) do
					Radio.Custom[ #Radio.Custom + 1 ] = { ar:String(), ar:String(), ar:String(), ar:String(), Radio.Time( ar:UInt( 20 ) ), ar:UInt( 20 ), Radio.Date( ar:UInt( 32 ) ) }
				end
			end
		end
		
		Core.SpawnWindow( { ID = "Radio", Dimension = { x = 750, y = 500 }, Args = { Title = "Radio", Mouse = true, Blur = true, Custom = Radio.Custom, Populate = Radio.GenerateGUI } } )
	elseif id == 1 then
		Radio.Callback( "Open", ar:Bit(), { ar:String(), ar:String(), ar:String(), ar:String(), ar:String() } )
	elseif id == 2 then
		Radio.SearchList = { Type = ar:String() }
		Radio.AddList( Radio.ListView, false )
		Radio.AddList( Radio.ListView, true, { "Double click any of the songs below to start playing it", "", "" } )
		Radio.AddList( Radio.ListView, true, { "Right click anywhere to cancel the search and go back", "", "" } )
		Radio.AddList( Radio.ListView, true, { "", "", "" } )
		
		for i = 1, ar:UInt( 32 ) do
			Radio.SearchList[ i + 3 ] = ar:String()
			Radio.AddList( Radio.ListView, true, { ar:String(), ar:String(), ar:String() } )
		end
	elseif id == 3 then
		local yid = ar:String()
		local data = { ar:String(), ar:String(), "", Radio.Time( ar:UInt( 20 ) ), 1, Radio.Date( os.time() ) }
		
		local at = Radio.AddList( Radio.MainView, true, data )
		Radio.MainList[ at ] = yid

		table.insert( data, 1, yid )
		Radio.Custom[ #Radio.Custom + 1 ] = data
		
		if Radio.SortedMainList then
			Radio.SortedMainList[ at ] = data
		end
	elseif id == 4 then
		Radio.MainList = {}
		Radio.SortedMainList = nil
		
		Radio.AddList( Radio.MainView, false )
		
		for i = 1, ar:UInt( 16 ) do
			Radio.MainList[ i ] = ar:String()
			Radio.AddList( Radio.MainView, true, { ar:String(), ar:String(), ar:String(), Radio.Time( ar:UInt( 20 ) ), ar:UInt( 20 ), Radio.Date( ar:UInt( 32 ) ) } )
		end
	end
end
Core.Register( "Radio/Net", Radio.Receive )

local Toggles = Core.GetSettings().Toggles
Toggles["RADIO_DATES"] = { "RadioShowDate", false, nil, "Show dates" }
Toggles["RADIO_MESSAGES"] = { "RadioMessages", false, nil, "Print titles" }

local Window = Core.GetWindow()
Radio.SettingID = #Window.Cache.Toggles + 1
Window.Cache.Toggles[ Radio.SettingID ] = { "Radio preferences", { "RADIO_DATES", "RADIO_MESSAGES" } }