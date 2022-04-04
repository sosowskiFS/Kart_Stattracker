--StatTracker
--Tracks and filesaves Skin usage, map usage, and player data
local globalSkinData = {}
local globalMapData = {}
local globalPlayerData = {}
local globalTimeData = {}
local f = io.open("Skincounter.txt", "r")
if f then
	--file already exsists, load from it
	--print('Loading skincounter data...')
	for l in f:lines() do
		local skinName, count = string.match(l, "(.*);(.*)")

		if skinName then
			globalSkinData[skinName] = count
		end
	end
	f:close()
end
local m = io.open("Mapdata.txt", "r")
if m then
	--file already exsists, load from it
	--print('Loading map data...')
	for l in m:lines() do
		local mapName, timesPlayed, rtv = string.match(l, "(.*);(.*);(.*)")

		if mapName then
			globalMapData[mapName] = {timesPlayed, rtv}
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

		if pName then
			globalPlayerData[pName] = {mapsPlayed, wins, hits, selfHits, spinned, exploded, squished, second, third, elo, jElo, nElo}
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

--You can't pcall functions with parameters unless the function is written inside of that, I guess
local function _saveSkinFunc()
	local f = assert(io.open("Skincounter.txt", "w"))
	for key, value in pairs(globalSkinData) do
		if key:find(";") then continue end -- sanity check
		f:write(key, ";", value, "\n")
	end
	f:close()
end

local function _saveMapFunc()
	local f = assert(io.open("Mapdata.txt", "w"))
	for key, value in pairs(globalMapData) do
		f:write(key, ";", value[1], ";", value[2], "\n")
	end
	f:close()
end

local function _savePlayerFunc()
	local f = assert(io.open("Playerdata.txt", "w"))
	for key, value in pairs(globalPlayerData) do
		if key:find(";") then continue end -- sanity check
		f:write(key, ";", value[1], ";", value[2], ";", value[3], ";", value[4], ";", value[5], ";", value[6], ";", value[7], "\n")
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

local function saveFiles(whatToSave)
	if consoleplayer ~= server then return end

	if whatToSave == "Skin" then
		--print('Saving skincounter data...')
		if not pcall(_saveSkinFunc) then
			print("Failed to save skin file!")
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
local posPointer = 1
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
				elseif p.exiting ~= 0 then
					--Someone stopped. Determine if winner and mark finished players.
					--Store names for each position as a table in case of ties
					if playerOrder[posPointer] == nil then
						playerOrder[posPointer] = {p.name}
					else if playerOrder[posPointer] ~= nil then
						--2 players finished on the same tic, this is a tie
						table.insert(playerOrder[posPointer], p.name)
					end
					
					--if raceWinner == nil then
						--raceWinner = p.name
					--end
					--if finishedPlayers[p.name] == nil then
						--possibleTie = true
						--finishedPlayers[p.name] = true
					--end
				end
			end
		end
		
		if playerOrder[posPointer] ~= nil then
			posPointer = posPointer + 1
		end
		
		completedRun = allStopped	
	end
end
addHook("ThinkFrame", think)

--Reset values that trigger file saves
local function durMapChange()
	didSaveSkins = false
	completedRun = false
	playerOrder = {}
	didSaveMap = false
	didSavePlayer = false
	didSaveTime = false
	posPointer = 1
end
addHook("MapChange", durMapChange)

local function notRunningSpecialGameType()
	--Checks to see if a special game mode is running or not
	local normalGame = true
	
	--Friendmod
	if CV_FindVar("fr_enabled") and  CV_FindVar("fr_enabled").value == 1 then
		normalGame = false
	end
	
	if CV_FindVar("combi_active") and  CV_FindVar("combi_active").value == 1 then
		normalGame = false
	end
	
	if CV_FindVar("frontrun_enabled") and  CV_FindVar("frontrun_enabled").value == 1 then
		normalGame = false
	end
	
	if CV_FindVar("elimination") and  CV_FindVar("elimination").value == 1 then
		normalGame = false
	end
	
	return normalGame
end

local function intThink()
	--Track skin usage
	if not didSaveSkins then
		--print("Updating skin use count...")
		didSaveSkins = true
		for p in players.iterate do
			if p.valid and p.mo ~= nil and p.mo.valid 
				if globalSkinData[p.mo.skin] == nil then
					globalSkinData[p.mo.skin] = 1
				else
					globalSkinData[p.mo.skin] = globalSkinData[p.mo.skin] + 1
				end
			end
		end
		saveFiles("Skin")	
	end
	
	--Track Map Usage
	if not didSaveMap then
		--print("Updating map data...")
		didSaveMap = true
		if globalMapData[tostring(gamemap)] == nil then
			globalMapData[tostring(gamemap)] = {0, 0}
		end
		if playerOrder[1] ~= nil then
			--Map was completed
			globalMapData[tostring(gamemap)][1] = globalMapData[tostring(gamemap)][1] + 1
		else
			--Nobody finished this race, assume it was RTV'd	
			--print ("Adding an RTV count...")
			globalMapData[tostring(gamemap)][2] = globalMapData[tostring(gamemap)][2] + 1
		end
		saveFiles("Map")	
	end
	
	--Track player shit
	if not didSavePlayer then
		--print("Updating player data...")
		--{mapsPlayed, wins, hits, selfHits, spinned, exploded, squished, second, third, elo, jElo, nElo}
		didSavePlayer = true
		
		if notRunningSpecialGameType() then
			local eloChanges = {}
			local gameModeIndex = 10
			if CV_FindVar("driftnitro") and CV_FindVar("driftnitro").value == 1 then
				gameModeIndex = 12
			else if CV_FindVar("juicebox") and CV_FindVar("juicebox").value == 1 then
				if CV_FindVar("techonly") and CV_FindVar("techonly").value == 1 then
					gameModeIndex = 10
				else
					gameModeIndex = 11
				end				
			end
					
			for pos, players in pairs(playerOrder) do
				--If there's more than a 5 way tie I'm legitimately impressed
				for i=1,5,1 do
					if players[i] ~= nil then
						checkNilPlayer(players[i])
						--Increment play count
						globalPlayerData[players[i]][1] = globalPlayerData[players[i]][1] + 1
						
						--Increment 1st,2nd,3rd finish where appropriate
						if pos == 1 then
							globalPlayerData[players[i]][2] = globalPlayerData[players[i]][2] + 1
							if globalPlayerData[players[i]][2] % 100 == 0 then
								chatprint('\130'..p.name..' has won '..tostring(globalPlayerData[players[i]][2])..' times!', true)
							end
						elseif pos == 2 then
							globalPlayerData[players[i]][8] = globalPlayerData[players[i]][8] + 1
						elseif pos == 3 then
							globalPlayerData[players[i]][9] = globalPlayerData[players[i]][9] + 1
						end
						
						--Calculate ELO changes and store to save at the end
						eloChanges[players[i]] = 0				
						for ePos, ePlayers in pairs(playerOrder) do
							for e=1,5,1 do
								--Ignore the same position
								if ePlayers[e] ~= nil and pos ~= ePos then		
									checkNilPlayer(ePlayers[e])
									
									if pos < ePos then
										--Players you beat
										--positive = lower rank, negative = higher rank
										--NEED TO VERIFY - For calcuations with decimals, this assumes that SRB2 strips decimal places without rounding
										local rankDif = (globalPlayerData[players[i]][gameModeIndex] - globalPlayerData[ePlayers[e]][gameModeIndex]) / 100
										local rankChange = 5						
										if rankDif > 0 then
											rankChange = rankChange - rankDif
											if rankChange < 0 then
												rankChange = 0
											end
										else if rankDif < 0 then
											--Absolute value of rankDif
											rankChange = rankChange + abs(rankDif)
										end
										
										eloChanges[players[i]] = eloChanges[players[i]] + rankChange
									else
										--players you lost to
										local rankDif = (globalPlayerData[players[i]][gameModeIndex] - globalPlayerData[ePlayers[e]][gameModeIndex]) / 100
										local rankChange = -5						
										if rankDif > 0 then
											rankChange = rankChange - rankDif
										else if rankDif < 0 then
											--Lost to someone with higher rank, cap max change at 500 diff							
											rankChange = rankChange + abs(rankDif)
											if rankChange > 0 then
												rankChange = 0
											end
										end
										
										eloChanges[players[i]] = eloChanges[players[i]] + rankChange
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
					print(player.." - "..tostring(change))
					globalPlayerData[player][gameModeIndex] = globalPlayerData[player][gameModeIndex] + change			
				end		
			end
		end
		saveFiles("Player")	
	end
	
	if not didSaveTime then
		didSaveTime = true
		--Make sure no special game type is running
		if notRunningSpecialGameType() then
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
end
addHook("NetVars", netvars)

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
		for pl in players.iterate do
			if pl.valid and globalPlayerData[pl.name] ~= nil then
				CONS_Printf(p, "\x82"..pl.name.."\x83 "..globalPlayerData[pl.name][2].." wins \x80| "..globalPlayerData[pl.name][1].." races")
			end
		end
	elseif globalPlayerData[pTarget] == nil then
		CONS_Printf(p, "Could not find player (It's case sensitive or leave blank to see your stats)")
	else
		--pName, mapsPlayed, wins, hits, selfHits, spinned, exploded, squished
		--Time assumption: 3 minutes 30 seconds per race
		--tfw no math library
		local playtime = 210 * tonumber(globalPlayerData[pTarget][1])
		local hours = FixedFloor((playtime / 3600) * FRACUNIT) / FRACUNIT
		local minutes = FixedFloor(((playtime % 3600) / 60) * FRACUNIT) / FRACUNIT
		CONS_Printf(p, "\x82"..pTarget)
		CONS_Printf(p, tostring(globalPlayerData[pTarget][1]).." races | \x83"..tostring(globalPlayerData[pTarget][2]).." wins")
		CONS_Printf(p, tostring(globalPlayerData[pTarget][3]).." item hits | \x85"..tostring(globalPlayerData[pTarget][4]).." self or enviroment hits")
		CONS_Printf(p, "\x82"..tostring(globalPlayerData[pTarget][5]).." spinouts | \x87"..tostring(globalPlayerData[pTarget][6]).." times exploded | \x84"..tostring(globalPlayerData[pTarget][7]).." times squished")
		CONS_Printf(p, "Total playtime : "..tostring(hours).." hours, "..tostring(minutes).." minutes (est.)")
	end
end
COM_AddCommand("st_playerdata", st_playerdata)

local function buildTimeString(x)
	if x == nil or x == 99999999 then return "N/A" end
	return ""..string.format("%02d", G_TicsToMinutes(x)).."' "..string.format("%02d", G_TicsToSeconds(x))..'" '..string.format("%02d", G_TicsToCentiseconds(x))
end

local function st_mapdata(p, ...)
	local mTarget = nil
	if not ... then
		--assume player is looking up current map
		mTarget = gamemap
	else
		mTarget = table.concat({...}, " ")
	end
	mTarget = tostring(mTarget)
	
	if globalMapData[mTarget] == nil then
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
		sTarget = p.mo.skin
	else
		sTarget = table.concat({...}, " ")
	end
	
	if globalSkinData[sTarget] == nil then
		CONS_Printf(p, "Could not find skin (Use skin code or leave blank for current map)")
	else
		--just a count
		CONS_Printf(p, "\x82"..sTarget)
		CONS_Printf(p, "Used in "..tostring(globalSkinData[sTarget]).." races")
	end
end
COM_AddCommand("st_skindata", st_skindata)
