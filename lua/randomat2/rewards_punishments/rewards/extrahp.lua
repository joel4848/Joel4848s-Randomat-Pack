local REWARD = {}

REWARD.Name = "Extra Health"
REWARD.Id = "extrahp"

local extrahp_amount = CreateConVar("rdmt_joel4848_rewardpunish_extrahp_amount", "50", FCVAR_NONE, "The amount of HP to give the target.", 1, 100)

function REWARD:Apply(target)
    local hp = extrahp_amount:GetInt()
    target:SetHealth(target:Health() + hp)
    target:SetMaxHealth(target:GetMaxHealth() + hp)
end

function REWARD:AddConVars(sliders, checks, textboxes)
    for _, v in ipairs({"amount"}) do
        local name = "randomat_joel4848_rewardpunish_" .. self.Id .. "_" .. v
        if ConVarExists(name) then
            local convar = GetConVar(name)
            table.insert(sliders, {
                cmd = self.Id .. "_" .. v,
                dsc = self.Name .. " - " .. convar:GetHelpText(),
                min = convar:GetMin(),
                max = convar:GetMax(),
                dcm = 0
            })
        end
    end
end

Joel4848:RegisterReward(REWARD)