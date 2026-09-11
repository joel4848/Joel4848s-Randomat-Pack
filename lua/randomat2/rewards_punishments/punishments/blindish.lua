local PUNISHMENT = {}

util.AddNetworkString("Rdmt_Joel4848_RewardPunish_BlindishBegin")
util.AddNetworkString("Rdmt_Joel4848_RewardPunish_BlindishEnd")

PUNISHMENT.Name = "Blind...ish"
PUNISHMENT.Id = "blindish"

function PUNISHMENT:Apply(target)
    target:ScreenFade(SCREENFADE.STAYOUT, Color(0, 0, 0, 255), 0, 0)

    net.Start("Rdmt_Joel4848_RewardPunish_BlindishBegin")
    net.Send(target)
end

function PUNISHMENT:CleanUp(ply)
    if ply then
        ply:ScreenFade(SCREENFADE.PURGE, Color(0, 0, 0, 255), 0, 0)
    else
        for _, p in player.Iterator() do
            p:ScreenFade(SCREENFADE.PURGE, Color(0, 0, 0, 255), 0, 0)
        end
    end

    net.Start("Rdmt_Joel4848_RewardPunish_BlindishEnd")
    if ply then
        net.Send(ply)
    else
        net.Broadcast()
    end
end

Joel4848:RegisterPunishment(PUNISHMENT)
