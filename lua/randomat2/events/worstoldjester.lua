local EVENT = {}

EVENT.Title       = "#BringBackWORSTOldJester"
EVENT.Description = "Someone is the WORST old Jester: no fire, explosion or fall damage immunity,\nand NO ONE knows who they are!"
EVENT.id          = "worstoldjester"
EVENT.Categories  = {"rolechange", "largeimpact"}

local function GetJoelJesterTarget()
    local plys = {}
    for _, p in player.Iterator() do
        if p:Alive() and not p:IsSpec() then table.insert(plys, p) end
    end
    if #plys == 0 then return nil end

    local priorities = {
        function(p) return p:IsJesterTeam() end,
        function(p) return p:IsMonsterTeam() end,
        function(p) return p:IsIndependentTeam() end,
        function(p) return p:GetRole() == ROLE_INNOCENT end,
        function(p) return p:IsInnocentTeam() and p:GetRole() ~= ROLE_INNOCENT end,
        function(p) return p:GetRole() == ROLE_TRAITOR end,
        function(p) return p:IsTraitorTeam() and p:GetRole() ~= ROLE_TRAITOR end,
        function(p) return true end
    }

    for _, check in ipairs(priorities) do
        local candidates = {}
        for _, p in ipairs(plys) do
            if check(p) then table.insert(candidates, p) end
        end
        if #candidates > 0 then
            return candidates[math.random(#candidates)]
        end
    end
    return nil
end

function EVENT:Begin()
    -- Worst Old Jester settings
    RunConsoleCommand("ttt_joeljester_win_by_traitors",   "1")
    RunConsoleCommand("ttt_joeljester_notify_sound",      "1")
    RunConsoleCommand("ttt_joeljester_notify_confetti",   "1")
    RunConsoleCommand("ttt_joeljester_win_ends_round",    "1")

    RunConsoleCommand("ttt_joeljester_immune_fall",       "0")
    RunConsoleCommand("ttt_joeljester_immune_fire",       "0")
    RunConsoleCommand("ttt_joeljester_immune_explosions", "0")

    RunConsoleCommand("ttt_joeljester_swaps_with_killer", "0")
    RunConsoleCommand("ttt_joeljester_killer_dies",       "0")
    RunConsoleCommand("ttt_joeljester_respawns",          "0")

    local target = GetJoelJesterTarget()
    if target then
        target:SetRole(ROLE_JOELJESTER)
        SendFullStateUpdate()
    end
end

function EVENT:End()
end

function EVENT:Condition()
    return CR_Version
end

Randomat:register(EVENT)