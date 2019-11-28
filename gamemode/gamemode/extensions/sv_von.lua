--[[	vON 1.3.4
	Copyright 2012-2014 Alexandru-Mihai Maftei
					aka Vercas
	GitHub Repository:
		https://github.com/vercas/vON
	You may use this for any purpose as long as:
	-	You don't remove this copyright notice.
	-	You don't claim this to be your own.
	-	You properly credit the author (Vercas) if you publish your work based on (and/or using) this.
	If you modify the code for any purpose, the above obligations still apply.
	If you make any interesting modifications, try forking the GitHub repository instead.
	Instead of copying this code over for sharing, rather use the link:
		https://github.com/vercas/vON/blob/master/von.lua
	The author may not be held responsible for any damage or losses directly or indirectly caused by
	the use of vON.
	If you disagree with the above, don't use the code.
-----------------------------------------------------------------------------------------------------------------------------
	
	Thanks to the following people for their contribution:
		-	Divran						Suggested improvements for making the code quicker.
										Suggested an excellent new way of deserializing strings.
										Lead me to finding an extreme flaw in string parsing.
		-	pennerlord					Provided some performance tests to help me improve the code.
		-	Chessnut					Reported bug with handling of nil values when deserializing array components.
		-	People who contributed on the GitHub repository by reporting bugs, posting fixes, etc.
-----------------------------------------------------------------------------------------------------------------------------
--]]

local _deserialize, _serialize, _d_meta, _s_meta, d_findVariable, s_anyVariable
local sub, gsub, find, concat, error, tonumber, tostring, type, next = string.sub, string.gsub, string.find, table.concat, error, tonumber, tostring, type, next

function d_findVariable(s, i, len, lastType, jobstate)
	local i, c, typeRead, val = i or 1
	while true do
		if i > len then
			error("vON: Reached end of string, cannot form proper variable.")
		end
		
		c = sub(s, i, i)
		
		if typeRead then
			val, i = _deserialize[lastType](s, i, len, false, jobstate)
			return val, i, lastType
		elseif c == "@" then
			return nil, i, lastType
		elseif c == "$" then
			lastType = "table_reference"
			typeRead = true
		elseif c == "n" then
			lastType = "number"
			typeRead = true
		elseif c == "b" then
			lastType = "boolean"
			typeRead = true
		elseif c == "'" then
			lastType = "string"
			typeRead = true
		elseif c == "\"" then
			lastType = "oldstring"
			typeRead = true
		elseif c == "{" then
			lastType = "table"
			typeRead = true
		elseif lastType then
			val, i = _deserialize[lastType](s, i, len, false, jobstate)
			return val, i, lastType
		else
			error("vON: Malformed data... Can't find a proper type definition. Char#" .. i .. ":" .. c)
		end
		
		i = i + 1
	end
end

function s_anyVariable(data, lastType, isNumeric, isKey, isLast, jobstate)
	local tp = type(data)

	if jobstate[1] and jobstate[2][data] then
		tp = "table_reference"
	end
	
	if lastType ~= tp then
		lastType = tp

		if _serialize[lastType] then
			return _serialize[lastType](data, true, isNumeric, isKey, isLast, false, jobstate), lastType
		else
			error("vON: No serializer defined for type \"" .. lastType .. "\"!")
		end
	end
	
	return _serialize[lastType](data, false, isNumeric, isKey, isLast, false, jobstate), lastType
end

_deserialize = {
	["table"] = function(s, i, len, unnecessaryEnd, jobstate)
		local ret, numeric, i, c, lastType, val, ind, expectValue, key = {}, true, i or 1, nil, nil, nil, 1
		if sub(s, i, i) == "#" then
			local e = find(s, "#", i + 2, true)

			if e then
				local id = tonumber(sub(s, i + 1, e - 1))

				if id then
					if jobstate[1][id] and not jobstate[2] then
						error("vON: There already is a table of reference #" .. id .. "! Missing an option maybe?")
					end

					jobstate[1][id] = ret

					i = e + 1
				else
					error("vON: Malformed table! Reference ID starting at char #" .. i .. " doesn't contain a number!")
				end
			else
				error("vON: Malformed table! Cannot find end of reference ID start at char #" .. i .. "!")
			end
		end
		
		while true do
			if i > len then
				if unnecessaryEnd then
					return ret, i
				else
					error("vON: Reached end of string, incomplete table definition.")
				end
			end
			
			c = sub(s, i, i)
			
			if c == "}" then
				return ret, i
			elseif c == "~" then
				numeric = false
			elseif c == ";" then
			elseif numeric then
				val, i, lastType = d_findVariable(s, i, len, lastType, jobstate)
				ret[ind] = val
				ind = ind + 1
			else
				if expectValue then
					val, i, lastType = d_findVariable(s, i, len, lastType, jobstate)
					ret[key] = val
					expectValue, key = false, nil
				elseif c == ":" then
					expectValue = true
				elseif key then
					error("vON: Malformed table... Two keys declared successively? Char#" .. i .. ":" .. c)
				else
					key, i, lastType = d_findVariable(s, i, len, lastType, jobstate)
				end
			end

			i = i + 1
		end

		return nil, i
	end,

	["table_reference"] = function(s, i, len, unnecessaryEnd, jobstate)
		local i, a = i or 1
		a = find(s, "[;:}~]", i)

		if a then
			local n = tonumber(sub(s, i, a - 1))

			if n then
				return jobstate[1][n] or error("vON: Table reference does not point to a (yet) known table!"), a - 1
			else
				error("vON: Table reference definition does not contain a valid number!")
			end
		end

		error("vON: Number definition started... Found no end.")
	end,
	
	["number"] = function(s, i, len, unnecessaryEnd, jobstate)
		local i, a = i or 1
		a = find(s, "[;:}~]", i)

		if a then
			return tonumber(sub(s, i, a - 1)) or error("vON: Number definition does not contain a valid number!"), a - 1
		end

		error("vON: Number definition started... Found no end.")
	end,

	["boolean"] = function(s, i, len, unnecessaryEnd, jobstate)
		local c = sub(s,i,i)
		if c == "1" then
			return true, i
		elseif c == "0" then
			return false, i
		end

		error("vON: Invalid value on boolean type... Char#" .. i .. ": " .. c)
	end,
	
	["oldstring"] = function(s, i, len, unnecessaryEnd, jobstate)
		local res, i, a = "", i or 1
		while true do
			a = find(s, "\"", i, true)

			if a then
				if sub(s, a - 1, a - 1) == "\\" then
					res = res .. sub(s, i, a - 2) .. "\""
					i = a + 1
				else
					return res .. sub(s, i, a - 2), a
				end
			else
				error("vON: Old string definition started... Found no end.")
			end
		end
	end,

	["string"] = function(s, i, len, unnecessaryEnd, jobstate)
		local res, i, a = "", i or 1
		while true do
			a = find(s, "\"", i, true)

			if a then
				if sub(s, a - 1, a - 1) == "\\" then
					res = res .. sub(s, i, a - 2) .. "\""
					i = a + 1
				else
					return res .. sub(s, i, a - 1), a
				end
			else
				error("vON: String definition started... Found no end.")
			end
		end
	end,
}



_serialize = {
	["table"] = function(data, mustInitiate, isNumeric, isKey, isLast, first, jobstate)
		local result, keyvals, len, keyvalsLen, keyvalsProgress, val, lastType, newIndent, indentString = {}, {}, #data, 0, 0
		for k, v in next, data do
			if type(k) ~= "number" or k < 1 or k > len or (k % 1 ~= 0) then
				keyvals[#keyvals + 1] = k
			end
		end

		keyvalsLen = #keyvals

		if not first then
			result[#result + 1] = "{"
		end

		if jobstate[1] and jobstate[1][data] then
			if jobstate[2][data] then
				error("vON: Table #" .. jobstate[1][data] .. " written twice..?")
			end

			result[#result + 1] = "#"
			result[#result + 1] = jobstate[1][data]
			result[#result + 1] = "#"

			jobstate[2][data] = true
		end

		if len > 0 then
			for i = 1, len do
				val, lastType = s_anyVariable(data[i], lastType, true, false, i == len and not first, jobstate)
				result[#result + 1] = val
			end
		end
		
		if keyvalsLen > 0 then
			result[#result + 1] = "~"

			for _i = 1, keyvalsLen do
				keyvalsProgress = keyvalsProgress + 1
				val, lastType = s_anyVariable(keyvals[_i], lastType, false, true, false, jobstate)
				result[#result + 1] = val..":"
				val, lastType = s_anyVariable(data[keyvals[_i]], lastType, false, false, keyvalsProgress == keyvalsLen and not first, jobstate)
				result[#result + 1] = val
			end
		end

		if not first then
			result[#result + 1] = "}"
		end

		return concat(result)
	end,

	["table_reference"] = function(data, mustInitiate, isNumeric, isKey, isLast, first, jobstate)
		data = jobstate[1][data]
		
		if mustInitiate then
			if isKey or isLast then
				return "$"..data
			else
				return "$"..data..";"
			end
		end

		if isKey or isLast then
			return data
		else
			return data..";"
		end
	end,

	["number"] = function(data, mustInitiate, isNumeric, isKey, isLast, first, jobstate)
		if mustInitiate then
			if isKey or isLast then
				return "n"..data
			else
				return "n"..data..";"
			end
		end

		if isKey or isLast then
			return data
		else
			return data..";"
		end
	end,

	["string"] = function(data, mustInitiate, isNumeric, isKey, isLast, first, jobstate)
		if sub(data, #data, #data) == "\\" then
			return "\"" .. gsub(data, "\"", "\\\"") .. "v\""
		end

		return "'" .. gsub(data, "\"", "\\\"") .. "\""
	end,

	["boolean"] = function(data, mustInitiate, isNumeric, isKey, isLast, first, jobstate)
		if mustInitiate then
			if data then
				return "b1"
			else
				return "b0"
			end
		end

		if data then
			return "1"
		else
			return "0"
		end
	end,

	["nil"] = function(data, mustInitiate, isNumeric, isKey, isLast, first, jobstate)
		return "@"
	end,
}

local function checkTableForRecursion(tab, checked, assoc)
	local id = checked.ID

	if not checked[tab] and not assoc[tab] then
		assoc[tab] = id
		checked.ID = id + 1
	else
		checked[tab] = true
	end

	for k, v in pairs(tab) do
		if type(k) == "table" and not checked[k] then
			checkTableForRecursion(k, checked, assoc)
		end
		
		if type(v) == "table" and not checked[v] then
			checkTableForRecursion(v, checked, assoc)
		end
	end
end


local _s_table = _serialize.table
local _d_table = _deserialize.table

_d_meta = {
	__call = function(self, str, allowIdRewriting)
		if type(str) == "string" then
			return _d_table(str, nil, #str, true, {{}, allowIdRewriting})
		end

		error("vON: You must deserialize a string, not a "..type(str))
	end
}
_s_meta = {
	__call = function(self, data, checkRecursion)
		if type(data) == "table" then
			if checkRecursion then
				local assoc, checked = {}, {ID = 1}

				checkTableForRecursion(data, checked, assoc)

				return _s_table(data, nil, nil, nil, nil, true, {assoc, {}})
			end

			return _s_table(data, nil, nil, nil, nil, true, {false})
		end

		error("vON: You must serialize a table, not a "..type(data))
	end
}

von = {
	version = "1.3.4",
	versionNumber = 1003004,

	deserialize = setmetatable(_deserialize,_d_meta),
	serialize = setmetatable(_serialize,_s_meta)
}

return von