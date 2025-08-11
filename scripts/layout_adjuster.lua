local last_stage = nil

local function boss_goal_watch(code)
    local boss_goal_setting = Tracker:FindObjectForCode(code)
    local stage = boss_goal_setting.CurrentStage
    local adjusted_stage
    if stage == 3 then
        -- Both of the stages for unique bosses use the same layout, so there is no need to reload UI when switching
        -- between them.
        adjusted_stage = 2
    else
        adjusted_stage = stage
    end
    if adjusted_stage == last_stage then
        -- No change from the last time, so skip the UI reload.
        return
    end
    if adjusted_stage == 0 then
        Tracker:AddLayouts("layouts/no_bosses_main_display.json")
        Tracker:AddLayouts("layouts/broadcast.json")
    elseif adjusted_stage == 1 then
        Tracker:AddLayouts("layouts/bosses_main_display.json")
        Tracker:AddLayouts("layouts/broadcast_bosses.json")
    elseif adjusted_stage == 2 then
        Tracker:AddLayouts("layouts/bosses_unique_display.json")
        Tracker:AddLayouts("layouts/broadcast_unique_bosses.json")
    end
    last_stage = adjusted_stage
end

ScriptHost:AddWatchForCode("boss_goal_layout_adjuster", "setting_defeat_bosses_mode", boss_goal_watch)