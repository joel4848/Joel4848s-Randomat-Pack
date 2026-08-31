local PUNISHMENT = {}

util.AddNetworkString("Rdmt_Joel4848_RewardPunish_LockedCameraBegin")
util.AddNetworkString("Rdmt_Joel4848_RewardPunish_LockedCameraEnd")

PUNISHMENT.Name = "Locked Camera"
PUNISHMENT.Id = "lockedcamera"

local timerAndHookIds = {}

local function ResetView(ply)
    local angles = ply:EyeAngles()
    angles.pitch = 0
    ply:SetEyeAngles(angles)
end

function PUNISHMENT:Apply(target)
    -- Generate a unique ID for this pairing and save it to be cleaned up later
    local timerAndHookId = "Rdmt_Joel4848_RewardPunish_LockedCamera_" .. target:SteamID64()
    table.insert(timerAndHookIds, timerAndHookId)

    ResetView(target)
    net.Start("Rdmt_Joel4848_RewardPunish_LockedCameraBegin")
    net.Send(target)

    timer.Create(timerAndHookId, 1, 0, function()
        -- Stop the timer if this player is gone or dead
        if not IsPlayer(target) or not target:Alive() or target:IsSpec() then
            timer.Remove(timerAndHookId)
            return
        end

        ResetView(target)
    end)

    hook.Add("PlayerSpawn", timerAndHookId, function(ply)
        if ply ~= target then return end

        timer.Simple(1, function()
            if not IsPlayer(target) or not target:Alive() or target:IsSpec() then return end
            ResetView(target)
        end)
    end)
end

function PUNISHMENT:CleanUp()
    for _, timerAndHookId in ipairs(timerAndHookIds) do
        timer.Remove(timerAndHookId)
        hook.Remove("PlayerSpawn", timerAndHookId)
    end
    table.Empty(timerAndHookIds)

    net.Start("Rdmt_Joel4848_RewardPunish_LockedCameraEnd")
    net.Broadcast()
end

function PUNISHMENT:Condition()
    return not Randomat:IsEventActive("doomed")
end

Joel4848:RegisterPunishment(PUNISHMENT)