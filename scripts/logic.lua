require("scripts/autotracking/archipelago")

function minikits_goal()
    local minikit_count = Tracker:ProviderCountForCode("minikits")
    local count_for_goal = Tracker:ProviderCountForCode("minikits_for_goal")
    return minikit_count >= count_for_goal
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
        local max_purchase_with_no_multipliers = Tracker:ProviderCountForCode("max_purchase_with_no_multipliers")
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

function boss_enabled(boss_code)
    -- The boss X enabled items do not provide any codes for their first stage (boss not enabled) or their second stage
    -- (boss enabled, but not defeated) because the boss items are hosted on sections, and the sections should only
    -- clear once the boss has been defeated. If a hosted item provides *any* codes, then the section is considered
    -- cleared, so this requires lua logic.
    return Tracker:FindObjectForCode(boss_code).CurrentStage > 0
end

local function get_defeated_bosses_count()
    if Tracker:ProviderCountForCode("setting_defeat_bosses_normal") > 0 then
        -- Each boss in a chapter counts separately.
        return Tracker:ProviderCountForCode("boss_defeated")
    elseif Tracker:ProviderCountForCode("setting_defeat_bosses_unique") > 0 then
        -- Each boss character counts separately.
        return Tracker:ProviderCountForCode("unique_boss_defeated")
    else
        -- The Defeat Bosses Goal is not enabled.
        return nil
    end
end

function defeat_bosses_goal()
    return Tracker:ProviderCountForCode("total_bosses_defeated") >= Tracker:ProviderCountForCode("setting_defeat_bosses_goal_amount")
end

function complete_levels_goal()
    return Tracker:ProviderCountForCode("level_completion_gold_brick") >= Tracker:ProviderCountForCode("setting_goal_level_completions_amount")
end

local function update_gold_brick_total(code)
    Tracker:FindObjectForCode("total_gold_bricks").AcquiredCount = Tracker:ProviderCountForCode(code)
end

local function update_level_completions_total(code)
    Tracker:FindObjectForCode("total_level_completions").AcquiredCount = Tracker:ProviderCountForCode(code)
end

local function update_defeated_bosses_total(code)
    local count = get_defeated_bosses_count() or 0
    Tracker:FindObjectForCode("total_bosses_defeated").AcquiredCount = count
end

ScriptHost:AddWatchForCode("update_gold_brick_total", "gold_brick", update_gold_brick_total)
ScriptHost:AddWatchForCode("update_level_completion_total", "level_completion_gold_brick", update_level_completions_total)
ScriptHost:AddWatchForCode("update_total_bosses_defeated_1", "boss_defeated", update_defeated_bosses_total)
ScriptHost:AddWatchForCode("update_total_bosses_defeated_2", "unique_boss_defeated", update_defeated_bosses_total)