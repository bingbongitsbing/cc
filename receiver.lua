---@diagnostic disable: undefined-global, undefined-field
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
        print("Successfully opened, now receiving on Channel "..rednet.CHANNEL_BROADCAST)
        print("-- START RECEIVER --")
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

local ret = false

while true do
    local event, id, text = os.pullEvent()
    if event == "rednet_message" then
        local msg = text
        if msg ~= nil then
            print(msg)
        end
    end
    if event == "key" then
        if id == 84 and not ret then
            ret = true
            print("-- INITIATING RETURN --")
            while true do
                rednet.broadcast("RET")
                local _, msg_loop = rednet.receive()
                print(msg_loop)
                if string.find(msg_loop, "[main]: Returning to base!",nil,true) then
                    ret = false
                    print("-- RETURN INITIATED --")
                    break
                end
            end
        end
    end
    rednet.broadcast("ACK")
end

