local PUNISHMENT = {}

util.AddNetworkString("Rdmt_Joel4848_RewardPunish_BlurScreenBegin")
util.AddNetworkString("Rdmt_Joel4848_RewardPunish_BlurScreenEnd")

PUNISHMENT.Name = "Blurred Screen"
PUNISHMENT.Id = "blurscreen"

function PUNISHMENT:Apply(target)
    net.Start("Rdmt_Joel4848_RewardPunish_BlurScreenBegin")
    net.Send(target)
end

function PUNISHMENT:CleanUp()
    net.Start("Rdmt_Joel4848_RewardPunish_BlurScreenEnd")
    net.Broadcast()
end

function PUNISHMENT:Condition()

end

Joel4848:RegisterPunishment(PUNISHMENT)