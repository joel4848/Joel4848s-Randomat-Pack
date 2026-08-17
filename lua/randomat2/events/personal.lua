local EVENT = {}

EVENT.Title = "YOU made this personal"
EVENT.Description = "RDMd teammates return as active Vindicators. Friendly fire = hostile consequences!"
EVENT.id = "personal"
EVENT.Categories = {"moderateimpact"}

local function IsSameTeam(attacker, victim)
    if attacker.IsSameTeam and isfunction(attacker.IsSameTeam) then
        return attacker:IsSameTeam(victim)
    end

    if (Randomat:IsInnocentTeam(attacker, false) and Randomat:IsInnocentTeam(victim, false)) then
        return true
    end

    if (Randomat:IsTraitorTeam(attacker) and Randomat:IsTraitorTeam(victim)) then
        return true
    end

    if (Randomat:IsMonsterTeam(attacker) and Randomat:IsMonsterTeam(victim)) then
        return true
    end

    return false
end

function EVENT:Begin()
    RegisterRoleHooks(ROLE_VINDICATOR)

    self:AddHook("DoPlayerDeath", function(victim, attacker, dmg)
        if not IsPlayer(victim) then return end
        if not IsPlayer(attacker) then return end
        if victim == attacker then return end
        if victim:IsRespawning() then
            victim:StopRespawning()
        end

        if IsValid(victim.PharaohAnkh) then
            victim.PharaohAnkh:DestroyAnkh()
            victim.PharaohAnkh = nil
        end

        if GetRoundState() ~= ROUND_ACTIVE then return end

        if not IsSameTeam(attacker, victim) then return end

        if victim:IsVindicator() then return end

        victim:StripRoleWeapons()
        victim:SetRole(ROLE_VINDICATOR)

        SendFullStateUpdate()
    end)
end

function EVENT:End()
    UnregisterRoleHooks(ROLE_VINDICATOR)
end

function EVENT:Condition()
    return ROLE_VINDICATOR ~= nil
end

Randomat:register(EVENT)