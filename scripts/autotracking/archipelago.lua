
require("scripts/autotracking/item_mapping")
require("scripts/autotracking/location_mapping")

-- Disabled until PopTracker 0.32.0 is released, which adds section highlighting.
-- local HIGHLIGHT_LEVEL = {
--     [0] = Highlight.Unspecified,
--     [10] = Highlight.NoPriority,
--     [20] = Highlight.Avoid,
--     [30] = Highlight.Priority,
--     [40] = Highlight.None,
-- }

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
    local already_reset = {}
    for _ap_id, item_pairs in pairs(ITEM_MAPPING) do
        for _, item_pair in ipairs(item_pairs) do
            local item_code = item_pair[1]
            -- local item_type = item_pair[2]
            if already_reset[item_code] == nil then
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
                already_reset[item_code] = true
            end
        end
    end
    PLAYER_ID = Archipelago.PlayerNumber or -1
    TEAM_NUMBER = Archipelago.TeamNumber or 0
    SLOT_DATA = slot_data

    local version = slot_data["apworld_version"] or {0, 1, 0}
    local major = version[1]
    local minor = version[2]
    local patch = version[3]
    -- Version (0,2,0) added the ability to change the goal amount
    local goal_amount
    if major > 0 or (major == 0 and minor >= 2) then
        goal_amount = slot_data["minikit_goal_amount"]
    else
        goal_amount = 270
    end
    Tracker:FindObjectForCode("minikits_for_goal").AcquiredCount = goal_amount
    -- if Tracker:FindObjectForCode("autofill_settings").Active == true then
    --     autoFill(slot_data)
    -- end
    -- print(PLAYER_ID, TEAM_NUMBER)

    -- Hint tracking disabled until PopTracker 0.32.0 is released, which adds section highlighting.
--     if Archipelago.PlayerNumber > -1 then
--
--         HINTS_ID = "_read_hints_"..TEAM_NUMBER.."_"..PLAYER_ID
--         Archipelago:SetNotify({HINTS_ID})
--         Archipelago:Get({HINTS_ID})
--     end
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
                if item_obj.Active then
                    item_obj.CurrentStage = item_obj.CurrentStage + 1
                else
                    item_obj.Active = true
                end
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
    -- Tell the LocationSectionChangedHandler to not send a LocationChecks for this location any more.
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

local function updateAllHints(value)
    for _, hint in ipairs(value) do
        -- print("hint", hint, hint.found)
        -- print(dump_table(hint))
        if hint.finding_player == Archipelago.PlayerNumber then
            updateHints(hint.location, hint.status)
        end
    end
end

function onNotify(key, value, old_value)
    print("onNotify", key, value, old_value)
    if key == HINTS_ID then
        if value ~= old_value then
            updateAllHints(value)
        end
    elseif key == goal_status_key then
        checkGoalStatus(value)
    end
end

function onNotifyLaunch(key, value)
    print("onNotifyLaunch", key, value)
    if key == HINTS_ID then
        updateAllHints(value)
    elseif key == goal_status_key then
        checkGoalStatus(value)
    end
end

function updateHints(locationID, status)
    local sections = LOCATION_MAPPING[locationID]
    for _, section_id in ipairs(sections) do
        local section = Tracker:FindObjectForCode(section_id)
        if section then
            highlight_level = HIGHLIGHT_LEVEL[status]
            if highlight_level ~= nil then
                section.Highlight = highlight_level
            else
                print(string.format("No highlight level found for status: %s", status))
            end
        else
            print(string.format("No object found for code: %s", location))
        end
    end
end


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
