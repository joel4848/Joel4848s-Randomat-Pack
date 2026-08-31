local PUNISHMENT = {}

local math = math

local MathRandom = math.random

PUNISHMENT.Name = "Butterfingers"
PUNISHMENT.Id = "butterfingers"

local butterfingers_time_min = CreateConVar("rdmt_joel4848_rewardpunish_butterfingers_time_min", 10, FCVAR_NONE, "Minimum time between weapon drops.", 5, 60)
local butterfingers_time_max = CreateConVar("rdmt_joel4848_rewardpunish_butterfingers_time_max", 30, FCVAR_NONE, "Maximum time between weapon drops.", 5, 60)

local timerIds = {}

function PUNISHMENT:Apply(target)
    -- Generate a unique ID for this pairing and save it to be cleaned up later
    local timerId = "Rdmt_Joel4848_RewardPunish_Butterfingers_" .. target:SteamID64()
    table.insert(timerIds, timerId)

    local time_min = butterfingers_time_min:GetInt()
    local time_max = butterfingers_time_max:GetInt()
    if time_min > time_max then
        time_min = time_max
    end
    local interval = MathRandom(time_min, time_max)
    timer.Create(timerId, interval, 0, function()
        -- Stop the timer if this player is gone or dead
        if not IsPlayer(target) or not target:Alive() or target:IsSpec() then
            timer.Remove(timerId)
            return
        end

        local wep = target:GetActiveWeapon()
        if IsValid(wep) and wep.AllowDrop then
            target:DropWeapon(wep)
            target:SetFOV(0, 0.2)
            target:EmitSound("vo/npc/Barney/ba_pain01.wav")
        end

        -- Choose another random interval
        interval = MathRandom(time_min, time_max)
        timer.Adjust(timerId, interval, nil, nil)
    end)
end

function PUNISHMENT:CleanUp()
    for _, timerId in ipairs(timerIds) do
        timer.Remove(timerId)
    end
    table.Empty(timerIds)
end

function PUNISHMENT:AddConVars(sliders, checks, textboxes)
    for _, v in ipairs({"time_min", "time_max"}) do
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
    return not Randomat:IsEventActive("butter")
end

Joel4848:RegisterPunishment(PUNISHMENT)