local Admin = {}
local ElemList = {}
local ElemCache = {}
local ElemData = {}

local function ReceiveAdmin( varArgs )
	local szType = tostring( varArgs[ 1 ] )
	if szType == "Query" then
		Admin.Query( varArgs )
	elseif szType == "EditZone" then
		Admin.Editor = varArgs[ 2 ] and varArgs[ 2 ] or nil
		hook.Add( "PostDrawTranslucentRenderables", "PreviewArea", Admin.DrawAreaEditor )
	elseif szType == "Request" then
		local tab = varArgs[ 2 ]
		DermaRequest = Derma_StringRequest( tab.Title, tab.Caption, tab.Default or "", function( r ) Admin.ReqAction( tab.Return, r or tab.Default, tab.Special ) end, function() end )
	elseif szType == "GUI" then
		Admin.Verify = true
		Admin.Reports = nil
		Admin.Logs = nil
		
		local args = varArgs[ 3 ] or Admin.Cached or { Width = 825, Height = 480, Title = "Admin Panel" }
		if string.find( args.Title, "Admin" ) then
			Admin.Cached = args
		elseif string.find( args.Title, "Reports" ) then
			Admin.Reports = true
		elseif string.find( args.Title, "Logs" ) then
			Admin.Logs = true
		end
		
		Core.SpawnWindow( { ID = varArgs[ 2 ], Dimension = { x = args.Width, y = args.Height }, Args = { Title = args.Title, Mouse = true, Blur = true, Custom = args, Populate = Admin.GenerateGUI } } )
		Admin.SubmitAction( "Players", varArgs[ 4 ] )
		Admin.SubmitAction( "Store", varArgs[ 5 ] )
	elseif szType == "Update" then
		for _,line in pairs( varArgs[ 2 ] ) do
			ElemData.List:AddLine( unpack( line ) )
		end
	end
end
Core.Register( "Global/Admin", ReceiveAdmin )


function Admin.Query( varArgs )
	local tab, func = varArgs[ 2 ], {}

	for i = 1, #tab do
		func[ #func + 1 ] = tab[ i ][ 1 ]
		func[ #func + 1 ] = tab[ i ][ 2 ][ 1 ] or -1
		func[ #func + 1 ] = tab[ i ][ 2 ][ 2 ] or -1
	end

	Core.SpawnWindow( { ID = "Query", Dimension = { x = 100, y = 100 }, Args = { Title = tab.Title, Mouse = true, Blur = true, Caption = tab.Caption, Custom = func, Count = #tab, Callback = Admin.ReqAction } } )
end


function Admin.ReqAction( nID, varData, bQuery )
	if not Admin.Verify and not bQuery then return end
	if not nID or nID < 0 then return end

	Core.Send( "Admin", { -1, nID, varData } )
end

function Admin.SendAction( nID, varData )
	if not Admin.Verify then return end
	if not nID or nID < 0 then return end
	
	Core.Send( "Admin", { -2, nID, varData } )
end

function Admin.SpecialAction( nID )
	if nID == 52 then
		local sel = ElemData.Store and ElemData.Store:GetValue( 2 )
		if sel then
			if string.find( sel, "Handled by" ) then
				ElemData.Store:Set( 2, "[Not h" .. string.sub( sel, 3 ) )
			else
				ElemData.Store:Set( 2, "[Handled by " .. LocalPlayer():Name() .. "] " .. sel )
			end
		end
	elseif nID == 53 then
		local sel = ElemData.Store and ElemData.Store:GetValue( 5 )
		if sel and sel != "Console" then
			local s64 = util.SteamIDTo64( sel )
			if s64 == "0" then return end
			
			Core.GetPlayerName( s64, function( uid, name, arg )
				ElemData.Store:Set( 5, name )
				
				if IsValid( ElemData.List ) then
					for _,line in pairs( ElemData.List:GetLines() ) do
						if line:GetValue( 5 ) == sel then
							line:SetColumnText( 5, name )
						end
					end
				end
			end )
		elseif sel == "Console" then
			local content = ElemData.Store:GetValue( 2 )
			local split = string.Explode( "(STEAM_", content )
			local second = string.Explode( ")", split[ 2 ] )
			local steam = "STEAM_" .. second[ 1 ]
			
			Core.GetPlayerName( util.SteamIDTo64( steam ), function( uid, name, arg )
				content = content:gsub( steam, name )
				ElemData.Store:Set( 2, content )
			end )
		end
		
		return true
	elseif nID == 54 then
		Admin.SendAction( nID, { #ElemData.List:GetLines(), Admin.Reports } )
		
		return true
	end
end

function Core.IsAdminAvailable() return Admin.Verify end


local function ButtonCallback( self )
	if self.Close then return Core.RequestClose() end
	if self.Identifier >= 50 and Admin.SpecialAction( self.Identifier ) then return end
	if not ElemData.Store then return end
	
	local data = ElemData.Store:GetValue()
	if not self.Require or (data != "" and data != ElemData.Default) then
		Admin.SendAction( self.Identifier, ElemData.Store:GetValue() )
	else
		Core.Print( "Admin", "You have to select or enter a valid player Steam ID." )
	end
end

local function CreateElement( data, parent, tools )
	local mods, elem = data["Modifications"]
	if data["Type"] == "DTextEntry" then
		elem = tools.Text( parent, mods[ 1 ], mods[ 2 ], mods[ 3 ], mods[ 4 ], { Default = function() return mods[ 5 ] end } )
		elem.NoCopy = true
		
		mods = nil
	else
		elem = vgui.Create( data["Type"], parent )
	end
	
	local sequence = {}
	for func,args in pairs( mods or {} ) do
		if func == "Sequence" then
			sequence = args
		else
			local f = elem[ func ]
			f( elem, unpack( args ) )
		end
	end
	
	for _,seq in pairs( sequence ) do
		local f = elem[ seq[ 1 ] ]
		local d = f( elem, unpack( seq[ 2 ] ) )
		if seq[ 3 ] then
			local q = d[ seq[ 3 ] ]
			q( d, seq[ 4 ] )
		end
	end
	
	if data["Label"] then
		ElemCache[ data["Label"] ] = elem
	end
	
	if data["Type"] == "DListView" then
		elem.OnRowSelected = function( s, row )
			if Admin.Reports then
				ElemData.Store = { Data = s:GetLine( row ), GetValue = function( x, i ) return x.Data:GetValue( i or 1 ) end, Set = function( x, i, s ) x.Data:SetColumnText( i, s ) end }
				SetClipboardText( s:GetLine( row ):GetValue( 2 ) )
			elseif ElemData.Store then
				ElemData.Store:SetText( s:GetLine( row ):GetValue( 2 ) )
			elseif Admin.Logs then
				Admin.SpecialAction( 54 )
			end
		end
		
		ElemData.List = elem
	elseif data["Type"] == "DButton" then
		elem.Identifier = data["Identifier"]
		elem.Require = data["Require"]
		elem.Extra = data["Extra"]
		elem.Close = data["Close"]
		elem.DoClick = ButtonCallback
	end
	
	ElemList[ #ElemList + 1 ] = elem
end

function Admin.SubmitAction( szID, varArgs )
	if szID == "Players" then
		local elem = ElemCache["PlayerList"]
		if not elem then return end
		for _,line in pairs( varArgs ) do
			elem:AddLine( unpack( line ) )
		end
	elseif szID == "Store" then
		ElemData.Store = ElemCache[ varArgs[ 1 ] ]
		ElemData.Default = varArgs[ 2 ]
	end
end

function Admin.GenerateGUI( parent, data, tools )
	parent:Center()
	parent:MakePopup()
	
	ElemList = {}
	
	for i = 1, #data do
		local elemdata = data[ i ]
		CreateElement( elemdata, parent, tools )
	end
end

local CHK, DAT, WRT = 4096
local function ReceiveBinary( l )
	Core.Config.NetReceive = Core.Config.NetReceive + l
	
	local id = net.ReadString()
	if id == "Help" then
		local settings = net.ReadBool()
		local length = net.ReadUInt( 32 )
		
		if length > 0 then
			local data = util.Decompress( net.ReadData( length ) )
			if not data then return Core.Print( "General", "Couldn't load help data" ) end
			
			Core.Trigger( "SetHelp", util.JSONToTable( data ) )
		end
		
		Core.Trigger( "ShowHelp", settings )
	elseif id == "List" then
		local cmd, length = net.ReadString(), net.ReadUInt( 32 )
		local data = util.Decompress( net.ReadData( length ) )
		if not data then return Core.Print( "Notification", "An error occurred while obtaining map list!" ) end
		local tab = util.JSONToTable( data )
		if not tab[ 1 ] or #tab != 3 then return end
		
		tab[ 4 ] = cmd != "" and cmd
		Core.Trigger( "SetMaps", tab )
	elseif id == "Export" then
		SetClipboardText( net.ReadString() )
		Core.Print( "General", "Exported map in JSON format has been set in your clipboard" )
	elseif id == "FullDemo" then
		local name = net.ReadString()
		local json = net.ReadString()
		local length = net.ReadUInt( 32 )
		local path = Core.Config.BasePath .. "demos/"
		
		WRT = path .. name .. ".dat"
		DAT = length
		
		file.CreateDir( path )
		file.Write( path .. name .. ".txt", json or "" )
		file.Write( WRT, "" )
		
		net.Start( "BinaryTransfer" )
		net.WriteUInt( 2, 2 )
		net.SendToServer()
	elseif id == "Demo" then
		if not WRT or not DAT then return end
		local fl = net.ReadUInt( 32 )
		if fl > 0 then
			file.Append( WRT, net.ReadData( fl ) )
		end
		
		if file.Size( WRT, "DATA" ) >= DAT then
			Core.Print( "Admin", "Demo '" .. WRT .. "' has been received and is now viewable!" )
		else
			net.Start( "BinaryTransfer" )
			net.WriteUInt( 2, 2 )
			net.SendToServer()
		end
	elseif id == "Part" then
		if not DAT then return end
		
		local at = net.ReadUInt( 32 )
		local stop = math.Clamp( at + CHK, 1, #DAT )
		local dat = string.sub( DAT, at, stop )
		
		net.Start( "BinaryTransfer" )
		net.WriteUInt( 1, 2 )
		net.WriteUInt( stop, 32 )
		net.WriteUInt( #dat, 32 )
		net.WriteData( dat, #dat )
		net.SendToServer()
	end
end
net.Receive( "BinaryTransfer", ReceiveBinary )

function Core.SubmitAdmin( bin, data )
	DAT = bin
	
	net.Start( "BinaryTransfer" )
	net.WriteUInt( 0, 2 )
	net.WriteUInt( #bin, 32 )
	net.WriteString( data )
	net.SendToServer()
end

local DrawObj = {}
local Min, Max, Round, lp, st, df = math.min, math.max, Core.RoundTo, LocalPlayer, SysTime, true
local DrawMat, DrawBeam = render.SetMaterial, render.DrawBeam

function Core.SetDrawFullZone( b )
	df = not b
end

function Core.DrawCustomZone( obj, b, t, w, c )
	DrawMat( obj.Material )

	DrawBeam( b[ 1 ], b[ 2 ], w, 0, 1, c )
	DrawBeam( b[ 2 ], b[ 3 ], w, 0, 1, c )
	DrawBeam( b[ 3 ], b[ 4 ], w, 0, 1, c )
	DrawBeam( b[ 4 ], b[ 1 ], w, 0, 1, c )
	
	if df then return end
	
	DrawBeam( t[ 1 ], t[ 2 ], w, 0, 1, c )
	DrawBeam( t[ 2 ], t[ 3 ], w, 0, 1, c )
	DrawBeam( t[ 3 ], t[ 4 ], w, 0, 1, c )
	DrawBeam( t[ 4 ], t[ 1 ], w, 0, 1, c )
	
	DrawBeam( b[ 1 ], t[ 1 ], w, 0, 1, c )
	DrawBeam( b[ 2 ], t[ 2 ], w, 0, 1, c )
	DrawBeam( b[ 3 ], t[ 3 ], w, 0, 1, c )
	DrawBeam( b[ 4 ], t[ 4 ], w, 0, 1, c )
end

function Admin.DrawAreaEditor()
	if Admin.Editor and Admin.Editor.Active then
		if not DrawObj.Created then
			DrawObj.Created = true
			DrawObj.Material = Material( Core.Config.MaterialID .. "/zone/lw" )
			DrawObj.DrawBox = Core.DrawCustomZone
		end
		
		local s, e = Admin.Editor.Start, lp():GetPos()
		if not Admin.Editor.NoSnap then
			local n, z = 32
			if lp():KeyDown( IN_SPEED ) then z = true end
			if lp():KeyDown( IN_DUCK ) then n = 16 end
			
			s, e = Round( s, n ), Round( e, n, z )
		end
		
		local m = Vector( Min( s.x, e.x ), Min( s.y, e.y ), Min( s.z, e.z ) )
		local x = Vector( Max( s.x, e.x ), Max( s.y, e.y ), Max( s.z + 128, e.z + 128 ) )
		DrawObj:DrawBox( { Vector( m.x, m.y, m.z ), Vector( m.x, x.y, m.z ), Vector( x.x, x.y, m.z ), Vector( x.x, m.y, m.z ) }, { Vector( m.x, m.y, x.z ), Vector( m.x, x.y, x.z ), Vector( x.x, x.y, x.z ), Vector( x.x, m.y, x.z ) }, 5, Color( 255, 255, 255 ) )
	else
		DrawObj = {}
		hook.Remove( "PostDrawTranslucentRenderables", "PreviewArea" )
	end
end