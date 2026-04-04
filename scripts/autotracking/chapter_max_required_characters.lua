-- Episode -> Chapter -> Max count
MAX_REQUIRED_STORY_CHARACTERS = {
    [1] = {
        [1] = 3,
        [2] = 3,
        [3] = 4,
        [4] = 1,
        [5] = 6,
        [6] = 2,
    },
    [2] = {
        [1] = 1,
        [2] = 2,
        [3] = 4,
        [4] = 5,
        [5] = 1,
        [6] = 3,
    },
    [3] = {
        [1] = 2,
        [2] = 4,
        [3] = 2,
        [4] = 2,
        [5] = 2,
        [6] = 2,
    },
    [4] = {
        [1] = 5,
        [2] = 4,
        [3] = 6,
        [4] = 6,
        [5] = 6,
        [6] = 2,
    },
    [5] = {
        [1] = 1,
        [2] = 4,
        [3] = 2,
        [4] = 4,
        [5] = 2,
        [6] = 5,
    },
    [6] = {
        [1] = 6,
        [2] = 7,
        [3] = 2,
        [4] = 6,
        [5] = 2,
        [6] = 2,
    },
}

MAX_REQUIRED_PURCHASE_CHARACTERS = {
    [1] = {
        [1] = 4,
        [2] = 2,
        [3] = 2,
        [4] = 3,
        [6] = 1,
    },
    [2] = {
        [1] = 3,
        [2] = 3,
        [3] = 2,
        [4] = 9,
    },
    [3] = {
        [1] = 3,
        [2] = 2,
        [3] = 1,
        [4] = 5,
        [5] = 2,
    },
    [4] = {
        [1] = 3,
        [2] = 2,
        [3] = 3,
        [4] = 5,
        [6] = 3,
    },
    [5] = {
        [2] = 5,
        [3] = 2,
        [6] = 4,
    },
    [6] = {
        [1] = 4,
        [2] = 2,
        [4] = 1,
        [5] = 2,
        [6] = 1,
    },
}

-- Episode -> Chapter -> {excludable characters set}
-- The innermost tables are converted to sets (dict-like tables keyed by the array elements)
EXCLUDABLE_CHARACTERS = {
    [1] = {
        [5] = {"R2-D2"},
    },
    [2] = {
        [3] = {"C-3PO", "R2-D2"},
        [4] = {"R2-D2"},
    },
    [3] = {
        [2] = {"R2-D2"},
        [4] = {"Chewbacca"},
    },
    [4] = {
        [1] = {"C-3PO", "R2-D2"},
        [2] = {"C-3PO", "R2-D2"},
        [3] = {"C-3PO", "R2-D2", "Chewbacca"},
        [4] = {"C-3PO", "R2-D2", "Chewbacca"},
        [5] = {"C-3PO", "R2-D2", "Chewbacca"},
    },
    [5] = {
        [2] = {"C-3PO", "Chewbacca"},
        [4] = {"R2-D2"},
        [5] = {"R2-D2"},
        [6] = {"C-3PO", "R2-D2", "Chewbacca"},
    },
    [6] = {
        [1] = {"C-3PO", "R2-D2", "Chewbacca"},
        [2] = {"C-3PO", "R2-D2", "Chewbacca"},
        [4] = {"C-3PO", "R2-D2", "Chewbacca"},
    },
}
-- Convert array-like tables into set-like tables (dict-like tables used as sets)
for episode, chapters_table in pairs(EXCLUDABLE_CHARACTERS) do
    for chapter, excludes_table in pairs(chapters_table) do
        local set_like_table = {}
        for _, character_name in ipairs(excludes_table) do
            set_like_table[character_name] = true
        end
        chapters_table[chapter] = set_like_table
    end
end
