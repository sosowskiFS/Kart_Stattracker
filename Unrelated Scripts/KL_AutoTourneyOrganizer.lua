--Automates handling of tourney sets
--By Onyo

--Stuff to import
--NVJR console score printout
--NVJR map list script

--TODO
--Start Random set, input = duration

--          Script vars
local tourneyMapList = {}
local raceNumber = 1
local totalMaps = 0
local tourneyInSet = false
local didAnnounce = false
local clearscoreflag = false
local RS_THINK, RS_VOTE, RS_INT = 1, 2, 3
local roundstatus = RS_THINK

--          General use functions

--Converts MAPXX format into full integer values
local function ConvertMapID(mapID)
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

--Verify that the inputted map set has valid IDs, and the map actually exists before starting
local function VerifyMapSet(player, inputTable)
	if inputTable == nil then
		CONS_Printf(player, "\nNo map ID found! Enter Map IDs, seperated by spaces.")
		CONS_Printf(player, "\nEX: ATO_StartSet map24 mapa3 map21 map1")
		return false
	end
	--Assemble table of maps
	local mapList = {}
	local count = 0
	for k, v in ipairs(inputTable) do
		local holder = ConvertMapID(v)
		if holder != -1 then
			table.insert(mapList, holder)
			count = $ + 1
		else
			CONS_Printf(player, tostring(v).." is an invalid MapID")
			return false
		end
	end	
	--Verify that each item is selecting a valid map
	for _, mapID in ipairs(mapList) do
		if mapheaderinfo[tostring(mapID)] == nil then
			CONS_Printf(player, "\nMap ID "..tostring(mapID).." was not found. Set not started.")
			return false
		end
	end
	--Load the validated data and begin the set
	tourneyMapList = mapList
	totalMaps = count
	raceNumber = 1
	tourneyInSet = true
	didAnnounce = false
	return true
end

--          Commands
--I wonder what this does
local function ClearScores(player)
	if (IsPlayerAdmin(player) or player == server) then
		COM_BufInsertText(server, "clearscores")
		chatprint("\133<TOURNEY> Scores have been reset", true)
	else
		CONS_Printf(player, "\nYou must be an admin to use this command.")	
		return
	end
end
COM_AddCommand("ATO_ClearScores", ClearScores)

local function StartSet(player, ...)
	if (IsPlayerAdmin(player) or player == server) then
		if tourneyInSet then
			CONS_Printf(player, "\nA tourney is already running. Use ATO_ClearSet to stop it.")	
			return
		end
		if roundstatus == RS_VOTE then
			CONS_Printf(player, "\nCan't run this on the vote screen - code flags won't set correctly.")	
			return	
		end
		local checkTable = {...}
		if VerifyMapSet(player, checkTable) then
			chatprint("\133<TOURNEY> A set is starting!", true)
			chatprint("\133<TOURNEY> Set now running for ".. tostring(totalMaps).." maps!", true)
			
			clearscoreflag = true
			COM_BufInsertText(server, "exitlevel")
		end		
	else
		CONS_Printf(player, "\nYou must be an admin to use this command.")	
	end
end
COM_AddCommand("ATO_StartSet", StartNitroSet)

local function ClearSet(player)
	if (IsPlayerAdmin(player) or player == server) and tourneyInSet then
		tourneyMapList = {}
		tourneyInSet = false
		didAnnounce = false
		COM_BufInsertText(server, "csay Tourney set has been cancelled")
		CONS_Printf(player, "\nTourney set has been cancelled")	
	else
		CONS_Printf(player, "\nThere is no active set or you are not an admin.")	
	end
end
COM_AddCommand("ATO_ClearSet", ClearSet)

--          Hooks

local function ThinkFrame()
	if tourneyInSet and roundstatus != RS_THINK then
		--Progress the tourney
		didAnnounce = false
		table.remove(tourneyMapList, 1)
		if clearscoreflag == true then
			--Wipe scores at the start of the first round
			COM_BufInsertText(server, "ATO_ClearScores")
			clearscoreflag = false
		end
	end
	
	roundstatus = RS_THINK
end
addHook("ThinkFrame", ThinkFrame)

local function IntermissionThinker()
	roundstatus = RS_INT
	
	if tourneyInSet then
		if not didAnnounce and raceNumber < totalMaps then
			didAnnounce = true
			chatprint("\133<TOURNEY> Up Next: "..mapheaderinfo[tostring(tourneyMapList[1])].lvlttl, true)
		elseif raceNumber >= totalMaps then
			chatprint("\133<TOURNEY> THE SET HAS CONCLUDED! \x82Let's see who won!", true)
			didAnnounce = true
			tourneyInSet = false
		end	
	end
end
addHook("IntermissionThinker", IntermissionThinker)

local function VoteThinker()
	if roundstatus != RS_VOTE and tourneyInSet then
		if raceNumber < totalMaps then
			--Timer has ended, move to next map
			raceNumber = $ + 1	
			local nextMap = tourneyMapList[1]		
			if raceNumber >= totalMaps then
				chatprint("\133<TOURNEY> LAST RACE OF THE SET!", true)	
			else
				chatprint("\133<TOURNEY> Race #"..tostring(raceNumber).." of "..tostring(totalMaps), true)	
			end				
			COM_BufInsertText(server, "map "..tostring(nextMap))	
		end
	end
	roundstatus = RS_VOTE
end
addHook("VoteThinker", VoteThinker)

--          Netsyncs
--Just sync everything, don't risk it when it comes to a tourney
addHook("NetVars", function(n)
	tourneyMapList = n($)
	raceNumber = n($)
	totalMaps = n($)
	tourneyInSet = n($)
	didAnnounce = n($)
	clearscoreflag = n($)
	roundstatus = n($)
end)

