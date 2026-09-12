local REWARD = {}

REWARD.Name = "Teleporter"
REWARD.Id = "teleporter"

function REWARD:Apply(target)
    target:Give("weapon_ttt_teleport")
end

function REWARD:CleanUp(ply)
    if ply then
        ply:StripWeapon("weapon_ttt_teleport")
    end
end

Joel4848:RegisterReward(REWARD)