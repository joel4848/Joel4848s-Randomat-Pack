if SERVER then
    Joel4848 = Joel4848 or {}

    Joel4848.REWARDPUNISH = Joel4848.REWARDPUNISH or {
        Rewards = {},
        Punishments = {}
    }

    function Joel4848:RegisterReward(reward)
        reward.Id = reward.Id or reward.id or reward.ID

        local enabled = CreateConVar("randomat_joel4848_rewardpunish_" .. reward.Id .. "_enabled", "1", FCVAR_NONE, "Whether this reward is enabled.", 0, 1)
        reward.Enabled = function()
            return enabled:GetBool()
        end

        self.REWARDPUNISH.Rewards[reward.Id] = reward
    end

    function Joel4848:RegisterPunishment(punishment)
        punishment.Id = punishment.Id or punishment.id or punishment.ID

        local enabled = CreateConVar("randomat_joel4848_rewardpunish_" .. punishment.Id .. "_enabled", "1", FCVAR_NONE, "Whether this punishment is enabled.", 0, 1)
        punishment.Enabled = function()
            return enabled:GetBool()
        end

        self.REWARDPUNISH.Punishments[punishment.Id] = punishment
    end

    local function GetRandomOutcome(outcomeTable, banned, activeOutcomes)
        if type(banned) == "string" then
            banned = {banned}
        end

        local validOutcomes = {}

        for id, outcome in pairs(outcomeTable) do
            -- Skip if banned
            if banned and table.HasValue(banned, id) then
                continue
            end

            -- Skip if player already has this
            if activeOutcomes and activeOutcomes[id] then
                continue
            end

            -- Skip if disabled or condition not met
            if outcome:Enabled() and (not outcome.Condition or outcome:Condition()) then
                table.insert(validOutcomes, outcome)
            end
        end

        if #validOutcomes == 0 then
            return nil
        end

        return validOutcomes[math.random(1, #validOutcomes)]
    end

    function Joel4848:ApplyReward(ply, banned, rewardId)
        local chosenReward

        ply.Joel4848_ActiveRewards = ply.Joel4848_ActiveRewards or {}

        if rewardId then
            chosenReward = self.REWARDPUNISH.Rewards[rewardId]
            if not chosenReward then
                ErrorNoHalt("[RANDOMAT] Reward with ID '" .. tostring(rewardId) .. "' does not exist\n")
                return nil
            end
        else
            -- Send player's active rewards so no duplicates
            chosenReward = GetRandomOutcome(self.REWARDPUNISH.Rewards, banned, ply.Joel4848_ActiveRewards)
            if not chosenReward then
                ErrorNoHalt("[RANDOMAT] Could not apply reward: No enabled/unbanned rewards found for " .. ply:Nick() .. "!\n")
                return nil
            end
        end

        chosenReward:Apply(ply)

        ply.Joel4848_ActiveRewards[chosenReward.Id] = true

        return chosenReward
    end

    function Joel4848:ApplyPunishment(ply, banned, punishmentId)
        local chosenPunishment

        ply.Joel4848_ActivePunishments = ply.Joel4848_ActivePunishments or {}

        if punishmentId then
            chosenPunishment = self.REWARDPUNISH.Punishments[punishmentId]
            if not chosenPunishment then
                ErrorNoHalt("[RANDOMAT] Punishment with ID '" .. tostring(punishmentId) .. "' does not exist\n")
                return nil
            end
        else
            -- Send player's active punishments so no duplicates
            chosenPunishment = GetRandomOutcome(self.REWARDPUNISH.Punishments, banned, ply.Joel4848_ActivePunishments)
            if not chosenPunishment then
                ErrorNoHalt("[RANDOMAT] Could not apply punishment: No enabled/unbanned punishments found for " .. ply:Nick() .. "!\n")
                return nil
            end
        end

        chosenPunishment:Apply(ply)

        ply.Joel4848_ActivePunishments[chosenPunishment.Id] = true

        return chosenPunishment
    end

    function Joel4848:ClearPlayerRewards(ply)
        if not IsValid(ply) or not ply.Joel4848_ActiveRewards then return end

        for id, _ in pairs(ply.Joel4848_ActiveRewards) do
            local reward = self.REWARDPUNISH.Rewards[id]
            if reward and reward.CleanUp then
                reward:CleanUp(ply)
            end
        end

        ply.Joel4848_ActiveRewards = {}
    end

    function Joel4848:ClearPlayerPunishments(ply)
        if not IsValid(ply) or not ply.Joel4848_ActivePunishments then return end

        for id, _ in pairs(ply.Joel4848_ActivePunishments) do
            local punishment = self.REWARDPUNISH.Punishments[id]
            if punishment and punishment.CleanUp then
                punishment:CleanUp(ply)
            end
        end

        ply.Joel4848_ActivePunishments = {}
    end

    function Joel4848:CleanUpRewardPunish()
        for _, reward in pairs(self.REWARDPUNISH.Rewards) do
            if reward.CleanUp then
                reward:CleanUp()
            end
        end
        for _, punishment in pairs(self.REWARDPUNISH.Punishments) do
            if punishment.CleanUp then
                punishment:CleanUp()
            end
        end

        for _, ply in player.Iterator() do
            ply.Joel4848_ActiveRewards = {}
            ply.Joel4848_ActivePunishments = {}
        end
    end

    hook.Add("TTTPrepareRound", "Joel4848_RewardPunish_Reset", function()
        Joel4848:CleanUpRewardPunish()
    end)
end

local function AddServer(fil)
    if SERVER then include(fil) end
end

local function AddClient(fil)
    if SERVER then AddCSLuaFile(fil) end
    if CLIENT then include(fil) end
end

local serverRewards, _ = file.Find("randomat2/rewards_punishments/rewards/*.lua", "LUA")
for _, fil in ipairs(serverRewards) do
    AddServer("randomat2/rewards_punishments/rewards/" .. fil)
end

local serverPunishments, _ = file.Find("randomat2/rewards_punishments/punishments/*.lua", "LUA")
for _, fil in ipairs(serverPunishments) do
    AddServer("randomat2/rewards_punishments/punishments/" .. fil)
end

local clientRewards, _ = file.Find("randomat2/rewards_punishments/rewards/client/*.lua", "LUA")
for _, fil in ipairs(clientRewards) do
    AddClient("randomat2/rewards_punishments/rewards/client/" .. fil)
end

local clientPunishments, _ = file.Find("randomat2/rewards_punishments/punishments/client/*.lua", "LUA")
for _, fil in ipairs(clientPunishments) do
    AddClient("randomat2/rewards_punishments/punishments/client/" .. fil)
end

local sharedRewards, _ = file.Find("randomat2/rewards_punishments/rewards/shared/*.lua", "LUA")
for _, fil in ipairs(sharedRewards) do
    AddServer("randomat2/rewards_punishments/rewards/shared/" .. fil)
    AddClient("randomat2/rewards_punishments/rewards/shared/" .. fil)
end

local sharedPunishments, _ = file.Find("randomat2/rewards_punishments/punishments/shared/*.lua", "LUA")
for _, fil in ipairs(sharedPunishments) do
    AddServer("randomat2/rewards_punishments/punishments/shared/" .. fil)
    AddClient("randomat2/rewards_punishments/punishments/shared/" .. fil)
end