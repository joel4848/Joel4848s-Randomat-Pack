local REWARD = {}

REWARD.Name = "Defibrillator"
REWARD.Id = "defibrillator"

function REWARD:Apply(target)
    target:Give("weapon_vadim_defib")
end

function REWARD:Condition()
    return weapons.Get("weapon_vadim_defib") ~= nil
end

Joel4848:RegisterReward(REWARD)