local PUNISHMENT = {}

util.AddNetworkString("Rdmt_Joel4848_RewardPunish_BlurScreenBegin")
util.AddNetworkString("Rdmt_Joel4848_RewardPunish_BlurScreenEnd")

PUNISHMENT.Name = "Blurred Screen"
PUNISHMENT.Id = "blurscreen"

function PUNISHMENT:Apply(target)
    net.Start("Rdmt_Joel4848_RewardPunish_BlurScreenBegin")
    net.Send(target)
end

function PUNISHMENT:CleanUp(ply)
    net.Start("Rdmt_Joel4848_RewardPunish_BlurScreenEnd")
    if ply then
        net.Send(ply)
    else
        net.Broadcast()
    end
end

function PUNISHMENT:Condition()

end

Joel4848:RegisterPunishment(PUNISHMENT)