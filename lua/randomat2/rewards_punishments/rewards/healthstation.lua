local REWARD = {}

REWARD.Name = "Health Station"
REWARD.Id = "healthstation"

function REWARD:Apply(target)
    target:Give("weapon_ttt_health_station")
end

function REWARD:CleanUp(ply)
    if ply then
        ply:StripWeapon("weapon_ttt_health_station")
    end
end

Joel4848:RegisterReward(REWARD)