local REWARD = {}

REWARD.Name = "Shrink Player"
REWARD.Id = "shrink"

local shrink_scale = CreateConVar("rdmt_joel4848_rewardpunish_shrink_scale", "0.5", FCVAR_NONE, "The shrinking scale factor", 0.1, 0.9)

function REWARD:Apply(target)
    local scale = shrink_scale:GetFloat()
    Randomat:SetPlayerScale(target, scale, "Joel4848_RewardPunish_Shrink")
end

function REWARD:CleanUp()
    for _, p in player.Iterator() do
        Randomat:ResetPlayerScale(p, "Joel4848_RewardPunish_Shrink")
    end
end

function REWARD:AddConVars(sliders, checks, textboxes)
    for _, v in ipairs({"scale"}) do
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
