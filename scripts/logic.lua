require("scripts/autotracking/archipelago")

local GOLD_BRICK_LOCATIONS = {
    ["@Episode 1/Negotiations"] = 2, -- One for completion and one for True Jedi
    ["@Episode 1/Negotiations/Minikits"] = 1,
    ["@Episode 1/Invasion of Naboo"] = 2,
    ["@Episode 1/Invasion of Naboo/Minikits"] = 1,
    ["@Episode 1/Escape From Naboo"] = 2,
    ["@Episode 1/Escape From Naboo/Minikits"] = 1,
    ["@Episode 1/Mos Espa Pod Race"] = 2,
    ["@Episode 1/Mos Espa Pod Race/Minikits"] = 1,
    ["@Episode 1/Retake Theed Palace"] = 2,
    ["@Episode 1/Retake Theed Palace/Minikits"] = 1,
    ["@Episode 1/Darth Maul"] = 2,
    ["@Episode 1/Darth Maul/Minikits"] = 1,
    ["@Episode 2/Bounty Hunter Pursuit"] = 2,
    ["@Episode 2/Bounty Hunter Pursuit/Minikits"] = 1,
    ["@Episode 2/Discovery on Kamino"] = 2,
    ["@Episode 2/Discovery on Kamino/Minikits"] = 1,
    ["@Episode 2/Droid Factory"] = 2,
    ["@Episode 2/Droid Factory/Minikits"] = 1,
    ["@Episode 2/Jedi Battle"] = 2,
    ["@Episode 2/Jedi Battle/Minikits"] = 1,
    ["@Episode 2/Gunship Cavalry"] = 2,
    ["@Episode 2/Gunship Cavalry/Minikits"] = 1,
    ["@Episode 2/Count Dooku"] = 2,
    ["@Episode 2/Count Dooku/Minikits"] = 1,
    ["@Episode 3/Battle Over Coruscant"] = 2,
    ["@Episode 3/Battle Over Coruscant/Minikits"] = 1,
    ["@Episode 3/Chancellor in Peril"] = 2,
    ["@Episode 3/Chancellor in Peril/Minikits"] = 1,
    ["@Episode 3/General Grievous"] = 2,
    ["@Episode 3/General Grievous/Minikits"] = 1,
    ["@Episode 3/Defense of Kashyyyk"] = 2,
    ["@Episode 3/Defense of Kashyyyk/Minikits"] = 1,
    ["@Episode 3/Ruin of the Jedi"] = 2,
    ["@Episode 3/Ruin of the Jedi/Minikits"] = 1,
    ["@Episode 3/Darth Vader"] = 2,
    ["@Episode 3/Darth Vader/Minikits"] = 1,
    ["@Episode 4/Secret Plans"] = 2,
    ["@Episode 4/Secret Plans/Minikits"] = 1,
    ["@Episode 4/Through the Jundland Wastes"] = 2,
    ["@Episode 4/Through the Jundland Wastes/Minikits"] = 1,
    ["@Episode 4/Mos Eisley Spaceport"] = 2,
    ["@Episode 4/Mos Eisley Spaceport/Minikits"] = 1,
    ["@Episode 4/Rescue the Princess"] = 2,
    ["@Episode 4/Rescue the Princess/Minikits"] = 1,
    ["@Episode 4/Death Star Escape"] = 2,
    ["@Episode 4/Death Star Escape/Minikits"] = 1,
    ["@Episode 4/Rebel Attack"] = 2,
    ["@Episode 4/Rebel Attack/Minikits"] = 1,
    ["@Episode 5/Hoth Battle"] = 2,
    ["@Episode 5/Hoth Battle/Minikits"] = 1,
    ["@Episode 5/Escape From Echo Base"] = 2,
    ["@Episode 5/Escape From Echo Base/Minikits"] = 1,
    ["@Episode 5/Falcon Flight"] = 2,
    ["@Episode 5/Falcon Flight/Minikits"] = 1,
    ["@Episode 5/Dagobah"] = 2,
    ["@Episode 5/Dagobah/Minikits"] = 1,
    ["@Episode 5/Cloud City Trap"] = 2,
    ["@Episode 5/Cloud City Trap/Minikits"] = 1,
    ["@Episode 5/Betrayal Over Bespin"] = 2,
    ["@Episode 5/Betrayal Over Bespin/Minikits"] = 1,
    ["@Episode 6/Jabba's Palace"] = 2,
    ["@Episode 6/Jabba's Palace/Minikits"] = 1,
    ["@Episode 6/Pit of Carkoon"] = 2,
    ["@Episode 6/Pit of Carkoon/Minikits"] = 1,
    ["@Episode 6/Speeder Showdown"] = 2,
    ["@Episode 6/Speeder Showdown/Minikits"] = 1,
    ["@Episode 6/Battle of Endor"] = 2,
    ["@Episode 6/Battle of Endor/Minikits"] = 1,
    ["@Episode 6/Jedi Destiny"] = 2,
    ["@Episode 6/Jedi Destiny/Minikits"] = 1,
    ["@Episode 6/Into the Death Star"] = 2,
    ["@Episode 6/Into the Death Star/Minikits"] = 1,
}

-- Helper function for checking if a certain number of locations are accessible.
-- May return AccessibilityLevel.SequenceBreak if the locations are only accessible via sequence break.
local function has_count_accessible_locations_pairs(location_increment_pairs, required_count)
    local sequence_break_count = 0
    local accessible_count = 0
    for loc_path, increment in pairs(location_increment_pairs) do
        local location = Tracker:FindObjectForCode(loc_path)
        if location then
            local location_accessibility = location.AccessibilityLevel
            if location_accessibility == AccessibilityLevel.Normal then
                accessible_count = accessible_count + increment
                if accessible_count >= required_count then
                    -- Return early.
                    return AccessibilityLevel.Normal
                end
            elseif location_accessibility == AccessibilityLevel.SequenceBreak then
                sequence_break_count = sequence_break_count + increment
            end
        end
    end
    if (sequence_break_count + accessible_count) >= required_count then
        -- There are enough that are accessible when including locations accessible via sequence break.
        return AccessibilityLevel.SequenceBreak
    else
        return AccessibilityLevel.None
    end
end

function minikits_goal()
    local minikit_count = Tracker:ProviderCountForCode("minikits")
    local count_for_goal = Tracker:ProviderCountForCode("minikits_for_goal")
    return minikit_count >= count_for_goal
end

function has_accessible_gold_bricks(count_str)
    local count = tonumber(count_str)
    return has_count_accessible_locations_pairs(GOLD_BRICK_LOCATIONS, count)
end

local progressive_score_multiplier_requirement_cache = {}
local function reset_score_multiplier_requirement_cache()
    progressive_score_multiplier_requirement_cache = {}
end
ScriptHost:AddWatchForCode("reset_price_cache",
                           "max_purchase_with_no_multipliers",
                           reset_score_multiplier_requirement_cache)

function can_purchase(studs_count_str)
    local required_item
    local cached = progressive_score_multiplier_requirement_cache[studs_count_str]
    if cached ~= nil then
        required_item = cached
    else
        local max_purchase_with_no_multipliers_item = Tracker:FindObjectForCode("max_purchase_with_no_multipliers")
        local max_purchase_with_no_multipliers = max_purchase_with_no_multipliers_item.AcquiredCount
        local studs_count = tonumber(studs_count_str)
        local required_count
        if studs_count <= max_purchase_with_no_multipliers then
            required_count = 0
        elseif studs_count <= max_purchase_with_no_multipliers * 2 then
            required_count = 1 -- 2x
        elseif studs_count <= max_purchase_with_no_multipliers * 8 then
            required_count = 2 -- 2x * 4x = 8x
        elseif studs_count <= max_purchase_with_no_multipliers * 48 then
            required_count = 3 -- 2x * 4x * 6x = 48x
        elseif studs_count <= max_purchase_with_no_multipliers * 384 then
            required_count = 4 -- 2x * 4x * 6x * 8x = 384x
        else
            required_count = 5 -- 2x * 4x * 6x * 8x * 10x = 3840x
        end
        required_item = "progressivescoremultiplier"..tostring(required_count)
        progressive_score_multiplier_requirement_cache[studs_count_str] = required_item
    end
    if required_item == "progressivescoremultiplier0" then
        return true
    else
        return Tracker:ProviderCountForCode(required_item) > 0
    end
end

function all_episodes_tokens()
    return Tracker:ProviderCountForCode("allepisodestoken") >= Tracker:ProviderCountForCode("enabled_episodes_count")
end