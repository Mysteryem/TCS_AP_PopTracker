require("scripts/autotracking/archipelago")

function minikits_goal()
    local minikit_count = Tracker:ProviderCountForCode("minikits")
    local count_for_goal = Tracker:ProviderCountForCode("minikits_for_goal")
    return minikit_count >= count_for_goal
end