local PUNISHMENT = {}

util.AddNetworkString("Rdmt_Joel4848_RewardPunish_RandomSensitivityValue")

PUNISHMENT.Name = "Random Sensitivity"
PUNISHMENT.Id = "randomsensitivity"

local change_interval = CreateConVar("rdmt_joel4848_rewardpunish_randomsensitivity_change_interval", 15, {FCVAR_NONE, FCVAR_NOTIFY}, "Sensitivity change interval", 5, 60)
local scale_min = CreateConVar("rdmt_joel4848_rewardpunish_randomsensitivity_scale_min", 25, {FCVAR_NONE, FCVAR_NOTIFY}, "Minimum sensitivity to use", 10, 100)
local scale_max = CreateConVar("rdmt_joel4848_rewardpunish_randomsensitivity_scale_max", 500, {FCVAR_NONE, FCVAR_NOTIFY}, "Maximum sensitivity to use", 100, 1000)

local timerAndHookIds = {}

local function SetSensitivity(ply, sensitivity)
    net.Start("Rdmt_Joel4848_RewardPunish_RandomSensitivityValue")
    net.WriteFloat(sensitivity)
    net.Send(ply)
end

function PUNISHMENT:Apply(target)
    -- Generate a unique ID for this pairing and save it to be cleaned up later
    local timerAndHookId = "Rdmt_Joel4848_RewardPunish_RandomSensitivity_" .. target:SteamID64()
    table.insert(timerAndHookIds, timerAndHookId)

    local interval = change_interval:GetInt()
    local min = scale_min:GetInt()
    local max = scale_max:GetInt()
    timer.Create(timerAndHookId, interval, 0, function()
        -- Stop the timer if this player is gone
        if not IsPlayer(target) then
            timer.Remove(timerAndHookId)
            return
        end

        -- If they are dead, stop the timer and reset their sensitivity
        if not target:Alive() or target:IsSpec() then
            SetSensitivity(target, 0)
            timer.Remove(timerAndHookId)
            return
        end

        local sensitivity = math.random(min, max) / 100
        SetSensitivity(target, sensitivity)
    end)

    -- Reset dead player's sensitivity
    hook.Add("PlayerDeath", timerAndHookId, function(victim, entity, killer)
        if not IsValid(victim) or victim ~= target then return end
        SetSensitivity(target, 0)
    end)
end

function PUNISHMENT:CleanUp()
    for _, timerAndHookId in ipairs(timerAndHookIds) do
        timer.Remove(timerAndHookId)
        hook.Remove("PlayerDeath", timerAndHookId)
    end
    table.Empty(timerAndHookIds)

    for _, v in player.Iterator() do
        SetSensitivity(v, 0)
    end
end

function PUNISHMENT:AddConVars(sliders, checks, textboxes)
    for _, v in ipairs({"change_interval", "scale_min", "scale_max"}) do
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
    return not Randomat:IsEventActive("sensitive")
end

Joel4848:RegisterPunishment(PUNISHMENT)
