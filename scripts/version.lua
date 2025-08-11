local Version = {
    __eq = function(v1, v2)
        return v1.major == v2.major and v1.minor == v2.minor and v1.patch == v2.patch
    end,
    __lt = function(v1, v2)
        for i=1,3 do
            if v1[i] > v2[i] then
                return false
            elseif v1[i] < v2[i] then
                return true
            end
        end
        -- They are equal.
        return false
    end,
}

function Version.new(major, minor, patch)
    if type(major) == "table" then
        return Version.new(table.unpack(major))
    else
        major = major or 0
        minor = minor or 0
        patch = patch or 0
        return setmetatable({major=major, minor=minor, patch=patch, [1]=major, [2]=minor, [3]=patch}, Version)
    end
end

return Version