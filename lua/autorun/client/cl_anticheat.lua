--#selfie - george anti cheat
local playerisreported = false
local runstring = false
local tablesdone = false

local dbgi = _G["debug"]["getinfo"]
local dbuv = _G["debug"]["getupvalue"]
local fr = _G["file"]["Read"]
local ns = _G["net"]["Start"]
local nw = _G["net"]["WriteString"]
local ns2 = _G["net"]["SendToServer"]
local lply = _G["LocalPlayer"]

local rawget = rawget
local sfind = string.find
local pairs = pairs
local type = type
local GCV = GetConVar
local smt = setmetatable
local schar = string.char
local mrand = math.random
local sgsub = string.gsub

mrand()
mrand()
mrand() --getting the pseudorandom to be more random and distributed

local function randomstringpls(l)
	if l < 1 then return nil end -- Check for l < 1
	local s = "" -- Start string
	for i = 1, l do
		s = s .. schar(mrand(32, 126)) -- Generate random number from 32 to 126, turn it into character and add to string
	end
	return s -- Return string
end

local function reportme(loadmsg,sf)
	if playerisreported then return end
	playerisreported = true

	ns("PG_MSG_LOAD")
	nw(loadmsg)
	ns2()
	--[[if(sf) then
		ns("PG_SM_BLESSING")
		nw(string.sub(sf,2))
		nw(fr(string.sub(sf,2),"GAME"))
		ns2()
	end]]--
end

local function runstringov()
	_G['RunString'] = function()
		local source = dbgi(2,"S").source
		reportme("Attempt to use RunString - "..source,source)
	end
	runstring = true
end

local protectzors = {
	"hook",
	"debug"
}

local oa = hook.Add

local function add(hook,s,f)
	local source = dbgi(2,"S").source
	if(string.sub(source,1,11) != "@gamemodes/") then
		reportme("Unwanted Hook on "..hook.." named "..s.." "..source,source)
	end
	oa(hook,s,f)
end

local ore = require

local function req(m)
	local source = dbgi(2,"S").source
	if(string.sub(source,1,11) != "@gamemodes/") then
		reportme(m.. " module required "..source,source)
	end
	ore(m)
end

local function gonindex(t, k)
	return rawget(t, k)
end

local function gonnewindex(t, k, v)
	for _, s in pairs(protectzors) do
		if sfind(k,s) then
			local s = dbgi(3,"S")
			if(s) then
				reportme("Trying to modify protected "..s.." library - "..s.source,s.source)
				break
			else
				reportme("Trying to modify protected "..s.." library")
				break
			end
			return
		end
	end

	rawset(t, k, v)
end

local function metaov()
	_G["hook"]["Add"] = add
	_G["require"] = req
	local mt = {
		__index = function(...) return gonindex(...) end,
		__newindex = function(...)
			gonnewindex(...)
		end,
		__metatable = {}
	}

	tablesdone = true

	local did, err = pcall(smt, _G, mt)
	return not did
end

local function testupvalues()
	local f = randomstringpls(mrand(10,17))
	local d = randomstringpls(mrand(16,20))
	local t = {}
	local b, v, ts, ts2

	t[f] = function(a, b, c)
		return a+b+c
	end

	t[d] = t[f]
	t[f] = function(a, b, c)
		return t[d](a, b, c)
	end

	b, v = debug.getupvalue(t[f], 2)
	ts, ts2 = dbuv(t[f], 2)
	return d != v or b != "d" or ts != b or ts2 != v
end

local checkdebug = {
	"getupvalue",
	"sethook",
	"getlocal",
	"setlocal",
	"gethook",
	"getmetatable",
	"setmetatable",
	"traceback",
	"setfenv",
	"getinfo",
	"setupvalue",
	"getregistry",
	"getfenv",
}

local checkthisout = {
	["hook"] = {
		["Add"] = "@lua/autorun/client/cl_anticheat.lua"
	},
	["file"] = {
		["Read"] = "@lua/includes/extensions/file.lua",
		["Write"] = "@lua/includes/extensions/file.lua",
		["Append"] = "@lua/includes/extensions/file.lua",
		["Exists"] = "=[C]",
		["Find"] = "=[C]",
		["Open"] = "=[C]",
	},
	["sql"] = {
		["Query"] = "=[C]",
		["QueryValue"] = "@lua/includes/util/sql.lua",
	},
	["debug"] = {
		["getupvalue"] = "=[C]",
		["sethook"] = "=[C]",
		["getlocal"] = "=[C]",
		["setlocal"] = "=[C]",
		["gethook"] = "=[C]",
		["getmetatable"] = "=[C]",
		["setmetatable"] = "=[C]",
		["traceback"] = "=[C]",
		["setfenv"] = "=[C]",
		["getinfo"] = "=[C]",
		["setupvalue"] = "=[C]",
		["getregistry"] = "=[C]",
		["getfenv"] = "=[C]",
	},
	["GetConVar"] = "@lua/includes/util.lua",
	["GetConVarNumber"] = "@lua/includes/util.lua",
	["GetConVarString"] = "@lua/includes/util.lua",
	["engineConsoleCommand"] = "@lua/includes/modules/concommand.lua",
	["RunConsoleCommand"] = "=[C]",
}

local function checkstuff()
	for k, s in pairs(checkthisout) do
		local x = {}
		if type(s) == "table" then
			for func, v in pairs(s) do
				if not _G[k] or type(_G[k][func]) != "function" then continue end
				x = dbgi(_G[k][func],"S")

				if sgsub(x.source,[[\]], "") != v then
					reportme("Incorrect source for "..k.."."..func..": "..x.source,x.source)
					break
				end
			end
		elseif type(s) == "string" then
			if type(_G[k]) != "function" then continue end
			x = dbgi(_G[k],"S")

			if sgsub(x.source,[[\]], "") != s then
				reportme("Incorrect source for "..k..": "..x.source,x.source)
				break
			end
		end
	end
end

local icvars = {
	["sv_cheats"] = 0,
	["sv_allowcslua"] = 0,
	["r_drawothermodels"] = 1,
	["host_timescale"] = 1,
	["mat_wireframe"] = 0,
}

local function notathinkhook()
	if not IsValid or not IsValid(lply()) then
		timer.Simple(1, notathinkhook)
		return
	end

	for k, v in pairs(icvars) do
		local d = false
		if tonumber(GCV(k):GetString()) != v then
			reportme("Overridden "..tostring(k))
			d = true
			break
		elseif !d && tonumber(GCV(k):GetString()) != GCV(k):GetInt() then
			reportme("Overridden "..tostring(k))
			d = true
			break
		elseif !d && GCV(k):GetInt() != v then
			reportme("Overridden "..tostring(k))
			d = true
			break
		elseif !d && !GCV(k) then
			reportme("Overridden "..tostring(k))
			d = true
			break
		end
	end

	if type(_G.debug) != "table" then reportme("Modified debug library.") return end

	for _, v in pairs(checkdebug) do
		if type(_G.debug[v]) != "function" then
			reportme("Modified debug library.")
			break
		end
	end

	if testupvalues() then reportme("Modified debug library.") return end

	checkstuff()

	for k,v in pairs(GAMEMODE) do
		if(type(v) == "function") then
			local s = dbgi(v,"S").source
			if(string.sub(s,1,11) != "@gamemodes/") then
				reportme("Overridden functions on GAMEMODE table "..s,s)
				break
			end
		end
	end

	timer.Simple(7,notathinkhook)
end
acthink = notathinkhook

oa("OnGamemodeLoaded",randomstringpls(mrand(10,17)),function()
	runstringov()
	metaov()
	notathinkhook()
end)
