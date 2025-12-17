-- Items
Tracker:AddItems("items/items.json")
Tracker:AddItems("items/settings.json")
Tracker:AddItems("items/pack_settings.json")
Tracker:AddItems("items/bosses.json")
Tracker:AddItems("items/unique_bosses.json")
Tracker:AddItems("items/gold_brick_events.json")
Tracker:AddItems("items/power_brick_events.json")
Tracker:AddItems("items/chapter_completion_character_unlock_helpers.json")
Tracker:AddItems("items/goal_helpers.json")

-- Maps
Tracker:AddMaps("maps/maps.json")

-- Layout
Tracker:AddLayouts("layouts/broadcast.json")
Tracker:AddLayouts("layouts/items.json")
Tracker:AddLayouts("layouts/no_bosses_main_display.json")
Tracker:AddLayouts("layouts/settings_popup.json")
Tracker:AddLayouts("layouts/tabs.json")
Tracker:AddLayouts("layouts/tracker.json")

-- Locations
Tracker:AddLocations("locations/logic/macros.json")
Tracker:AddLocations("locations/Cantina.json")
Tracker:AddLocations("locations/Episode 1.json")
Tracker:AddLocations("locations/Episode 2.json")
Tracker:AddLocations("locations/Episode 3.json")
Tracker:AddLocations("locations/Episode 4.json")
Tracker:AddLocations("locations/Episode 5.json")
Tracker:AddLocations("locations/Episode 6.json")
Tracker:AddLocations("locations/Overworld.json")
Tracker:AddLocations("locations/LevelRequirementsDisplay.json")

-- AutoTracking for Poptracker
require("scripts/autotracking/archipelago")
require("scripts/logic")

-- Runtime layout adjustments
require("scripts/layout_adjuster")