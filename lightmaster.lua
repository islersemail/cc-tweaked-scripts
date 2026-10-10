local PROTOCOL = "islerrtopia_lights"
local HOSTNAME = "islerrtopia_lights_master"

local PULSE_TIME = 0.5

-- =========================================================
-- LIGHT CHANNELS
-- Each output sends only a short pulse because the actual
-- light circuits are controlled by external latch systems.
-- =========================================================

local CHANNELS = {
    CREATE = {
        side = "top",
        name = "CREATE AREA LIGHTS"
    },

    HALLWAY = {
        side = "bottom",
        name = "HALLWAY LIGHTS"
    },

    FARM = {
        side = "left",
        name = "FARM AREA LIGHTS"
    }
}

local MODEM_SIDE = "front"


-- =========================================================
-- MODEM SETUP
-- =========================================================

local function openModem()

    if peripheral.getType(MODEM_SIDE) == "modem" then
        if not rednet.isOpen(MODEM_SIDE) then
            rednet.open(MODEM_SIDE)
        end

        return true
    end

    -- Backup search in case modem gets moved later
    for _, side in ipairs({
        "top",
        "bottom",
        "left",
        "right",
        "front",
        "back"
    }) do

        if peripheral.getType(side) == "modem" then

            if not rednet.isOpen(side) then
                rednet.open(side)
            end

            return true
        end
    end

    return false
end


-- =========================================================
-- SAFETY
-- Make absolutely sure every controlled output begins OFF.
-- =========================================================

local function resetOutputs()

    for _, channel in pairs(CHANNELS) do
        redstone.setOutput(channel.side, false)
    end
end


-- =========================================================
-- PULSE
-- =========================================================

local function pulse(side)

    redstone.setOutput(side, true)

    sleep(PULSE_TIME)

    redstone.setOutput(side, false)
end


-- =========================================================
-- TOGGLE ONE LIGHT GROUP
-- =========================================================

local function toggleChannel(channelID)

    local channel = CHANNELS[channelID]

    if not channel then
        return false, "UNKNOWN CHANNEL"
    end

    pulse(channel.side)

    return true, channel.name
end


-- =========================================================
-- TOGGLE ALL
-- Pulses all three outputs simultaneously for exactly
-- 0.5 seconds.
-- =========================================================

local function toggleAll()

    for _, channel in pairs(CHANNELS) do
        redstone.setOutput(channel.side, true)
    end

    sleep(PULSE_TIME)

    for _, channel in pairs(CHANNELS) do
        redstone.setOutput(channel.side, false)
    end
end


-- =========================================================
-- STARTUP
-- =========================================================

term.clear()
term.setCursorPos(1, 1)

print("================================")
print("   ISLERRTOPIA LIGHT CONTROL")
print("================================")
print()

if not openModem() then
    print("ERROR: NO MODEM FOUND")
    print()
    print("Expected modem:")
    print("FRONT")
    return
end

resetOutputs()

pcall(function()
    rednet.unhost(PROTOCOL, HOSTNAME)
end)

rednet.host(PROTOCOL, HOSTNAME)

print("SYSTEM ONLINE")
print()
print("TOP    : CREATE AREA LIGHTS")
print("BOTTOM : HALLWAY LIGHTS")
print("LEFT   : FARM AREA LIGHTS")
print()
print("Pulse duration: " .. PULSE_TIME .. " sec")
print()
print("Waiting for tablet...")


-- =========================================================
-- MAIN NETWORK LOOP
-- =========================================================

while true do

    local sender, message =
        rednet.receive(PROTOCOL)

    if type(message) == "table"
    and message.type == "lights" then

        local command = message.command


        -- CREATE AREA ---------------------------------------

        if command == "TOGGLE_CREATE" then

            local success, name =
                toggleChannel("CREATE")

            rednet.send(
                sender,
                {
                    type = "lights_response",
                    success = success,
                    channel = "CREATE",
                    name = name
                },
                PROTOCOL
            )


        -- HALLWAY -------------------------------------------

        elseif command == "TOGGLE_HALLWAY" then

            local success, name =
                toggleChannel("HALLWAY")

            rednet.send(
                sender,
                {
                    type = "lights_response",
                    success = success,
                    channel = "HALLWAY",
                    name = name
                },
                PROTOCOL
            )


        -- FARM ----------------------------------------------

        elseif command == "TOGGLE_FARM" then

            local success, name =
                toggleChannel("FARM")

            rednet.send(
                sender,
                {
                    type = "lights_response",
                    success = success,
                    channel = "FARM",
                    name = name
                },
                PROTOCOL
            )


        -- ALL LIGHTS ----------------------------------------

        elseif command == "TOGGLE_ALL" then

            toggleAll()

            rednet.send(
                sender,
                {
                    type = "lights_response",
                    success = true,
                    channel = "ALL",
                    name = "ALL LIGHT GROUPS"
                },
                PROTOCOL
            )


        -- PING ----------------------------------------------

        elseif command == "PING" then

            rednet.send(
                sender,
                {
                    type = "lights_response",
                    success = true,
                    online = true
                },
                PROTOCOL
            )

        end
    end
end
