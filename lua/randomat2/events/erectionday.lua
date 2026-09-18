local EVENT = {}

EVENT.Title       = "Erection Day"
EVENT.Description = "Everyone gets a Fortnite Building Tool to erect buildings with!"
EVENT.id          = "erectionday"
EVENT.Categories  = {"moderateimpact"}

function EVENT:Begin()
    for _, ply in pairs(self:GetAlivePlayers()) do
        ply:Give("weapon_ttt_fortnite_building")
    end
end

function EVENT:Condition()
    return weapons.Get("weapon_ttt_fortnite_building") ~= nil
end

Randomat:register(EVENT)