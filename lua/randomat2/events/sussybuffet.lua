local EVENT = {}

EVENT.Title = "Sussy Buffet"
EVENT.Description = "Everyone chooses their role!"
EVENT.id = "sussybuffet"
EVENT.Categories = {"moderateimpact"}

util.AddNetworkString("RdmtSussyBuffetChoices")
util.AddNetworkString("RdmtSussyBuffetQueueInit")
util.AddNetworkString("RdmtSussyBuffetQueueUpdate")
util.AddNetworkString("RdmtSussyBuffetInfoToClient")

local TableInsert = table.insert

CreateConVar("randomat_sussybuffet_rolepack_only", 0, FCVAR_NONE, "Whether only roles in the active role pack should be offered", 0, 1)
CreateConVar("randomat_sussybuffet_include_default_roles", 0, FCVAR_NONE, "Whether detective/innocent/traitor should be offered", 0, 1)
CreateConVar("randomat_sussybuffet_show_tutorial", 1, FCVAR_NONE, "Whether to show the tutorial on event start", 0, 1)
CreateConVar("randomat_sussybuffet_excluded_roles", "", FCVAR_NONE, "Comma-separated list of (raw) role names not to offer")

local innocentPool  = {}
local detectivePool = {}
local traitorPool   = {}
local jesterPool    = {}
local otherPool     = {}

local playerQueue = {}
local currentPlayer = nil
local currentTeamAmounts = {}

local function ClearTimeoutTimer(ply)
    if IsValid(ply) then
        timer.Remove("RdmtSussyBuffetTimeout_" .. ply:SteamID64())
    end
end

function SendSussyBuffetInfo(choices, rerolls, detCount, innCount, traCount, jesCount, indCount)
    local allowDupes  = GetConVar("randomat_sussybuffet_allow_duplicates"):GetBool()
    local respawnDead = GetConVar("randomat_sussybuffet_respawn_dead_players"):GetBool()

    net.Start("RdmtSussyBuffetInfoToClient")
        net.WriteUInt(choices, 8)
        net.WriteUInt(rerolls, 8)
        net.WriteUInt(detCount, 8)
        net.WriteUInt(innCount, 8)
        net.WriteUInt(traCount, 8)
        net.WriteUInt(jesCount, 8)
        net.WriteUInt(indCount, 8)
        net.WriteBool(respawnDead)
        net.WriteBool(allowDupes)
    net.Broadcast()
end

local function GetTeamAmounts(playerCount, innocentPoolTotal, detectivePoolTotal, traitorPoolTotal, jesterPoolTotal, otherPoolTotal)
    local innocents  = 0
    local detectives = 0
    local traitors   = 0
    local jesters    = 0
    local others     = 0

    if detectivePoolTotal ~= 0 then detectives = 1 end
    traitors = math.floor((playerCount - 1) / 5) + 1
    if jesterPoolTotal ~= 0 and playerCount >= 5 then jesters = 1 end
    if otherPoolTotal ~= 0 then others = math.floor(playerCount / 8) end
    innocents = playerCount - detectives - traitors - jesters - others

    return {
        ["innocents"]  = innocents,
        ["detectives"] = detectives,
        ["traitors"]   = traitors,
        ["jesters"]    = jesters,
        ["others"]     = others
    }
end

local function TestPrint()
    for playerCount = 1, 15 do
        roleAmounts = GetTeamAmounts(playerCount, 50, 50, 50, 50, 50)
        print("**************************")
        print("Player Count = " .. playerCount)
        print("innocents    = " .. roleAmounts["innocents"] or 0)
        print("detectives   = " .. roleAmounts["detectives"] or 0)
        print("traitors     = " .. roleAmounts["traitors"] or 0)
        print("jesters      = " .. roleAmounts["jesters"] or 0)
        print("others       = " .. roleAmounts["others"] or 0)
    end
end

local function DetermineChoices(teamAmounts, choiceAmount)
    local choicePool = {}

    local teams = {
        {pool = table.Copy(innocentPool),  amount = teamAmounts.innocents},
        {pool = table.Copy(detectivePool), amount = teamAmounts.detectives},
        {pool = table.Copy(traitorPool),   amount = teamAmounts.traitors},
        {pool = table.Copy(jesterPool),    amount = teamAmounts.jesters},
        {pool = table.Copy(otherPool),     amount = teamAmounts.others}
    }

    -- Build choice pool based on remaining 'slots'
    for _, data in ipairs(teams) do
        local toPick = data.amount * 3
        local picked = 0

        while picked < toPick and #data.pool > 0 do
            TableInsert(choicePool, table.remove(data.pool, 1))
            picked = picked + 1
        end
    end

    -- Pick choices from choice pool
    local choices = {}
    local actualAmount = math.min(choiceAmount, #choicePool)

    table.Shuffle(choicePool)
    for i = 1, actualAmount do
        TableInsert(choices, choicePool[i])
    end

    return choices
end

local PlayerPickChoice

local function SendChoices(choices, ply)
    net.Start("RdmtSussyBuffetChoices")
        net.WriteTable(choices, true)
    net.Send(ply)

    -- Individual timeout timers
    local choiceTime = GetConVar("randomat_sussybuffet_choice_time"):GetInt()
    local timeout = choiceTime + 1
    local timerName = "RdmtSussyBuffetTimeout_" .. ply:SteamID64()

    timer.Create(timerName, timeout, 1, function()
        if IsValid(ply) and currentPlayer == ply then
            -- If no response from client, force reroll 'choice'
            PlayerPickChoice(ply, 4)
        end
    end)
end

local function NextPlayerTurn()
    if IsValid(currentPlayer) then
        ClearTimeoutTimer(currentPlayer)
    end

    currentPlayer = nil

    -- Move to next player in the queue
    while #playerQueue > 0 do
        EVENT.CurrentQueuePos = EVENT.CurrentQueuePos + 1
        local nextPly = table.remove(playerQueue, 1)

        if IsValid(nextPly) and nextPly:Alive() then
            currentPlayer = nextPly
            break
        end
    end

    -- Queue empty
    if not IsValid(currentPlayer) then
        -- Send what's effectively a 'close queue' command to the clients
        net.Start("RdmtSussyBuffetQueueUpdate")
            net.WriteUInt(0, 8)
        net.Broadcast()

        -- Remove all traces of the players' former roles, and give them their new ones
        for _, ply in player.Iterator() do
            ClearTimeoutTimer(ply)

            Randomat:SmallNotify("The buffet is closed!", 5, ply)

            if ply.buffetChosenRole then
                timer.Simple(2, function()
                    Randomat:SmallNotify("You are now " .. ROLE_STRINGS_EXT[ply.buffetChosenRole], 5, ply)
                    ply.buffetChosenRole = nil
                end)

                ply:StripRoleWeapons()

                for _, wep in ipairs(ply:GetWeapons()) do
                    if IsValid(wep) and wep.CanBuy and #wep.CanBuy > 0 then
                        ply:StripWeapon(wep:GetClass())
                    end
                end

                ply:ResetEquipment()

                ply:SetRole(ply.buffetChosenRole)
                ply:SetDefaultCredits()
                ply:StripRoleWeapons()
                hook.Run("PlayerLoadout", ply)

                ply.buffetChoices = nil
                ply.buffetChoiceAmount = nil
            end
        end

        SendFullStateUpdate()
        hook.Remove("Think", "RdmtSussyBuffet_PauseRound")
        hook.Remove("EntityTakeDamage", "RdmtSussyBuffet_BlockDamage")
        hook.Remove("PostPlayerDeath", "RdmtSussyBuffet_RespawnOnDeath")
        return
    end

    -- Update current queue position
    net.Start("RdmtSussyBuffetQueueUpdate")
        net.WriteUInt(EVENT.CurrentQueuePos, 8)
    net.Broadcast()

    -- Determine new choices for the next player and send them
    currentPlayer.buffetChoices = DetermineChoices(currentTeamAmounts, currentPlayer.buffetChoiceAmount)
    SendChoices(currentPlayer.buffetChoices, currentPlayer)
end

PlayerPickChoice = function(ply, playerChoice)
    if playerChoice >= 1 and playerChoice <= 3 then

        local chosenRole = ply.buffetChoices[playerChoice]
        ply.buffetChosenRole = chosenRole

        local teamName
        local pool
        local team = player.GetRoleTeam(chosenRole)

        if team == ROLE_TEAM_INNOCENT then
            teamName = "innocents"
            pool = innocentPool
        elseif team == ROLE_TEAM_DETECTIVE then
            teamName = "detectives"
            pool = detectivePool
        elseif team == ROLE_TEAM_TRAITOR then
            teamName = "traitors"
            pool = traitorPool
        elseif team == ROLE_TEAM_JESTER then
            teamName = "jesters"
            pool = jesterPool
        else
            teamName = "others"
            pool = otherPool
        end

        -- Reduce relevant team slot amount
        if currentTeamAmounts[teamName] and currentTeamAmounts[teamName] > 0 then
            currentTeamAmounts[teamName] = currentTeamAmounts[teamName] - 1
        end

        -- Remove role from its pool if duplicates aren't allowed
        if not GetConVar("randomat_sussybuffet_allow_duplicates"):GetBool() then
            table.RemoveByValue(pool, chosenRole)
        end

        -- Move on to next player
        NextPlayerTurn()
    elseif playerChoice == 4 then
        -- Reroll if they have rerolls left
        if ply.buffetChoiceAmount > 1 then
            ply.buffetChoiceAmount = ply.buffetChoiceAmount - 1
            ply.buffetChoices = DetermineChoices(currentTeamAmounts, ply.buffetChoiceAmount)
            SendChoices(ply.buffetChoices, ply)
        else
            -- If no rerolls left, they're assigned the new 'choice'
            PlayerPickChoice(ply, 1)
        end
    end
end

net.Receive("RdmtSussyBuffetChoices", function(_, ply)
    -- Ignore things from the non-current player, just in case?
    if ply ~= currentPlayer then return end

    -- Cancel their backup timeout timer
    ClearTimeoutTimer(ply)

    local playerChoice = net.ReadUInt(3)
    PlayerPickChoice(ply, playerChoice)
end)

function EVENT:Begin()
    -- Respawn dead players so they can take part in the buffet
    if GetConVar("randomat_sussybuffet_respawn_dead_players"):GetBool() then
        for _, ply in player.Iterator() do
            if not ply:Alive() then
                ply:SpawnForRound(true)

                if IsValid(ply.server_ragdoll) then
                    ply.server_ragdoll:Remove()
                end
            end
        end
    end

    -- Pause round time
    hook.Add("Think", "RdmtSussyBuffet_PauseRound", function()
        SetGlobalFloat("ttt_round_end", GetGlobalFloat("ttt_round_end", 0) + FrameTime())
        SetGlobalFloat("ttt_haste_end", GetGlobalFloat("ttt_haste_end", 0) + FrameTime())
    end)

    -- Prevent damage during buffet
    hook.Add("EntityTakeDamage", "RdmtSussyBuffet_BlockDamage", function()
        return true
    end)

    -- If a player somehow dies anyway, then respawn them immediately
    hook.Add("PostPlayerDeath", "RdmtSussyBuffet_RespawnOnDeath", function(ply)
        timer.Simple(0.1, function()
            ply:SpawnForRound(true)

            if IsValid(ply.server_ragdoll) then
                ply.server_ragdoll:Remove()
            end
        end)
    end)

    local players = self:GetAlivePlayers()
    local playerCount = #players

    local rolePackOnly    = GetConVar("randomat_sussybuffet_rolepack_only"):GetBool()
    local includeDefaults = GetConVar("randomat_sussybuffet_include_default_roles"):GetBool()

    for _, ply in ipairs(players) do
        ply.buffetChoiceAmount = 3
        ply.buffetChoices      = {}
        ply.buffetChosenRole   = nil
    end

    -- Clear previous pools
    innocentPool  = {}
    detectivePool = {}
    traitorPool   = {}
    jesterPool    = {}
    otherPool     = {}

    local teamTables = {
        [ROLE_TEAM_INNOCENT]    = innocentPool,
        [ROLE_TEAM_DETECTIVE]   = detectivePool,
        [ROLE_TEAM_TRAITOR]     = traitorPool,
        [ROLE_TEAM_JESTER]      = jesterPool,
        [ROLE_TEAM_INDEPENDENT] = otherPool,
        [ROLE_TEAM_MONSTER]     = otherPool
    }

    --------------------------------------------------------------
    -- Build role pools
    --------------------------------------------------------------

    -- Turn convar string into table
    local bannedString = GetConVar("randomat_sussybuffet_excluded_roles"):GetString()

    -- Convert any upper case letters to lower, remove spaces and make into a table
    local bannedStringLower   = string.lower(bannedString)
    local bannedStringNoSpace = string.Replace(bannedStringLower, " ", "")
    local bannedRolesRaw      = string.Split(bannedStringNoSpace, ",")

    -- Convert raw banned roles into role objects (if that's the word?)
    local bannedRoles = {}
    for _, raw in ipairs(bannedRolesRaw) do
        local roleNumber = table.KeyFromValue(ROLE_STRINGS_RAW, raw) or nil
        if roleNumber then
            TableInsert(bannedRoles, roleNumber)
        else
            print("No role found for convar argument: " .. raw)
        end
    end

    local roleStart = includeDefaults and 0 or 3

    for role = roleStart, ROLE_MAX do
        local roleBanned = table.HasValue(bannedRoles, role)

        local includeRole = false
        if rolePackOnly then
            includeRole = DEFAULT_ROLES[role] or (ROLE_PACK_ROLES and ROLE_PACK_ROLES[role])
        else
            if not (roleBanned or ROLE_BLOCK_SPAWN_CONVARS[role]) then
                includeRole = true
            end
        end

        if includeRole then
            local team = player.GetRoleTeam(role)
            if teamTables[team] then
                TableInsert(teamTables[team], role)
            end
        end
    end

    --------------------------------------------------------------
    -- Set up queue and start the buffet!
    --------------------------------------------------------------
    currentTeamAmounts = GetTeamAmounts(playerCount, #innocentPool, #detectivePool, #traitorPool, #jesterPool, #otherPool)

    local baseDetectives = currentTeamAmounts["detectives"]
    local baseInnocents  = currentTeamAmounts["innocents"]
    local baseTraitors   = currentTeamAmounts["traitors"]
    local baseJesters    = currentTeamAmounts["jesters"]
    local baseOthers     = currentTeamAmounts["others"]

    playerQueue = table.Copy(players)
    table.Shuffle(playerQueue)

    EVENT.CurrentQueuePos = 0

    timer.Simple(5, function()
        -- Tell each client how big the queue is, and what their secret position is
        for i, ply in ipairs(playerQueue) do
            net.Start("RdmtSussyBuffetQueueInit")
                net.WriteUInt(#playerQueue, 8)
                net.WriteUInt(i, 8)
            net.Send(ply)
        end

        -- Base 24s
        local tutorialTime = 24
        if GetConVar("randomat_sussybuffet_respawn_dead_players"):GetBool() then
            tutorialTime = tutorialTime + 4
        end

        local function PrintBuffetMenu()
            local dGram  = baseDetectives == 1 and "role" or "roles"
            local iGram  = baseInnocents  == 1 and "role" or "roles"
            local tGram  = baseTraitors   == 1 and "role" or "roles"
            local jGram  = baseJesters    == 1 and "role" or "roles"
            local imGram = baseOthers     == 1 and "role" or "roles"

            PrintMessage(HUD_PRINTTALK, "============ Menu ============")
            PrintMessage(HUD_PRINTTALK, "After the buffet there will be:")
            PrintMessage(HUD_PRINTTALK, baseDetectives .. " Detective "            .. dGram  .. " in the game")
            PrintMessage(HUD_PRINTTALK, baseInnocents  .. " Innocent "             .. iGram  .. " in the game")
            PrintMessage(HUD_PRINTTALK, baseTraitors   .. " Traitor "              .. tGram  .. " in the game")
            PrintMessage(HUD_PRINTTALK, baseJesters    .. " Jester "               .. jGram  .. " in the game")
            PrintMessage(HUD_PRINTTALK, baseOthers     .. " Independent/Monster "  .. imGram .. " in the game")
            PrintMessage(HUD_PRINTTALK, "============================")
        end

        if GetConVar("randomat_sussybuffet_show_tutorial"):GetBool() then
            SendSussyBuffetInfo(3, 2, baseDetectives, baseInnocents, baseTraitors, baseJesters, baseOthers)
            timer.Create("RdmtSussyBuffet_TutorialTimer", tutorialTime, 1, function()
                PrintBuffetMenu()
                NextPlayerTurn()
            end)
        else
            PrintBuffetMenu()
            NextPlayerTurn()
        end
    end)
end

function EVENT:End()
    for _, ply in player.Iterator() do
        ClearTimeoutTimer(ply)
    end

    timer.Remove("RdmtSussyBuffet_TutorialTimer")

    hook.Remove("Think", "RdmtSussyBuffet_PauseRound")
    hook.Remove("EntityTakeDamage", "RdmtSussyBuffet_BlockDamage")
    hook.Remove("PostPlayerDeath", "RdmtSussyBuffet_RespawnOnDeath")
end

function EVENT:GetConVars()
    local sliders = {}

    for _, v in ipairs({"choice_time"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(sliders, {
                cmd = v,
                dsc = convar:GetHelpText(),
                min = convar:GetMin(),
                max = convar:GetMax(),
                dcm = 0
            })
        end
    end

    local checks = {}

    for _, v in ipairs({"rolepack_only", "include_default_roles", "show_tutorial", "allow_duplicates", "respawn_dead_players"}) do
        local name = "randomat_" .. self.id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(checks, {
                cmd = v,
                dsc = convar:GetHelpText()
            })
        end
    end

    return sliders, checks
end

Randomat:register(EVENT)