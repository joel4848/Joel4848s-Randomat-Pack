local function PrintHelp()
    print("================================= Help =================================")
    print("Input: \'ttt_get_role_information <roles>\'")
    print("Output: Raw role names of the roles in <roles>")
    print("")
    print("\'<roles>\' should be a non-comma-separated list of actual role names")
    print("If a role name has spaces in it, surround it with quote marks")
    print("")
    print("Example:")
    print("")
    print("Input: \'ttt_get_role_information \"Mad Scientist\" Paladin Assassin\'")
    print("")
    print("Output:")
    print("")
    print("************************************************")
    print("Raw name for role \"Mad Scientist\": madscientist")
    print("")
    print("Raw name for role \"Paladin\": paladin")
    print("")
    print("2 roles found with the name \"Assassin\":")
    print("- assassin")
    print("- assassinjbc")
    print("************************************************")

    print("========================================================================")
end

local function FindRole(roles)
    print("************************************************")
    local firstEntry = true
    for _, role in ipairs(roles) do
        -- Make argument title case if it isn't already
        local roleTitleCase = role:gsub("(%a)(%w*)", function(a,b) return string.upper(a) .. string.lower(b) end)
        roleTitleCase = string.Replace(roleTitleCase, ",", "")

        local stringKeys = table.KeysFromValue(ROLE_STRINGS, roleTitleCase) or {}
        local defaultStringKeys = table.KeysFromValue(ROLE_STRINGS_DEFAULT, roleTitleCase) or {}

        local roleNumbers = {}

        for _, rnm in ipairs(stringKeys) do
            table.insert(roleNumbers, rnm)
        end

        for _, rnm in ipairs(defaultStringKeys) do
            if not table.HasValue(roleNumbers, rnm) then
                table.insert(roleNumbers, rnm)
            end
        end

        if firstEntry then
            firstEntry = false
        else
            print("")
        end

        if #roleNumbers == 0 then
            print("Error: no matching role for \"" .. role .. "\" found.")
            print("Run \"ttt_get_role_information help\" for more information.")
        elseif #roleNumbers == 1 then
            roleRaw = ROLE_STRINGS_RAW[roleNumbers[1]] or nil

            print("Raw name for role \"" .. roleTitleCase .. "\": " .. roleRaw)
        else
            print(#roleNumbers .. " roles found with the name \"" .. roleTitleCase .. "\":")

            for _, key in ipairs(roleNumbers) do
                roleRaw = ROLE_STRINGS_RAW[key] or nil
                print("- " .. roleRaw)
            end
        end
    end

    print("************************************************")
end

concommand.Add("ttt_get_role_information", function(ply, cmd, args)
    local method = #args > 0 and args or "help"

    if method == "help" then
        PrintHelp()
    else
        FindRole(method)
    end
end)