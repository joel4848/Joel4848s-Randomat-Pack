local REWARD = {}

REWARD.Name = "Unlimited Ammo"
REWARD.Id = "unlimitedammo"

CreateConVar("rdmt_joel4848_rewardpunish_unlimitedammo_affectbuymenu", 0, FCVAR_NONE, "Affects buy menu weapons.")

local hookIds = {}

function REWARD:Apply(target)
    -- Generate a unique ID for this pairing and save it to be cleaned up later
    local hookId = "Rdmt_Joel4848_RewardPunish_UnlimitedAmmo_" .. target:SteamID64()
    table.insert(hookIds, hookId)

    local affects_buy = GetConVar("rdmt_joel4848_rewardpunish_unlimitedammo_affectbuymenu"):GetBool()
    hook.Add("Think", hookId, function()
        local active_weapon = target:GetActiveWeapon()
        if IsValid(active_weapon) and (active_weapon.AutoSpawnable or (not active_weapon.CanBuy or affects_buy)) then
            active_weapon:SetClip1(active_weapon.Primary.ClipSize)
        end
    end)
end

function REWARD:CleanUp()
    for _, hookId in ipairs(hookIds) do
        hook.Remove("Think", hookId)
    end
    table.Empty(hookIds)
end

function REWARD:AddConVars(sliders, checks, textboxes)
    for _, v in ipairs({"affectbuymenu"}) do
        local name = "randomat_joel4848_rewardpunish_" .. self.Id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(checks, {
                cmd = self.Id .. "_" .. v,
                dsc = self.Name .. " - " .. convar:GetHelpText()
            })
        end
    end
end

function REWARD:Condition()
    return not Randomat:IsEventActive("ammo")
end

Joel4848:RegisterReward(REWARD)