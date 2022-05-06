--Admin commands
--Global enable, if checking to see if this addon exists, look at this.
--Will disable all hooks and leave commands running
sTrack.cv_enabled = CV_RegisterVar({
	name = "st_enabled",
	defaultvalue = 1,
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff,
})

--Shows/Hides record time popup for all players
--Possibly needs to be a netvar idk
sTrack.cv_recordpopup = CV_RegisterVar({
	name = "st_recordpopup",
	defaultvalue = 1,
	PossibleValue = CV_OnOff,
})

--Player commands
--Hides KS updates in player's chat
sTrack.cv_showks = CV_RegisterVar ({
	name = "st_showks"
	defaultvalue = 1,
	PossibleValue = CV_OnOff
})

--Hides time on HUD
sTrack.cv_showtime = CV_RegisterVar ({
	name = "st_showtime"
	defaultvalue = 1,
	PossibleValue = CV_OnOff
})
 
--In game player data lookups
local function st_playerdata(p, ...)
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
				CONS_Printf(p, "\x82"..pl.name.."\x84 "..sTrack.globalPlayerData[pl.name][gameModeIndex].." KS \x80|\x83 "..sTrack.globalPlayerData[pl.name][2].." wins \x80| "..sTrack.globalPlayerData[pl.name][1].." races")
			end
		end
	elseif pTarget=="top" or pTarget == "top wins" then
		local stuffToSort = {}
		for k, v in pairs(sTrack.globalPlayerData) do
			stuffToSort[k] = tonumber(v[2])	
		end
		local forCounter = 1
		for k,v in sTrack.spairs(stuffToSort, function(t,a,b) return t[b] < t[a] end) do
			CONS_Printf(p, tostring(forCounter).." - \x83"..k.." \x82 "..tostring(v).." wins")
			
			forCounter = forCounter + 1
			if forCounter > 10 then break end
		end
	elseif pTarget == "top ks" then
		--Uses the current mode's ELO
		local gameModeIndex = sTrack.getModeIndex()
		
		local stuffToSort = {}
		for k, v in pairs(sTrack.globalPlayerData) do
			stuffToSort[k] = tonumber(v[gameModeIndex])
		end
		local forCounter = 1
		for k,v in sTrack.spairs(stuffToSort, function(t,a,b) return t[b] < t[a] end) do
			CONS_Printf(p, tostring(forCounter).." - \x83"..k.." \x82 "..tostring(v).." KartScore")
			
			forCounter = forCounter + 1
			if forCounter > 10 then break end
		end
	elseif sTrack.globalPlayerData[pTarget] == nil then
		CONS_Printf(p, "Could not find player! (It's case sensitive or leave blank to see your stats)")
	else
		--{mapsPlayed, wins, hits, selfHits, spinned, exploded, squished, second, third, elo, jElo, nElo}
		--Time assumption: 3 minutes 30 seconds per race
		--tfw no math library
		local playtime = 210 * tonumber(sTrack.globalPlayerData[pTarget][1])
		local hours = FixedFloor((playtime / 3600) * FRACUNIT) / FRACUNIT
		local minutes = FixedFloor(((playtime % 3600) / 60) * FRACUNIT) / FRACUNIT
		CONS_Printf(p, "\x83"..pTarget.." \x80- "..tostring(sTrack.globalPlayerData[pTarget][1]).." races")
		CONS_Printf(p, "\x82"..tostring(sTrack.globalPlayerData[pTarget][2]).." 1st places \x80| \x86"..tostring(sTrack.globalPlayerData[pTarget][8]).." 2nd places \x80| \x8D"..tostring(sTrack.globalPlayerData[pTarget][9]).." 3rd places")
		CONS_Printf(p, "KartScores - \x83"..tostring(sTrack.globalPlayerData[pTarget][10]).." Vanilla/Tech \x80| \x84"..tostring(sTrack.globalPlayerData[pTarget][11]).." Juicebox \x80| \x85"..tostring(sTrack.globalPlayerData[pTarget][12]).." Nitro")
		CONS_Printf(p, tostring(sTrack.globalPlayerData[pTarget][3]).." item hits | \x85"..tostring(sTrack.globalPlayerData[pTarget][4]).." self or enviroment hits")
		CONS_Printf(p, "\x82"..tostring(sTrack.globalPlayerData[pTarget][5]).." spinouts | \x87"..tostring(sTrack.globalPlayerData[pTarget][6]).." times exploded | \x84"..tostring(sTrack.globalPlayerData[pTarget][7]).." times squished")
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
		local stuffToSort = {}
		for k, v in pairs(sTrack.globalMapData) do
			stuffToSort[k] = tonumber(v[1])
		end
		local forCounter = 1
		for k,v in sTrack.spairs(stuffToSort, function(t,a,b) return t[b] < t[a] end) do
			if mapheaderinfo[k] and k ~= "1" then
				CONS_Printf(p, tostring(forCounter).." - \x82"..mapheaderinfo[k].lvlttl.." |\x83"..tostring(v).." plays | \x85"..tostring(sTrack.globalMapData[k][2]).." RTVs")
			
				forCounter = forCounter + 1
				if forCounter > 10 then break end
			end
		end
	elseif mTarget == "bottom" then
		local stuffToSort = {}
		for k, v in pairs(sTrack.globalMapData) do
			stuffToSort[k] = tonumber(v[2])
		end
		local forCounter = 1
		for k,v in sTrack.spairs(stuffToSort, function(t,a,b) return t[b] < t[a] end) do
			if mapheaderinfo[k] and k ~= "1" then	
				CONS_Printf(p, tostring(forCounter).." - \x82"..mapheaderinfo[k].lvlttl.." |\x85"..tostring(v).." RTVs | \x83"..tostring(sTrack.globalMapData[k][1]).." plays")
				
				forCounter = forCounter + 1
				if forCounter > 10 then break end
			end
		end
	elseif sTrack.globalMapData[mTarget] == nil then
		CONS_Printf(p, "Could not find map! (Use the map code or leave blank for current map)")
	else
		--timesPlayed, rtv
		CONS_Printf(p, "\x82"..tostring(mapheaderinfo[mTarget].lvlttl).." ("..tostring(mTarget)..")")
		CONS_Printf(p, "\x83"..tostring(sTrack.globalMapData[mTarget][1]).." plays | \x85"..tostring(sTrack.globalMapData[mTarget][2]).." RTVs")
		
		if sTrack.globalTimeData[mTarget] ~= nil then
			if sTrack.globalTimeData[mTarget][2] ~= "placeholder" then
				CONS_Printf(p, "Vanilla/Tech Record : "..buildTimeString(globalTimeData[mTarget][1]).." by "..tostring(sTrack.globalTimeData[mTarget][2]))
			end
			if sTrack.globalTimeData[mTarget][5] ~= "placeholder" then
				CONS_Printf(p, "Juicebox Record : "..buildTimeString(sTrack.globalTimeData[mTarget][4]).." by "..tostring(sTrack.globalTimeData[mTarget][5]))
			end
			if sTrack.globalTimeData[mTarget][8] ~= "placeholder" then
				CONS_Printf(p, "Nitro Record : "..buildTimeString(sTrack.globalTimeData[mTarget][7]).." by "..tostring(sTrack.globalTimeData[mTarget][8]))
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
		local stuffToSort = {}
		for k, v in pairs(sTrack.globalSkinData) do
			stuffToSort[k] = tonumber(v[1])
		end
		local forCounter = 1
		for k,v in sTrack.spairs(stuffToSort, function(t,a,b) return tonumber(t[b]) < tonumber(t[a]) end) do
			if skins[k] ~= nil then
				CONS_Printf(p, tostring(forCounter).." - \x82"..tostring(skins[k].realname).." - \x83"..tostring(v).." weighted uses")
			else
				CONS_Printf(p, tostring(forCounter).." - \x82"..k.." - \x83"..tostring(v).." weighted uses")
			end					
			forCounter = forCounter + 1
			if forCounter > 10 then break end
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
		
		CONS_Printf(p, tostring(sTrack.globalSkinData[sTarget][1]).." weighted uses, "..tostring(sTrack.globalSkinData[sTarget][3]).." total uses")
	end
end
COM_AddCommand("st_skindata", st_skindata)