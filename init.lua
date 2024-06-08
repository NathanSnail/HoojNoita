dofile_once( "data/scripts/lib/utilities.lua" )



local pollnet = require('mods\\hoojMod\\pollnet')
local json = require('mods\\hoojMod\\json')


-- Reactor is a convenience for running Lua coroutines
local reactor = pollnet.Reactor()

-- all functions below are optional and can be left out

function OnModPreInit()
	print("Hooj - OnModPreInit()") -- First this is called for all mods
end

function OnModInit()
	print("Hooj - OnModInit()") -- After that this is called for all mods


	-- Connect to hooj eventstream
	-- https://overlay.woohooj.in/stream/?channel=events
	reactor:run(function()
		local req_sock = pollnet.open_tcp("69.55.54.58:80")
		req_sock:send("GET /stream/?channel=simple-chat HTTP/1.1\r\nHost: overlay.woohooj.in\r\nUser-Agent: curl/7.85.0\r\nAccept: */*\r\n\r\n")

		while true do
			local response = req_sock:await()
			if type(response) ~= "string" then
				goto continue
			end

			local found_start = false
			local start_index = 0
			local end_index = 0

			local index = 1
			for c in response:gmatch"." do
				if (c == "{" and not found_start) then
					start_index = index
					found_start = true
				end

				if (c == "}") then
					end_index = index
				end

				index = index + 1
			end

			if start_index == 0 or end_index == 0 then
				goto continue
			end

			local payload = string.sub(response, start_index, end_index)
			local decoded = json.decode(payload)

			local content = decoded.content
			local author = decoded.author_id

			print(content)

			::continue::
		end
	end)

	-- Print chat messages
end

function OnModPostInit()
	StreamingSetVotingEnabled(true)
end

--[[
function OnPlayerSpawned( player_entity ) -- This runs when player entity has been created
	GamePrint( "OnPlayerSpawned() - Player entity id: " .. tostring(player_entity) )
end

function OnWorldInitialized() -- This is called once the game world is initialized. Doesn't ensure any world chunks actually exist. Use OnPlayerSpawned to ensure the chunks around player have been loaded or created.
	GamePrint( "OnWorldInitialized() " .. tostring(GameGetFrameNum()) )
end

function OnWorldPreUpdate() -- This is called every time the game is about to start updating the world
	GamePrint( "Pre-update hook " .. tostring(GameGetFrameNum()) )
end

]]--

function OnWorldPostUpdate() -- This is called every time the game has finished updating the world
	GamePrint( "Post-update hook " .. tostring(GameGetFrameNum()) )
	reactor:update()
end


function OnMagicNumbersAndWorldSeedInitialized() -- this is the last point where the Mod* API is available. after this materials.xml will be loaded.
	local x = ProceduralRandom(0,0)
	print( "===================================== random " .. tostring(x) )
end


-- This code runs when all mods' filesystems are registered
ModLuaFileAppend( "data/scripts/gun/gun_actions.lua", "mods/example/files/actions.lua" ) -- Basically dofile("mods/example/files/actions.lua") will appear at the end of gun_actions.lua
ModMagicNumbersFileAdd( "mods/example/files/magic_numbers.xml" ) -- Will override some magic numbers using the specified file

-- see tools_modding/noita_fmod_project/ for the project that defines the audio events used in this mod
ModRegisterAudioEventMappings( "mods/example/files/audio_events.txt" ) -- Use this to register custom fmod events. Event mapping files can be generated via File -> Export GUIDs in FMOD Studio.
ModRegisterMusicBank( "mods/example/files/music.bank" ) -- Use this to register custom banks in the music system. ModRegisterAudioEventMappings also needs to be called to make the game recognize the events.

ModMaterialsFileAdd( "mods/example/files/materials_rainbow.xml" ) -- Adds a new 'rainbow' material to materials
ModLuaFileAppend( "data/scripts/items/potion.lua", "mods/example/files/potion_appends.lua" )

-- make coalmine play music from the new bank
local coal_xml = ModTextFileGetContent( "data/biome/coalmine.xml" )
coal_xml = coal_xml:gsub([[audio_music_2="coalmine"]], [[audio_music_2="thebiome"]] )
ModTextFileSetContent( "data/biome/coalmine.xml", coal_xml )


if ModImageMakeEditable ~= nil then -- needed to avoid error if this file is hotloaded after init
	-- make the player sprite green
	local t1 = GameGetRealWorldTimeSinceStarted();

	local recolor = function( filename)
		local id,w,h = ModImageMakeEditable( filename, 0, 0 )
		for y=0,h do
			for x=0,w do
				local c = ModImageGetPixel( id, x, y )
				local r,g,b,a = color_abgr_split( c )
				r = r / 2
				b = b / 2
				c = color_abgr_merge(r,g,b,a)
				ModImageSetPixel( id, x, y, c )
			end
		end
	end

	-- using different slots here to test the feature works,
	-- but you could use the same slot when editing images independent of each other like this
	recolor( "data/enemies_gfx/player.png" )
	recolor( "data/enemies_gfx/player_arm.png" )
	recolor( "data/enemies_gfx/player_arm_no_item.png" )

	t1 = GameGetRealWorldTimeSinceStarted() -t1
	print("ModImage stuff took " .. t1 .. " seconds")

	local who_edited = ModImageWhoSetContent( "data/enemies_gfx/player.png" )
	local ok = " - fail"
	if who_edited == "example" then ok = " - ok" end

	print( "Who edited? " .. who_edited .. ok )
end

--print("Example mod init done")