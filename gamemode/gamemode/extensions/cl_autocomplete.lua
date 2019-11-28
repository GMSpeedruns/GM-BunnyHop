local Suggestions, Pointer, LastChange, LastProcess, IsOpen, IsHold = {}, 1, SysTime()
local function HelpAutoFill( str )
	if not Core.GetSettings():ToggleValue( "MISC_CMDSUGGEST" ) then
		IsOpen = nil
		Suggestions = {}
		return
	end
	
	if str != LastProcess then
		LastProcess = str
	else
		return
	end
	
	local prefix = string.sub( str, 1, 1 )
	if prefix == "/" or prefix == "!" then
		local help = Core.ObtainHelp()
		if not help then
			if not AutocompleteHelp then
				AutocompleteHelp = true
				RunConsoleCommand( Core.CVar( "ask_help" ) )
			end
			
			return
		end
		
		Pointer = 1
		Suggestions = {}
		
		local com = string.sub( str, 2, (string.find( str, " " ) or #str + 1) - 1 )
		for _,data in pairs( help ) do
			if string.sub( data[ 2 ][ 1 ], 1, #com ) == string.lower( com ) then
				Suggestions[ #Suggestions + 1 ] = { Cmd = string.sub( str, 1, 1 ) .. data[ 2 ][ 1 ], Usage = data[ 1 ] }
			end
		end
		
		for _,data in pairs( help ) do
			for i,cmd in pairs( data[ 2 ] ) do
				if i == 1 then continue end
				if string.sub( cmd, 1, #com ) == string.lower( com ) then
					Suggestions[ #Suggestions + 1 ] = { Cmd = string.sub( str, 1, 1 ) .. cmd, Usage = data[ 1 ] }
				end
			end
		end
		
		table.SortByMember( Suggestions, "Cmd", function( a, b ) return a < b end )
	else
		Pointer = 1
		Suggestions = {}
	end
end
hook.Add( "ChatTextChanged", "HelpAutoFill", HelpAutoFill )

local function HelpAutoComplete( str )
	if #Suggestions > 0 then
		return Suggestions[ Pointer ].Cmd
	end
end
hook.Add( "OnChatTab", "HelpAutoComplete", HelpAutoComplete )

local function PaintAutoFill()
	if IsOpen then
		local x, y = 30, ScrH() - 175
		surface.SetFont( "ChatFont" )
		
		for i = Pointer, Pointer + 5 do
			local v = Suggestions[ i ]
			if v then
				local sx, sy = surface.GetTextSize( v.Cmd )
				draw.SimpleText( v.Cmd, "ChatFont", x, y, Color( 0, 0, 0, 255 ) )
				draw.SimpleText( " " .. v.Usage or "", "ChatFont", x + sx, y, Color( 0, 0, 0, 255 ) )
				draw.SimpleText( v.Cmd, "ChatFont", x, y, Color( 255, 255, 100, 255 ) )
				draw.SimpleText( " " .. v.Usage or "", "ChatFont", x + sx, y, Color( 255, 255, 255, 255 ) )
				
				y = y + sy
			end
		end
		
		if input.IsKeyDown( KEY_DOWN ) then
			if not IsHold then
				Pointer = Pointer + 1
				IsHold = true
				LastChange = SysTime()
			elseif SysTime() - LastChange > 0.1 then
				Pointer = Pointer + 1
				LastChange = SysTime()
			end
			
			if Pointer > #Suggestions - 5 then
				Pointer = #Suggestions - 5
			end
		elseif input.IsKeyDown( KEY_UP ) then
			if not IsHold then
				Pointer = Pointer - 1
				IsHold = true
				LastChange = SysTime()
			elseif SysTime() - LastChange > 0.1 then
				Pointer = Pointer - 1
				LastChange = SysTime()
			end
			
			if Pointer < 1 then
				Pointer = 1
			end
		else
			IsHold = nil
		end
	end
end
hook.Add( "HUDPaint", "PaintAutoFill", PaintAutoFill )
hook.Add( "StartChat", "HandleChatOpen", function() IsOpen = true end )
hook.Add( "FinishChat", "HandleChatClose", function() IsOpen = nil end )