local originalName
local originalNameExt
local originalNamePlural

net.Receive("ComicRelifeBegin", function()
    -- Re-naming the Jester to "Dr. Prankensteir"
    originalName = ROLE_STRINGS[ROLE_JESTER]
    originalNameExt = ROLE_STRINGS_EXT[ROLE_JESTER]
    originalNamePlural = ROLE_STRINGS_PLURAL[ROLE_JESTER]
    ROLE_STRINGS[ROLE_JESTER] = "Dr. Prankenstein"
    ROLE_STRINGS_EXT[ROLE_JESTER] = "Dr. Prankenstein"
    -- Ask me about the plural of 'octupus'. Honestly, it's great fun!
    ROLE_STRINGS_PLURAL[ROLE_JESTER] = "Dr. Prankensteinopedes"
end)

net.Receive("ComicRelifeEnd", function()
    -- Resets the names of roles
    if originalName then
        ROLE_STRINGS[ROLE_JESTER] = originalName
        ROLE_STRINGS_EXT[ROLE_JESTER] = originalNameExt
        ROLE_STRINGS_PLURAL[ROLE_JESTER] = originalNamePlural
    end
end)