local PUNISHMENT = {}

util.AddNetworkString("Rdmt_Joel4848_RewardPunish_FlipScreenBegin")
util.AddNetworkString("Rdmt_Joel4848_RewardPunish_FlipScreenEnd")

PUNISHMENT.Name = "Flipped Screen"
PUNISHMENT.Id = "flipscreen"

local hookIds = {}

function PUNISHMENT:Apply(target)
    -- Generate a unique ID for this pairing and save it to be cleaned up later
    local hookId = "Rdmt_Joel4848_RewardPunish_FlipScreen_" .. target:SteamID64()
    table.insert(hookIds, hookId)

    hook.Add("SetupMove", hookId, function(ply, mv, cmd)
        if not IsPlayer(ply) or not ply:Alive() or ply:IsSpec() or ply ~= target then return end

        local sidespeed = mv:GetSideSpeed()
        mv:SetSideSpeed(-sidespeed)
    end)

    net.Start("Rdmt_Joel4848_RewardPunish_FlipScreenBegin")
    net.Send(target)
end

function PUNISHMENT:CleanUp(ply)
    if ply then
        local hookId = "Rdmt_Joel4848_RewardPunish_FlipScreen_" .. ply:SteamID64()
        hook.Remove("SetupMove", hookId)
        table.RemoveByValue(hookIds, hookId)
    else
        for _, hookId in ipairs(hookIds) do
            hook.Remove("SetupMove", hookId)
        end
        table.Empty(hookIds)
    end

    net.Start("Rdmt_Joel4848_RewardPunish_FlipScreenEnd")
    if ply then
        net.Sent(ply)
    else
        net.Broadcast()
    end
end

function PUNISHMENT:Condition()
    return not Randomat:IsEventActive("downunder")
end

Joel4848:RegisterPunishment(PUNISHMENT)
