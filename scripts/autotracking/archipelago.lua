
require("scripts/autotracking/item_mapping")
require("scripts/autotracking/location_mapping")
require("scripts/autotracking/hints_mapping")

-- The first integer is the team (mostly unused by Archipelago currently). The second integer is the slot number.
local GOAL_STATUS_FORMAT = "_read_client_status_%i_%i"
goal_status_key = nil

CUR_INDEX = -1
--SLOT_DATA = nil

SLOT_DATA = {}
COLLECTED_LOCATION_IDS = {}

function has_value (t, val)
    for i, v in ipairs(t) do
        if v == val then return 1 end
    end
    return 0
end

function dump_table(o, depth)
    if depth == nil then
        depth = 0
    end
    if type(o) == 'table' then
        local tabs = ('\t'):rep(depth)
        local tabs2 = ('\t'):rep(depth + 1)
        local s = '{'
        for k, v in pairs(o) do
            if type(k) ~= 'number' then
                k = '"' .. k .. '"'
            end
            s = s .. tabs2 .. '[' .. k .. '] = ' .. dump_table(v, depth + 1) .. ','
        end
        return s .. tabs .. '}'
    else
        return tostring(o)
    end
end

function onClear(slot_data)
    --SLOT_DATA = slot_data
    COLLECTED_LOCATION_IDS = {}

    -- Get and subscribe to changes in the player's status to track goal completion
    goal_status_key = string.format(GOAL_STATUS_FORMAT, Archipelago.TeamNumber, Archipelago.PlayerNumber)
    Archipelago:Get({goal_status_key})
    Archipelago:SetNotify({goal_status_key})

    CUR_INDEX = -1
    -- reset locations
    for _, location_array in pairs(LOCATION_MAPPING) do
        for _, location in pairs(location_array) do
            if location then
                local location_obj = Tracker:FindObjectForCode(location)
                if location_obj then
                    if location:sub(1, 1) == "@" then
                        location_obj.AvailableChestCount = location_obj.ChestCount
                    else
                        location_obj.Active = false
                    end
                end
            end
        end
    end
    -- reset items
    for _ap_id, item_pairs in pairs(ITEM_MAPPING) do
        for _, item_pair in ipairs(item_pairs) do
            local item_code = item_pair[1]
            -- local item_type = item_pair[2]
            local item_obj = Tracker:FindObjectForCode(item_code)
            if item_obj then
                if item_obj.Type == "toggle" then
                    item_obj.Active = false
                elseif item_obj.Type == "progressive" then
                    item_obj.CurrentStage = 0
                    item_obj.Active = false
                elseif item_obj.Type == "consumable" then
                    if item_obj.MinCount then
                        item_obj.AcquiredCount = item_obj.MinCount
                    else
                        item_obj.AcquiredCount = 0
                    end
                elseif item_obj.Type == "progressive_toggle" then
                    item_obj.CurrentStage = 0
                    item_obj.Active = false
                end
            end
        end
    end
    PLAYER_ID = Archipelago.PlayerNumber or -1
    TEAM_NUMBER = Archipelago.TeamNumber or 0
    SLOT_DATA = slot_data
    -- if Tracker:FindObjectForCode("autofill_settings").Active == true then
    --     autoFill(slot_data)
    -- end
    -- print(PLAYER_ID, TEAM_NUMBER)
    if Archipelago.PlayerNumber > -1 then

        HINTS_ID = "_read_hints_"..TEAM_NUMBER.."_"..PLAYER_ID
        Archipelago:SetNotify({HINTS_ID})
        Archipelago:Get({HINTS_ID})
    end
end

function onItem(index, item_id, item_name, player_number)
    if index <= CUR_INDEX then
        return
    end
    local is_local = player_number == Archipelago.PlayerNumber
    CUR_INDEX = index;
    local item = ITEM_MAPPING[item_id]
    if not item or not item[1] then
        --print(string.format("onItem: could not find item mapping for id %s", item_id))
        return
    end
    for _, item_pair in pairs(item) do
        item_code = item_pair[1]
        item_type = item_pair[2]
        local item_obj = Tracker:FindObjectForCode(item_code)
        if item_obj then
            if item_obj.Type == "toggle" then
                -- print("toggle")
                item_obj.Active = true
            elseif item_obj.Type == "progressive" then
                -- print("progressive")
                item_obj.Active = true
            elseif item_obj.Type == "consumable" then
                -- print("consumable")
                item_obj.AcquiredCount = item_obj.AcquiredCount + item_obj.Increment * (tonumber(item_pair[3]) or 1)
            elseif item_obj.Type == "progressive_toggle" then
                -- print("progressive_toggle")
                if item_obj.Active then
                    item_obj.CurrentStage = item_obj.CurrentStage + 1
                else
                    item_obj.Active = true
                end
            end
        else
            print(string.format("onItem: could not find object for code %s", item_code[1]))
        end
    end
end

--called when a location gets cleared
function onLocation(location_id, location_name)
    COLLECTED_LOCATION_IDS[location_id] = true
    local location_array = LOCATION_MAPPING[location_id]
    if not location_array or not location_array[1] then
        print(string.format("onLocation: could not find location mapping for id %s", location_id))
        return
    end

    for _, location in pairs(location_array) do
        local location_obj = Tracker:FindObjectForCode(location)
        -- print(location, location_obj)
        if location_obj then
            if location:sub(1, 1) == "@" then
                location_obj.AvailableChestCount = location_obj.AvailableChestCount - 1
            else
                location_obj.Active = true
            end
        else
            print(string.format("onLocation: could not find location_object for code %s", location))
        end
    end
end

function onEvent(key, value, old_value)
    updateEvents(value)
end

function onEventsLaunch(key, value)
    updateEvents(value)
end

-- this Autofill function is meant as an example on how to do the reading from slotdata and mapping the values to 
-- your own settings
-- function autoFill()
--     if SLOT_DATA == nil  then
--         print("its fucked")
--         return
--     end
--     -- print(dump_table(SLOT_DATA))

--     mapToggle={[0]=0,[1]=1,[2]=1,[3]=1,[4]=1}
--     mapToggleReverse={[0]=1,[1]=0,[2]=0,[3]=0,[4]=0}
--     mapTripleReverse={[0]=2,[1]=1,[2]=0}

--     slotCodes = {
--         map_name = {code="", mapping=mapToggle...}
--     }
--     -- print(dump_table(SLOT_DATA))
--     -- print(Tracker:FindObjectForCode("autofill_settings").Active)
--     if Tracker:FindObjectForCode("autofill_settings").Active == true then
--         for settings_name , settings_value in pairs(SLOT_DATA) do
--             -- print(k, v)
--             if slotCodes[settings_name] then
--                 item = Tracker:FindObjectForCode(slotCodes[settings_name].code)
--                 if item.Type == "toggle" then
--                     item.Active = slotCodes[settings_name].mapping[settings_value]
--                 else 
--                     -- print(k,v,Tracker:FindObjectForCode(slotCodes[k].code).CurrentStage, slotCodes[k].mapping[v])
--                     item.CurrentStage = slotCodes[settings_name].mapping[settings_value]
--                 end
--             end
--         end
--     end
-- end

local function checkGoalStatus(value)
    -- CLIENT_UNKNOWN = 0
    -- CLIENT_CONNECTED = 5
    -- CLIENT_READY = 10
    -- CLIENT_PLAYING = 20
    -- CLIENT_GOAL = 30
    if value == 30 then
        local goal_location = Tracker:FindObjectForCode("@Cantina/Goal/Slave I")
        goal_location.AvailableChestCount = goal_location.AvailableChestCount - 1
    else
        print(string.format("Current goal status is %s", value))
    end
end

function onNotify(key, value, old_value)
    print("onNotify", key, value, old_value)
    if key == HINTS_ID then
        if value ~= old_value then
            for _, hint in ipairs(value) do
                if hint.finding_player == Archipelago.PlayerNumber then
                    if hint.found then
                        updateHints(hint.location, true)
                    else
                        updateHints(hint.location, false)
                    end
                end
            end
        end
    elseif key == goal_status_key then
        checkGoalStatus(value)
    end
end

function onNotifyLaunch(key, value)
    print("onNotifyLaunch", key, value)
    if key == HINTS_ID then
        for _, hint in ipairs(value) do
            -- print("hint", hint, hint.found)
            -- print(dump_table(hint))
            if hint.finding_player == Archipelago.PlayerNumber then
                if hint.found then
                    updateHints(hint.location, true)
                else
                    updateHints(hint.location, false)
                end
            end
        end
    elseif key == goal_status_key then
        checkGoalStatus(value)
    end
end

function updateHints(locationID, clear)
    local item_codes = HINTS_MAPPING[locationID]

    for _, item_table in ipairs(item_codes, clear) do
        for _, item_code in ipairs(item_table) do
            local obj = Tracker:FindObjectForCode(item_code)
            if obj then
                if not clear then
                    obj.Active = true
                else
                    obj.Active = false
                end
            else
                print(string.format("No object found for code: %s", item_code))
            end
        end
    end
end

-- Taken from the Pokemon Platinum tracker and modified.
ScriptHost:AddOnLocationSectionChangedHandler("manual", function(section)
    if section.AvailableChestCount ~= 0 then -- this only works for 1 chest per section
        return
    end

    local sectionID = "@" .. section.FullID
    local apID = sectionIDToAPID[sectionID]

    -- The victory location is also a real AP location in manuals. While it should always contain our own Victory item,
    -- it is technically possible for the location to be sent manually through a server cheat command, so the goal check
    -- needs to run before deciding to early return if the location has already been collected.
    if sectionID == "@Cantina/Goal/Slave I" then
        if Tracker:ProviderCountForCode("5minikits") >= 54 then
            local res = Archipelago:StatusUpdate(Archipelago.ClientStatus.GOAL)
            if res then
                print("Sent Victory")
            else
                print("Error sending Victory")
            end
        end
    end

    if COLLECTED_LOCATION_IDS[apID] ~= nil then
        -- Location has been collected already (either by us or by !collect), don't sent it again.
        return
    end

    -- AP location cleared
    if apID ~= nil then
        local res = Archipelago:LocationChecks({apID})
        if res then
            print("Sent " .. tostring(apID) .. " for " .. tostring(sectionID))
            COLLECTED_LOCATION_IDS[apID] = true
        else
            print("Error sending " .. tostring(apID) .. " for " .. tostring(sectionID))
        end
    else
        print(tostring(sectionID) .. " is not an AP location")
    end
end)


-- ScriptHost:AddWatchForCode("settings autofill handler", "autofill_settings", autoFill)
Archipelago:AddClearHandler("clear handler", onClear)
Archipelago:AddItemHandler("item handler", onItem)
Archipelago:AddLocationHandler("location handler", onLocation)

Archipelago:AddSetReplyHandler("notify handler", onNotify)
Archipelago:AddRetrievedHandler("notify launch handler", onNotifyLaunch)



--doc
--hint layout
-- {
--     ["receiving_player"] = 1,
--     ["class"] = Hint,
--     ["finding_player"] = 1,
--     ["location"] = 67361,
--     ["found"] = false,
--     ["item_flags"] = 2,
--     ["entrance"] = ,
--     ["item"] = 66062,
-- } 
