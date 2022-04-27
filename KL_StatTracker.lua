--StatTracker
--Tracks and filesaves Skin usage, map usage, and player data
--Note: add sep=; at the top of saved txt files in order to open in Excel as a CSV
--	1.3 - Adds KartScore(ELO) system
--  1.4 - Tracks skin usage by player

local globalSkinData = {}
local globalMapData = {}
local globalPlayerData = {}
local globalTimeData = {}
local globalPlayerSkinUseData = {}

local f = io.open("Skincounter.txt", "r")
if f then
	--file already exsists, load from it
	--print('Loading skincounter data...')
	for l in f:lines() do
		local skinName, count, realName = string.match(l, "(.*);(.*);(.*)")

		if skinName then
			globalSkinData[skinName] = {count, realName}
		else
			--Old record, update
			local LskinName, Lcount = string.match(l, "(.*);(.*)")
			if LskinName and skins[LskinName] then
				globalSkinData[LskinName] = {Lcount, skins[LskinName].realname}
			elseif LskinName then
				--possible deleted skin
				globalSkinData[LskinName] = {Lcount, "Removed Skin"}
			end
		end
	end
	f:close()
end
local m = io.open("Mapdata.txt", "r")
if m then
	--file already exsists, load from it
	--print('Loading map data...')
	for l in m:lines() do
		local mapID, timesPlayed, rtv, mapName = string.match(l, "(.*);(.*);(.*);(.*)")

		if mapID then
			globalMapData[mapID] = {timesPlayed, rtv, mapName}
		else
			--Attempt to parse & update old record
			local LmapID, LtimesPlayed, Lrtv = string.match(l, "(.*);(.*);(.*)")
			if LmapID and mapheaderinfo[tostring(LmapID)] then
				globalMapData[LmapID] = {LtimesPlayed, Lrtv, mapheaderinfo[tostring(LmapID)].lvlttl}
			elseif LmapID then
				--Old record and no longer on server - will be deleted in maintenance
				globalMapData[LmapID] = {LtimesPlayed, Lrtv, "I am dead"}
			end
		end
	end
	m:close()
end
local p = io.open("Playerdata.txt", "r")
if p then
	--do I really have to explain this to you three times
	--print('Loading player data...')
	for l in p:lines() do
		local pName, mapsPlayed, wins, hits, selfHits, spinned, exploded, squished, second, third, elo, jElo, nElo = string.match(l, "(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*)")

		--print(pName)
		if pName then
			--print("in")
			globalPlayerData[pName] = {mapsPlayed, wins, hits, selfHits, spinned, exploded, squished, second, third, elo, jElo, nElo}
		else
			--Assume this is an older record & attempt to update it
			local LpName, LmapsPlayed, Lwins, Lhits, LselfHits, Lspinned, Lexploded, Lsquished = string.match(l, "(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*)")
			if LpName then
				globalPlayerData[LpName] = {LmapsPlayed, Lwins, Lhits, LselfHits, Lspinned, Lexploded, Lsquished, 0, 0, 1500, 1500, 1500}
			end		
		end
	end
	p:close()
end
local f = io.open("Timerecords.txt", "r")
if f then
	--Vanilla/Tech records, juicebox records, Nitro records
	--print('Loading time record data...')
	for l in f:lines() do
		local mapName, time, player, skin, jTime, jPlayer, jSkin, nTime, nPlayer, nSkin = string.match(l, "(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*)")
		if mapName then
			globalTimeData[mapName] = {time, player, skin, jTime, jPlayer, jSkin, nTime, nPlayer, nSkin}
		end
	end
	f:close()
end
--https://stackoverflow.com/questions/1426954/split-string-in-lua
local f = io.open("pSkinUse.txt", "r")
if f then
	--Skin usage per player
	--Data line format PlayerName;SkinName/Use(as number)|SkinName2/Use....
	--Converted data format
		--globalPlayerSkinUseData["PlayerName"] = Table object
		--globalPlayerSkinUseData["PlayerName"]["SkinName"] = Skin's use count by this player
	for l in f:lines() do
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
			
			globalPlayerSkinUseData[pName] = tempTable
		end
	end
	f:close()
end

--Todo - reformat the above data for file saving
--Data line format PlayerName;SkinName/Use(as number)|SkinName2/Use....

--You can't pcall functions with parameters unless the function is written inside of that, I guess
local function _saveSkinFunc()
	local f = assert(io.open("Skincounter.txt", "w"))
	for key, value in pairs(globalSkinData) do
		if key:find(";") then continue end -- sanity check
		f:write(key, ";", value[1], ";", value[2], "\n")
	end
	f:close()
end

local function _saveMapFunc()
	local f = assert(io.open("Mapdata.txt", "w"))
	for key, value in pairs(globalMapData) do
		f:write(key, ";", value[1], ";", value[2], ";", value[3], "\n")
	end
	f:close()
end

local function _savePlayerFunc()
	local f = assert(io.open("Playerdata.txt", "w"))
	for key, value in pairs(globalPlayerData) do
		if key:find(";") then continue end -- sanity check
		f:write(key, ";", value[1], ";", value[2], ";", value[3], ";", value[4], ";", value[5], ";", value[6], ";", value[7], ";", value[8], ";", value[9], ";", value[10], ";", value[11], ";", value[12], "\n")
	end
	f:close()	
end

local function _saveTimeFunc()
	--{time, player, skin, jTime, jPlayer, jSkin, nTime, nPlayer, nSkin}
	local f = assert(io.open("Timerecords.txt", "w"))
	for key, value in pairs(globalTimeData) do
		if value[2]:find(";") or value[5]:find(";") or value[8]:find(";") then continue end -- sanity check
		f:write(key, ";", value[1], ";", value[2], ";", value[3], ";", value[4], ";", value[5], ";", value[6], ";", value[7], ";", value[8], ";", value[9], "\n")
	end
	f:close()
end

local function _savePSkinUseFunc()
	--{player, {SkinData}}
	--SkinData is reformatted to be stored as plaintext
	local f = assert(io.open("pSkinUse.txt", "w"))
	for key, value in pairs(globalPlayerSkinUseData) do
		if key:find(";") then continue end -- no no no no no
		local assembledString = ""
		for key2, value2 in pairs(value) do
			if key2:find("/") or key2:find("|") then continue end -- if you're putting this into a skin ID, you're an asshole
		    if assembledString ~= "" then assembledString = assembledString .. "|" end
		    assembledString = assembledString .. key2 .. "/" .. value2
		end
		f:write(key, ";", assembledString, "\n")
	end
end

local function saveFiles(whatToSave)
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

local function checkNilPlayer(name)
	--Cleaner to just throw this here since I have to do it so much
	if globalPlayerData[name] == nil then
		globalPlayerData[name] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 1500, 1500, 1500}
	end
end

--Keep track of player damage
local function playerSpin(p, i, s)
	--player hit = p.name
	--player who threw item = s.player.name (nil - enviroment, matches p - self hit)
	checkNilPlayer(p.name)
	globalPlayerData[p.name][5] = globalPlayerData[p.name][5] + 1
	
	if s ~= nil and s.player ~= nil then
		if s.player.name == p.name then
			--Self hit
			globalPlayerData[p.name][4] = globalPlayerData[p.name][4] + 1
		else
			checkNilPlayer(s.player.name)
			globalPlayerData[s.player.name][3] = globalPlayerData[s.player.name][3] + 1		
		end
	else
		--Self hit (enviromental hazard probably)
		globalPlayerData[p.name][4] = globalPlayerData[p.name][4] + 1
	end
end
addHook("PlayerSpin", playerSpin)

local function playerExplode(p, i, s)
	checkNilPlayer(p.name)
	globalPlayerData[p.name][6] = globalPlayerData[p.name][6] + 1
	
	if s ~= nil and s.player ~= nil then
		if s.player.name == p.name then
			--Self hit
			globalPlayerData[p.name][4] = globalPlayerData[p.name][4] + 1
		else
			checkNilPlayer(s.player.name)
			globalPlayerData[s.player.name][3] = globalPlayerData[s.player.name][3] + 1
			
		end
	else
		globalPlayerData[p.name][4] = globalPlayerData[p.name][4] + 1
	end
end
addHook("PlayerExplode", playerExplode)

local function playerSquish(p, i, s)
	checkNilPlayer(p.name)
	globalPlayerData[p.name][7] = globalPlayerData[p.name][7] + 1
	
	if s ~= nil and s.player ~= nil then
		if s.player.name == p.name then
			--Self hit
			globalPlayerData[p.name][4] = globalPlayerData[p.name][4] + 1
		else
			checkNilPlayer(s.player.name)
			globalPlayerData[s.player.name][3] = globalPlayerData[s.player.name][3] + 1
			
		end
	else
		globalPlayerData[p.name][4] = globalPlayerData[p.name][4] + 1
	end
end
addHook("PlayerSquish", playerSquish)

--all saving flags
local completedRun = false
local didSaveSkins = false
local playerOrder = {}
local recordedPlayers = {}
local didSaveMap = false
local didSavePlayer = false
local didSaveTime = false

--if p.exiting > 0 then someone crossed the finish line
--keep track of partial and full finishes for recordkeeping
-- p.mo ~= nil (nil = spectator)
local function think()
	if not completedRun then
		local allStopped = true
		
		for p in players.iterate do
			if p.valid and p.mo ~= nil and p.mo.valid then
				if p.exiting == 0 then
					--Someone is still running
					allStopped = false
					if p.pflags & PF_TIMEOVER then
						--Someone DNF'd. Mark them down.
						if recordedPlayers[p.name] == nil then
							if playerOrder[p.kartstuff[k_position]] == nil then
								playerOrder[p.kartstuff[k_position]] = {p.name}
							elseif playerOrder[p.kartstuff[k_position]] ~= nil then
								--2 players finished on the same tic, this is a tie
								table.insert(playerOrder[p.kartstuff[k_position]], p.name)
							end					
							recordedPlayers[p.name] = 1
							--print(p.name.." Pos "..tostring(p.kartstuff[k_position]).." Realtime "..tostring(p.realtime))
						end	
					end
				elseif p.exiting ~= 0 then
					--Someone stopped. Determine if winner and mark finished players.
					--Store names for each position as a table in case of ties
					if recordedPlayers[p.name] == nil then
						if playerOrder[p.kartstuff[k_position]] == nil then
							playerOrder[p.kartstuff[k_position]] = {p.name}
						elseif playerOrder[p.kartstuff[k_position]] ~= nil then
							--2 players finished on the same tic, this is a tie
							table.insert(playerOrder[p.kartstuff[k_position]], p.name)
						end					
						recordedPlayers[p.name] = 1
						--print(p.name.." Pos "..tostring(p.kartstuff[k_position]).." Realtime "..tostring(p.realtime))
					end		
				end
			end
		end
		
		completedRun = allStopped	
	end
	
	for p in players.iterate
		if p.hasRecordHUD == nil and p.showKSChange == nil then
			p.hasRecordHUD = 1
			p.showKSChange = 1
		else
			continue
		end
	end
end
addHook("ThinkFrame", think)

--Reset values that trigger file saves
local function durMapChange()
	didSaveSkins = false
	completedRun = false
	playerOrder = {}
	recordedPlayers = {}
	didSaveMap = false
	didSavePlayer = false
	didSaveTime = false
end
addHook("MapChange", durMapChange)

local function notRunningSpecialGameType()
	--Checks to see if a special game mode is running or not
	local normalGame = true
	
	--Friendmod
	if CV_FindVar("fr_enabled") and CV_FindVar("fr_enabled").value == 1 then
		normalGame = false
	end
	
	if CV_FindVar("combi_active") and CV_FindVar("combi_active").value == 1 then
		normalGame = false
	end
	
	if CV_FindVar("frontrun_enabled") and CV_FindVar("frontrun_enabled").value == 1 then
		normalGame = false
	end
	
	if CV_FindVar("elimination") and CV_FindVar("elimination").value == 1 then
		normalGame = false
	end
	
	if CV_FindVar("spbatk") and CV_FindVar("spbatk").value == 1 then
		local foundP = 0
		for p in players.iterate do
			if p.valid and p.mo ~= nil and p.mo.valid then
				foundP = foundP + 1
				if foundP > 1 then
					--print("More than 1 playing, exiting")
					break
				end
			end	
		end
		if foundP <= 1 then
			normalGame = false
		end
	end
	
	return normalGame
end

--show KS change toggle p.showKSChange
COM_AddCommand("st_showks", function(p, text)
	if (p.showKSChange ~= nil) then
		if ((text == "off") or (text == "0") or (text == "no"))
			p.showKSChange = 0
			CONS_Printf(p, "\n".."\x82".."Disabled end of race KS display")
		elseif ((text == "on") or (text == "1") or (text == "yes"))
			p.showKSChange = 1
			CONS_Printf(p, "\n".."\x82".."Enabled end of race KS display")
		end
	else
		CONS_Printf(p, "\nNot ready yet, try again shortly.")
	end
 end, 0)

--Not touched outside of setting true - should mean only 1 maintenance per restart
local didMaint = false

local function intThink()

	--Data maintenance
	if didMaint == false then
		--Add new skins that aren't represented in data yet
		for s in skins.iterate do
			if globalSkinData[s.name] == nil then
				globalSkinData[s.name] = {0, s.realname}
			end
		end
		--Delete removed skins
		local skinReference = globalSkinData
		for k, v in pairs(skinReference) do
			if skins[k] == nil then
				globalSkinData[k] = nil
			elseif skins[k] ~= nil and v[2] == "Removed Skin" then
				--Fix broken record
				globalSkinData[k][2] = skins[k].realname
			end
		end
		--Add new maps that aren't in data yet & delete removed maps
		--MAPZZ = 1035. If they extend this higher then update the max in the loop below.
		for i=1,1035,1 do
			if mapheaderinfo[tostring(i)] ~= nil and globalMapData[tostring(i)] == nil then
				globalMapData[tostring(i)] = {0, 0, mapheaderinfo[tostring(i)].lvlttl}
			elseif mapheaderinfo[tostring(i)] == nil and globalMapData[tostring(i)] ~= nil then
				globalMapData[tostring(i)] = nil
			end
			
			if globalMapData[tostring(i)] ~= nil and globalMapData[tostring(i)][3] == "I am dead" and mapheaderinfo[tostring(i)] ~= nil then
				--Try to correct any messed up data
				globalMapData[tostring(i)][3] = mapheaderinfo[tostring(i)].lvlttl
			end
		end
		
		didMaint = true
	end
	
	local notSpecialMode = true
	
	--Track skin usage
	if not didSaveSkins then
		--print("Updating skin use count...")
		didSaveSkins = true
		
		--This gets set once here, and then checked by everything else
		notSpecialMode = notRunningSpecialGameType()
		
		if notSpecialMode then
			for p in players.iterate do
				if p.valid and p.mo ~= nil and p.mo.valid then
					if globalPlayerSkinUseData[p.name] == nil then
						globalPlayerSkinUseData[p.name] = {}
						globalPlayerSkinUseData[p.name][p.mo.skin] = 1
					elseif globalPlayerSkinUseData[p.name][p.mo.skin] == nil then
						globalPlayerSkinUseData[p.name][p.mo.skin] = 1
					else
						globalPlayerSkinUseData[p.name][p.mo.skin] = globalPlayerSkinUseData[p.name][p.mo.skin] + 1
					end
					--Determine if this player's usage should increment global data
					local shouldIncrement = false
					if globalPlayerSkinUseData[p.name][p.mo.skin] == 1 then
						shouldIncrement = true
					elseif globalPlayerSkinUseData[p.name][p.mo.skin] <= 50 and globalPlayerSkinUseData[p.name][p.mo.skin] % 5 == 0 then
						shouldIncrement = true
					end
					
					--realname
					if shouldIncrement then
						if globalSkinData[p.mo.skin] == nil then
							globalSkinData[p.mo.skin] = {1, skins[p.mo.skin].realname}
						else
							globalSkinData[p.mo.skin][1] = globalSkinData[p.mo.skin][1] + 1
						end
					end
				end
			end
		end

		saveFiles("Skin")	
	end
	
	--Track Map Usage
	if not didSaveMap then
		--print("Updating map data...")
		didSaveMap = true
		
		if notSpecialMode then
			if globalMapData[tostring(gamemap)] == nil then
				globalMapData[tostring(gamemap)] = {0, 0, mapheaderinfo[tostring(gamemap)].lvlttl}
			end
			if playerOrder[1] ~= nil then
				--Map was completed
				globalMapData[tostring(gamemap)][1] = globalMapData[tostring(gamemap)][1] + 1
			else
				--Nobody finished this race, assume it was RTV'd	
				--print ("Adding an RTV count...")
				globalMapData[tostring(gamemap)][2] = globalMapData[tostring(gamemap)][2] + 1
			end
		end
		saveFiles("Map")	
	end
	
	--Track player shit
	if not didSavePlayer then
		--print("Updating player data...")
		--{mapsPlayed, wins, hits, selfHits, spinned, exploded, squished, second, third, elo, jElo, nElo}
		didSavePlayer = true
		
		if notSpecialMode then
			local eloChanges = {}
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
					
			for pos, thisPlayer in pairs(playerOrder) do
				--If there's more than a 5 way tie I'm legitimately impressed
				for i=1,5,1 do
					if thisPlayer[i] ~= nil then
						checkNilPlayer(thisPlayer[i])
						--Increment play count
						globalPlayerData[thisPlayer[i]][1] = globalPlayerData[thisPlayer[i]][1] + 1
						
						--Increment 1st,2nd,3rd finish where appropriate
						if pos == 1 then
							globalPlayerData[thisPlayer[i]][2] = globalPlayerData[thisPlayer[i]][2] + 1
							if globalPlayerData[thisPlayer[i]][2] % 100 == 0 then
								chatprint('\130'..p.name..' has won '..tostring(globalPlayerData[thisPlayer[i]][2])..' times!', true)
							end
						elseif pos == 2 then
							globalPlayerData[thisPlayer[i]][8] = globalPlayerData[thisPlayer[i]][8] + 1
						elseif pos == 3 then
							globalPlayerData[thisPlayer[i]][9] = globalPlayerData[thisPlayer[i]][9] + 1
						end
						
						--Calculate ELO changes and store to save at the end
						eloChanges[thisPlayer[i]] = 0				
						for ePos, ePlayers in pairs(playerOrder) do
							for e=1,5,1 do
								--Ignore the same position
								if ePlayers[e] ~= nil and pos ~= ePos then		
									checkNilPlayer(ePlayers[e])
									
									if pos < ePos then
										--Players you beat
										--positive = lower rank, negative = higher rank
										--NEED TO VERIFY - For calcuations with decimals, this assumes that SRB2 strips decimal places without rounding
										local rankDif = (globalPlayerData[thisPlayer[i]][gameModeIndex] - globalPlayerData[ePlayers[e]][gameModeIndex]) / 100
										local rankChange = 5						
										if rankDif > 0 then
											rankChange = rankChange - rankDif
											if rankChange < 0 then
												rankChange = 0
											end
										elseif rankDif < 0 then
											--Absolute value of rankDif
											rankChange = rankChange + abs(rankDif)
										end
										
										eloChanges[thisPlayer[i]] = eloChanges[thisPlayer[i]] + rankChange
									else
										--players you lost to
										local rankDif = (globalPlayerData[thisPlayer[i]][gameModeIndex] - globalPlayerData[ePlayers[e]][gameModeIndex]) / 100
										local rankChange = -5						
										if rankDif > 0 then
											rankChange = rankChange - rankDif
										elseif rankDif < 0 then
											--Lost to someone with higher rank, cap max change at 500 diff							
											rankChange = rankChange + abs(rankDif)
											if rankChange > 0 then
												rankChange = 0
											end
										end
										
										eloChanges[thisPlayer[i]] = eloChanges[thisPlayer[i]] + rankChange
									end
								end
							end
						end
					end
				end			
			end
			
			--Loop through and apply all ELO changes
			for player, change in pairs(eloChanges) do
				if player ~= nil then
					--muh sanity
					checkNilPlayer(player)
					--print(player.." - "..tostring(change))
					globalPlayerData[player][gameModeIndex] = globalPlayerData[player][gameModeIndex] + change
					if globalPlayerData[player][gameModeIndex] < 0 then
						--Holy shit you suck, what the fuck
						globalPlayerData[player][gameModeIndex] = 0
					end
				end
			end
			
			--Notify players
			for p in players.iterate do
				if p.valid and p.mo ~= nil and p.mo.valid and eloChanges[p.name] ~= nil then
					if p.showKSChange == 0 then return end					
					local changeFormatted = tostring(eloChanges[p.name])
					if tonumber(eloChanges[p.name]) > 0 then
						changeFormatted = "+"..tostring(eloChanges[p.name])
					end
					chatprintf(p, "\130KS - "..tostring(globalPlayerData[p.name][gameModeIndex]).." ("..changeFormatted..")", false)
				end
			end
			
		end
		saveFiles("Player")	
	end
	
	if not didSaveTime then
		didSaveTime = true
		--Make sure no special game type is running
		if notSpecialMode then
			if globalTimeData[tostring(gamemap)] == nil then
				globalTimeData[tostring(gamemap)] = {99999999, "placeholder", "sonic", 99999999, "placeholder", "sonic", 99999999, "placeholder", "sonic"}
			end
			
			--Temp fix to wipe damaged records
			if tonumber(globalTimeData[tostring(gamemap)][7]) < 200 then
				globalTimeData[tostring(gamemap)][7] = 99999999
			end
			if tonumber(globalTimeData[tostring(gamemap)][4]) < 200 then
				globalTimeData[tostring(gamemap)][4] = 99999999
			end
			if tonumber(globalTimeData[tostring(gamemap)][1]) < 200 then
				globalTimeData[tostring(gamemap)][1] = 99999999
			end
			
			--Determine what mods are running
			--Time record saving priority - Driftmod > Juicebox > Tech/Vanilla
			local driftmodValue = 0
			if CV_FindVar("driftnitro") then
				driftmodValue = CV_FindVar("driftnitro").value
			end
			local juiceboxValue = 0
			if CV_FindVar("juicebox") then
				juiceboxValue = CV_FindVar("juicebox").value
			end
			if CV_FindVar("techonly") then
				--If techonly = 1 then consider juicebox as "off" for records
				if CV_FindVar("techonly").value == 1 then
					juiceboxValue = 0
				end
			end
			
			if playerOrder[1] ~= nil and playerOrder[1][1] ~= nil then
				--There's no handling for ties here and I don't really care all that much tbh
				for p in players.iterate do
					if p.valid and p.mo ~= nil and p.mo.valid and playerOrder[1][1] == p.name
						if driftmodValue == 1 then
							if p.realtime < tonumber(globalTimeData[tostring(gamemap)][7]) then
								globalTimeData[tostring(gamemap)][7] = p.realtime
								globalTimeData[tostring(gamemap)][8] = p.name
								globalTimeData[tostring(gamemap)][9] = p.mo.skin
								chatprint('\130NEW NITRO MAP RECORD!', true)
								K_PlayPowerGloatSound(p.mo)
							end	
						elseif juiceboxValue == 1 then
							if p.realtime < tonumber(globalTimeData[tostring(gamemap)][4]) then
								globalTimeData[tostring(gamemap)][4] = p.realtime
								globalTimeData[tostring(gamemap)][5] = p.name
								globalTimeData[tostring(gamemap)][6] = p.mo.skin
								chatprint('\130NEW JUICEBOX MAP RECORD!', true)
								K_PlayPowerGloatSound(p.mo)
							end	
						else
							if p.realtime < tonumber(globalTimeData[tostring(gamemap)][1]) then
								globalTimeData[tostring(gamemap)][1] = p.realtime
								globalTimeData[tostring(gamemap)][2] = p.name
								globalTimeData[tostring(gamemap)][3] = p.mo.skin
								chatprint('\130NEW MAP RECORD!', true)
								K_PlayPowerGloatSound(p.mo)
							end
						end
					end
				end
			end
			
			saveFiles("Time")	
		end
	
	end
end
addHook("IntermissionThinker", intThink)

local function netvars(net)
	globalSkinData = net($)
	globalMapData = net($)
	globalPlayerData = net($)
	globalTimeData = net($)
	globalPlayerSkinUseData = net($)
end
addHook("NetVars", netvars)

local function buildTimeString(x)
	if x == nil or x == 99999999 then return "N/A" end
	return ""..string.format("%02d", G_TicsToMinutes(x)).."' "..string.format("%02d", G_TicsToSeconds(x))..'" '..string.format("%02d", G_TicsToCentiseconds(x))
end

local function buildTimeStringTable(x)
	if x == nil or x == 99999999 then return nil end
	return {string.sub(string.format("%02d", G_TicsToMinutes(x)), 1, 1), string.sub(string.format("%02d", G_TicsToMinutes(x)), 2, 2), string.sub(string.format("%02d", G_TicsToSeconds(x)), 1, 1), string.sub(string.format("%02d", G_TicsToSeconds(x)), 2, 2), string.sub(string.format("%02d", G_TicsToCentiseconds(x)), 1, 1), string.sub(string.format("%02d", G_TicsToCentiseconds(x)), 2, 2)}
end

--record hud toggle
COM_AddCommand("st_showtime", function(p, text)
	if (p.hasRecordHUD ~= nil) then
		if ((text == "off") or (text == "0") or (text == "no"))
			p.hasRecordHUD = 0
			CONS_Printf(p, "\n".."\x82".."Disabled record time display")
		elseif ((text == "on") or (text == "1") or (text == "yes"))
			p.hasRecordHUD = 1
			CONS_Printf(p, "\n".."\x82".."Enabled record time display")
		end
	else
		CONS_Printf(p, "\nNot ready yet, try again shortly.")
	end
 end, 0)

--Draw map + mode's record below current time (if it exists)
local function drawRecordTime(v, p)
	if p.hasRecordHUD == 0 then return end
	
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
	
	local stringTime = nil
	local recordHolder = nil
	local recordSkin = nil
	if globalTimeData[tostring(gamemap)] ~= nil then
		if gameModeIndex == 10 then
			stringTime = buildTimeStringTable(globalTimeData[tostring(gamemap)][1])
			recordHolder = globalTimeData[tostring(gamemap)][2]
			recordSkin = globalTimeData[tostring(gamemap)][3]
		elseif gameModeIndex == 11 then
			stringTime = buildTimeStringTable(globalTimeData[tostring(gamemap)][4])
			recordHolder = globalTimeData[tostring(gamemap)][5]
			recordSkin = globalTimeData[tostring(gamemap)][6]
		elseif gameModeIndex == 12 then
			stringTime = buildTimeStringTable(globalTimeData[tostring(gamemap)][7])
			recordHolder = globalTimeData[tostring(gamemap)][8]
			recordSkin = globalTimeData[tostring(gamemap)][9]
		end
	end
	
	--Hide temp stuff
	if recordHolder == 'placeholder' then return end
	
	if stringTime ~= nil then
		local rgHudOffset = 138
		local screenYSub = 173
		
		if splitscreen == 0	
			local scrwidth = v.width()/v.dupx();
			local winheight = v.height()/v.dupy();
			local windiff = ((winheight-200)/2) + (winheight-200) --REEEEEEE DECIMALS ARE THE DEVIL!!!
			local right = ((scrwidth+75)/2);
			local font = "OPPRNK"
			
			if leveltime < 138 then
				rgHudOffset = -1 * (138-leveltime)
			else
				rgHudOffset = 0
			end		
			
			v.draw((-19-(rgHudOffset*12))+right, ((winheight-windiff)-screenYSub), v.cachePatch("2STTMBG"), vflags)
			if skins[recordSkin] ~= nil then
				v.draw((37-(rgHudOffset*12))+right, ((winheight-windiff)-screenYSub-2), v.cachePatch(skins[recordSkin].facemmap), flags, v.getColormap(recordSkin, skins[recordSkin].prefcolor))
			end
			--v.drawString((16-(rgHudOffset*12))+right, ((winheight-windiff)-screenYSub), tostring(stringTime[1]))
			--OPPRNK only has characters for 1 digit at a time, so here's a block of shit
			v.draw((49-(rgHudOffset*12))+right, ((winheight-windiff)-screenYSub), v.cachePatch(font.."0"..stringTime[1]), flags)
			v.draw((55-(rgHudOffset*12))+right, ((winheight-windiff)-screenYSub), v.cachePatch(font.."0"..stringTime[2]), flags)
			v.draw((63-(rgHudOffset*12))+right, ((winheight-windiff)-screenYSub), v.cachePatch("2STMNMK"), vflags)
			v.draw((69-(rgHudOffset*12))+right, ((winheight-windiff)-screenYSub), v.cachePatch(font.."0"..stringTime[3]), flags)
			v.draw((75-(rgHudOffset*12))+right, ((winheight-windiff)-screenYSub), v.cachePatch(font.."0"..stringTime[4]), flags)
			v.draw((83-(rgHudOffset*12))+right, ((winheight-windiff)-screenYSub), v.cachePatch("2STSCMK"), vflags)
			v.draw((89-(rgHudOffset*12))+right, ((winheight-windiff)-screenYSub), v.cachePatch(font.."0"..stringTime[5]), flags)
			v.draw((95-(rgHudOffset*12))+right, ((winheight-windiff)-screenYSub), v.cachePatch(font.."0"..stringTime[6]), flags)
			--v.draw((18-(rgHudOffset*12))+right, ((winheight-windiff)-screenYSub), v.cachePatch(font.."0"..tostring(stringTime)), flags)
			
			--player name
			if string.len(recordHolder) < 7 then
				local nameWidth = v.stringWidth(recordHolder, flags)
				v.drawString((36-(rgHudOffset*12))+(right - nameWidth), ((winheight-windiff)-screenYSub), recordHolder, flags)
			elseif string.len(recordHolder) > 13 then
				recordHolder = string.sub(recordHolder, 1, 11)..".."
				local nameWidth = v.stringWidth(recordHolder, flags, "small")
				v.drawString((36-(rgHudOffset*12))+(right - nameWidth), ((winheight-windiff)-screenYSub) + 2, recordHolder, flags, "small")
			else
				local nameWidth = v.stringWidth(recordHolder, flags, "small")
				v.drawString((36-(rgHudOffset*12))+(right - nameWidth), ((winheight-windiff)-screenYSub) + 2, recordHolder, flags, "small")
			end
			
		end
	end
end

hud.add(drawRecordTime, game)

--Helper function for sorting data in console commands
local function spairs(t, order)
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

--Console commands for data lookups
local function st_playerdata(p, ...)
	local pTarget = nil
	if not ... then
		--assume player is looking up player
		pTarget = p.name
	else
		pTarget = table.concat({...}, " ")
	end
	
	if pTarget == "lobby" then
		--Show races/wins for everyone currently playing
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
				
		for pl in players.iterate do
			if pl.valid and globalPlayerData[pl.name] ~= nil then			
				CONS_Printf(p, "\x82"..pl.name.."\x84 "..globalPlayerData[pl.name][gameModeIndex].." KS \x80|\x83 "..globalPlayerData[pl.name][2].." wins \x80| "..globalPlayerData[pl.name][1].." races")
			end
		end
	elseif pTarget=="top" or pTarget == "top wins" then
		local shitToSort = {}
		for k, v in pairs(globalPlayerData) do
			shitToSort[k] = tonumber(v[2])
			
		end
		local forCounter = 1
		for k,v in spairs(shitToSort, function(t,a,b) return t[b] < t[a] end) do
			CONS_Printf(p, tostring(forCounter).." - \x83"..k.." \x82 "..tostring(v).." wins")
			
			forCounter = forCounter + 1
			if forCounter > 10 then break end
		end
	elseif pTarget == "top ks" then
		--Uses the current mode's ELO
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
		
		local shitToSort = {}
		for k, v in pairs(globalPlayerData) do
			shitToSort[k] = tonumber(v[gameModeIndex])
		end
		local forCounter = 1
		for k,v in spairs(shitToSort, function(t,a,b) return t[b] < t[a] end) do
			CONS_Printf(p, tostring(forCounter).." - \x83"..k.." \x82 "..tostring(v).." KartScore")
			
			forCounter = forCounter + 1
			if forCounter > 10 then break end
		end
	elseif globalPlayerData[pTarget] == nil then
		CONS_Printf(p, "Could not find player (It's case sensitive or leave blank to see your stats)")
	else
		--{mapsPlayed, wins, hits, selfHits, spinned, exploded, squished, second, third, elo, jElo, nElo}
		--Time assumption: 3 minutes 30 seconds per race
		--tfw no math library
		local playtime = 210 * tonumber(globalPlayerData[pTarget][1])
		local hours = FixedFloor((playtime / 3600) * FRACUNIT) / FRACUNIT
		local minutes = FixedFloor(((playtime % 3600) / 60) * FRACUNIT) / FRACUNIT
		CONS_Printf(p, "\x83"..pTarget.." \x80- "..tostring(globalPlayerData[pTarget][1]).." races")
		CONS_Printf(p, "\x82"..tostring(globalPlayerData[pTarget][2]).." 1st places \x80| \x86"..tostring(globalPlayerData[pTarget][8]).." 2nd places \x80| \x8D"..tostring(globalPlayerData[pTarget][9]).." 3rd places")
		CONS_Printf(p, "KartScores - \x83"..tostring(globalPlayerData[pTarget][10]).." Vanilla/Tech \x80| \x84"..tostring(globalPlayerData[pTarget][11]).." Juicebox \x80| \x85"..tostring(globalPlayerData[pTarget][12]).." Nitro")
		CONS_Printf(p, tostring(globalPlayerData[pTarget][3]).." item hits | \x85"..tostring(globalPlayerData[pTarget][4]).." self or enviroment hits")
		CONS_Printf(p, "\x82"..tostring(globalPlayerData[pTarget][5]).." spinouts | \x87"..tostring(globalPlayerData[pTarget][6]).." times exploded | \x84"..tostring(globalPlayerData[pTarget][7]).." times squished")
		CONS_Printf(p, "Total playtime : "..tostring(hours).." hours, "..tostring(minutes).." minutes (est.)")
	end
end
COM_AddCommand("st_playerdata", st_playerdata)

local function st_mapdata(p, ...)
	local mTarget = nil
	if not ... then
		--assume player is looking up current map
		mTarget = gamemap
	else
		mTarget = table.concat({...}, " ")
	end
	mTarget = tostring(mTarget)
	
	if mTarget == "top" then
		local shitToSort = {}
		for k, v in pairs(globalMapData) do
			shitToSort[k] = tonumber(v[1])
		end
		local forCounter = 1
		for k,v in spairs(shitToSort, function(t,a,b) return t[b] < t[a] end) do
			if mapheaderinfo[k] and k ~= "1" then
				CONS_Printf(p, tostring(forCounter).." - \x82"..mapheaderinfo[k].lvlttl.." |\x83"..tostring(v).." plays | \x85"..tostring(globalMapData[k][2]).." RTVs")
			
				forCounter = forCounter + 1
				if forCounter > 10 then break end
			end
		end
	elseif mTarget == "bottom" then
		local shitToSort = {}
		for k, v in pairs(globalMapData) do
			shitToSort[k] = tonumber(v[2])
		end
		local forCounter = 1
		for k,v in spairs(shitToSort, function(t,a,b) return t[b] < t[a] end) do
			if mapheaderinfo[k] and k ~= "1" then	
				CONS_Printf(p, tostring(forCounter).." - \x82"..mapheaderinfo[k].lvlttl.." |\x85"..tostring(v).." RTVs | \x83"..tostring(globalMapData[k][1]).." plays")
				
				forCounter = forCounter + 1
				if forCounter > 10 then break end
			end
		end
	elseif globalMapData[mTarget] == nil then
		CONS_Printf(p, "Could not find map (Use the map code or leave blank for current map)")
	else
		--timesPlayed, rtv
		CONS_Printf(p, "\x82"..tostring(mapheaderinfo[mTarget].lvlttl).." ("..tostring(mTarget)..")")
		CONS_Printf(p, "\x83"..tostring(globalMapData[mTarget][1]).." plays | \x85"..tostring(globalMapData[mTarget][2]).." RTVs")
		
		if globalTimeData[mTarget] ~= nil then
			if globalTimeData[mTarget][2] ~= "placeholder" then
				CONS_Printf(p, "Vanilla/Tech Record : "..buildTimeString(globalTimeData[mTarget][1]).." by "..tostring(globalTimeData[mTarget][2]))
			end
			if globalTimeData[mTarget][5] ~= "placeholder" then
				CONS_Printf(p, "Juicebox Record : "..buildTimeString(globalTimeData[mTarget][4]).." by "..tostring(globalTimeData[mTarget][5]))
			end
			if globalTimeData[mTarget][8] ~= "placeholder" then
				CONS_Printf(p, "Nitro Record : "..buildTimeString(globalTimeData[mTarget][7]).." by "..tostring(globalTimeData[mTarget][8]))
			end
		end
	end
end
COM_AddCommand("st_mapdata", st_mapdata)

local function st_skindata(p, ...)
	local sTarget = nil
	if not ... then
		--assume player is looking at their current skin
		if p.mo ~= nil then
			sTarget = p.mo.skin
		else
			sTarget = "sonic"
		end	
	else
		sTarget = table.concat({...}, " ")
	end
	
	if sTarget == "top" then
		local shitToSort = {}
		for k, v in pairs(globalSkinData) do
			shitToSort[k] = tonumber(v[1])
		end
		local forCounter = 1
		for k,v in spairs(shitToSort, function(t,a,b) return tonumber(t[b]) < tonumber(t[a]) end) do
			if skins[k] ~= nil then
				CONS_Printf(p, tostring(forCounter).." - \x82"..tostring(skins[k].realname).." - \x83"..tostring(v).." weighted uses")
			else
				CONS_Printf(p, tostring(forCounter).." - \x82"..k.." - \x83"..tostring(v).." weighted uses")
			end					
			forCounter = forCounter + 1
			if forCounter > 10 then break end
		end
	elseif globalSkinData[sTarget] == nil then
		CONS_Printf(p, "Could not find skin (Use skin code or leave blank for current map)")
	else
		--just a count
		if skins[sTarget] then
			CONS_Printf(p, "\x82"..tostring(skins[sTarget].realname))
		else
			CONS_Printf(p, "\x82"..sTarget)
		end
		
		CONS_Printf(p, tostring(globalSkinData[sTarget][1]).." weighted uses")
	end
end
COM_AddCommand("st_skindata", st_skindata)

--[[
	I'm just leaving this here for reference on sorting because I fucking hate it

	local globalPlayerData = {}
	globalPlayerData['UrMom'] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 1500, 1500, 1500}
	globalPlayerData['UrDad'] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 1250, 1500, 1500}
	globalPlayerData['UrFace'] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 1654, 1500, 1500}

	local shitToSort = {}
	for k, v in pairs(globalPlayerData) do
	  shitToSort[k] = v[10]
	end

	for k,v in spairs(shitToSort, function(t,a,b) return t[b] < t[a] end) do
		print(k, v)
	end
--]]
