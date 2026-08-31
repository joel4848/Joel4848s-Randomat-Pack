local REWARD = {}

REWARD.Name = "One-Shot Knife"
REWARD.Id = "oneshotknife"

function REWARD:Apply(target)
    target:Give("weapon_ttt_rewardpunishknife")
end

Joel4848:RegisterReward(REWARD)