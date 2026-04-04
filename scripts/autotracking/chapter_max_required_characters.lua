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

-- Episode -> Chapter -> {requires C-3PO, requires R2-D2, requires Chewbacca}
EXCLUDABLE_CHARACTERS = {
    [1] = {
        [1] = {false, false, false},
        [2] = {false, false, false},
        [3] = {false, false, false},
        [4] = {false, false, false},
        [5] = {false, true, false},
        [6] = {false, false, false},
    },
    [2] = {
        [1] = {false, false, false},
        [2] = {false, false, false},
        [3] = {true, true, false},
        [4] = {false, true, false},
        [5] = {false, false, false},
        [6] = {false, false, false},
    },
    [3] = {
        [1] = {false, false, false},
        [2] = {false, true, false},
        [3] = {false, false, false},
        [4] = {false, false, true},
        [5] = {false, false, false},
        [6] = {false, false, false},
    },
    [4] = {
        [1] = {true, true, false},
        [2] = {true, true, false},
        [3] = {true, true, true},
        [4] = {true, true, true},
        [5] = {true, true, true},
        [6] = {false, false, false},
    },
    [5] = {
        [1] = {false, false, false},
        [2] = {true, false, true},
        [3] = {false, false, false},
        [4] = {false, true, false},
        [5] = {false, true, false},
        [6] = {true, true, true},
    },
    [6] = {
        [1] = {true, true, true},
        [2] = {true, true, true},
        [3] = {false, false, false},
        [4] = {true, true, true},
        [5] = {false, false, false},
        [6] = {false, false, false},
    },
}
EXCLUDABLE_C_3PO = 1
EXCLUDABLE_R2_D2 = 2
EXCLUDABLE_CHEWBACCA = 3
