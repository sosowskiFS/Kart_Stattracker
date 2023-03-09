rawset(_G, "gTypeVoting", {})

/* Variables */
gTypeVoting.roundnumcounter = -1		-- The amount of rounds remaining to play
gTypeVoting.roundnumset = -1			-- The total amount of rounds set to play
local roundnummax = 7			-- The maximum possible amount of rounds to play at once.
local roundprepared = false	-- Whether or not PrepareNextRound needs to run.
local remindercounter = -1		-- Counter to display a chat message reminding players they can vote for certain gamemodes.
local remindercountermax = 50
local massesreminded = false	-- Whether or not the oblivious masses have been reminded that they can vote for certain gamemodes.
gTypeVoting.currentgametype = nil	-- The current gametype.
--Flags for randomized mods
local randomModActive = false -- Indicator that the random state is active
local currentMod = nil -- Save to make sure that a new roll doesn't just play the same thing as the last roll
local currentModDuration = 0 -- Value of 1-5 for current length of current mod
local RS_THINK, RS_VOTE, RS_INT = 1, 2, 3 -- Server status indicators not shamefully lifted from ATO because I wrote the fucking thing
local roundstatus = RS_THINK

local gametypes = {			-- Table of mod-specific values
	combi		= {name = "combi",		fullname = "Combi-Ring",	toggle = "combi_active",		suggestedrounds = 5},
	elimination	= {name = "elimination",fullname = "Elimination",	toggle = "elimination",			suggestedrounds = 5,	extracommand1 = "basenumlaps \"map default\"",	extracommand2 = "allowteamchange 1"},
	friendmod	= {name = "friendmod",	fullname = "Friendmod",		toggle = "fr_enabled",			suggestedrounds = 5},
	frontrun	= {name = "frontrun",	fullname = "Frontrun",		toggle = "frontrun_enabled",	suggestedrounds = 5,	extracommand1 = "basenumlaps \"map default\"",	extracommand3 = "basenumlaps 50"},
	hpmod		= {name = "hpmod",		fullname = "HPMod",			toggle = "hpmod_enabled",		suggestedrounds = 5},
	weather		= {name = "weather",	fullname = "Weathermod",	toggle = "weathermod",			suggestedrounds = 5},
	battle		= {name = "battle",	fullname = "Battle-Plus",		toggle = "kmp_battleaccel",		suggestedrounds = 5,	extracommand4 = "map mapb1 -gametype battle"}
	--nitrotech	= {name = "nitro",		fullname = "DriftNitro",	toggle = "driftnitro",			suggestedrounds = 5,	extracommand1 = "setmod juice",					extracommand3 = "setmod tech"},
	--nitrojuice	= {name = "juicenitro",	fullname = "DriftNitro (Juicebox)",	toggle = "driftnitro",	suggestedrounds = 5},
}
local current_gametype = ""
local current_rounds = ""

 /* Special print functions */
local function CheckServerPrint(player, printstring)
	if (player == server) then
		chatprint("\n\130* \128" .. printstring .. "\n", 1)
	else
		CONS_Printf(player, "\n" .. printstring .. "\n")
	end
end -- Close function

local function CheckHOSTMODPrint(player, commandname)
	if (CV_FindVar("hm_vote_timer")) then
		CONS_Printf(player, "Try using \'\130vote " .. commandname .. "\128\' instead!\n")
	else
		CONS_Printf(player, "\n") -- This is dumb but...
	end
end -- Close function

/*=======*/
/* Cvars */
/*=======*/

CV_RegisterVar({
	name = "GH_Reminder",
	defaultvalue = -1,
	flags = CV_CALL|CV_NETVAR,
	PossibleValue = {MIN = -1, MAX = 20},
	func = function(playerinput)
		remindercountermax = playerinput
	end -- Close function
})

CV_RegisterVar({
	name = "GH_RoundNumMax",
	defaultvalue = 7,
	flags = CV_CALL|CV_NETVAR,
	PossibleValue = {MIN = 1, MAX = 50},
	func = function(playerinput)
		roundnummax = playerinput
	end -- Close function
})

/*==========*/
/* Commands */
/*=======f===*/
COM_AddCommand("SetGametype", function(player, gametypeinput, roundnuminput)
	if (gametypeinput == nil and roundnuminput == nil) then -- Player types command with no inputs
		CONS_Printf(player, "\nSetGametype \130<Gametype> \135<Number of rounds>\n            \133*Required   \134Optional\n\n\128ExtendGametype \130<Number of rounds>\n               \133*Required\n\n\128ResetGametype\n\n\128The currently loaded gametypes are:\n")
		for k,v in pairs(gametypes)
			if (CV_FindVar(v.toggle)) then
				CONS_Printf(player, "\130" .. v.fullname .. " (" .. v.name .. ")")
			end
		end
		CONS_Printf(player, "\n")
		return
	end
	if (IsPlayerAdmin(player) or player == server) then
		if (gametypes[gametypeinput] and CV_FindVar(gametypes[gametypeinput].toggle)) then -- Check if gametypeinput exists
			if (gTypeVoting.roundnumcounter < 1) then -- Check if no other gametype is being played
				gTypeVoting.currentgametype = gametypeinput
				if (tonumber(roundnuminput) == nil) then
					gTypeVoting.roundnumcounter = gametypes[gTypeVoting.currentgametype].suggestedrounds
					gTypeVoting.roundnumset		= gametypes[gTypeVoting.currentgametype].suggestedrounds
				else
					gTypeVoting.roundnumcounter = max(min(tonumber(roundnuminput), roundnummax.value), 1)
					gTypeVoting.roundnumset		= max(min(tonumber(roundnuminput), roundnummax.value), 1)
					if (tonumber(roundnuminput) > roundnummax.value) then
						CONS_Printf(player, "Requested number of rounds is above the maximum allowed of " .. roundnummax.value)
					end
				end
				if (tonumber(gTypeVoting.roundnumcounter) == 1) then -- Pluralization check
					CheckServerPrint(player, gametypes[gTypeVoting.currentgametype].fullname .. " will be set for " .. gTypeVoting.roundnumcounter .. " round.")
				else
					CheckServerPrint(player, gametypes[gTypeVoting.currentgametype].fullname .. " will be set for " .. gTypeVoting.roundnumcounter .. " rounds.")
				end
				roundprepared = false
			else
				CheckServerPrint(player, "Please wait for this gametype to end before voting for another.\nYou can use \"\130ResetGametype\128\" to return to normal races.")
			end
		else
			CheckServerPrint(player, "This gametype does not exist or is not loaded.")
		end
	else
		CONS_Printf(player, "\nYou must be an admin to use this command.")
		CheckHOSTMODPrint(player, "SetGametype")
	end
end, 0)

COM_AddCommand("ExtendGametype", function(player, roundnuminput)
	if (tonumber(roundnuminput) == nil) then
		CONS_Printf(player, "\nExtendGametype \130<Number of rounds>\n               \133*Required\n")
	end
	if (IsPlayerAdmin(player) or player == server) then
		if (gTypeVoting.currentgametype) then -- Check if there's a gametype to extend
			if (tonumber(roundnuminput) == 0) then
				CheckServerPrint(player, "Ok...?")
			elseif (tonumber(roundnuminput) < 0) then
				CheckServerPrint(player, "You cannot shorten the current gamemode.\nYou can use \'\130ResetGametype\128\' to return to normal races.")
			else
				gTypeVoting.roundnumcounter	= min($ + tonumber(roundnuminput), roundnummax.value)
				gTypeVoting.roundnumset 	= min($ + tonumber(roundnuminput), roundnummax.value)
				CheckServerPrint(player, "The current gametype has been extended to " .. gTypeVoting.roundnumcounter .. " rounds.")
				roundprepared = false
			end
		else
			CheckServerPrint(player, "You must be playing a custom gamemode to extend it.")
		end
	else
		CONS_Printf(player, "\nYou must be an admin to use this command.")
		CheckHOSTMODPrint(player, "ExtendGametype")
	end
end, 0)

COM_AddCommand("ResetGametype", function(player)
	if (IsPlayerAdmin(player) or player == server) then
		gTypeVoting.roundnumcounter = -1
		roundprepared = false
		COM_BufInsertText(server, gametypes[gTypeVoting.currentgametype].toggle .. " Off")
		COM_BufInsertText(server, "basenumlaps \"map default\"")
		COM_BufInsertText(server, "karteliminatelast 1")
		current_gametype = ""
		if G_BattleGametype()
			COM_BufInsertText(server, "juicebox 1; kmp_growthbump 1; map map01 -gametype race")
		else
			COM_BufInsertText(server, "exitlevel")
		end
		
		
	else
		CONS_Printf(player, "\nYou must be an admin to use this command.")
		CheckHOSTMODPrint(player, "ResetGametype")
	end
 end, 0)

COM_AddCommand("DebugPrint", function(player)
	print("=== Current Gametype ===")
	print(gTypeVoting.currentgametype)
	print("==== Round Counters ====")
	print(gTypeVoting.roundnumcounter+1 .. " / " .. gTypeVoting.roundnumset+1)
	print("=== Round Prepared? ====")
	print(roundprepared)
end, 1)

local anonmaps = {
	killer = "map mapnn",
	hongkong = "map mapnq",
	meadow = "map mapno",
	jelly = "map mapdn",
	cake = "map mapdp",
	crack = "map mapdo",
	warehouse = "map mapdu",
	moto = "map maphz",
	chilly = "map mapdg",
	westopolis = "map mapt1",
	matrix = "map mapt2",
	gun = "map mapt3",
	comet = "map mapt4",
	geofront = "map mapdh",
	mansion = "map mapd3",
	skyscrapers = "map mapd4",
	canyon = "map mapd5",
	hyakki = "map mapij"
}

local mods = {
	vanilla = "juicebox 0;techonly 0;driftnitro off",
	juice = "juicebox 1;techonly 0;driftnitro off",
	juicebox = "juicebox 1;techonly 0;driftnitro off",
	tech = "juicebox 1;techonly 1;driftnitro off",
	nitro = "driftnitro on;juicebox 1;techonly 1",
	rings = "juicebox 0;techonly 0;driftnitro off",
	ring = "juicebox 0;techonly 0;driftnitro off",
}

COM_AddCommand("fixall", function(player)
	if (IsPlayerAdmin(player) or player == server) then
		gTypeVoting.roundnumcounter = -1
		roundprepared = false
		COM_BufInsertText(server, "basenumlaps \"map default\"")
		COM_BufInsertText(server, "allowteamchange 1")
		COM_BufInsertText(server, "karteliminatelast 1")
		COM_BufInsertText(server, "juicebox 1")
		COM_BufInsertText(server, "fr_enabled 0")
		COM_BufInsertText(server, "combi_active 0")
		COM_BufInsertText(server, "frontrun_enabled 0")
		COM_BufInsertText(server, "techonly 0")
		COM_BufInsertText(server, "driftnitro off")
		if (cv_dorings) and (cv_dorings == 1) then
			COM_BufInsertText(server, "togglerings")
		end
		
		randomModActive = false
		currentMod = nil
		currentModDuration = 0	
		current_gametype = ""
		COM_BufInsertText(server, "map map01 -gametype race")		
	else
		CONS_Printf(player, "\nYou must be an admin to use this command.")
		CheckHOSTMODPrint(player, "fixall")
	end
 end, 0)

COM_AddCommand("gtypesetup", function(player)
	if (IsPlayerAdmin(player) or player == server) then
		COM_BufInsertText(server, "wait 10;hm_votable resetgametype;hm_votable fixall;hm_votable setgametype;hm_votable extendgametype;wait 5;hm_votable setmod;hm_votable anonmap;hm_votable restartlevel;hm_votable randommod;wait 10;map map01")
	else
		CONS_Printf(player, "\nYou must be an admin to use this command.")
	end
 end, 0)


COM_AddCommand("anonmap", function(player, name)
	if (IsPlayerAdmin(player) or player == server) then
		if (name == nil) then
			chatprint("Anonmap Names: killer, hongkong, meadow, jelly, cake, crack, warehouse, moto, chilly, westopolis, matrix, gun, comet, geofront, mansion, skyscrapers, canyon, hyakki")
		elseif (anonmaps[name] == nil) then chatprint ("Anonmap Names: killer, hongkong, meadow, jelly, cake, crack, warehouse, moto, chilly, westopolis, matrix, gun, comet, geofront, mansion, skyscrapers, canyon, hyakki")
		else
			COM_BufInsertText(server, anonmaps[name])	
		end
	else
		CONS_Printf(player, "\nAvailable Maps: Killer, HongKong, Meadow, Jelly, Cake, Crack, Warehouse, Moto, Chilly, Westopolis, Matrix, GUN, Comet, Geofront, Mansion, Skyscrapers, Canyon, Hyakki")
	end
 end, 0)

COM_AddCommand("setmod", function(player, name)
	if (IsPlayerAdmin(player) or player == server) then
		if (randomModActive) then
			chatprint("How about you disable randommod first, you genetic rejects?")
		elseif (name == nil) then
			chatprint("Setmod Options: vanilla, juice, tech, nitro, rings")
		elseif (mods[name] == nil) then chatprint ("Setmod Options: vanilla, juice, tech, nitro, rings")
		else
			name = string.lower(name)
			if ((name == "rings" or name == "ring") and (cv_dorings == 0)) or ((name ~= "rings" and name ~= "ring") and (cv_dorings == 1)) then
				COM_BufInsertText(server, "togglerings")			
			end
			COM_BufInsertText(server, mods[name])
			COM_BufInsertText(server, "exitlevel")	
		end
	else
		CONS_Printf(player, "\nAvailable Options: Vanilla, Juice, Tech, Nitro, Rings")
	end
 end, 0)
 
 COM_AddCommand("randommod", function(player)
	if (IsPlayerAdmin(player) or player == server) then
		if not randomModActive then
			--Enable
			randomModActive = true
			chatprint("\130<RANDOM>\128 Random mods enabled. Shuffling begins next round.")
			if roundstatus == RS_VOTE or roundstatus == RS_INT then
				chatprint("\130<RANDOM>\128 (After this next race that is, because I can't do setup right now)")
			end
		else
			--Disable
			randomModActive = false
			currentMod = nil
			currentModDuration = 0
			chatprint("\130<RANDOM>\128 Random mods disabled. You're stuck playing this mod until you change it.")
		end
	else
		CONS_Printf(player, "\n YOU'RE NOT A JANNIE YOU FUCKING BITCH!")
	end
 end, 0)


local function vsg(p, ...)
	COM_BufAddText(p, "vote setgametype "..table.concat({...}, " "))
end
COM_AddCommand("vsg", vsg)

local function veg(p, ...)
	COM_BufAddText(p, "vote extendgametype "..table.concat({...}, " "))
end
COM_AddCommand("veg", veg)

local function vsm(p, ...)
	COM_BufAddText(p, "vote setmod "..table.concat({...}, " "))
end
COM_AddCommand("vsm", vsm)

/*===========*/
/* Functions */
/*===========*/
local function PrepareNextRound()
	if (roundprepared == false) then
		if (gTypeVoting.currentgametype) then -- Check if a gametype is set
			if (gTypeVoting.roundnumcounter == gTypeVoting.roundnumset) then -- Check if we need to turn it on
				COM_BufInsertText(server, gametypes[gTypeVoting.currentgametype].toggle .. " On")
				COM_BufInsertText(server, "karteliminatelast 0")
				
				current_gametype = gametypes[gTypeVoting.currentgametype].name
				
				if (gametypes[gTypeVoting.currentgametype].extracommand3) then COM_BufInsertText(server, gametypes[gTypeVoting.currentgametype].extracommand3) end
				if (gametypes[gTypeVoting.currentgametype].extracommand4) and not G_BattleGametype() then COM_BufInsertText(server, 'juicebox 0; kmp_growthbump 0; map mapb'..P_RandomRange(0, 9)..' -gametype battle') end
				if G_BattleGametype() and not (gametypes[gTypeVoting.currentgametype].extracommand4) then COM_BufInsertText(server, 'juicebox 1; kmp_growthbump 1; map map'..P_RandomRange(10, 30)..' -gametype race') end
			end
			if (gTypeVoting.roundnumcounter <= 0) then -- Check if we need to turn it off
				COM_BufInsertText(server, gametypes[gTypeVoting.currentgametype].toggle .. " Off")
				COM_BufInsertText(server, "karteliminatelast 1")
				if (gametypes[gTypeVoting.currentgametype].extracommand1) then COM_BufInsertText(server, gametypes[gTypeVoting.currentgametype].extracommand1) end
				if (gametypes[gTypeVoting.currentgametype].extracommand2) then COM_BufInsertText(server, gametypes[gTypeVoting.currentgametype].extracommand2) end
				if G_BattleGametype() then COM_BufInsertText(server, 'juicebox 1; kmp_growthbump 1; map map'..P_RandomRange(10, 30)..' -gametype race') end
				gTypeVoting.currentgametype = nil
				gTypeVoting.roundnumcounter = -1 -- Double make sure shit isn't fucked
				gTypeVoting.roundnumset = -1
				
				current_gametype = ""
			end
			if (gTypeVoting.currentgametype) then -- Check gTypeVoting.currentgametype again now that it's potentially been set
				gTypeVoting.roundnumcounter = $ - 1 -- Decrement Round Number
			end
		end
		roundprepared = true -- Finish preparing for the next round
	end
end -- Close function

local function ModExistsRemind()
	if (remindercounter <= 0 and massesreminded == false and remindercountermax.value != -1 and CV_FindVar("hm_vote_timer")) then
		chatprint("\n\130* \128You can vote for your favorite gamemodes with \134'vote setgametype <gamemode>'\128!\nType \134'setgametype' \128in the console to see which are loaded!\n", true)
		remindercounter = remindercountermax.value
		massesreminded = true
	end
end -- Close function

--Just updating the status variable don't mind me
local function ThinkFrame()
	roundstatus = RS_THINK
end

local function IntermissionThinker()
	if roundstatus != RS_INT and randomModActive then
		if currentModDuration <= 1 then
			-- Time to reroll
			currentModDuration = P_RandomRange(2, 5)
			local modRoll = P_RandomRange(1, 4)
			--1 - Tech
			--2 - Juice
			--3 - NITRO NITRO NITRO
			--4 - Rings
			if (currentMod == modRoll) then
				--Just played this, shunt it.
				currentMod = modRoll + 1
				if (currentMod > 4) then
					currentMod = 1
				end
			else
				currentMod = modRoll
			end
			--Mod now selected, do setup
			local pickedMod = nil
			
			if (currentMod == 1) then
				if cv_dorings == 1 then
					COM_BufInsertText(server, "togglerings")
				end
				COM_BufInsertText(server, mods["tech"])	
				pickedMod = "TECH"
			elseif (currentMod == 2) then
				if cv_dorings == 1 then
					COM_BufInsertText(server, "togglerings")
				end
				COM_BufInsertText(server, mods["juice"])			
				pickedMod = "JUICEBOX"
			elseif (currentMod == 3) then
				if cv_dorings == 1 then
					COM_BufInsertText(server, "togglerings")
				end
				COM_BufInsertText(server, mods["nitro"])			
				pickedMod = "NITRO"
			elseif (currentMod == 4) then
				if cv_dorings == 0 then
					COM_BufInsertText(server, "togglerings")
				end
				COM_BufInsertText(server, mods["rings"])			
				pickedMod = "RINGS"
			end
			
			chatprint("\130<RANDOM>\128 UP NEXT: \131"..pickedMod.."\128, running for \131"..tostring(currentModDuration).."\128 races.")
		else
			-- Just tick down
			currentModDuration = $ - 1
		end
	end
	roundstatus = RS_INT
end

local function VoteRandomMod()
	roundstatus = RS_VOTE
end

local function ResetVars()
	roundprepared = false
	massesreminded = false
	if (remindercounter > 0) then
		remindercounter = $ - 1
	end
	
	-- API usage, really ugly and hacky, but so's this whole game HEYO
	COM_BufInsertText(server, "servername gm:" .. current_gametype .. "||rn:" .. gTypeVoting.roundnumcounter)
end -- Close function

/* HUD function (((very scary))) */
local function RoundNumRemind(v, p)
	local hudfadeinoutflags = V_10TRANS * min(max(0, leveltime-(TICRATE*2)), 10)
	if (gTypeVoting.currentgametype) then -- Check if a gametype is even set
		if (gTypeVoting.roundnumcounter == 0) then -- Pluralization check
			v.drawString(160, 20, "\133FINAL \128round of " .. gametypes[gTypeVoting.currentgametype].fullname .. ".", V_SNAPTOTOP|V_ALLOWLOWERCASE|hudfadeinoutflags, "center")
		else
			v.drawString(160, 20, "\133" .. (gTypeVoting.roundnumcounter+1) .. " \128rounds of " .. gametypes[gTypeVoting.currentgametype].fullname .. " remaining.", V_SNAPTOTOP|V_ALLOWLOWERCASE|hudfadeinoutflags, "center")
		end
	end
end -- Close function

/*=======*/
/* Hooks */
/*=======*/
hud.add(RoundNumRemind,	"game")
addHook("VoteThinker",	PrepareNextRound)
addHook("VoteThinker",	ModExistsRemind)
addHook("VoteThinker",	VoteRandomMod)
addHook("ThinkFrame",   ThinkFrame)
addHook("IntermissionThinker", IntermissionThinker)
addHook("MapLoad",		ResetVars)

/* Netsync ya vars */
addHook("NetVars", function(n)
	gTypeVoting.currentgametype = n($)
	gTypeVoting.roundnumcounter = n($)
	gTypeVoting.roundnumset		= n($)
	roundprepared	= n($)
	remindercounter	= n($)
	randomModActive = n($)
	currentModDuration = n($)
	currentMod = n($)
	roundstatus = n($)
end)