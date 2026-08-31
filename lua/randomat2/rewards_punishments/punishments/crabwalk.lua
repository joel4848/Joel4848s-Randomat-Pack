local PUNISHMENT = {}

util.AddNetworkString("Rdmt_Joel4848_RewardPunish_CrabWalkBegin")
util.AddNetworkString("Rdmt_Joel4848_RewardPunish_CrabWalkEnd")

PUNISHMENT.Name = "Crab Walk"
PUNISHMENT.Id = "crabwalk"

function PUNISHMENT:Apply(target)
    net.Start("Rdmt_Joel4848_RewardPunish_CrabWalkBegin")
    net.Send(target)
end

function PUNISHMENT:CleanUp()
    net.Start("Rdmt_Joel4848_RewardPunish_CrabWalkEnd")
    net.Broadcast()
end

function PUNISHMENT:Condition()
    return not Randomat:IsEventActive("crabwalk")
end

Joel4848:RegisterPunishment(PUNISHMENT)
