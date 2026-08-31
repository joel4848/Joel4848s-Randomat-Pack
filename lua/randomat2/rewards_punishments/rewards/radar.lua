local REWARD = {}

REWARD.Name = "Radar"
REWARD.Id = "radar"

function REWARD:Apply(target)
    target:GiveEquipmentItem(EQUIP_RADAR)
    Randomat:CallShopHooks(true, EQUIP_RADAR, target)
end

Joel4848:RegisterReward(REWARD)