local PUNISHMENT = {}

PUNISHMENT.Name = "Grow Player"
PUNISHMENT.Id = "grow"

local grow_scale = CreateConVar("rdmt_joel4848_rewardpunish_grow_scale", "1.5", FCVAR_NONE, "The growing scale factor", 1.1, 3.0)

function PUNISHMENT:Apply(target)
    local scale = grow_scale:GetFloat()
    Randomat:SetPlayerScale(target, scale, "Joel4848_RewardPunish_Grow")
end

function PUNISHMENT:CleanUp()
    for _, p in player.Iterator() do
        Randomat:ResetPlayerScale(p, "Joel4848_RewardPunish_Grow")
    end
end

function PUNISHMENT:AddConVars(sliders, checks, textboxes)
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

Joel4848:RegisterPunishment(PUNISHMENT)
