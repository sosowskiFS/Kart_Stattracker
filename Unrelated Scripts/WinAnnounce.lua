--CHANGE ME
--Write in all of your sounds here
--ex your sound file in the pack is DSLAST1, write "sfx_last1" here
freeslot("sfx_sdndth","sfx_last1","sfx_last2","sfx_last3","sfx_last4","sfx_last5")

--CHANGE ME
--Remember, use the internal skin name here! Not the display name. Find it in a skin's S_SKIN file in their respective package. You want the stuff after "name = "
--Format: name = soundID
local announceList = {sonic = sfx_kc3d, racer2 = sfx_kc3d, racer3 = sfx_kc3d }
	
--Variables to make this do the thing
local announcedRaceWinner = false
local timeList = {}
local playerOrder = {}
local timeToAnnounce = nil

--CHANGE ME
--Play around with this to change when the win announcement happens!
local announceDelay = 3*TICRATE
	
--Sorts data in a table
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

local function sortPlayers()
	local posPointer = 0
	local lastTime = 0
	playerOrder = {}
	for k,v in spairs(timeList, function(t,a,b) return tonumber(t[b]) > tonumber(t[a]) end) do
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
end

--Game thinker, executes once every mid race tick
local function think()
	--Assuming you only care about announcing the winner, this check stops this loop after it finds a winner to announce
	if announcedRaceWinner == false then
		for p in players.iterate do
			--Check for validity, ignore spectators
			if p.valid and p.mo ~= nil and p.mo.valid then		
				if p.exiting ~= 0 then
					--Someone stopped. Determine if winner and mark finished players.
					if timeList[p.name] == nil then
						timeList[p.name] = p.realtime
						--Sort player order
						sortPlayers()
						--Set delay
						timeToAnnounce = leveltime + announceDelay
					end		
				end
			end
		end
	end

	--If winner found, announce it
	if playerOrder[1] ~= nil and playerOrder[1][1] ~= nil and announcedRaceWinner == false and leveltime >= timeToAnnounce then
		--Set this immediately so in case of error it doesn't blow people's ears out
		announcedRaceWinner = true
		--Have to loop through players again to find our winner
		for p in players.iterate do
			--Check if this is the player and also if there's a sound file for their skin
			if p.valid and p.mo ~= nil and p.mo.valid and playerOrder[1][1] == p.name and announceList[p.mo.skin] ~= nil
				S_StartSound(nil, announceList[p.mo.skin], p)
				S_StartSoundAtVolume(nil, announceList[p.mo.skin], 155)
			end
		end
	end
end
addHook("ThinkFrame", think)

--Triggers once during map change, reset variables
local function durMapChange()
	announcedRaceWinner = false
	timeList = {}
	playerOrder = {}
	timeToAnnounce = nil
end
addHook("MapChange", durMapChange)