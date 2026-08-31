local REWARD = {}

REWARD.Name = "Health Station"
REWARD.Id = "healthstation"

function REWARD:Apply(target)
    target:Give("weapon_ttt_health_station")
end

Joel4848:RegisterReward(REWARD)