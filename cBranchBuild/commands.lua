--Admin commands
--Global enable, if checking to see if this addon exists, look at this.
--Will disable all hooks and leave commands running
sTrack.cv_enabled = CV_RegisterVar({
	name = "st_enabled",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff,
})

--Toggle for calculating KS
sTrack.cv_enableks = CV_RegisterVar({
	name = "st_enableks",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff,
})

--Toggle for recording time records
sTrack.cv_enablerecords = CV_RegisterVar({
	name = "st_enablerecords",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff,
})

--0 - disabled, 1 - Hides HUD elements, 2 - Hides HUD elements and blocks data lookup commands
sTrack.cv_silentmode = CV_RegisterVar({
	name = "st_silentmode",
	defaultvalue = 0,
	flags = CV_NETVAR,
	PossibleValue = {MIN = 0, MAX = 2},
})

--Toggle to remove wiped characters/maps during data maintenance
sTrack.cv_wiperemovedaddons = CV_RegisterVar({
	name = "st_wiperemovedaddons",
	defaultvalue = 0,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff,
})

--KS Calculations debug display
sTrack.cv_ksdebug = CV_RegisterVar({
	name = "st_ksdebug",
	defaultvalue = 0,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff,
})

--KS Calculations debug display
sTrack.cv_limitnetvar = CV_RegisterVar({
	name = "st_limitnetvar",
	defaultvalue = 0,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff,
})


--Toggle to replace in game score count with KartScore
--Intermission score increase is hardcoded, the add won't match in vanilla
--[[
sTrack.cv_scoreboardKS = CV_RegisterVar({
	name = "st_scoreboardKS",
	defaultvalue = 0,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff,
})
]]--

--Player commands
--Shows/Hides record time popup
sTrack.cv_recordpopup = CV_RegisterVar({
	name = "st_recordpopup",
	defaultvalue = 1,
	PossibleValue = CV_OnOff,
})

--Hides KS updates in player's chat
sTrack.cv_showks = CV_RegisterVar ({
	name = "st_showks",
	defaultvalue = 1,
	PossibleValue = CV_OnOff,
})

--Hides time on HUD
sTrack.cv_showtime = CV_RegisterVar ({
	name = "st_showtime",
	defaultvalue = 1,
	PossibleValue = CV_OnOff,
})

--Stops new record gloat from playing
sTrack.cv_recordsound = CV_RegisterVar ({
	name = "st_recordsound",
	defaultvalue = 1,
	PossibleValue = CV_OnOff,
})
 
--In game player data lookups
local function st_playerdata(p, ...)
	if sTrack.cv_silentmode.value == 2 then return end
	local pTarget = nil
	if not ... then
		--assume player is looking up themself
		pTarget = p.name
	else
		pTarget = table.concat({...}, " ")
	end
	
	if pTarget == "lobby" then
		--Show KS/races/wins for everyone currently playing
		local gameModeIndex = sTrack.getModeIndex()
		
		for pl in players.iterate do
			if pl.valid and sTrack.globalPlayerData[pl.name] ~= nil then
				local pData = sTrack.stringSplit(sTrack.globalPlayerData[pl.name])
				if sTrack.cv_enableks.value == 1 then
					CONS_Printf(p, "\x82"..pl.name.."\x84 "..pData[gameModeIndex].." KS \x80|\x83 "..pData[2].." wins \x80| "..pData[1].." races")
				else
					CONS_Printf(p, "\x83 "..pData[2].." wins \x80| "..pData[1].." races")
				end		
			end
		end
	elseif pTarget=="top" or pTarget == "top wins" then
		local stuffToSort = {}
		for k, v in pairs(sTrack.globalPlayerData) do
			local pData = sTrack.stringSplit(sTrack.globalPlayerData[k])
			stuffToSort[k] = tonumber(pData[2])	
		end
		local forCounter = 1
		for k,v in sTrack.spairs(stuffToSort, function(t,a,b) return t[b] < t[a] end) do
			CONS_Printf(p, tostring(forCounter).." - \x83"..k.." \x82 "..tostring(v).." wins")
			
			forCounter = forCounter + 1
			if forCounter > 15 then break end
		end
	elseif pTarget == "top ks" then
		if sTrack.cv_enableks.value == 0 then
			CONS_Printf(p, "This server has disabled KartScore.")
		else
			--Uses the current mode's KS
			local gameModeIndex = sTrack.getModeIndex()
			
			local stuffToSort = {}
			for k, v in pairs(sTrack.globalPlayerData) do
				local pData = sTrack.stringSplit(sTrack.globalPlayerData[k])
				stuffToSort[k] = tonumber(pData[gameModeIndex])
			end
			local forCounter = 1
			for k,v in sTrack.spairs(stuffToSort, function(t,a,b) return t[b] < t[a] end) do
				CONS_Printf(p, tostring(forCounter).." - \x83"..k.." \x82 "..tostring(v).." KartScore")
				
				forCounter = forCounter + 1
				if forCounter > 15 then break end
			end
		end
	elseif sTrack.globalPlayerData[pTarget] == nil then
		CONS_Printf(p, "Could not find player! (It's case sensitive or leave blank to see your stats)")
	else
		local pData = sTrack.stringSplit(sTrack.globalPlayerData[pTarget])
		--{mapsPlayed, wins, hits, selfHits, spinned, exploded, squished, second, third, elo, jElo, nElo}
		--Time assumption: 3 minutes 30 seconds per race
		--tfw no math library
		local playtime = 210 * tonumber(pData[1])
		local hours = FixedFloor((playtime / 3600) * FRACUNIT) / FRACUNIT
		local minutes = FixedFloor(((playtime % 3600) / 60) * FRACUNIT) / FRACUNIT
		if tonumber(pData[1]) > 0 then
			local winPercent = FixedInt(FixedRound(FixedDiv(pData[2], pData[1]) * 100))
			local podiumCount = pData[2] + pData[8] + pData[9]
			local podiumPercent = FixedInt(FixedRound(FixedDiv(podiumCount, pData[1]) * 100))
			CONS_Printf(p, "\x83"..pTarget.." \x80- "..tostring(pData[1]).." races, ~"..tostring(winPercent).."% wins, ~"..tostring(podiumPercent).."% podium finishes")
		else
			CONS_Printf(p, "\x83"..pTarget.." \x80- "..tostring(pData[1]).." races")
		end
		CONS_Printf(p, "\x82"..tostring(pData[2]).." 1st places \x80| \x86"..tostring(pData[8]).." 2nd places \x80| \x8D"..tostring(pData[9]).." 3rd places")

		if sTrack.cv_enableks.value == 1 then
			local kString = "KartScores - \x83"..tostring(pData[10]).." Vanilla "
			if CV_FindVar("techonly") then
				kString = "KartScores - \x83"..tostring(pData[10]).." Vanilla/Tech "
			end
			if CV_FindVar("juicebox") then
				kString = $ + "\x80| \x84"..tostring(pData[sTrack.jKSPointer]).." Juicebox "
			end
			if CV_FindVar("driftnitro") then
				kString = $ + "\x80| \x85"..tostring(pData[sTrack.nKSPointer]).." Nitro "
			end
			if CV_FindVar("elimination") then
				kString = $ + "\x80| \x86"..tostring(pData[sTrack.eKSPointer]).." Elimination "
			end
			if CV_FindVar("combi_active") then
				kString = $ + "\x80| \x87"..tostring(pData[sTrack.cKSPointer]).." Combi "
			end
			CONS_Printf(p, kString)
			
			kString = "\x85Highest KartScores \x80- \x83"..tostring(pData[15]).." Vanilla "
			if CV_FindVar("techonly") then
				kString = "\x85Highest KartScores \x80- \x83"..tostring(pData[15]).." Vanilla/Tech "
			end
			if CV_FindVar("juicebox") then
				kString = $.."\x80| \x84"..tostring(pData[sTrack.jKSPointer + 5]).." Juicebox "
			end
			if CV_FindVar("driftnitro") then
				kString = $.."\x80| \x85"..tostring(pData[sTrack.nKSPointer + 5]).." Nitro "
			end
			if CV_FindVar("elimination") then
				kString = $.."\x80| \x86"..tostring(pData[sTrack.eKSPointer + 5]).." Elimination "
			end
			if CV_FindVar("combi_active") then
				kString = $.."\x80| \x87"..tostring(pData[sTrack.cKSPointer + 5]).." Combi "
			end
			CONS_Printf(p, kString)
		end
		
		local uHitPerRace = 0
		local gotHitTotal = 0
		local gotHitPerRace = 0
		if tonumber(pData[1]) > 0 then
			uHitPerRace = FixedInt(FixedRound(FixedDiv(pData[3], pData[1])))
			gotHitTotal = pData[5] + pData[6] + pData[7]
			gotHitPerRace = FixedInt(FixedRound(FixedDiv(gotHitTotal, pData[1])))
		end	
		CONS_Printf(p, tostring(pData[3]).." item hits (~"..tostring(uHitPerRace).." per race) | \x85"..tostring(pData[4]).." self or enviroment hits")
		CONS_Printf(p, "\x82"..tostring(pData[5]).." spinouts | \x87"..tostring(pData[6]).." times exploded | \x84"..tostring(pData[7]).." times squished")
		CONS_Printf(p, "You get hit ~"..tostring(gotHitPerRace).." time(s) per race. Total playtime : "..tostring(hours).." hours, "..tostring(minutes).." minutes (est.)")
	end
end
COM_AddCommand("st_playerdata", st_playerdata)

local function st_mapdata(p, ...)
	if sTrack.cv_silentmode.value == 2 then return end
	if (sTrack.cv_limitnetvar.value and consoleplayer == server) or sTrack.cv_limitnetvar.value == 0 then
		local mTarget = nil
		if not ... then
			--assume player is looking up current map
			mTarget = gamemap
		else
			mTarget = table.concat({...})
		end
		mTarget = tostring(mTarget)
		
		if mTarget == "top" then
			local stuffToSort = {}
			for k, v in pairs(sTrack.globalMapData) do
				local mData = sTrack.stringSplit(sTrack.globalMapData[k])
				stuffToSort[k] = tonumber(mData[1])
			end
			local forCounter = 1
			for k,v in sTrack.spairs(stuffToSort, function(t,a,b) return t[b] < t[a] end) do
				if k ~= "1" then
					local mData = sTrack.stringSplit(sTrack.globalMapData[k])
					CONS_Printf(p, tostring(forCounter).." - \x82"..mData[3].." |\x83"..tostring(v).." plays | \x85"..tostring(mData[2]).." RTVs")
				
					forCounter = forCounter + 1
					if forCounter > 15 then break end
				end
			end
		elseif mTarget == "bottom" then
			local stuffToSort = {}
			for k, v in pairs(sTrack.globalMapData) do
				local mData = sTrack.stringSplit(sTrack.globalMapData[k])
				stuffToSort[k] = tonumber(mData[2])
			end
			local forCounter = 1
			for k,v in sTrack.spairs(stuffToSort, function(t,a,b) return t[b] < t[a] end) do
				if k ~= "1" then
					local mData = sTrack.stringSplit(sTrack.globalMapData[k])
					CONS_Printf(p, tostring(forCounter).." - \x82"..mData[3].." |\x85"..tostring(v).." RTVs | \x83"..tostring(mData[1]).." plays")
					
					forCounter = forCounter + 1
					if forCounter > 15 then break end
				end
			end
		else
			mTarget = sTrack.convertMapToInt(mTarget)
			if mTarget == -1 then
				CONS_Printf(p, "Invalid MapID")
				return
			end
			if sTrack.globalMapData[tostring(mTarget)] == nil then
				CONS_Printf(p, "Could not find map! (Use the map code or leave blank for current map)")
				return
			end
			local mData = sTrack.stringSplit(sTrack.globalMapData[tostring(mTarget)])
			--timesPlayed, rtv
			CONS_Printf(p, "\x82"..tostring(mData[3]).." ("..tostring(mTarget)..")")
			CONS_Printf(p, "\x83"..tostring(mData[1]).." plays | \x85"..tostring(mData[2]).." RTVs")
			
			if gamespeed == 0 then
				if sTrack.globalEasyTimeData[tostring(mTarget)] ~= nil and sTrack.cv_enablerecords.value == 1 then
					local timeRecord = sTrack.stringSplit(sTrack.globalEasyTimeData[mTarget])
					if timeRecord[2] ~= "p" then
						if CV_FindVar("techonly") then
							CONS_Printf(p, "Vanilla/Tech Record : "..sTrack.buildTimeString(timeRecord[1]).." by "..tostring(timeRecord[2]))
						else
							CONS_Printf(p, "Vanilla Record : "..sTrack.buildTimeString(timeRecord[1]).." by "..tostring(timeRecord[2]))
						end				
					end
					if sTrack.jTimePointer and timeRecord[sTrack.jTimePointer + 1] ~= "p" then
						CONS_Printf(p, "Juicebox Record : "..sTrack.buildTimeString(timeRecord[sTrack.jTimePointer]).." by "..tostring(timeRecord[sTrack.jTimePointer + 1]))
					end
					if sTrack.nTimePointer and timeRecord[sTrack.nTimePointer + 1] ~= "p" then
						CONS_Printf(p, "Nitro Record : "..sTrack.buildTimeString(timeRecord[sTrack.nTimePointer]).." by "..tostring(timeRecord[sTrack.nTimePointer + 1]))
					end
				end		
			elseif gamespeed == 1 then
				if sTrack.globalNormalTimeData[tostring(mTarget)] ~= nil and sTrack.cv_enablerecords.value == 1 then
					local timeRecord = sTrack.stringSplit(sTrack.globalNormalTimeData[mTarget])
					if timeRecord[2] ~= "p" then
						if CV_FindVar("techonly") then
							CONS_Printf(p, "Vanilla/Tech Record : "..sTrack.buildTimeString(timeRecord[1]).." by "..tostring(timeRecord[2]))
						else
							CONS_Printf(p, "Vanilla Record : "..sTrack.buildTimeString(timeRecord[1]).." by "..tostring(timeRecord[2]))
						end				
					end
					if sTrack.jTimePointer and timeRecord[sTrack.jTimePointer + 1] ~= "p" then
						CONS_Printf(p, "Juicebox Record : "..sTrack.buildTimeString(timeRecord[sTrack.jTimePointer]).." by "..tostring(timeRecord[sTrack.jTimePointer + 1]))
					end
					if sTrack.nTimePointer and timeRecord[sTrack.nTimePointer + 1] ~= "p" then
						CONS_Printf(p, "Nitro Record : "..sTrack.buildTimeString(timeRecord[sTrack.nTimePointer]).." by "..tostring(timeRecord[sTrack.nTimePointer + 1]))
					end
				end			
			elseif gamespeed == 2 then
				if sTrack.globalHardTimeData[tostring(mTarget)] ~= nil and sTrack.cv_enablerecords.value == 1 then
					local timeRecord = sTrack.stringSplit(sTrack.globalHardTimeData[mTarget])
					if timeRecord[2] ~= "p" then
						if CV_FindVar("techonly") then
							CONS_Printf(p, "Vanilla/Tech Record : "..sTrack.buildTimeString(timeRecord[1]).." by "..tostring(timeRecord[2]))
						else
							CONS_Printf(p, "Vanilla Record : "..sTrack.buildTimeString(timeRecord[1]).." by "..tostring(timeRecord[2]))
						end				
					end
					if sTrack.jTimePointer and timeRecord[sTrack.jTimePointer + 1] ~= "p" then
						CONS_Printf(p, "Juicebox Record : "..sTrack.buildTimeString(timeRecord[sTrack.jTimePointer]).." by "..tostring(timeRecord[sTrack.jTimePointer + 1]))
					end
					if sTrack.nTimePointer and timeRecord[sTrack.nTimePointer + 1] ~= "p" then
						CONS_Printf(p, "Nitro Record : "..sTrack.buildTimeString(timeRecord[sTrack.nTimePointer]).." by "..tostring(timeRecord[sTrack.nTimePointer + 1]))
					end
				end			
			end
		end
	else
		CONS_Printf(p, "Limited data mode on - map data not available.")
	end
end
COM_AddCommand("st_mapdata", st_mapdata)

local function st_skindata(p, ...)
	if sTrack.cv_silentmode.value == 2 then return end
	if (sTrack.cv_limitnetvar.value and consoleplayer == server) or sTrack.cv_limitnetvar.value == 0 then
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
			local stuffToSort = {}
			for k, v in pairs(sTrack.globalSkinData) do
				local sData = sTrack.stringSplit(sTrack.globalSkinData[k])
				stuffToSort[k] = tonumber(sData[1])
			end
			local forCounter = 1
			for k,v in sTrack.spairs(stuffToSort, function(t,a,b) return tonumber(t[b]) < tonumber(t[a]) end) do
				if skins[k] ~= nil then
					CONS_Printf(p, tostring(forCounter).." - \x82"..tostring(skins[k].realname).." - \x83"..tostring(v).." weighted uses")
				else
					CONS_Printf(p, tostring(forCounter).." - \x82"..k.." - \x83"..tostring(v).." weighted uses")
				end					
				forCounter = forCounter + 1
				if forCounter > 15 then break end
			end
		elseif sTrack.globalSkinData[sTarget] == nil then
			CONS_Printf(p, "Could not find skin (Use skin code or leave blank for current skin)")
		else
			--just a count
			if skins[sTarget] then
				CONS_Printf(p, "\x82"..tostring(skins[sTarget].realname))
			else
				CONS_Printf(p, "\x82"..sTarget)
			end
			
			local skinRecord = sTrack.stringSplit(sTrack.globalSkinData[sTarget])
			CONS_Printf(p, tostring(skinRecord[1]).." weighted uses, "..tostring(skinRecord[3]).." total uses")
			if sTrack.globalPlayerSkinUseData[p.name] ~= nil and sTrack.globalPlayerSkinUseData[p.name][sTarget] ~= nil then
				CONS_Printf(p, "You've used this character "..tostring(sTrack.globalPlayerSkinUseData[p.name][sTarget]).." times")
			end
		end
	else
		CONS_Printf(p, "Limited data mode on - skin data not available.")
	end
end
COM_AddCommand("st_skindata", st_skindata)

--Admin Commands

--Delete a map record (use this when a map updates and old records don't apply)
--BE. CAREFUL.
local function st_clearmaprecord(p, ...)
	if (IsPlayerAdmin(p) or p == server) then
		local mapID = table.concat({...})
		if mapID == nil or mapID == '' then
			CONS_Printf(p, "\nClears map time records and saves the changes to file immediately")
			CONS_Printf(p, "\nUsage: st_clearmaprecord [mapID], mapID can be numeric or extended format")
			CONS_Printf(p, "\n(DO NOT TYPO THE MAP ID - IT IS IRREVERSIBLY DESTRUCTIVE)")
			return
		end
		mapID = sTrack.convertMapToInt(mapID)
		if mapID == -1 then
			CONS_Printf(p, "\nInvalid MapID format. No changes have been made.")
			return
		end
		
		local didWork = false
		--mapheaderinfo[tostring(i)].lvlttl
		if sTrack.globalEasyTimeData[tostring(mapID)] then
			sTrack.globalEasyTimeData[tostring(mapID)] = sTrack.buildPlaceholderRecord()
			didWork = true
		end
		if sTrack.globalNormalTimeData[tostring(mapID)] then
			sTrack.globalNormalTimeData[tostring(mapID)] = sTrack.buildPlaceholderRecord()
			didWork = true
		end
		if sTrack.globalHardTimeData[tostring(mapID)] then
			sTrack.globalHardTimeData[tostring(mapID)] = sTrack.buildPlaceholderRecord()
			didWork = true
		end
		
		local MapData = sTrack.stringSplit(sTrack.globalMapData[tostring(mapID)])
		if didWork == false then
			if sTrack.globalMapData[tostring(mapID)] then
				CONS_Printf(p, "\nNo records found for "..MapData[3]..". No changes made.")
			else
				CONS_Printf(p, "\nNo records found for ID "..tostring(mapID)..". No changes made.")
			end
		else
			sTrack.saveFiles("Time")
			
			if sTrack.globalMapData[tostring(mapID)] then
				CONS_Printf(p, "\nRecords have been wiped for "..MapData[3]..".")
			else
				CONS_Printf(p, "\nRecords have been wiped for unloaded map with ID "..tostring(mapID)..".")
			end
		end		
	else
		CONS_Printf(p, "\nYou must be an admin to use this command.")
	end
end
COM_AddCommand("st_clearmaprecord", st_clearmaprecord)