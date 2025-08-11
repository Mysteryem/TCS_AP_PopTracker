
require("scripts/autotracking/item_mapping")
require("scripts/autotracking/location_mapping")
require("scripts/autotracking/cantina_room_mapping")
require("scripts/autotracking/boss_mapping")
require("scripts/autotracking/area_id_mapping")
Version = require("scripts/version")

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

local CANTINA_ROOM_KEY_FORMAT = "tcs_cantina_room_%i_%i"
local cantina_room_key

-- Gold/Power Brick events. These are written to datastorage as lists of area IDs, and updated as if the lists were
-- sets.
local COMPLETED_FREE_PLAY_KEY_FORMAT = "tcs_completed_free_play_%i_%i"
local completed_free_play_key
local COMPLETED_TRUE_JEDI_KEY_FORMAT = "tcs_completed_true_jedi_%i_%i"
local completed_true_jedi_key
local COMPLETED_10_MINIKITS_KEY_FORMAT = "tcs_completed_10_minikits_%i_%i"
local completed_10_minikits_key
local COMPLETED_BONUSES_KEY_FORMAT = "tcs_completed_bonuses_%i_%i"
local completed_bonuses_key

local COLLECTED_POWER_BRICKS_KEY_FORMAT = "tcs_collected_power_bricks_%i_%i"
local collected_power_bricks_key

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
    -- Get and subscribe to changes in the player's current room in the Cantina
    cantina_room_key = string.format(CANTINA_ROOM_KEY_FORMAT, Archipelago.TeamNumber, Archipelago.PlayerNumber)
    -- Get and subscribe to changes in the player's completed chapters
    completed_free_play_key = string.format(COMPLETED_FREE_PLAY_KEY_FORMAT, Archipelago.TeamNumber, Archipelago.PlayerNumber)
    -- Get and subscribe to changes in the player's completed Bonus levels
    completed_bonuses_key = string.format(COMPLETED_BONUSES_KEY_FORMAT, Archipelago.TeamNumber, Archipelago.PlayerNumber)
    -- Get and subscribe to changes in the player's completed True Jedi
    completed_true_jedi_key = string.format(COMPLETED_TRUE_JEDI_KEY_FORMAT, Archipelago.TeamNumber, Archipelago.PlayerNumber)
    -- Get and subscribe to changes in the player's completed 10/10 Minikits
    completed_10_minikits_key = string.format(COMPLETED_10_MINIKITS_KEY_FORMAT, Archipelago.TeamNumber, Archipelago.PlayerNumber)
    -- Get and subscribe to changes in the player's collected Power Bricks
    collected_power_bricks_key = string.format(COLLECTED_POWER_BRICKS_KEY_FORMAT, Archipelago.TeamNumber, Archipelago.PlayerNumber)
    local datastorage_keys = {
        goal_status_key,
        cantina_room_key,
        completed_free_play_key,
        completed_bonuses_key,
        completed_true_jedi_key,
        completed_10_minikits_key,
        collected_power_bricks_key,
    }
    Archipelago:Get(datastorage_keys)
    Archipelago:SetNotify(datastorage_keys)

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
    -- Reset Gold Bricks
    for _k, shortname in pairs(AREA_ID_TO_SHORTNAME) do
        Tracker:FindObjectForCode(shortname.."_completion_gold_brick").Active = false
        -- Bonus levels only have completion, so only reset True Jedi and 10 Minikits Gold Bricks, and Power Bricks, for
        -- Chapter levels.
        if string.len(shortname) == 3 then
            Tracker:FindObjectForCode(shortname.."_true_jedi_gold_brick").Active = false
            Tracker:FindObjectForCode(shortname.."_minikits_gold_brick").Active = false
            Tracker:FindObjectForCode(shortname.."_power_brick").Active = false
        end
    end

    PLAYER_ID = Archipelago.PlayerNumber or -1
    TEAM_NUMBER = Archipelago.TeamNumber or 0
    SLOT_DATA = slot_data

    local apworld_version = Version.new(slot_data["apworld_version"])
    local goal_amount = slot_data["minikit_goal_amount"]

    Tracker:FindObjectForCode("minikits_for_goal").AcquiredCount = goal_amount

    -- Set enabled chapters.
    -- Read from slot data.
    local enabled_chapters = slot_data["enabled_chapters"]
    -- Create a dictionary used as a set and add all enabled chapters to it.
    local enabled_chapters_set = {}
    for _i, chapter_string in ipairs(enabled_chapters) do
        enabled_chapters_set[chapter_string] = true
    end
    -- Iterate through every chapter and set enabled chapters as active and disabled chapters as inactive.
    for episode=1,6 do
        for chapter=1,6 do
            local chapter_item = Tracker:FindObjectForCode(string.format("%s_%s_enabled", episode, chapter))
            local chapter_string = string.format("%s-%s", episode, chapter)
            if enabled_chapters_set[chapter_string] then
                chapter_item.Active = true
            else
                chapter_item.Active = false
            end
        end
    end

    -- Enable Episode unlocks when unlocking episodes has no requirements.
    if slot_data["episode_unlock_requirement"] == 0 then
        for episode=1,6 do
            local item_name = string.format("episode%iunlock", episode)
            Tracker:FindObjectForCode(item_name).Active = true
        end
    end

    -- Set active state for items used to signify whether episodes are enabled.
    -- Set consumable item that stores the number of enabled episodes.
    local enabled_episodes_set = {}
    for _, episode_number in ipairs(slot_data["enabled_episodes"]) do
        enabled_episodes_set[episode_number] = true
    end
    for episode=1,6 do
        local item_name = string.format("episode_%i_enabled", episode)
        local item = Tracker:FindObjectForCode(item_name)
        if enabled_episodes_set[episode] ~= nil then
            item.CurrentStage = 1
        else
            item.CurrentStage = 0
        end
    end

    local bonuses_enabled = slot_data["enable_bonus_locations"] == 1
    Tracker:FindObjectForCode("bonuses_enabled").Active = bonuses_enabled

    -- Disable all bonuses to start with.
    local bonuses_mapping = {
        ["Mos Espa Pod Race (Original)"] = "bonuses_enabled_podrace",
        ["Anakin's Flight"] = "bonuses_enabled_anakin_flight",
        ["Gunship Cavalry (Original)"] = "bonuses_enabled_gunship",
        ["A New Hope (Bonus Level)"] = "bonuses_enabled_a_new_hope",
        ["LEGO City"] = "bonuses_enabled_lego_city",
        ["New Town"] = "bonuses_enabled_new_town",
        ["Indiana Jones: Trailer"] = "bonuses_enabled_indy"
    }
    for _, code in pairs(bonuses_mapping) do
        Tracker:FindObjectForCode(code).Active = false
    end
    -- Then enable all enabled bonuses.
    local enabled_bonuses = slot_data["enabled_bonuses"]
    for _, key in ipairs(enabled_bonuses) do
        Tracker:FindObjectForCode(bonuses_mapping[key]).Active = true
    end

    -- Set logic settings
    local most_expensive_purchase = slot_data["most_expensive_purchase_with_no_multiplier"] * 1000
    Tracker:FindObjectForCode("max_purchase_with_no_multipliers").AcquiredCount = most_expensive_purchase

    local all_episodes_purchases_unlock = slot_data["all_episodes_character_purchase_requirements"]
    Tracker:FindObjectForCode("all_episodes_purchases_unlock").CurrentStage = all_episodes_purchases_unlock

    -- Set enabled location types
    local story_character_locations_enabled = slot_data["enable_story_character_unlock_locations"] == 1
    Tracker:FindObjectForCode("story_character_locations").Active = story_character_locations_enabled

    local all_episodes_purchases_enabled = slot_data["enable_all_episodes_purchases"] == 1
    Tracker:FindObjectForCode("all_episodes_purchase_locations").Active = all_episodes_purchases_enabled

    local enable_true_jedi_locations
    if apworld_version < Version.new({1,1,0}) then
        -- Always enabled in earlier versions.
        enable_true_jedi_locations = true
    else
        enable_true_jedi_locations = slot_data["enable_true_jedi_locations"] == 1
    end
    Tracker:FindObjectForCode("setting_true_jedi_locations_enabled").Active = enable_true_jedi_locations

    local enable_minikit_locations
    if apworld_version < Version.new({1,1,0}) then
        -- Always enabled in earlier versions.
        enable_minikit_locations = true
    else
        enable_minikit_locations = slot_data["enable_minikit_locations"] == 1
    end
    Tracker:FindObjectForCode("setting_minikit_locations_enabled").Active = enable_minikit_locations

    local defeat_bosses_goal_amount
    if apworld_version < Version.new({1,1,0}) then
        -- The goal did not exist in earlier versions.
        defeat_bosses_goal_amount = 0
    else
        defeat_bosses_goal_amount = slot_data["defeat_bosses_goal_amount"] or 0
    end
    Tracker:FindObjectForCode("setting_defeat_bosses_goal_amount").AcquiredCount = defeat_bosses_goal_amount

    -- Set bosses mode
    local setting_defeat_bosses_mode
    if defeat_bosses_goal_amount == 0 then
        -- Without bosses enabled, don't show bosses in the tracker.
        setting_defeat_bosses_mode = 0
    else
        -- The only_unique_bosses_count option covers stages 1, 2 and 3 of the setting_defeat_bosses_mode item, so needs
        -- to be increased by 1 to get the correct stage number.
        setting_defeat_bosses_mode = slot_data["only_unique_bosses_count"] + 1
    end
    Tracker:FindObjectForCode("setting_defeat_bosses_mode").CurrentStage = setting_defeat_bosses_mode

    -- Set enabled bosses
    set_bosses_from_slot_data_chapters(slot_data, setting_defeat_bosses_mode)

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
        local goal_location = Tracker:FindObjectForCode("@Cantina/Goal Event/Goal")
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

local function update_cantina_room(room_value)
    if room_value then
        tab = CANTINA_ROOM_MAPPING[room_value]
        if tab then
            Tracker:UiHint("ActivateTab", tab)
        end
    end
end

local function update_gold_or_power_bricks(format, completed_chapters)
    completed_chapters = completed_chapters or {}
    for _, area_id in ipairs(completed_chapters) do
        local shortname = AREA_ID_TO_SHORTNAME[area_id]
        if shortname ~= nil then
            local s = string.format(shortname)
            Tracker:FindObjectForCode(s).Active = true
        end
    end
end

local function new_area_ids(value, old_value)
    value = value or {}
    old_value = old_value or {}
    local old_set = {}
    for _, v in ipairs(old_value) do
        old_set[v] = true
    end
    local new_values = {}
    for _, v in ipairs(value) do
        if old_set[v] == nil then
            table.insert(new_values, v)
        end
    end
    return new_values
end

local function update_new_gold_or_power_bricks(format, value, old_value)
    update_gold_or_power_bricks(format, new_area_ids(value, old_value))
end

function onNotify(key, value, old_value)
    print("onNotify", key, value, old_value)
    if key == HINTS_ID then
        if value ~= old_value then
            updateAllHints(value)
        end
    elseif key == goal_status_key then
        checkGoalStatus(value)
    elseif key == cantina_room_key then
        update_cantina_room(value)
    elseif key == completed_free_play_key or key == completed_bonuses_key then
        update_new_gold_or_power_bricks("%s_completion_gold_brick", value, old_value)
    elseif key == completed_true_jedi_key then
        update_new_gold_or_power_bricks("%s_true_jedi_gold_brick", value, old_value)
    elseif key == completed_10_minikits_key then
        update_new_gold_or_power_bricks("%s_minikits_gold_brick", value, old_value)
    elseif key == collected_power_bricks_key then
        update_new_gold_or_power_bricks("%s_power_brick", value, old_value)
    end
end

function onNotifyLaunch(key, value)
    print("onNotifyLaunch", key, value)
    if key == HINTS_ID then
        updateAllHints(value)
    elseif key == goal_status_key then
        checkGoalStatus(value)
    elseif key == cantina_room_key then
        update_cantina_room(value)
    elseif key == completed_free_play_key or key == completed_bonuses_key then
        update_gold_or_power_bricks("%s_completion_gold_brick", value)
    elseif key == completed_true_jedi_key then
        update_gold_or_power_bricks("%s_true_jedi_gold_brick", value)
    elseif key == completed_10_minikits_key then
        update_gold_or_power_bricks("%s_minikits_gold_brick", value)
    elseif key == collected_power_bricks_key then
        update_gold_or_power_bricks("%s_power_brick", value)
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
