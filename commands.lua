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

--Hard toggles for individual data catagories
--Disabling each will stop these items from being tracked & saved, which will save you server memory.
--Remember to also remove the noted files from your luafiles folder so they aren't loaded.

--Skins (Skincounter.txt | pSkinUse.txt)
sTrack.cv_enableskintracking = CV_RegisterVar({
	name = "st_enableskintracking",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff,
})

--Map play & rtv count (Mapdata.txt)
sTrack.cv_enablemaptracking = CV_RegisterVar({
	name = "st_enablemapcounttracking",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff,
})

--Map time records (EasyRecords.txt | NormalRecords.txt | HardRecords.txt)
sTrack.cv_enabletimerecordtracking = CV_RegisterVar({
	name = "st_enabletimerecordtracking",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff,
})

--General player data (Playerdata.txt)
sTrack.cv_enableplayertracking = CV_RegisterVar({
	name = "st_enableplayertracking",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff,
})

--Scorekeeper tracking (scorekeeper.txt)
sTrack.cv_enablescorekeeper = CV_RegisterVar({
	name = "st_enablescorekeeper",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff,
})
--For REALLY BIG misakes
sTrack.cv_enabledebug = CV_RegisterVar({
	name = "st_enabledebug",
	defaultvalue = 0,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff,
})

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
	if sTrack.cv_silentmode.value == 2 or sTrack.cv_enableplayertracking.value == 0 then return end
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
		CONS_Printf(p, "\x83"..pTarget.." \x80- "..tostring(pData[1]).." races")
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
		end
		CONS_Printf(p, tostring(pData[3]).." item hits | \x85"..tostring(pData[4]).." self or enviroment hits")
		CONS_Printf(p, "\x82"..tostring(pData[5]).." spinouts | \x87"..tostring(pData[6]).." times exploded | \x84"..tostring(pData[7]).." times squished")
		CONS_Printf(p, "Total playtime : "..tostring(hours).." hours, "..tostring(minutes).." minutes (est.)")
	end
end
COM_AddCommand("st_playerdata", st_playerdata)

local function st_mapdata(p, ...)
	if sTrack.cv_silentmode.value == 2 or sTrack.cv_enablemaptracking.value == 0 then return end
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
		local mData = sTrack.stringSplit(sTrack.globalMapData[mTarget])
		--timesPlayed, rtv
		CONS_Printf(p, "\x82"..tostring(mData[3]).." ("..tostring(mTarget)..")")	
		CONS_Printf(p, "\x83"..tostring(mData[1]).." plays | \x85"..tostring(mData[2]).." RTVs")
		
		local timeRecord = ""
		if sTrack.cv_enablerecords.value == 1 then
			if gamespeed == 0 then
				timeRecord = sTrack.stringSplit(sTrack.globalEasyTimeData[mTarget])
			elseif gamespeed == 1 then
				timeRecord = sTrack.stringSplit(sTrack.globalNormalTimeData[mTarget])
			elseif gamespeed == 2 then
				timeRecord = sTrack.stringSplit(sTrack.globalHardTimeData[mTarget])
			end
			
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
COM_AddCommand("st_mapdata", st_mapdata)

local function st_skindata(p, ...)
	if sTrack.cv_silentmode.value == 2 or sTrack.cv_enableskintracking.value == 0 then return end
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
		CONS_Printf(p, "Could not find skin (Use skin code or leave blank for current map)")
	else
		--just a count
		if skins[sTarget] then
			CONS_Printf(p, "\x82"..tostring(skins[sTarget].realname))
		else
			CONS_Printf(p, "\x82"..sTarget)
		end
		
		local skinRecord = sTrack.stringSplit(sTrack.globalSkinData[sTarget])
		CONS_Printf(p, tostring(skinRecord[1]).." weighted uses, "..tostring(skinRecord[3]).." total uses")
		if sTrack.globalPlayerSkinUseData[p.name] ~= nil then
			local tempTable = sTrack.pSkinDataStringSplit(sTrack.globalPlayerSkinUseData[p.name])
			if tempTable[sTarget] then
				CONS_Printf(p, "You've used this character "..tostring(tempTable[sTarget]).." times")
			end		
		end
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

//Scorekeeper's setscore function
COM_AddCommand("sk_setscore",function(p, thedude, amount)
	if not thedude then
		CONS_Printf(p, "\133Usage: \128'sk_setscore <name/node> <score>' - Sets the score of the player at the specified name or node.")
		return
	end
	
	local plyr = tonumber(thedude)
	local target = nil
	local results = {}

	if plyr~=nil and plyr>=0 then
		target = players[plyr]
	end
	if target == nil then
		for p in players.iterate
			if p and p.valid then //AHHH PARANOIA
				if string.find(p.name, thedude,1,true)~=nil then
					table.insert(results, p)
				end
			end
		end
		if #results > 1 then
			CONS_Printf(p, "\133Found more than one player matching that name. \128Be more specific or use a node:")
			for i=1,#results do
				CONS_Printf(p, results[i].name.." [Node "..#results[i].."]")
			end
			return
		elseif #results < 1 then
			CONS_Printf(p, "\133No players found by that name. \128(this command only works for players currently in-game)")
			return
		else
			target = results[1]
		end
	end

	if target and target.valid then
		local realscore = tonumber(amount)
		if realscore == nil then
			CONS_Printf(p, "\133Invalid score. \128Make sure to enclose player names that have spaces with quotations, or use a player node.")
			return
		end
		target.score = realscore
		target.skforcesave = true //forces score to save even if lower then what they currently have
		CONS_Printf(p, "Successfully set the score of "..target.name.." to "..realscore..". (You can use 'showscores' to verify)")
	end
end,1)