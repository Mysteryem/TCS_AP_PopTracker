-- Work-in-progress.
-- This will be relevant in the future when there are maps displayed for each individual level.

local NEGOTIATIONS = {
    --[1] = "A", -- intro1
    --[2] = "A", -- intro2
    [3] = "A",
    [4] = "B",
    [5] = "C",
    --[6] = "C", -- outro
    --[7] = "C", -- status
}
local INVASION_OF_NABOO = {
    --[8] = "A",
    --[9] = "A",
    [10] = "A",
    [11] = "B",
    [12] = "C",
    [13] = "E",
    --[14] = "E",
    --[15] = "E",
}
local ESCAPE_FROM_NABOO = {
    [19] = "A",
    [20] = "B",
    [21] = "C",
    [22] = "E",
}
local MOS_ESPA_POD_RACE = {
    [36] = "A",
}
local EPISODE1_LEVEL_MAPPING = {
    ["Negotiations"] = NEGOTIATIONS,
    ["Invasion of Naboo"] = INVASION_OF_NABOO,
    ["Escape From Naboo"] = ESCAPE_FROM_NABOO,
    ["Mos Espa Pod Race"] = MOS_ESPA_POD_RACE,
    ["Retake Theed Palace"] = RETAKE_THEED_PALACE,
    ["Darth Maul"] = DARTH_MAUL,
}

local EPISODES_LEVEL_MAPPING = {
    ["Episode 1"] = EPISODE1_LEVEL_MAPPING,
    ["Episode 2"] = EPISODE1_LEVEL_MAPPING,
    ["Episode 3"] = EPISODE1_LEVEL_MAPPING,
    ["Episode 4"] = EPISODE1_LEVEL_MAPPING,
    ["Episode 5"] = EPISODE1_LEVEL_MAPPING,
    ["Episode 6"] = EPISODE1_LEVEL_MAPPING,
}

LEVEL_MAPPING = {
    -- [0] = nil -- Title screen
    [325] = {"Cantina"}
}

for episode, episode_mapping in pairs(EPISODES_LEVEL_MAPPING) do
    for chapter, chapter_mapping in pairs(episode_mapping) do
        for level_id, level in pairs(chapter_mapping) do
            LEVEL_MAPPING[level_id] = {episode, chapter, level}
        end
    end
end