rawset(_G, "sTrack", {}) -- Stat Tracker global namespace

sTrack.globalSkinData = {}
sTrack.globalMapData = {}
sTrack.globalPlayerData = {}
sTrack.globalEasyTimeData = {}
sTrack.globalNormalTimeData = {}
sTrack.globalHardTimeData = {}
sTrack.globalPlayerSkinUseData = {}
--This table is only populated during intermission, code wisely.
--sTrack.ksChanges[playerName] = totalChange (numeric)
sTrack.ksChanges = {}

--If I ever want to reduce placeholder data, here this is, but we pretty much use everything now.

--Set up pointers for limiting saved data
--Time record pointers
sTrack.jTimePointer = 4
sTrack.nTimePointer = 7

--[[if CV_FindVar("driftnitro") and CV_FindVar("juicebox") then
	sTrack.jTimePointer = 4
	sTrack.nTimePointer = 7
elseif CV_FindVar("juicebox") then
	sTrack.jTimePointer = 4
elseif CV_FindVar("driftnitro") then
	sTrack.nTimePointer = 4
end]]--

--Pointers for KS
-- 10 = vanilla KS pointer
--elo, jElo, nElo, eElo, cElo
sTrack.jKSPointer = 11
sTrack.nKSPointer = 12
sTrack.eKSPointer = 13
sTrack.cKSPointer = 14
--[[local KSPointer = 11
if CV_FindVar("juicebox") then
	sTrack.jKSPointer = KSPointer
	KSPointer = $ + 1
end
if CV_FindVar("driftnitro") then
	sTrack.nKSPointer = KSPointer
	KSPointer = $ + 1
end
if CV_FindVar("elimination") then
	sTrack.eKSPointer = KSPointer
	KSPointer = $ + 1
end
if CV_FindVar("combi_active") then
	sTrack.cKSPointer = KSPointer
	KSPointer = $ + 1
end
KSPointer = nil]]--

--Load data into tables
--Isolating this into a function to stop the user from loading local files and syncfailing
sTrack.loadData = function()
	--Previously used string.match but that doesn't seem to scale well with a large amount of columns (long processing times)
	--New - gsub to just loop through every character and manually assemble the data row
	local f = io.open("Skincounter.txt", "r")
	if f then
		--file already exsists, load from it
		for l in f:lines() do
			if l ~= '' and l ~= "\n" and l ~= "\r" then
				local holder = ""
				local rowHolder = {}
				local index = 1
				l:gsub(".", function(c)
					if c==';' then
						rowHolder[index] = holder
						holder = ""
						index = index + 1			
					else
						holder = holder..c
					end		
				end)
				rowHolder[index] = tonumber(holder)
				--local skinName, count, realName, totalCount = string.match(l, "(.*);(.*);(.*);(.*)")

				if rowHolder[1] and rowHolder[1] ~= '' and rowHolder[4] then
					sTrack.globalSkinData[rowHolder[1]] = rowHolder[2]..";"..rowHolder[3]..";"..rowHolder[4]
				end
			end
		end
		f:close()
	end
	local m = io.open("Mapdata.txt", "r")
	if m then
		--file already exsists, load from it
		for l in m:lines() do
			if l ~= '' and l ~= "\n" and l ~= "\r" then
				local holder = ""
				local rowHolder = {}
				local index = 1
				l:gsub(".", function(c)
					if c==';' then
						rowHolder[index] = holder
						holder = ""
						index = index + 1			
					else
						holder = holder..c
					end		
				end)
				rowHolder[index] = holder
				--local mapID, timesPlayed, rtv, mapName = string.match(l, "(.*);(.*);(.*);(.*)")

				if rowHolder[1] and rowHolder[1] ~= '' and rowHolder[4] then
					sTrack.globalMapData[rowHolder[1]] = rowHolder[2]..";"..rowHolder[3]..";"..rowHolder[4]
				end
			end
		end
		m:close()
	end
	local p = io.open("Playerdata.txt", "r")
	if p then
		--do I really have to explain this to you three times
		for l in p:lines() do
			if l ~= '' and l ~= "\n" and l ~= "\r" then
				local holder = ""
				local rowHolder = {}
				local index = 1
				l:gsub(".", function(c)
					if c==';' then
						rowHolder[index] = holder
						holder = ""
						index = index + 1			
					else
						holder = holder..c
					end		
				end)
				--Remember the last data point too
				--tonumber scrubs out a possible newline character from the last data point	
				rowHolder[index] = tonumber(holder)
				
				--local pName, mapsPlayed, wins, hits, selfHits, spinned, exploded, squished, second, third, elo, jElo, nElo, eElo, cElo, eloC, jEloC, nEloC, eEloC, cEloC = string.match(l, "(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*)")
				--print(pName)
				if rowHolder[1] and rowHolder[1] ~= '' and rowHolder[20] then
					sTrack.globalPlayerData[rowHolder[1]] = rowHolder[2]..";"..rowHolder[3]..";"..rowHolder[4]..";"..rowHolder[5]..";"..rowHolder[6]..";"..rowHolder[7]..";"..rowHolder[8]..";"..rowHolder[9]..";"..rowHolder[10]..";"..rowHolder[11]..";"..rowHolder[12]..";"..rowHolder[13]..";"..rowHolder[14]..";"..rowHolder[15]..";"..rowHolder[16]..";"..rowHolder[17]..";"..rowHolder[18]..";"..rowHolder[19]..";"..rowHolder[20]
				end
			end
		end
		p:close()
	end

	local q = io.open("pSkinUse.txt", "r")
	if q then
		--Skin usage per player
		--Data line format PlayerName;SkinName/Use(as number)|SkinName2/Use....
		--Converted data format
			--globalPlayerSkinUseData["PlayerName"] = Table object
			--globalPlayerSkinUseData["PlayerName"]["SkinName"] = Skin's use count by this player
		for l in q:lines() do
			local pName, rawData = string.match(l, "(.*);(.*)")
			if pName and pName ~= '' then
				local tempTable = {}
				for str in string.gmatch(rawData, "([^|]+)") do
					--Needs 2 splits
					local keyV = ""
					for str2 in string.gmatch(str, "([^/]+)") do
						if keyV == "" then
							keyV = str2
						else
							tempTable[keyV] = str2
							keyV = ""
						end
					end
				end
				
				sTrack.globalPlayerSkinUseData[pName] = tempTable
			end
		end
		q:close()
	end

	local t = io.open("EasyRecords.txt", "r")
	if t then
		--Vanilla/Tech records, juicebox records, Nitro records
		for l in t:lines() do
			if l ~= '' and l ~= "\n" and l ~= "\r" then
				local holder = ""
				local rowHolder = {}
				local index = 1
				l:gsub(".", function(c)
					if c==';' then
						rowHolder[index] = holder
						holder = ""
						index = index + 1			
					else
						holder = holder..c
					end		
				end)
				rowHolder[index] = holder
				--local mapName, time, player, skin, jTime, jPlayer, jSkin, nTime, nPlayer, nSkin = string.match(l, "(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*)")
				if rowHolder[1] and rowHolder[1] ~= '' and rowHolder[10] then
					sTrack.globalEasyTimeData[rowHolder[1]] = rowHolder[2]..";"..rowHolder[3]..";"..rowHolder[4]..";"..rowHolder[5]..";"..rowHolder[6]..";"..rowHolder[7]..";"..rowHolder[8]..";"..rowHolder[9]..";"..rowHolder[10]
				end
			end
		end
		t:close()
	end

	local n = io.open("NormalRecords.txt", "r")
	if n then
		--Vanilla/Tech records, juicebox records, Nitro records
		for l in n:lines() do
			if l ~= '' and l ~= "\n" and l ~= "\r" then
				local holder = ""
				local rowHolder = {}
				local index = 1
				l:gsub(".", function(c)
					if c==';' then
						rowHolder[index] = holder
						holder = ""
						index = index + 1			
					else
						holder = holder..c
					end		
				end)
				rowHolder[index] = holder
				--local mapName, time, player, skin, jTime, jPlayer, jSkin, nTime, nPlayer, nSkin = string.match(l, "(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*)")
				if rowHolder[1] and rowHolder[1] ~= '' and rowHolder[10] then
					sTrack.globalNormalTimeData[rowHolder[1]] = rowHolder[2]..";"..rowHolder[3]..";"..rowHolder[4]..";"..rowHolder[5]..";"..rowHolder[6]..";"..rowHolder[7]..";"..rowHolder[8]..";"..rowHolder[9]..";"..rowHolder[10]
				end
			end
		end
		n:close()
	end

	local h = io.open("HardRecords.txt", "r")
	if h then
		--Vanilla/Tech records, juicebox records, Nitro records
		for l in h:lines() do
			if l ~= '' and l ~= "\n" and l ~= "\r" then
				local holder = ""
				local rowHolder = {}
				local index = 1
				l:gsub(".", function(c)
					if c==';' then
						rowHolder[index] = holder
						holder = ""
						index = index + 1			
					else
						holder = holder..c
					end		
				end)
				rowHolder[index] = holder
				--local mapName, time, player, skin, jTime, jPlayer, jSkin, nTime, nPlayer, nSkin = string.match(l, "(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*)")
				if rowHolder[1] and rowHolder[1] ~= '' and rowHolder[10] then
					sTrack.globalHardTimeData[rowHolder[1]] = rowHolder[2]..";"..rowHolder[3]..";"..rowHolder[4]..";"..rowHolder[5]..";"..rowHolder[6]..";"..rowHolder[7]..";"..rowHolder[8]..";"..rowHolder[9]..";"..rowHolder[10]
				end
			end
		end
		h:close()
	end
end

--You can't pcall functions with parameters unless the function is written inside of that, I guess
local function _saveSkinFunc()
    --{skinID, weightedUse, fullName, totalUse}
	local f = assert(io.open("Skincounter.txt", "w+"))
	local dataString = ""
	for key, value in pairs(sTrack.globalSkinData) do
		if key:find(";") then continue end -- sanity check
		dataString = $..key..";"..value.."\n"
		--f:write(key, ";", value[1], ";", value[2], ";", value[3], "\n")
	end
	f:write(dataString)
	f:close()
end

local function _saveMapFunc()
	--{Plays, RTVs, Map Name}
	local f = assert(io.open("Mapdata.txt", "w+"))
	local dataString = ""
	for key, value in pairs(sTrack.globalMapData) do
		dataString = $..key..";"..value.."\n"
		--f:write(key, ";", value[1], ";", value[2], ";", value[3], "\n")
	end
	f:write(dataString)
	f:close()
end

local function _savePlayerFunc()
	local f = assert(io.open("Playerdata.txt", "w+"))
	--{mapsPlayed, wins, hits, selfHits, spinned, exploded, squished, second, third, elo, jElo, nElo, eElo, cElo}
	--Test to see if assembling the string first, and THEN writing to file works faster
	local dataString = ""
	for key, value in pairs(sTrack.globalPlayerData) do
		if key:find(";") then continue end -- sanity check
		dataString = $..key..";"..value.."\n"
		--f:write(key, ";", value[1], ";", value[2], ";", value[3], ";", value[4], ";", value[5], ";", value[6], ";", value[7], ";", value[8], ";", value[9], ";", value[10], ";", value[11], ";", value[12], ";", value[13], ";", value[14], "\n")
	end
	f:write(dataString)
	f:close()
end

local function _savePSkinUseFunc()
	--{player, {SkinData}}
	--SkinData is reformatted to be stored as plaintext
	local f = assert(io.open("pSkinUse.txt", "w"))
	for key, value in pairs(sTrack.globalPlayerSkinUseData) do
		if key:find(";") then continue end -- no no no no no
		local assembledString = ""
		for key2, value2 in pairs(value) do
			if key2:find("/") or key2:find("|") then continue end -- Can't let seperators into the string, sorry.
		    if assembledString ~= "" then assembledString = assembledString .. "|" end
		    assembledString = assembledString .. key2 .. "/" .. value2
		end
		f:write(key, ";", assembledString, "\n")
	end
	f:close()
end

local function _saveTimeFunc()
	--{time, player, skin, jTime, jPlayer, jSkin, nTime, nPlayer, nSkin}
	--local f = assert(io.open("Timerecords.txt", "w"))
	local f = nil
	local dataString = ""
	if gamespeed == 0 then
		f = assert(io.open("EasyRecords.txt", "w+"))
		for key, value in pairs(sTrack.globalEasyTimeData) do
			--f:write(key, ";", value[1], ";", value[2], ";", value[3], ";", value[4], ";", value[5], ";", value[6], ";", value[7], ";", value[8], ";", value[9], "\n")
			dataString = $..key..";"..value.."\n"
		end
	elseif gamespeed == 1 then
		f = assert(io.open("NormalRecords.txt", "w+"))
		for key, value in pairs(sTrack.globalNormalTimeData) do
			--f:write(key, ";", value[1], ";", value[2], ";", value[3], ";", value[4], ";", value[5], ";", value[6], ";", value[7], ";", value[8], ";", value[9], "\n")
			dataString = $..key..";"..value.."\n"
		end
	elseif gamespeed == 2 then
		f = assert(io.open("HardRecords.txt", "w+"))
		for key, value in pairs(sTrack.globalHardTimeData) do
			--f:write(key, ";", value[1], ";", value[2], ";", value[3], ";", value[4], ";", value[5], ";", value[6], ";", value[7], ";", value[8], ";", value[9], "\n")
			dataString = $..key..";"..value.."\n"
		end
	end
	f:write(dataString)
	f:close()
end

--Global functions
sTrack.saveFiles = function(whatToSave)
	if consoleplayer ~= server then return end

	if whatToSave == "Skin" then
		--print('Saving skincounter data...')
		if not pcall(_saveSkinFunc) then
			print("Failed to save skin file!")
		end
		if not pcall(_savePSkinUseFunc) then
			print("Failed to save player skin use file!")
		end
	elseif whatToSave == "Map" then	
		--print('Saving map data...')
		if not pcall(_saveMapFunc) then
			print("Failed to save map file!")
		end
	elseif whatToSave == "Player" then
		--print('Saving player data...')
		if not pcall(_savePlayerFunc) then
			print("Failed to save player file!")
		end
	elseif whatToSave == "Time" then
		--print('Saving time data...')
		if not pcall(_saveTimeFunc) then
			print("Failed to save time file!")
		end
	end
end

sTrack.checkNilPlayer = function(name)
	--Cleaner to just throw this here since I have to do it so much
	if sTrack.globalPlayerData[name] == nil then
		sTrack.globalPlayerData[name] = "0;0;0;0;0;0;0;0;0;1500;1500;1500;1500;1500;1500;1500;1500;1500;1500"
	end
end

--0 Vanilla/Tech, 1 Juicebox, 2 Nitro
sTrack.findCurrentMode = function()
	if CV_FindVar("driftnitro") and CV_FindVar("driftnitro").value == 1 then
		return 2
	end
	local juiceboxValue = 0
	if CV_FindVar("juicebox") then
		juiceboxValue = CV_FindVar("juicebox").value
	end
	if CV_FindVar("techonly") and CV_FindVar("techonly").value == 1 then
		--If techonly = 1 then consider juicebox as "off" for records
		juiceboxValue = 0
	end
	return juiceboxValue
end

sTrack.getModeIndex = function()
	--returns a pointer to the current mode's KS
	--bElo 13, eElo 14, cElo 15
	local gameModeIndex = 10
	if CV_FindVar("driftnitro") and CV_FindVar("driftnitro").value == 1 then
		gameModeIndex = 12
	elseif CV_FindVar("juicebox") and CV_FindVar("juicebox").value == 1 then
		if CV_FindVar("techonly") and CV_FindVar("techonly").value == 1 then
			gameModeIndex = 10
		else
			gameModeIndex = 11
		end				
	end
	
	--These modes override the above modes
	if CV_FindVar("elimination") and CV_FindVar("elimination").value == 1 then
		gameModeIndex = 13
	elseif CV_FindVar("combi_active") and CV_FindVar("combi_active").value == 1 then
		gameModeIndex = 14
	end
	return gameModeIndex
end

sTrack.isTimeSupportedMode = function(pOrder)
	--Check for gamemodes that mess with the timer
	if G_BattleGametype() then
		return false
	end
	
	--Friendmod
	if CV_FindVar("fr_enabled") and CV_FindVar("fr_enabled").value == 1 then
		return false
	end
	
	if CV_FindVar("combi_active") and CV_FindVar("combi_active").value == 1 then
		return false
	end
	
	if CV_FindVar("frontrun_enabled") and CV_FindVar("frontrun_enabled").value == 1 then
		return false
	end
	
	if CV_FindVar("elimination") and CV_FindVar("elimination").value == 1 then
		return false
	end
	
	--Freeplay gets boots every item.....that's not quite fair for a multiplayer record now is it
	local foundP = 0
	for k, v in pairs(pOrder)
		foundP = $ + 1
		if foundP > 1 then
			return true
		end
	end
	if foundP == 1 then
		return false
	end
	
	return true
end

sTrack.isKSSupportedMode = function()
	--These are things that aren't supported with the current position calculation
	if G_BattleGametype() then
		return false
	end
	
	--Friendmod
	if CV_FindVar("fr_enabled") and CV_FindVar("fr_enabled").value == 1 then
		return false
	end
	
	if CV_FindVar("frontrun_enabled") and CV_FindVar("frontrun_enabled").value == 1 then
		return false
	end
	
	return true
end

--Changes realtime to a time string
sTrack.buildTimeString = function(x)
	if x == nil or x == 20000 then return "N/A" end
	return ""..string.format("%02d", G_TicsToMinutes(x)).."' "..string.format("%02d", G_TicsToSeconds(x))..'" '..string.format("%02d", G_TicsToCentiseconds(x))
end

--Same but each digit in table format for HUD record display
sTrack.buildTimeStringTable = function(x)
	if x == nil or x == 20000 then return nil end
	return {string.sub(string.format("%02d", G_TicsToMinutes(x)), 1, 1), string.sub(string.format("%02d", G_TicsToMinutes(x)), 2, 2), string.sub(string.format("%02d", G_TicsToSeconds(x)), 1, 1), string.sub(string.format("%02d", G_TicsToSeconds(x)), 2, 2), string.sub(string.format("%02d", G_TicsToCentiseconds(x)), 1, 1), string.sub(string.format("%02d", G_TicsToCentiseconds(x)), 2, 2)}
end

--Helper function for sorting data in console commands
sTrack.spairs = function(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

--Takes Map ID (with letters) and converts it into full numeric for internal use
sTrack.convertMapToInt = function(mapID)
	--Just in case scrubbing
	mapID = string.gsub(tostring(mapID), "map", "")
	mapID = string.gsub(tostring(mapID), "MAP", "")
	--If there's no letters in the ID then we don't need to do anything
	if tonumber(mapID) ~= nil then
		return mapID
	end
	--Too long/short to be a valid map ID at this point
	if #mapID > 2 or #mapID < 2 then
		return -1
	end
	
	--Char in C++ converts to int, lua doesn't have that luxury, so...
	local conDig = {
		['a'] = 0, ['A'] = 0,
		['b'] = 1, ['B'] = 1,
		['c'] = 2, ['C'] = 2,
		['d'] = 3, ['D'] = 3,
		['e'] = 4, ['E'] = 4,
		['f'] = 5, ['F'] = 5,
		['g'] = 6, ['G'] = 6,
		['h'] = 7, ['H'] = 7,
		['i'] = 8, ['I'] = 8,
		['j'] = 9, ['J'] = 9,
		['k'] = 10, ['K'] = 10,
		['l'] = 11, ['L'] = 11,
		['m'] = 12, ['M'] = 12,
		['n'] = 13, ['N'] = 13,
		['o'] = 14, ['O'] = 14,
		['p'] = 15, ['P'] = 15,
		['q'] = 16, ['Q'] = 16,
		['r'] = 17, ['R'] = 17,
		['s'] = 18, ['S'] = 18,
		['t'] = 19, ['T'] = 19,
		['u'] = 20, ['U'] = 20,
		['v'] = 21, ['V'] = 21,
		['w'] = 22, ['W'] = 22,
		['x'] = 23, ['X'] = 23,
		['y'] = 24, ['Y'] = 24,
		['z'] = 25, ['Z'] = 25,
	}
	--Letters in digit 2 are conDig[] + 10
	local Digit1 = 0
	local Digit2 = 0
	for i = 1, #mapID do
		local c = mapID:sub(i, i)
		if tonumber(c) ~= nil then
			if i == 1 then
				Digit1 = c
			else
				Digit2 = c
			end
		else
			if conDig[tostring(c)] == nil then
				--Invalid character
				return -1
			end
			if i == 1 then
				Digit1 = conDig[tostring(c)]
			else
				Digit2 = conDig[tostring(c)] + 10
			end
		end
	end
	return ((36 * Digit1 + Digit2) + 100)
end

--Turns a data string into a table for temporary use
sTrack.stringSplit = function(input)
	local holder = ""
	local rowHolder = {}
	local index = 1
	input:gsub(".", function(c)
		if c==';' then
			rowHolder[index] = holder
			holder = ""
			index = index + 1			
		else
			holder = holder..c
		end		
	end)
	rowHolder[index] = holder
	
	return rowHolder
end

--Turns a temporary table back into a data string
sTrack.stringCombine = function(input)
	if input == nil then return nil end
	local dataString = ""
	for k, v in pairs(input)
		if dataString == "" then
			dataString = $..v
		else
			dataString = $..";"..v
		end		
	end
	
	return dataString
end

--Creates a new placeholder time record
--(there's pointers here on public version, but not in custom)
sTrack.buildPlaceholderRecord = function()
	return "99999;p;h;99999;p;h;99999;p;h"
end
			