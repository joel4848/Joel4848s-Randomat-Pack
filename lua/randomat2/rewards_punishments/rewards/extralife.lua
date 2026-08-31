local REWARD = {}

REWARD.Name = "Extra Life"
REWARD.Id = "extralife"

local hookIds = {}
local timerIds = {}

function REWARD:Apply(target)
    target:SetNWBool("Rdmt_Joel4848_RewardPunish_ExtraLife", true)

    -- Generate a unique ID for this pairing and save it to be cleaned up later
    local hookId = "Rdmt_Joel4848_RewardPunish_ExtraLife_" .. target:SteamID64()
    table.insert(hookIds, hookId)

    hook.Add("PlayerDeath", hookId .. "_PlayerDeath", function(victim, entity, killer)
        if not IsValid(victim) or target ~= victim or not victim:GetNWBool("Rdmt_Joel4848_RewardPunish_ExtraLife", false) then return end

        local timerId = "Rdmt_Joel4848_RewardPunish_ExtraLifeTimer_" .. target:SteamID64()
        table.insert(timerIds, timerId)

        timer.Create(timerId, 0.25, 1, function()
            victim:SpawnForRound(true)
            local body = victim.server_ragdoll or victim:GetRagdollEntity()
            if IsValid(body) then
                body:Remove()
            end
            Randomat:PrintMessage(victim, MSG_PRINTBOTH, "You have been respawned with your extra life!")
            target:SetNWBool("Rdmt_Joel4848_RewardPunish_ExtraLife", false)
        end)
    end)

    hook.Add("TTTDeathNotifyOverride", hookId .. "_TTTDeathNotifyOverride", function(victim, inflictor, attacker, reason, killerName, role)
        if not IsPlayer(victim) or target ~= victim or not target:GetNWBool("Rdmt_Joel4848_RewardPunish_ExtraLife", false) then return end
        if reason ~= "ply" then return end

        return reason, killerName, ROLE_NONE
    end)
end

function REWARD:CleanUp()
    for _, hookId in ipairs(hookIds) do
        hook.Remove("PlayerDeath", hookId .. "_PlayerDeath")
        hook.Remove("TTTDeathNotifyOverride", hookId .. "_TTTDeathNotifyOverride")
    end
    table.Empty(hookIds)

    for _, timerId in ipairs(timerIds) do
        timer.Remove(timerId)
    end
    table.Empty(timerIds)

    for _, p in player.Iterator() do
        p:SetNWBool("Rdmt_Joel4848_RewardPunish_ExtraLife", false)
    end
end

Joel4848:RegisterReward(REWARD)