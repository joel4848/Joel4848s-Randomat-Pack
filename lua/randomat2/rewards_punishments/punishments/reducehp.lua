local PUNISHMENT = {}

local math = math

local MathRound = math.Round

PUNISHMENT.Name = "Reduce Health"
PUNISHMENT.Id = "reducehp"

local reducehp_factor = CreateConVar("rdmt_joel4848_rewardpunish_reducehp_factor", "0.5", FCVAR_NONE, "The reduction factor (0.5 = 50% less HP).", 0.05, 0.95)

local originalMax   = {}
local removedHealth = {}

function PUNISHMENT:Apply(target)
    originalMax[target:SteamID64()] = target:GetMaxHealth()

    local factor = 1 - reducehp_factor:GetFloat()
    local hp = MathRound(target:Health() * factor)
    removedHealth[target:SteamID64()] = target:Health() - hp
    target:SetHealth(hp)
    local max = MathRound(target:GetMaxHealth() * factor)
    target:SetMaxHealth(max)
end

function PUNISHMENT:CleanUp(ply)
    if ply then
        local newMax = originalMax[ply:SteamID64()] or ply:GetMaxHealth()
        ply:SetMaxHealth(newMax)

        local plyRemovedHealth = removedHealth[ply:SteamID64()] or 0
        local newHealth = ply:Health() + plyRemovedHealth
        ply:SetHealth(newHealth)
    else
        for _, p in player.Iterator() do
            local newMax = originalMax[p:SteamID64()] or p:GetMaxHealth()
            p:SetMaxHealth(newMax)

            local plyRemovedHealth = removedHealth[p:SteamID64()] or 0
            local newHealth = p:Health() + plyRemovedHealth
            p:SetHealth(newHealth)
        end
    end
end

function PUNISHMENT:AddConVars(sliders, checks, textboxes)
    for _, v in ipairs({"factor"}) do
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