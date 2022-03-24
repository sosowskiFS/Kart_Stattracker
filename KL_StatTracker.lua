--StatTracker
--Tracks and filesaves Skin usage, map usage, and player data
local globalSkinData = {}
local globalMapData = {}
local globalPlayerData = {}
local globalTimeData = {}
local f = io.open("Skincounter.txt", "r")
if f then
	--file already exsists, load from it
	print('Loading skincounter data...')
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
	print('Loading map data...')
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
	print('Loading player data...')
	for l in p:lines() do
		local pName, mapsPlayed, wins, hits, selfHits, spinned, exploded, squished = string.match(l, "(.*);(.*);(.*);(.*);(.*);(.*);(.*);(.*)")

		if pName then
			globalPlayerData[pName] = {mapsPlayed, wins, hits, selfHits, spinned, exploded, squished}
		end
	end
	p:close()
end
local f = io.open("Timerecords.txt", "r")
if f then
	--STOP
	print('Loading time record data...')
	for l in f:lines() do
		local mapName, time, player, skin = string.match(l, "(.*);(.*);(.*);(.*)")
		if mapName then
			globalTimeData[mapName] = {time, player, skin}
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
	local f = assert(io.open("Timerecords.txt", "w"))
	for key, value in pairs(globalTimeData) do
		if value[2]:find(";") then continue end -- sanity check
		f:write(key, ";", value[1], ";", value[2], ";", value[3], "\n")
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
		print('Saving map data...')
		if not pcall(_saveMapFunc) then
			print("Failed to save map file!")
		end
	elseif whatToSave == "Player" then
		print('Saving player data...')
		if not pcall(_savePlayerFunc) then
			print("Failed to save player file!")
		end
	elseif whatToSave == "Time" then
		print('Saving time data...')
		if not pcall(_saveTimeFunc) then
			print("Failed to save time file!")
		end
	end
end

local function checkNilPlayer(name)
	--Cleaner to just throw this here since I have to do it so much
	if globalPlayerData[name] == nil then
		globalPlayerData[name] = {0, 0, 0, 0, 0, 0, 0}
	end
end

--Keep track of player damage
local function playerSpin(p, i, s)
	--player hit = p.name
	--player who threw item = s.player.name (nil - enviroment, matches p - self hit)
	checkNilPlayer(p.name)
	globalPlayerData[p.name][5] = globalPlayerData[p.name][5] + 1
	
	if s.player ~= nil then
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
	
	if s.player ~= nil then
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
	
	if s.player ~= nil then
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
local raceWinner = nil
local finishedPlayers = {}
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
					if raceWinner == nil then
						raceWinner = p.name
					end
					if finishedPlayers[p.name] == nil then
						finishedPlayers[p.name] = true
					end
				end
			end
		end
		completedRun = allStopped	
	end
end
addHook("ThinkFrame", think)

--Reset values that trigger file saves
local function durMapChange()
	didSaveSkins = false
	completedRun = false
	raceWinner = nil
	finishedPlayers = {}
	didSaveMap = false
	didSavePlayer = false
	didSaveTime = false
end
addHook("MapChange", durMapChange)

local function intThink()
	--Track skin usage
	if not didSaveSkins then
		print("Updating skin use count...")
		for p in players.iterate do
			if globalSkinData[p.mo.skin] == nil then
				globalSkinData[p.mo.skin] = 1
			else
				globalSkinData[p.mo.skin] = globalSkinData[p.mo.skin] + 1
			end
		end
		saveFiles("Skin")
		didSaveSkins = true
	end
	
	--Track Map Usage
	if not didSaveMap then
		print("Updating map data...")
		if globalMapData[tostring(gamemap)] == nil then
			globalMapData[tostring(gamemap)] = {0, 0}
		end
		if raceWinner ~= nil then
			--Map was completed
			globalMapData[tostring(gamemap)][1] = globalMapData[tostring(gamemap)][1] + 1
		else
			--Nobody finished this race, assume it was RTV'd	
			print ("Adding an RTV count...")
			globalMapData[tostring(gamemap)][2] = globalMapData[tostring(gamemap)][2] + 1
		end
		saveFiles("Map")
		didSaveMap = true
	end
	
	--Track player shit
	if not didSavePlayer then
		print("Updating player data...")
		for p in players.iterate do
			checkNilPlayer(p.name)
			if finishedPlayers[p.name] ~= nil then
				globalPlayerData[p.name][1] = globalPlayerData[p.name][1] + 1
			end
			if raceWinner == p.name then
				globalPlayerData[p.name][2] = globalPlayerData[p.name][2] + 1
			end
		end
		
		saveFiles("Player")
		didSavePlayer = true
	end
	
	if not didSaveTime then
		if globalTimeData[tostring(gamemap)] == nil then
			globalTimeData[tostring(gamemap)] = {99999999, "placeholder", "sonic"}
		end
	
		if raceWinner ~= nil then
			for p in players.iterate do
				if p.valid and p.mo ~= nil and p.mo.valid and raceWinner == p.name then
					if p.realtime < tonumber(globalTimeData[tostring(gamemap)][1]) then
						globalTimeData[tostring(gamemap)] = {p.realtime, p.name, p.mo.skin}
						chatprint('\130NEW MAP RECORD!', true)
						K_PlayPowerGloatSound(p.mo)
					end
				end
			end
		end
		
		saveFiles("Time")
		didSaveTime = true
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
	
	if globalPlayerData[pTarget] == nil then
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
		CONS_Printf(p, "\x82"..mapheaderinfo[mTarget].lvlttl)
		CONS_Printf(p, "\x83"..tostring(globalMapData[mTarget][1]).." plays | \x85"..tostring(globalMapData[mTarget][2]).." RTVs")
		if globalTimeData[mTarget] ~= nil and globalTimeData[mTarget][2] ~= "placeholder" then
			--time, player, skin
			CONS_Printf(p, "Best time : "..buildTimeString(globalTimeData[mTarget][1]).." by "..tostring(globalTimeData[mTarget][2]))
		end
	end
end
COM_AddCommand("st_mapdata", st_mapdata)

local function st_skindata(p, ...)
	local sTarget = nil
	if not ... then
		--assume player is looking their current skin
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
