--Keep track of player damage
local function playerSpin(p, i, s)
	if sTrack.cv_enabled.value == 1 then
		--player hit = p.name
		--player who threw item = s.player.name (nil - enviroment, matches p - self hit)
		sTrack.checkNilPlayer(p.name)
		sTrack.globalPlayerData[p.name][5] = sTrack.globalPlayerData[p.name][5] + 1
		
		if s ~= nil and s.player ~= nil then
			if s.player.name == p.name then
				--Self hit
				sTrack.globalPlayerData[p.name][4] = sTrack.globalPlayerData[p.name][4] + 1
			else
				sTrack.checkNilPlayer(s.player.name)
				sTrack.globalPlayerData[s.player.name][3] = sTrack.globalPlayerData[s.player.name][3] + 1		
			end
		else
			--Self hit (enviromental hazard probably)
			sTrack.globalPlayerData[p.name][4] = sTrack.globalPlayerData[p.name][4] + 1
		end
	end
end
addHook("PlayerSpin", playerSpin)

local function playerExplode(p, i, s)
	if sTrack.cv_enabled.value == 1 then
		sTrack.checkNilPlayer(p.name)
		sTrack.globalPlayerData[p.name][6] = sTrack.globalPlayerData[p.name][6] + 1
		
		if s ~= nil and s.player ~= nil then
			if s.player.name == p.name then
				--Self hit
				sTrack.globalPlayerData[p.name][4] = sTrack.globalPlayerData[p.name][4] + 1
			else
				sTrack.checkNilPlayer(s.player.name)
				sTrack.globalPlayerData[s.player.name][3] = sTrack.globalPlayerData[s.player.name][3] + 1		
			end
		else
			sTrack.globalPlayerData[p.name][4] = sTrack.globalPlayerData[p.name][4] + 1
		end
	end
end
addHook("PlayerExplode", playerExplode)

local function playerSquish(p, i, s)
	if sTrack.cv_enabled.value == 1 then
		sTrack.checkNilPlayer(p.name)
		sTrack.globalPlayerData[p.name][7] = sTrack.globalPlayerData[p.name][7] + 1
		
		if s ~= nil and s.player ~= nil then
			if s.player.name == p.name then
				--Self hit
				sTrack.globalPlayerData[p.name][4] = sTrack.globalPlayerData[p.name][4] + 1
			else
				sTrack.checkNilPlayer(s.player.name)
				sTrack.globalPlayerData[s.player.name][3] = sTrack.globalPlayerData[s.player.name][3] + 1
				
			end
		else
			sTrack.globalPlayerData[p.name][4] = sTrack.globalPlayerData[p.name][4] + 1
		end
	end
end
addHook("PlayerSquish", playerSquish)

--all saving flags
local completedRun = false
local didSaveSkins = false
local playerOrder = {}
local timeList = {}
local DNFList = {}
local RSList = {}
local hmIntermission = false
local didSaveMap = false
local didSavePlayer = false
local didSaveTime = false
local cMode = sTrack.findCurrentMode()
local gameModeIndex = sTrack.getModeIndex()

--HUD Display stuff
local recordSkinColor = nil
local slideValue = -50
local slideRun = "stop"
local rTimeHolder = nil
local rPlayerHolder = nil
local rSkinHolder = nil
local rSkinColorHolder = nil

--This is only ever set to true so it runs once. 
local didMaint = false

--This is where all the calculations and saving happens
local function intThink()
	if sTrack.cv_enabled.value == 0 then return end
	--Data maintenance
	if didMaint == false then
		--Reset use values to 0 in globalSkinData, repopulate it from player skin use data
		for k, v in pairs(sTrack.globalSkinData)
			sTrack.globalSkinData[k][1] = 0
			sTrack.globalSkinData[k][3] = 0
		end
		
		--globalPlayerSkinUseData["PlayerName"]["SkinName"]
		local playerSkinUseReference = sTrack.globalPlayerSkinUseData
		for k, v in pairs(playerSkinUseReference)
			for k2, v2 in pairs(playerSkinUseReference[k])
				if sTrack.cv_wiperemovedaddons.value == 1 and skins[k2] == nil then
					--This skin doesn't exist anymore and can be removed
					sTrack.globalPlayerSkinUseData[k][k2] = nil
				else
					--calculate the weighted uses			
					local weightedUse = FixedFloor((v2 / 5) * FRACUNIT) / FRACUNIT
					if tonumber(v2) > 0 then
						weightedUse = $ + 1
					end
					if weightedUse > 10 then
						weightedUse = 10
					end			
					
					if sTrack.globalSkinData[k2] == nil then
						if skins[k2] == nil then
							sTrack.globalSkinData[k2] = {weightedUse, "Removed Skin", v2}
						else
							sTrack.globalSkinData[k2] = {weightedUse, skins[k2].realname, v2}
						end					
					else
						sTrack.globalSkinData[k2][1] = $ + weightedUse
						sTrack.globalSkinData[k2][3] = $ + v2
					end		
				end				
			end
		end
	
		--Add new skins that aren't represented in data yet
		for s in skins.iterate do
			if sTrack.globalSkinData[s.name] == nil then
				sTrack.globalSkinData[s.name] = {0, s.realname, 0}
			end
		end
		--Delete removed skins
		local skinReference = sTrack.globalSkinData
		for k, v in pairs(skinReference) do
			if sTrack.cv_wiperemovedaddons.value == 1 and skins[k] == nil then
				sTrack.globalSkinData[k] = nil
			elseif skins[k] ~= nil and v[2] == "Removed Skin" then
				--Fix broken record
				sTrack.globalSkinData[k][2] = skins[k].realname
			end
		end
		--Add new maps that aren't in data yet & delete removed maps
		--MAPZZ = 1035. If they extend this higher then update the max in the loop below.
		for i=1,1035,1 do
			if mapheaderinfo[tostring(i)] ~= nil and sTrack.globalMapData[tostring(i)] == nil then
				sTrack.globalMapData[tostring(i)] = {0, 0, mapheaderinfo[tostring(i)].lvlttl}
			elseif sTrack.cv_wiperemovedaddons.value == 1 and mapheaderinfo[tostring(i)] == nil and sTrack.globalMapData[tostring(i)] ~= nil then
				sTrack.globalMapData[tostring(i)] = nil
			end
			
			if sTrack.globalMapData[tostring(i)] ~= nil and sTrack.globalMapData[tostring(i)][3] == "I am dead" and mapheaderinfo[tostring(i)] ~= nil then
				--Try to correct any messed up data
				sTrack.globalMapData[tostring(i)][3] = mapheaderinfo[tostring(i)].lvlttl
			end
		end
		
		didMaint = true
	end
	
	--checks to see if more than 1 player is playing for various increments
	local foundP = 0
	for p in players.iterate do
		if p.valid and p.mo ~= nil and p.mo.valid then
			foundP = foundP + 1
			if foundP > 1 then
				break
			end
		end	
	end
	
	local hasTimeSupport = sTrack.isTimeSupportedMode(playerOrder)
	local hasKSSupport = sTrack.isKSSupportedMode()
	
	--Track skin usage
	if not didSaveSkins then
		--These vars are always set first in case something breaks
		didSaveSkins = true
		
		for p in players.iterate do
			if p.valid and p.mo ~= nil and p.mo.valid then
				if sTrack.globalPlayerSkinUseData[p.name] == nil then
					sTrack.globalPlayerSkinUseData[p.name] = {}
					sTrack.globalPlayerSkinUseData[p.name][p.mo.skin] = 1
				elseif sTrack.globalPlayerSkinUseData[p.name][p.mo.skin] == nil then
					sTrack.globalPlayerSkinUseData[p.name][p.mo.skin] = 1
				else
					sTrack.globalPlayerSkinUseData[p.name][p.mo.skin] = sTrack.globalPlayerSkinUseData[p.name][p.mo.skin] + 1
				end
				--Determine if this player's usage should increment global data
				local shouldIncrement = false
				if sTrack.globalPlayerSkinUseData[p.name][p.mo.skin] == 1 then
					shouldIncrement = true
				elseif sTrack.globalPlayerSkinUseData[p.name][p.mo.skin] <= 45 and sTrack.globalPlayerSkinUseData[p.name][p.mo.skin] % 5 == 0 then
					shouldIncrement = true
				end
				
				--Tick up weighted total
				if shouldIncrement then
					if sTrack.globalSkinData[p.mo.skin] == nil then
						sTrack.globalSkinData[p.mo.skin] = {1, skins[p.mo.skin].realname, 1}
					else
						sTrack.globalSkinData[p.mo.skin][1] = sTrack.globalSkinData[p.mo.skin][1] + 1
					end
				end
				
				--Tick up total count
				if sTrack.globalSkinData[p.mo.skin] == nil then
					sTrack.globalSkinData[p.mo.skin] = {1, skins[p.mo.skin].realname, 1}					
				else
					sTrack.globalSkinData[p.mo.skin][3] = sTrack.globalSkinData[p.mo.skin][3] + 1
				end
				
			end
		end

		sTrack.saveFiles("Skin")	
	end
	
	--Track Map Usage
	if not didSaveMap then
		didSaveMap = true
		
		--doing an isolated check here for SPBAttack because this inflates RTV count quite a bit
		local doUseSaves = true
		if CV_FindVar("spbatk") and CV_FindVar("spbatk").value == 1 then
			if foundP <= 1 then
				doUseSaves = false
			end
		end
		
		if doUseSaves then
			if sTrack.globalMapData[tostring(gamemap)] == nil then
				sTrack.globalMapData[tostring(gamemap)] = {0, 0, mapheaderinfo[tostring(gamemap)].lvlttl}
			end
			if playerOrder[1] ~= nil then
				--Map was completed
				sTrack.globalMapData[tostring(gamemap)][1] = sTrack.globalMapData[tostring(gamemap)][1] + 1
			else
				--Nobody finished this race, assume it was RTV'd	
				--print ("Adding an RTV count...")
				sTrack.globalMapData[tostring(gamemap)][2] = sTrack.globalMapData[tostring(gamemap)][2] + 1
			end
		end
		sTrack.saveFiles("Map")	
	end
	
	--Track player data
	if not didSavePlayer then
		didSavePlayer = true
				
		for pos, thisPlayer in pairs(playerOrder) do
			for k, v in pairs(thisPlayer) do
				sTrack.checkNilPlayer(v)
				--Increment play count
				sTrack.globalPlayerData[v][1] = sTrack.globalPlayerData[v][1] + 1
				
				--Increment 1st,2nd,3rd finish where appropriate
				if foundP > 1 then
					if pos == 1 then
						sTrack.globalPlayerData[v][2] = sTrack.globalPlayerData[v][2] + 1
						if sTrack.globalPlayerData[v][2] % 100 == 0 and sTrack.cv_silentmode.value == 0 then
							chatprint('\130'..v..' has won '..tostring(sTrack.globalPlayerData[v][2])..' times!', true)
						end
					elseif pos == 2 then
						sTrack.globalPlayerData[v][8] = sTrack.globalPlayerData[v][8] + 1
					elseif pos == 3 then
						sTrack.globalPlayerData[v][9] = sTrack.globalPlayerData[v][9] + 1
					end				
				end
				
				if hasKSSupport and sTrack.cv_enableks.value == 1 then							
					--Calculate ELO changes and store to save at the end
					sTrack.ksChanges[v] = 0				
					for ePos, ePlayers in pairs(playerOrder) do
						for eK, eV in pairs(ePlayers)
							--Ignore the same position
							if eV ~= nil and pos ~= ePos then						
								sTrack.checkNilPlayer(eV)							
								if pos < ePos then
									--Players you beat
									--positive = lower rank, negative = higher rank
									local rankDif = (sTrack.globalPlayerData[v][gameModeIndex] - sTrack.globalPlayerData[eV][gameModeIndex]) / 100
									local rankChange = 5						
									if rankDif > 0 then
										rankChange = rankChange - rankDif
										if rankChange < 1 then
											rankChange = 1
										end
									elseif rankDif < 0 then
										--Absolute value of rankDif
										rankChange = rankChange + abs(rankDif)
									end
									
									sTrack.ksChanges[v] = sTrack.ksChanges[v] + rankChange
								else
									--players you lost to
									local rankDif = (sTrack.globalPlayerData[v][gameModeIndex] - sTrack.globalPlayerData[eV][gameModeIndex]) / 100
									local rankChange = -5						
									if rankDif > 0 then
										rankChange = rankChange - rankDif
									elseif rankDif < 0 then
										--Lost to someone with higher rank, cap max change at 500 diff							
										rankChange = rankChange + abs(rankDif)
										if rankChange > -1 then
											rankChange = -1
										end
									end
									
									sTrack.ksChanges[v] = sTrack.ksChanges[v] + rankChange
								end
							end
						end
					end
				end
			end			
		end
		
		--Loop through and apply all KartScore changes
		for player, change in pairs(sTrack.ksChanges) do
			if player ~= nil then
				--muh sanity
				sTrack.checkNilPlayer(player)
				--print(player.." - "..tostring(change))
				sTrack.globalPlayerData[player][gameModeIndex] = sTrack.globalPlayerData[player][gameModeIndex] + change
				if sTrack.globalPlayerData[player][gameModeIndex] < 0 then
					--If you manage to hit 0 in an ELO system I'm legitimately impressed
					sTrack.globalPlayerData[player][gameModeIndex] = 0
				end
			end
		end
		
		--Notify players
		for p in players.iterate do
			if p.valid and p.mo ~= nil and p.mo.valid and sTrack.ksChanges[p.name] ~= nil then
				if sTrack.cv_showks.value == 0 or sTrack.cv_silentmode.value >= 1 then return end					
				local changeFormatted = "\x85"..tostring(sTrack.ksChanges[p.name])
				if tonumber(sTrack.ksChanges[p.name]) > 0 then
					changeFormatted = "\x83+"..tostring(sTrack.ksChanges[p.name])
				end
				chatprintf(p, "\x82KS - "..tostring(sTrack.globalPlayerData[p.name][gameModeIndex]).." ("..changeFormatted.."\x82)", false)
			end
		end
		sTrack.saveFiles("Player")	
	end
	
	if not didSaveTime then
		didSaveTime = true
		--Make sure no special game type is running
		if hasTimeSupport and sTrack.cv_enablerecords.value == 1 then
			if gamespeed == 0 and sTrack.globalEasyTimeData[tostring(gamemap)] == nil then
				sTrack.globalEasyTimeData[tostring(gamemap)] = {99999, "p", "h", 99999, "p", "h", 99999, "p", "h"}
			elseif gamespeed == 1 and sTrack.globalNormalTimeData[tostring(gamemap)] == nil then
				sTrack.globalNormalTimeData[tostring(gamemap)] = {99999, "p", "h", 99999, "p", "h", 99999, "p", "h"}
			elseif gamespeed == 2 and sTrack.globalHardTimeData[tostring(gamemap)] == nil then
				sTrack.globalHardTimeData[tostring(gamemap)] = {99999, "p", "h", 99999, "p", "h", 99999, "p", "h"}
			end
			
			if playerOrder[1] ~= nil and playerOrder[1][1] ~= nil then
				--Loop though the first position to condense names in case of ties
				local winList = ""
				for k, v in pairs(playerOrder[1])
					if winList == "" then
						winList = v
					else
						winList = $.." & "..v
					end				
				end
				
				for p in players.iterate do
					if p.valid and p.mo ~= nil and p.mo.valid and playerOrder[1][1] == p.name
						if gamespeed == 0 then
							if cMode == 2 and p.realtime < tonumber(sTrack.globalEasyTimeData[tostring(gamemap)][7]) then
								sTrack.globalEasyTimeData[tostring(gamemap)][7] = p.realtime
								sTrack.globalEasyTimeData[tostring(gamemap)][8] = winList
								sTrack.globalEasyTimeData[tostring(gamemap)][9] = p.mo.skin
							elseif cMode == 1 and p.realtime < tonumber(sTrack.globalEasyTimeData[tostring(gamemap)][4]) then
								sTrack.globalEasyTimeData[tostring(gamemap)][4] = p.realtime
								sTrack.globalEasyTimeData[tostring(gamemap)][5] = winList
								sTrack.globalEasyTimeData[tostring(gamemap)][6] = p.mo.skin
							elseif cMode == 0 and p.realtime < tonumber(sTrack.globalEasyTimeData[tostring(gamemap)][1]) then
								sTrack.globalEasyTimeData[tostring(gamemap)][1] = p.realtime
								sTrack.globalEasyTimeData[tostring(gamemap)][2] = winList
								sTrack.globalEasyTimeData[tostring(gamemap)][3] = p.mo.skin
							end
						elseif gamespeed == 1 then
							if cMode == 2 and p.realtime < tonumber(sTrack.globalNormalTimeData[tostring(gamemap)][7]) then
								sTrack.globalNormalTimeData[tostring(gamemap)][7] = p.realtime
								sTrack.globalNormalTimeData[tostring(gamemap)][8] = winList
								sTrack.globalNormalTimeData[tostring(gamemap)][9] = p.mo.skin
							elseif cMode == 1 and p.realtime < tonumber(sTrack.globalNormalTimeData[tostring(gamemap)][4]) then
								sTrack.globalNormalTimeData[tostring(gamemap)][4] = p.realtime
								sTrack.globalNormalTimeData[tostring(gamemap)][5] = winList
								sTrack.globalNormalTimeData[tostring(gamemap)][6] = p.mo.skin
							elseif cMode == 0 and p.realtime < tonumber(sTrack.globalNormalTimeData[tostring(gamemap)][1]) then
								sTrack.globalNormalTimeData[tostring(gamemap)][1] = p.realtime
								sTrack.globalNormalTimeData[tostring(gamemap)][2] = winList
								sTrack.globalNormalTimeData[tostring(gamemap)][3] = p.mo.skin
							end						
						elseif gamespeed == 2 then
							if cMode == 2 and p.realtime < tonumber(sTrack.globalHardTimeData[tostring(gamemap)][7]) then
								sTrack.globalHardTimeData[tostring(gamemap)][7] = p.realtime
								sTrack.globalHardTimeData[tostring(gamemap)][8] = winList
								sTrack.globalHardTimeData[tostring(gamemap)][9] = p.mo.skin
							elseif cMode == 1 and p.realtime < tonumber(sTrack.globalHardTimeData[tostring(gamemap)][4]) then
								sTrack.globalHardTimeData[tostring(gamemap)][4] = p.realtime
								sTrack.globalHardTimeData[tostring(gamemap)][5] = winList
								sTrack.globalHardTimeData[tostring(gamemap)][6] = p.mo.skin
							elseif cMode == 0 and p.realtime < tonumber(sTrack.globalHardTimeData[tostring(gamemap)][1]) then
								sTrack.globalHardTimeData[tostring(gamemap)][1] = p.realtime
								sTrack.globalHardTimeData[tostring(gamemap)][2] = winList
								sTrack.globalHardTimeData[tostring(gamemap)][3] = p.mo.skin
							end						
						end
					end
				end
			end
			
			sTrack.saveFiles("Time")	
		end
	end
end
addHook("IntermissionThinker", intThink)

local function think()
	if sTrack.cv_enabled.value == 0 then return end
	
	if leveltime < 3 then
		didSaveSkins = false
		completedRun = false
		playerOrder = {}
		timeList = {}
		DNFList = {}
		RSList = {}
		hmIntermission = false
		didSaveMap = false
		didSavePlayer = false
		didSaveTime = false	
		
		recordSkinColor = nil
		slideValue = -50
		slideRun = "stop"
		
		rTimeHolder = nil
		rPlayerHolder = nil
		rSkinHolder = nil
		rSkinColorHolder = nil
		
		for p in players.iterate do
			if p.valid and p.mo ~= nil then
				p.inRace = true
			elseif p.valid then
				p.inRace = false
			end
		end
		
		sTrack.ksChanges = {}
		cMode = sTrack.findCurrentMode()
		gameModeIndex = sTrack.getModeIndex()
	end
	
	if not completedRun then
		local allStopped = true
		
		for p in players.iterate do
			if p.valid and p.mo ~= nil and p.mo.valid then
				--Note player as currently racing
				if p.inRace == nil or p.inRace == false then
					p.inRace = true
				end			
				if p.exiting == 0 then
					if p.pflags & PF_TIMEOVER then
						--Someone DNF'd. Mark them down.
						if timeList[p.name] == nil and DNFList[p.name] == nil then
							DNFList[p.name] = true
						end
					else
						--Someone is still running
						allStopped = false
					end
				elseif p.exiting ~= 0 then
					--Someone stopped. Determine if winner and mark finished players.
					if timeList[p.name] == nil then
						timeList[p.name] = p.realtime
					end		
				end
			elseif p.valid and p.inRace == true and p.mo == nil and leveltime > 6*TICRATE + (3*TICRATE/4) + (20*TICRATE) then
				--This looks like a ragespec
				if RSList[p.name] == nil then
					--Save time since elimination triggers this for the guy that blew up in last
					RSList[p.name] = p.realtime
				end
				p.inRace = false
			elseif p.valid and p.inRace == nil and p.mo == nil then
				p.inRace = false
			end
			
			--Intermission score increase is hardcoded, the add won't match in vanilla
			--[[			
			if sTrack.cv_scoreboardKS.value == 1 and p.scoreSet == nil then
				--Replace player's score with the current mode's KS
				sTrack.checkNilPlayer(p.name)
				p.score = sTrack.globalPlayerData[p.name][gameModeIndex]
				p.scoreSet = true
			end
			]]--
		end		
		completedRun = allStopped
	end
	
	--Race is over, recalculate everyone's position in case of jankpoints
	if completedRun and playerOrder[1] == nil then
		local posPointer = 0
		local lastTime = 0
		for k,v in sTrack.spairs(timeList, function(t,a,b) return tonumber(t[b]) > tonumber(t[a]) end) do
			--k = playername, v = realtime
			if lastTime == v and playerOrder[posPointer] ~= nil then
				--This is a tie
				table.insert(playerOrder[posPointer], k)
			else
				posPointer = $ + 1
				playerOrder[posPointer] = {k}	
			end		
			lastTime = v
			--print(tostring(posPointer).." - "..k)
		end
		
		--Add DNFs		
		local dnfAdded = false
		for k, v in pairs(DNFList)
			if dnfAdded == false then
				posPointer = $ + 1
				dnfAdded = true
			end
			if playerOrder[posPointer] == nil then
				playerOrder[posPointer] = {k}
			else
				table.insert(playerOrder[posPointer], k)
			end
			--print("DNF - "..k)
		end
		
		--Add Ragespecs
		--Some special considerations for elim here
		posPointer = $ + 1
		for k, v in sTrack.spairs(RSList, function(t,a,b) return tonumber(t[b]) < tonumber(t[a]) end) do
			if playerOrder[posPointer] == nil then
				playerOrder[posPointer] = {k}
			else
				table.insert(playerOrder[posPointer], k)
			end
			if CV_FindVar("elimination") and CV_FindVar("elimination").value == 1 then
				posPointer = $ + 1
			end
			--print("Rage - "..k)
		end
	end
	
	--Handles showing the sliding new record popup
	--This would be better suited for intermission but there's no hud lua hook in there :(
	if completedRun and sTrack.cv_recordpopup.value == 1 and sTrack.cv_enablerecords.value == 1 and sTrack.cv_silentmode.value == 0 and slideRun == "stop" and hmIntermission == false then
		if playerOrder[1] ~= nil and playerOrder[1][1] ~= nil and sTrack.isTimeSupportedMode(playerOrder) then
			--Check for ties
			local winList = ""
			for k, v in pairs(playerOrder[1])
				if winList == "" then
					winList = v
				else
					winList = $.." & "..v
				end				
			end
			
			for p in players.iterate do
				if p.valid and p.mo ~= nil and p.mo.valid and playerOrder[1][1] == p.name
					if gamespeed == 0 then
						if sTrack.globalEasyTimeData[tostring(gamemap)] == nil then
							sTrack.globalEasyTimeData[tostring(gamemap)] = {99999, "p", "h", 99999, "p", "h", 99999, "p", "h"}
						end
						if (cMode == 2 and p.realtime < tonumber(sTrack.globalEasyTimeData[tostring(gamemap)][7])) or (cMode == 1 and p.realtime < tonumber(sTrack.globalEasyTimeData[tostring(gamemap)][4])) or (cMode == 0 and p.realtime < tonumber(sTrack.globalEasyTimeData[tostring(gamemap)][1])) then
							rTimeHolder = p.realtime
							rPlayerHolder = winList
							rSkinHolder = p.mo.skin
							rSkinColorHolder = p.skincolor
							slideRun = "left"
							S_StartSound(nil, skins[p.mo.skin].soundsid[SKSKPOWR])
						end
					elseif gamespeed == 1 then
						if sTrack.globalNormalTimeData[tostring(gamemap)] == nil then
							sTrack.globalNormalTimeData[tostring(gamemap)] = {99999, "p", "h", 99999, "p", "h", 99999, "p", "h"}
						end
						if (cMode == 2 and p.realtime < tonumber(sTrack.globalNormalTimeData[tostring(gamemap)][7])) or (cMode == 1 and p.realtime < tonumber(sTrack.globalNormalTimeData[tostring(gamemap)][4])) or (cMode == 0 and p.realtime < tonumber(sTrack.globalNormalTimeData[tostring(gamemap)][1])) then
							rTimeHolder = p.realtime
							rPlayerHolder = winList
							rSkinHolder = p.mo.skin
							rSkinColorHolder = p.skincolor
							slideRun = "left"
							S_StartSound(nil, skins[p.mo.skin].soundsid[SKSKPOWR])
						end
					elseif gamespeed == 2 then
						if sTrack.globalHardTimeData[tostring(gamemap)] == nil then
							sTrack.globalHardTimeData[tostring(gamemap)] = {99999, "p", "h", 99999, "p", "h", 99999, "p", "h"}
						end
						if (cMode == 2 and p.realtime < tonumber(sTrack.globalHardTimeData[tostring(gamemap)][7])) or (cMode == 1 and p.realtime < tonumber(sTrack.globalHardTimeData[tostring(gamemap)][4])) or (cMode == 0 and p.realtime < tonumber(sTrack.globalHardTimeData[tostring(gamemap)][1])) then
							rTimeHolder = p.realtime
							rPlayerHolder = winList
							rSkinHolder = p.mo.skin
							rSkinColorHolder = p.skincolor
							slideRun = "left"
							S_StartSound(nil, skins[p.mo.skin].soundsid[SKSKPOWR])
						end
					end

				end
			end	
		end
	end
	
	--Special handling for fake intermission
	if not (hm_intermissioncalc and hm_intermissioncalc()) then return end
	hmIntermission = true
    intThink()
end
addHook("ThinkFrame", think)

--This makes data accessable by players
local function netvars(net)
	sTrack.globalSkinData = net($)
	sTrack.globalMapData = net($)
	sTrack.globalPlayerData = net($)
	sTrack.globalEasyTimeData = net($)
	sTrack.globalNormalTimeData = net($)
	sTrack.globalHardTimeData = net($)
	sTrack.globalPlayerSkinUseData = net($)
	
	didMaint = net($)
end
addHook("NetVars", netvars)

--HUD Hooks

--Intermission isn't a set up hud hook for Kart, so this will have to do without jamming in crazy hacks
--If you do have crazy hacks, however, that concept may interest you
local function interShowNewRecord(v)
	if sTrack.cv_recordpopup.value == 0 or sTrack.cv_enabled.value == 0 or sTrack.cv_enablerecords.value == 0 or sTrack.cv_silentmode.value >= 1 then return end
	if slideRun ~= "stop" and hmIntermission == true then slideRun = "stop" end
	if slideRun ~= "stop" then		
		local stringTime = nil
		local recordHolder = nil
		local recordSkin = nil

		stringTime = sTrack.buildTimeString(rTimeHolder)
		recordHolder = rPlayerHolder
		recordSkin = rSkinHolder
			
		local rgHudOffset = 138
		local screenYSub = 50
		
		local scrwidth = v.width()/v.dupx();
		local winheight = v.height()/v.dupy();
		local windiff = ((winheight-200)/2)
		local right = ((scrwidth+75)/2);

		--Left this here for example of popup sliding in and out
		--local actualOffset = -50
		--[[if slideRun == "left" then
			slideValue = $ + 1
			if slideValue <= 0 then
				actualOffset = slideValue
			else
				actualOffset = 0
			end
			if slideValue > 300 then
				slideRun = "right"
			end
		elseif slideRun == "right" then
			slideValue = $ - 1
			if slideValue <= 0 then
				actualOffset = slideValue
			else
				actualOffset = 0
			end
			if slideValue < -50 then
				slideRun = "stop"
			end
		end]]--
		if slideValue < 0 then
			slideValue = $ + 2
		end
	
		if skins[recordSkin] ~= nil then
			if rSkinColorHolder == nil then
				v.draw((65-(slideValue*5))+right, ((winheight-windiff)-screenYSub), v.cachePatch(skins[recordSkin].facewant), flags, v.getColormap(recordSkin, skins[recordSkin].prefcolor))
			else
				v.draw((65-(slideValue*5))+right, ((winheight-windiff)-screenYSub), v.cachePatch(skins[recordSkin].facewant), flags, v.getColormap(recordSkin, rSkinColorHolder))
			end		
		end
		
		local headerWidth = v.stringWidth("NEW RECORD", flags)
		v.drawString((64-(slideValue*5))+(right - headerWidth), ((winheight-windiff)-48), "\x82NEW RECORD", flags)
		--Flashing text if slideValue is set to be a constantly incrementing value
		--[[if slideValue % 5 == 0 then
			v.drawString((64-(slideValue*5))+(right - headerWidth), ((winheight-windiff)-48), "\x82NEW RECORD", flags)
		else
			v.drawString((64-(slideValue*5))+(right - headerWidth), ((winheight-windiff)-48), "NEW RECORD", flags)
		end]]--
		
		local nameWidth = v.stringWidth(recordHolder, flags)
		v.drawString((64-(slideValue*5))+(right - nameWidth), ((winheight-windiff)-38), recordHolder, flags)
		
		local timeWidth = v.stringWidth(stringTime, flags)
		v.drawString((64-(slideValue*5))+(right - timeWidth), ((winheight-windiff)-28), stringTime, flags)
	end
end
hud.add(interShowNewRecord, game)

--Draw map + mode's record below current time (if it exists)
local function drawRecordTime(v, p)
	if sTrack.cv_enabled.value == 0 or sTrack.cv_showtime.value == 0 or sTrack.cv_enablerecords.value == 0 or sTrack.cv_silentmode.value >= 1 then return end
	
	local stringTime = nil
	local recordHolder = nil
	local recordSkin = nil
	--I'm not copying the correct table to a local variable here because that's initializing a HUGE variable every frame.
	if gamespeed == 0 then
		if sTrack.globalEasyTimeData[tostring(gamemap)] ~= nil then
			if gameModeIndex == 10 then
				stringTime = sTrack.buildTimeStringTable(sTrack.globalEasyTimeData[tostring(gamemap)][1])
				recordHolder = sTrack.globalEasyTimeData[tostring(gamemap)][2]
				recordSkin = sTrack.globalEasyTimeData[tostring(gamemap)][3]
			elseif gameModeIndex == 11 then
				stringTime = sTrack.buildTimeStringTable(sTrack.globalEasyTimeData[tostring(gamemap)][4])
				recordHolder = sTrack.globalEasyTimeData[tostring(gamemap)][5]
				recordSkin = sTrack.globalEasyTimeData[tostring(gamemap)][6]
			elseif gameModeIndex == 12 then
				stringTime = sTrack.buildTimeStringTable(sTrack.globalEasyTimeData[tostring(gamemap)][7])
				recordHolder = sTrack.globalEasyTimeData[tostring(gamemap)][8]
				recordSkin = sTrack.globalEasyTimeData[tostring(gamemap)][9]
			end
		end
	elseif gamespeed == 1 then
		if sTrack.globalNormalTimeData[tostring(gamemap)] ~= nil then
			if gameModeIndex == 10 then
				stringTime = sTrack.buildTimeStringTable(sTrack.globalNormalTimeData[tostring(gamemap)][1])
				recordHolder = sTrack.globalNormalTimeData[tostring(gamemap)][2]
				recordSkin = sTrack.globalNormalTimeData[tostring(gamemap)][3]
			elseif gameModeIndex == 11 then
				stringTime = sTrack.buildTimeStringTable(sTrack.globalNormalTimeData[tostring(gamemap)][4])
				recordHolder = sTrack.globalNormalTimeData[tostring(gamemap)][5]
				recordSkin = sTrack.globalNormalTimeData[tostring(gamemap)][6]
			elseif gameModeIndex == 12 then
				stringTime = sTrack.buildTimeStringTable(sTrack.globalNormalTimeData[tostring(gamemap)][7])
				recordHolder = sTrack.globalNormalTimeData[tostring(gamemap)][8]
				recordSkin = sTrack.globalNormalTimeData[tostring(gamemap)][9]
			end
		end
	elseif gamespeed == 2 then
		if sTrack.globalHardTimeData[tostring(gamemap)] ~= nil then
			if gameModeIndex == 10 then
				stringTime = sTrack.buildTimeStringTable(sTrack.globalHardTimeData[tostring(gamemap)][1])
				recordHolder = sTrack.globalHardTimeData[tostring(gamemap)][2]
				recordSkin = sTrack.globalHardTimeData[tostring(gamemap)][3]
			elseif gameModeIndex == 11 then
				stringTime = sTrack.buildTimeStringTable(sTrack.globalHardTimeData[tostring(gamemap)][4])
				recordHolder = sTrack.globalHardTimeData[tostring(gamemap)][5]
				recordSkin = sTrack.globalHardTimeData[tostring(gamemap)][6]
			elseif gameModeIndex == 12 then
				stringTime = sTrack.buildTimeStringTable(sTrack.globalHardTimeData[tostring(gamemap)][7])
				recordHolder = sTrack.globalHardTimeData[tostring(gamemap)][8]
				recordSkin = sTrack.globalHardTimeData[tostring(gamemap)][9]
			end
		end
	end

	
	--Hide temp stuff
	if recordHolder == 'p' then return end
	
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
			--OPPRNK font only has digits 0-9 so this is printed one at a time
			v.draw((49-(rgHudOffset*12))+right, ((winheight-windiff)-screenYSub), v.cachePatch(font.."0"..stringTime[1]), flags)
			v.draw((55-(rgHudOffset*12))+right, ((winheight-windiff)-screenYSub), v.cachePatch(font.."0"..stringTime[2]), flags)
			v.draw((63-(rgHudOffset*12))+right, ((winheight-windiff)-screenYSub), v.cachePatch("2STMNMK"), vflags)
			v.draw((69-(rgHudOffset*12))+right, ((winheight-windiff)-screenYSub), v.cachePatch(font.."0"..stringTime[3]), flags)
			v.draw((75-(rgHudOffset*12))+right, ((winheight-windiff)-screenYSub), v.cachePatch(font.."0"..stringTime[4]), flags)
			v.draw((83-(rgHudOffset*12))+right, ((winheight-windiff)-screenYSub), v.cachePatch("2STSCMK"), vflags)
			v.draw((89-(rgHudOffset*12))+right, ((winheight-windiff)-screenYSub), v.cachePatch(font.."0"..stringTime[5]), flags)
			v.draw((95-(rgHudOffset*12))+right, ((winheight-windiff)-screenYSub), v.cachePatch(font.."0"..stringTime[6]), flags)
			
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