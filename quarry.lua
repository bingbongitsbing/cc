---@diagnostic disable: undefined-field, undefined-global
---Original File from https://pastebin.com/u/King0fGamesYami
---Edited by m0rtis0 14.11.2021, Added Rednet + Fast waste algorithm
--[[
Use below List for defining waste blocks
Slot 15: Bucket
Slot 16: Fuel
]]--

local ok, tArgs, ignoredFuel, oldprint, fuelAmount = true, { ... }, 0, print, nil

local waste_blocks = {
    "minecraft:sand",
    "minecraft:dirt",
    "minecraft:stone",
    "minecraft:gravel",
    "minecraft:andesite",
    "minecraft:diorite",
    "minecraft:granite",
    "minecraft:torch",
    "minecraft:lava",
    "minecraft:water",
    "minecraft:cobblestone",
    "minecraft:prismarine_bricks",
    "minecraft:dark_prismarine",
    "minecraft:prismarine_wall",
    "minecraft:tall_seagrass",
    "minecraft:seagrass",
    "minecraft:oak_trapdoor",
    "tconstruct:molten_ender_fluid",
    "create:andesite_cobblestone",
    "create:diorite_cobblestone",
    "create:granite_cobblestone",
    "create:gabbro_cobblestone",
    "create:gabbro",
    "chisel:basalt/raw",
    "forbidden_arcanus:darkstone",
    "forbidden_arcanus:runestone",
    "extcaves:brokenstone",
    "darkerdepths:grimestone"
}


local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end


if peripheral.getType("left") ~= "modem" then
    print( "There is no wireless modem attached! Do you wish to continue? Y/N" )
		while true do
			local _, char = os.pullEvent( "char" )
			if char:lower() == "n" then
				error("Aborted.")
			elseif char:lower() == "y" then
				break
			end
		end
else
    print("Found wireless modem on 'left' slot, trying to open it ...")
    if pcall(rednet.open, "left") then
        print("Successfully opened, now broadcasting on Channel "..rednet.CHANNEL_BROADCAST)
        print("-- START BROADCAST --")
    else 
        print("Failed to open Channel, continue without modem? Y/N")
        while true do
			local _, char = os.pullEvent( "char" )
			if char:lower() == "n" then
				error("Aborted.")
			elseif char:lower() == "y" then
				break
			end
		end
    end
end


print( "You have defined the following as waste blocks: " )
for i,v in ipairs(waste_blocks) do print("  - "..v) end
print("Is this correct? Y/N")
while true do
    local _, char = os.pullEvent( "char" )
    if char:lower() == "n" then
        error("Aborted.")
    elseif char:lower() == "y" then
        break
    end
end


if turtle.getItemCount( 15 ) ~= 1 then
	error( "Place a single bucket in slot 15" )
end
if turtle.getItemCount( 16 ) == 0 then
	print( "Are you sure you wish to continue with no fuel in slot 16? Y/N" )
	while true do
		local _, char = os.pullEvent( "char" )
		if char:lower() == "n" then
			error("Aborted.")
		elseif char:lower() == "y" then
			break
		end
	end
end

local function print( text )
	oldprint( text )
	local file = fs.open( "turtleLog", "a" )
	file.writeLine( text )
	file.close()
    if rednet.isOpen("left") then
        pcall(rednet.broadcast, text)
    end
end

function dumpWaste()
	while ok do
        local num_dumped = 0
        print("[dumpWaste]: Will dump the following blocks:")
		for i = 1, 14 do -- only checks first 14 slots to preserve slot 15 and 16 logic
			local detail = turtle.getItemDetail( i )
			if detail then
                local isWaste = has_value(waste_blocks, detail.name)
                if isWaste then
                    turtle.select( i )
                    turtle.drop( turtle.getItemCount( i ) )
                    num_dumped = num_dumped + turtle.getItemCount( i )
                    print("[dumpWaste]: - "..detail.name.." (x"..turtle.getItemCount( i )..")")
                end
			end
		end
        if num_dumped == 0 then
            print("[dumpWaste]: No waste blocks to dump.")
        else
            print("[dumpWaste]: Dumped "..num_dumped.." blocks of waste!")
        end
		-- Wait and check again
		local id = os.startTimer( 20 )
		while true do
			local _, tid = os.pullEvent( "timer" )
			if tid == id then break end
		end
	end
end


function notwaste(func)
    local success, block = func()
    if success then
        -- If the block's name contains "ore", consider it not waste
        if string.find(block.name, "ore") then
            return true -- It's an ore, not waste
        else
            return false -- If it doesn't contain "ore", it's considered waste
        end
    end
    return false -- If no block is present, also consider it as waste
end


function check( nLevel )
	if not nLevel then
		nLevel = 1
	elseif nLevel > 40 then
		return
	end
	if not ok then return end
	--check for lava
	turtle.select( 14 )
	if turtle.getItemCount( 14 ) == 0 and not turtle.compare() and not turtle.detect() then
		turtle.select( 15 )
		if turtle.place() then
			print( "[check]: Liquid detected!" )
			if turtle.refuel() then
				print( "[check]: Refueled using lava source!" )
				turtle.forward()
				check( nLevel + 1 )
				while not turtle.back() do end
				ignoredFuel = ignoredFuel + 2
			else
				print( "[check]: Liquid was not lava!" )
				turtle.place()
			end
		end
	end
	--check for inventories
	if turtle.detect() and turtle.suck() then
		while turtle.suck() do end
	end
	--check for ore
	if notwaste( turtle.inspect ) then
        local _, ore = turtle.inspect()
		print( "[check]: Ore Detected! ("..ore.name..")" )
		repeat turtle.dig() until turtle.forward()
		print( "[check]: Dug ore!" )
		check( nLevel + 1 )
		while not turtle.back() do end
		ignoredFuel = ignoredFuel + 2
	end
	if not ok then return end
	turtle.turnLeft()
	--check for lava
	turtle.select( 14 )
	if turtle.getItemCount( 14 ) == 0 and not turtle.compare() and not turtle.detect() then
		turtle.select( 15 )
		if turtle.place() then
			print( "[check]: Liquid detected!" )
			if turtle.refuel() then
				print( "[check]: Refueled using lava source!" )
				turtle.forward()
				check( nLevel + 1 )
				while not turtle.back() do end
				ignoredFuel = ignoredFuel + 2
			else
				print( "[check]: Liquid was not lava!" )
				turtle.place()
			end
		end
	end
	--check for inventories
	if turtle.detect() and turtle.suck() then
		while turtle.suck() do end
	end
	--check for ore
	if notwaste( turtle.inspect ) then
        local _, ore = turtle.inspect()
		print( "[check]: Ore Detected! ("..ore.name..")" )
		repeat turtle.dig() until turtle.forward()
		print( "[check]: Dug ore!" )
		check( nLevel + 1 )
		while not turtle.back() do end
		ignoredFuel = ignoredFuel + 2
	end
	turtle.turnRight()
	if not ok then return end
	turtle.turnRight()
	--check for lava
	turtle.select( 14 )
	if turtle.getItemCount( 14 ) == 0 and not turtle.compare() and not turtle.detect() then
		turtle.select( 15 )
		if turtle.place() then
			print( "[check]: Liquid detected!" )
			if turtle.refuel() then
				print( "[check]: Refueled using lava source!" )
				turtle.forward()
				check( nLevel + 1 )
				while not turtle.back() do end
				ignoredFuel = ignoredFuel + 2
			else
				print( "[check]: Liquid was not lava!" )
				turtle.place()
			end
		end
	end
	--check for inventories
	if turtle.detect() and turtle.suck() then
		while turtle.suck() do end
	end
	--check for ore
	if notwaste( turtle.inspect ) then
        local _, ore = turtle.inspect()
		print( "[check]: Ore Detected! ("..ore.name..")" )
		repeat turtle.dig() until turtle.forward()
		print( "[check]: Dug ore!" )
		check( nLevel + 1 )
		while not turtle.back() do end
		ignoredFuel = ignoredFuel + 2
	end
	turtle.turnLeft()
	if not ok then return end
	--check for lava
	turtle.select( 14 )
	if turtle.getItemCount( 14 ) == 0 and not turtle.compareUp() and not turtle.detectUp() then
		turtle.select( 15 )
		if turtle.placeUp() then
			print( "[check]: Liquid detected!" )
			if turtle.refuel() then
				print( "[check]: Refueled using lava source!" )
				turtle.up()
				check( nLevel + 1 )
				while not turtle.down() do end
				ignoredFuel = ignoredFuel + 2
			else
				print( "[check]: Liquid was not lava!" )
				turtle.placeUp()
			end
		end
	end
	--check for inventories
	if turtle.detectUp() and turtle.suckUp() then
		while turtle.suckUp() do end
	end
	--check for ore
	if notwaste( turtle.inspectUp ) then
        local _, ore = turtle.inspectUp()
		print( "[check]: Ore Detected! ("..ore.name..")" )
		repeat turtle.digUp() until turtle.up()
		print( "[check]: Dug ore!" )
		check( nLevel + 1 )
		while not turtle.down() do end
		ignoredFuel = ignoredFuel + 2
	end
	if not ok then return end
	--check for lava
	turtle.select( 14 )
	if turtle.getItemCount( 14 ) == 0 and not turtle.compareDown() and not turtle.detectDown() then
		turtle.select( 15 )
		if turtle.placeDown() then
			print( "[check]: Liquid detected!" )
			if turtle.refuel() then
				print( "[check]: Refueled using lava source!" )
				turtle.down()
				check( nLevel + 1 )
				while not turtle.up() do end
				ignoredFuel = ignoredFuel + 2
			else
				print( "[check]: Liquid was not lava!" )
				turtle.placeDown()
			end
		end
	end
	--check for inventories
	if turtle.detectDown() and turtle.suckDown() then
		while turtle.suckDown() do end
	end
	--check for ore
	if notwaste( turtle.inspectDown ) then
        local _, ore = turtle.inspectDown()
		print( "[check]: Ore Detected! ("..ore.name..")" )
		repeat turtle.digDown() until turtle.down()
		print( "[check]: Dug ore!" )
		check( nLevel + 1 )
		while not turtle.up() do end
		ignoredFuel = ignoredFuel + 2
	end
end

function quarryLayer()
    local gone = 0
    for i = 1, 25 do -- Adjust the 25 to change the length of each layer
        repeat turtle.dig() until turtle.forward()
        print("[quarryLayer]: Dug layer at pos ["..gone.."]!")
        gone = gone + 1
        if not ok then break end
        check()
        if not ok then break end
    end
    print("[quarryLayer]: Layer complete!")
    turtle.turnLeft()
    turtle.turnLeft()
    for i = 1, gone do
        while not turtle.forward() do
            while turtle.dig() do end
            while turtle.attack() do end
        end
    end
    ignoredFuel = ignoredFuel + (gone * 2)
    print("[quarryLayer]: Returned to start of layer!")
end

function main()
    local depth = 0
    while ok do
        print("[main]: Starting new layer")
        quarryLayer()
        if not ok then break end
        print("[main]: Moving down to next layer")
        if turtle.digDown() then
            depth = depth + 1
            if depth >= 10 then -- Adjust the 10 to change the depth of the quarry
                ok = false
                print("[main]: Reached maximum quarry depth, returning")
            end
        else
            ok = false
            print("[main]: Can't move down further, returning")
        end
    end
    -- Return to surface
    print("[main]: Returning to surface!")
    for i = 1, depth do
        while not turtle.up() do
            while turtle.digUp() do end
            while turtle.attackUp() do end
        end
    end
    print("[main]: Back at surface!")
end

function findMaxLevel()
	local level = turtle.getFuelLevel()
	if turtle.getItemCount( 16 ) > 1 then
		if not fuelAmount then
			turtle.select( 16 )
			turtle.refuel( 1 )
			fuelAmount = turtle.getFuelLevel() - level
			print( "[findMaxLevel]: Found fuelAmount: "..fuelAmount)
		end
		print( "[findMaxLevel]: Found max level: " .. turtle.getItemCount( 16 ) * fuelAmount + turtle.getFuelLevel() .. "!")
		return turtle.getItemCount( 16 ) * fuelAmount + turtle.getFuelLevel()
	else
		print( "[findMaxLevel]: Found max level: " .. turtle.getFuelLevel() .. "!" )
		return turtle.getFuelLevel()
	end
end

function isOk()
	local okLevel = findMaxLevel() / 2 + 10
	while ok do
		local currentLevel = turtle.getFuelLevel()
		if currentLevel < 100 then --check fuel
			print( "[isOk]: Fuel Level Low!" )
			if turtle.getItemCount( 16 ) > 0 then
				print( "[isOk]: Refueling!" )
				repeat
					turtle.select( 16 )
				until turtle.refuel( 1 ) or turtle.getSelectedSlot() == 16
				if turtle.getFuelLevel() > currentLevel then
					print( "[isOk]: Refuel Successful!" )
				else
					print( "[isOk]: Refuel Unsuccessful, Initiating return!" )
					ok = false
				end
			end
		elseif okLevel - ignoredFuel > findMaxLevel()  then
			print("[isOk]: Fuel Reserves Depleted!  Initiating return!")
			ok = false
		end
		--make sure turtle can take new items
		local hasSpace = false
		for i = 1, 15 do
			if turtle.getItemCount( i ) == 0 then
				hasSpace = true
			end
		end
        local manualInterrupt = false
        --Listen for RedNet manual interrupts
        if rednet.isOpen("left") then
            --Listen for RET
            local _, msg = rednet.receive(nil, 0.1)
            if msg == "RET" then
                manualInterrupt = true
            end
        end
		if not hasSpace then
			print( "[isOk]: Out of space!  Intiating return!" )
			ok = false
        end
        if manualInterrupt then
            print("[isOk]: Manual return requested!, Returning..")
            ok = false
		elseif ok then
			print( "[isOk]: Everything is OK!" )
			local id = os.startTimer( 10 )
			while true do
				local _, tid = os.pullEvent( "timer" )
				if tid == id then
					break
				end
			end
		end
	end
end


function trackTime()
	local sTime = table.concat( tArgs, " " )
	local nSeconds = 0
	for i, period in sTime:gmatch( "(%d+)%s+(%a+)s?" ) do
		if period:lower() == "second" then
			nSeconds = nSeconds + i
		elseif period:lower() == "minute" then
			nSeconds = nSeconds + ( i * 60 )
		elseif period:lower() == "hour" then
			nSeconds = nSeconds + ( i * 3600 )
		end
	end
	print( "[trackTime]: Starting timer for "..nSeconds.." seconds!" )
	local id = os.startTimer( nSeconds )
	while ok do
		local _, tid = os.pullEvent( "timer" )
		if id == tid then
			print( "[trackTime]: End of session reached!  Returning to base!" )
			ok = false
		end
	end
end

parallel.waitForAll( trackTime, isOk, dumpWaste, main )
for i = 1, 14 do
	turtle.select( i )
	turtle.dropDown()
end