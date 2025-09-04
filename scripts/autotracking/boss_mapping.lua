require("scripts/autotracking/area_id_mapping")

local BOSS_MAPPING_UNIQUE = {
    ["1-6"] = "boss_darth_maul",
    ["2-1"] = "boss_zam_wesell",
    ["2-2"] = "boss_jango_fett",
    ["2-4"] = "boss_jango_fett",
    ["2-6"] = "boss_count_dooku",
    ["3-2"] = "boss_count_dooku",
    ["3-3"] = "boss_general_grievous",
    ["3-6"] = "boss_anakin_skywalker",
    ["4-3"] = "boss_imperial_spy",
    ["4-6"] = "boss_death_star",
    ["5-4"] = "boss_darth_vader",
    ["5-5"] = "boss_darth_vader",
    ["5-6"] = "boss_boba_fett",
    ["6-1"] = "boss_rancor",
    ["6-2"] = "boss_boba_fett",
    ["6-5"] = "boss_the_emperor",
    ["6-6"] = "boss_death_star_ii",
}

local BOSS_MAPPING_NORMAL = {}
local BOSS_MAPPING_UNIQUE_ANAKIN_AS_VADER = {}
for k, v in pairs(BOSS_MAPPING_UNIQUE) do
    BOSS_MAPPING_NORMAL[k] = v .. "_" .. k
    if v == "boss_anakin_skywalker" then
        BOSS_MAPPING_UNIQUE_ANAKIN_AS_VADER[k] = "boss_darth_vader"
    else
        BOSS_MAPPING_UNIQUE_ANAKIN_AS_VADER[k] = v
    end
end

local MAPPING_LOOKUP = {
    [0] = {},
    [1] = BOSS_MAPPING_NORMAL,
    [2] = BOSS_MAPPING_UNIQUE,
    [3] = BOSS_MAPPING_UNIQUE_ANAKIN_AS_VADER,
}

function set_bosses_from_slot_data_chapters(slot_data, setting_defeat_bosses_mode)
    -- todo: Get the defeat bosses mode from slot data and set the setting_defeat_bosses_mode item to its value
    local enabled_boss_chapters = slot_data["enabled_bosses"] or {}

    local disabled = {}
    -- Set everything disabled to start with.
    for _, v in pairs(BOSS_MAPPING_NORMAL) do
        disabled[v] = true
    end
    for _, v in pairs(BOSS_MAPPING_UNIQUE) do
        disabled[v] = true
    end

    local mapping = MAPPING_LOOKUP[setting_defeat_bosses_mode]

    local enabled = {}
    for _, v in ipairs(enabled_boss_chapters) do
        local item_name = mapping[v]
        if item_name then
            enabled[item_name] = true
            disabled[item_name] = nil
        end
    end
    -- If a duplicated unique boss is only an enabled boss in one of the chapters present in the multiworld, but there
    -- are multiple chapters present that feature the boss, only the enabled boss chapter should show in the tracker.
    -- To do this, the unique boss locations' visibility also require the non-unique boss items to be activated.
    if setting_defeat_bosses_mode > 1 then
        for _, v in ipairs(enabled_boss_chapters) do
            local item_name = BOSS_MAPPING_NORMAL[v]
            if item_name then
                enabled[item_name] = true
                disabled[item_name] = nil
            end
        end
    end

    -- Disable all disabled bosses.
    for k, _ in pairs(disabled) do
        local item = Tracker:FindObjectForCode(k)
        item.CurrentStage = 0
    end

    -- Enable all enabled bosses.
    for k, _ in pairs(enabled) do
        local item = Tracker:FindObjectForCode(k)
        item.CurrentStage = 1
    end
end

function update_defeated_bosses(completed_area_ids)
    local setting_defeat_bosses_mode = Tracker:FindObjectForCode("setting_defeat_bosses_mode").CurrentStage
    if setting_defeat_bosses_mode == 0 then
        -- Bosses are disabled.
        return
    end
    local mapping = MAPPING_LOOKUP[setting_defeat_bosses_mode]
    for _, area_id in ipairs(completed_area_ids or {}) do
        -- Get the chapter shortname from the area_id
        local shortname = AREA_ID_TO_SHORTNAME[area_id]
        if shortname ~= nil then
            -- Get the item code for the chapter
            local code = mapping[shortname]
            if code ~= nil then
                local item = Tracker:FindObjectForCode(code)
                -- Check that the boss exists and is enabled, then mark the boss as defeated.
                if item ~= nil and item.CurrentStage == 1 then
                    item.CurrentStage = 2
                end
            end
        end
    end
end