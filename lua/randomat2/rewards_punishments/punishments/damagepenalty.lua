local PUNISHMENT = {}

PUNISHMENT.Name = "Damage Penalty"
PUNISHMENT.Id = "damagepenalty"

local damagepenalty_penalty = CreateConVar("rdmt_joel4848_rewardpunish_damagepenalty_penalty", "0.3", FCVAR_NONE, "Outgoing damage penalty.", 0, 1)

local hookIds = {}

function PUNISHMENT:Apply(target)
    -- Generate a unique ID for this pairing and save it to be cleaned up later
    local hookId = "Rdmt_Joel4848_RewardPunish_DamagePenalty_" .. target:SteamID64()
    table.insert(hookIds, hookId)

    local penalty = damagepenalty_penalty:GetFloat()

    hook.Add("ScalePlayerDamage", hookId, function(ply, hitgroup, dmginfo)
        local att = dmginfo:GetAttacker()
        if IsPlayer(att) and GetRoundState() >= ROUND_ACTIVE then
            if att == target and ply ~= att then
                dmginfo:ScaleDamage(1 - penalty)
            end
        end
    end)
end

function PUNISHMENT:CleanUp()
    for _, hookId in ipairs(hookIds) do
        hook.Remove("ScalePlayerDamage", hookId)
    end
    table.Empty(hookIds)
end

function PUNISHMENT:AddConVars(sliders, checks, textboxes)
    for _, v in ipairs({"penalty"}) do
        local name = "randomat_joel4848_rewardpunish_" .. self.Id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(sliders, {
                cmd = self.Id .. "_" .. v,
                dsc = self.Name .. " - " .. convar:GetHelpText(),
                min = convar:GetMin(),
                max = convar:GetMax(),
                dcm = 2
            })
        end
    end
end

Joel4848:RegisterPunishment(PUNISHMENT)