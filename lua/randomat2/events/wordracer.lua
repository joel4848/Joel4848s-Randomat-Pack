local EVENT = {}

CreateConVar("randomat_wordracer_only_once",                 0,  FCVAR_NONE, "Whether to only have one puzzle rather than multiple",                      0, 1)
CreateConVar("randomat_wordracer_kill_failures",             1,  FCVAR_NONE, "Whether players who don't succeed within the time limit are killed",        0, 1)
CreateConVar("randomat_wordracer_time_limit",                60, FCVAR_NONE, "How long in seconds players have to succeed (0 to disable)",                0, 300)
CreateConVar("randomat_wordracer_time_between_puzzles",      5,  FCVAR_NONE, "How long in seconds before a new puzzle starts",                            0, 60)
CreateConVar("randomat_wordracer_reward_success",            0,  FCVAR_NONE, "Whether all successful players get a reward",                               0, 1)
CreateConVar("randomat_wordracer_reward_first_success_only", 0,  FCVAR_NONE, "Whether only the first successful player gets a reward",                    0, 1)
CreateConVar("randomat_wordracer_punish_failure",            0,  FCVAR_NONE, "Whether all unsuccessful players get a punishment",                         0, 1)
CreateConVar("randomat_wordracer_punish_first_failure_only", 0,  FCVAR_NONE, "Whether the first unsuccessful player gets a punishment",                   0, 1)
CreateConVar("randomat_wordracer_show_everyone_progress",    0,  FCVAR_NONE, "Whether everyone (not just spectators) should see other players' progress", 0, 1)

local descriptionTime = GetConVar("randomat_wordracer_time_limit"):GetInt() or 0
local descriptionTimeText = " - and " .. descriptionTime .. " seconds - "
if descriptionTime == 0 then descriptionTimeText = "" end

EVENT.Title = "Legally-distinct word-guessing-game racer"
EVENT.AltTitle = "Wordracer"
EVENT.Description = "Get 6 chances" .. descriptionTimeText .. "to guess a 5-letter word!"
EVENT.id = "wordracer"
EVENT.Categories = {"gamemode", "largeimpact"}

util.AddNetworkString("rdmtWordRacer_Answer")
util.AddNetworkString("rdmtWordRacer_Success")
util.AddNetworkString("rdmtWordRacer_GuessUpdate")

local function RewardSuccess(successfulPlayers)
    for _, ply in ipairs(successfulPlayers) do
        local reward = Joel4848:ApplyReward(ply)

        Randomat:SmallNotify("Success! Your reward is: " .. reward.Name)
    end
end

local function PunishFailure(failingPlayers)
    for _, ply in ipairs(failingPlayers) do
        local punishment = Joel4848:ApplyPunishment(ply)

        Randomat:SmallNotify("Failure! Your punishment is: " .. punishment.Name)
    end
end

local usedWords         = {}
local successfulPlayers = {}
local failurePlayers    = {}
local processedPlayers  = {}
local eventActive       = false
local chosenWord        = ""
local playerGuesses     = {}

local function UpdateGuesses(ply, guess, clear)
    if ply and guess then
        playerGuesses[ply] = guess
    end

    if clear then playerGuesses = {} end

    net.Start("rdmtWordRacer_GuessUpdate")
        net.WriteTable(playerGuesses)
        net.WriteBool(GetConVar("randomat_wordracer_show_everyone_progress"):GetBool())
    net.Broadcast()
end

local ProcessRoundEnd

local function StartNewRound()
    if not eventActive then return end

    UpdateGuesses(nil, nil, clear)

    successfulPlayers = {}
    failurePlayers = {}
    processedPlayers = {}

    -- Reset word pool if all words were used
    if #usedWords >= #WordRacer.answerWords then
        usedWords = {}
    end

    -- Select an unused word
    local availableWords = {}
    for _, word in ipairs(WordRacer.answerWords) do
        if not table.HasValue(usedWords, word) then
            table.insert(availableWords, word)
        end
    end

    chosenWord = availableWords[math.random(#availableWords)]
    table.insert(usedWords, chosenWord)
    currentAnswer = chosenWord

    local timeLimit = GetConVar("randomat_wordracer_time_limit"):GetInt()

    -- Send word and timer length to all clients
    net.Start("rdmtWordRacer_Answer")
        net.WriteString(chosenWord)
        net.WriteInt(timeLimit, 16)
    net.Broadcast()

    -- Backup timer
    timer.Remove("RdmtWordRacer_BackupTimer")
    if timeLimit > 0 then
        timer.Create("RdmtWordRacer_BackupTimer", timeLimit + 2, 1, function()
            if not eventActive then return end
            ProcessRoundEnd(true)
        end)
    end
end

local function CheckRoundCompletion()
    local allDone = true

    local alivePlayers = Randomat:GetPlayers(nil, true)

    for _, ply in ipairs(alivePlayers) do
        if not processedPlayers[ply] then
            allDone = false
            break
        end
    end

    if allDone then
        timer.Remove("RdmtWordRacer_BackupTimer")
        ProcessRoundEnd(false)
    end
end

ProcessRoundEnd = function(timedOut)
    if not eventActive then return end

    local alivePlayers = Randomat:GetPlayers(nil, true)

    -- Fill in missing players as failures if they timed out
    if timedOut then
        for _, ply in ipairs(alivePlayers) do
            if not processedPlayers[ply] then
                processedPlayers[ply] = true
                table.insert(failurePlayers, ply)
            end
        end
    end

    for _, ply in ipairs(failurePlayers) do
        Randomat:SmallNotify("The word was " .. string.upper(chosenWord) .. "!", 5, ply)
    end

    -- Kill failures
    if GetConVar("randomat_wordracer_kill_failures"):GetBool() then
        for _, ply in ipairs(failurePlayers) do
            if IsValid(ply) and ply:Alive() and not ply:IsSpec() then
                ply:Kill()
            end
        end
    end

    -- Process rewards
    if GetConVar("randomat_wordracer_reward_first_success_only"):GetBool() then
        if IsValid(successfulPlayers[1]) then
            RewardSuccess({successfulPlayers[1]})
        end
    elseif GetConVar("randomat_wordracer_reward_success"):GetBool() then
        if #successfulPlayers > 0 then
            RewardSuccess(successfulPlayers)
        end
    end

    -- Process punishments
    if GetConVar("randomat_wordracer_punish_first_failure_only"):GetBool() then
        if IsValid(failurePlayers[1]) then
            PunishFailure({failurePlayers[1]})
        end
    elseif GetConVar("randomat_wordracer_punish_failure"):GetBool() then
        if #failurePlayers > 0 then
            PunishFailure(failurePlayers)
        end
    end

    -- Repeat round if enabled
    if not GetConVar("randomat_wordracer_only_once"):GetBool() then
        local roundIntervalConVar = GetConVar("randomat_wordracer_time_between_puzzles"):GetInt()

        if roundIntervalConVar >= 2 then
            timer.Simple(3, function()
                if eventActive then
                    Randomat:SmallNotify("New word in " .. roundIntervalConVar .. " seconds!", math.min(roundIntervalConVar, 5))
                end
            end)
        end

        timer.Create("RdmtWordRacer_RoundStartTimer", roundIntervalConVar + 3, 1, function()
            if eventActive then
                Randomat:SmallNotify("Go!")
                StartNewRound()
            end
        end)
    end
end

net.Receive("rdmtWordRacer_GuessUpdate", function(_, ply)
    local guess = net.ReadTable()
    UpdateGuesses(ply, guess)
end)

net.Receive("rdmtWordRacer_Success", function(len, ply)
    if not eventActive or not IsValid(ply) or processedPlayers[ply] then return end

    local success = net.ReadBool()
    processedPlayers[ply] = true

    if success then
        table.insert(successfulPlayers, ply)
    else
        table.insert(failurePlayers, ply)
    end

    CheckRoundCompletion()
end)

function EVENT:Begin()
    eventActive = true
    usedWords = {}

    local killFailures = GetConVar("randomat_wordracer_kill_failures"):GetBool()
    local rewardAll    = GetConVar("randomat_wordracer_reward_success"):GetBool()
    local rewardFirst  = GetConVar("randomat_wordracer_reward_first_success_only"):GetBool()
    local punishAll    = GetConVar("randomat_wordracer_punish_failure"):GetBool()
    local punishFirst  = GetConVar("randomat_wordracer_punish_first_failure_only"):GetBool()

    local successInfo, failureInfo

    if rewardAll then
        successInfo = "Successful players will receive a reward!"
    elseif rewardFirst then
        successInfo = "The first successful player will receive a reward!"
    end

    if killFailures then
        failureInfo = "Unsuccessful players will be killed..."
    elseif punishAll then
        failureInfo = "Unsuccessful players will receive a punishment..."
    elseif punishFirst then
        failureInfo = "The first unsuccessful player will receive a punishment..."
    end

    timer.Create("RdmtWordRacer_RoundStartTimer1", 5, 1, function()
        if successInfo then
            Randomat:SmallNotify(successInfo)
        end

        if failureInfo then
            Randomat:SmallNotify(failureInfo)
        end

        timer.Create("RdmtWordRacer_RoundStartTimer2", 7, 1, function()
            Randomat:SmallNotify("Go!")
            StartNewRound()
        end)
    end)

    self:AddHook("PostPlayerDeath", function()
        timer.Simple(0.1, function()
            UpdateGuesses()
        end)
    end)

    self:AddHook("PlayerSpawn", function()
        timer.Simple(1, function()
            UpdateGuesses()
        end)
    end)
end

function EVENT:End()
    eventActive = false
    timer.Remove("RdmtWordRacer_BackupTimer")
    timer.Remove("RdmtWordRacer_RoundStartTimer1")
    timer.Remove("RdmtWordRacer_RoundStartTimer2")

    successfulPlayers = {}
    failurePlayers    = {}
    processedPlayers  = {}
    playerGuesses     = {}

    Joel4848:CleanUpRewardPunish()
end

function EVENT:GetConVars()
    local sliders = {}

    for _, v in ipairs({"time_limit", "time_between_puzzles"}) do
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
    for _, v in ipairs({"only_once", "kill_failures", "reward_success", "reward_first_success_only", "punish_failure", "punish_first_failure_only", "show_everyone_progress"}) do
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