local old = { Normal = 1, SW = 2, HSW = 3, ["W-Only"] = 4, ["A-Only"] = 5, ["D-Only"] = 6, Legit = 7, ["Easy Scroll"] = 8, Stamina = 9, Unreal = 10, Bonus = 11, ["Bonus 2"] = 12, ["Bonus 3"] = 13, Practice = 14 }
local oldsurf = { Normal = 1, SW = 2, HSW = 3, ["W-Only"] = 4, ["A-Only"] = 5, ["D-Only"] = 6, Legit = 7, Backwards = 8, Stamina = 9, Unreal = 10, Bonus = 11, ["Bonus 2"] = 12, ["Bonus 3"] = 13, Practice = 14 }
local new = { Normal = 1, SW = 2, HSW = 3, ["W-Only"] = 4, ["A-Only"] = 5, ["D-Only"] = 6, ["S-Only"] = 7, Legit = 8, ["Easy Scroll"] = 9, Stamina = 10, Unreal = 11, Backwards = 12, ["Low Gravity"] = 13, Bonus = 14 }

local translate = {
	[old["Bonus 3"]] = new["Bonus"] + 2, -- 13 -> 16
	[old["Bonus 2"]] = new["Bonus"] + 1, -- 12 -> 15
	[old["Bonus"]] = new["Bonus"], -- 11 -> 14
	[old["Unreal"]] = new["Unreal"], -- 10 -> 11
	[old["Stamina"]] = new["Stamina"], -- 9 -> 10
	[old["Easy Scroll"]] = new["Easy Scroll"], -- 8 -> 9
	[old["Legit"]] = new["Legit"] -- 7 -> 8
}

local translatesurf = {
	[oldsurf["Bonus 3"]] = new["Bonus"] + 2, -- 13 -> 16
	[oldsurf["Bonus 2"]] = new["Bonus"] + 1, -- 12 -> 15
	[oldsurf["Bonus"]] = new["Bonus"], -- 11 -> 14
	[oldsurf["Unreal"]] = new["Unreal"], -- 10 -> 11
	[oldsurf["Stamina"]] = new["Stamina"], -- 9 -> 10
	[oldsurf["Backwards"]] = new["Backwards"], -- 8 -> 12
	[oldsurf["Legit"]] = new["Legit"] -- 7 -> 8
}

local bas = "bhop/bots/"
function DoTranslate()
	local changes = 0
	local customs = {}
	local files = file.Find( bas .. "*", "DATA" )
	
	for _,f in pairs( files ) do
		local last = f:match( ".*_()" )
		if last then
			local style = tonumber( f:sub( last, #f - 4 ) )
			
			if not style then continue end
			if style > 50 then
				file.Delete( bas .. f )
				print( "Deleted TAS file!", f )
				continue
			end
			
			local trans = translate[ style ]
			if trans then				
				local target = f:sub( 1, last - 1 ) .. trans .. ".txt"
				if file.Exists( bas .. target, "DATA" ) then
					customs[ target ] = "double_" .. target
					local r = file.Read( bas .. target, "DATA" )
					file.Delete( bas .. target )
					file.Write( bas .. customs[ target ], r )
				end
				
				if customs[ f ] then
					f = "double_" .. f
				end
				
				print( _, f, style, trans, target )
				
				local re = file.Read( bas .. f, "DATA" )
				file.Delete( bas .. f )
				file.Write( bas .. target, re )
				
				changes = changes + 1
			end
		end
	end

	print( "Completed renaming " .. changes .. " files!" )
end

local bar = "bhop/bots/revisions/"
function DoTranslateRev()
	local changes = 0
	local customs = {}
	local files = file.Find( bar .. "*", "DATA" )
	
	for _,f in pairs( files ) do
		local ftest = string.find( f, "_v%d+.txt" )
		local last = string.sub( f, 1, ftest - 1 )
		local spl = string.Explode( "_", last )
		local style = tonumber( spl[ #spl ] )
		
		if style then
			local pre = string.find( f, "_" .. style .. string.sub( f, ftest, #f ), 1, true )
			local map = string.sub( f, 1, pre )
			
			if style > 50 or style == old["Unreal"] then
				file.Delete( bar .. f )
				print( "Deleted TAS/Unreal file!", f )
				continue
			end

			local trans = translate[ style ]
			if trans then				
				local target = map .. trans .. string.sub( f, ftest, #f )
				if file.Exists( bar .. target, "DATA" ) then
					customs[ target ] = "double_" .. target
					local r = file.Read( bar .. target, "DATA" )
					file.Delete( bar .. target )
					file.Write( bar .. customs[ target ], r )
				end
				
				if customs[ f ] then
					f = "double_" .. f
				end
				
				print( _, f, style, trans, target )
				
				local re = file.Read( bar .. f, "DATA" )
				file.Delete( bar .. f )
				file.Write( bar .. target, re )
				
				changes = changes + 1
			end
		end
	end
	
	print( "Completed changing " .. changes .. " files!" )
end

function DeleteByStyle( nStyle )
	local changes = 0
	local customs = {}
	local files = file.Find( bas .. "*", "DATA" )
	
	for _,f in pairs( files ) do
		local last = f:match( ".*_()" )
		if last then
			local style = tonumber( f:sub( last, #f - 4 ) )
			
			if not style then continue end
			if style == new["Unreal"] then
				file.Delete( bas .. f )
				print( "Deleted Unreal file!", f )
				changes = changes + 1
				continue
			end
		end
	end

	print( "Completed deleting " .. changes .. " files!" )
end