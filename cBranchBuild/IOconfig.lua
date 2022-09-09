local loaded = false

-- store commands, we'll iterate through this to create a config if necessary
local commands = {
	{sTrack.cv_recordpopup, "Shows/Hides record time popup"}, 
	{sTrack.cv_showks, "Shows/Hides KS updates"}, 
	{sTrack.cv_showtime, "Shows/Hides record time in game HUD"},
	{sTrack.cv_recordsound, "Plays/Mutes record time skin gloat audio"}, 
}

addHook("ThinkFrame", do
	if (loaded) then return end
	
	-- create/load the config!
	local config = io.open("stattracker.cfg", "r")
	if not (config)	-- no config? create one.
		config = io.open("stattracker.cfg", "w")	-- create it.
			
		-- write all our defaults to it.
		for i = 1, #commands
			local command = commands[i][1]
			local command_desc = commands[i][2]
				
			config:write(command.name.." "..command.defaultvalue.." // "..command_desc.."\n")
		end
			
		CONS_Printf(consoleplayer, "\x83NOTICE:\x80 stattracker.cfg not found, created a config in \x82/luafiles\x80.")
	else	-- we got a config, load it!
		for line in config:lines()
			COM_BufInsertText(consoleplayer, line)
		end
		CONS_Printf(consoleplayer, "\x83NOTICE:\x80 Successfully loaded stattracker.cfg!")
	end
	config:close()
		
	-- set this to true, we dont wanna do this again.
	loaded = true
end)