if SERVER then
    Joel4848 = Joel4848 or {}

    Joel4848.REWARDPUNISH = Joel4848.REWARDPUNISH or {
        Rewards = {},
        Punishments = {}
    }

    function Joel4848:RegisterReward(reward)
        reward.Id = reward.Id or reward.id or reward.ID

        -- if self.REWARDPUNISH.Rewards[reward.Id] then
        --     ErrorNoHalt("[RANDOMAT] Reward already exists with ID '" .. reward.Id .. "'\n")
        --     return
        -- end

        local enabled = CreateConVar("randomat_joel4848_rewardpunish_" .. reward.Id .. "_enabled", "1", FCVAR_NONE, "Whether this reward is enabled.", 0, 1)
        reward.Enabled = function()
            return enabled:GetBool()
        end

        self.REWARDPUNISH.Rewards[reward.Id] = reward
    end

    function Joel4848:RegisterPunishment(punishment)
        punishment.Id = punishment.Id or punishment.id or punishment.ID

        -- if self.REWARDPUNISH.Punishments[punishment.Id] then
        --     ErrorNoHalt("[RANDOMAT] Punishment already exists with ID '" .. punishment.Id .. "'\n")
        --     return
        -- end

        local enabled = CreateConVar("randomat_joel4848_rewardpunish_" .. punishment.Id .. "_enabled", "1", FCVAR_NONE, "Whether this punishment is enabled.", 0, 1)
        punishment.Enabled = function()
            return enabled:GetBool()
        end

        self.REWARDPUNISH.Punishments[punishment.Id] = punishment
    end

    local function GetRandomOutcome(outcomeTable, banned)
        if type(banned) == "string" then
            banned = {banned}
        end

        local validOutcomes = {}

        for id, outcome in pairs(outcomeTable) do
            if banned and table.HasValue(banned, id) then
                continue
            end

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

        if rewardId then
            chosenReward = self.REWARDPUNISH.Rewards[rewardId]
            if not chosenReward then
                ErrorNoHalt("[RANDOMAT] Reward with ID '" .. tostring(rewardId) .. "' does not exist\n")
                return nil
            end
        else
            chosenReward = GetRandomOutcome(self.REWARDPUNISH.Rewards, banned)
            if not chosenReward then
                ErrorNoHalt("[RANDOMAT] Could not apply reward: No enabled/unbanned rewards found!\n")
                return nil
            end
        end

        chosenReward:Apply(ply)

        return chosenReward
    end

    function Joel4848:ApplyPunishment(ply, banned, punishmentId)
        local chosenPunishment

        if punishmentId then
            chosenPunishment = self.REWARDPUNISH.Punishments[punishmentId]
            if not chosenPunishment then
                ErrorNoHalt("[RANDOMAT] Punishment with ID '" .. tostring(punishmentId) .. "' does not exist\n")
                return nil
            end
        else
            chosenPunishment = GetRandomOutcome(self.REWARDPUNISH.Punishments, banned)
            if not chosenPunishment then
                ErrorNoHalt("[RANDOMAT] Could not apply punishment: No enabled/unbanned punishments found!\n")
                return nil
            end
        end

        chosenPunishment:Apply(ply)

        return chosenPunishment
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
    end
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