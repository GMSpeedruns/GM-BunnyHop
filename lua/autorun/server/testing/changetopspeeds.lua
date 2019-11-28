function dofixa()
	-- ONLY FOR BHOP
	
	local c1, c2 = SysTime(), 0
	local query = sql.Query( "SELECT szUID, szMap, nStyle, vData FROM game_times WHERE substr(vData, 1, 2) = '0 '" )
	if query and #query > 0 then
		for i = 1, #query do
			local data = query[ i ]
			if data.vData then
				local remain = string.sub( data.vData, 3 )
				local avg = tonumber( string.sub( remain, 1, string.find( remain, " " ) - 1 ) )
				local top = math.ceil( avg * math.random( 1.1, 1.4 ) )
				local new = top .. " " .. remain
				
				sql.Query( "UPDATE game_times SET vData = '" .. new .. "' WHERE szUID = '" .. data.szUID .. "' AND szMap = '" .. data.szMap .. "' AND nStyle = " .. data.nStyle )
				c2 = c2 + 1
			end
		end
	end
	
	print( c2 .. " out of " .. #query .. " rows updated in " .. math.Round( SysTime() - c1, 5 ) .. " seconds" )
end

function dosurfa()
	local c1, c2 = SysTime(), 0
	local query = sql.Query( "SELECT * FROM game_zones WHERE nType = 0 OR nType = 300 ORDER BY nType ASC" )
	if query and #query > 0 then
		local mem = {}
		for i = 1, #query do
			local data = query[ i ]
			if tonumber( data.nType ) == 0 then
				mem[ data.szMap ] = { vPos1 = data.vPos1, vPos2 = data.vPos2 }
			elseif mem[ data.szMap ] then
				local temp = mem[ data.szMap ]
				if temp.vPos1 != data.vPos1 or temp.vPos2 != data.vPos2 then
					sql.Query( "UPDATE game_zones SET vPos1 = '" .. temp.vPos1 .. "', vPos2 = '" .. temp.vPos2 .. "' WHERE szMap = '" .. data.szMap .. "' AND nType = 300" )
					c2 = c2 + 1
				end
			end
		end
	end
	
	print( c2 .. " out of " .. #query .. " rows updated in " .. math.Round( SysTime() - c1, 5 ) .. " seconds" )
end