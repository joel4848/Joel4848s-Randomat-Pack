local EVENT = {}

EVENT.Title = "That @!#%~ dog!"
EVENT.Description = "Woof!"
EVENT.id = "damndog"
EVENT.Categories = {"moderateimpact"}

util.AddNetworkString("DamnDogSpawnDog")

function EVENT:Begin()
    local function SpawnDog(ply)
        local plyPos = ply:GetPos()
        local ang = ply:EyeAngles()
        local pos = plyPos + ang:Forward() * 75
        ang.x = 0
        pos.z = plyPos.z
        local dog = ents.Create("ttt_rdmt_damndog_dog")
        dog:SetPos(pos + Vector(0, 0, 5))
        dog:SetAngles(ang)
        dog:Spawn()
        dog:Activate()
    end

    net.Receive("DamnDogSpawnDog", function(_, ply)
        SpawnDog(ply)
    end)
end

Randomat:register(EVENT)