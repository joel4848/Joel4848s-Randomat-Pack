local REWARD = {}

REWARD.Name = "Damage Resistance"
REWARD.Id = "damageresistance"

local damageresistance_resistance = CreateConVar("rdmt_joel4848_rewardpunish_damageresistance_resistance", "0.3", FCVAR_NONE, "Incoming damage reduction.", 0, 1)

local hookIds = {}

function REWARD:Apply(target)
    -- Generate a unique ID for this pairing and save it to be cleaned up later
    local hookId = "Rdmt_Joel4848_RewardPunish_DamageResistance_" .. target:SteamID64()
    table.insert(hookIds, hookId)

    local resistance = damageresistance_resistance:GetFloat()

    hook.Add("ScalePlayerDamage", hookId, function(ply, hitgroup, dmginfo)
        if GetRoundState() >= ROUND_ACTIVE then
            if ply == target then
                dmginfo:ScaleDamage(1 - resistance)
            end
        end
    end)
end

function REWARD:CleanUp()
    for _, hookId in ipairs(hookIds) do
        hook.Remove("ScalePlayerDamage", hookId)
    end
    table.Empty(hookIds)
end

function REWARD:AddConVars(sliders, checks, textboxes)
    for _, v in ipairs({"resistance"}) do
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

Joel4848:RegisterReward(REWARD)