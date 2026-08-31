local PUNISHMENT = {}

util.AddNetworkString("Rdmt_Joel4848_RewardPunish_ParanoiaBegin")
util.AddNetworkString("Rdmt_Joel4848_RewardPunish_ParanoiaEnd")

PUNISHMENT.Name = "Paranoia"
PUNISHMENT.Id = "paranoia"

local paranoia_timer_min = CreateConVar("rdmt_joel4848_rewardpunish_paranoia_timer_min", 15, {FCVAR_NONE, FCVAR_NOTIFY}, "Minimum time between sounds", 1, 120)
local paranoia_timer_max = CreateConVar("rdmt_joel4848_rewardpunish_paranoia_timer_max", 30, {FCVAR_NONE, FCVAR_NOTIFY}, "Maximum time between sounds", 1, 120)

function PUNISHMENT:Apply(target)
    net.Start("Rdmt_Joel4848_RewardPunish_ParanoiaBegin")
    net.WriteUInt(paranoia_timer_min:GetInt(), 8)
    net.WriteUInt(paranoia_timer_max:GetInt(), 8)
    net.Send(target)
end

function PUNISHMENT:CleanUp()
    net.Start("Rdmt_Joel4848_RewardPunish_ParanoiaEnd")
    net.Broadcast()
end

function PUNISHMENT:AddConVars(sliders, checks, textboxes)
    for _, v in ipairs({"timer_min", "timer_max"}) do
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

function PUNISHMENT:Condition()
    return not Randomat:IsEventActive("paranoid")
end

Joel4848:RegisterPunishment(PUNISHMENT)
