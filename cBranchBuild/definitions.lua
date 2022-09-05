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

--Load data into tables
local f = io.open("Skincounter.txt", "r")
if f then
	--file already exsists, load from it
	for l in f:lines() do
		local skinName, count, realName, totalCount = string.match(l, "(.*);(.*);(.*);(.*)")

		if skinName then
			sTrack.globalSkinData[skinName] = {count, realName, totalCount}
		else
			--Old record, update
			local LskinName, Lcount, LrealName = string.match(l, "(.*);(.*);(.*)")
			if LskinName then
				sTrack.globalSkinData[LskinName] = {Lcount, LrealName, Lcount}
			end
		end
	end
	f:close()
end
local m = io.open("Mapdata.txt", "r")
if m then
	--file already exsists, load from it
	for l in m:lines() do
		local mapID, timesPlayed, rtv, mapName = string.match(l, "(.*);(.*);(.*);(.*)")

		if mapID then
			sTrack.globalMapData[mapID] = {timesPlayed, rtv, mapName}
		end
	end
	m:close()
end
local p = io.open("Playerdata.txt", "r")
if p then
	--do I really have to explain this to you three times
	for l in p:lines() do
		local pName, mapsPlayed, wins, hits, selfHits, spinned, exploded, squished, second, third, elo, jElo, nElo, eElo, cElo, eloC, jEloC, nEloC, eEloC, cEloC = string.match(l, "(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*)")

		--print(pName)
		if pName then
			--print("in")
			sTrack.globalPlayerData[pName] = {mapsPlayed, wins, hits, selfHits, spinned, exploded, squished, second, third, elo, jElo, nElo, eElo, cElo, eloC, jEloC, nEloC, eEloC, cEloC}
		else
			--Attempt to parse & update old record
			local LpName, LmapsPlayed, Lwins, Lhits, LselfHits, Lspinned, Lexploded, Lsquished, Lsecond, Lthird, Lelo, LjElo, LnElo, LeElo, LcElo = string.match(l, "(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*)")
			if LpName then
				sTrack.globalPlayerData[LpName] = {LmapsPlayed, Lwins, Lhits, LselfHits, Lspinned, Lexploded, Lsquished, Lsecond, Lthird, Lelo, LjElo, LnElo, LeElo, LcElo, Lelo, LjElo, LnElo, LeElo, LcElo}
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
		if pName then
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
		local mapName, time, player, skin, jTime, jPlayer, jSkin, nTime, nPlayer, nSkin = string.match(l, "(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*)")
		if mapName then
			sTrack.globalEasyTimeData[mapName] = {time, player, skin, jTime, jPlayer, jSkin, nTime, nPlayer, nSkin}
		end
		
	end
	t:close()
end

local n = io.open("NormalRecords.txt", "r")
if n then
	--Vanilla/Tech records, juicebox records, Nitro records
	for l in n:lines() do
		local mapName, time, player, skin, jTime, jPlayer, jSkin, nTime, nPlayer, nSkin = string.match(l, "(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*)")
		if mapName then
			sTrack.globalNormalTimeData[mapName] = {time, player, skin, jTime, jPlayer, jSkin, nTime, nPlayer, nSkin}
		end
	end
	n:close()
end

local h = io.open("HardRecords.txt", "r")
if h then
	--Vanilla/Tech records, juicebox records, Nitro records
	for l in h:lines() do
		local mapName, time, player, skin, jTime, jPlayer, jSkin, nTime, nPlayer, nSkin = string.match(l, "(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*)")
		if mapName then
			sTrack.globalHardTimeData[mapName] = {time, player, skin, jTime, jPlayer, jSkin, nTime, nPlayer, nSkin}
		end
	end
	h:close()
end

--You can't pcall functions with parameters unless the function is written inside of that, I guess
local function _saveSkinFunc()
    --{skinID, weightedUse, fullName, totalUse}
	local f = assert(io.open("Skincounter.txt", "w"))
	for key, value in pairs(sTrack.globalSkinData) do
		if key:find(";") then continue end -- sanity check
		f:write(key, ";", value[1], ";", value[2], ";", value[3], "\n")
	end
	f:close()
end

local function _saveMapFunc()
	--{Plays, RTVs, Map Name}
	local f = assert(io.open("Mapdata.txt", "w"))
	for key, value in pairs(sTrack.globalMapData) do
		f:write(key, ";", value[1], ";", value[2], ";", value[3], "\n")
	end
	f:close()
end

local function _savePlayerFunc()
	local f = assert(io.open("Playerdata.txt", "w"))
	--{mapsPlayed, wins, hits, selfHits, spinned, exploded, squished, second, third, elo, jElo, nElo, eElo, cElo, eloC, jEloC, nEloC, eEloC, cEloC}
	for key, value in pairs(sTrack.globalPlayerData) do
		if key:find(";") then continue end -- sanity check
		f:write(key, ";", value[1], ";", value[2], ";", value[3], ";", value[4], ";", value[5], ";", value[6], ";", value[7], ";", value[8], ";", value[9], ";", value[10], ";", value[11], ";", value[12], ";", value[13], ";", value[14], ";", value[15], ";", value[16], ";", value[17], ";", value[18], ";", value[19], "\n")
	end
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
	if gamespeed == 0 then
		f = assert(io.open("EasyRecords.txt", "w"))
		for key, value in pairs(sTrack.globalEasyTimeData) do
			if value[2]:find(";") or value[5]:find(";") or value[8]:find(";") then continue end -- sanity check
			f:write(key, ";", value[1], ";", value[2], ";", value[3], ";", value[4], ";", value[5], ";", value[6], ";", value[7], ";", value[8], ";", value[9], "\n")
		end
	elseif gamespeed == 1 then
		f = assert(io.open("NormalRecords.txt", "w"))
		for key, value in pairs(sTrack.globalNormalTimeData) do
			if value[2]:find(";") or value[5]:find(";") or value[8]:find(";") then continue end -- sanity check
			f:write(key, ";", value[1], ";", value[2], ";", value[3], ";", value[4], ";", value[5], ";", value[6], ";", value[7], ";", value[8], ";", value[9], "\n")
		end
	elseif gamespeed == 2 then
		f = assert(io.open("HardRecords.txt", "w"))
		for key, value in pairs(sTrack.globalHardTimeData) do
			if value[2]:find(";") or value[5]:find(";") or value[8]:find(";") then continue end -- sanity check
			f:write(key, ";", value[1], ";", value[2], ";", value[3], ";", value[4], ";", value[5], ";", value[6], ";", value[7], ";", value[8], ";", value[9], "\n")
		end
	end
	
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
		sTrack.globalPlayerData[name] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 1500, 1500, 1500, 1500, 1500}
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
			