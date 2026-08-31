local REWARD = {}

REWARD.Name = "Teleporter"
REWARD.Id = "teleporter"

function REWARD:Apply(target)
    target:Give("weapon_ttt_teleport")
end

Joel4848:RegisterReward(REWARD)